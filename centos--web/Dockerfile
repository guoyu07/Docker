FROM centos:centos7
MAINTAINER Aario <AarioAi@gmail.com>

# use for `make -j $cpu_core_num`
# make -j `grep processor /proc/cpuinfo | wc -l`
#ENV CPU_CORE_NUM 4

#ENV GCC_VER     gcc-5.3.0

# Users and Groups
#   WWW     [client] --> nginx - phpfpm  shared
ENV SHARED_GROUP Aario
ENV SHARED_USER Aario
RUN groupadd -r ${SHARED_GROUP}												\
	&& useradd -d /home/${SHARED_USER} -m -g ${SHARED_GROUP} ${SHARED_USER}


# System Directories
ENV SYS_CONF_DIR    /etc
#   S_P_L_DIR   Lock files
#   @warning, /var/lock direcotry is disabled in docker container
#ENV S_P_L_DIR       /var/lock
#   S_P_L_DIR     pid and sock
#ENV S_P_L_DIR         /var/run

# Spool  --> queue
ENV SPOOL_DIR       /var/spool
#ENV CRON_DIR        ${SPOOL_DIR}/cron
ENV CRONTAB_FILE    /etc/crontab
#ENV AT_DIR          ${SPOOL_DIR}/at
ENV PREFIX_BASE     /usr/local
ENV SRC_DIR         /usr/local/src
ENV BIN_DIR         /usr/local/bin
ENV SBIN_DIR        /usr/local/sbin
ENV LIB_DIR         /usr/local/lib
ENV LIB64_DIR       /usr/local/lib64
ENV LIB_EXEC_DIR    /usr/local/libexec
ENV INCLUDE_DIR     /usr/local/include
ENV CACHE_DIR       /var/cache
ENV SSL_DIR         /etc/ssl
ENV LIB_DIR         /usr/lib64

# Self-Defined Directories
#   SCRIPT_DIR         Entrypoint Scripts
#               only root user executable shell scripts
#               warning don't run these scripts by non-root user!!
#   SYNC_DIR   backup data into SYNC_DIR, then transfer the data to remote backup servers with internet
#   S_P_L_DIR  .sock, .pid, .lock 
ENV S_P_L_DIR           /aa_run
ENV SHAREDSTATE_DIR     ${S_P_L_DIR}/com
ENV SCRIPT_DIR          /aa_script
ENV AUTORUN_SCRIPT_DIR  ${SCRIPT_DIR}/autorun
ENV SYNC_DIR            /aa_sync

RUN mkdir -p "${SHAREDSTATE_DIR}" 									\
	&& chown -R ${SHARED_USER}:${SHARED_GROUP} ${S_P_L_DIR}				\
	&& chmod -R g+rxw ${S_P_L_DIR}

RUN if [ ! -d "${SCRIPT_DIR}" ]; then                               \
        mkdir -p "${SCRIPT_DIR}";                                   \
        chmod -R u+x ${SCRIPT_DIR};                                 \
    fi
    
RUN if [ ! -d "${AUTORUN_SCRIPT_DIR}" ]; then                               \
        mkdir -p "${AUTORUN_SCRIPT_DIR}";                                   \
        chmod -R u+x ${AUTORUN_SCRIPT_DIR};                                 \
    fi

RUN if [ ! -d "${SYNC_DIR}" ]; then                      \
        mkdir -p "${SYNC_DIR}";                          \
        chmod -R a+rw ${SYNC_DIR};                       \
    fi
    
    
