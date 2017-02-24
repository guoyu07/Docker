#!/bin/bash
# MAINTAINER Aario <AarioAi@gmail.com>
set -e

. /aa_script/entrypointBase.sh

TIMEZONE=${TIMEZONE:-""}
HOST=${HOST:-"aa_mysql"}
ENTRYPOINT_LOG=${ENTRYPOINT_LOG:-'&2'}
LOG_TAG=${LOG_TAG:-"mysql_entrypoint[$$]"}

UPDATE_REPO=${UPDATE_REPO:-0}
GEN_SSL_CRT=${GEN_SSL_CRT:-""}

MYSQL_PREFIX=${MYSQL_PREFIX:-"/usr/local/mysql"}
MYSQL_USER=${MYSQL_USER:-mysql}
MYSQL_GROUP=${MYSQL_GROUP:-mysql}
MYSQL_BIND_ADDRESS=${MYSQL_BIND_ADDRESS:-'%'}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-''}
MYSQL_LOG_DIR=${MYSQL_LOG_DIR:-'/var/log/mysql'}
MYSQL_LOGBIN_DIR=${MYSQL_LOGBIN_DIR:-'/var/lib/mysql_log_bin'}
BIN_DIR=${BIN_DIR:-"/usr/local/bin"}
SBIN_DIR=${SBIN_DIR:-"/usr/local/sbin"}

if [ -z "${MYSQL_BIN_DIR}" ]; then
    if [ -x "${BIN_DIR}/mysql" -a -x "${BIN_DIR}/mysqld_safe" -a -x "${BIN_DIR}/mysql_tzinfo_to_sql"]; then
        MYSQL_BIN_DIR="${BIN_DIR}"
    elif [ -x "${MYSQL_PREFIX}/bin/mysql" -a -x "${MYSQL_PREFIX}/bin/mysqld_safe" ]; then
        MYSQL_BIN_DIR="${MYSQL_PREFIX}/bin"
    fi
fi

if [ -z "${MYSQL_SBIN_DIR}" ]; then
    if [ -x "${SBIN_DIR}/mysqld" ]; then
        MYSQL_SBIN_DIR="${SBIN_DIR}"
    elif [ -x "${MYSQL_PREFIX}/bin/mysqld" ]; then
        MYSQL_SBIN_DIR="${BIN_DIR}"
    fi
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


# setConfig /etc/my.cnf /usr/share/mysql/etc/my.cnf
setConfig() {
    for i in $@; do
        if [ -f "$i" ]; then
            aaLog "Configuration file: $i"
            if [ ! -z "${MYSQL_SERVER_ID}" ]; then
                aaLog "Seting : server-id=${MYSQL_SERVER_ID}"
                sed -Ei "s/^(server-id)[\s=]*.+$/server-id=${MYSQL_SERVER_ID}/" "$i"
                break
            fi
        fi
    done
}


# if command starts with an option, prepend mysqld
#if [ "${1:0:1}" = '-' ]; then
#	set -- mysqld "$@"
#fi

