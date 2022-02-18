#!/bin/sh
CLDIR="$XDG_DATA_HOME/checklist"
TMP="/tmp/cl.tmp"

[ ! -d $CLDIR ] && mkdir $CLDIR
[ ! -f "$CLDIR/list" ] && touch $FILE

usage() {
echo "Usage: cl [-c] [[OPTION] LIST:TASK]..."
    echo "  [LIST:TASK]			Check task"
    echo "  -c				Clear all checked tasks"
    echo "  -n [LIST:TASK]		Add new task"
    echo "  -r [LIST:TASK]		Uncheck task"
    echo "  -u [LIST:TASK]		Remove task"
    exit
}

case "$1" in
	"-h" | "--help")
		usage
		exit
		;;
esac

#file task is in
TASKFILE=""

#search input
SEARCH=""

#text of matched line
MATCH=""

#index of matched line
LINE=-1
gettask() {
	IFS=':' read TASKFILE SEARCH <<< "$1"

	[ "$SEARCH" == "" ] && SEARCH=$TASKFILE && TASKFILE=$(ls -d $CLDIR/* | grep -v '\.backup$') && MULTIFILE=1 || TASKFILE=$CLDIR/$TASKFILE

	[ $((MULTIFILE)) -eq 0 ] && [ ! -f $TASKFILE ] && touch "$TASKFILE"

	if [ "$2" == "N" ]; then
		[ $((MULTIFILE)) -eq 1 ] && TASKFILE=$CLDIR/list
		return $(grep "\[.\] $SEARCH$" $TASKFILE | wc -l)
	fi

	grep -Hn "\[$2\].*$SEARCH" $TASKFILE > $TMP

	MC=$(wc -l < $TMP)
	[ $MC -eq 0 ] && LINE=-1 && return 1
	
	SELEC=1
	if [ $MC -gt 1 ];
	then
		echo "Multiple matches!"
		cut -d':' -f1,3 $TMP | sed 's/.*\///'
		echo "Select one [1-$MC]: "
		read SELEC		
	fi

	IFS=':' read TASKFILE LINE MATCH <<< "$(sed -n $SELEC'p' $TMP)"
}

# OPTIONS
while getopts ":cn:u:r:t:" ARG; do
    case $ARG in
	c)
		for F in $(ls $CLDIR | grep -v "\.backup$");
		do
			sed -i "/\[X\].*/d" "$CLDIR/$F"
		done
	    ;;
	n) 
		gettask "$OPTARG" "N" && echo "[ ] $SEARCH" >> "$TASKFILE" && echo "Added: [ ] $SEARCH"
	    ;;
	r)
	    gettask "$OPTARG" "X" || break
	    sed -i $LINE"s/\[X/\[ /" "$TASKFILE"
	    echo "Unchecked: $MATCH"
	    ;;
	u)
	    gettask "$OPTARG" "." || break
		sed -i $LINE"d" "$TASKFILE"
	    echo "Removed: $MATCH"
	    ;;
	*) 
	    echo "Invalid option"
	    usage
    esac
done

# MARK
shift $((OPTIND - 1))
for EL in $@; do
	gettask "$EL" " " || continue

	sed -i $LINE"s/\[ /[X/" "$TASKFILE"
    echo "Checked: $MATCH"
done
rm -f "$TMP"

echo "list:"
cat $CLDIR/list
for L in $(ls $CLDIR | grep -vE "(^list$|\.backup$)");
do
	if [ $(wc -l < "$CLDIR/$L") -gt 0 ];
	then
		echo "$L:"
		cat "$CLDIR/$L"
	else
		rm "$CLDIR/$L"
	fi
done