COPY ./etc/* /etc/
ADD ./src/* ${SRC_DIR}/

#####
# Linux Kernel Configurations for Web
# Redis
#   echo never > /sys/kernel/mm/transparent_hugepage/enabled
#   echo 511 > /proc/sys/net/core/somaxconn

 
# In Docker, the ulimit is already unlimited; You should not modify it any more. You can modify its hosts ulimit
#RUN echo "* soft nofile 262140\n* hard nofile 262140\nroot soft nofile 262140\nroot hard nofile 262140\n* soft core unlimited\n* hard core unlimited\nroot soft core unlimited\nroot hard core unlimited" >> /etc/security/limits.conf

# sysctl is not allowed to run in docker container
#RUN sysctl -p


    
# GCC Requires
#   dejagnu* libmpc-devel mpfr-devel gmp-devel
# yum upgrade and yum update will perform the same function that update to the latest current version of package.
#   But the difference is Upgrade will delete obsolete packages, while update will preserve them.
# && yum clean metadata && yum clean dbcache && yum makecache 
# Basic Tools
#   lua --> nginx php go
#   java --> logstash kibana elasticSearch
# Debug Tools
#   valgrind ctags vim
# Mail
#   postfix
#       postfix cyrus-sasl cyrus-sasl-plain mailx         
#       && curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim     \
#       && git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7                              \
    && yum update -y                                                                \
    && yum clean all                                                                \
    && yum install -y epel-release                                                  \
    && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7                             \
    && yum install -y gcc gcc-c++ java-openjdk lua-devel lua-static                 \
        autoconf automake make cmake net-tools curl tcl crontabs valgrind ctags     \
        binutils libtool pkg-config zlib-devel CUnit-devel libxml2-devel            \
        libev-devel libevent-devel Cython python3-dev python-setuptools             \
        openssl openssl-devel                                                       \
        git rsync                                                                   \
    && yum clean all

#####


##### SSL
# ENV OPENSSL_VER openssl-1.0.2h
# ENV OPENSSL_SRC_URL https://www.openssl.org/source/${OPENSSL_VER}.tar.gz
# ENV OPENSSL_PREFIX ${PREFIX_BASE}/openssl
# WORKDIR ${SRC_DIR}
# RUN if [ ! -d "${SRC_DIR}/${OPENSSL_VER}" ]; then                               \
        # curl -sSL ${OPENSSL_SRC_URL} -o ${SRC_DIR}/${OPENSSL_VER}.tar.gz;       \
        # tar -zxvf ${SRC_DIR}/${OPENSSL_VER}.tar.gz;                             \
        # rm -f ${SRC_DIR}/${OPENSSL_VER}.tar.gz;                                 \
    # fi
# WORKDIR ${SRC_DIR}/${OPENSSL_VER}
# # http://www.linuxfromscratch.org/blfs/view/cvs/postlfs/openssl.html
# #   Configurations
# #       hared: This parameter forces the creation of shared libraries along with the static libraries.
# #       zlib-dynamic: This parameter adds compression/decompression functionality using the libz library.
# #   Bin
# #       bin/c_rehash is a Perl script that scans all files in a directory and adds symbolic links to their hash values.
# #       bin/openssl is a command-line tool for using the various cryptography functions of OpenSSL's crypto library from the shell. It can be used for various functions which are documented in man 1 openssl.

# RUN ./config                        \
    # --prefix=${OPENSSL_PREFIX}      \
    # --openssldir=${SSL_DIR}         \
    # --libdir=${LIB_DIR}             \
    # shared                          
# RUN make depend && make && make install                                     \
    # && ln ${OPENSSL_PREFIX}/bin/openssl /usr/bin/openssl                    \
    # && ln ${OPENSSL_PREFIX}/bin/c_rehash /usr/bin/c_rehash                  \
    # && ln -s ${OPENSSL_PREFIX}/include/openssl /usr/include/openssl         \
    # && echo "${OPENSSL_PREFIX}/usr/lib64" >> /etc/ld.so.conf                \
    # && ldconfig

# ENV LIBEVENT_VER_NUM 2.0.22
# ENV LIBEVENT_VER libevent-${LIBEVENT_VER_NUM}
# ENV LIBEVENT_SRC_URL https://github.com/libevent/libevent/releases/download/release-${LIBEVENT_VER_NUM}-stable/${LIBEVENT_VER}-stable.tar.gz  
# ENV LIBEVENT_PREFIX ${PREFIX_BASE}/libevent
# WORKDIR ${SRC_DIR}
# RUN if [ ! -d "${SRC_DIR}/${LIBEVENT_VER}" ]; then                                  \
        # curl -sSL ${LIBEVENT_SRC_URL} -o ${SRC_DIR}/${LIBEVENT_VER}.tar.gz;         \
        # tar -zxvf ${SRC_DIR}/${LIBEVENT_VER}.tar.gz;                                \
        # rm -f ${SRC_DIR}/${LIBEVENT_VER}.tar.gz;                                    \
    # fi
# WORKDIR ${SRC_DIR}/${LIBEVENT_VER}
# RUN ./configure                         \
    # --prefix=${LIBEVENT_PREFIX}         \
    # --sysconfdir=${SYS_CONF_DIR}        \
    # --bindir=${BIN_DIR}                 \
    # --sbindir=${SBIN_DIR}               \
    # && make && make install

ENV JEMALLOC_VER_NUM 4.2.1
ENV JEMALLOC_VER jemalloc-${JEMALLOC_VER_NUM}
ENV JEMALLOC_SRC_URL https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VER_NUM}/${JEMALLOC_VER}.tar.bz2
ENV JEMALLOC_PREFIX ${PREFIX_BASE}/jemalloc
WORKDIR ${SRC_DIR}
RUN if [ ! -d "${SRC_DIR}/${JEMALLOC_VER}" ]; then                                  \
        curl -sSL ${JEMALLOC_SRC_URL} -o ${SRC_DIR}/${JEMALLOC_VER}.tar.gz;         \
        tar -zxvf ${SRC_DIR}/${JEMALLOC_VER}.tar.gz;                                \
        rm -f ${SRC_DIR}/${JEMALLOC_VER}.tar.gz;                                    \
    fi
WORKDIR ${SRC_DIR}/${JEMALLOC_VER}
RUN ./configure                         \
    --prefix=${JEMALLOC_PREFIX}         \
    --bindir=${BIN_DIR}                 \
    --sbindir=${SBIN_DIR}               \
    --sysconfdir=${SYS_CONF_DIR}        \
    --sharedstatedir=${SHAREDSTATE_DIR} \
    --runstatedir=${S_P_L_DIR}          \
    --libdir=${LIB_DIR}                 \
    --libexecdir=${LIB_EXEC_DIR}        \
    --includedir=${INCLUDE_DIR}         \
    && make && make install

ENV JANSSON_VER_NUM 2.7
ENV JANSSON_VER jansson-${JANSSON_VER_NUM}
ENV JANSSON_SRC_URL http://www.digip.org/jansson/releases/${JANSSON_VER}.tar.gz
ENV JANSSON_PREFIX ${PREFIX_BASE}/jansson
WORKDIR ${SRC_DIR}
RUN if [ ! -d "${SRC_DIR}/${JANSSON_VER}" ]; then                                  \
        curl -sSL ${JANSSON_SRC_URL} -o ${SRC_DIR}/${JANSSON_VER}.tar.gz;          \
        tar -zxvf ${SRC_DIR}/${JANSSON_VER}.tar.gz;                                \
        rm -f ${SRC_DIR}/${JANSSON_VER}.tar.gz;                                    \
    fi
WORKDIR ${SRC_DIR}/${JANSSON_VER}
RUN ./configure                         \
    --prefix=${JANSSON_PREFIX}          \
    --bindir=${BIN_DIR}                 \
    --sbindir=${SBIN_DIR}               \
    --sysconfdir=${SYS_CONF_DIR}        \
    --sharedstatedir=${SHAREDSTATE_DIR} \
    --libdir=${LIB_DIR}                 \
    --libexecdir=${LIB_EXEC_DIR}        \
    --includedir=${INCLUDE_DIR}         \
    && make && make install

# HTTP2
# Requires
#   binutils libtool pkg-config zlib-devel CUnit-devel libxml2-devel libev-devel libevent-devel Cython python3-dev python-setuptools
#    jemalloc jansson
#   openssl-devel
ENV NGHTTP2_VER_NUM 1.19.0
ENV NGHTTP2_VER nghttp2-${NGHTTP2_VER_NUM}
ENV NGHTTP2_SRC_URL https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VER_NUM}/${NGHTTP2_VER}.tar.gz
ENV NGHTTP2_PREFIX ${PREFIX_BASE}/nghttp2
WORKDIR ${SRC_DIR}
RUN if [ ! -d "${SRC_DIR}/${NGHTTP2_VER}" ]; then                                  \
        curl -sSL ${NGHTTP2_SRC_URL} -o ${SRC_DIR}/${NGHTTP2_VER}.tar.gz;         \
        tar -zxvf ${SRC_DIR}/${NGHTTP2_VER}.tar.gz;                                \
        rm -f ${SRC_DIR}/${NGHTTP2_VER}.tar.gz;                                    \
    fi
WORKDIR ${SRC_DIR}/${NGHTTP2_VER}
RUN ./configure                         \
    --prefix=${NGHTTP2_PREFIX}          \
    --bindir=${BIN_DIR}                 \
    --sbindir=${SBIN_DIR}               \
    --sysconfdir=${SYS_CONF_DIR}        \
    --sharedstatedir=${SHAREDSTATE_DIR} \
    --runstatedir=${S_P_L_DIR}          \
    --libdir=${LIB_DIR}                 \
    --libexecdir=${LIB_EXEC_DIR}        \
    --includedir=${INCLUDE_DIR}         \
    && make && make install

# Log Tools

# Logstash
#   Requires:
#       Ruby
#       Java-openjdk
#       Redis
#       ElasticSearch (there's one in logstash)
ENV LOGSTASH_VER logstash-5.1.2
ENV LOGSTASH_SRC_URL https://download.elastic.co/logstash/logstash/${LOGSTASH_VER}.tar.gz
ENV LOGSTASH_PREFIX ${PREFIX_BASE}/logstash
WORKDIR ${SRC_DIR}
RUN if [ ! -d "${SRC_DIR}/${LOGSTASH_VER}" ]; then                                  \
        curl -sSL ${LOGSTASH_SRC_URL} -o ${SRC_DIR}/${LOGSTASH_VER}.tar.gz;         \
        tar -zxvf ${SRC_DIR}/${LOGSTASH_VER}.tar.gz;                                \
        rm -f ${SRC_DIR}/${LOGSTASH_VER}.tar.gz;                                    \
    fi

RUN mkdir -p ${LOGSTASH_PREFIX}                                                     \         
    && mv ${SRC_DIR}/${LOGSTASH_VER}/* ${LOGSTASH_PREFIX}                              \
    && ln -s ${LOGSTASH_PREFIX}/bin/logstash ${BIN_DIR}/logstash

# KIBANA
#   Requires:
#       Ruby, Rubygems
#ENV KIBANA_VER kibana-4.5.0-linux-x64
#ENV KIBANA_SRC_URL https://download.elastic.co/kibana/kibana/${KIBANA_VER}.tar.gz

# Monitor Tools

# Keepalived
#   http://www.keepalived.org/pdf/UserGuide.pdf
#   Required:
#       OpenSSL
#       popt
# ENV KEEPALIVED_VER keepalived-1.3.2
# ENV KEEPALIVED_SRC_URL http://www.keepalived.org/software/${KEEPALIVED_VER}.tar.gz
# ENV KEEPALIVED_PREFIX ${PREFIX_BASE}/keepalived
# WORKDIR ${SRC_DIR}
# RUN if [ ! -d "${SRC_DIR}/${KEEPALIVED_VER}" ]; then                                \
        # curl -sSL ${KEEPALIVED_SRC_URL} -o ${SRC_DIR}/${KEEPALIVED_VER}.tar.gz;     \
        # tar -zxvf ${SRC_DIR}/${KEEPALIVED_VER}.tar.gz;                              \
        # rm -f ${SRC_DIR}/${KEEPALIVED_VER}.tar.gz;                                  \
    # fi
# WORKDIR ${SRC_DIR}/${KEEPALIVED_VER}

# #    --with-openssl=${OPENSSL_PREFIX}    \

# RUN ./configure                         \
    # --prefix=${KEEPALIVED_PREFIX}       \
    # --bindir=${BIN_DIR}                 \
    # --sbindir=${SBIN_DIR}               \
    # --sysconfdir=${SYS_CONF_DIR}        \
    # && make && make install
#RUN yes | cp ${KEEPALIVED_PREFIX}/etc/sysconfig/keepalived /etc/sysconfig/keepalived
#RUN chmod -R a+r /etc/sysconfig
#RUN ln -s ${KEEPALIVED_PREFIX}/sbin/keepalived /usr/sbin/keepalived && chmod -R a+x /usr/sbin

# keepalived -f /etc/keepalived/keepalived.conf



# @warn cant adjust the time in docker container!
#   it's allowed in A-class IP address, e.g. 10.0.x.x
#RUN yum install -y ntp
#RUN yes | cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
#RUN ntpdate time.nist.gov


#RUN sysctl -p


# The signals of the running status of each containers
#   0   Running
#   1   not run yet
# @Warning
#   How to get the signals in different servers
#ENV SCRIPT_DIRRYPOINT_SIGNALS_DIR /var/lib/docker_entrypoint_signals
#RUN mkdir -p "${SCRIPT_DIRRYPOINT_SIGNALS_DIR}"

RUN echo -e "\nPATH=$PATH:/usr/bin:/usr/local/bin:/usr/local/sbin\nexport PATH\nexport HISTSIZE=0\n" >> /etc/profile
RUN source /etc/profile



################ Entrypoint And Clean ########################
ENV ENT_CONST_SCRIPT    ${SCRIPT_DIR}/entrypointConst.sh
ENV ENT_BASE_SCRIPT     ${SCRIPT_DIR}/entrypointBase.sh
ENV ENT_SCRIPT          ${SCRIPT_DIR}/entrypoint.sh
COPY ./script/entrypointConst.sh    ${ENT_CONST_SCRIPT}
COPY ./script/entrypointBase.sh     ${ENT_BASE_SCRIPT}
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/


RUN echo -e "\n SHARED_GROUP='${SHARED_GROUP}' \n SHARED_USER='${SHARED_USER}' \n SHARED_GROUP='${SHARED_GROUP}' \n NO_SHARED_USER='${NO_SHARED_USER}' \n SYS_CONF_DIR='${SYS_CONF_DIR}' \n SPOOL_DIR='${SPOOL_DIR}' \n S_P_L_DIR='${S_P_L_DIR}' \n PREFIX_BASE='${PREFIX_BASE}' \n CRONTAB_FILE='${CRONTAB_FILE}' \n SRC_DIR='${SRC_DIR}' \n BIN_DIR='${BIN_DIR}' \n SBIN_DIR='${SBIN_DIR}' \n LIB_DIR='${LIB_DIR}' \n LIB64_DIR='${LIB64_DIR}' \n LIB_EXEC_DIR='${LIB_EXEC_DIR}' \n INCLUDE_DIR='${INCLUDE_DIR}' \n CACHE_DIR='${CACHE_DIR}' \n PREFIX_BASE='${PREFIX_BASE}' \n SCRIPT_DIR='${SCRIPT_DIR}' \n AUTORUN_SCRIPT_DIR='${AUTORUN_SCRIPT_DIR}' \n SYNC_DIR='${SYNC_DIR}' \n SSL_DIR='${SSL_DIR}' \n ENT_CONST_SCRIPT='${ENT_CONST_SCRIPT}' \n ENT_BASE_SCRIPT='${ENT_BASE_SCRIPT}' \n ENT_SCRIPT='${ENT_SCRIPT}' \n SHAREDSTATE_DIR='${SHAREDSTATE_DIR}'" >> ${ENT_CONST_SCRIPT}               \
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


# ONBUILD


#sh$ docker build -t aario/centos:web ./centos

# --privileged to enable `sysctl -p`
#sh$ docker run -it --privileged aario/centos:web /bin/bash

#sh$ docker commit -m '20151015' <CONTAINER_ID> aario/centos:web