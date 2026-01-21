#!/bin/bash
#This script install apache on remote servers.

#Service to be installed on remote servers.
SERVICE='httpd'
FIREWALLD_SERVICE='http'

#DocumentRoot on the web server.
DOCUMENT_ROOT='/var/www/html'

#Display usage statement.
usage() {
    echo 'Execute this script following the usage below:' >&2
    echo "${0} HOSTNAME..." >&2
}

#Execute the script without root privileges. (SSH into remote servers as a non-root user using its own SSH key.)
if [[ "${UID}" -eq 0 ]]
then
    echo 'Please execute this script without root privileges.' >&2
    usage
    exit 1
fi

#Display error message when hosts are not provided as argument.
if [[ "${#}" -eq 0 ]]
then
    echo 'Please supply a hostname that the apache service will be installed on.' >&2
    usage
    exit 1
fi

#Default exit status
EXIT_STATUS=0

#Install apache with a for loop on remote servers.
for SERVER in "${@}"
do
    #SSH into the remote server.
    echo "Installing ${SERVICE} on ${SERVER}."
    ssh "${SERVER}" sudo dnf install -y "${SERVICE}"
    
    #Check if the SSH command fails. If fails, skip the apache initialization and move onto the next server.
    if [[ "${?}" -ne 0 ]]
    then
        echo "Fail to install ${SERVICE} on ${SERVER}." >&2
        continue
    fi

    #Create an index.html file in the document root directory in the server.
    ssh "${SERVER}" "echo 'Hello world.' | sudo tee ${DOCUMENT_ROOT}/index.html &>/dev/null"
    #Check if successfully create the index.html file.
    if [[ "${?}" -ne 0 ]]
    then
        echo "Fail to create an index.html file in ${DOCUMENT_ROOT} on ${SERVER}." >&2
        continue
    fi

    #Start and enable apache.
    ssh "${SERVER}" sudo systemctl enable --now "${SERVICE}"
    #Check if successfully initialise apache.
    if [[ "${?}" -ne 0 ]]
    then
        echo "Fail to start and enable ${SERVICE} on ${SERVER}." >&2
        continue
    fi

    #Open http access in firewalld.
    ssh "${SERVER}" "sudo firewall-cmd --add-service=${FIREWALLD_SERVICE} --permanent >/dev/null"
    ssh "${SERVER}" "sudo firewall-cmd --reload >/dev/null"
    #Check if successfully open http access.
    if [[ "${?}" -ne 0 ]]
    then
        echo "Fail to open ${SERVICE} access in firewalld on ${SERVER}."
        continue
    fi

    #Test to see if the web server responds. (Ensure DNS can resolve the server hostname!)
    curl "${SERVER}" &>/dev/null
    #Check if successfully curl the web server.
    CURL_EXIT_STATUS="${?}"
    if [[ "${CURL_EXIT_STATUS}" -ne 0 ]]
    then
        echo "Fail to GET content with curl from ${SERVER}." >&2
        echo "Curl exit code: ${CURL_EXIT_STATUS}" >&2
        EXIT_STATUS="${CURL_EXIT_STATUS}"
        continue
    fi

    #Ping the server. If no response, the host is down and continue to ping the next host.
    ping -c3 "${SERVER}" >/dev/null
    #Check if successfully ping the web server.
    PING_EXIT_STATUS="${?}"
    if [[ "${PING_EXIT_STATUS}" -ne 0 ]]
    then
        echo "${SERVER} is down. Cannot ping ${SERVER}." >&2
        EXIT_STATUS="${PING_EXIT_STATUS}"
        continue
    fi
done 

exit "${EXIT_STATUS}"