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
enabled = node['omero']['web']['enabled']
web_frontend = node['omero']['web']['frontend']
web_port = node['omero']['web']['http_port']
web_configure = node['omero']['web']['configure']
web_recipe = node['omero']['web']['recipe']

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
    bin/omero config set omero.web.application_server "fastcgi-tcp"
    bin/omero config set omero.web.debug False
    bin/omero config set omero.web.server_list \
            '[["#{node['ipaddress']}", 4064, "omero"]]'
    EOH
end

if web_frontend then
  if web_frontend == 'apache' then
    web_recipe ||= 'apache2::default'
    ensite = 'a2ensite'
    dissite = 'a2dissite'
    http = node['apache']['dir']
  elsif web_frontend == 'nginx' then
    web_recipe ||= 'nginx::default'     
    ensite = 'nxensite'
    dissite = 'nxdissite'
    http = node['nginx']['dir']
  else 
    raise "Unsupported web frontend #{web_frontend}"
  end
  include_recipe web_recipe
  if web_configure then
    web_opts = "--system --http #{web_port}"
    bash 'omero-web-frontend' do
      cwd "#{omero_install}/OMERO.server"
      code <<-EOH
        sudo -u #{omero_user} bash -c "export HOME=/tmp ; bin/omero web config #{web_frontend} #{web_opts}" \
                > #{http}/sites-available/omero
        #{dissite} default
        #{ensite} omero
      EOH
    end
  end
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
