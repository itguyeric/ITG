# Start Docker-Compose Delayed

cd /srv
/usr/bin/docker-compose up -d nextcloud-db
sleep 15

/usr/bin/docker-compose up -d nextcloud unifi
sleep 15

/usr/bin/docker-compose up -d letsencrypt
