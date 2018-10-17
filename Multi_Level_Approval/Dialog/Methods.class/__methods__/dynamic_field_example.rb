values_hash = {}
  values_hash['!'] = '-- select from list --'
  user_group = $evm.root['user'].ldap_group
  #
  # Everyone can provision to DEV and UAT
  #
  values_hash['dev'] = "Development"
  values_hash['uat'] = "User Acceptance Test"
  if user_group.downcase =~ /administrators/
    #
    # Administrators can also provision to PRE-PROD and PROD
    #
    values_hash['pre-prod'] = "Pre-Production"
    values_hash['prod'] = "Production"
  end

  list_values = {
     'sort_by'    => :value,
     'data_type'  => :string,
     'required'   => true,
     'values'     => values_hash
  }
  list_values.each { |key, value| $evm.object[key] = value }
