FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

ENV FREESWITCH_VER freeswitch-1.6.8

WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/
# https://freeswitch.org/stash/projects/FS/repos/freeswitch/browse
RUN if [ ! -d "${SRC_DIR}/${FREESWITCH_VER}" ]; then                             \
        git clone -b v1.6 --single-branch https://freeswitch.org/stash/scm/fs/freeswitch.git "${FREESWITCH_VER}";   \
    fi
# May this tar.gz file is cloned without changing directory name
RUN if [ ! -d "${SRC_DIR}/${FREESWITCH_VER}" -a -d "${SRC_DIR}/freeswitch" ]; then    \
        mv "${SRC_DIR}/freeswitch" "${SRC_DIR}/${FREESWITCH_VER}";                    \
    fi

RUN yum install -y http://files.freeswitch.org/freeswitch-release-1-6.noarch.rpm epel-release
RUN yum install -y git gcc-c++ autoconf automake libtool wget python ncurses-devel zlib-devel libjpeg-devel openssl-devel e2fsprogs-devel sqlite-devel libcurl-devel pcre-devel speex-devel ldns-devel libedit-devel libxml2-devel libyuv-devel opus-devel libvpx-devel libvpx2* libdb4* libidn-devel unbound-devel libuuid-devel lua-devel libsndfile-devel yasm-devel

WORKDIR ${SRC_DIR}/${FREESWITCH_VER}
# cd   high quality sound
# hd   includes sounds
# uhd  includes hd-sounds, sounds
RUN ./bootstrap.sh -j && ./configure 
RUN make && make install && make hd-sounds-install && make hd-moh-install && make samples

################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/


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

# docker run -d --restart=always --name aa_freeswitch --privileged=true  -v /SyncGits/Depository/data/log/freeswitch:/var/log -e ENTRYPOINT_LOG=/var/log/freeswitch/docker_entrypoint.log -e UPDATE_REPO=0 -e GEN_SSL_CRT=crt2048,crt4096,dhparam2048,dhparam4096 -e TIMEZONE=Asia/Shanghai -it aario/freeswitch
