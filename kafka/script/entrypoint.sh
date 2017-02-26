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

KAFKA_USER=${KAFKA_USER:-'kafka'}
KAFKA_GROUP=${KAFKA_GROUP:-'kafka'}
KAFKA_PREFIX=${KAFKA_PREFIX:-"/usr/local/kafka"}
KAFKA_DATA_DIR=${KAFKA_DATA_DIR:-'/var/lib/kafka'}
KAFKA_LOG_DIR=${KAFKA_LOG_DIR:-'/var/log/kafka'}

ZOOKEEPER_USER=${ZOOKEEPER_USER:-'zookeeper'}
ZOOKEEPER_GROUP=${ZOOKEEPER_GROUP:-'zookeeper'}
ZOOKEEPER_PREFIX=${ZOOKEEPER_PREFIX:-"/usr/local/zookeeper"}
ZOOKEEPER_DATA_DIR=${ZOOKEEPER_DATA_DIR:-'/var/lib/zookeeper'}
ZOOKEEPER_LOG_DIR=${ZOOKEEPER_LOG_DIR:-'/var/log/zookeeper'}

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

lock_file="${S_P_L_DIR}/php-entrypoint-"$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)
if [ ! -f "$lock_file" ]; then
	[ ! -d "${KAFKA_DATA_DIR}" ] && mkdir -p "${KAFKA_DATA_DIR}"
	[ ! -d "${KAFKA_LOG_DIR}" ] && mkdir -p "${KAFKA_LOG_DIR}"
	chown -R ${KAFKA_USER}:${KAFKA_GROUP} "${KAFKA_DATA_DIR}" "${KAFKA_LOG_DIR}"
	chmod -R u+rwx  "${KAFKA_DATA_DIR}" "${KAFKA_LOG_DIR}"
	[ ! -d "${ZOOKEEPER_DATA_DIR}" ] && mkdir -p "${ZOOKEEPER_DATA_DIR}"
	[ ! -d "${ZOOKEEPER_LOG_DIR}" ] && mkdir -p "${ZOOKEEPER_LOG_DIR}"
	chown -R ${ZOOKEEPER_USER}:${ZOOKEEPER_GROUP} "${ZOOKEEPER_DATA_DIR}" "${ZOOKEEPER_LOG_DIR}"
	chmod -R u+rwx  "${KAFKA_DATA_DIR}" "${KAFKA_LOG_DIR}"
	touch "$lock_file"
fi


${ZOOKEEPER_PREFIX}/bin/zkServer.sh start

for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

RunningSignal ${RUNING_ID:-''}

if [ $# -gt 0 ]; then
	echo "Running $@"
	if [ "${1, -5}" == 'kafka' ]; then
		su - ${KAFKA_USER} << EOF
			$@
EOF
	else
		exec "$@"
	fi
fi