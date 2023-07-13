#podman pod create -n seafile -p 8006:80

#podman run --pod seafile --name=seafile-mysql -d --restart always --label io.containers.autoupdate=registry -e MYSQL_ROOT_PASSWORD=Amniotic2-Blustery-Drainage-Detail -e MYSQL_LOG_CONSOLE=true -v /var/lib/containers/mysql/seafile:/var/lib/mysql docker.io/library/mariadb:latest

#podman run --pod seafile --name=seafile-memcached -d --restart always --label io.containers.autoupdate=registry docker.io/library/memcached:latest

#podman run --pod seafile --name=seafile-elasticsearch -d --restart always --label io.containers.autoupdate=registry -e discovery.type=single-node -e bootstrap.memory_lock=true -v /var/lib/containers/seafile/elasticsearch:/usr/share/elasticsearch/data docker.elastic.co/elasticsearch/elasticsearch:7.17.10

#sleep 30

podman run --pod seafile --name=seafile-app -d --restart always --label io.containers.autoupdate=registry -e DB_HOST=127.0.0.1 -e DB_ROOT_PASSWD=Amniotic2-Blustery-Drainage-Detail -e SEAFILE_ADMIN_EMAIL=eric@hendricks.life -e SEAFILE_ADMIN_PASSWORD=Crazily-Evasive1-Bruising-Unworn -e SEAFILE_SERVER_LETSENCRYPT=false -e SEAFILE_SERVER_HOSTNAME=seafile.itguyeric.com -v /var/lib/containers/seafile:/shared docker.seadrive.org/seafileltd/seafile-pro-mc:latest
