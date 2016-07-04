#!/bin/bash                                                                                                                          

#Input Variables                                                                                                                     
appname=$1
appdomain=$2
shuport=$3
redport=$(($shuport+1))
ajpport=$(($redport+1))

apphome=/usr/share/vhost/$appname
appconf=$apphome/conf

#Process                                                                                                                             
echo "Copying template install from /usr/share/tomcat-template into $apphome"
cp -pr /usr/share/tomcat-template $apphome

echo "Replacing variables in server.xml"
# in /usr/share/{app-name}/conf/server.xml                                                                                           
    # replace {shutdown-port} with Shutdown Port                                                                                     
    echo "  Shutdown port: $shuport"
    sed -i "s/{shutdown-port}/$shuport/" $appconf/server.xml

    # replace {ajp-port} with AJP Conn. Port                                                                                         
    echo "  AJP Connection Port: $ajpport"
    sed -i "s/{ajp-port}/$ajpport/" $appconf/server.xml

    # replace {redirect-port} with Redirect Port                                                                                     
    echo "  Redirect Port: $redport"
    sed -i "s/{redirect-port}/$redport/" $appconf/server.xml

    # replace {app-base} with {app-name}                                                                                             
    echo "  App Name: $appname"
    sed -i "s/{app-base}/$appname/" $appconf/server.xml

echo "Linking app bin to base bin"
ln -s /etc/rc.d/init.d/tomcat7 $apphome/bin/$appname

echo "Creating local app configuration file"
echo "#!/bin/bash                                                                                                                    
export CATALINA_HOME=/usr/share/tomcat7                                                                                              
export CATALINA_BASE=$apphome                                                                                                        
export CATALINA_PID=/var/run/$appname.pid                                                                                            
export TOMCAT_LOG=\${CATALINA_BASE}/logs/$appname-initd.log" > $appconf/$appname

echo "Linking local app conf to /etc/sysconfig/$appname"
ln -s $appconf/$appname /etc/sysconfig/$appname

echo "Linking to app source directory in /home/$appname"
ln -s /home/$appname $apphome/$appname

echo "Adding app entry to /etc/httpd/conf/workers.properties"
workers=/etc/httpd/conf/workers.properties
sed -i "s/\# end ajp ports/$appname=$ajpport\n\# end ajp ports/" $workers
echo "#$appname                                                                                                                      
worker.list=$appname                                                                                                                 
worker.balancer.balance_workers=$appname                                                                                             
worker.$appname.reference=worker.template                                                                                            
worker.$appname.host=localhost                                                                                                       
worker.$appname.port=\$($appname)                                                                                                    
worker.$appname.activation=A" >> $workers

echo "Creating app virtual host entry in /etc/httpd/vhost"
echo "<VirtualHost *:80>                                                                                                             
  ServerAdmin root@$appdomain                                                                                                        
  ServerName $appdomain                                                                                                              
  JkMount /* $appname                                                                                                                
  ErrorLog logs/${appname}_error_log                                                                                                 
</VirtualHost>" > /etc/httpd/vhost/$appname.conf

echo "restarting httpd"
service httpd --full-restart

echo $appname :: $appdomain :: ${shuport}, ${redport}, ${ajpport} > $apphome/metadata

echo "Complete. To start your app, run 'vhost --start $appname'"
