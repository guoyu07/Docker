FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

# Testing Tools
ENV HTTP_LOAD_VER http_load-09Mar2016
ENV HTTP_LOAD_SRC_URL http://www.acme.com/software/http_load/${HTTP_LOAD_VER}.tar.gz

ENV SIEGE_VER siege-4.0.2
ENV SIEGE_SRC_URL http://download.joedog.org/siege/${SIEGE_VER}.tar.gz

ENV APR_VER apr-1.5.2
ENV APR_SRC_URL http://mirrors.tuna.tsinghua.edu.cn/apache//apr/${APR_VER}.tar.gz
ENV APR_PREFIX /usr/local/apr

ENV APR_UTIL_VER apr-util-1.5.4
ENV APR_UTIL_SRC_URL http://mirrors.tuna.tsinghua.edu.cn/apache//apr/${APR_UTIL_VER}.tar.gz
ENV APR_UTIL_PREFIX /usr/local/apr-util

ENV APACHE_VER httpd-2.4.23
ENV APACHE_SRC_URL http://mirrors.tuna.tsinghua.edu.cn/apache//httpd/${APACHE_VER}.tar.gz

# Javascript Tools
RUN curl -sSL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo	\
	&& yum update -y && yum install -y nodejs yarn babel

WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/
RUN if [ ! -d "${SRC_DIR}/${HTTP_LOAD_VER}" ]; then                            \
        curl -sSL ${HTTP_LOAD_SRC_URL} -o ${SRC_DIR}/${HTTP_LOAD_VER}.tar.gz;  \
        tar -zxvf ${SRC_DIR}/${HTTP_LOAD_VER}.tar.gz;                          \
        rm -f ${SRC_DIR}/${HTTP_LOAD_VER}.tar.gz;                              \
    fi
    
RUN if [ ! -d "${SRC_DIR}/${SIEGE_VER}" ]; then                             \
        curl -sSL ${SIEGE_SRC_URL} -o ${SRC_DIR}/${SIEGE_VER}.tar.gz;       \
        tar -zxvf ${SRC_DIR}/${SIEGE_VER}.tar.gz;                           \
        rm -f ${SRC_DIR}/${SIEGE_VER}.tar.gz;                               \
    fi

RUN if [ ! -d "${SRC_DIR}/${APR_VER}" ]; then                           \
        curl -sSL ${APR_SRC_URL} -o ${SRC_DIR}/${APR_VER}.tar.gz;       \
        tar -zxvf ${SRC_DIR}/${APR_VER}.tar.gz;                         \
        rm -f ${SRC_DIR}/${APR_VER}.tar.gz;                             \
    fi
    
RUN if [ ! -d "${SRC_DIR}/${APR_UTIL_VER}" ]; then                            \
        curl -sSL ${APR_UTIL_SRC_URL} -o ${SRC_DIR}/${APR_UTIL_VER}.tar.gz;   \
        tar -zxvf ${SRC_DIR}/${APR_UTIL_VER}.tar.gz;                          \
        rm -f ${SRC_DIR}/${APR_UTIL_VER}.tar.gz;                              \
    fi
    
RUN if [ ! -d "${SRC_DIR}/${APACHE_VER}" ]; then                            \
        curl -sSL ${APACHE_SRC_URL} -o ${SRC_DIR}/${APACHE_VER}.tar.gz;     \
        tar -zxvf ${SRC_DIR}/${APACHE_VER}.tar.gz;                          \
        rm -f ${SRC_DIR}/${APACHE_VER}.tar.gz;                              \
    fi
    
    
WORKDIR ${SRC_DIR}/${HTTP_LOAD_VER}
RUN mkdir /usr/local/man && make && make install

WORKDIR ${SRC_DIR}/${SIEGE_VER}
RUN ./configure --prefix=/usr/local/siege --with-ssl && make && make install \
    && ln /usr/local/siege/bin/siege /usr/local/bin/siege                   \
    && ln /usr/local/siege/bin/bombardment /usr/local/bin/bombardment

WORKDIR ${SRC_DIR}/${APR_VER}
RUN ./configure --prefix=${APR_PREFIX} && make && make install

WORKDIR ${SRC_DIR}/${APR_UTIL_VER}
RUN ./configure --prefix=${APR_UTIL_PREFIX}     \
    --with-apr=${APR_PREFIX}                    \
    && make && make install


WORKDIR ${SRC_DIR}/${APACHE_VER}
RUN ./configure --prefix=/usr/local/apache      \
    --with-apr=${APR_PREFIX}                    \
    --with-apr-util=${APR_UTIL_PREFIX}          \
    && make && make install                     \
    && ln /usr/local/apache/bin/ab /usr/local/bin/ab

################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "" >>${ENT_CONST_SCRIPT}       \
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

ENTRYPOINT ["/aa_script/entrypoint.sh"]