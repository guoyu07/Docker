FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

# http://pecl.php.net/package-stats.php

ENV PHP_VER php-7.0.15
ENV PHP_SRC_URL http://cn.php.net/distributions/${PHP_VER}.tar.gz
ENV PHP_USER ${SHARED_USER}
ENV PHP_GROUP ${SHARED_GROUP}

WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/
RUN if [ ! -d "${SRC_DIR}/${PHP_VER}" ]; then                               \
        curl -sSL ${PHP_SRC_URL} -o ${SRC_DIR}/${PHP_VER}.tar.gz;           \
        tar -zxvf ${SRC_DIR}/${PHP_VER}.tar.gz;                             \
        rm -f ${SRC_DIR}/${PHP_VER}.tar.gz;                                 \
    fi

# RUN 
   						# \
    # && yum install -y libicu-devel openldap-devel bzip2* libtidy* 			\
                   # \
    # && yum install -y glibc glibc-devel glib2 glib2-devel

ENV PHP_PREFIX ${PREFIX_BASE}/php
ENV PHP_CONF_SCAN_DIR ${PHP_PREFIX}/etc

WORKDIR ${SRC_DIR}/${PHP_VER}
#	--with-pdo_mysql=mysqlnd
#	--with-pdo_pgsql
# http://php.net/manual/en/configure.about.php
#	--with-mysqli=mysqlnd                                   \
#	http://php.net/manual/zh/mysqli.installation.php
# --gettext    for locale http://php.net/manual/zh/book.gettext.php
# Debug
#   --enable-phpdbg                                         \
#   --enable-phpdbg-debug                                   \
#   --enable-debug                                          \
RUN ./configure                                             \
    --prefix="${PHP_PREFIX}"                                \
    --with-config-file-scan-dir="${PHP_CONF_SCAN_DIR}"      \
    --enable-fpm                                            \
    --with-fpm-user=${PHP_USER}                             \
    --with-fpm-group=${PHP_GROUP}                           \
    --disable-short-tags                                    \
    --with-openssl                                          \
    --enable-mbstring                                       \
    --enable-opcache                                        \
	--enable-opcache-file									\
    --with-gettext                                          \
    --enable-sockets                                        \
    --with-mhash                                            \
    --enable-bcmath                                         \
	--with-pdo-mysql=mysqlnd 								\ 	
    && make && make install && make clean
	
################### configurations7 ###############
ENV PHPFPM_PORT 9000
ENV PHP_LOG_DIR /var/log/php
ENV WWW_HTDOCS /var/lib/htdocs
    
COPY ./etc/* ${PHP_CONF_SCAN_DIR}/
    
WORKDIR ${PHP_CONF_SCAN_DIR}
RUN chown -R ${PHP_USER}:${PHP_GROUP} ${PHP_CONF_SCAN_DIR}
RUN chmod -R g+rx ${PHP_CONF_SCAN_DIR}

RUN if [ ! -d "${PHP_CONF_SCAN_DIR}/php-fpm.d" ]; then mkdir -p ${PHP_CONF_SCAN_DIR}/php-fpm.d; fi

RUN if [ ! -f "${PHP_CONF_SCAN_DIR}/php-fpm.conf" ]; then                                       \
        if [ -f "${PHP_CONF_SCAN_DIR}/php-fpm.conf.default" ]; then                             \
            cp "${PHP_CONF_SCAN_DIR}/php-fpm.conf.default" "${PHP_CONF_SCAN_DIR}/php-fpm.conf"; \
        else                                                                                    \
            touch "${PHP_CONF_SCAN_DIR}/php-fpm.conf";                                          \
        fi                                                                                      \
    fi

RUN if [ ! -f "${PHP_CONF_SCAN_DIR}/php-fpm.d/www.conf" ]; then cp "${PHP_CONF_SCAN_DIR}/php-fpm.d/www.conf.default" "${PHP_CONF_SCAN_DIR}/php-fpm.d/www.conf"; fi

RUN if [ ! -f "${PHP_CONF_SCAN_DIR}/php.ini" ]; then touch "${PHP_CONF_SCAN_DIR}/php.ini"; fi

# to check whether host allow hugepages
RUN echo | awk '{"cat /proc/sys/vm/nr_hugepages" | getline s;if(s > 0){print("opcache.huge_code_pages=1") >> "opcache.ini"}}'

RUN sed -i "s/^[\s;]*listen\s*=.*/listen=[::]:${PHPFPM_PORT}/"  ${PHP_CONF_SCAN_DIR}/php-fpm.conf     \
    && sed -i "s/^[\s;]*user\s*=.*/user=${PHP_USER}/"              ${PHP_CONF_SCAN_DIR}/php-fpm.conf  \
    && sed -i "s/^[\s;]*group\s*=.*/group=${PHP_GROUP}/"           ${PHP_CONF_SCAN_DIR}/php-fpm.conf  \
    && sed -i "s/^[\s;]*listen\s*=.*/listen=[::]:${PHPFPM_PORT}/"  ${PHP_CONF_SCAN_DIR}/php-fpm.d/www.conf     \
    && sed -i "s/^[\s;]*user\s*=.*/user=${PHP_USER}/"              ${PHP_CONF_SCAN_DIR}/php-fpm.d/www.conf  \
    && sed -i "s/^[\s;]*group\s*=.*/group=${PHP_GROUP}/"           ${PHP_CONF_SCAN_DIR}/php-fpm.d/www.conf
