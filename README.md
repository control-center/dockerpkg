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

    For Example:
        mkdir /tmp/1.6.0
        cd /tmp/1.6.0
        wget http://cbs.centos.org/repos/virt7-testing/x86_64/os/Packages/docker-1.6.0-1.el7.x86_64.rpm
        rpm2cpio docker-1.6.0-1.el7.x86_64.rpm | cpio -idmv
        cdz dockerpkg
        rm -fr dockerpkg/{etc,usr}
        tar -C /tmp/1.6.0 -czf - etc usr | tar -C dockerpkg -xzf -


TODO
----
-  See if it would be easier to contribute to get.docker.io
-  Jenkify this

