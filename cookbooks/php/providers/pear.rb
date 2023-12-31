#
# Author:: Seth Chisamore <schisamo@chef.io>
# Cookbook:: php
# Provider:: pear_package
#
# Copyright:: 2011-2017, Chef Software, Inc <legal@chef.io>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use_inline_resources

# the logic in all action methods mirror that of
# the Chef::Provider::Package which will make
# refactoring into core chef easy

use_inline_resources

def whyrun_supported?
  true
end

action :install do
  # If we specified a version, and it's not the current version, move to the specified version
  install_version = @new_resource.version unless @new_resource.version.nil? || @new_resource.version == @current_resource.version

  # If it's not installed at all or an upgrade, install it
  if install_version || @current_resource.version.nil?
    description = "install package #{@new_resource} #{install_version}"
    converge_by(description) do
      info_output = "Installing #{@new_resource}"
      info_output << " version #{install_version}" if install_version && !install_version.empty?
      Chef::Log.info(info_output)
      install_package(@new_resource.package_name, install_version)
    end
  end
end

action :upgrade do
  if @current_resource.version != candidate_version
    orig_version = @current_resource.version || 'uninstalled'
    description = "upgrade package #{@new_resource} version from #{orig_version} to #{candidate_version}"
    converge_by(description) do
      Chef::Log.info("Upgrading #{@new_resource} version from #{orig_version} to #{candidate_version}")
      upgrade_package(@new_resource.package_name, candidate_version)
    end
  end
end

action :remove do
  if removing_package?
    description = "remove package #{@new_resource}"
    converge_by(description) do
      Chef::Log.info("Removing #{@new_resource}")
      remove_package(@current_resource.package_name, @new_resource.version)
    end
  end
end

action :purge do
  if removing_package?
    description = "purge package #{@new_resource}"
    converge_by(description) do
      Chef::Log.info("Purging #{@new_resource}")
      purge_package(@current_resource.package_name, @new_resource.version)
    end
  end
end

def removing_package?
  if @current_resource.version.nil?
    false # nothing to remove
  elsif @new_resource.version.nil?
    true # remove any version of a package
  elsif @new_resource.version == @current_resource.version
    true # remove the version we have
  else
    false # we don't have the version we want to remove
  end
end

def expand_options(options)
  options ? " #{options}" : ''
end

# these methods are the required overrides of
# a provider that extends from Chef::Provider::Package
# so refactoring into core Chef should be easy

def load_current_resource
  @current_resource = new_resource.class.new(new_resource.name)
  @current_resource.package_name(@new_resource.package_name)
  @bin = node['php']['pear']
  if pecl?
    Chef::Log.debug("#{@new_resource} smells like a pecl...installing package in Pecl mode.")
    @bin = node['php']['pecl']
  end
  Chef::Log.debug("#{@current_resource}: Installed version: #{current_installed_version} Candidate version: #{candidate_version}")

  unless current_installed_version.nil?
    @current_resource.version(current_installed_version)
    Chef::Log.debug("Current version is #{@current_resource.version}") if @current_resource.version
  end
  @current_resource
end

def current_installed_version
  @current_installed_version ||= begin
                                   version_check_cmd = "#{@bin} -d "
                                   version_check_cmd << " preferred_state=#{can_haz(@new_resource, 'preferred_state')}"
                                   version_check_cmd << " list#{expand_channel(can_haz(@new_resource, 'channel'))}"
                                   p = shell_out(version_check_cmd)
                                   response = nil
                                   response = grep_for_version(p.stdout, @new_resource.package_name) if p.stdout =~ /\.?Installed packages/i
                                   response
                                 end
end

def candidate_version
  @candidate_version ||= begin
                           candidate_version_cmd = "#{@bin} -d "
                           candidate_version_cmd << "preferred_state=#{can_haz(@new_resource, 'preferred_state')}"
                           candidate_version_cmd << " search#{expand_channel(can_haz(@new_resource, 'channel'))}"
                           candidate_version_cmd << " #{@new_resource.package_name}"
                           p = shell_out(candidate_version_cmd)
                           response = nil
                           response = grep_for_version(p.stdout, @new_resource.package_name) if p.stdout =~ /\.?Matched packages/i
                           response
                         end
end

def install_package(name, version)
  command = "printf \"\r\" | #{@bin} -d"
  command << " preferred_state=#{can_haz(@new_resource, 'preferred_state')}"
  command << " install -a#{expand_options(@new_resource.options)}"
  command << " #{prefix_channel(can_haz(@new_resource, 'channel'))}#{name}"
  command << "-#{version}" if version && !version.empty?
  pear_shell_out(command)
  manage_pecl_ini(name, :create, can_haz(@new_resource, 'directives'), can_haz(@new_resource, 'zend_extensions')) if pecl?
  enable_package(name)
end

