#
# Cookbook:: wp-cb
# Recipe:: wordpress
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Descargamos el paquete de WordPress
remote_file '/tmp/wordpress.tar.gz' do
    source 'https://wordpress.org/latest.tar.gz'
    action :create
  end
  
  # Descomprimimos el paquete de WordPress
  bash 'extract_wordpress' do
    cwd '/tmp'
    code <<-EOH
    tar xzvf wordpress.tar.gz
    cp -R wordpress/* /var/www/html/
    EOH
    not_if { ::File.exists?("/var/www/html/wp-config.php") }
  end
  