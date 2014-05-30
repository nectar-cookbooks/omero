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
  dependencies = [ 'zip', 'python2.7', 'python-pil', 'python-matplotlib',
                   'python-numpy', 'python-tables', 'python-scipy',
                   'zero-ice', 'postgresql', 'nginx', 'mencoder' ]
else
  raise 'Platform not supported ...'
end

include_recipe 'java'

dependencies.each() do |pkg| 
  package pkg
end

directory "/opt/omero" do
  end

version = '5.0.1'
build = 'OMERO.server-5.0.1-ice35-b21'

remote_file "/opt/omero/#{build}.zip" do
  source "http://downloads.openmicroscopy.org/omero/#{version}/artifacts/#{build}.zip"
end

bash "unpack" do
  code "unzip #{build}.zip"
  cwd "/opt/omero"
end

link "/opt/omero/OMERO.server" do
  to "/opt/omero/#{build}"
  link_type :symbolic
end
