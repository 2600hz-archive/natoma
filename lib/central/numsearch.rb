class Central
  class Numsearch

    def lookup(query)
    #SET UP
    bigcouchurl = "http://10.10.3.61:5984"
    raccount = Hash.new
    rparent = Hash.new
    rsugar = Hash.new
    rsugarcontact = Hash.new
    rticket = Hash.new

    if query.match(/[a-z]/)
      #SEARCH BY ACCOUNT NAME
      namesearchraw = `curl -sS "#{bigcouchurl}/accounts/_design/accounts/_view/listing_by_name"`
      namesearchparse = JSON.parse(namesearchraw)
      rows = namesearchparse["rows"]
      for i in 0..namesearchparse["rows"].length.to_i
        if (rows[i]["key"] == query)
          accountid = rows[i]["id"]
          break
        end
      end

    else
      #SEARCH BY PHONE NUMBER
      #FORMAT NUMBER
      digits = query.gsub(/\D/, '').split(//)
      if (digits.length == 11 and digits[0] == '1')
        #STRIP LEADING 1
        digits.shift
      end
      if (digits.length == 10)
        formnum = digits
      else
        puts "Incorrect number format"
        exit
      end
      #CURL FOR NUMBER DOCUMENT IN AREA CODE DATABASE
      numraw = `curl -sS "#{bigcouchurl}/numbers%2F%2B1#{formnum[0,3]}/%2B1#{formnum}"`
      #PARSE NUMBER DOCUMENT
      numparse = JSON.parse(numraw)
      if (numparse["pvt_assigned_to"] != nil)
        accountid = numparse["pvt_assigned_to"]
      else
        puts "Number not assigned to an account"
        exit
      end
    end

    accraw = `curl -sS "#{bigcouchurl}/accounts/#{accountid}"`
    accparse = JSON.parse(accraw)
    #LOAD INFO INTO HASH
    raccount["id"] = accparse["_id"]
    raccount["name"] = accparse["name"]
    raccount["role"] = accparse["role"]
    raccount["realm"] = accparse["realm"]
    raccount["parentcount"] = accparse["pvt_tree"].length-1
    #LOOP TO GET INFO OF EACH PARENT ACCOUNT
    for i in 0..accparse["pvt_tree"].length-1
      parentid = accparse["pvt_tree"][i]
      parentraw = `curl -sS "#{bigcouchurl}/accounts/#{parentid}"`
      parentparse = JSON.parse(parentraw)
      rparent["id#{i}"] = accparse["pvt_tree"][i]
      rparent["name#{i}"] = parentparse["name"]
      rparent["role#{i}"] = parentparse["role"]
      rparent["realm#{i}"] = parentparse["realm"]
    end

    #SUGARCRM INFO GET
    crm = SugarCRM.connect("http://crm.2600hz.com:32950/sugar", 'jeremy', 'aBkXX1R1wBnI')
    sugaraccount = crm::Account.find_by_name(accparse["name"])
    rsugar["description"] = sugaraccount.description
    rsugar["website"] = sugaraccount.website
    rsugar["services"] = sugaraccount.account_services_c
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


    #ZENDESK INFO GET
      client = ZendeskAPI::Client.new do |config|
        config.url = "https://2600hz.zendesk.com/api/v2"
        config.username = "alerts@2600hz.com"
        config.password = "Fun1234!"
      end

      orgsearch = client.organization()
      orgsearch.each do |org|
        if (org.name == "Comtel Connect")
          @orgid = org.id
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

    #RETURN INFO
    return raccount, rparent, rsugar, rsugarcontact, rticket
    #return raccount

    end

end

end
