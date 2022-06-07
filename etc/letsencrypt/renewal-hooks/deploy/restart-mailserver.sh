#!/bin/sh
for domain in $RENEWED_DOMAINS; do
    if [ "$domain" = "mail.stefant.org" ]
    then
        systemctl reload postfix
        systemctl reload dovecot
    fi
done
