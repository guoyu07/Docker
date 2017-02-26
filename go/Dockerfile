FROM aario/centos:web
MAINTAINER Aario <AarioAi@gmail.com>

ENV GO_VER go1.7.3
ENV GO_SRC_NAME ${GO_VER}.linux-amd64
ENV GO_SRC_URL https://storage.googleapis.com/golang/${GO_SRC_NAME}.tar.gz
ENV GO_PREFIX ${PREFIX_BASE}/go


WORKDIR ${SRC_DIR}
ADD ./src/* ${SRC_DIR}/

RUN if [ ! -d "${SRC_DIR}/go" ]; then                           \
        curl -sSL ${GO_SRC_URL} -o ${SRC_DIR}/go.tar.gz;        \
        tar -C ${PREFIX_BASE} -zxf ${SRC_DIR}/go.tar.gz;        \
        rm -f ${SRC_DIR}/go.tar.gz;                             \
    fi

ENV GO_LOG_DIR /var/log/go
ENV GO_PATH /var/lib/go
RUN if [ ! -d ${GO_LOG_DIR} ]; then             \
        mkdir -p ${GO_LOG_DIR};                 \
    fi
    
    
RUN mv ${SRC_DIR}/go ${PREFIX_BASE}                                 \
    && ln -s ${GO_PREFIX}/bin/go ${BIN_DIR}/go                      \
    && ln -s ${GO_PREFIX}/bin/gofmt ${BIN_DIR}/gofmt                \
    && ln -s ${GO_PREFIX}/bin/godoc ${BIN_DIR}/godoc                \
    && echo -e "\nexport GOPATH=${GO_PATH}\n" >> /etc/profile       \
    && source /etc/profile




# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout ${GO_LOG_DIR}/stdout.log        \
    && ln -sf /dev/stderr ${GO_LOG_DIR}/stderr.log



#ENTRYPOINT ["/aa_script/entrypoint.sh"]
    
#sh$ docker run -d --restart=always --name aa_go --privileged=true -p 30080:80 -p 38080:8080 -v /SyncGits/Depository/go:/var/lib/go -v /SyncGits/Depository/data/log/go:/var/log -e ENTRYPOINT_LOG=/var/log/go/docker_entrypoint.log -e UPDATE_REPO=0 -e TIMEZONE=Asia/Shanghai -it aario/go


