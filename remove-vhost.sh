#!/bin/bash                                                                                                                          

#Variables                                                                                                                           
appname=$1
apphome=/usr/share/vhost/$appname

#Process                                                                                                                             
vhost --stop $appname
rm $apphome/$appname
rm -r $apphome
rm /etc/sysconfig/$appname
rm /etc/httpd/vhost/$appname.conf

#Remove from workers.properties all lines containing $appname, including commented lines.                                            

perl -0777 -i.back -pe "s/\n[^\n]*$appname[^\n]*//g" /etc/httpd/conf/workers.properties

# sed -rni "1h; 1!H; ${ g; s/\n[^\n]+$appname[^\n]+//g p }" /etc/httpd/conf/workers.properties                                       
# sed -ni '1h; 1!H; ${ g; s/\n\#$appname//g p}' /etc/httpd/conf/workers.properties                                                   

service httpd --full-restart
