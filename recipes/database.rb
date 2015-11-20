#
# Cookbook Name:: cida_auth
# Recipe:: database
# Author: Phethala Thongsavanh < thongsav@usgs.gov >
#
# Description: 

# install maven, contruct pom, run pom
node.default['maven']['version'] = "3.2.2"
node.default['maven']['setup_bin'] = true

include_recipe "java::default"
include_recipe "maven::default"

#create liquibase directory
group_name = "liquibase"
os_user_name = "liquibsae"

group group_name do
  action :create
end

user os_user_name do 
  comment "Tomcat user used to access tomcat services"
  system true
  gid group_name
  home '/home/liquibase'
end

directory '/home/liquibase' do
  owner os_user_name
  group group_name
  mode '0755'
  action :create
end

#decrypt username and password
schema_name = node['cida_auth']['schema_name']
data_bag_name = node['cida_auth']['credentials_data_bag_name']
encryption_key_path = node['cida_auth']['data_bag_encryption_key']
data_bag_username_field = node['cida_auth']['data_bag_username_field']
data_bag_password_field = node['cida_auth']['data_bag_password_field']

credential_data_bag = data_bag_item(data_bag_name, data_bag_name, IO.read(encryption_key_path))
username = credential_data_bag[data_bag_username_field]
pass = credential_data_bag[data_bag_password_field]

# get config
cida_auth_version = node['cida_auth']['cida_auth_version']
db_connection = node['cida_auth']['db_connection']

template '/home/liquibase/pom.xml' do
	owner os_user_name
	group group_name
	source "pom.xml.erb"
	sensitive true
	variables(
	:cida_auth_version => cida_auth_version,
	:schema_name => schema_name,
	:db_connection => db_connection,
	:db_username	=> username,
	:db_password => pass
	)
end

bash "run_maven_liquibase" do
  cwd "/home/liquibase"
  code "mvn dependency:unpack liquibase:update"
  action :run
end