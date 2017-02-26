FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>
ENV PGSQL_VER_NUM 9.6.1
ENV PGSQL_VER postgresql-${PGSQL_VER_NUM}
ENV PGSQL_SRC_URL https://ftp.postgresql.org/pub/source/v${PGSQL_VER_NUM}/${PGSQL_VER}.tar.gz
ENV PGSQL_SRC_MD5_URL ${PGSQL_SRC_URL}.md5

ENV PGSQL_USER ${SHARED_USER}
ENV PGSQL_GROUP ${SHARED_GROUP}

ADD ./src/* ${SRC_DIR}/
WORKDIR ${SRC_DIR}
RUN if [ ! -d "${SRC_DIR}/${PGSQL_VER}" ]; then                             \
        curl -sSL ${PGSQL_SRC_URL} -o ${SRC_DIR}/${PGSQL_VER}.tar.gz;       \
        if [ "$(openssl md5 "${SRC_DIR}/${PGSQL_VER}.tar.gz" | awk -F '= ' '{print $2}')" !=   "echo $(curl -s ${PGSQL_SRC_MD5_URL}) | awk '{print $1}'" ]; then                                        \
            echo "MD5 ERROR!"; exit 1;                                      \
        fi;                                                                 \
        tar -zxvf ${SRC_DIR}/${PGSQL_VER}.tar.gz;                           \
        rm -f ${SRC_DIR}/${PGSQL_VER}.tar.gz;                               \
    fi

ENV PGSQL_PREFIX ${PREFIX_BASE}/pgsql
ENV PGSQL_PORT 5432

RUN yum install -y readline-devel

WORKDIR ${SRC_DIR}/${PGSQL_VER}
# ./configure --help
#   --enable-debug
#   --enable-profiling
#   --without-readline
RUN ./configure --prefix=${PGSQL_PREFIX}        \
                --with-pgport=${PGSQL_PORT}     \
                --with-openssl					\
	&& make && make install


ENV PGSQL_DATADIR /var/lib/pgsql
ENV PGSQL_LOG_DIR /var/log/pgsql

RUN mkdir -p ${PGSQL_LOG_DIR} && mkdir -p ${PGSQL_DATADIR}  \
    && chown -R ${PGSQL_USER}:${PGSQL_GROUP} ${PGSQL_PREFIX}   \
    && chown -R ${PGSQL_USER}:${PGSQL_GROUP} ${PGSQL_LOG_DIR}  \
    && chown -R ${PGSQL_USER}:${PGSQL_GROUP} ${PGSQL_DATADIR}


ENV PGSQL_CONF_DIR /etc/pgsql

################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "\n PGSQL_VER_NUM='${PGSQL_VER_NUM}' \n PGSQL_PREFIX='${PGSQL_PREFIX}' \n PGSQL_DATADIR='${PGSQL_DATADIR}' \n PGSQL_USER='${PGSQL_USER}' \n PGSQL_GROUP='${PGSQL_GROUP}' \n " >> ${ENT_CONST_SCRIPT}          \
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


# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/stdout.log    		\
    && ln -sf /dev/stderr /var/log/stderr.log

#ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/local/pgsql/bin/pg_ctl", "start", "-s", "-D", "/var/lib/pgsql", "-l", "/var/log/pgsql/pgsql.log"]
#ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/local/pgsql/bin/postgres", "-s","-D", "/var/lib/pgsql", "-l", "/var/log/pgsql/pgsql.log"]
#ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/local/pgsql/bin/postgres", "-s","-D", "/var/lib/pgsql", "-l", "/var/log/pgsql/pgsql.log", "-c", "/etc/pgsql/postgresql.conf"]

#USER ${PGSQL_USER}
#CMD ["pg_ctl", "start"]
# PGSQL_ROOT_PASSWORD
# PGSQL_DATABASES
# PGSQL_ADMIN_USER
# PGSQL_ADMIN_PASSWORD

