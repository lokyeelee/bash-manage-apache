#!/bin/bash
#This script checks and restarts down service locally.

#Run this script every 5 mins using cron: 
#*/5 * * * * /path/3-monitor-service.sh &>> /var/tmp/monitor-service.cronlog
#Any output from this script is sent to /var/tmp/monitor-service.cronlog

#Execute this script as root.
if [[ "${UID}" -ne 0 ]]
then
    echo 'Please execute this script with root privileges.' >&2
    exit 1
fi

#Load Telegram credentials.
source /home/vagrant/.telegram_bot.conf
#If Telegram credentials not found, telegram notification is disabled.
if [[ -z "${TELEGRAM_BOT_TOKEN}" || -z "${TELEGRAM_CHAT_ID}" ]]
then
    echo "Telegram bot token or chat ID not set. Notifications will be disabled." >&2
    TELEGRAM_ENABLED=0
else
    TELEGRAM_ENABLED=1
fi

#Checks if configuration file exists and readable.
CONFIG_FILE="/shared/configfile/monitor-service.conf.${HOSTNAME}"
if [[ ! -r "${CONFIG_FILE}" ]]
then
    echo "${CONFIG_FILE} is not readable or doesn't exist." >&2
    exit 1
fi

#Create a log file if it doesn't exist.
LOG_FILE="/shared/monitor-service.log.${HOSTNAME}"
if [[ ! -e "${LOG_FILE}" ]]
then
    echo "Log file not found. Creating a log file: ${LOG_FILE}" >&2
    touch "${LOG_FILE}"
fi

#Assign exit status.
EXIT_STATUS=0

#Use loops to check if services are running in the CONFIG_FILE.
while read SERVICE COMMAND
do
    #Check if the service is running. Count the number of process for the service. 
    SERVICE_PID=$(pidof "${SERVICE}" | wc -w)

    #Log the service checking process.
    TIMESTAMP=$(date "+%d %b %Y %T")
    echo "${TIMESTAMP} Checking service: ${SERVICE}" >> ${LOG_FILE}
    
    #Restart down service and log its status to the log file.
    if [[ "${SERVICE_PID}" -eq 0 ]]
    then
        ${COMMAND}
        echo "${TIMESTAMP} *${SERVICE} is down." >> ${LOG_FILE}
        echo "${TIMESTAMP} *Restarting ${SERVICE} with command: ${COMMAND}" >> ${LOG_FILE}
        
        #Send Telegram notification if service is down and notification is enabled.
        if [[ "${TELEGRAM_ENABLED}" -eq 1 ]]
        then
            MESSAGE="${TIMESTAMP} Service ${SERVICE} was down and restarted on ${HOSTNAME}."
            curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                    -d chat_id="${TELEGRAM_CHAT_ID}" \
                    -d text="${MESSAGE}" > /dev/null
        fi

        EXIT_STATUS=2
        continue
    else
        echo "${TIMESTAMP} ${SERVICE} running as PID(s): ${SERVICE_PID}" >> ${LOG_FILE}
    fi
done < "${CONFIG_FILE}"

exit "${EXIT_STATUS}"