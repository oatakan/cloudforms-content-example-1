display_string = "..."
#
# Read the input from the 'tag_location' and hostname_suffix elements
#


#location_classification = $evm.vmdb(:classification).find_by_name('location')
#tag = $evm.vmdb('classification').find(
#                            :first,
#                            :conditions => ["parent_id = ? AND id = ?",
#                            location_classification.id, '#{location_name}'])
#tag_name = tag.name

location_tag = $evm.root['dialog_tag_location']
hostname_suffix = $evm.root['dialog_hostname_suffix']

if (!location_tag.length.zero? && !hostname_suffix.nil?)
  $evm.log(:info, "Location tag = \'#{location_tag}\'")
  $evm.log(:info, "Hostname suffix = \'#{hostname_suffix}\'")
  location_name = location_tag.first.description
  lowercase_location_name = location_name.downcase
  lowercase_hostname_suffix = hostname_suffix.downcase
  
  case lowercase_location_name
  when "london"
  	hostname_prefix = "f1252ia"
  when "chicago"
  	hostname_prefix = "f1253ia"
  else
    hostname_prefix = "f1234ia"
  end
  display_string = "#{hostname_prefix}#{lowercase_hostname_suffix}"
end

list_values = {
  'required'   => true,
  'protected'   => false,
  'read_only'  => true,
  'value' => display_string,
}
list_values.each do |key, value| 
  $evm.log(:info, "Setting dialog variable #{key} to #{value}")
  $evm.object[key] = value
end
exit MIQ_OK
