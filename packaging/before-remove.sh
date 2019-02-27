#!/bin/sh -eu

service=opentaxii

systemctl stop $service.service
systemctl disable $service.service
