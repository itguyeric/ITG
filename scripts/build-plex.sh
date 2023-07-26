# /bin/bash
# remove plex container and rebuild
systemctl stop container-plex
/usr/bin/podman pull docker.io/plexinc/pms-docker:latest
/usr/bin/podman stop plex 
/usr/bin/podman rm plex 
rm -f /etc/systemd/system/container-plex.service
/usr/bin/podman run -d --name plex --label "io.containers.autoupdate=registry" --device=/dev/dri:/dev/dri --network=host -e PLEX_CLAIM=$1 -e PUID=1000 -e PGID=1000 -e TZ="America/Chicago" -h ITG -v /var/lib/containers/plex/config:/config/Library/Application\ Support/Plex\ Media\ Server:z -v /media:/data -v /var/lib/containers/plex/transcode:/transcode:z docker.io/plexinc/pms-docker
cd /etc/systemd/system/
/usr/bin/podman generate systemd -f -n plex 
chcon --reference=default.target container-plex.service
/usr/bin/podman generate kube plex
mv ./plex.yaml /root/git/itg-lab/podman/
systemctl daemon-reload
/usr/bin/podman stop plex 
systemctl enable --now container-plex
echo "That's all folks!"
