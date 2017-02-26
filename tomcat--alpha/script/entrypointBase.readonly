#!/bin/bash
# MAINTAINER Aario <AarioAi@gmail.com>
set -e

cat << EOF

--------------------------------------------------------------------------------
                              Hello, Aario!
--------------------------------------------------------------------------------

EOF

######### Do not modify it when its name is "entrypointBase.readonly"!!!
#### It's a link to $base/entrypointBase.sh

. /aa_script/entrypointConst.sh

S_P_L_DIR=${S_P_L_DIR:-'/aa_pid'}
SYNC_DIR=${SYNC_DIR:-'/aa_sync'}
SSL_DIR=${SSL_DIR:-'/etc/ssl'}

entrypoint_log_path="${S_P_L_DIR}/entrypoint_log.path"

# Linux Kernel Configurations for Web
#   requires –privileged
#   @param string path
#   @param string method  TO | APPEND | APPEND_LN | GREATER | LESSER
#   @param mixed value 
#   @example
#       ConfigKernel /sys/kernel/mm/transparent_hugepage/enabled TO never

ConfigKernel() {
    if [ $# -lt 2 ]; then
        echo "Config Kernel Requires 2 arguments"
    else
        lock_dir="${S_P_L_DIR}/ConfigKernel"
        if [ ! -d "$lock_dir" ]; then
            mkdir "$lock_dir"
        fi
        lock="$lock_dir/"$(echo "$@" | md5sum | awk -F ' ' '{print $1}')'.lock'
        if [ -f "$lock" ]; then
            echo "$lock exists"
        else
            if [ -w "$1" ]; then
                content=$@
                content=${content#* }
                content=${content#* }
                
                case $(echo "$2" | awk '{print toupper($0)}') in
                    TO)
                        echo "$content" > "$1"
                    ;;
                    APPEND)
                        echo "$content" >> "$1"
                    ;;
                    APPEND_LN)
                        echo "\n$content" >> "$1"
                    ;;
                    GREATER)
                        v=$(cat "$1")
                        v=${v:-0}
                        if [ $3 -gt $v ]; then
                            echo "$3" > "$1"
                        fi
                    ;;
                    LESSER)
                        v=$(cat "$1")
                        v=${v:-0}
                        if [ $3 -lt $v ]; then
                            echo "$3" > "$1"
                        fi
                    ;;
                esac
                echo "$@" > "$lock"
            fi
        fi
    fi
}

#   echo never > /sys/kernel/mm/transparent_hugepage/enabled
#   echo 511 > /proc/sys/net/core/somaxconn 
ConfigKernel /sys/kernel/mm/transparent_hugepage/enabled TO never
ConfigKernel /proc/sys/net/core/somaxconn GREATER 511
ConfigKernel /etc/sysctl.conf APPEND_LN "net.ipv4.tcp_mem = 379008 505344 758016"
ConfigKernel /etc/sysctl.conf APPEND_LN "net.ipv4.tcp_wmem = 4096 16384 4194304"
ConfigKernel /etc/sysctl.conf APPEND_LN "net.ipv4.tcp_rmem = 4096 87380 4194304"
ConfigKernel /etc/sysctl.conf APPEND_LN "net.core.wmem_default = 8388608"
ConfigKernel /etc/sysctl.conf APPEND_LN "net.core.rmem_default = 8388608"
ConfigKernel /etc/sysctl.conf APPEND_LN "net.core.rmem_max = 16777216"
ConfigKernel /etc/sysctl.conf APPEND_LN "net.core.wmem_max = 16777216"
ConfigKernel /etc/sysctl.conf APPEND_LN "net.unix.max_dgram_qlen = 100"
ConfigKernel /etc/security/limits.conf APPEND_LN "* soft nofile 262140"
ConfigKernel /etc/security/limits.conf APPEND_LN "* hard nofile 262140"
ConfigKernel /etc/security/limits.conf APPEND_LN "root soft nofile 262140"
ConfigKernel /etc/security/limits.conf APPEND_LN "root hard nofile 262140"
ConfigKernel /etc/security/limits.conf APPEND_LN "* soft core unlimited"
ConfigKernel /etc/security/limits.conf APPEND_LN "* hard core unlimited"
ConfigKernel /etc/security/limits.conf APPEND_LN "root soft core unlimited"
ConfigKernel /etc/security/limits.conf APPEND_LN "root hard core unlimited"


