FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

#http://mosquitto.org/
ENV MOSQUITTO_VER mosquitto-1.4.10
ENV MOSQUITTO_SRC_URL http://mosquitto.org/files/source/${MOSQUITTO_VER}.tar.gz

ENV MOSQUITTO_USER  ${SHARED_USER}
ENV MOSQUITTO_GROUP ${SHARED_GROUP}

WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/
RUN if [ ! -d "${SRC_DIR}/${MOSQUITTO_VER}" ]; then                             \
        curl -sSL ${MOSQUITTO_SRC_URL} -o ${SRC_DIR}/${MOSQUITTO_VER}.tar.gz;   \
        tar -zxvf ${SRC_DIR}/${MOSQUITTO_VER}.tar.gz;                           \
        rm -f ${SRC_DIR}/${MOSQUITTO_VER}.tar.gz;                               \
    fi
    
WORKDIR ${SRC_DIR}/${MOSQUITTO_VER}
ENV MOSQUITTO_PREFIX ${PREFIX_BASE}/mosquitto
RUN yum install -y c-ares-devel libuuid-devel
RUN make && make install prefix=${MOSQUITTO_PREFIX}

# MQTT
#   mosquitto
#   mosquitto_pub               --> MQTT publisher
#   mosquitto_sub               --> MQTT subscriber
#   mosquitto_passwd
# Usage:
#   ./sbin/mosquitto -c /etc/mosquitto/mosquitto.conf -d
#   ./bin/mosquitto_sub -t mqtt
#   ./bin/mosquitto_pub -t mqtt -m "Hello, Aario!"
#   ./bin/mosquitto_pub -t mqtt2 -m "Hello, Aario Session 2!"
#   mosquitto_pub
#    -A : bind the outgoing socket to this host/ip address. Use to control which interface the client communicates over.
#    -d : enable debug messages.
#    -f : send the contents of a file as the message.
#    -h : mqtt host to connect to. Defaults to localhost.
#    -i : id to use for this client. Defaults to mosquitto_pub_ appended with the process id.
#    -I : define the client id as id_prefix appended with the process id. Useful for when the broker is using the clientid_prefixes option.
#    -k : keep alive in seconds for this client. Defaults to 60.
#    -l : read messages from stdin, sending a separate message for each line.
#    -m : message payload to send.
#    -M : the maximum inflight messages for QoS 1/2..
#    -n : send a null (zero length) message.
#    -p : network port to connect to. Defaults to 1883.
#    -P : provide a password (requires MQTT 3.1 broker)
#    -q : quality of service level to use for all messages. Defaults to 0.
#    -r : message should be retained.
#    -s : read message from stdin, sending the entire input as a message.
#    -S : use SRV lookups to determine which host to connect to.
#    -t : mqtt topic to publish to.
#    -u : provide a username (requires MQTT 3.1 broker)
#    -V : specify the version of the MQTT protocol to use when connecting. Can be mqttv31 or mqttv311. Defaults to mqttv31.
#    --help : display this message.
#    --quiet : don't print error messages.
#    --will-payload : payload for the client Will, which is sent by the broker in case of unexpected disconnection. If not given and will-topic is set, a zero length message will be sent.
#    --will-qos : QoS level for the client Will.
#    --will-retain : if given, make the client Will retained.
#    --will-topic : the topic on which to publish the client Will.
#    --cafile : path to a file containing trusted CA certificates to enable encrypted communication.
#    --capath : path to a directory containing trusted CA certificates to enable encrypted communication.
#    --cert : client certificate for authentication, if required by server.
#    --key : client private key for authentication, if required by server.
#    --ciphers : openssl compatible list of TLS ciphers to support.
#    --tls-version : TLS protocol version, can be one of tlsv1.2 tlsv1.1 or tlsv1. Defaults to tlsv1.2 if available.
 
RUN ln -s ${MOSQUITTO_PREFIX}/sbin/mosquitto    /usr/sbin/mosquitto         \
    && ln -s ${MOSQUITTO_PREFIX}/bin/mosquitto_pub /usr/bin/mosquitto_pub   \
    && ln -s ${MOSQUITTO_PREFIX}/bin/mosquitto_sub /usr/bin/mosquitto_sub   \
    && ln -s ${MOSQUITTO_PREFIX}/bin/mosquitto_passwd /usr/bin/mosquitto_passwd

