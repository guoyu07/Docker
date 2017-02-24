#!/bin/bash
# MAINTAINER Aario <AarioAi@gmail.com>
set -e

. /aa_script/entrypointBase.sh

TIMEZONE=${TIMEZONE:-""}
HOST=${HOST:-"aa_git"}
ENTRYPOINT_LOG=${ENTRYPOINT_LOG:-'&2'}
LOG_TAG=${LOG_TAG:-"git_entrypoint[$$]"}

UPDATE_REPO=${UPDATE_REPO:-0}
GEN_SSL_CRT=${GEN_SSL_CRT:-""}


GIT_LOG_DIR=${GIT_LOG_DIR:-'/var/log/git'}
GIT_SSHD_PORT=${GIT_SSHD_PORT:-'22'}
GIT_USER=${GIT_USER:-'git'}
GIT_GROUP=${GIT_GROUP:-"git"}
GIT_REPO_ROOT=${GIT_REPO_ROOT:-"/var/lib/git"}
SSH_HOST_KEY_COMPLEXITY=${SSH_HOST_KEY_COMPLEXITY:-"default"}
SSH_HOST_KEY_COMPLEXITY=$(echo "${SSH_HOST_KEY_COMPLEXITY}" | awk '{print tolower($0)}') 




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


sshd_lock_file="${S_P_L_DIR}/git-entrypoint.sshd."$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)

if [ ! -f "$sshd_lock_file" ]; then 
	if [ "${GIT_SSHD_PORT}" != '22' ]; then
		sed -Ei "s/^\s*(Port\s)/#&/" '/etc/ssh/sshd_config'
		echo -e "\nPort ${GIT_SSHD_PORT}" >> '/etc/ssh/sshd_config'
	fi

	while read line; do 
		hot_key=$(echo $line | awk -F ' ' '{print $2}')
		if [ ! -z "$hot_key" -a ! -f "$hot_key" ]; then
			aaLog "ssh-keygen -P -t \"Aario\" rsa -b ${GEN_SSH_HOST_KEY_BITS} -f \"$hot_key\""        
			case ${hot_key##*/} in 
				ssh_host_rsa_key)
					# 768 2048(default)
					case "${SSH_HOST_KEY_COMPLEXITY}" in
						lowest)
							rsa_bits=768
							;;
						low)
							rsa_bits=1024
							;;
						default)
							rsa_bits=2048
							;;
						high)
							rsa_bits=4096
							;;
						highest)
							rsa_bits=16384
							;;
					esac
					ssh-keygen -P "" -t rsa -b $rsa_bits -f "$hot_key" >> "${ENTRYPOINT_LOG}" 2>&1
					;;
				ssh_host_dsa_key)
					# DSA keys must be 1024 bits
					ssh-keygen -P "" -t dsa -b 1024 -f "$hot_key" >> "${ENTRYPOINT_LOG}" 2>&1
					;;
				ssh_host_ecdsa_key)
					# valid lengths are 256, 384 or 521 bits
					case "${SSH_HOST_KEY_COMPLEXITY}" in
						low|lowest)
							ecdsa_bits=256
							;;
						default)
							ecdsa_bits=384
							;;
						high|highest)
							ecdsa_bits=521
							;;
					esac
					ssh-keygen -P "" -t ecdsa -b $ecdsa_bits -f "$hot_key" >> "${ENTRYPOINT_LOG}" 2>&1
					;;
				ssh_host_ed25519_key)
					case "${SSH_HOST_KEY_COMPLEXITY}" in
						lowest)
							ed25519_bits=768
							;;
						low)
							ed25519_bits=1024
							;;
						default)
							ed25519_bits=2048
							;;
						high)
							ed25519_bits=4096
							;;
						highest)
							ed25519_bits=16384
							;;
					esac
					ssh-keygen -P "" -t ed25519 -b $ed25519_bits -f "$hot_key" >> "${ENTRYPOINT_LOG}" 2>&1
					;;
				*)
					ssh-keygen -A >> "${ENTRYPOINT_LOG}" 2>&1
					;;
			esac
			
		fi
	done < <(cat '/etc/ssh/sshd_config' | grep "^HostKey\s*")
	
	touch "$sshd_lock_file"
fi

# setting password to git user
# git clone ${USER}@${IP}:${PATH}
# git clone ssh://${USER}@${IP}:${PORT}${PATH}
# git remote add origin ssh://${USER}@${IP}:${PORT}${PATH}

setHomeUsers() {
    if [ ! -z "${GIT_HOME_USERS}" ]; then
        # GIT_HOME_USERS=git:git,aario:Aario 
        for home_user in $(echo "${GIT_HOME_USERS}" | tr ',' "\n"); do
            user="$(echo $home_user | awk -F ':' '{print $1}')"
            password="$(echo $home_user | awk -F ':' '{print $2}')"
            if [ ! -z "$user" -a ! -z "$password" ]; then
                home_dir="${GIT_REPO_ROOT}/$user"
                if [ ! -d "$home_dir" ]; then
                    mkdir -p "$home_dir"
                fi
                useradd -g "${GIT_GROUP}" -d "$home_dir" -r -s /usr/bin/git-shell "$user"
                (echo "$password"; sleep 1; echo "$password") | passwd "$user" > /dev/null
				chown -R "$user:${GIT_GROUP}" "${GIT_REPO_ROOT}"
            fi
        done
    fi
}




lock_file="${S_P_L_DIR}/git-entrypoint-"$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)
if [ ! -f "$lock_file" ]; then
	setHomeUsers
	
	[ ! -d "${GIT_LOG_DIR}" ] && mkdir -p "${GIT_LOG_DIR}"
	chown -R ${GIT_USER}:${GIT_GROUP} "${GIT_LOG_DIR}"
	chmod -R u+xrw "${GIT_LOG_DIR}"
	touch "$lock_file"
fi



# git remote add origin ssh://${USER}@${IP}:${PORT}${PATH}
# git init --bare proj.git

for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

RunningSignal ${RUNING_ID:-''}

if [ $# -gt 0 ]; then
	echo "Running $@"
	if [ "${1: -3}" == 'git' ]; then
		su - ${GIT_USER} << EOF
		$@
EOF
	else
		exec "$@"
	fi
fi