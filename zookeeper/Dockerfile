FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

ENV ZOOKEEPER_VER zookeeper-3.4.9
ENV ZOOKEEPER_SRC_URL https://mirrors.tuna.tsinghua.edu.cn/apache/zookeeper/${ZOOKEEPER_VER}/${ZOOKEEPER_VER}.tar.gz
ENV ZOOKEEPER_USER ${SHARED_USER}
ENV ZOOKEEPER_GROUP ${SHARED_GROUP}
ENV ZOOKEEPER_PREFIX ${PREFIX_BASE}/zookeeper
ENV ZOOKEEPER_CONF ${ZOOKEEPER_PREFIX}/conf/zoo.cfg
ENV ZOOKEEPER_LOG_DIR /var/log/zookeeper
ENV ZOOKEEPER_DATA_DIR /var/lib/zookeeper
ENV ZOOKEEPER_CLIENT_PORT 2181


# Install Postfix
#RUN yum install -y postfix && /usr/sbin/alternatives --set mta /usr/sbin/sendmail.postfix

#RUN yum install -y mailx

WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/
    
RUN if [ ! -d "${SRC_DIR}/${ZOOKEEPER_VER}" ]; then                             \
        curl -sSL ${ZOOKEEPER_SRC_URL} -o ${SRC_DIR}/${ZOOKEEPER_VER}.tar.gz;   \
        tar -zxvf ${SRC_DIR}/${ZOOKEEPER_VER}.tar.gz;                           \
        rm -f ${SRC_DIR}/${ZOOKEEPER_VER}.tar.gz;                               \
    fi    

RUN mkdir -p ${ZOOKEEPER_PREFIX}                                                             	\
    && mv ${SRC_DIR}/${ZOOKEEPER_VER}/* ${ZOOKEEPER_PREFIX}                                     \
    && cp ${ZOOKEEPER_PREFIX}/conf/zoo_sample.cfg ${ZOOKEEPER_CONF}                             \
    && sed -i "s/^[\#]*dataDir=.*/dataDir=\/var\/lib\/zookeeper/" ${ZOOKEEPER_CONF}             \
    && sed -i "s/&[\#]*clientPort=.*/clientPort=${ZOOKEEPER_CLIENT_PORT}/" ${ZOOKEEPER_CONF}
    
	
################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "\n ZOOKEEPER_USER='${ZOOKEEPER_USER}' \n ZOOKEEPER_GROUP='${ZOOKEEPER_GROUP}' \n ZOOKEEPER_PREFIX='${ZOOKEEPER_PREFIX}' \n ZOOKEEPER_CONF='${ZOOKEEPER_CONF}' \n ZOOKEEPER_LOG_DIR='${ZOOKEEPER_LOG_DIR}' \n ZOOKEEPER_DATA_DIR='${ZOOKEEPER_DATA_DIR}' \n ZOOKEEPER_CLIENT_PORT='${ZOOKEEPER_CLIENT_PORT}'" >> ${ENT_CONST_SCRIPT}         \
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


# /script/entrypoint.sh redis-server /etc/redis.conf

# zkServer.sh start    				daemon running
# zkServer.sh start-foreground 		
ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/local/zookeeper/bin/zkServer.sh", "start-foreground"]


