values_hash = {}
  values_hash['!'] = '-- select from list --'
  user_group = $evm.root['user'].ldap_group
  #
  # Everyone can list network1 and network2
  #
  values_hash['network1'] = "Network 1"
  values_hash['network2'] = "Network 2"
  if user_group.downcase =~ /administrators/
    #
    # Administrators can also provision to network3 and network4
    #
    values_hash['network3'] = "Network 3"
    values_hash['network4'] = "Network 4"
  end

  list_values = {
     'sort_by'    => :value,
     'data_type'  => :string,
     'required'   => true,
     'values'     => values_hash
  }
  list_values.each { |key, value| $evm.object[key] = value }
