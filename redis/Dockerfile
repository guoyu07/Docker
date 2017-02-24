FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

ENV RDS_VER     redis-3.2.6
ENV RDS_SRC_URL http://download.redis.io/releases/${RDS_VER}.tar.gz
ENV RDS_USER    ${SHARED_USER}
ENV RDS_GROUP   ${SHARED_GROUP}

WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/
RUN if [ ! -d "${SRC_DIR}/${RDS_VER}" ]; then                       \
        curl -sSL ${RDS_SRC_URL} -o ${SRC_DIR}/${RDS_VER}.tar.gz;   \
        tar -zxvf ${SRC_DIR}/${RDS_VER}.tar.gz;                     \
        rm -f ${SRC_DIR}/${RDS_VER}.tar.gz;                         \
    fi
    
WORKDIR ${SRC_DIR}/${RDS_VER}
#RUN yum install -y tcl              ---> for make test
RUN make && make install

########### configuration #################
ENV RDS_PORT        6379
ENV RDS_CONF        /etc/redis/redis.conf
ENV RDS_DATA_DIR    /var/lib/redis
ENV RDS_LOG_DIR     /var/log/redis

COPY ./etc/redis/redis.conf /etc/redis/redis.conf
RUN chown -R ${RDS_USER}:${RDS_GROUP} /etc/redis && chmod -R u+r /etc/redis


#RUN if [ $(cat "/proc/sys/net/core/somaxconn") -lt 511 ]; then      \
#        chmod a+w "/proc/sys/net/core/somaxconn"                    \
#        echo "511" > "/proc/sys/net/core/somaxconn";                \ 
#    fi
#RUN if [ ! -f "/etc/sysctl.conf" ]; then    \
#        touch "/etc/sysctl.conf"            \
#    fi
#RUN chmod a+w "/etc/sysctl.conf"
#RUN sed -i 's/^\s*vm\.overcommit_memory.*//g' "/etc/sysctl.conf"
#RUN echo -e  echo "\nvm.overcommit_memory = 1\n" >> "/etc/sysctl.conf"

#RUN chmod a+w "/sys/kernel/mm/transparent_hugepage/enabled"
#RUN echo "never" > "/sys/kernel/mm/transparent_hugepage/enabled"

RUN mkdir -p ${RDS_DATA_DIR} ${RDS_LOG_DIR}                             \
	&& chown -R ${RDS_USER}:${RDS_GROUP} ${RDS_DATA_DIR} ${RDS_LOG_DIR}	\
    && chmod -R u+rwx ${RDS_DATA_DIR} ${RDS_LOG_DIR}

RUN sed -Ei 's/^\s*(daemonize|port|dir|logfile)\s*/#&/' ${RDS_CONF}     \
    && sed -i '/^#/d' ${RDS_CONF}                                       \
    && sed -i "1adaemonize no\nport ${RDS_PORT}\ndir ${RDS_DATA_DIR}\nlogfile ${RDS_LOG_DIR}/redis.log\n" ${RDS_CONF}
RUN cp ${RDS_CONF} /tmp/redis.conf
###########################################





################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "\n RDS_VER='${RDS_VER}' \n RDS_SRC_URL='${RDS_SRC_URL}' \n RDS_USER='${RDS_USER}' \n RDS_GROUP='${RDS_GROUP}' \n RDS_CONF='${RDS_CONF}' \n RDS_DATA_DIR='${RDS_DATA_DIR}' \n RDS_LOG_DIR='${RDS_LOG_DIR}'" >>${ENT_CONST_SCRIPT}       \
    && sed -i 's/^\s*//g' ${ENT_CONST_SCRIPT}

RUN rm -rf /tmp/spool && mkdir /tmp/spool
COPY ./spool/* /tmp/spool
RUN if [ -f "/tmp/spool/crontab" ]; then                    \
        if [ -f "/etc/crontab" ]; then                      \
            yes | cp /etc/crontab /etc/crontab-cp1;         \
            cat /tmp/spool/crontab >> /etc/crontab;         \
        else                                                \
            mv /tmp/spool/crontab /etc/crontab;             \
        fi;                                                 \
        sort -k2n "/etc/crontab" | sed '$!N; /^\(.*\)\n\1$/!P; D' > "/tmp/crontab";    \
        yes | mv "/tmp/crontab" "/etc/crontab";             \
        yes | cp /etc/crontab /etc/crontab-cp2;             \
        rm -rf /tmp/spool;                                  \
    fi
RUN yum clean all && rm -rf ${SRC_DIR}/*
#################################################

#EXPOSE ${RDS_PORT}
#VOLUME "${RDS_DATA_DIR}"
#VOLUME "${RDS_LOG_DIR}"

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/stdout.log    		\
    && ln -sf /dev/stderr /var/log/stderr.log

#  in docker, you can't run service as daemon or in background
# /script/entrypoint.sh redis-server /etc/redis/redis.conf
ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/local/bin/redis-server", "/etc/redis/redis.conf"]

#CMD ["redis-server", "/etc/redis/redis.conf"]
#CMD ["crontab", "/script/init.d/crontab.job"]
#VOLUME ['/var/log', '/var/lib/redis']
#EXPOSE 6379