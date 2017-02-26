FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

ENV GITLAB_VER 1

RUN yum -y install openssl-server passwd


#ENTRYPOINT ["/aa_script/entrypoint.sh"]
    
#sh$ docker run -d --restart=always --name aa_gitlab --privileged=true -p 39418:9418 -p 39480:80 -p 39422:22 --link aa_redis:aa_redis --link aa_mysql57:aa_mysql57 --link aa_mysqlslave57:aa_mysqlslave57 -v /SyncGits/Depository/gitlab:/var/lib/gitlab -v /SyncGits/Depository/data/log/gitlab:/var/log -e ENTRYPOINT_LOG=/var/log/gitlab/docker_entrypoint.log -e UPDATE_REPO=0 -e TIMEZONE=Asia/Shanghai -it aario/gitlab


