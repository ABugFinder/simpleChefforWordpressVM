#
# Cookbook:: wp-cb
# Recipe:: default
#
# Copyright:: 2023, The Authors, All Rights Reserved.

include_recipe 'wp-cb::apache'
include_recipe 'wp-cb::php'
include_recipe 'wp-cb::mysql'
include_recipe 'wp-cb::wordpress'