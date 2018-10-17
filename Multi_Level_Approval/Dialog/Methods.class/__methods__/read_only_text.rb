display_string = "Validation...\n"
environment_found = false
#
# Read the input from the 'environment' element
#
environment_name = $evm.root['dialog_environment_name']
$evm.log(:info, "Environment name = \'#{environment_name}\'")
unless (environment_name.length.zero? || environment_name == '!')
  lowercase_environment = environment_name.downcase
  display_string += "   Environment \'#{environment_name}\' is available for use"
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
