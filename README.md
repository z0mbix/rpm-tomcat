Tomcat RPM Build
================

This repo is for building a Tomcat RPM from the official tarball release.

- Installation directory: **/opt/tomcat**
- Log directory: **/var/log/tomcat**
- Settings file: **/etc/sysconfig/tomcat**


Tested with Tomcat 7 and 8 on CentOS 6.x

## Build Requirements

- CentOS 6.x
- curl
- fpm

## Package info

    Name        : tomcat                        Relocations: /
    Version     : 8.0.30                        Vendor: vagrant@dev.foo.bar
    Release     : 1                             Build Date: Sun 10 Jan 2016 21:51:22 UTC
    Install Date: (not installed)               Build Host: dev.foo.bar
    Group       : default                       Source RPM: tomcat-8.0.30-1.src.rpm
    Size        : 9610912                       License: Apache
    Signature   : (none)
    Packager    : David Wooldridge <zombie@zombix.org>
    URL         : http://tomcat.apache.org/
    Summary     : tomcat - Built from release apache-tomcat-8.0.30.tar.gz
    Description :
    tomcat - Built from release apache-tomcat-8.0.30.tar.gz

## Starting/Stopping Tomcat

    # service tomcat {start|stop|restart|status|version}

## TODO

- Implement RHEL/CentOS 7.x packaging with systemd unit file
- Test checksum after download