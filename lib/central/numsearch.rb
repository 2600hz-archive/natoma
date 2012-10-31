class Central
  class Numsearch

def initialize(query)
#Set up
bigcouchurl = "http://10.10.3.61:5984"
raccount = Hash.new
rparent = Hash.new
rsugar = Hash.new
rsugarcontact = Hash.new

puts query

if query.match(/[a-z]/)
  #SEARCH BY ACCOUNT NAME
  puts "Searching by account name...\n"
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
  puts "Searching by phone number...\n"
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
  puts accountid
end

accraw = `curl -sS "#{bigcouchurl}/accounts/#{accountid}"`
accparse = JSON.parse(accraw)
#PRINT ACCOUNT INFO
raccount["id"] = accparse["_id"]
raccount["name"] = accparse["name"]
raccount["role"] = accparse["role"]
raccount["realm"] = accparse["realm"]
#LOOP TO PRINT INFO OF EACH PARENT ACCOUNT
for i in 0..accparse["pvt_tree"].length-1
  parentid = accparse["pvt_tree"][i]
  parentraw = `curl -sS "#{bigcouchurl}/accounts/#{parentid}"`
  parentparse = JSON.parse(parentraw)
  rparent[i]["id"] = accparse["pvt_tree"][i]
  rparent[i]["name"] = parentparse["name"]
  rparent[i]["role"] = parentparse["role"]
  rparent[i]["realm"] = parentparse["realm"]
end

puts accparse["name"]
#SUGARCRM INFO GET
SugarCRM.connect("http://***REMOVED***:32950/sugar", '***REMOVED***', '***REMOVED***')
sugaraccount = SugarCRM::Account.find_by_name(accparse["name"])
rsugar["description"] = sugaraccount.description
rsugar["website"] = sugaraccount.website
rsugar["services"] = sugaraccount.account_services_c
contactcount = 0
sugaraccount.contacts.each do |contact|
  rsugarcontact[contactcount]["first_name"] = ["#{contact.first_name}"]
  rsugarcontact[contactcount]["last_name"] = ["#{contact.last_name}"]
  rsugarcontact[contactcount]["title"] = ["#{contact.title}"]
  rsugarcontact[contactcount]["phone_work"] = ["#{contact.phone_work}"]
  emailcount = 0
  contact.email_addresses.each do |email|
    rsugarcontact[contactcount]["email_address"][emailcount] = ["#{email.email_address}"]
    emailcount = emailcount+1
  end
  contactcount = contactcount+1
end

puts rsugar["description"]
puts rsugarcontact[0]["first_name"]


#RETURN INFO
return raccount, rparent, rsugar, rsugarcontact
end

end

end
