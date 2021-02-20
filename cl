#!/bin/sh
CLDIR="$XDG_DATA_HOME/checklist"
TMP="/tmp/cl.tmp"

[ ! -d $CLDIR ] && mkdir $CLDIR
[ ! -f "$CLDIR/list" ] && touch $FILE

usage() {
echo "Usage: cl [-c] [-[n|r|u] [LIST:]TASK]... [[LIST:]TASK]..."
    echo "  [[LIST:]TASK]			Check task"
    echo "  -c				Clear all checked tasks"
    echo "  -n [[LIST:]TASK]		Add new task"
    echo "  -r [[LIST:]TASK]		Uncheck task"
    echo "  -u [[LIST:]TASK]		Remove task"
    exit
}

case "$1" in
	"-h" | "--help")
		usage
		exit
		;;
esac

TASKFILE=""
SEARCH=""
MATCH=""
LINE=-1
# STATUS=' '
gettask() {
	#echo "ARG: $1"
	IFS=':' read -ra ARGS <<< "$1"
	#echo "SPLIT: ${ARGS[@]}"

	[ ${#ARGS[@]} -lt 2 ] && TASKFILE="$CLDIR/list" && SEARCH="${ARGS[0]}"
	[ ${#ARGS[@]} -gt 1 ] && TASKFILE="$CLDIR/${ARGS[0]}" && SEARCH="${ARGS[1]}"

	# echo FILE: "$TASKFILE"
	# echo SEARCH: "$SEARCH"

	[ ! -f "$TASKFILE" ] && read -p "No checklist \"$TASKFILE\" found. Create it? [Y/n] " P
	case $P in
		'n' | 'N') LINE=-1 && return 2 ;;
		*) touch "$TASKFILE" ;;
	esac

	[ "$2" = "Q" ] && return $(grep "\[.\] $SEARCH$" "$TASKFILE" | wc -l)

	grep -n "\[$2\].*$SEARCH" $TASKFILE > $TMP

	MC=$(wc -l < $TMP)

	[ $MC -eq 0 ] && LINE=-1 && return 1
	if [ $MC -gt 1 ];
	then
		echo "Multiple matches!"
		sed "s/^\w*://g" $TMP
		echo "Select one [1-$MC]: "
		read SELEC
		
		ML=$(sed -n $SELEC"p" $TMP)
		LINE=$(cut -d':' -f1 <<< "$ML")
		MATCH=$(cut -d':' -f2- <<< "$ML")
	else
		LINE=$(cut -d':' -f1 $TMP)
		MATCH=$(cut -d':' -f2- $TMP)
	fi

	# echo "MATCH: $MATCH"
	# echo "LINE:  $LINE"
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
		gettask "$OPTARG" "Q" && echo "[ ] $SEARCH" >> "$TASKFILE"
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

for L in $(ls $CLDIR | grep -v "\.backup$");
do
	if [ $(wc -l "$CLDIR/$L" | cut -d' ' -f1) -gt 0 ];
	then
		echo "$L:"
		cat "$CLDIR/$L"
	fi
done
