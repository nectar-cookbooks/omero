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

You need to open firewall access on ports 4063 and 4064 for
OMERO.service, and optionally ports 80 and 443 for Omero.web.  (If you 
use non-standard ports, adjust accordingly.)  

For a NeCTAR virtual, you need to open the external firewall ports using
the NeCTAR Dashboard:
1. Go to your project's "Access & Security" panel
2. Click "Edit Rules".
3. Click "Add Rule", fill in the port and then "Add".  
4. Repeat for each port you need to open.

Recipes:
--------

The `omero::server` recipe installs and configures OMERO.server according 
to the standard OMERO instructions.

The `omero::web` recipe runs the server recipe, and then installs and 
configures OMERO.web using Nginx as the front-end web-server.

The `omero::web-internal` recipe runs the server recipe, and then installs and 
configures Omero.web in development mode.  (The omero-web service is disabled,
and you need to run it by hand using ".../OMERO.server/bin/omero web start".)

Attributes:
-----------

The following attributes control the main OMERO installation recipe:

* `node['omero']['release']` - The OMERO release to be installed.  This can be either the URL for the OMERO.server downloadable, or its basename.  Note that this recipe only supports 5.x releases.
* `node['omero']['install']` - The OMERO installation directory; defaults to 
"/opt/omero".  The installation will be created as a subdirectory of this,
and an "OMERO.server" symlink will be created to the installation.
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

The following attributes control the OMERO web recipes:

* `node['omero']['web']['enabled']` - This tells the `omero::web` recipe to
enable or disable the `omero-web` init script; defaults to true.
* `node['omero']['web']['frontend']` - Select the frontend webserver.  
Currently, only 'nginx' is supported.
* `node['omero']['web']['http_port']` - Select frontend webserver's HTTP port;  
defaults to 80.
* `node['omero']['web']['recipe']` - Select the Chef recipe to use to install
the frontend webserver.  By default, we use the "standard" Chef Community 
cookbook.
* `node['omero']['web']['configure']` - If true, the web recipe will attempt 
to configure the frontend webserver on the assumption that it only needs to 
support Omero.web.  If false, we don't touch the frontend configuration.  
Defaults to true. 

Starting and stopping services
------------------------------

The recipe installs service scripts in "/etc/init.d" so that you can start
and stop the services.  The "omero" script is for the OMERO.service services,
and the "omero-web" script is for the OMERO.web services.

For example:

```
  $ sudo /etc/init.d/omero start      # starts the OMERO service
  $ sudo /etc/init.d/omero stop       # stops the OMERO service
  $ sudo /etc/init.d/omero restart    # stops and starts the OMERO service
```

Testing
-------

If the OMERO.server installation is working, you should be use OMERO.client
tools to talk to the server on (at least) port 4063 of the server, using the
server's external IP address or hostname.  (The OMERO.client tools can be
downloaded and installed on Windows, Mac and Linux machines.)

If the OMERO.web installation is working, you should be able to access the
OMERO web service using a web browser.  Use "http://<IP-address>/" as the URL,
where <IP> is the IP address of the server.  (If you have configured the server
to use a non-standard port, include that in the URL.)

In both cases, you can use the "root" account and password for initial testing.

More documentation
------------------

For more documentation, please refer to the relevant OMERO documention 
pages on their support site:

* http://www.openmicroscopy.org/site/support/omero5/

The installation documentation has various hints and links on checking
things are working, and diagnosing problems:

* http://www.openmicroscopy.org/site/support/omero5/sysadmins/unix/server-installation.html

Limitations
-----------

The cookbook only works on Ubuntu 14.04 ("trusty") at the moment, and 
only supports nginx as the webserver front-end.

TO DO List
----------

* We are not yet doing anything about backup or internal firewalls.
* We are not attempting to configure advanced options such as LDAP, 
  OMERO.dropbox, though apparently OMERO.dropbox is running ...
* Support for Omero.web needs more work / testing
* Support more OS platforms
* Support Apache web front-end.
* Support for SSL i.e. generating and configuring a certificate
* Support for updating Omero
* Support for rerunning with different usernames, passwords, etc.
* Support for installing clients
