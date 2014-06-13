#
# Cookbook Name:: omero
# Recipe:: web
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

include_recipe 'omero::server'

omero_install = node['omero']['install']
omero_user = node['omero']['user']
omero_var = node['omero']['var']
enabled = node['omero']['web_enabled']

# If the server might be running, stop and disable it.
service 'omero-web' do
  pattern 'OMERO.server/var/django.pid'
  action [ :stop ] 
  only_if do ::File.exists?('/etc/init.d/omero-web') end
end

bash 'omero-web-configuration' do
  cwd "#{omero_install}/OMERO.server"
  user omero_user
  code <<-EOH
  bin/omero config set omero.web.application_server "fastcgi"
  bin/omero config set omero.web.debug False
  bin/omero web config nginx > /tmp/omero-nginx
  EOH
end

if platform_family?('debian') then
  rc_flavour = '-debian'
else
  rc_flavour = ''
end

template '/etc/init.d/omero-web' do
  source "omero-web-init#{rc_flavour}.erb"
  mode 0755
  variables({
     :omero_user => omero_user,
     :omero_home => "#{omero_install}/OMERO.server"
  })            
end

service 'omero-web' do
  pattern 'OMERO.server/var/django.pid'
  action enabled ? [ :enable, :start ] : [ :disabled ]
end
