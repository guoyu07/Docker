FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

ENV MYSQL_VER_MAJOR 5.7
ENV MYSQL_VER_NUM ${MYSQL_VER_MAJOR}.16
ENV MYSQL_VER mysql-${MYSQL_VER_NUM}
ENV MYSQL_SRC_FILENAME mysql-boost-${MYSQL_VER_NUM}
ENV MYSQL_SRC_URL http://dev.mysql.com/get/Downloads/MySQL-${MYSQL_VER_MAJOR}/${MYSQL_SRC_FILENAME}.tar.gz

# list in the downloading page  http://dev.mysql.com/downloads/mysql/
# Source Code > Generic Linux (Architecture Independent), Compressed TAR Archive Includes Boost Headers

ENV MYSQL_USER ${SHARED_USER}
ENV MYSQL_GROUP ${SHARED_GROUP}

WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/
RUN if [ ! -d "${SRC_DIR}/${MYSQL_VER}" ]; then                             \
        curl -sSL ${MYSQL_SRC_URL} -o ${SRC_DIR}/${MYSQL_VER}.tar.gz;       \
        tar -zxvf ${SRC_DIR}/${MYSQL_VER}.tar.gz;                           \
        rm -f ${SRC_DIR}/${MYSQL_VER}.tar.gz;                               \
    fi
    
WORKDIR ${SRC_DIR}/${MYSQL_VER}
RUN yum update -y && yum install -y ncurses-devel bison
ENV MYSQL_RUN_DIR ${S_P_L_DIR}/mysqld

# @warning MySQL sock requires a direactory which belongs to user mysql
RUN mkdir -p ${MYSQL_RUN_DIR} && chown -R ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_RUN_DIR} && chmod -R a+x ${MYSQL_RUN_DIR}

ENV MYSQL_SOCK      ${MYSQL_RUN_DIR}/mysqld.sock
ENV MYSQL_PID       ${MYSQL_RUN_DIR}/mysqld.pid
ENV MYSQL_DATADIR   /var/lib/mysql
ENV MYSQL_PREFIX    ${PREFIX_BASE}/mysql
ENV MYSQL_PORT 3306

# cmake options https://dev.mysql.com/doc/refman/5.7/en/source-configuration-options.html
#   -DMYSQL_TCP_MYSQL_PORT=3306                           \
#    -DWITH_SYSTEMD=1                                \ cause mysqld_safe not installed
#    -DSYSTEMD_PID_DIR=${MYSQL_RUN_DIR}              \  needs -DWITH_SYSTEMD=1  
RUN cmake \
    -DCMAKE_INSTALL_PREFIX=${MYSQL_PREFIX}          \
    -DEXTRA_CHARSETS=all                            \
    -DDEFAULT_CHARSET=utf8                          \
    -DDEFAULT_COLLATION=utf8_unicode_ci             \
    -DENABLED_PROFILING=1                           \
    -DENABLE_DEBUG_SYNC=1                           \
    -DINNODB_PAGE_ATOMIC_REF_COUNT=1                \
    -DINSTALL_BINDIR=${BIN_DIR}                     \
    -DINSTALL_SBINDIR=${SBIN_DIR}                   \
    -DMYSQL_DATADIR=${MYSQL_DATADIR}                \
    -DMYSQL_TCP_PORT=${MYSQL_PORT}                  \
    -DMYSQL_UNIX_ADDR=${MYSQL_SOCK}                 \
    -DSYSCONFDIR=${SYS_CONF_DIR}                    \   
    -DDOWNLOAD_BOOST=1                              \
    -DWITH_BOOST=${SRC_DIR}/${MYSQL_VER}/boost      \
    -DWITH_DEBUG=0                                  \
    -DWITH_MYISAM_STORAGE_ENGINE=1                  \
    -DWITH_INNOBASE_STORAGE_ENGINE=1                \
    -DWITH_BLACKHOLE_STORAGE_ENGINE=1               \
    -DWITH_ARCHIVE_STORAGE_ENGINE=1                 \
    -DWITH_PERFSCHEMA_STORAGE_ENGINE=1              \
    -DWITH_PARTITION_STORAGE_ENGINE=1               \
    -DENABLED_LOCAL_INFILE=1                        \
    -DENABLE_DOWNLOADS=1                            \
    -DWITH_PARTITION_STORAGE_ENGINE=1               \
    -DMYSQL_MAINTAINER_MODE=0                       \
    -DWITH_SSL:STRING=bundled                       \
    -DWITH_ZLIB:STRING=bundled                      \
    && make && make install

