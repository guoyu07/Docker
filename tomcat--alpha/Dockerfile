FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

ENV TOMCAT_VER apache-tomcat-8.0.35

#WORKDIR ${ENT_DIR}/src
#RUN curl -sSL http://apache.fayea.com/tomcat/tomcat-8/v8.0.35/bin/${TOMCAT_VER}.tar.gz -o ${TOMCAT_VER}.tar.gz
#RUN tar -zxvf ${TOMCAT_VER}.tar.gz && rm ${TOMCAT_VER}.tar.gz

ADD ./src/* ${SRC_DIR}/



RUN yum install -y java

ENV TOMCAT_PREFIX ${PREFIX_BASE}/tomcat

RUN mkdir -p ${TOMCAT_PREFIX}
RUN mv ${SRC_DIR}/${TOMCAT_VER} ${TOMCAT_PREFIX}

COPY ./conf/ ${TOMCAT_PREFIX}/conf/

ENV TOMCAT_LOG_DIR /var/log/tomcat
RUN mkdir -p ${TOMCAT_LOG_DIR}
################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "" >> ${ENT_CONST_SCRIPT}               \
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
RUN ln -sf /dev/stdout ${TOMCAT_LOG_DIR}/stdout.log     \
    && ln -sf /dev/stderr ${TOMCAT_LOG_DIR}/stderr.log

ENTRYPOINT ["/ent/entrypoint.sh"]
CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]

#docker run -d --restart=always --name aa_tomcat --privileged=true -p 58080:8080 -v /SyncGits/Depository/data/log/tomcat/:/usr/local/tomcat/logs  -e ENTRYPOINT_LOG=/usr/local/tomcat/logs/docker_entrypoint.log -v /SyncGits/Depository/htdocs/webapps:/usr/local/tomcat/webapps -e UPDATE_REPO=0 -e GEN_SSL_CRT=crt2048,crt4096,dhparam2048,dhparam4096 -e TIMEZONE=Asia/Shanghai -it aario/tomcat:alpha