#################################################

################## extensions 7 ####################
ENV PHP_EXT_SRC             ${PHP_PREFIX}/src/ext
ENV PHP_EXT_DEPENDENCIES    ${PHP_EXT_SRC}/_dependencies

RUN if [ ! -d "${PHP_EXT_SRC}" ]; then mkdir -p "${PHP_EXT_SRC}"; fi
RUN if [ "${PHP_EXT_SRC}" != "${SRC_DIR}/${PHP_VER}/ext" ]; then mv ${SRC_DIR}/${PHP_VER}/ext/* "${PHP_EXT_SRC}/"; fi
    
ADD ./ext/* ${PHP_EXT_SRC}/
ADD ./ext_dependencies/* ${PHP_EXT_DEPENDENCIES}/

WORKDIR ${PHP_EXT_SRC}

COPY ./bin/* /usr/bin/
# Notice: ${PHP_EXT_SRC} includes '/'
RUN sed -i 's/^\s*#\!\/bin\/bash\s*$//g' /usr/bin/docker-php-ext-*      \
    && sed -i 's/^\s*set\s*\-e\s*$//g' /usr/bin/docker-php-ext-*        \
    && sed -i "1s/.*/\#\!\/bin\/bash\nset \-e\n\. \/aa_script\/entrypointConst\.sh\n&/" /usr/bin/docker-php-ext-*   \
    && sed -i 's/\r$//' /usr/bin/docker-php-ext-*

################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "\n PHP_VER='${PHP_VER}' \n PHP_SRC_URL='${PHP_SRC_URL}' \n PHP_EXT_SRC='${PHP_EXT_SRC}' \n PHP_EXT_DEPENDENCIES='${PHP_EXT_DEPENDENCIES}' \n PHP_GROUP='${PHP_GROUP}' \n PHP_USER='${PHP_USER}' \n PHP_PREFIX='${PHP_PREFIX}' \n PHP_CONF_SCAN_DIR='${PHP_CONF_SCAN_DIR}' \n PHP_LOG_DIR='${PHP_LOG_DIR}' \n WWW_HTDOCS='${WWW_HTDOCS}'" >> ${ENT_CONST_SCRIPT}         \
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

RUN ln ${PHP_PREFIX}/sbin/php-fpm       /usr/sbin/php-fpm   \
	&& ln ${PHP_PREFIX}/bin/php         /usr/bin/php        \
	&& ln ${PHP_PREFIX}/bin/phpize      /usr/bin/phpize     \
	&& ln ${PHP_PREFIX}/bin/php-config  /usr/bin/php-config
# /aa_script/entrypoint.sh php-fpm -F
ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/local/php/sbin/php-fpm", "-F"]

#COLUME ['/var/lib/htdocs', '/var/log']