FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

ENV CASSANDRA_VER_NUM 3.0.10
ENV CASSANDRA_VER apache-cassandra-${CASSANDRA_VER_NUM}
ENV CASSANDRA_SRC_FILENAME ${CASSANDRA_VER}-bin
ENV CASSANDRA_SRC_URL http://apache.fayea.com/cassandra/${CASSANDRA_VER_NUM}/${CASSANDRA_SRC_FILENAME}.tar.gz

ENV CASSANDRA_USER ${SHARED_USER}
ENV CASSANDRA_GROUP ${SHARED_GROUP}

ENV CASSANDRA_PREFIX  ${PREFIX_BASE}/cassandra

WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/
RUN if [ ! -d "${SRC_DIR}/${CASSANDRA_VER}" ]; then                                 \
        curl -sSL ${CASSANDRA_SRC_URL} -o ${SRC_DIR}/${CASSANDRA_VER}.tar.gz;       \
        tar -zxvf ${SRC_DIR}/${CASSANDRA_VER}.tar.gz;                               \
        rm -f ${SRC_DIR}/${CASSANDRA_VER}.tar.gz;                                   \
    fi
    

RUN mkdir -p ${CASSANDRA_PREFIX}                                                    \
    && mv ${SRC_DIR}/${CASSANDRA_VER}/* ${CASSANDRA_PREFIX}                         \
	&& chown -R ${CASSANDRA_USER}:${CASSANDRA_GROUP} ${CASSANDRA_PREFIX}

ENV CASSANDRA_CONF ${PREFIX_BASE}/cassandra/conf/cassandra.yaml
ENV CASSANDRA_COMMIT_LOG_DIR /var/log/cassandra_commitlog
#ENV CASSANDRA_COMMIT_LOG_DIR ${PREFIX_BASE}/cassandra/data/commitlog
ENV CASSANDRA_DATA_DIR /var/lib/cassandra/data
ENV CASSANDRA_SAVED_CACHES_DIR /var/lib/cassandra/saved_caches
ENV CASSANDRA_HINTS_DIR /var/lib/cassandra/hints

RUN chown ${CASSANDRA_USER} ${CASSANDRA_CONF} 	\
	&& sed -Ei 's/^(rpc_address|broadcast_rpc_address|commitlog_directory|saved_caches_directory|hints_directory)/#&/' ${CASSANDRA_CONF} 														\
	&& sed -i '/^#/d' ${CASSANDRA_CONF}  									\
	&& echo -e "\nrpc_address: 0.0.0.0\nbroadcast_rpc_address: localhost\ndata_file_directories:\n    - ${CASSANDRA_DATA_DIR}\ncommitlog_directory: ${CASSANDRA_COMMIT_LOG_DIR}\nsaved_caches_directory: ${CASSANDRA_SAVED_CACHES_DIR}\nhints_directory: ${CASSANDRA_HINTS_DIR}" >>  ${CASSANDRA_CONF} 
  

################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "\n CASSANDRA_USER='${CASSANDRA_USER}' \n CASSANDRA_GROUP='${CASSANDRA_GROUP}' \n CASSANDRA_PREFIX='${CASSANDRA_PREFIX}' \n CASSANDRA_CONF='${CASSANDRA_CONF}' \n CASSANDRA_DATA_DIR='${CASSANDRA_DATA_DIR}' \n CASSANDRA_COMMIT_LOG_DIR='${CASSANDRA_COMMIT_LOG_DIR}' \n CASSANDRA_SAVED_CACHES_DIR='${CASSANDRA_SAVED_CACHES_DIR}' \n CASSANDRA_HINTS_DIR='${CASSANDRA_HINTS_DIR}'" >> ${ENT_CONST_SCRIPT}         \
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
ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/local/cassandra/bin/cassandra", "-f"]

#VOLUME ["/var/lib/cassandra"]

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
#EXPOSE 7000 7001 7199 9042 9160

# cassandra-env.sh
# 	CASSANDRA_ENV_MAX_HEAP_SIZE
# 	CASSANDRA_ENV_HEAP_NEWSIZE