def upgrade_package(name, version)
  command = "printf \"\r\" | #{@bin} -d"
  command << " preferred_state=#{can_haz(@new_resource, 'preferred_state')}"
  command << " upgrade -a#{expand_options(@new_resource.options)}"
  command << " #{prefix_channel(can_haz(@new_resource, 'channel'))}#{name}"
  command << "-#{version}" if version && !version.empty?
  pear_shell_out(command)
  manage_pecl_ini(name, :create, can_haz(@new_resource, 'directives'), can_haz(@new_resource, 'zend_extensions')) if pecl?
  enable_package(name)
end

def remove_package(name, version)
  command = "#{@bin} uninstall"
  command << " #{expand_options(@new_resource.options)}"
  command << " #{prefix_channel(can_haz(@new_resource, 'channel'))}#{name}"
  command << "-#{version}" if version && !version.empty?
  pear_shell_out(command)
  disable_package(name)
  manage_pecl_ini(name, :delete, nil, nil) if pecl?
end

def enable_package(name)
  execute "#{node['php']['enable_mod']} #{name}" do
    only_if { platform?('ubuntu') && ::File.exist?(node['php']['enable_mod']) }
  end
end

def disable_package(name)
  execute "#{node['php']['disable_mod']} #{name}" do
    only_if { platform?('ubuntu') && ::File.exist?(node['php']['disable_mod']) }
  end
end

def pear_shell_out(command)
  p = shell_out!(command)
  # pear/pecl commands return a 0 on failures...we'll grep for it
  p.invalid! if p.stdout.split('\n').last =~ /^ERROR:.+/i
  p
end

def purge_package(name, version)
  remove_package(name, version)
end

def expand_channel(channel)
  channel ? " -c #{channel}" : ''
end

def prefix_channel(channel)
  channel ? "#{channel}/" : ''
end

def extension_dir
  @extension_dir ||= begin
                       # Consider using "pecl config-get ext_dir". It is more cross-platform.
                       # p = shell_out("php-config --extension-dir")
                       p = shell_out("#{node['php']['pecl']} config-get ext_dir")
                       p.stdout.strip
                     end
end

def get_extension_files(name)
  files = []

  p = shell_out("#{@bin} list-files #{name}")
  p.stdout.each_line.grep(/^src\s+.*\.so$/i).each do |line|
    files << line.split[1]
  end

  files
end

def manage_pecl_ini(name, action, directives, zend_extensions)
  ext_prefix = extension_dir
  ext_prefix << ::File::SEPARATOR if ext_prefix[-1].chr != ::File::SEPARATOR

  files = get_extension_files(name)

  extensions = Hash[
               files.map do |filepath|
                 rel_file = filepath.clone
                 rel_file.slice! ext_prefix if rel_file.start_with? ext_prefix
                 zend = zend_extensions.include?(rel_file)
                 [(zend ? filepath : rel_file), zend]
               end
  ]

  directory node['php']['ext_conf_dir'] do
    owner 'root'
    group 'root'
    mode '0755'
    recursive true
  end

  template "#{node['php']['ext_conf_dir']}/#{name}.ini" do
    source 'extension.ini.erb'
    cookbook 'php'
    owner 'root'
    group 'root'
    mode '0644'
    variables(name: name, extensions: extensions, directives: directives)
    action action
  end
end

def grep_for_version(stdout, package)
  v = nil

  stdout.split(/\n/).grep(/^#{package}\s/i).each do |m|
    # XML_RPC          1.5.4    stable
    # mongo   1.1.4/(1.1.4 stable) 1.1.4 MongoDB database driver
    # Horde_Url -n/a-/(1.0.0beta1 beta)       Horde Url class
    # Horde_Url 1.0.0beta1 (beta) 1.0.0beta1 Horde Url class
    v = m.split(/\s+/)[1].strip
    v = if v.split(%r{/\//})[0] =~ /.\./
          # 1.1.4/(1.1.4 stable)
          v.split(%r{/\//})[0]
        else
          # -n/a-/(1.0.0beta1 beta)
          v.split(%r{/(.*)\/\((.*)/}).last.split(/\s/)[0]
        end
  end
  v
end

def pecl?
  @pecl ||=
    begin
      # search as a pear first since most 3rd party channels will report pears as pecls!
      search_args = ''
      search_args << " -d preferred_state=#{can_haz(@new_resource, 'preferred_state')}"
      search_args << " search#{expand_channel(can_haz(@new_resource, 'channel'))} #{@new_resource.package_name}"

      if    grep_for_version(shell_out(node['php']['pear'] + search_args).stdout, @new_resource.package_name)
        false
      elsif grep_for_version(shell_out(node['php']['pecl'] + search_args).stdout, @new_resource.package_name)
        true
      else
        raise "Package #{@new_resource.package_name} not found in either PEAR or PECL."
      end
    end
end

# TODO: remove when provider is moved into Chef core
# this allows PhpPear to work with Chef::Resource::Package
def can_haz(resource, attribute_name)
  resource.respond_to?(attribute_name) ? resource.send(attribute_name) : nil
end
