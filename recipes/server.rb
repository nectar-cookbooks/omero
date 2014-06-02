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

if platform_family?('debian') then
  dependencies = [ 'zip', 'python2.7', 'python-matplotlib',
                   'python-numpy', 'python-tables', 'python-scipy',
                   'zeroc-ice35', 'postgresql', 'nginx', 'mencoder' ]
  use_pil_package = platform?('ubuntu') and 
    ( node['platform_version'] <=> '14.04') >= 0
else
  raise 'Platform not supported ...'
end

include_recipe 'postgres::default'

include_recipe 'java::default'

dependencies.each() do |pkg| 
  package pkg
end

if use_pil_package then
  package 'python-pil' do
  end
else 
  # If we can't install 'pil' from the package manager, build from source.
  include_recipe 'python::default'
  pip_build_deps = ['python-dev', 'libjpeg-dev', 'libfreetype6-dev', 
                    'zlib1g-dev']
  pip_build_deps.each() do |pkg|
    package pkg do
    end
  end
  python_pip 'pil' do
  end
end

directory "/opt/omero" do
end

version = '5.0.1'
build = 'OMERO.server-5.0.1-ice35-b21'

remote_file "/opt/omero/#{build}.zip" do
  source "http://downloads.openmicroscopy.org/omero/#{version}/artifacts/#{build}.zip"
  action :create_if_missing
end

bash "unpack" do
  code "unzip #{build}.zip"
  cwd "/opt/omero"
  not_if do ::File.exists?("/opt/omero/#{build}") end
end

link "/opt/omero/OMERO.server" do
  to "/opt/omero/#{build}"
  link_type :symbolic
end

bash 'init-omero-database' do
  user 'postgres'
  code <<-EOH
  psql -d postgres -c "create user db_user with password 'db_password';"
  createdb -O db_user omero_database
  createlang plpgsql omero_database
  EOH
end

user 'omero' do
  comment 'Omero service user'
  home '/var/omero'
  system true
  shell '/bin/false'
  supports { :manage_home => true }
end

