# This files contains functions for bash scripts

# function for output with timestamp
function echo_time() {
    echo '[' `date` ']'	"$1"

    if [ ! -z "$logfile_name" ]
    then
        echo '[' `date` ']'	"$1" >> log/$logfile_name
    fi
}
