#!/bin/sh
CLDIR="$XDG_DATA_HOME/checklist"
FILE="$XDG_DATA_HOME/checklist/list"

[ ! -d $CLDIR ] && mkdir $CLDIR
[ ! -f $FILE ] && touch $FILE

usage() {
echo "Usage: cl [-c] [-[n|r|u] TASK]... [TASK]..."
    echo "  [TASK]		Check task"
    echo "  -c			Clear all checked tasks"
    echo "  -n [TASK]		Add new task"
    echo "  -r [TASK]		Uncheck task"
    echo "  -u [TASK]		Remove task"
    exit
}

[ "$1" == "-h" ] && usage && exit || [ "$1" == "--help" ] && usage && exit

# get list matches
CHK=""
getchk() {
    CHK="$1"
    X=1
    grep -i "\[$2\].*$CHK" $FILE > "$FILE.tmp"

    [ $(wc -l "$FILE.tmp" | cut -d' ' -f1) -eq 0 ] && return 1

    if [ $(wc -l "$FILE.tmp" | cut -d' ' -f1) -gt 1 ];
    then
	echo "Multiple matches!"
	cat "$FILE.tmp"
	echo "Make a pick: "
	read X
    fi
    CHK=$(cut -d$'\n' -f$X "$FILE.tmp" | sed "s/\[$2\] //")
}

repl() {
    cat "$FILE.tmp" > $FILE
}

# switch options
while getopts ":cn:u:r:" ARG; do
    case $ARG in
	c)
	    grep -v "\[X\]" $FILE > "$FILE.tmp"
	    cat "$FILE.tmp" > $FILE
	    ;;
	n) 
	    [ $(grep "\[.\] $OPTARG$" $FILE | wc -l | cut -d' ' -f1) -eq 0 ] && echo "[ ] $OPTARG" >> $FILE
	    ;;
	r)
	    getchk "$OPTARG" "X" || break
	    sed "s/\[X\] $CHK/\[ \] $CHK/g" $FILE > "$FILE.tmp"
	    echo "Unchecked: $CHK"
	    repl
	    ;;
	u)
	    getchk "$OPTARG" " " || break
	    grep -v "$CHK" $FILE > "$FILE.tmp" 
	    echo "Removed: $CHK"
	    repl
	    ;;
	*) 
	    echo "Invalid option"
	    usage
    esac
done

# mark checked options
shift $((OPTIND - 1))
for EL in $@; do
    getchk "$EL" " " || continue
    
    sed "s/\[ \] $CHK/\[X\] $CHK/g" $FILE > "$FILE.tmp"
    repl
    echo "Checked: $CHK"
done
rm -f "$FILE.tmp"

cat $FILE
