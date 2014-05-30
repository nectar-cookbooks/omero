omero
=====

Cookbook for installing Omero server

Prerequisites
=============

If you deploy using Chef Solo, you need to set `node['postgresql']['password']['postgres']` to a password for the database.  (By default, the postgres cookbook wants to persist a randomly generated password in a node attribute ... which only works in Chef Server mode.)  Refer to the postgres cookbook's README file for more details, and instructions on how to generate the password hash.

