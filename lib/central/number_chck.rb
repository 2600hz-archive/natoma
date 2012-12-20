class Central
  class Number_chck
    def check(account_id)
      #Setup
      bigcouch_url = "184.106.180.226:15984"
      temphash = Hash.new
      result = Hash.new
      flow_num = Hash.new
      found_nums = Hash.new
      new_result = Hash.new

      #Get phone_numbers document from target account
      parsed_id = "%2F" + account_id[0..1] + "%2F" + account_id[2..3] + "%2F" + account_id[4..account_id.length]
      phonenumbers_raw = `curl -sS "http://#{bigcouch_url}/account#{parsed_id}/phone_numbers"`
      phonenumbers_parsed = JSON.parse(phonenumbers_raw)
      temphash = phonenumbers_parsed

      #Remove non-phonenumber keys from hash
      temphash.delete("_id")
      temphash.delete("_rev")
      temphash.delete("pvt_created")
      temphash.delete("pvt_account_db")
      temphash.delete("pvt_account_id")
      temphash.delete("pvt_vsn")
      temphash.delete("pvt_type")
      temphash.delete("pvt_modified")

      #Check to see if number is in service and on account
      count = 0
      temphash.each do |key, value|
        if (temphash[key]["state"] == "in_service" and temphash[key]["on_subaccount"] == false and temphash[key]["assigned_to"] == account_id)
          result[count] = key
          count=count+1
        end
      end

      #Get callflow document from target account
      parsed_id = "%2F" + account_id[0..1] + "%2F" + account_id[2..3] + "%2F" + account_id[4..account_id.length]
      callflows_raw = `curl -sS "http://#{bigcouch_url}/account#{parsed_id}/_design/callflows/_view/crossbar_listing"`
      callflows_parsed = JSON.parse(callflows_raw)

      #Put callflows into flow_num hash
      rows = callflows_parsed["rows"]
      for i in 0..callflows_parsed["rows"].length.to_i-1
        flow_num[i] = rows[i]["value"]["numbers"]
      end

      #Create key-value pairs for find
      for i in 0..result.length-1 do
        result["#{i};find"] = "false"
      end

      #Search through callflows for phone numbers
      result.each do |res_k, res_v|
        if (res_v != "false" and res_v != "true")
          flow_num.each do |fl_k, fl_v|
            scan_power = "\\#{res_v}"
            scanner = fl_v.to_s.match(/#{scan_power}/)
            if (scanner.to_s == res_v.to_s)
              result["#{res_k};find"] = "true"
              new_result[res_v] = "true"
              break
            end
          end
          if result["#{res_k};find"] != "true"
            new_result[res_v] = "false"
          end
        end
      end

      return new_result
    end
  end
end
