FROM aario/redis
MAINTAINER Aario <AarioAi@gmail.com>



########### configuration #################
#ENV RDS_PORT    46379


RUN sed -Ei 's/^\s*(port)\s*/#&/' ${RDS_CONF}           \
    && sed -i '/^#/d' ${RDS_CONF} 

#RUN sed -i "1a port ${RDS_PORT}\n" ${RDS_CONF}


RUN rm -rf /tmp/redis.conf.d && mkdir /tmp/redis.conf.d
COPY ./etc/redis_conf.d/* /tmp/redis.conf.d/
RUN if [ ! -z "$(ls /tmp/redis.conf.d/*.conf)" ]; then  \
        for c in `ls /tmp/redis.conf.d/*.conf`;         \
        do echo -e "\n" >> "${RDS_CONF}";               \
        cat $c >> ${RDS_CONF}; done;                    \
    fi
RUN cp ${RDS_CONF} /tmp/redis.conf
################ Entrypoing ########################
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/
RUN rm -rf /tmp/spool && mkdir /tmp/spool
COPY ./spool/* /tmp/spool
RUN if [ -f "/tmp/spool/crontab" ]; then                \
        if [ -f "/etc/crontab" ]; then                  \
            yes | cp /etc/crontab /etc/crontab-cp1;     \
            cat /tmp/spool/crontab >> /etc/crontab;     \
        else                                            \
            mv /tmp/spool/crontab /etc/crontab;         \
        fi;                                             \
        sort -k2n "/etc/crontab" | sed '$!N; /^\(.*\)\n\1$/!P; D' > "/tmp/crontab";    \
        yes | mv "/tmp/crontab" "/etc/crontab";         \
        yes | cp /etc/crontab /etc/crontab-cp2;         \
        rm -rf /tmp/spool;                              \
    fi
RUN yum clean all && rm -rf ${SRC_DIR}/*
#################################################

