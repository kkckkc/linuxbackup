#!/bin/bash

source `dirname $(readlink -f $0)`/../etc/settings.conf

dateDiff () {
    case $1 in
        -s)   sec=1;      shift;;
        -m)   sec=60;     shift;;
        -h)   sec=3600;   shift;;
        -d)   sec=86400;  shift;;
        *)    sec=86400;;
    esac
    dte1=$(date --date "$1" +%s )
    dte2=$(date --date "$2" +%s )
    diffSec=$((dte2-dte1))
    if ((diffSec < 0)); then abs=-1; else abs=1; fi
    return $((diffSec/sec*abs))
}

# Set up directories
if [ ! -d "$SNAPSHOT_FOLDER" ]; then
    mkdir -p "$SNAPSHOT_FOLDER"
fi

mkdir -p "${SNAPSHOT_FOLDER}/daily"
mkdir -p "${SNAPSHOT_FOLDER}/hourly"
mkdir -p "${SNAPSHOT_FOLDER}/weekly"

if [ -d "${SNAPSHOT_FOLDER}/partial" ]; then
    # Clean aborted backups
    rm -rf "${SNAPSHOT_FOLDER}/partial"
fi
 
latest=`ls "${SNAPSHOT_FOLDER}/hourly" | grep "^20*" | sort -r | head -n 1`

if [ -n "$latest" ]; then
	rsync -v -a --filter="merge `dirname $0`/${RSYNC_FILTER_CONF}" \
		--delete --delete-excluded \
    	--link-dest="${SNAPSHOT_FOLDER}/hourly/${latest}" \
		"$SOURCE" "${SNAPSHOT_FOLDER}/partial/" > /tmp/rsync.log
else
	mkdir ~/.snapshots/partial
	rsync -v -a --filter="merge `dirname $0`/${RSYNC_FILTER_CONF}" \
		--delete --delete-excluded \
		"$SOURCE" "${SNAPSHOT_FOLDER}/partial/" > /tmp/rsync.log
fi

# Abort if rsync failed
if [ "$?" -ne "0" ]; then
	exit
fi

# Move partial folder to its right place
dest="${SNAPSHOT_FOLDER}/hourly/`date "+%Y-%m-%d %T"`"
mv "${SNAPSHOT_FOLDER}/partial" "$dest"

archive() {
	from=$1
	to=$2 
	age=$3
	latest_from=`ls $1 | grep "^20*" | sort -r | head -n 1`
	latest_to=`ls $2 | grep "^20*" | sort -r | head -n 1`
	if [ -n "$latest_to" ]; then
		dateDiff -h "now" "$latest_to"
		diff=$?
		if [ "$diff" -ge "$age" ]; then
			echo "Archiving $latest_from to $to"
			cp -al "$1/$latest_from" "$2/$latest_from"
		fi
	else
		echo "Archiving $latest_from to $to"
		cp -al "$1/$latest_from" "$2/$latest_from"
	fi
}

archive "${SNAPSHOT_FOLDER}/hourly" "${SNAPSHOT_FOLDER}/daily" 24
archive "${SNAPSHOT_FOLDER}/hourly" "${SNAPSHOT_FOLDER}/weekly" $[7*24]

# Remove all old backups
find "${SNAPSHOT_FOLDER}/hourly" -maxdepth 1 -type d \
	-name "20*" -ctime $HOURLY_MAX_AGE -exec rm -rf {} \;
find "${SNAPSHOT_FOLDER}/daily" -maxdepth 1 -type d \
	-name "20*" -ctime $DAILY_MAX_AGE -exec rm -rf {} \;
find "${SNAPSHOT_FOLDER}/weekly" -maxdepth 1 -type d \
	-name "20*" -ctime $WEEKLY_MAX_AGE -exec rm -rf {} \;

cp /tmp/rsync.log "$dest"

echo "Done"
