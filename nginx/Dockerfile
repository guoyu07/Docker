FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

ENV NGX_VER nginx-1.10.2
ENV NGINX_SRC_URL http://nginx.org/download/${NGX_VER}.tar.gz

ENV NGX_USER ${SHARED_USER}
ENV NGX_GROUP ${SHARED_GROUP}

WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/
RUN if [ ! -d "${SRC_DIR}/${NGX_VER}" ]; then                               \
        curl -sSL ${NGINX_SRC_URL} -o ${SRC_DIR}/${NGX_VER}.tar.gz;         \
        tar -zxvf ${SRC_DIR}/${NGX_VER}.tar.gz;                             \
        rm -f ${SRC_DIR}/${NGX_VER}.tar.gz;                                 \
    fi

WORKDIR ${SRC_DIR}/${NGX_VER}

ENV NGX_PREFIX ${PREFIX_BASE}/nginx
ENV NGX_CONF_PATH /etc/nginx/nginx.conf

RUN mkdir -p ${CACHE_DIR}/nginx && chown -R ${NGX_USER}:${NGX_GROUP} ${CACHE_DIR}/nginx

RUN ./configure                                 \
    --prefix=${NGX_PREFIX}                      \
    --sbin-path=/usr/sbin/nginx                 \
    --conf-path=${NGX_CONF_PATH}                \
    --error-log-path=/var/log/nginx/error.log   \
    --http-log-path=/var/log/nginx/access.log   \
    --pid-path=${S_P_L_DIR}/nginx.pid           \
    --lock-path=${S_P_L_DIR}/nginx.lock         \
    --http-client-body-temp-path=/var/cache/nginx/client_temp   \
    --http-proxy-temp-path=/var/cache/nginx/proxy_temp          \
    --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp      \
    --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp          \
    --http-scgi-temp-path=/var/cache/nginx/scgi_temp            \
    --user=${NGX_USER}                          \
    --group=${NGX_GROUP}                        \
    --with-http_ssl_module                      \
    --with-threads                              \
    --with-file-aio                             \
    --with-http_v2_module                       \
    --with-ipv6                                 \
    && make && make install



######### Configuration ##########

# Nginx Configurations

ENV NGX_LOG_DIR /var/log/nginx
ENV WWW_HTDOCS /var/lib/htdocs
ENV NGX_INCLUDE_CONF_DIR /etc/nginx/conf.d

RUN mkdir -p ${NGX_LOG_DIR}                                             \
    && chown -R ${NGX_USER}:${NGX_GROUP} ${NGX_LOG_DIR}                 \
    && chmod -R u+w ${NGX_LOG_DIR}                                      \
    && mkdir -p /var/lib/htdocs && chgrp -R ${NGX_GROUP} ${WWW_HTDOCS}  \
    && chmod -R g+rwx ${WWW_HTDOCS}
RUN mkdir -p ${NGX_INCLUDE_CONF_DIR}                                  \
    && chown -R ${NGX_USER}:${NGX_GROUP} /etc/nginx/            \
    && chmod -R u+rw /etc/nginx/
    
COPY ./etc/nginx.conf ${NGX_CONF_PATH}
COPY ./etc/conf.d/* ${NGX_INCLUDE_CONF_DIR}/

RUN sed -Ei "s/^\s*(user|daemon\s)/#&/" ${NGX_CONF_PATH}        \
    && sed -Ei "1a user ${NGX_USER} ${NGX_GROUP};\ndaemon off;" ${NGX_CONF_PATH}    \
    && sed -i 's/^\s*include\s*.*\*\.conf\s*;\s*$/include \/etc\/nginx\/conf\.d\/\*\.conf;/' ${NGX_CONF_PATH}
#######################################


################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "\n NGX_VER='${NGX_VER}' \n NGINX_SRC_URL='${NGINX_SRC_URL}' \n NGX_USER='${NGX_USER}' \n NGX_PREFIX='${NGX_PREFIX}' \n NGX_CONF_PATH='${NGX_CONF_PATH}' \n NGX_INCLUDE_CONF_DIR='${NGX_INCLUDE_CONF_DIR}' \n NGX_LOG_DIR='${NGX_LOG_DIR}' \n WWW_HTDOCS='${WWW_HTDOCS}'" >> ${ENT_CONST_SCRIPT}          \
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

# , "-g", "daemon off;"

ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/sbin/nginx"]
#VOLUME ['/var/lib/htdocs', '/var/log']
