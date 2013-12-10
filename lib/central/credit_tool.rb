class Central
  class Credit_tool
	def set(credit_debit, credit_amt, account_id)
      bigcouch_url = "184.106.180.226:15984"
      result = Hash.new
      result["id"] = account_id
      result["credit_debit"] = credit_debit
	  #SSH info
	  ip = "184.106.180.226"
	  port = "22223"
	  user = "root"
	  if (credit_debit == "add")
	    #Add credit to account
		debug = "Adding credit to account"
	    cmd = "/opt/kazoo/utils/sup/sup whistle_services_maintenance credit #{account_id} #{credit_amt}"
	  elsif (credit_debit == "remove")
	    #Remove credit from account
		debug = "Removing credit from account"
	    cmd = "/opt/kazoo/utils/sup/sup whistle_services_maintenance debit #{account_id} #{credit_amt}"
	  else
	    #Error
	    exit
	  end
	  command = "ssh -p #{port} #{user}@#{ip} '#{cmd}'"
	  Central.debug debug
	  log = Log.new object_id
	  b_stdout = Log::Buffer.new object_id, "stdout"
	  b_stderr = Log::Buffer.new object_id, "stderr"
	  h = {}
      h["exit_status"] = 1
      h["started"] = Time.now.to_f
      h["finished"] = nil
      log.save h
	  begin
        status = spawn command, 'stdout' => b_stdout, 'stderr' => b_stderr
      rescue => e
        h["error"] = e
      end
      h["finished"] = Time.now.to_f
      log.save h
	  if DEBUG
        puts command
        puts status.to_i
        puts b_stdout
        puts b_stderr if b_stderr
      end
      result["msg"] = b_stdout
      parsed_id = "%2F" + account_id[0..1] + "%2F" + account_id[2..3] + "%2F" + account_id[4..account_id.length]
      credit_raw = `curl -sS "http://#{bigcouch_url}/account#{parsed_id}/_design/transactions/_view/credit_remaining"`
      credit_parsed = JSON.parse(credit_raw)
      rows = credit_parsed["rows"]
      result["current"] = rows[0]["value"].to_f/10000
      return result
    end
  end
end
