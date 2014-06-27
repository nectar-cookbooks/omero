node.default['omero']['release'] = 
  "http://downloads.openmicroscopy.org/omero/5.0.1/artifacts/OMERO.server-5.0.1-ice35-b21.zip"
node.default['omero']['install'] = '/opt/omero'
node.default['omero']['user'] = 'omero'
node.default['omero']['var'] = '/var/omero'
node.default['omero']['db_user'] = 'db_user'
node.default['omero']['db_password'] = 'db_password'
node.default['omero']['db_name'] = 'omero_database'
node.default['omero']['root_password'] = 'omero_root_password'

# The 'web' recipes use this to determine whether the Omero web service
# is enabled / started or disabled / stopped by the recipe.
node.default['omero']['web']['enabled'] = true

# The choices will be nginx or apache
node.default['omero']['web']['frontend'] = 'nginx'

node.default['omero']['web']['http_port'] = 80

# The recipe used to install and configure the frontend webserver.  If unset,
# the 'web.rb' recipe intuits one based on the 'frontend' attribute.
node.default['omero']['web']['recipe'] = ''

# If this is true, we attempt to inject suitable reverse proxy configs into
# the frontend webserver configurations.
node.default['omero']['web']['configure'] = true

node.normal['java']['install_flavor'] = 'openjdk'
node.normal['java']['jdk_version'] = '7'
node.normal['java']['accept_license_agreement'] = true
