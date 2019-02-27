#!/bin/sh -eu

# create group and user if they do not already exist
user=opentaxii
if ! getent group "$user" >/dev/null; then
    groupadd $user
fi
if ! getent passwd "$user" >/dev/null; then
    useradd "$user" -s "$(command -v nologin)" -g "$user"
fi

logfile=/var/log/opentaxii.log
if [ ! -e "$logfile" ]; then
    touch "$logfile"
    chown $user:$user "$logfile"
    chmod 644 "$logfile"
fi
