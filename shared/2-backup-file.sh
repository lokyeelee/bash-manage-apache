#!/bin/bash
#This script back up files from remote servers.

#This script can work with cron. 
#You need to specify the remote server name in the cron job, e.g. run daily at 00:00
# 0 0 */1 * * backup.sh

#You can specify a log file to record the backup status. 
LOG_FILE="/var/http_backup/$(basename ${0}).log"

#Execute as root.
if [[ "${UID}" -ne 0 ]]
then
    echo 'Please run this script as a root user.' >&2
    exit 1
fi

#Check if remote servers are supplied to the script.
if [[ "${#}" -eq 0 ]]
then
    echo "Please specify the remote server: ${0} SERVER..." >&2
    exit 1
fi

#Specify the backup files.
FILES_TO_BACKUP='/home/vagrant/backupfile'

#Specify the backup timestamp.
TIMESTAMP=$(date +%F_%H:%M:%S)

#Specify the path to store the backup files.
mkdir -p "/var/http_backup/backup_${TIMESTAMP}"
BACKUP_DST="/var/http_backup/backup_${TIMESTAMP}"

#Track if any backup fail and indicate the result in the exit code
EXIT_STATUS=0

#Backup files.
for SERVER in "${@}"
do
    SERVER_BACKUP_DST="${BACKUP_DST}"

    #If there's more than one server supplied, create an individual directory to store the back up files for that server.
    if [[ "${#}" -gt 1 ]]
    then
        SERVER_BACKUP_DST="${BACKUP_DST}/${SERVER}"
        mkdir -p "${SERVER_BACKUP_DST}"
    fi

    for FILE in $(cat ${FILES_TO_BACKUP})
    do
        rsync -azR ${SERVER}:${FILE} ${SERVER_BACKUP_DST}

        #Check if backup is successful.
        #Can redirect the message to ${LOG_FILE}
        if [[ "${?}" -ne 0 ]]
        then
            echo "${TIMESTAMP} Fail to backup ${FILE} in ${SERVER} to ${SERVER_BACKUP_DST}"  >> ${LOG_FILE}
            EXIT_STATUS=1
            continue
        else
            echo "${TIMESTAMP} Backup ${FILE} in ${SERVER} to ${SERVER_BACKUP_DST} successfully." >> ${LOG_FILE}
            continue
        fi
    done
done

exit ${EXIT_STATUS}
