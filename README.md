# vhost-manager
Scripts to ease the handling of multiple tomcat instances running behind an apache server on Amazon Linuz AMIs

TODO: Fix file permissioning so that this doesn't rely on /usr/share/tomcat-template in order to work.

# What is this?

The tomcat install on Amazon Linux AMIs is a little peculiar; it may be a fairly standard construction that experienced dev-ops engineers are familiar with, but it doesn't match the available online documentation for tomcat. It appears to be constructed in such a way that a user who intends to run multiple tomcat instances is expected to do this by creating individual directories for a given instance and symlinking various things therein to the source directory in /usr/share/tomcat7. It's relatively simple, but only if you script it. So I did.

## Installation

This relies on mod_jk to connect tomcat instances to apache. If you don't have it, you'll need it.

The simplest thing to do is going to be to just clone this repo into some directory on your AMI. Then add the following line to your `mod_jk.conf` or to a new file in `/etc/httpd/conf.d/` (say, vhosts.conf): `Include vhost/*.conf`, and create the folder `/etc/httpd/vhost/`. Finally, you will have to create the instance template in `/usr/share/tomcat-template`; the easiest way to do this is probably to just copy the `tomcat7` directory, but keep in mind that a bunch of symlinks may have to be replaced with real folders, and bunch of real files will have to be replaced with symlinks; for most of this you can reference the scripts themselves and find out what they need.

## Usage

Once it's installed, using it is as simple as navigating into the cloned `vhost-manager` directory, running `./vhost.sh --help`, and working out from there. If you want to avoid having to be in the directory in order to access the vhost manager you can just symlink it: `ln -s /path/to/vhost-namager/vhost.sh /somewhere/in/your/path/vhost`. Then it's available from anywhere as `vhost --help`. In some instances you may have to use `sudo` to install and use it.

## What's going on here?

Here's what it does right now when you call `./vhost.sh --make name domain port` (my notes verbatim from building the first instance of what would become a many-instance set-up.):

```
# First we have to copy the template dir
cp -pr /usr/share/tomcat-template /usr/share/vhost/{app-name}

each instance needs 3 ports:
Shutdown Port  (xxxx0)
Redirect Port  (xxxx1)
AJP Conn. Port (xxxx2)
in /usr/share/vhost/{app-name}/conf/server.xml
    replace {shutdown-port} with Shutdown Port
    replace {ajp-port} with AJP Conn. Port
    replace {redirect-port} with Redirect Port
    replace {app-base} with {app-name}

ln -s /etc/rc.d/init.d/tomcat7 /usr/share/vhost/{app-name}/bin/{app-name}

create file: /usr/share/vhost/{app-name}/conf/{app-name}
#!/bin/bash
export CATALINA_HOME=/usr/share/tomcat7
export CATALINA_BASE=/usr/share/vhost/{app-name}
export CATALINA_PID=/var/run/{app-name}.pid
export TOMCAT_LOG=${CATALINA_BASE}/logs/{app-name}-initd.log

ln -s /usr/share/vhost/{app-name}/conf/{app-name} /etc/sysconfig/{app-name}
ln -s /home/{app-name} /usr/share/vhost/{app-name}/{app-name}

add to worker.properties:
    under "ajp port for each servlet by name:":
        {app-name}={AJP Conn. Port}
    at end of file:
        worker.list.{app-name}
        worker.balancer.balance_workers={app-name}
        worker.{app-name}.reference=worker.template
        worker.{app-name}.host=localhost
        worker.{app-name}.port=$(draft)
        worker.{app-name}.activation=A

create file: /etc/httpd/vhost/{app-name}.conf
<VirtualHost *:80>
  ServerAdmin root@{app-domain}
  ServerName {app-domain}
  JkMount /* {app-name}
  ErrorLog logs/{app-name}_error_log
</VirtualHost>
```

The template dir in this case is a model for an instance with some important variables incomplete: '{app-name}' in place of the name of the app, for example. First, we copy it over to a folder with the name of our new application instance, and then we go through and replace a bunch of named positions with useful values. We assume that backing applications (.war files) will be placed in `/home/{app-name}/`, so we symlink to that. Then we add a new worker to `/etc/httpd/conf/worker.properties` and a new vhost file in `/etc/httpd/vhost/`.

## Problems

It relies on the tomcat-template directory, which you will have to create by hand. I'm going to fix this eventually, but I haven't yet, so ymmv.

Some parts of the underlying tomcat scripts (which I didn't write and have no control over) exhibit undesirable behavior. In particular, calling `vhost --start name` will try to start name; if something else is already running on ports that name needs, the start script will fail, but it will report success. You can double-check in a couple of ways. One is by calling `vhost --stop name`, which will report failure if name is not running. Another is to call `sudo netstat -tulpn` and look through the resulting list of ports in use; a given tomcat app created with this script will listen on the port you give it, and the port two above that. Here, I created one on port 10000 and started it, so I see the following in netstat:

```
tcp        0      0 ::ffff:127.0.0.1:10000      :::*                        LISTEN      15205/java                  
tcp        0      0 :::10002                    :::*                        LISTEN      15205/java          
```

Note that these lines will not always be nicely lined up; you may see `::ffff:127.0.0.1:10030` near the bottom of the list and `:::10032` near the top (or vice versa), but so long as you see them both somewhere, (and so long as you've chosen ports that other programs are unlikely to use) you can be reasonably certain that the tomcat instance in question is running.
