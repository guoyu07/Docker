FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>


ENV GIT_GROUP git
RUN groupadd -r ${GIT_GROUP}

RUN yum -y install openssh-server passwd 
# gitweb

#RUN sed -i -e 's/.*LogLevel.*/LogLevel VERBOSE/' -e 's/#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i -e 's/.*LogLevel.*/LogLevel VERBOSE/' -e 's/#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
#RUN sed -i -e 's/#UsePAM.*/UsePAM no/' /etc/ssh/sshd_config
RUN sed -i -e 's/#UsePAM.*/UsePAM yes/' /etc/ssh/sshd_config
#Set a long random password to unlock the git user account
#RUN usermod -p `dd if=/dev/urandom bs=1 count=30 | uuencode -m - | head -2 | tail -1` git
#RUN usermod -p Aario root

################ Entrypoint ########################
COPY ./script/entrypoint.sh         ${ENT_SCRIPT}
COPY ./script/autorun/*             ${AUTORUN_SCRIPT_DIR}/

RUN echo -e "\n GIT_GROUP='${GIT_GROUP}' \n " >> ${ENT_CONST_SCRIPT}         \
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

RUN ln -sf /dev/stdout /var/log/stdout.log    		\
    && ln -sf /dev/stderr /var/log/stderr.log
	
# /usr/sbin/sshd -D
ENTRYPOINT ["/aa_script/entrypoint.sh", "/usr/sbin/sshd", "-D"]

# SSH_HOST_KEY_COMPLEXITY  low default high
# GIT_HOME_USERS   $username:$password

#sh$ docker run -d --restart=always --name aa_git --privileged=true -p 9418:9418 -p 10022:22 -v /SyncGits/Depository/git:/var/lib/git -v /SyncGits/Depository/data/log/git:/var/log -e GIT_REPO_ROOT=/var/lib/git -e ENTRYPOINT_LOG=/var/log/git/docker_entrypoint.log -e UPDATE_REPO=0 -e TIMEZONE=Asia/Shanghai -e SSH_HOST_KEY_COMPLEXITY=default -e GIT_HOME_USERS=git:git,aario:Aario -it aario/git


# git remote add origin ssh://${USER}@${IP}:${PORT}${PATH}
# git clone ssh://${USER}@${IP}:${port}:${PATH}