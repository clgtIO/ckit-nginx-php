#!/bin/bash

service nginx start &

/usr/sbin/php-fpm7.4 -c /etc/php/7.4/fpm