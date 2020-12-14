#!/bin/sh

clear

mkdir -p logs

kill $(pgrep nginx)

rm -Rf $PWD/logs/*

openresty -p $PWD -c $PWD/conf/nginx.conf -g "daemon off;"