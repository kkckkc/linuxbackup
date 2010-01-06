source `dirname $(readlink -f $0)`/../etc/settings.conf

list() {
	cd $SNAPSHOT_FOLDER
	find . -maxdepth 2 -name "20*" -type d | awk -F / '{print $3}' | sort | uniq
	cd - > /dev/null
}

size() {
	cd $SNAPSHOT_FOLDER
	du -sh hourly/* daily/* weekly/*
	echo "--------------------------------------------------------------------"
	du -sh hourly daily weekly
	cd - > /dev/null
} 

log() {
	cd $SNAPSHOT_FOLDER

	find . -maxdepth 2 -name "20*" -type d -exec \
		stat --format "%n %i" {}/$1 \; 2> /dev/null | \
		sed 's:\./[a-z]*/::' | \
		sed 's:\([^/]*\)/\(.*\) \([0-9]*\):\1|\2|\3:' |
		sort | \
		awk -F "|" '$3 != old {print($1, $2); old = $3 }'

	cd - > /dev/null
}

ref() {
	cd $SNAPSHOT_FOLDER
	folder=`find . -maxdepth 2 -name "$1 $2" -type d | head -n 1`
	echo $SNAPSHOT_FOLDER/${folder:2}/$3
	cd - > /dev/null
}

view() {
	less "`ref $1 $2 $3`"
}

case $1 in
	list)   list;;
	size)   size;;
	log)   log $2;;
	ref)   ref $2 $3 $4;;
	view)   view $2 $3 $4;;
    *)    echo "Need to specify either list, size, log, ref";;
esac



