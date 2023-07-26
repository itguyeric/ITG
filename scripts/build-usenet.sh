#/bin/bash
# Creates a pod for Plex and associated services

printf "\nDefining Variables...\n\n"
export USEUID=1000
export USEGID=1000
export PODDIR=/var/lib/containers

printf "\nCleaning up...\n\n"
/bin/systemctl stop pod-usenet.service
#/bin/systemctl stop container-plex.service
#/usr/bin/podman stop plex
#/usr/bin/podman rm plex
/usr/bin/podman pod stop usenet
/usr/bin/podman pod rm usenet
#/usr/bin/podman rmi -a -f
#rm -f /etc/systemd/system/container* /etc/systemd/system/pod-*.service

#printf "\nCreating users...\n\n"
#/usr/sbin/groupadd -g $USEGID plex
#/usr/sbin/useradd -M -u $USEUID -g $USEGID -c "Plex Service Account" plex

#printf "\nCreating folders...\n\n"
#/usr/bin/mkdir -p /media/{books,movies,music,pictures,tvshows,youtube}
#/usr/bin/mkdir -p /media/downloads/{completed,incomplete}
#/usr/bin/mkdir -p /var/lib/containers/{bazarr,lidarr,nzbget,radarr,plex,sonarr}

#printf "\nEnabling NFS for Podman...\n\n"
#/usr/bin/sed -i "/mount_program \=/s/^#//g" /etc/containers/storage.conf
#podman system reset -f

printf "\nPulling images...\n\n"
#/usr/bin/podman pull docker.io/plexinc/pms-docker
/usr/bin/podman pull lscr.io/linuxserver/bazarr
/usr/bin/podman pull lscr.io/linuxserver/lidarr
/usr/bin/podman pull lscr.io/linuxserver/nzbget 
/usr/bin/podman pull lscr.io/linuxserver/radarr
/usr/bin/podman pull lscr.io/linuxserver/readarr
/usr/bin/podman pull lscr.io/linuxserver/sonarr

printf "\nCreating pod...\n\n"
/usr/bin/podman pod create --name usenet -p 1900:1900 -p 5353:5353 -p 6767:6767 -p 6789:6789 -p 7878:7878 -p 8686:8686 -p 8787:8787 -p 8989:8989 -p 9091:9091
#/usr/bin/podman pod create --name plex --network=host

printf "\nPulling containers...\n\n"
/usr/bin/podman run -d --name bazarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/bazarr:/config:z -v /media/movies:/movies -v /media/tv:/tv lscr.io/linuxserver/bazarr                          
/usr/bin/podman run -d --name lidarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/lidarr:/config:z -v /media/downloads:/downloads -v /media:/media lscr.io/linuxserver/lidarr                  
/usr/bin/podman run -d --name nzbget --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/nzbget:/config:z -v /media/downloads:/downloads -v /media:/media lscr.io/linuxserver/nzbget                
/usr/bin/podman run -d --name radarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/radarr:/config:z -v /media/downloads:/downloads -v /media:/media lscr.io/linuxserver/radarr                
/usr/bin/podman run -d --name readarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/readarr:/config:z -v /media/downloads:/downloads -v /media/books:/books lscr.io/linuxserver/readarr:develop 
/usr/bin/podman run -d --name sonarr --pod usenet --label "io.containers.autoupdate=registry" -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -v $PODDIR/usenet/sonarr:/config:z -v /media/downloads:/downloads -v /media:/media lscr.io/linuxserver/sonarr
#/usr/bin/podman run -d --name plex --label "io.containers.autoupdate=registry" --device=/dev/dri:/dev/dri --network=host -e PLEX_CLAIM=$1 -e PUID=1000 -e PGID=1000 -e TZ="America/Chicago" -h ITG -v /var/lib/containers/plex/config:/config/Library/Application\ Support/Plex\ Media\ Server:z -v /media:/data -v /var/lib/containers/plex/transcode:/transcode:z docker.io/plexinc/pms-docker
#/usr/bin/podman run -d --name plex-app --pod plex --label "io.containers.autoupdate=registry" --device=/dev/dri:/dev/dri -e PUID=$USEUID -e PGID=$USEGID -e TZ="America/Chicago" -e PLEX_CLAIM=$1 -v $PODDIR/plex:/config/Library/Application\ Support/Plex\ Media\ Server/:z -v /media:/data -v $PODDIR/plex/transcode:/transcode:z docker.io/plexinc/pms-docker

printf "\nConfiguring services...\n\n"
/usr/bin/podman generate kube usenet > ~/git/itg-lab/podman/pod-usenet.yaml
#mv -f ./pod-usenet.yaml /media/configs/
/usr/bin/podman generate systemd -n -f usenet
#/usr/bin/podman generate systemd -n -f plex
mv -f ./pod-*.service /etc/systemd/system/
mv -f ./container-* /etc/systemd/system/
chcon --reference=/etc/systemd/system/basic.target.wants /etc/systemd/system/pod-*.service
chcon --reference=/etc/systemd/system/basic.target.wants /etc/systemd/system/container-*
systemctl daemon-reload
#systemctl enable --now container-plex.service
systemctl enable --now pod-usenet.service
printf "\nThats all folks...\n\n"
