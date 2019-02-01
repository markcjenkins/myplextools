#!/bin/sh
PROG=`basename $0`
VERSION="1.1"
DATABASE="/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"

#
## Functions
#
debug()
{
	if [ "$DEBUG" = "ON" ]
	then
		FDATE=`date +%D`
		TIME=`date +%T`

		D_TYPE=$1
		D_MSG=$2

		case "$D_TYPE" in
		"USAGE")	echo "$USAGE"; exit 0; ;;
		"ERROR")	echo "$PROG|$FDATE|$TIME|$D_TYPE|$D_MSG|" | tee -a $LOGFILE; ;;
		"FATAL")	echo "$PROG|$FDATE|$TIME|$D_TYPE|$D_MSG|" | tee -a $LOGFILE; exit 1; ;;
		*)			echo "$PROG|$FDATE|$TIME|$D_TYPE|$D_MSG|" | tee -a $LOGFILE; ;;
		esac			
	fi
}

USAGE="$PROG: [-b database-file] [-d] [-l] [-i|-u] <title>...

===> 	Warning: Production database is used by default

	-b filename	Database File		
	-d		Enable Debug, Off by default
	-l		List Info for ALL Movies
	-i title(s)	Display Info for Title(s)
	-u title(s)	Update Date Added for Title(s)
	-v 		Version information
	-h|?		Display usage
"

export MODE="SINGLE"
export DEBUG="OFF"

while getopts b:i:u:dlvh? opt
do
	case "$opt" in
	b)		export DATABASE="$OPTARG"; ;;
	d)		export DEBUG="ON"; ;;
	v)		echo $VERSION; exit 0;;
	l)		export MODE="LIST"; ;;
	i)		export MODE="INFO"; shift $((OPTIND - 2)); ;;
	u)		export MODE="UPDATE"; shift $((OPTIND - 2)); ;;
	h|?)		echo "$USAGE"; exit 0; ;;
	esac
done

if [ $# -lt 1 ]
then
	echo "$PROG - some arguments required"
	exit 0
fi

# Validate existence of named database
if [ ! -f "$DATABASE" ]
then
	echo "$PROG: Cannot locate the database: $DATABASE"
	exit 1
fi

# Ensure sqlite3 is installed
if [ ! -f /usr/bin/sqlite3 ]
then
	echo "$PROG - Script requires 'sqlite3' to be installed..."
	exit 1
fi

debug START "$PROG Script Started"
debug INFO "Using Database: [$DATABASE]"

case "$MODE" in
LIST)		## List Movies Files and relevant data points
		debug LIST_MODE "Listing Movie Info"
		sqlite3 -column -header "$DATABASE" "SELECT id, metadata_type, title, title_sort, added_at, created_at, originally_available_at, year FROM metadata_items WHERE metadata_type = '1';"
		;;
INFO)		## Display Info for a particular TITLE
		debug INFO_MODE "Gathering Movie Info"
		for TITLE in "$@"
		do
			sqlite3  -column -header "$DATABASE" "SELECT id, title, added_at, created_at, originally_available_at FROM metadata_items WHERE metadata_type = '1' AND title = '$TITLE';"
		done
		;;
UPDATE)		## Update Date on Multiple Titles
		debug UPDATE_MODE "Updating Title(s)"
		for TITLE in "$@"
		do
			debug MULTIPLE_TITLES "Updating $TITLE"
			sqlite3 "$DATABASE" "UPDATE metadata_items SET added_at = originally_available_at WHERE metadata_type = '1' AND title = '$TITLE';"
		done
		;;
esac


debug STOP "$PROG Script Ended"

exit 0

