#!/bin/sh -eu

# we're not sure if systemd unit files have changed,
# so reload the daemon always, just in case
systemctl daemon-reload

if systemctl -q is-active opentaxii; then
    systemctl restart opentaxii
fi
