#
# Cookbook:: wp-cb
# Recipe:: mysql
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package 'mysql-server' do
    action :install
  end
  
  service 'mysql' do
    action [:enable, :start]
  end