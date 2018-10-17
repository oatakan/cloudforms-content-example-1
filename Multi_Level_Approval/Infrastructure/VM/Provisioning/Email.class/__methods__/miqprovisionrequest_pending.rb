#
# Description: This method is launched from the not_approved method which raises the requst_pending event
# when the provisioning request is NOT auto-approved
# Events: request_pending
# Model Notes:
# 1. to_email_address - used to specify an email address in the case where the
#    requester does not have a valid email address.To specify more than one email
#    address separate email address with commas. (I.e. admin@example.com,user@example.com)
# 2. from_email_address - used to specify an email address in the event the
#    requester replies to the email
# 3. signature - used to stamp the email with a custom signature
#

# $evm.root['miq_provision_request'].options[:ws_values] = {:approval_level=>"multi", :dialog_approval_level=>"multi", :flavor=>"small", :volume_1_size=>"0", :group_id=>"2", :group_name=>"EvmGroup-super_administrator", :service_id=>"36", :service_guid=>"eb2bee0c-c3a6-11e6-9c87-001a4aa0151a", :environment=>"dev", :flex_monitor=>"false", :flex_maximum=>"1"}   (type: Hash)
# $evm.root['miq_provision_request'].options[:vm_tags] = [25, 138, 140, 142]   (type: Array)

# Build email to requester with reason
def emailrequester(miq_request, appliance, msg)

  $evm.log("info", "Requester email logic starting")

  # Get requester object
  requester = miq_request.requester

  # Get requester email else set to nil
  requester_email = requester.email || nil

  # Get Owner Email else set to nil
  owner_email = miq_request.options[:owner_email] || nil
  $evm.log("info", "Requester email:<#{requester_email}> Owner Email:<#{owner_email}>")

  # if to is nil then use requester_email or owner_email
  to = nil
  to ||= requester_email # || owner_email

  # If to is still nil use to_email_address from model
  to ||= $evm.object['to_email_address']

  # Get from_email_address from model unless specified below
  from = nil
  from ||= $evm.object['from_email_address']

  # Get signature from model unless specified below
  signature = nil
  signature ||= $evm.object['signature']

  # Set email subject
  subject = "Request ID #{miq_request.id} - Your Request for a new VM(s) was not Auto-Approved"

  # Build email body
  body = "Hello, "
  body += "<br>#{msg}."
  body += "<br><br>Please review your Request and update or wait for approval from an Administrator."
  body += "<br><br>To view this Request go to: "
  body += "<a href='https://#{appliance}/miq_request/show/#{miq_request.id}'>https://#{appliance}/miq_request/show/#{miq_request.id}</a>"
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"

  $evm.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
  $evm.execute(:send_email, to, from, subject, body)
end

def approver_href(appliance, miq_request)
  body = "<a href='https://#{appliance}/miq_request/show/#{miq_request.id}'"
  body += ">https://#{appliance}/miq_request/show/#{miq_request.id}</a>"
  body
end

def dialog_options(options_hash)
  options = []
  options_hash.each do |option, value|
    next if /^service_guid/ =~ option.to_s
    options << {option.to_s.sub(/^dialog_/, '') => value}
  end
  options.uniq!
end

def dialog_tags(tags_hash)
  tags = []
  tags_hash.each do |tag, value|
    tags << {tag.to_s.sub(/^dialog_tag_\d+_/, '') => value}
  end
  tags
end

# Build email to approver with reason
def emailapprover(miq_request, appliance, msg, provisionRequestApproval)
  $evm.log("info", "Approver email logic starting")

  # Get approval level if set
  approval_level = @dialog_options_hash[:dialog_approval_level]

  # Get requester object
  requester = miq_request.requester

  # Get requester email else set to nil
  requester_email = requester.email || nil

  # Get Owner Email else set to nil
  owner_email = miq_request.options[:owner_email] || nil
  $evm.log("info", "Requester email:<#{requester_email}> Owner Email:<#{owner_email}>")

  # Override to email address below or get to_email_address from from model
  to = nil
  to ||= $evm.object['to_email_address']

  # Override from_email_address below or get from_email_address from model
  from = nil
  from ||= $evm.object['from_email_address']

  # Get signature from model unless specified below
  signature = nil
  signature ||= $evm.object['signature']

  # Set email subject
  if approval_level == 'multi'
    subject = "Request ID #{miq_request.id} - Service request needs approving"
  else
    if provisionRequestApproval
      subject = "Request ID #{miq_request.id} - Virtual machine request was not approved"
    else
      subject = "Request ID #{miq_request.id} - Virtual Machine request was denied due to quota limitations"
    end
  end

  # Build email body
  body = "Dear approver, "
  if approval_level == 'multi'
    body = "<br>"
    body += "<br>A Service request received from #{requester_email} is pending, and you are the final stage approver."
    body += "<br><br>Request details: "
    if @dialog_options_hash.key?(:dialog_service_name)
      body += "<br><br>&nbsp;&nbsp;Service description: #{@dialog_options_hash[:dialog_service_name]}"
    else
      body += "<br><br>&nbsp;&nbsp;Service description: #{miq_request.description}"
    end
    body += "<br><br>&nbsp;&nbsp;Service options selected: "
    dialog_options(@dialog_options_hash).each do |option| 
      key, value = option.flatten
      body += "<br>&nbsp;&nbsp;&nbsp;&nbsp;#{key}: #{value}"
    end
  else
    body += "<br>A VM provision request received from #{requester_email} is pending."
    body += "<br><br>#{msg}."
    body += "<br><br>Approvers notes: #{miq_request.reason}" if provisionRequestApproval
  end
  body += "<br><br>To approve or deny this request please go to: "
  body += approver_href(appliance, miq_request)
  body += "<br><br> Thank you,"
  body += "<br> #{signature}"
  $evm.log("info", "Sending email to <#{to}> from <#{from}> subject: <#{subject}>")
  $evm.execute(:send_email, to, from, subject, body)
end

# Get miq_request from root
miq_request = $evm.root['miq_request']
raise "miq_request missing" if miq_request.nil?
@dialog_options_hash = miq_request.options[:ws_values]
$evm.log("info", "Detected Request:<#{miq_request.id}> with Approval State:<#{miq_request.approval_state}>")

# Override the default appliance IP Address below
appliance = nil
appliance ||= $evm.root['miq_server'].ipaddress

# Get incoming message or set it to default if nil
msg = miq_request.resource.message || "Request pending"

# Check to see which state machine called this method
if msg.downcase.include?('quota')
  provisionRequestApproval = false
else
  provisionRequestApproval = true
end

# Email Requester
# emailrequester(miq_request, appliance, msg)

# Email Approver
emailapprover(miq_request, appliance, msg, provisionRequestApproval)
