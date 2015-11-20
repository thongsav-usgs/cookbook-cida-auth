default["cida_auth"] = {
	"cida_auth_version" => "1.0.3",
	"schema_name" => "public",
	"db_connection" => "jdbc:postgresql://example.com:5432/example",
	"credentials_data_bag_name" => "cida_auth_credentials",
	"data_bag_encryption_key" => "/etc/chef/data-bag-encryption-key",
	"data_bag_username_field" => "username",
	"data_bag_password_field" => "password"
}
