#
# Cookbook:: wp-cb
# Recipe:: apache
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package 'apache2' do
  action :install
end

service 'apache2' do
  action [:enable, :start]
end