#!/bin/bash
# MAINTAINER Aario <AarioAi@gmail.com>
set -e

. /aa_script/entrypointBase.sh

TIMEZONE=${TIMEZONE:-""}
HOST=${HOST:-"aa_centos"}
ENTRYPOINT_LOG=${ENTRYPOINT_LOG:-'&2'}
LOG_TAG=${LOG_TAG:-"centos_entrypoint[$$]"}

UPDATE_REPO=${UPDATE_REPO:-0}
GEN_SSL_CRT=${GEN_SSL_CRT:-""}

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
aaLog "yum update done"

aaLog "Generating SSL Certificate..."
GenSslCrt "${GEN_SSL_CRT}"
aaLog "Created SSL Certificates:"

for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

if [ $# -gt 0 ]; then
	echo "Running $@"
	RunningSignal ${RUNING_ID:-''}
    exec "$@"
fi