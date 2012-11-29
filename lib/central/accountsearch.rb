class Central
  class Accountsearch
    def bigcouch_search(query)
      #Setup
      bigcouch_url = "184.106.180.226:15984"
      search_results = Hash.new
      search_results["query"] = query
      if query.match(/[a-zA-Z]/)
        #Search by account name
        query = query.gsub(/\s+/, "")
        query = query.downcase
        namesearch_raw = `curl -sS "http://#{bigcouch_url}/accounts/_design/accounts/_view/listing_by_name"`
        namesearch_parsed = JSON.parse(namesearch_raw)
        rows = namesearch_parsed["rows"]
        search_count = 0
        search_results["count"] = 0
        for i in 0..namesearch_parsed["rows"].length.to_i
          if rows[i]["key"].match(/#{query}/)
            search_results["#{search_count};key"] = rows[i]["key"]
            search_results["#{search_count};id"] = rows[i]["id"]
            search_count = search_count+1
           end
        end
        search_results["count"] = search_count
        return search_results
      else
        #Search by phone number
        digits = query.gsub(/\D/, '').split(//)
        if (digits.length == 11 and digits[0] == '1')
          digits.shift
        end
        if (digits.length == 10)
          formnum = digits
        else
          search_results["error"] = "Incorrect number format."
          return search_results
        end
        num_raw = `curl -sS "http://#{bigcouch_url}/numbers%2F%2B1#{formnum[0,3]}/%2B1#{formnum}"`
        num_parsed = JSON.parse(num_raw)
        if (num_parsed["pvt_assigned_to"] != nil)
          account_id = num_parsed["pvt_assigned_to"]
          search_results["count"] = 1
          search_results["0;key"] = formnum
          search_results["0;id"] = num_parsed["pvt_assigned_to"]
        elsif (num_parsed["_id"] != nil and numparsed["pvt_assigned_to"] == nil)
          search_results["error"] = "Number found but not assigned to any account."
        else
          search_results["error"] = "Number not found in bigcouch db."
        end
        return search_results
      end
    end

    def bigcouch_info(account_id)
      #Setup
      bigcouch_url = "184.106.180.226:15984"
      raccount = Hash.new
      rparent = Hash.new
      rsugar = Hash.new
      rsugarcontact = Hash.new
      rticket = Hash.new
      #Load account info into hash
      account_raw = `curl -sS "http://#{bigcouch_url}/accounts/#{account_id}"`
      account_parsed = JSON.parse(account_raw)
      raccount["id"] = account_parsed["_id"]
      raccount["name"] = account_parsed["name"]
      raccount["role"] = account_parsed["role"]
      raccount["realm"] = account_parsed["realm"]
      raccount["parent_count"] = account_parsed["pvt_tree"].length-1
      #Load parent account info into hash
      for i in 0..account_parsed["pvt_tree"].length-1
        parent_id = account_parsed["pvt_tree"][i]
        parent_raw = `curl -sS "http://#{bigcouch_url}/accounts/#{parent_id}"`
        parent_parsed = JSON.parse(parent_raw)
        rparent["id#{i}"] = account_parsed["pvt_tree"][i]
        rparent["name#{i}"] = parent_parsed["name"]
        rparent["role#{i}"] = parent_parsed["role"]
        rparent["realm#{i}"] = parent_parsed["realm"]
      end
      rsugar, rsugarcontact = self.sugar_search(account_parsed["name"])
      rticket = self.zendesk_search(account_id)
      return raccount, rparent, rsugar, rsugarcontact, rticket
    end

    def sugar_search(query)
      rsugar = Hash.new
      rsugarcontact = Hash.new
      crm = SugarCRM.connect("http://crm.2600hz.com:32950/sugar", 'jeremy', 'aBkXX1R1wBnI')
      sugaraccount = crm::Account.find_by_name(query)
      rsugar["description"] = sugaraccount.description
      rsugar["website"] = sugaraccount.website
      rsugar["services"] = (sugaraccount.account_services_c).gsub(/\^/, "")
      contactcount = 0
      emailcount = 0
      test = Hash.new
      sugaraccount.contacts.each do |contact|
        rsugarcontact["first_name#{contactcount}"] = ["#{contact.first_name}"]
        rsugarcontact["last_name#{contactcount}"] = ["#{contact.last_name}"]
        rsugarcontact["title#{contactcount}"] = ["#{contact.title}"]
        rsugarcontact["phone_work#{contactcount}"] = ["#{contact.phone_work}"]
        emailcount = 0
        contact.email_addresses.each do |email|
          rsugarcontact["email_address#{contactcount};#{emailcount}"] = ["#{email.email_address}"]
          emailcount = emailcount+1
        end
        contactcount = contactcount+1
      end
      rsugarcontact["contactcount"] = contactcount-1
      rsugarcontact["emailcount"] = emailcount-1
      return rsugar, rsugarcontact
    end

    def zendesk_search(query)
      rticket = Hash.new
      find = false
      client = ZendeskAPI::Client.new do |config|
        config.url = "https://2600hz.zendesk.com/api/v2"
        config.username = "alerts@2600hz.com"
        config.password = "Fun1234!"
      end
      orgsearch = client.organization()
      orgsearch.each do |org|
        if (org.external_id == "#{query}")
          @orgid = org.id
          find = true
        end
      end
      if (find == false)
        orgsearch.each do |org|
          if ((org.name).downcase == query.downcase)
            @orgid = org.id
          end
        end
      end
      query = client.tickets(:organization_id => "#{@orgid}")
      counter = 0
      query.each do |ticket|
        if (ticket.status == "open" or ticket.status == "new")
          rticket["#{counter};id"] = ticket.id
          rticket["#{counter};subject"] = ticket.subject
          rticket["#{counter};url"] = "http://help.2600hz.com/tickets/#{ticket.id}"
          rticket["#{counter};updated_at"] = ticket.updated_at
          counter = counter+1
        end
      end
      rticket["ticketcount"] = counter-1
      return rticket
    end
  end
end
