#!/bin/bash
# MAINTAINER Aario <AarioAi@gmail.com>
set -e

. /aa_script/entrypointBase.sh

TIMEZONE=${TIMEZONE:-""}
HOST=${HOST:-"aa_redis"}
ENTRYPOINT_LOG=${ENTRYPOINT_LOG:-'&2'}
LOG_TAG=${LOG_TAG:-"redis_entrypoint[$$]"}

UPDATE_REPO=${UPDATE_REPO:-0}
GEN_SSL_CRT=${GEN_SSL_CRT:-""}

RDS_LOG_DIR=${RDS_LOG_DIR:-'/var/log/redis'}
RDS_DATA_DIR=${RDS_DATA_DIR:-"/var/lib/redis"}
RDS_USER=${RDS_USER:-"redis"}
RDS_GROUP=${RDS_GROUP:-"redis"}
RDS_CONF=${RDS_CONF:-"/etc/redis/redis.conf"}

if [ ! -d '/var/log/redis' ]; then 
	mkdir -p '/var/log/redis'
	chown -R ${RDS_USER}:${RDS_GROUP} '/var/log/redis'
	chmod -R u+rwx '/var/log/redis'
fi

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

lock_file="${S_P_L_DIR}/redis-entrypoint.lock-${RUNING_ID}-$$"
aaLog 'Lock: '$lock_file

if [ ! -f "$lock_file" ]; then
	
	[ ! -f "${RDS_DATA_DIR}" ] && mkdir -p "${RDS_DATA_DIR}"
	[ ! -f "${RDS_LOG_DIR}" ] && mkdir -p "${RDS_LOG_DIR}"
	chown -R ${RDS_USER}:${RDS_GROUP} "${RDS_DATA_DIR}" "${RDS_LOG_DIR}"
	chmod u+rwx "${RDS_DATA_DIR}" "${RDS_LOG_DIR}"
	
	if [ -f "${RDS_CONF}" ]; then
		if [ -f "/tmp/redis.conf" ]; then
			rm ${RDS_CONF}
		else
			mv ${RDS_CONF} '/tmp/redis.conf'
		fi
	fi
	if [ -f "${RDS_CONF}-overwrite" ]; then
		aaLog "Using ${RDS_CONF}-overwrite"
		mv "${RDS_CONF}-overwrite" > "${RDS_CONF}"
	else 
		if [ -f "/tmp/redis.conf" ]; then
			aaLog "Using Docker generated redis.conf"
			mv "/tmp/redis.conf" "${RDS_CONF}"
		fi
	fi
	
	if [ -f "${RDS_CONF}-append" ]; then
		aaLog "Appending ${RDS_CONF}-append"
		cat "${RDS_CONF}-append" >> "${RDS_CONF}"
	fi
	if [ -f "${RDS_CONF}-prepend" ]; then
		aaLog "Prepending ${RDS_CONF}-append"
		cp "${RDS_CONF}-append" "/tmp/redis.conf-append"
		cat "${RDS_CONF}" >> "/tmp/redis.conf-append"
		mv "/tmp/redis.conf-append" "${RDS_CONF}"
	fi
	chown ${RDS_USER}:${RDS_GROUP} ${RDS_CONF} && chmod u+rw ${RDS_CONF}

    if [ ! -z "${RDS_REQUIREPASS}" ]; then
        aaLog "Setting requirepass ${RDS_REQUIREPASS}"
        sed -Ei 's/^\s*requirepass\s*/#&/g' "${RDS_CONF}"
        echo -e "\nrequirepass ${RDS_REQUIREPASS}\n" >> "${RDS_CONF}"
    fi

    if [ ! -z "${RDS_MASTERAUTH}" ]; then
        aaLog "Setting masterauth ${RDS_MASTERAUTH}"
        sed -Ei 's/^\s*masterauth\s*/#&/g' "${RDS_CONF}"
        echo -e "\nmasterauth ${RDS_MASTERAUTH}\n" >> "${RDS_CONF}"
    fi

    if [ ! -z "${RDS_SLAVE_OF}" ]; then
        aaLog "Setting slaveof ${master_host} ${master_port}"
        master_host=$(echo ${RDS_SLAVE_OF} | awk -F ':' '{print $1}')
        master_port=$(echo ${RDS_SLAVE_OF} | awk -F ':' '{print $2}')
        echo ${master_port:="6379"}
        sed -Ei 's/^\s*slaveof\s*/#&/g' "${RDS_CONF}"
        echo -e "\nslaveof ${master_host} ${master_port}\n" >> "${RDS_CONF}"
    fi
	touch "$lock_file"
fi

for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

RunningSignal ${RUNING_ID:-''}

if [ $# -gt 0 ]; then
	echo "Running $@"
	if [ ! -z "${RDS_USER}" -a "${1: -12}" == 'redis-server' ]; then
		su - ${RDS_USER} << EOF
			$@
EOF
	else
		exec "$@"
	fi
fi