#RUN yum install -y libaio

#RUN rpm -Uvh http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
#RUN yum-config-manager --disable mysql56-community && yum-config-manager --enable mysql57-community

#RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-*
#RUN yum clean all && yum update -y && yum install -y mysql-community-server

##################### my.cnf #################################

ENV SERVER_ID 1
ENV MYSQL_LOG_DIR /var/log/mysql
ENV MYSQL_LOG_ERROR ${MYSQL_LOG_DIR}/error.log
# it'll create /var/log/mysql_log_bin/bin.00001 ...
ENV MYSQL_LOGBIN_DIR /var/lib/mysql_log_bin
ENV MYSQL_LOGBIN ${MYSQL_LOGBIN_DIR}/bin

# /var/log/mysql/error.log needs executable privileges  
RUN [ ! -d "${MYSQL_LOG_DIR}" ] && mkdir -p ${MYSQL_LOG_DIR}  
RUN chown -R ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_LOG_DIR};          \
	chmod -R u+xw ${MYSQL_LOG_DIR};  
RUN rm -rf ${MYSQL_LOGBIN_DIR} && mkdir -p ${MYSQL_LOGBIN_DIR}      \
    && chown -R ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_LOGBIN_DIR} && chmod -R u+rxw ${MYSQL_LOGBIN_DIR}
RUN rm -rf ${MYSQL_DATADIR} && mkdir -p ${MYSQL_DATADIR}        \
    && chown -R ${MYSQL_USER}:${MYSQL_GROUP} ${MYSQL_DATADIR} && chmod -R u+rw ${MYSQL_DATADIR}
