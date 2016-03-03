#
# Cookbook Name:: cida-auth
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe "cida-auth::database"
include_recipe "cida-auth::appstack"