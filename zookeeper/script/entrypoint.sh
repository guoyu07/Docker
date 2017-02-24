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
	[ ! -d "${ZOOKEEPER_DATA_DIR}" ] && mkdir -p "${ZOOKEEPER_DATA_DIR}"
	[ ! -d "${ZOOKEEPER_LOG_DIR}" ] && mkdir -p "${ZOOKEEPER_LOG_DIR}"
	chown -R ${ZOOKEEPER_USER}:${ZOOKEEPER_GROUP} "${ZOOKEEPER_DATA_DIR}" "${ZOOKEEPER_LOG_DIR}"
	touch "$lock_file"
fi


for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

RunningSignal ${RUNING_ID:-''}

if [ $# -gt 0 ]; then
	echo "Running $@"
	if [ "${1, -11}" == 'zkServer.sh' ]; then
		su - ${ZOOKEEPER_USER} << EOF
			$@
EOF
	else
		exec "$@"
	fi
fi