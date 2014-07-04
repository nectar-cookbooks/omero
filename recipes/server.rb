#
# Cookbook Name:: omero
# Recipe:: server
#
# Copyright (c) 2014, The University of Queensland
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# * Neither the name of the The University of Queensland nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE UNIVERSITY OF QUEENSLAND BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

omero_install = node['omero']['install']
omero_user = node['omero']['user']
omero_var = node['omero']['var']
db_user = node['omero']['db_user']
db_password = node['omero']['db_password']
db_name = node['omero']['db_name']
root_password = node['omero']['root_password']

BASE_URL = 'http://downloads.openmicroscopy.org/omero'
release = node['omero']['release']

unless %r{^((http|https)://.+/)?([^/]*)\.zip$} =~ release then
  raise "The release attribute should be a ZIP filename or url."
end
m1 = Regexp.last_match
build = m1[3]
unless %r{^[^-]*-([0-9.]+)(-ice[0-9]+)-(b[0-9]+)$} =~ build then
  raise "Cannot parse the release filename."
end
m2 = Regexp.last_match
version = m2[1]
ice = m2[2]
if m1[1] then
  url = release
else
  url = "#{BASE_URL}/#{version}/artifacts/#{build}.zip"
end

pips = []
if platform_family?('debian') then
  dependencies = [ 'zip', 'python2.7', 'python-matplotlib',
                   'python-numpy', 'python-scipy', 'python_tables',
                   "zeroc#{ice}", 'mencoder', 'postgresql' ]
  
  if platform?('ubuntu') && ( node['platform_version'] <=> '14.04') >= 0
    dependencies << 'python-pil'
  else
    pips = [ { 'module' => 'pil',
               'deps' => [ 'python-dev', 'libjpeg-dev', 'libfreetype6-dev', 
                           'zlib1g-dev' ]
             } ]
  end
    
elsif platform_family?('fedora') then
  dependencies = [ 'zip', 'unzip', 'python', 'python-devel', 'python_tables',
                   'python-pillow', 'python-matplotlib', 'numpy', 'scipy',
                   'ice', 'ice-python', 'ice-servers', 'mencoder', 
                   'postgresql-server' ]
  enable_rpmfusion_free = true

elsif platform_family?('rhel') then
  # Note that we are not installing any version of mencoder ...
  dependencies = [ 'zip', 'unzip', 'python', 'python-devel', 
                   'python-matplotlib', 'numpy', 'scipy',
                   'ice', 'ice-python', 'ice-servers' ]
  pips = [ { 'module' => 'pillow',
             'deps' => [ 'python-devel', 'libjpeg-devel', 'libtiff-devel', 
                         'zlib-devel' ]
           },
           { 'module' => 'numexpr',
             'version' => '1.4.2',
             'deps' => [],
           },
           { 'module' => 'tables',
             'version' => '2.4.0',
             'deps' => [ 'gcc', 'Cython', 'hdf5-devel' ]
           }
         ]
  enable_rpmfusion_free = true
  
  # Ugly way to add the ZeroC repo ...
  remote_file '/etc/yum.repos.d/zeroc-ice-el6.repo' do
    source 'http://download.zeroc.com/Ice/3.5/el6/zeroc-ice-el6.repo'
    not_if { ::File.exists?('/etc/yum.repos.d/zeroc-ice-el6.repo') }
  end

else
  raise "Platform / family not supported: #{node['platform']} / #{node['platform_family']}"
end

if enable_rpmfusion_free then
  # Fedora specific ...
  bash "enable rpmfusion" do
    code <<-EOF
    yum -y localinstall --nogpgcheck \
      http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm 
    EOF
  end
end

# For any platforms that have an old version of postgresql ...
if platform_family?('rhel') && node['platform_version'].to_f() < 7.0 then
  node.normal['postgresql']['version'] = '9.3'
  node.normal['postgresql']['enable_pgdg_yum'] = true
  node.normal['postgresql']['client']['packages'] = ["postgresql93"]
  node.normal['postgresql']['server']['packages'] = ["postgresql93-server"]
  node.normal['postgresql']['server']['service_name'] = "postgresql-9.3"
end

include_recipe 'postgresql::client'
include_recipe 'postgresql::server'

include_recipe 'java::default'

# Regular packages from the package repositories
dependencies.each() do |pkg| 
  package pkg
end

# Python packages that need to be 'pip' installed.
if pips.length > 0
  include_recipe 'python::default'
  pips.each() do |pip_data|
    pip_data['deps'].each() do |pkg|
      package pkg do
      end
    end
    python_pip pip_data['module'] do
      version pip_data['version'] if pip_data['version']
    end
  end
end

user omero_user do
  comment 'Omero service user'
  home omero_var
  system true
  shell '/bin/false'
  supports :manage_home => true
end

directory omero_install do
  owner omero_user
end

remote_file "#{omero_install}/#{build}.zip" do
  source url
  action :create_if_missing
end

# Shut down Omero / Omero.web while we fiddle with things ...
service 'omero-web-stop' do
  pattern 'OMERO.server/var/django.pid'
  service_name 'omero-web'
  action [ :stop ] 
  only_if do ::File.exists?('/etc/init.d/omero-web') end
end
service 'omero-stop' do
  service_name 'omero'
  pattern 'icegridnode'
  action [ :stop ] 
  only_if do ::File.exists?('/etc/init.d/omero') end
end

bash "unpack" do
  code "unzip #{build}.zip"
  cwd omero_install
  user omero_user
  not_if do ::File.exists?("#{omero_install}/#{build}") end
end

link "#{omero_install}/OMERO.server" do
  to "#{omero_install}/#{build}"
  link_type :symbolic
end

bash 'init-postgres-database' do
  user 'postgres'
  code <<-EOH
  psql -d postgres -c "create user #{db_user} with password '#{db_password}';"
  createdb -O #{db_user} #{db_name}
  # createlang plpgsql #{db_name}
  EOH
  not_if <<-EOH
  export PGPASSWORD=#{db_password}
  psql -h localhost -U #{db_user} -l | grep -l #{db_name}
  EOH
end

directory "#{omero_var}/data" do
  user omero_user
  mode 0750
end

# (For reasons that we don't understand, it is necessary to tell Ice
# to use the virtual's IP address as the default host.  This ought to
# happen without us saying so, but ...)
bash 'omero-configuration' do
  cwd "#{omero_install}/OMERO.server"
  user omero_user
  code <<-EOH
  bin/omero config set omero.db.name #{db_name}
  bin/omero config set omero.db.user #{db_user}
  bin/omero config set omero.db.pass #{db_password}
  bin/omero config set omero.data.dir #{omero_var}/data
  bin/omero config set Ice.Default.Host #{node['ipaddress']}
  EOH
end

# 
bash 'init-omero-db' do
  cwd "#{omero_install}/OMERO.server"
  user omero_user
  code <<-EOH
  export HOME=/tmp
  bin/omero db script "" "" #{root_password}
  export PGPASSWORD=#{db_password}
  psql -h localhost -U #{db_user} #{db_name} < OMERO5.0__0.sql
  EOH
  not_if do ::File.exists?("#{omero_install}/OMERO.server/OMERO5.0__0.sql") end
end

if platform_family?('debian') then
  rc_flavour = '-debian'
else
  rc_flavour = ''
end

template '/etc/init.d/omero' do
  source "omero-init#{rc_flavour}.erb"
  mode 0755
  variables({
     :omero_user => omero_user,
     :omero_home => "#{omero_install}/OMERO.server"
  })            
end

service 'omero' do
  pattern 'icegridnode'
  action [ :enable, :start ]
end
