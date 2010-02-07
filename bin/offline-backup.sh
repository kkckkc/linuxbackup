#!/bin/bash

source $( dirname $(readlink -f $0) )/../etc/settings.conf

export RSYNC_PASSWORD=$OFFLINE_PASSWORD
rsync -v -a --filter="merge `dirname $0`/${RSYNC_FILTER_CONF}" \
	--delete --delete-excluded \
	--chmod=ugo=rwX \
	"$SOURCE" $OFFLINE_DESTINATION

