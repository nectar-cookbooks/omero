Overview
========

This cookbook contains a recipe for installing Omero server, and others will
be added for installing other components, in due course.

Prerequisites:
--------------

If you deploy using Chef Solo, you need to set 
`node['postgresql']['password']['postgres']` to a password for the database.  
(By default, the postgres cookbook wants to persist a randomly generated 
password in a node attribute ... which only works in Chef Server mode.)  
Refer to the postgres cookbook's README file for more details, and 
instructions on how to generate the password hash.

Attributes:
-----------

The following attributes control aspects of the Omero server installation:

* `node['omero']['install']` - The Omero installation directory; defaults to 
"/opt/omero".
* `node['omero']['user']` - The Omero service user name; defaults to "omero".
* `node['omero']['var']` - The Omero server's 'var' directory; defaults to 
"/var/omero".
* `node['omero']['db_user']` - The Omero server's postgres database account 
name; defaults to "db_user".
* `node['omero']['db_password']` - The Omero server's postgres database account 
password; defaults to "db_password".  THIS SHOULD BE CHANGED.
* `node['omero']['db_name']` - The Omero server's postgres database name; 
defaults to "omero_database".
* `node['omero']['root_password']` - The Omero root password; defaults to 
"omero_root_password".  THIS SHOULD BE CHANGED.

TO DO List
----------

* We are not yet doing anything about backup or firewalls.
* We are not yet configuring OMERO.web
* We are not attempting to configure advanced options such as LDAP, 
  OMERO.dropbox.
