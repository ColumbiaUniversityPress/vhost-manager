#!/bin/bash                                                                                                                          

vroot=/usr/share/vhost-manage

function list {
    for dir in /usr/share/vhost/*; do
        cat $dir/metadata
    done
}

function new {
    $vroot/new-vhost.sh $@
}

function remove {
    if [[ $# > 1 ]]; then
        for arg in $@; do
            $vroot/remove-vhost.sh $arg
        done
    else
        $vroot/remove-vhost.sh $@
    fi

}

function start {
    if [[ "$1" == "--all" ]]; then
        $vroot/cmd-all.sh start
    elif [[ $# ==  1 ]]; then
        /usr/share/vhost/$1/bin/$1 start
    else
        for arg in $@; do
            start-vhost $arg
        done
    fi
}

function stop {
    if [[ "$1" == "--all" ]]; then
        $vroot/cmd-all.sh stop
    elif [[ $# == 1 ]]; then
        /usr/share/vhost/$1/bin/$1 stop
    else
        for arg in $@; do
            stop-vhost $arg
        done
    fi
}

function restart {
    if [[ "$1" == "--all" ]]; then
        $vroot/cmd-all.sh restart
    elif [[ $# == 1 ]]; then
        /usr/share/vhost/$1/bin/$1 restart
    else
        for arg in $@; do
            restart-vhost $arg
        done
    fi
}

function vhosthelp {
    while read line; do
        echo "$line"
    done < $vroot/help.txt
}

cmd=$1
if [[ "$cmd" == "--list" || "$cmd" == "ls" ]]; then
    list
elif [[ "$cmd" == "--make" ]]; then
    new $2 $3 $4
elif [[ "$cmd" == "--remove" ]]; then
    remove $2
elif [[ "$cmd" == "--start" ]]; then
    start $2
elif [[ "$cmd" == "--stop" ]]; then
    stop $2
elif [[ "$cmd" == "--restart" ]]; then
    restart $2
else
    vhosthelp
fi