COPY ./data/data/           ${MYSQL_DATADIR}
COPY ./data/mysql_log_bin/  ${MYSQL_LOGBIN_DIR}
COPY ./etc/*    /etc/
RUN if [ ! -f "/etc/my.cnf" ]; then                                     \
        cp ${MYSQL_PREFIX}/support-files/my-default.cnf /etc/my.cnf;    \
        chown ${MYSQL_USER}:${MYSQL_GROUP} /etc/my.cnf;                 \
    fi

# don't reverse lookup hostnames, they are usually another container
# docker build will convert `\n`
# `bind-address=0.0.0.0` is necessary!  Otherwise, even ignored by `# bind-address...`, you can only connect mysql by `mysql -uroot -p` with a socket file on mysql docker container. But you can't connect it by `mysql -h127.0.0.1 -uroot -p` inside the container or outside the container
RUN sed -Ei 's/^(skip-host-cache|skip-name-resolve|skip-networking|bind-address|port|user|log-bin|log-error|pid-file|socket|server-id)[\s=]/#&/' /etc/my.cnf                              \
    && sed -i '/^#/d' /etc/my.cnf                                    \
    && echo -e "\nskip-host-cache\nskip-name-resolve\nbind-address=0.0.0.0\nport=${MYSQL_PORT}\nuser=${MYSQL_USER}\nserver-id=${SERVER_ID}\nlog-bin=${MYSQL_LOGBIN}\nlog-error=${MYSQL_LOG_ERROR}\ndatadir=${MYSQL_DATADIR}\npid-file=${MYSQL_PID}\nsocket=${MYSQL_SOCK}\n" | awk '{ print } $1 ~/^\[mysqld\]/ && c == 0 { c = 1; system("cat") }' /etc/my.cnf > /tmp/my.cnf      \
    && mv /tmp/my.cnf /etc/my.cnf                                   \
    && chown ${MYSQL_USER}:${MYSQL_GROUP} /etc/my.cnf               \
    && chmod a+r /etc/my.cnf
 
##################### my.cnf #################################

# --initialize will generate a random password in `~/.mysql_secret` while `--initialize-insecure will` not
#RUN ${MYSQL_PREFIX}/bin/mysqld --initialize-insecure --user=mysql --basedir=${MYSQL_PREFIX} --datadir=${MYSQL_DATADIR}

################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "\n MYSQL_VER_MAJOR='${MYSQL_VER_MAJOR}' \n  MYSQL_VER_NUM='${MYSQL_VER_NUM}' \n MYSQL_VER='${MYSQL_VER}' \n MYSQL_SRC_URL='${MYSQL_SRC_URL}' \n MYSQL_USER='${MYSQL_USER}' \n MYSQL_GROUP='${MYSQL_GROUP}' \n MYSQL_RUN_DIR='${MYSQL_RUN_DIR}' \n MYSQL_SOCK='${MYSQL_SOCK}' \n MYSQL_PID='${MYSQL_PID}' \n MYSQL_DATADIR='${MYSQL_DATADIR}' \n MYSQL_BIN_DIR='${BIN_DIR}' \n MYSQL_LOG_DIR='${MYSQL_LOG_DIR}' \n MYSQL_LOG_ERROR='${MYSQL_LOG_ERROR}' \n MYSQL_PREFIX='${MYSQL_PREFIX}' \n MYSQL_LOGBIN='${MYSQL_LOGBIN}' \n MYSQL_LOGBIN_DIR='${MYSQL_LOGBIN_DIR}' \n MYSQL_SBIN_DIR='${SBIN_DIR}' \n MYSQL_PREFIX='${MYSQL_PREFIX}' \n " >> ${ENT_CONST_SCRIPT}                           \
    && sed -i 's/^\s*//g' ${ENT_CONST_SCRIPT}

RUN rm -rf /tmp/spool && mkdir /tmp/spool
COPY ./spool/* /tmp/spool
RUN if [ -f "/tmp/spool/crontab" ]; then            \
        if [ -f "/etc/crontab" ]; then              \
            yes | cp /etc/crontab /etc/crontab-cp1; \
            cat /tmp/spool/crontab >> /etc/crontab; \
        else                                        \
            mv /tmp/spool/crontab /etc/crontab;     \
        fi;                                         \
        sort -k2n "/etc/crontab" | sed '$!N; /^\(.*\)\n\1$/!P; D' > "/tmp/crontab";    \
        yes | mv "/tmp/crontab" "/etc/crontab";     \
        yes | cp /etc/crontab /etc/crontab-cp2;     \
        rm -rf /tmp/spool;                          \
    fi
RUN yum clean all && rm -rf ${SRC_DIR}/*
#################################################

RUN chown -R ${MYSQL_USER} ${SBIN_DIR}/mysqld 						\
	&& chmod -R u+x ${SBIN_DIR}/mysqld
	
# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/stdout.log    		\
    && ln -sf /dev/stderr /var/log/stderr.log


#EXPOSE ${MYSQL_PORT}


#VOLUME "${MYSQL_DATADIR}"
#VOLUME "${MYSQL_LOGBIN_DIR}"
#VOLUME "${MYSQL_LOG_DIR}"


#USER ${MYSQL_USER}


# mysql5.7 GTID-Slave-Replication https://dev.mysql.com/doc/refman/5.7/en/replication-gtids-howto.html

# mysqld options http://dev.mysql.com/doc/refman/5.7/en/server-options.html
# /aa_script/entrypoint.sh /usr/local/sbin/mysqld --user=mysql --gtid-mode=ON --explicit_defaults_for_timestamp --enforce-gtid-consistency
ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/local/sbin/mysqld", "--user=mysql", "--gtid-mode=ON", "--explicit_defaults_for_timestamp", "--enforce-gtid-consistency"]