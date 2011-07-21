#!/bin/bash -i
# must use -i to enable COLUMNS varable

# configuration
MAX_FILE_NAME_LENGHT=14
BAR_CHAR=#

# auto calculated
SCRIPT_NAME=$(basename $0)
BAR=$(printf "%01000d" 0 | tr "0" "${BAR_CHAR}")

if [ -n $COLUMNS ]; then
    echo "No COLUMNS definition, USE 80 as default"
    COLUMNS=80
fi


OutputError() {
    echo "${SCRIPT_NAME}: error: $1"
}

OutputUsage() {
    # if $1 is not null
    if [ -n "$1" ]; then
    echo "Usage: ${SCRIPT_NAME} src dst"
        echo
        OutputError "$1"
    else
        echo "${SCRIPT_NAME}: a folder copy tool."
        echo "Usage:"
        echo "    ${SCRIPT_NAME} src dst"
    fi
    exit 1
}

Debug() {
    echo $@
}

OutputProgressBar() {
    # filename, percentage
    local bar_full_length
    local bar_current_length
    local line
    local bar
    # printf "%0${COLUMNS}d0" 0 | tr "0" "\b" # may have bug
    printf "\r"
    bar_full_length=$(( ${COLUMNS} - ${MAX_FILE_NAME_LENGHT} - 9))
    bar_current_length=$((${bar_full_length} * $2 / 100))
    line="%-${MAX_FILE_NAME_LENGHT}.${MAX_FILE_NAME_LENGHT}s [%-${bar_full_length}.${bar_current_length}s] %3d%%"
    printf "$line" $1 ${BAR} $2
}

FileSize() {
    #du -sb "$1" | cut -f1
    wc -c "$1" | cut -d' ' -f1
}

CopyFile1() {
    # (src, dst)
    BUFFER_SIZE=102400        # 10K
    BLOCK_SIZE=10240
    local file_size
    local block_index
    local total_blocks
    local block_count
    file_size=$(FileSize "$1")
    Debug "filesize of $1 is $file_size"
    if [ $file_size -le $BUFFER_SIZE ]; then
    OutputProgressBar "$1" 0
    cp "$1" "$2"
    OutputProgressBar "$1" 100
    echo
    else
    OutputProgressBar "$1" 0
    : > "$2"
    block_index=0
    total_blocks=$(($file_size / $BLOCK_SIZE + 1))
    block_count=$(($BUFFER_SIZE / $BLOCK_SIZE))
    while [ $block_index -lt $total_blocks ]; do
        dd count=$block_count \
        bs=$BLOCK_SIZE if="$1" skip="$block_index" \
        of="$2" seek="$block_index" &> /dev/null
        block_index=$(($BUFFER_SIZE / $BLOCK_SIZE + $block_index))
        OutputProgressBar "$1" $(($block_index * 100 / $total_blocks))
    done
    OutputProgressBar "$1" 100
    fi
}

# method 2
CopyFile() {
    # (src, dst)
    local file_size=$(FileSize "$1")
    OutputProgressBar "$1" 0
    : > "$2"
    cp "$1" "$2" &
    local cp_pid=$!
    while ps -p $cp_pid &> /dev/null; do
        OutputProgressBar "$1" $(($(FileSize "$2") * 100 / $file_size))
        sleep 0.01
    done
    OutputProgressBar "$1" 100
    echo
}



RecursivelyCopyFile() {
    # basename test, if qe
    local SRC=${1%/}
    local DST
    if [ -f "$SRC" ]; then
	# Debug "SRC is a file"
        if [ -d "$2" ]; then    # cp to a dir
            DST=${2%/}/$(basename "$SRC")
        elif [ -f "$2" ]; then   # cp to a file
            DST=$2
        elif [ -d $(dirname "$2") ]; then 
	    DST=$2
	else
            OutputUsage "destination doesn't exists"
            exit 1
        fi
	CopyFile "$SRC" "$DST"
    elif [ -d "$SRC" ]; then
	# Debug "SRC is a dir"
	if [ -d $(dirname "$2") ] && [ ! -e "$2" ]; then
	    mkdir "$2"
	fi
        if [ -d "$2" ]; then 	# dir to a dir inside
	    for f in $(ls -1 "$SRC"); do
		# Debug "f = $f"
		DST=${2%/}/$(basename "$f")
		# Debug "DST=$DST"
		
		RecursivelyCopyFile "$SRC/$f" "$DST"
	    done
	elif [ -e "$2" ]; then
	    OutputUsage "can't overwrite exsiting file"
	fi
    else
	OutputUsage "source doesn't exists or not supported"
	exit 1
    fi
#    if [ $(basename "$1") -ne $(basename "$2") ]; then
	#    :
#    fi
    # mkdir -p "$2"
    if [ -f "$1" ]; then
	    :
    fi

}




if [ $# -eq 0 ]; then
    OutputUsage
    exit 1
elif [ $# -lt 2 ]; then
    OutputUsage "no enough parameters"
    exit 1
elif [ "$1" -ef "$2" ]; then
    OutputUsage "you are joking...."
    exit
fi

# Debug "Column length ${COLUMNS}"
echo
RecursivelyCopyFile "$1" "$2"


echo ok
exit 0

for f in file1 file2 file3 file4; do
    i=1
    while [ $i -le 100 ]; do
        OutputProgressBar "$f" "$i"
        let "i += 1"
        sleep 0.01
    done
    echo
done
#for arg in "$@"; do
#    echo "$arg"
#done
echo
