#/bin/bash
# update and redeploy Podman environment

# define variables
export USEUID=1000
export USEGID=1000
export PODDIR=/var/lib/containers

# pull images
podman pull docker.io/plexinc/pms-docker
podman pull docker.io/didstopia/starbound-server
podman pull docker.io/felddy/foundryvtt
podman pull docker.io/gitlab/gitlab-ce
podman pull docker.io/felddy/foundryvtt
podman pull docker.io/itzg/minecraft-bedrock-server
podman pull docker.io/itzg/minecraft-server
podman pull docker.io/library/mariadb
podman pull docker.io/library/memcached
podman pull docker.io/library/mysql
podman pull docker.io/library/wordpress
podman pull docker.io/lloesche/valheim-server
podman pull docker.io/oznu/homebridge
podman pull docker.io/plexinc/pms-docker
podman pull ghcr.io/mrprimate/ddb-proxy
podman pull lscr.io/linuxserver/bazarr
podman pull lscr.io/linuxserver/calibre
podman pull lscr.io/linuxserver/lidarr
podman pull lscr.io/linuxserver/nzbget
podman pull lscr.io/linuxserver/radarr
podman pull lscr.io/linuxserver/sonarr 

# pod build
cd /etc/systemd/system

## calibre
systemctl stop pod-calibre
rm -f pod-calibre.service container-calibre-calibre.service
podman pod stop calibre
podman pod rm calibre
podman kube play ~/git/itg-lab/podman/calibre.yml
podman generate systemd -n -f calibre

## ddb-proxy
systemctl stop pod-ddb-proxy
rm -f pod-ddb-proxy.service container-ddb-proxy-ddb-app.service
podman pod stop ddb-proxy
podman pod rm ddb-proxy
podman kube play ~/git/itg-lab/podman/ddb-proxy.yml
podman generate systemd -n -f ddb-proxy

## foundry
systemctl stop pod-foundry
rm -f pod-foundry.service container-foundry-vtt.service
podman pod stop foundry
podman pod rm foundry
podman kube play ~/git/itg-lab/podman/foundry.yml
podman generate systemd -n -f foundry

## gitlab
systemctl stop pod-gitlab
rm -f pod-gitlab.service container-gitlab-gitlab-app-gitlab.service
podman pod stop gitlab
podman pod rm gitlab
podman kube play ~/git/itg-lab/podman/gitlab.yml
podman generate systemd -n -f gitlab

## homebridge
systemctl stop pod-homebridge
rm -f pod-homebridge.service container-homebridge.service
podman pod stop homebridge
podman pod rm homebridge
podman kube play ~/git/itg-lab/podman/homebridge.yml
podman generate systemd -n -f homebridge

## itguyeric
systemctl stop pod-itguyeric
rm -f pod-itguyeric.service container-itguyeric-wordpress.service container-itguyeric-wordpressdb.service
podman pod stop itguyeric
podman pod rm itguyeric
podman kube play ~/git/itg-lab/podman/itguyeric.yml
podman generate systemd -n -f itguyeric

## mc-bedrock
systemctl stop pod-mc-bedrock
rm -f pod-mc-bedrock.service container-mc-bedrock-bedrock.service
podman pod stop mc-bedrock
podman pod rm mc-bedrock
podman kube play ~/git/itg-lab/podman/mc-bedrock.yml
podman generate systemd -n -f mc-bedrock

## minecraft
systemctl stop pod-minecraft
rm -f pod-minecraft.service container-minecraft-minecraft.service
podman pod stop minecraft
podman pod rm minecraft
podman kube play ~/git/itg-lab/podman/minecraft.yml
podman generate systemd -n -f minecraft

## plex
systemctl stop container-plex
rm -f container-plex.service
podman stop plex
podman rm plex
podman run -d --name plex --label "io.containers.autoupdate=registry" --device=/dev/dri:/dev/dri --network=host -e PUID=1000 -e PGID=1000 -e TZ="America/Chicago" -h ITG -v /var/lib/containers/plex/config:/config/Library/Application\ Support/Plex\ Media\ Server:z -v /media:/data -v /var/lib/containers/plex/transcode:/transcode:z docker.io/plexinc/pms-docker
podman generate systemd plex --files --name

## seafile
systemctl stop pod-seafile
rm -f pod-seafile.service container-seafile-app.service container-seafile-elasticsearch.service container-seafile-memcached.service container-seafile-mysql.service
podman pod stop seafile
podman pod rm seafile
podman kube play ~/git/itg-lab/podman/seafile.yml
podman generate systemd -n -f seafile

## starbound
# systemctl stop pod-starbound
# rm -f pod-starbound.service container-starbound-starbound-server.service
# podman pod stop starbound
# podman pod rm starbound
# podman kube play ~/git/itg-lab/podman/starbound.yml
# podman generate system -n -f starbound

## valheim
systemctl stop pod-valheim
rm -f pod-valheim.service container-valheim-valheim-valheim-app.service
podman pod stop valheim
podman pod rm valheim
podman kube play ~/git/itg-lab/podman/valheim.yml
podman generate systemd -n -f valheim 

## usenet
systemctl stop pod-usenet
rm -f pod-usenet.service container-radarr.service container-sonarr.service container-bazarr.service container-lidarr.service container-nzbget.service
podman pod stop usenet
podman pod rm usenet
podman pod create --name usenet -p 1900:1900 -p 5353:5353 -p 6767:6767 -p 6789:6789 -p 7878:7878 -p 8686:8686 -p 8989:8989 -p 9091:9091 -p 32469:32469
/usr/bin/podman run -d --name bazarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/bazarr:/config:z -v /media/movies:/movies -v /media/tv:/tv lscr.io/linuxserver/bazarr
/usr/bin/podman run -d --name lidarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/lidarr:/config:z -v /media/downloads:/downloads -v /media:/media lscr.io/linuxserver/lidarr
/usr/bin/podman run -d --name nzbget --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/nzbget:/config:z -v /media/downloads:/downloads -v /media:/media lscr.io/linuxserver/nzbget
/usr/bin/podman run -d --name radarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/radarr:/config:z -v /media/downloads:/downloads -v /media:/media lscr.io/linuxserver/radarr
#/usr/bin/podman run -d --name readarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/readarr:/config:z -v /media/downloads:z -v /media/books:/books lscr.io/linuxserver/readarr 
/usr/bin/podman run -d --name sonarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/sonarr:/config:z -v /media/downloads:/downloads -v /media:/media lscr.io/linuxserver/sonarr
podman generate systemd -n -f usenet

# deployment
chcon --reference=nginx.service.d pod-*.service container-*.service
systemctl daemon-reload
systemctl enable --now container-plex.service
systemctl enable --now pod-calibre.service
systemctl enable --now pod-ddb-proxy.service
systemctl enable --now pod-foundry.service
systemctl enable --now pod-gitlab.service
systemctl enable --now pod-homebridge.service
systemctl enable --now pod-itguyeric.service
systemctl enable --now pod-mc-bedrock.service
systemctl enable --now pod-minecraft.service
systemctl enable --now pod-seafile.service
#systemctl enable --now pod-starbound.service
systemctl enable --now pod-valheim.service
systemctl enable --now pod-usenet.service
systemctl restart nginx.service

# cleanup
podman image prune -f

