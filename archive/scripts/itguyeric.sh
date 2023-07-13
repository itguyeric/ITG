#!/bin/bash
# deploy WordPress Podman pod

export DB_ROOT=vo2eiB0giphai3Bei5
export DB_NAME=wordpressdb
export DB_USER=pressuser
export DB_PASS=Loh1Oep2hiedaanaiz

set -e # exit on most errors
podman pod stop itguyeric
podman pod rm itguyeric
#mkdir -p /var/lib/containers/{mysql,wordpress}

podman pod create -n itguyeric -p 8000:80

podman run --pod itguyeric --name wordpressdb -d --restart always --label "io.containers.autoupdate=registry" -e MYSQL_ROOT_PASSWORD=$DB_ROOT -e MYSQL_DATABASE=$DB_NAME -e MYSQL_USER=$DB_USER -e MYSQL_PASSWORD=$DB_PASS -v /var/lib/containers/mysql/itguyeric:/var/lib/mysql:Z docker.io/library/mysql

podman run --pod itguyeric --name wordpress -d --restart always --label "io.containers.autoupdate=registry" -e WORDPRESS_DB_HOST=127.0.0.1 -e WORDPRESS_DB_USER=$DB_USER -e WORDPRESS_DB_PASSWORD=$DB_PASS -e WORDPRESS_DB_NAME=$DB_NAME -v /var/lib/containers/wordpress/itguyeric:/var/www/html:Z docker.io/library/wordpress

#chown -R 33:33 /var/lib/containers/wordpress
#find /var/lib/containers/wordpress/ -type f -exec chmod 655 {} \; && find /var/lib/containers/wordpress/ -type d -exec chmod 755 {} \;
#systemctl reload nginx
