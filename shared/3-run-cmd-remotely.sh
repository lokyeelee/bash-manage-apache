#!/bin/bash
#This script SSH to remote servers and run commands on them.

#Provide a server list.
SERVER_LIST='/shared/servers'

#Usage statement.
usage() {
    echo 'Please run this script following the usage.' >&2
    echo "${0} [OPTION] COMMAND...[COMMAND]" >&2
    echo " -f FILE   Override the default server file. The default is ${SERVER_LIST}." >&2
    echo " -n        Perform a "dry run" where the commands will be displayed instead of executed." >&2
    echo " -s        Run the command with sudo (superuser) privileges on the remote servers." >&2
    echo " -v        Verbose mode, which displays the name of the server for which the command is being executed on." >&2
    exit 1
}

#Enforce to connect as a normal user.
if [[ "${UID}" -eq 0 ]]
then
    echo 'Please specify the -s option if you want to run this script with root privileges.' >&2
    usage
    exit 1
fi

#Parse options.
while getopts f:nsv OPTION
do
    case ${OPTION} in
    f) SERVER_LIST="${OPTARG}" ;;
    n) DRY_RUN='true' ;;
    s) SUDO='sudo' ;;
    v) VERBOSE='true' ;;
    ?) usage ;;
    esac
done

#Check if the server file exists. (Put this after user enter the override server file)
if [[ ! -e "${SERVER_LIST}" ]]
then
    echo "Cannot find the server list ${SERVER_LIST}." >&2
    exit 1
fi

#Remove options, leave arguments only.
shift "$((OPTIND - 1))"

#Provide a usage statement if no command is supplied to the script.
if [[ "${#}" -eq 0 ]]
then
    usage
fi

#SSH to the remote servers and execute commands on them
for SERVER in $(cat ${SERVER_LIST})
do
    for COMMAND in "${@}"
    do
        #If -v is specified.
        if [[ "${VERBOSE}" = 'true' ]]
        then
            echo "Executing ${SUDO} ${COMMAND} on ${SERVER}."
        fi

        #If -n (dry run) is specified.
        if [[ "${DRY_RUN}" = 'true' ]]
        then
            echo "DRY RUN: ssh -o ConnectTimeout=2 ${SERVER} ${SUDO} ${COMMAND}"  
        else
            ssh -o ConnectTimeout=2 "${SERVER}" "${SUDO}" "${COMMAND}" 
            SSH_EXIT_STATUS="${?}"
        fi
        
        #Report non-zero exit status from the SSH command (if any).
        if [[ "${SSH_EXIT_STATUS}" -ne 0 ]]
        then
            echo "Failed to execute command ${COMMAND} on the remote host ${SERVER}." >&2
            EXIT_STATUS="${SSH_EXIT_STATUS}"
        fi
    done
done

exit ${EXIT_STATUS}