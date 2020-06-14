#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Run this script with bash -x (script name) to execute commands one a time

#/ Usage: ./simple-backup-creator.sh -k mysql_ -p backups -d medicine_shop
#/ 
#/ Description: Create a mysql database backup with a tail of 30 files
#/ Examples: (same as usage above)
#/ Options:
#/   --help: Display this help message
#/   -k|--filename_key: the main part of the file name, e.g.: mysql_ in mysql_backup_ 14.tar.gz
#/   -p|--path_to_backups: where the backups will be created, e.g.: /home/ted/site_backups
#/   -d|--database: the the name of the database to back up
#/

usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

filename_key='mysql_'
path_to_backups='./'
database=''
STEP=''
MAX_BACKUPS=30
EXISTING_BACKUPS=0

# get the named parameters
while [ "${1:-}" != "" ]; do
    case $1 in
        -k | --filename_key)    shift
                                filename_key=${1:-}
                                ;;
        -p | --path_to_backups) shift
                                path_to_backups=${1:-}
                                ;;
        -d | --database)	    shift
                                database=${1:-}
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

# tiny logging framework, logs have datetime stamps
DATEFILE='%Y-%m-%d_%H%M%S'
DATESTAMP='%Y-%m-%d %H:%M:%S'
mkdir -p 'logs'
readonly LOG_FILE="logs/$(basename "$0" .sh)-${filename_key}.log"
echo '' > "$LOG_FILE"
info()    { echo "[INFO]    $$ $*" | tee -a "$LOG_FILE" >&2 ; }
warning() { echo "[WARNING] $$ $*" | tee -a "$LOG_FILE" >&2 ; }
error()   { echo "[ERROR]   $$ $*" | tee -a "$LOG_FILE" >&2 ; }
fatal()   { echo "[FATAL]   $$ $*" | tee -a "$LOG_FILE" >&2 ; exit 1 ; }

# what to do when the script is interrupted, Ctrl+C, for example
function cleanup() { 
    # Restart services
    echo "Cleaning up $$"
    exit 0
}

# traps commands that exit with an error status
function onerror_handler() {
	ERROR_LINE=$1
	RETURN_CODE=$?
    case "$STEP" in
        "mysql_exists" )
            info "Failed to import the profile image, nothing more."
        ;;
        * )
            # Unkown error
            info "Return code $RETURN_CODE on line $ERROR_LINE"
            exit 17
        ;;
    esac
}

# and finally, the actual script
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
    trap 'cleanup $LINENO' INT
    trap 'onerror_handler $LINENO' ERR
    info "==== $(date +"$DATESTAMP") ===="
    info "Starting a new backup"
        
    mkdir -p "${path_to_backups}"
    
    # get the existing backup count
    BACKUPS=$(ls -ltU "${path_to_backups}" | grep -E "\b${filename_key}.*\.tar\.gz" || true)
	EXISTING_BACKUPS=$(echo "$BACKUPS" | wc -l)
    ELDEST_BACKUP=$(echo "$BACKUPS" | tail -n 1 | awk '{print $9}')
    info "Existing backups is ${EXISTING_BACKUPS}"
    
    # if more than max, delete the oldest
    if (( $EXISTING_BACKUPS > $MAX_BACKUPS ))
    then
    	# delete the oldest
		[ "${path_to_backups}/${ELDEST_BACKUP}" ] && rm -f "${path_to_backups}/${ELDEST_BACKUP}"
    fi
    
    # add a backup
    NEW_BACKUP_FILENAME="${filename_key}_$(date +"$DATEFILE")"
    info "Saving new backup as $NEW_BACKUP_FILENAME in ${path_to_backups}"
    mysqldump $database --result-file="${path_to_backups}/${NEW_BACKUP_FILENAME}"
    tar -czf "${path_to_backups}/${NEW_BACKUP_FILENAME}.tar.gz" -C "${path_to_backups}" "${NEW_BACKUP_FILENAME}"
    [ "${path_to_backups}/${NEW_BACKUP_FILENAME}" ] && rm -rf "${path_to_backups}/${NEW_BACKUP_FILENAME}"
fi
exit 0
