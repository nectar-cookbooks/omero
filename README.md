Overview
========

This cookbook contains recipes for installing and configuring OMERO.server 
and OMERO.web.

Prerequisites:
--------------

If you deploy using Chef Solo, you need to set 
`node['postgresql']['password']['postgres']` to a password for the database.  
(By default, the postgres cookbook wants to persist a randomly generated 
password in a node attribute ... which only works in Chef Server mode.)  
Refer to the postgres cookbook's README file for more details, and 
instructions on how to generate the password hash.

Recipes:
--------

The `omero::server` recipe installs and configures OMERO.server according 
to the standard OMERO instructions.

The `omero::web` recipe runs the server recipe, and then installs and 
configures OMERO.web using Nginx as the front-end web-server.

The `omero::web-internel` recipe runs the server recipe, and then installs and 
configures Omero.web in development mode.  (The omero-web service is disabled,
and you need to run it by hand using ".../OMERO.server/bin/omero web start".)

Attributes:
-----------

The following attributes control aspects of the OMERO installation:

* `node['omero']['release']` - The OMERO release to be installed.  This can be either the URL for the OMERO.server downloadable, or its basename.  Note that this recipe only supports 5.x releases.
* `node['omero']['install']` - The OMERO installation directory; defaults to 
"/opt/omero".
* `node['omero']['user']` - The OMERO service user name; defaults to "omero".
* `node['omero']['var']` - The OMERO server's 'var' directory; defaults to 
"/var/omero".
* `node['omero']['db_user']` - The OMERO server's postgres database account 
name; defaults to "db_user".
* `node['omero']['db_password']` - The OMERO server's postgres database account 
password; defaults to "db_password".  THIS SHOULD BE CHANGED.
* `node['omero']['db_name']` - The OMERO server's postgres database name; 
defaults to "omero_database".
* `node['omero']['root_password']` - The OMERO root password; defaults to 
"omero_root_password".  THIS SHOULD BE CHANGED.
* `node['omero']['web_enabled']` - This tells the `omero::web` recipe to
enable or disable the `omero-web` init script; defaults to true.

Limitations
-----------

The cookbook only works on Ubuntu "trusty" at the moment, and only supports 
Nginx as the webserver front-end.

TO DO List
----------

* We are not yet doing anything about backup or firewalls.
* We are not attempting to configure advanced options such as LDAP, 
  OMERO.dropbox, though apparently OMERO.dropbox is running ...
* Support more platforms
* Support Apache web front-end.

