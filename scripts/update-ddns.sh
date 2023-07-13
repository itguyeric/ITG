#!/bin/sh
# dynamically update Digital Ocean DNS
# adapted from: https://salvatorelab.com/2020/10/how-to-point-a-domain-to-your-dynamic-home-ip-address/

TOKEN="dop_v1_62e56a39994ac52f52bde17a221157b99e2ef6f83962586669d25fe7df90ffc9"
DOMAIN="itguyeric.com"
RECORD_ID="304486033"
LOG_FILE="/var/log/ddns.log"

CURRENT_IPV4="$(dig +short myip.opendns.com @resolver1.opendns.com)"
LAST_IPV4="$(tail -1 $LOG_FILE | awk -F, '{print $2}')"

if [ "$CURRENT_IPV4" = "$LAST_IPV4" ]; then
    echo "IP has not changed ($CURRENT_IPV4)"
else
    echo "IP has changed: $CURRENT_IPV4"
    echo "$(date),$CURRENT_IPV4" >> "$LOG_FILE"
    curl -X PUT -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d '{"data":"'"$CURRENT_IPV4"'"}' "https://api.digitalocean.com/v2/domains/$DOMAIN/records/$RECORD_ID"
fi