if [ "${1: -6}" == 'mysqld' -o "${1: -11}" == 'mysqld_safe' ]; then
	data_dir="$($@ --verbose --help --innodb-read-only 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
    
    # Remove last '/',  e.g.  /var/lib/mysql/
    data_dir=${data_dir%%/}
    if [ -z "$data_dir" ]; then 
        data_dir="$(${MYSQL_BIN_DIR}/mysqld --user=${MYSQL_USER} --verbose --help --innodb-read-only 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
    fi
    
    aaLog "data dir: $data_dir"

	# /var/log/mysql/error.log needs executable privileges  
	[ ! -d "${MYSQL_LOG_DIR}" ] && mkdir -p ${MYSQL_LOG_DIR}
	chown -R ${MYSQL_USER}:${MYSQL_USER} ${MYSQL_LOG_DIR} ${MYSQL_LOGBIN_DIR}
	chmod -R u+rxw ${MYSQL_LOG_DIR} ${MYSQL_LOGBIN_DIR}

    # database mysql
	if [ ! -d "$data_dir/mysql" ]; then

		if [ -z "${MYSQL_ROOT_PASSWORD}" -a -z "${MYSQL_ALLOW_EMPTY_PASSWORD}" ]; then
			#echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
			#echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
            aaLog --aalogpri_severity ERROR 'database is uninitialized and MYSQL_ROOT_PASSWORD not set'
            aaLog '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
            rm -rf "$data_dir"
			exit 1
		fi
        [ ! -d "$data_dir" ] && mkdir -p "$data_dir"
		chown -R ${MYSQL_USER}:${MYSQL_GROUP} "$data_dir"
		
		
			
    


		aaLog 'Initializing database'
		# if [ ! -x "${MYSQL_SBIN_DIR}/mysqld" ]; then
			# aaLog --aalogpri_severity ERROR "${MYSQL_SBIN_DIR}/mysqld is not executable!"
		# fi
		
		aaLog "datadir: ls -al $data_dir"
		aaLog $(ls -al "$data_dir")
		aaLog "logbin dir: ls -al ${MYSQL_LOGBIN_DIR}"
		aaLog $(ls -al "${MYSQL_LOGBIN_DIR}")
		aaLog "log dir(requires rwx permissions): ls -al ${MYSQL_LOG_DIR}"
		aaLog $(ls -al "${MYSQL_LOG_DIR}")

		${MYSQL_SBIN_DIR}/mysqld --user=${MYSQL_USER} --initialize-insecure=on --datadir=$data_dir
		aaLog 'Database initialized'

        # Run in background
		$@ --skip-networking &
        
        pid="$!"
        
        aaLog "Running $@ --skip-networking & : pid=$pid"
        
        ps aux >> "${ENTRYPOINT_LOG}" 2>&1
        
        aaLog "Running ${MYSQL_BIN_DIR}/mysql --protocol=socket -uroot"
		mysql=( ${MYSQL_BIN_DIR}/mysql --protocol=socket -uroot )
        
        aaLog 'MySQL first init process in progress...'
        is_mysql_running=0
        for i in {30..0}; do
            aaLog "$i"
            if echo 'SELECT 1;' | "${mysql[@]}" &> /dev/null; then
                is_mysql_running=1
                break
            fi
            aaLog 'MySQL init sleep 1'
            sleep 1
        done
        aaLog "MySQL first initialiation has been initialized "$[30-i]" times"
        if [ $is_mysql_running -eq 0 ]; then
            aaLog --aalogpri $[16*8+3] 'MySQL init process failed.'
            rm -rf "$data_dir"
            exit 1
        fi
        
        echo 'RESET QUERY CACHE;' | "${mysql[@]}"
        
		if [ -z "$MYSQL_INITDB_SKIP_TZINFO" ]; then
			# sed is for https://bugs.mysql.com/bug.php?id=20545
			${MYSQL_BIN_DIR}/mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
		fi
        

        aaLog "Changing Root Password"
		"${mysql[@]}" <<-EOSQL
			-- What's done in this file shouldn't be replicated
			--  or products like mysql-fabric won't work
			SET @@SESSION.SQL_LOG_BIN=0;
			DELETE FROM mysql.user ;
			CREATE USER 'root'@'${MYSQL_BIND_ADDRESS}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
			GRANT ALL ON *.* TO 'root'@'${MYSQL_BIND_ADDRESS}' WITH GRANT OPTION ;
			DROP DATABASE IF EXISTS test ;
			FLUSH PRIVILEGES ;
		EOSQL
        aaLog "Root Password changed"
		
        # -pAario     there should be no space between `-p` and `password`
		mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
	
        echo "SET PASSWORD FOR 'root'@'${MYSQL_BIND_ADDRESS}'=PASSWORD('${MYSQL_ROOT_PASSWORD}'); " | "${mysql[@]}"
        echo 'FLUSH PRIVILEGES;' | "${mysql[@]}"
        

        ######### Setting initialiation configurations with another mysql deamon process
		if ! kill -s TERM "$pid" || ! wait "$pid"; then
			#echo >&2 'MySQL init process failed.'
            aaLog --aalogpri $[16*8+3] 'MySQL init process failed.'
            rm -rf "$data_dir"
            exit 1
		fi
        
        if [ ! -z "${MYSQL_ROOT_PASSWORD}" ]; then
            
            aaLog "Initializing Start Up Process..."
            # Run in background
            "$@" --skip-networking &
            
            pid="$!"
            
            aaLog "Running mysqld with pid=$pid : Setting MYSQL_ROOT_PASSWORD"
            
            mysql=( ${MYSQL_BIN_DIR}/mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" )
            
            is_mysql_running=0
            for i in {30..0}; do
                aaLog 'MySQL (with root password) init process in progress...'
                if echo 'SELECT 1;' | "${mysql[@]}" &> /dev/null; then
                    is_mysql_running=1
                    break
                fi
                aaLog 'MySQL init sleep 1'
                sleep 1
            done
            aaLog "MySQL (with root password) has been initialized "$[30-i]" times"
            if [ $is_mysql_running -eq 0 ]; then
                aaLog --aalogpri $[16*8+3] 'MySQL init process failed.'
                rm -rf "$data_dir"
                exit 1
            fi
            
            aaLog 'RESET QUERY CACHE;'
            echo 'RESET QUERY CACHE;' | "${mysql[@]}"
            aaLog "Mysql Client Connected..."
            
            
            if [ ! -z "${MYSQL_DATABASES}" ]; then
                dbs=$(echo "${MYSQL_DATABASES}" | tr ',' "\n")
                aaLog "Handling $dbs ..."
                # for i in 100 200 300; do 
                # for i in "100 200 300"; do    error!!!
                for db in $dbs; do
                    aaLog "Creating datebase $db ..."
                    echo "CREATE DATABASE IF NOT EXISTS $db;" | "${mysql[@]}"
                    aaLog "Datebase $db created"
                done

            fi

            if [ ! -z "${MYSQL_ADMIN_USER}" -a ! -z "${MYSQL_ADMIN_PASSWORD}" ]; then
                aaLog "Granting Mysql Admin User..."
				MYSQL_ADMIN_BIND_ADDRESS=${MYSQL_ADMIN_BIND_ADDRESS:-'%'}
				MYSQL_ADMIN_PRIVILEGES=${MYSQL_ADMIN_PRIVILEGES:-'ALL'}
                MYSQL_ADMIN_PRIVILEGED_TABLES=${MYSQL_ADMIN_PRIVILEGED_TABLES:-'*.*'}
                echo "GRANT ${MYSQL_ADMIN_PRIVILEGES} ON ${MYSQL_ADMIN_PRIVILEGED_TABLES} TO '${MYSQL_ADMIN_USER}'@'${MYSQL_ADMIN_BIND_ADDRESS}' IDENTIFIED BY '${MYSQL_ADMIN_PASSWORD}' ;" | "${mysql[@]}"

                echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
            fi

            if [ ! -z "${MYSQL_REP_USER}" -a ! -z "${MYSQL_REP_PASSWORD}" ]; then
                aaLog "Granting Slave Server..."
				MYSQL_REP_BIND_ADDRESS=${MYSQL_REP_BIND_ADDRESS:-'%'}
                echo "GRANT REPLICATION SLAVE ON *.* TO '${MYSQL_REP_USER}'@'${MYSQL_REP_BIND_ADDRESS}' IDENTIFIED BY '${MYSQL_REP_PASSWORD}' ;"| "${mysql[@]}"
                echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
            fi
            
            aaLog "Setting slave's configs with another mysql deamon process"
            if ! kill -s TERM "$pid" || ! wait "$pid"; then
                aaLog --aalogpri $[16*8+3] "Fail to kill MySQL pid=$pid... : After Granting Slave Server"
                exit 1
            fi
            
            
            if [ ! -z "${MYSQL_MASTER}" -a ! -z "${MYSQL_MASTER_REP_USER}" -a ! -z "${MYSQL_MASTER_REP_PASSWORD}" ]; then
                aaLog "Setting Master Server..."
                # Run in background
                "$@" --skip-networking &
                
                pid="$!"
                
                aaLog " Running mysqld with pid=$pid : Setting Master Server"
               
			    master_host=$(echo "${MYSQL_MASTER}" | awk -F ':' '{print $1}')
				master_port=$(echo "${MYSQL_MASTER}" | awk -F ':' '{print $2}')
				master_port=${master_port:-'3306'}
                is_master_alive=0
                # Try to connect to master mysql server within 30 times (1 sec each time)
                for i in {30..0}; do
                    aaLog "($i) : Connecting to Master Server ${MYSQL_MASTER_REP_USER}@${MYSQL_MASTER} ..."
                    
                    # -h127.0.0.3 -P3306 will connect to current server, not the master one
                    #   Please connect to its master's link name (e.g aa_mysql)
                    mysql_master=( ${MYSQL_BIN_DIR}/mysql -h"$master_host" -P"$master_port" -u"${MYSQL_MASTER_REP_USER}" -p"${MYSQL_MASTER_REP_PASSWORD}")
                    if echo 'SELECT 1' | "${mysql_master[@]}" &> /dev/null; then
                        is_master_alive=1
                        aaLog " Connected to MySQL Master Server"
                        break
                    fi
                    
                    sleep 1
                done
                 
                if [ $is_master_alive -eq 0 ]; then
                    aaLog --aalogpri $[16*8+3] ' Master Server: ${MYSQL_MASTER} is not alive ...'
                    rm -rf "$data_dir"
                    exit 1
                fi
                
                mysql=( ${MYSQL_BIN_DIR}/mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" )
                is_slave_alive=0
                for i in {30..0}; do
                    aaLog 'MySQL slave init process in progress...'
                    if echo 'SELECT 1;' | "${mysql[@]}" &> /dev/null; then
                        is_slave_alive=1
                        aaLog " Connected to MySQL Slave Server"
                        break
                    fi
                    sleep 1
                done
                
                if [ $is_slave_alive -eq 0 ]; then
                    aaLog --aalogpri $[16*8+3] 'MySQL slave init failure'
                    rm -rf "$data_dir"
                    exit 1
                fi
                
                aaLog " stop slave ..."
                echo "stop slave;" | "${mysql[@]}"
                
                aaLog " reset slave ..."
                echo "reset slave;" | "${mysql[@]}"
                
                aaLog " CHANGE MASTER TO MASTER_HOST='$master_host', MASTER_PORT=$master_port, MASTER_USER='${MYSQL_MASTER_REP_USER}', MASTER_PASSWORD='${MYSQL_MASTER_REP_PASSWORD}', MASTER_AUTO_POSITION = 1;"
                
                echo "CHANGE MASTER TO MASTER_HOST='$master_host', MASTER_PORT=$master_port, MASTER_USER='${MYSQL_MASTER_REP_USER}', MASTER_PASSWORD='${MYSQL_MASTER_REP_PASSWORD}', MASTER_AUTO_POSITION = 1;" | "${mysql[@]}"
                
                aaLog " start slave"
                echo "start slave;" | "${mysql[@]}"
                
                if ! kill -s TERM "$pid" || ! wait "$pid"; then
                    aaLog --aalogpri $[16*8+3] 'Fail to kill MySQL pid=$pid... : After Setting Master Server'
                    rm -rf "$data_dir"
                    exit 1
                fi
            fi
            aaLog 'MySQL start up process init step done. Ready to start up.'
        fi
        
        aaLog 'MySQL init process done. Ready to start up.'
    fi
    
    setConfig "/etc/my.cnf" "${MYSQL_PREFIX}/etc/my.cnf"
    
fi

for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

RunningSignal ${RUNING_ID:-''}

[ -f "${MYSQL_RUN_DIR}/mysqld.sock" ] && rm -f "${MYSQL_RUN_DIR}/mysqld.sock"
[ -f "${MYSQL_RUN_DIR}/mysqld.sock.lock" ] && rm -f "${MYSQL_RUN_DIR}/mysqld.sock.lock"


if [ $# -gt 0 ]; then
	echo "Running $@"
	if [ "${1: -6}" == 'mysqld' -o "${1: -11}" == 'mysqld_safe' ]; then
		su - ${MYSQL_USER} << EOF
		$@
EOF
	else
	    exec "$@"
	fi
fi