dockerpkg
=========

Build docker packages for platforms not supported by get.docker.io (RHEL, etc). 

To make an RPM, do `make clean && make docker-rpm`

TODO
----
-  Get bash completion working for docker (possibly use something like this code https://git.centos.org/blob/rpms!docker.git/b28b51e15aa6779281060b1e61368d948730d0f4/SPECS!docker.spec#L99)
-  Put manpages in
-  See if it would be easier to contribute to get.docker.io
-  Jenkify this
