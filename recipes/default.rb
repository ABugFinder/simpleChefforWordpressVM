#
# Cookbook:: wp-cb
# Recipe:: default
#
# Copyright:: 2023, The Authors, All Rights Reserved.

include_recipe 'mi_cookbook::apache'
include_recipe 'mi_cookbook::php'
include_recipe 'mi_cookbook::mysql'
include_recipe 'mi_cookbook::wordpress'