RUN echo "${MOSQUITTO_PREFIX}/lib" > /etc/ld.so.conf.d/mosquitto_lib.conf   \
    && /sbin/ldconfig                                                       \
    && ln -s ${MOSQUITTO_PREFIX}/lib/libmosquitto.so.1 /usr/lib/libmosquitto.so.1
    
######### Configuration ##########
# TCP ports 8883 and 1883 are registered with IANA for MQTT TLS and non TLS communication respectively.
ENV MOSQUITTO_PORT 1883
ENV MOSQUITTO_CONF_DIR /etc/mosquitto
ENV MOSQUITTO_PID ${S_P_L_DIR}/mosquitto.pid
ENV MOSQUITTO_LOG_DIR /var/log/mosquitto
ENV MOSQUITTO_LOG ${MOSQUITTO_LOG_DIR}/mosquitto.log
ENV MOSQUITTO_CONF ${MOSQUITTO_CONF_DIR}/mosquitto.conf


RUN if [ ! -d "${MOSQUITTO_LOG_DIR}" ]; then        \
        mkdir -p "${MOSQUITTO_LOG_DIR}";            \
        chmod a+w "${MOSQUITTO_LOG_DIR}";           \
    fi

RUN if [ ! -d "${MOSQUITTO_CONF_DIR}" ]; then       \
        mkdir -p "${MOSQUITTO_CONF_DIR}";           \
        chmod a+r "${MOSQUITTO_CONF_DIR}";          \
    fi
RUN if [ ! -f "${MOSQUITTO_CONF}" ]; then                \
        if [ -f "${MOSQUITTO_CONF_DIR}/mosquitto.conf.example" ]; then      \
            cp "${MOSQUITTO_CONF_DIR}/mosquitto.conf.example" "${MOSQUITTO_CONF}";    \
        else                                                                \
            touch "${MOSQUITTO_CONF}";                    \
        fi                                                                  \
    fi
    
RUN sed -i '/^#/d' ${MOSQUITTO_CONF}        \
    && sed -Ei 's/^(user|pid_file|port|bind_address|log_dest|log_facility|log_type|remote_user|remote_password)[\s=]/#&/' ${MOSQUITTO_CONF}                 \
    && echo -e "\nuser ${MOSQUITTO_USER}\npid_file ${MOSQUITTO_PID}\nport ${MOSQUITTO_PORT}\nlog_dest file ${MOSQUITTO_LOG}\nlog_facility 5\nlog_type error\n" >> ${MOSQUITTO_CONF}     \
    && sed -i '/^$/d' ${MOSQUITTO_CONF}
#######################################
    
    
################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "\n MOSQUITTO_VER='${MOSQUITTO_VER}' \n MOSQUITTO_USER='${MOSQUITTO_USER}' \n MOSQUITTO_GROUP='${MOSQUITTO_GROUP}' \n MOSQUITTO_PREFIX='${MOSQUITTO_PREFIX}' \n MOSQUITTO_LOG_DIR='${MOSQUITTO_LOG_DIR}' \n MOSQUITTO_LOG='${MOSQUITTO_LOG}' \n MOSQUITTO_CONF='${MOSQUITTO_CONF}'" >> ${ENT_CONST_SCRIPT}  \
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


# -d   do not make it run as a daemon process
ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/local/mosquitto/sbin/mosquitto", "-c", "/etc/mosquitto/mosquitto.conf"]


# MOSQUITTO_REMOTE_USER
# MOSQUITTO_REMOTE_PASSWORD
# TCP ports 8883 and 1883 are registered with IANA for MQTT TLS and non TLS communication respectively.
# docker run -d --restart=always --name aa_mosquitto --privileged=true -p 1883:1883 -p 8883:8883 -v /SyncGits/Depository/data/mosquitto:/var/lib/mosquitto -v /SyncGits/Depository/data/log/mosquitto:/var/log -e MOSQUITTO_PASSWORD=Aario -e MOSQUITTO_REMOTE_USER=Aa -e MOSQUITTO_REMOTE_PASSWORD=Aario -e ENTRYPOINT_LOG=/var/log/mosquitto/docker_entrypoint.log -e UPDATE_REPO=0 -e GEN_SSL_CRT=crt2048,crt4096,dhparam2048,dhparam4096 -e TIMEZONE=Asia/Shanghai -it aario/mosquitto