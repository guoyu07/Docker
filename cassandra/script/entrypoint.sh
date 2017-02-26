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

CASSANDRA_USER=${CASSANDRA_USER:-'cassandra'}
CASSANDRA_GROUP=${CASSANDRA_GROUP:-'cassandra'}
CASSANDRA_PREFIX=${CASSANDRA_PREFIX:-'/usr/local/cassandra'}
CASSANDRA_CONF=${CASSANDRA_CONF:-'/usr/local/cassandra/conf/cassandra.yaml'}

CASSANDRA_DATA_DIR=${CASSANDRA_DATA_DIR:-'/var/lib/cassandra/data'}
CASSANDRA_COMMIT_LOG_DIR=${CASSANDRA_COMMIT_LOG_DIR:-'/var/log/cassandra_commit_log'}
CASSANDRA_SAVED_CACHES_DIR=${CASSANDRA_SAVED_CACHES_DIR:-'/var/lib/cassandra/saved_caches'}
CASSANDRA_HINTS_DIR=${CASSANDRA_HINTS_DIR:-'/var/lib/cassandra/hints'}


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

if [ ! -d "${CASSANDRA_DATA_DIR}/system" -a "${1: -9}" == 'cassandra' ]; then
	if [ ! -z "${CLUSTER_NAME}" ]; then
		sed -Ei "s/^\s*cluster_name:.*$/cluster_name: '${CLUSTER_NAME}'/" ${CASSANDRA_CONF}
	fi
fi

lock_file="${S_P_L_DIR}/cassandra-entrypoint.sh."$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)
if [ ! -f "$lock_file" ]; then
	if [ ! -d "/etc/ld.so.conf.d/" ]; then
		mkdir "/etc/ld.so.conf.d"
	fi
	touch '/etc/ld.so.conf.d/aario.conf'
	[ ! -d "${CASSANDRA_DATA_DIR}" ] && mkdir -p "${CASSANDRA_DATA_DIR}"
	[ ! -d "${CASSANDRA_COMMIT_LOG_DIR}" ] && mkdir -p "${CASSANDRA_COMMIT_LOG_DIR}"
	[ ! -d "${CASSANDRA_SAVED_CACHES_DIR}" ] && mkdir -p "${CASSANDRA_SAVED_CACHES_DIR}"
	[ ! -d "${CASSANDRA_HINTS_DIR}" ] && mkdir -p "${CASSANDRA_HINTS_DIR}"
	
	chown -R ${CASSANDRA_USER}:${CASSANDRA_GROUP} '/etc/ld.so.conf.d' ${CASSANDRA_DATA_DIR} ${CASSANDRA_COMMIT_LOG_DIR} ${CASSANDRA_SAVED_CACHES_DIR} ${CASSANDRA_HINTS_DIR}
	chmod -R u+rwx '/etc/ld.so.conf.d' ${CASSANDRA_DATA_DIR} ${CASSANDRA_COMMIT_LOG_DIR} ${CASSANDRA_SAVED_CACHES_DIR} ${CASSANDRA_HINTS_DIR}
	touch "$lock_file"
fi


for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

RunningSignal ${RUNING_ID:-''}

if [ $# -gt 0 ]; then
	echo "Running $@"
	if [ "${1: -9}" == 'cassandra' ]; then
		su - ${CASSANDRA_USER} << EOF
		$@
EOF
	else
		exec "$@"
	fi
fi