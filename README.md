dockerpkg
=========

Build docker packages for platforms not supported by get.docker.io (RHEL, etc). 

To make an RPM, do `make clean && make docker-rpm`

Updating Docker
---------------
To update the version of Docker (and this package), the following should be changed:
 1. Change the version in VERSION
 2. Revert the 'ITERATION' variable in the makefile back to '1'
 3. Pull and replace an updated bash completion script from the official Docker repo
 4. Review and (if necessary) pull in any systemd service changes in the official Docker repo

TODO
----
-  Put manpages in
-  See if it would be easier to contribute to get.docker.io
-  Jenkify this