# console file
SetEntrypointLogPath() {
    if [ ! -z "$1" ]; then
        echo $1 > $entrypoint_log_path
		if [ "$1" == '&2' ]; then
				cat "/aa_script/entrypointConst.sh" >&1
		else 
			if [ ! -f "$1" ]; then
				if [ ! -d ${1%/*} ]; then
					mkdir -p ${1%/*}
				fi
				touch "$1"
			fi
			cat "/aa_script/entrypointConst.sh" >> $1 2>&1
		fi
    fi
}

# for `docker logs xxx | tail -1`
RunningSignal() {
	echo -e "\nRUNNING_ID=$@"
}

# Yum update frequency  UPDATE_REPO
#   0       not update
#   > 0     every N times, update once
YumUpdate() {
    if [ ! -z "$1" -a $1 -gt 0 ]; then
        if [ -f "$entrypoint_log_path" -a ! -z $(cat "$entrypoint_log_path") ]; then
            yum update -y >> $(cat "$entrypoint_log_path") 2>&1
        else
            yum update -y
        fi
    fi
}


# SSL Certificates  GEN_SSL_CRT
#   crt2048  crt4096  dhparam2048  dhparam4096
#   @example
#       GenSslCrt crt2048 crt4096 dhparam2048 dhparam4096
#       GenSslCrt crt2048,crt4096,dhparam2048,dhparam4096
GenSslCrt() {
    ssl_crt_lock_file="${S_P_L_DIR}/entrypoint_ssl_crt.lock"
    if [ ! -f "$ssl_crt_lock_file" -a $# -gt 0 ]; then
        if [ $# -eq 1 ]; then
            set -- ${1//,/ }
        fi
    
        if [ ! -d "${SSL_DIR}/certs" -o ! -d "${SSL_DIR}/private" ]; then
            mkdir -p ${SSL_DIR}/certs && mkdir -p ${SSL_DIR}/private;
        fi
        
        for crt in $@; do
            case $crt in
                crt2048 | "aa_2048.crt" | "2048.crt")
                    cd "${SSL_DIR}/certs"
                    if [ ! -f "${SSL_DIR}/certs/aa_2048.crt" ]; then
                        if [ -f "$entrypoint_log_path" -a ! -z $(cat "$entrypoint_log_path") ]; then
                            openssl req -new -newkey rsa:2048 -sha256 -nodes -out aa_2048.csr -keyout aa_2048.key -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Aario Ai/OU=Aario/CN=Aa" >> $(cat "$entrypoint_log_path") 2>&1
                             openssl x509 -req -days 3650 -sha1 -extensions v3_ca -signkey aa_2048.key -in aa_2048.csr -out aa_2048.crt >> $(cat "$entrypoint_log_path") 2>&1
                        else
                            openssl req -new -newkey rsa:2048 -sha256 -nodes -out aa_2048.csr -keyout aa_2048.key -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Aario Ai/OU=Aario/CN=Aa"
                            openssl x509 -req -days 3650 -sha1 -extensions v3_ca -signkey aa_2048.key -in aa_2048.csr -out aa_2048.crt
                        fi
                    fi
                ;;
                crt4096 | "aa_4096.crt" | "4096.crt")
                    cd "${SSL_DIR}/certs"
                    if [ ! -f "${SSL_DIR}/certs/aa_4096.crt" ]; then
                        if [ -f "$entrypoint_log_path" -a ! -z $(cat "$entrypoint_log_path") ]; then
                            openssl req -new -newkey rsa:4096 -sha256 -nodes -out aa_4096.csr -keyout aa_4096.key -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Aario Ai/OU=Aario/CN=Aa" >> $(cat "$entrypoint_log_path") 2>&1
                            openssl x509 -req -days 3650 -sha1 -extensions v3_ca -signkey aa_4096.key -in aa_4096.csr -out aa_4096.crt >> $(cat "$entrypoint_log_path") 2>&1
                        else
                            openssl req -new -newkey rsa:4096 -sha256 -nodes -out aa_4096.csr -keyout aa_4096.key -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Aario Ai/OU=Aario/CN=Aa"
                            openssl x509 -req -days 3650 -sha1 -extensions v3_ca -signkey aa_4096.key -in aa_4096.csr -out aa_4096.crt
                        fi
                    fi
                ;;
                dhparam2048 | "aa_2048.dhparam" | "aa_4096.dhparam")
                    cd "${SSL_DIR}/private"
                    if [ ! -f "${SSL_DIR}/private/aa_2048.dhparam" ]; then
                        if [ -f "$entrypoint_log_path" -a ! -z $(cat "$entrypoint_log_path") ]; then
                            openssl dhparam -out aa_2048.dhparam 2048 >> $(cat "$entrypoint_log_path") 2>&1
                        else
                            openssl dhparam -out aa_2048.dhparam 2048
                        fi
                    fi
                ;;
                dhparam4096 | "aa_4096.dhparam" | "aa_4096.dhparam")
                    cd "${SSL_DIR}/private"
                    if [ ! -f "${SSL_DIR}/private/aa_4096.dhparam" ]; then
                        if [ -f "$entrypoint_log_path" -a ! -z $(cat "$entrypoint_log_path") ]; then
                            openssl dhparam -out aa_4096.dhparam 4096 >> $(cat "$entrypoint_log_path") 2>&1
                        else
                            openssl dhparam -out aa_4096.dhparam 4096
                        fi
                    fi
                ;;
            esac
        done
        
        touch "$ssl_crt_lock_file"
    fi
}

# severity lock
#   lock exists, severity error exists;
AaSeverityLock() {
    lockFile=${S_P_L_DIR}"/entrypointSeverity.lock"
    
    if [ $# -gt 0 ]; then
        if [ ! -f $lockFile ]; then
            touch $lockFile
        fi
        echo $@ >> $lockFile
        cat $lockFile
        return 1
    else
        if [ -f $lockFile ]; then
            cat $lockFile
            return 1
        else
            return 0
        fi
    fi
}


# Every restart will check whether the severity lock exists
AaSeverityLock
if [  $? -eq 1 ]; then
    echo "Severity Lock Exists..."
    exit 1
fi




# Usage:
#   AaLog $msg  | AaLog $msg --aalogfile console        //  echo
#   AaLog $msg --aalogfile &2               //  error.log
#   AaLog $msg --aalogfile $toFile
# @param --aalogfile 
# @param --aalogpri <$pri> in syslog
# @param --aalogpri_facility
#   “kern”, “user”, “mail”, “daemon”, “auth”, “intern”, “lpr”, “news”, “uucp”, “clock”, “authpriv”, “ftp”, “ntp”, “audit”, “alert”, “cron”, “local0”..“local7”
# @param --aalogpri_severity
#   emerge, alert, crit, err, warning, notice, info, debug
# @param --aalogheader_host
# @param --aalogheader_ip
# @param --aalogtag     e.g. nginx[0], phpfpm[0], nginx_entrypoint.sh[0]
# @Note:
#   echo >&2 "message"                      // to error.log, e.g. mysql.error , php.error
# @Warning:
#   AaLog "Running $@"
#   AaLog "Running redis-server /etc/redis.conf"
#       $1 = "Running redis-server", $2 = "/etc/redis.conf"
# @see https://tools.ietf.org/html/rfc3164
#   Syslog format
#   <191>Oct 22 10:33:33 
AaLog() {
    echo -e "\nArgs: @ = $@ 1 = $1 ; 2 = $2;\n"
    local log_msg=""
    
    local last_opt
    local log_file
    local log_pri
    local log_pri_facility
    local log_pri_severity
    local log_header_host
    local log_header_ip
    local log_tag
    for arg in $@; do
        if [ ! -z "$last_opt" ]; then 
            echo "__last opt: $last_opt"
            case $last_opt in
                --aalogfile)
                    echo "# --aalogfile $arg"
                    log_file=$arg
                ;;
                --aalogpri)
                    echo "# --aalogpri $arg"
                    log_pri=$arg
                ;;
                --aalogheader_host)
                    echo "# --aalogheader_host $arg"
                    log_header_host=$arg
                ;;
                --aalogheader_ip)
                    echo "# --aalogheader_ip $arg"
                    log_header_ip=$arg
                ;;
                --aalogtag)
                    echo "# --aalogtag $arg"
                    log_tag=$arg
                ;;
                --aalogpri_facility)
                    echo "# --aalogpri_facility $arg"
                    log_pri_facility=$arg
                ;;
                --aalogpri_severity)
                    echo "# --aalogpri_severity $arg"
                    log_pri_severity=$arg
                ;;
            esac
            unset last_opt
            continue;
        else
            case $arg in
                --aalogfile)
                    last_opt='--aalogfile'
                    echo '## --aalogfile'
                ;;
                --aalogpri)
                    last_opt='--aalogpri'
                    echo '## --aalogpri'
                ;;
                --aalogheader_host)
                    last_opt='--aalogheader_host'
                    echo '## --aalogheader_host'
                ;;
                --aalogheader_ip)
                    last_opt='--aalogheader_ip'
                    echo '## --aalogheader_ip'
                ;;
                --aalogtag)
                    last_opt='--aalogtag'
                    echo '## --aalogtag'
                ;;
                --aalogpri_facility)
                    last_opt='--aalogpri_facility'
                    echo '## --aalogpri_facility'
                ;;
                --aalogpri_severity)
                    last_opt='--aalogpri_severity'
                    echo '## --aalogpri_severity'
                ;;
                *)
                    log_msg=$log_msg" "$arg
                ;;
            esac
        fi
    done
    
    if [ ! -z $log_pri_severity ]; then
        local facility_ID
        local severity
        if [ -z $log_pri_facility ]; then
            log_pri_facility="local0"
        fi
        
        case $(echo "$log_pri_facility" | awk '{print tolower($0)}') in
            kern)
                facility_ID=0
            ;;
            user)
                facility_ID=1
            ;;
            mail)
                facility_ID=2
            ;;
            daemon)
                facility_ID=3
            ;;
            auth)
                facility_ID=4
            ;;
            intern)
                facility_ID=5
            ;;
            lpr)
                facility_ID=6
            ;;
            news)
                facility_ID=7
            ;;
            uucp)
                facility_ID=8
            ;;
            clock)
                facility_ID=9
            ;;
            authpriv)
                facility_ID=10
            ;;
            ftp)
                facility_ID=11
            ;;
            ntp)
                facility_ID=12
            ;;
            audit)
                facility_ID=13
            ;;
            alert)
                facility_ID=14
            ;;
            cron)
                facility_ID=15
            ;;
            local0)
                facility_ID=16
            ;;
            local1)
                facility_ID=17
            ;;
            local2)
                facility_ID=18
            ;;
            local3)
                facility_ID=19
            ;;
            local4)
                facility_ID=20
            ;;
            local5)
                facility_ID=21
            ;;
            local6)
                facility_ID=22
            ;;
            local7)
                facility_ID=23
            ;;
            *)
                facility_ID=16
            ;;
        esac
        
        case $(echo "$log_pri_severity" | awk '{print toupper($0)}') in
            EMERG | EMERGENCY)
                severity=0
            ;;
            ALERT)
                severity=1
            ;;
            CRIT | CRITICAL)
                severity=2
            ;;
            ERR | ERROR)
                severity=3
            ;;
            WARNING)
                severity=4
            ;;
            NOTICE)
                severity=5
            ;;
            INFO | INFORMATION)
                severity=6
            ;;
            DEBUG)
                severity=7
            ;;
            *)
                severity=7
            ;;
        esac
        
        log_pri=$[$facility_ID * 8 + $severity]
    fi
    log_pri=${log_pri:-"191"}
    local severity_msgs=("EMERG" "ALERT" "CRIT" "ERR" "WARNING" "NOTICE" "INFO" "DEBUG")
    local severity_msg=${severity_msgs[$(($log_pri & 7))]}
    local syslog_date=$(date '+%b %d %T %z')             # date '+%b %d %T %z
    log_header_host=${log_header_host:-""}
    log_header_ip=${log_header_ip:-""}
    log_tag=${log_tag:-""}
    log_msg="<$log_pri>$syslog_date $log_header_host $log_header_ip $log_tag: [$severity_msg] $log_msg"
    
    if [ -z "$log_file" -o "$log_file" == "console" ]; then
        echo -e "$log_msg"
    else
        if [ "$log_file" == '&2' ]; then
            echo -e "$log_msg" >&2    # to system error.log, e.g. syslog, mysql.err, php.err
        else
            if [ ! -f "$log_file" ]; then
                local log_dir=${log_file%/*}
                if [ ! -d "${log_dir}" ]; then
                    mkdir -p "${log_dir}"
                fi
                touch "$log_file"
                chmod a+r "$log_file"
            fi
            
            echo -e "To log file $log_file: $log_msg"
            echo -e "$log_msg" >> "$log_file"
        fi
    fi
    
    # Severity: Err, CRIT, ALERT, EMERG
    if [ ${severity:-7} -lt 4 ]; then
        AaSeverityLock $log_msg
        exit 1
    fi

}

AaAdjustTime() {
    # root user
    if [ "$(id -u)" != "0" ]; then
        echo "AaAdjustTime requires root privileges"
    else
        local lockFile="${S_P_L_DIR}/entrypointBase.sh-init_timezone.lock"
        if [ ! -f "$lockFile" -a ! -z "$1" ]; then
            local timezoneFile="/usr/share/zoneinfo/$1"     # e.g. Asia/Shanghai
            if [ -f "$timezoneFile" ]; then
                yes | cp -f "$timezoneFile" "/etc/localtime"
                touch "$lockFile"
                echo "change timezone to $1"
            fi
        fi
    fi
    #echo "ntpdate ..."
    #ntpdate time.nist.gov &
}



#REGEXAP_SYNC_DIR=${SYNC_DIR//\//\\/}
#REGEXAP_SYNC_DIR=${REGEXAP_SYNC_DIR//\-/\\-}
#REGEXAP_SYNC_DIR=${REGEXAP_SYNC_DIR//\*/\\*}
# concatFiles() {
    # if [ ! -f "$2" ]; then 
        # mv $1 $2
    # else
        # cat "$1" >> "$2"
    # fi
# }

# readonly CRONTAB_RUN="${ENT_DIR}/run/crontab.job"
# if [ -f "${ENT_DIR}/src/crontab.job" ]; then
    # cp -rT "${ENT_DIR}/src/crontab.job" ${CRONTAB_RUN}
    # rm -f "${ENT_DIR}/src/crontab.job"
# else 
    # for crontab in `ls -a ${ENT_DIR}/src/crontabs/`; do 
        # if [ -f "$crontab" ]; then
            # appendSrcToRun "$crontab" "${CRONTAB_RUN}"
            # # Remove repeated lines
            # sort -k2n "${CRONTAB_RUN}"  | sed '$!N; /^\(.*\)\n\1$/!P; D' > "$crontab"
            # cat "$crontab" > "${CRONTAB_RUN}"
            # rm -f "$crontab"
        # fi
    # done
# fi

# readonly SYNC_SCRIPT_RUN="${ENT_DIR}/run/sync.sh"
# if [ -f "${ENT_DIR}/src/sync.sh" ]; then
    # cp -rT "${ENT_DIR}/src/sync.sh" ${SYNC_SCRIPT_RUN}
    # rm -f "${ENT_DIR}/src/sync.sh"
# else 
    # for syncScript in `ls -a ${ENT_DIR}/src/syncScripts/`; do
        # if [ -f "$syncScript" ]; then
            # appendSrcToRun "$syncScript" "${SYNC_SCRIPT_RUN}"
            # sed -i "s/^\s*\#\!\/bin\/bash//g" ${SYNC_SCRIPT_RUN}
            # sed -i "s/^s*set\s+\-e//g" ${SYNC_SCRIPT_RUN}
            # sed -i "1s/.*/\#\!\/bin\/bash\nset \-e\nSYNC_DIR=${REGEXAP_SYNC_DIR}\n&/" ${SYNC_SCRIPT_RUN}
            # rm -f "$syncScript"
        # fi
    # done
# fi

