#!/bin/bash
# MAINTAINER Aario <AarioAi@gmail.com>
set -e

. /aa_script/entrypointBase.sh

TIMEZONE=${TIMEZONE:-""}
HOST=${HOST:-"aa_nginx"}
ENTRYPOINT_LOG=${ENTRYPOINT_LOG:-'&2'}
LOG_TAG=${LOG_TAG:-"nginx_entrypoint[$$]"}

UPDATE_REPO=${UPDATE_REPO:-0}
GEN_SSL_CRT=${GEN_SSL_CRT:-""}

NGX_INCLUDE_CONF_DIR=${NGX_INCLUDE_CONF_DIR:-"/etc/nginx/conf.d"}

NGX_USER=${NGX_USER:-'nginx'}
NGX_GROUP=${NGX_GROUP:-'nginx'}

WWW_HTDOCS=${WWW_HTDOCS:-'/var/lib/htdocs'}
NGX_LOG_DIR=${NGX_LOG_DIR:-'/var/log/nginx'}

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

# e.g. yii_40080,80,8080
enableServers() {
    local lockFile="${S_P_L_DIR}/nginx-entrypoint.sh-enableServers."$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)
    if [ ! -f "$lockFile" -a ! -z "${NGX_ENABLE_SERVERS}" ]; then
        enable_servers=$(echo "${NGX_ENABLE_SERVERS}" | tr ',' "\n")
        
        # for i in 100 200 300; do 
        # for i in "100 200 300"; do    error!!!
        for enable_serv in $enable_servers; do
            if [ -f ${NGX_INCLUDE_CONF_DIR}$enable_serv".conf_" ]; then
                mv ${NGX_INCLUDE_CONF_DIR}$enable_serv".conf_" ${NGX_INCLUDE_CONF_DIR}$enable_serv".conf"
                aaLog "Enabled Server: $enable_serv"
            fi
        done
        touch "$lockFile"
    fi
}


disableServers() {
    local lockFile="${S_P_L_DIR}/nginx-entrypoint.sh-disableServers."$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)
    if [ ! -f "$lockFile" -a ! -z "${NGX_DISALBE_SERVERS}" ]; then
        disable_servers=$(echo "${NGX_DISALBE_SERVERS}" | tr ',' "\n")
        
        # for i in 100 200 300; do 
        # for i in "100 200 300"; do    error!!!
        for disable_serv in  $disable_servers; do
            if [ -f ${NGX_INCLUDE_CONF_DIR}$disable_serv".conf" ]; then
                mv ${NGX_INCLUDE_CONF_DIR}$disable_serv".conf" ${NGX_INCLUDE_CONF_DIR}$disable_serv".conf_"
                aaLog "Disabled Server: $enable_serv"
            fi
        done
        touch "$lockFile"
    fi
}

setDefaultFastCgiPass() {
    local lockFile="${S_P_L_DIR}/nginx-entrypoint.sh-setDefaultFastCgiPass."$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)
    if [ ! -f "$lockFile" -a ! -z "${NGX_DEFAULT_FASTCGI_PASS}" ]; then
    
        # for i in 100 200 300; do 
        # for i in "100 200 300"; do    error!!!
        for serv in $(ls ${NGX_INCLUDE_CONF_DIR}/*.conf*); do
            if [ -f "$serv" ]; then
                sed -i "s/fastcgi_pass\s*.*/fastcgi_pass ${NGX_DEFAULT_FASTCGI_PASS};/g" "$serv"
                aaLog "Set $serv default fastcgi_pass to ${NGX_DEFAULT_FASTCGI_PASS}"
            fi
        done
        touch "$lockFile"
    fi
}

# server@phpfpm-host:phpfpm-port,server@phpfpm-host:phpfpm-port
# e.g. 80@aa_php7:9000,8080@aa_php56:9001
setServersDynamically() {
    setDefaultFastCgiPass
    local lockFile="${S_P_L_DIR}/nginx-entrypoint.sh-specificServersFastCgiPassesSetted."$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)
    if [ ! -f "$lockFile" -a ! -z "${NGX_FASTCGI_PASSES}" ]; then
        fastcgi_passes=$(echo "${NGX_FASTCGI_PASSES}" | tr ',' "\n")
        
        # for i in 100 200 300; do 
        # for i in "100 200 300"; do    error!!!
        for cgi in $fastcgi_passes; do
            serv=$(echo $cgi | awk -F '@' '{print $1}')
            fastcgi_pass=$(echo $cgi | awk -F '@' '{print $2}')
            serv_conf=${NGX_INCLUDE_CONF_DIR}$serv".conf"
            if [ -f "$serv_conf" ]; then
              sed -i "s/fastcgi_pass\s*aa_php:9000;/fastcgi_pass ${fastcgi_pass};" "$serv_conf"
              aaLog "Set $serv_conf fastcgi_pass to ${fastcgi_pass}"
            fi
        done
        touch "$lockFile"
    fi
}

grantPrivileges() {
    [ ! -d "${WWW_HTDOCS}" ] && mkdir -p ${WWW_HTDOCS}
	[ ! -d "${NGX_LOG_DIR}" ] && mkdir -p ${NGX_LOG_DIR}
	chown -R ${NGX_USER}:${NGX_GROUP} ${WWW_HTDOCS} ${NGX_LOG_DIR}
	chmod -R g+rwx ${WWW_HTDOCS} ${NGX_LOG_DIR}
}

lock_file="${S_P_L_DIR}/nginx-entrypoint-"$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)
if [ ! -f "$lock_file" ]; then
	enableServers
	disableServers
	setServersDynamically
	grantPrivileges
	touch "$lock_file"
fi
for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

RunningSignal ${RUNING_ID:-''}

if [ $# -gt 0 ]; then
	echo "Running $@"
	# You have to run nginx server with root privilege
	exec "$@"
fi