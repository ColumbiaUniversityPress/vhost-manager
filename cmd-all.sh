#!/bin/bash                                                                                                                          
vhosts=/usr/share/vhost
for vhost in $vhosts/*; do
    name=${vhost:17}
    $vhost/bin/$name $1
done
