#
# Cookbook:: wp-cb
# Recipe:: mysql
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Agregar el repositorio de MySQL
#execute 'add_mysql_repo' do
#  command 'yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm'
#  not_if 'yum repolist enabled | grep mysql'
#end

package 'mysql-server' do
  action :install
end
  
service 'mysql' do
  action [:enable, :start]
end