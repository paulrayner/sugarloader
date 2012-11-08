class AddContact
  require 'rubygems'
  require 'json'
  require 'pp'
  require 'sugarcrm'

  def self.load_sugar_info
      json = File.read('SugarCRM_Connection.json')
      return JSON.parse(json)
    end

  def self.load_contact_info
    json = File.read('contact.json')
    return JSON.parse(json)
  end

  def self.display_contact_info(contact_info)
    puts "Loading account: "
    pp contact_info["Account"]
    puts "---------------"
    puts "Loading contact: "
    pp contact_info["Contact"]
    puts "----------"
  end

  def self.connect_to_crm(sugar_info)
    pp sugar_info
    SugarCRM.connect(sugar_info["url"], sugar_info["username"], sugar_info["password"])
  end

  def self.add_contact(contact_info, user)
    contact = find_contact(contact_info)
    if (contact.nil?)
      puts "Adding new contact " + contact_info["first_name"] + " " + contact_info["last_name"]
      contact=SugarCRM::Contact.new
      contact.account_influence_c = contact_info["decision_influence"]
      contact.airport_code_c = contact_info["airport_code"]
      contact.assigned_user_id = user.id
      contact.campaign_name = contact_info["campaign"]
      contact.contact_quality_c = contact_info["quality"]
      contact.department = contact_info["department"]
      contact.description = contact_info["description"]
      #    c.do_not_call = ---- # TODO is this boolean?
      contact.email1=contact_info["email"]
      contact.first_name=contact_info["first_name"]
      contact.full_name = contact_info["first_name"] + " " + contact_info["last_name"]
      contact.last_name=contact_info["last_name"]
      contact.lead_source = contact_info["lead_source"]
      contact.lead_source_description_c = contact_info["description"]
      contact.linkedin_public_profile_c = contact_info["linked_in"]
      contact.phone_mobile = contact_info["mobile_phone"]
      contact.phone_work = contact_info["office_phone"]
      contact.refered_by_c = contact_info["referred_by"]
      #    c.reports_to = contact["reports_to"] # TODO contact lookup here
      contact.title = contact_info["title"]
      contact.training_attendance_c = contact_info["training_attendance"]
      contact.twitter_link_c = contact_info["twitter"]
      contact.save

      contact = find_contact(contact_info)
      if contact.nil?
        puts "Contact " + contact.first_name + " " + contact.last_name + " added successfully "
      end
    else
      puts "Contact " + contact.first_name + " " + contact.last_name + " already exists"
    end
    return contact
  end

  def self.find_contact(contact_info)
    SugarCRM::Contact.first(:conditions => {:first_name => contact_info["first_name"], :last_name => contact_info["last_name"]})
  end

  def self.add_account(contact_info, user)
    account_info = contact_info["Account"]
    account = SugarCRM::Account.find_by_name(account_info["name"])
    if (account.nil?)
      # Add new account
      puts "Adding new account for " + account_info["name"]
      account = SugarCRM::Account.new
      account.name = account_info["name"]
      account.airport_codes_c = contact_info["Contact"]["airport_code"]
      account.website = account_info["website"]
      account.assigned_user_id = user.id
      account.account_intensity_c = account_info["intensity"]
      account.account_type = account_info["type"]
      account.description = account_info["description"]
      account.date_of_last_purchase_c = account_info["last purchase"]

      account.save
      account = SugarCRM::Account.find_by_name(account_info["name"])
      if account.nil?
        puts "New account for " + account_info["name"] + " added successfully"
      end
    else
      puts "Account already exists for " + account_info["name"]
    end
    return account
  end

  def self.add_contact_to_account(account, contact)
    puts "Associating contact " + contact.first_name + " " + contact.last_name + " with account " + account.name
    account.contacts << contact
    account.save
  end

  def self.display_result(account, contact)
    if account.contacts.include?(contact)
      puts "Contact " + contact.first_name + " " + contact.last_name + " is associated correctly with account " + account.name
    else
      puts "Contact " + contact.first_name + " " + contact.last_name + " is not associated with account " + account.name + ", adding to account"
      add_contact_to_account(account, contact)
      if account.contacts.include?(contact)
        puts "Contact " + contact.first_name + " " + contact.last_name + " is now associated correctly with account " + account.name
      end
    end
  end

  def self.assign_contact_to_new_account(contact, contact_info, user)
    account = add_account(contact_info, user)
    add_contact_to_account(account, contact)
    display_result(account, contact)
  end

  contact_info = load_contact_info()
  connect_to_crm(load_sugar_info["Sugar_Info"])
  display_contact_info(contact_info)

  user = SugarCRM::User.find_by_user_name("paul")
  contact = add_contact(contact_info["Contact"], user)
  assign_contact_to_new_account(contact, contact_info, user) unless  (contact_info["Account"]["name"] == "None")
end