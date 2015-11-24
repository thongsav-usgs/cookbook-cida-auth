#
# Cookbook Name:: cida_auth
# Recipe:: appstack
# Author: Phethala Thongsavanh < thongsav@usgs.gov >
#
# Description: 

managerCore = node["cida_auth"]["tomcat"]["manager.core.source.war"]
managerCoreName = node["cida_auth"]["tomcat"]["manager.core.final.name"]
manager = node["cida_auth"]["tomcat"]["manager.source.war"]
managerName = node["cida_auth"]["tomcat"]["manager.final.name"]
cidaAuth = node["cida_auth"]["tomcat"]["cida.auth.source.war"]
cidaAuthName = node["cida_auth"]["tomcat"]["cida.auth.final.name"]

Chef::Log.info("Provisioning #{managerName}, #{managerName}, #{cidaAuthName} using from #{managerCore}, #{manager}, #{cidaAuth}.")

node.default["wsi_tomcat"]["instances"]["default"]["context"]["environments"] = [
	{ "name" => "development", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["development"]},
	{ "name" => "auth.ldap.url", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["auth.ldap.url"]},
	{ "name" => "auth.ldap.domain", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["auth.ldap.domain"]},
	{ "name" => "auth.ldap.bind.user.prefix", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["auth.ldap.bind.user.prefix"]},
	{ "name" => "auth.ldap.bind.user.suffix", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["auth.ldap.bind.user.suffix"]},
	{ "name" => "auth.manager.password.algorithm", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["auth.manager.password.algorithm"]},
	{ "name" => "auth.manager.core.rest.url", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["auth.manager.core.rest.url"]},
	{ "name" => "auth.manager.core.host", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["auth.manager.core.host"]},
	{ "name" => "auth.manager.core.port", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["auth.manager.core.port"]},
	{ "name" => "auth.manager.core.scheme", "type" => "java.lang.String", "override" => true, "value" => node["cida_auth"]["tomcat"]["auth.manager.core.scheme"]}
]

# The encrypted data_bag referenced by credentials_data_bag_name settings 
# should have the following properties defined...
# auth.manager.username
# auth.manager.password
if node["cida_auth"]["tomcat"].has_key?("encrypted_environments_data_bag")
	node.default["wsi_tomcat"]["instances"]["default"]["context"]["encrypted_environments_data_bag"] = node["cida_auth"]["tomcat"]["encrypted_environments_data_bag"]
end

#Database connection
username_key = node["cida_auth"]["data_bag_username_field"]
password_key = node["cida_auth"]["data_bag_password_field"]
node.default["wsi_tomcat"]["instances"]["default"]["context"]["resources"] = [{ 
        "description" => "token storage database",
        "name" => "jdbc/cidaAuthDS",
        "auth" => "Container",
        "type" => "javax.sql.DataSource",
        "driver_class" => node["cida_auth"]["jdbc_driver_class"],
        "url" => node['cida_auth']['db_connection'],
        "max_active" => "50",
        "max_idle" => "10",
        "remove_abandoned" => "true",
        "remove_abandoned_timeout" => "60",
        "log_abandoned" => "true",
        "validation_query" => "select version()",
        "encrypted_attributes" => {
        	"data_bag_name" => node["cida_auth"]["credentials_data_bag_name"],
        	"key_location" => node["cida_auth"]["data_bag_encryption_key"],
        	"field_map" => {
        		"#{username_key}" => "username",
        		"#{password_key}" => "password"
        	}
        }
}]

#all app components
node.default["wsi_tomcat"]["instances"]["default"]["application"]["core"] = {
	"url" => managerCore,
	"final_name" => managerCoreName
}
node.default["wsi_tomcat"]["instances"]["default"]["application"]["manager"] = {
	"url" => manager,
	"final_name" => managerName
}
node.default["wsi_tomcat"]["instances"]["default"]["application"]["cidaAuth"] = {
	"url" => cidaAuth,
	"final_name" => cidaAuthName
}

#set up trust stores
node.default["wsi_tomcat"]["instances"]["default"]["service_definitions"] = [{
  "name" => "Catalina", 
  "thread_pool" => { "max_threads" => 200, "daemon" => "true", "min_spare_threads" => 25, "max_idle_time" => 60000 },
  "connector" => { "port" => 8080 },
  "ssl_connector" => { 
    "enabled" => true,
    "wsi_tomcat_keys_data_bag" => node["cida_auth"]["tomcat"]["wsi_tomcat_keys_config"]["data_bag_name"],
    "key_location" => node["cida_auth"]["tomcat"]["wsi_tomcat_keys_config"]["key_location"], # note: this feature relies on an encryption key being placed on the system before this recipe runs
  },
  "engine" => { "host" => [ "name" => "localhost" ] }
  }]

#turn off the manager
node.default["wsi_tomcat"]["disable_manager"] = true

# configure to download the jdbc driver
node.default["wsi_tomcat"]["lib_sources"] = [{
	"name" => node["cida_auth"]["jdbc_driver_filename"], 
	"url" => node["cida_auth"]["jdbc_driver_source"] 
}]

include_recipe "wsi_tomcat::default"

#if we are using the oracle driver, we have to bring in the oracle jar
jdbc_driver_class = node["cida_auth"]["jdbc_driver_class"]
if jdbc_driver_class == "oracle.jdbc.OracleDriver"
	# Bring in the needed ojdbc jar
	tomcat_home_dir = node["wsi_tomcat"]["user"]["home_dir"]
	tomcat_lib_dir = File.expand_path("lib", tomcat_home_dir)
	ojdbc_jar = "ojdbc6.jar"
	cookbook_file File.expand_path(ojdbc_jar, tomcat_lib_dir) do
	  source ojdbc_jar
	end
end

include_recipe "wsi_tomcat::deploy_application"
include_recipe "wsi_tomcat::download_libs"
include_recipe "wsi_tomcat::update_context"

include_recipe "iptables::default"

iptables_rule 'iptables_rule_tomcat_8080' do
  action :enable
end

iptables_rule 'iptables_rule_tomcat_8443' do
  action :enable
end