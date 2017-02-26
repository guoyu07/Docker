#!/bin/bash
# MAINTAINER Aario <AarioAi@gmail.com>
set -e

. /aa_script/entrypointBase.sh

TIMEZONE=${TIMEZONE:-""}
HOST=${HOST:-"aa_pgsql"}
ENTRYPOINT_LOG=${ENTRYPOINT_LOG:-'&2'}
LOG_TAG=${LOG_TAG:-"pgsql_entrypoint[$$]"}

UPDATE_REPO=${UPDATE_REPO:-0}
GEN_SSL_CRT=${GEN_SSL_CRT:-""}

PGSQL_PREFIX=${PGSQL_PREFIX:-'/usr/local/pgsql'}
PGSQL_DATADIR=${PGSQL_DATADIR:-'/var/lib/pgsql'}
PGSQL_USER=${PGSQL_USER:-'pgsql'}
PGSQL_GROUP=${PGSQL_GROUP:-'pgsql'}
PGSQL_BIND_ADDRESS=${PGSQL_BIND_ADDRESS:-'%'}
PGSQL_LOG_DIR=${PGSQL_LOG_DIR:-'/var/log/pgsql'}

# ENTRYPOINT_LOG
#   $file         create log file
#   console(default)      echo
SetEntrypointLogPath "${ENTRYPOINT_LOG}"
aaLog() {
    AaLog --aalogheader_host "${HOST}" --aalogfile "${ENTRYPOINT_LOG}" --aalogtag "${LOG_TAG}" "$@"
}

aaLog "Adjusting date... : $(date)"
AaAdjustTime "${TIMEZONE}"
aaLog "Adjusted date : $(date)"

aaLog "Doing yum update ..."
YumUpdate "${UPDATE_REPO}"

aaLog "Generating SSL Certificate..."
GenSslCrt "${GEN_SSL_CRT}"

if [ "${1: -8}" == 'postgres' -o "${1: -6}" == 'pg_ctl' ]; then

	chown -R ${PGSQL_USER} ${PGSQL_DATADIR}
    if [ ! -d "${PGSQL_DATADIR}" -o -z "$(ls "${PGSQL_DATADIR}/")" ]; then
		
        #This will create a /usr/local/pgsql/data directory and initialize it ready for startup and use.
		
		su - ${PGSQL_USER} << EOF
		echo "${PGSQL_PREFIX}/bin/initdb -D ${PGSQL_DATADIR}"
        ${PGSQL_PREFIX}/bin/initdb -D "${PGSQL_DATADIR}"
		
        chown -R "${PGSQL_USER}":"${PGSQL_GROUP}" "${PGSQL_DATADIR}"
		
		echo "${PGSQL_PREFIX}/bin/createuser -d -r -l -d -P ${PGSQL_ROOT_PASSWORD} postgres"
		
		${PGSQL_PREFIX}/bin/createuser -d -r -l -d -P ${PGSQL_ROOT_PASSWORD} postgres
		
		echo "${PGSQL_PREFIX}/bin/createuser -d -r -l -d -P ${PGSQL_ROOT_PASSWORD} ${PGSQL_ADMIN_USER}"
      
        if [ ! -z "${PGSQL_ADMIN_USER}" -a ! -z "${PGSQL_ADMIN_PASSWORD}" ]; then
            # https://www.postgresql.org/docs/current/static/app-createuser.html
           ${PGSQL_PREFIX}/bin/createuser -d -r -l -d -P "${PGSQL_ADMIN_PASSWORD}" "${PGSQL_ADMIN_USER}"
        fi

        if [ ! -z "${PGSQL_DATABASES}" ]; then
			echo "Creating Databases: ${PGSQL_DATABASES}"
            dbs=$(echo "${PGSQL_DATABASES}" | tr ',' "\n")            
            owner=${PGSQL_ADMIN_USER:-'postgres'}
            # for i in 100 200 300; do 
            # for i in "100 200 300"; do    error!!!
            for db in $dbs; do
                # create database
                # We have to set the owner of the database when we create it, otherwise the 'postgres' user owns it and then we have to grant access to allow our new user to access it.
                ${PGSQL_PREFIX}/bin/createdb --owner=$owner $db
            done

        fi
EOF
    fi
fi

for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

RunningSignal ${RUNING_ID:-''}

if [ $# -gt 0 ]; then
	echo "Running $@"
	if [ "${1: -8}" == 'postgres' -o "${1: -6}" == 'pg_ctl' ]; then
		su - ${PGSQL_USER} << EOF
		$@
EOF
	else
	    exec "$@"
	fi
fi

