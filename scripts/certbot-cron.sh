/usr/bin/podman pull docker.io/certbot/dns-digitalocean

/usr/bin/podman run -it --rm --name certbot \
	-v /etc/letsencrypt:/etc/letsencrypt:Z -v /var/lib/letsencrypt:/var/lib/letsencrypt:Z \
	certbot/dns-digitalocean certonly --non-interactive --agree-tos -m contact@itguyeric.com \
	-d itguyeric.com -d *.itguyeric.com --dns-digitalocean --dns-digitalocean-credentials /etc/letsencrypt/.do_creds.in

#podman run -it --rm --name certbot \
#	-v /etc/letsencrypt:/etc/letsencrypt:Z -v /var/lib/letsencrypt:/var/lib/letsencrypt:Z \
#	certbot/dns-digitalocean certonly --non-interactive --agree-tos -m contact@itguyeric.com \
#	-d opsrel.org -d *.opsrel.org --dns-digitalocean --dns-digitalocean-credentials /etc/letsencrypt/.do_creds.in

/usr/bin/systemctl reload nginx
