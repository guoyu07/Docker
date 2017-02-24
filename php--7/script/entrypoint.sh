#!/bin/bash
# MAINTAINER Aario <AarioAi@gmail.com>
set -e

. /aa_script/entrypointBase.sh

TIMEZONE=${TIMEZONE:-""}
HOST=${HOST:-"aa_php"}
ENTRYPOINT_LOG=${ENTRYPOINT_LOG:-'&2'}
LOG_TAG=${LOG_TAG:-"php_entrypoint[$$]"}

UPDATE_REPO=${UPDATE_REPO:-0}
GEN_SSL_CRT=${GEN_SSL_CRT:-""}

PHP_USER=${PHP_USER:-'php'}
PHP_GROUP=${PHP_GROUP:-'php'}
WWW_HTDOCS=${WWW_HTDOCS:-'/var/lib/htdocs'}
PHP_LOG_DIR=${PHP_LOG_DIR:-'/var/log/php'}
PHP_PREFIX=${PHP_PREFIX:-'/var/local/php'}




if [ -z "${PHP_EXT_SRC}" ]; then
    for $src in $(ls /usr/src); do
        if [ ${src:0:3} == 'php' -a -d "$src/ext"]; then
            PHP_EXT_SRC=$src
        fi
    done
fi
PHP_EXTS_WITH_SSL=${PHP_EXTS_WITH_SSL:-0}
PHP_EXTS_WITH_HTTP2=${PHP_EXTS_WITH_HTTP2:-0}
PHP_EXT_DEPENDENCIES=${PHP_EXT_DEPENDENCIES:-"${PHP_EXT_SRC}/_dependencies"}
PHP_CLEAN_COMPILED_EXT_SRC=${PHP_CLEAN_COMPILED_EXT_SRC:-1}
# PHP_CONF_SCAN_DIR=${PHP_CONF_SCAN_DIR:-''}

# ENTRYPOINT_LOG
#   $file         create log file
#   console(default)      echo
SetEntrypointLogPath "${ENTRYPOINT_LOG}"
aaLog() {
    AaLog --aalogheader_host "${HOST}" --aalogfile "${ENTRYPOINT_LOG}" --aalogtag "${LOG_TAG}" "$@"
}


aaLog "Adjusting date... : $(date)"
AaAdjustTime "${TIMEZONE}"
aaLog "Adjusted date : $(date)"

aaLog "Doing yum update ..."
YumUpdate "${UPDATE_REPO}"

aaLog "Generating SSL Certificate..."
GenSslCrt "${GEN_SSL_CRT}"


php_ext_dir=$(php -i | grep "^extension_dir =>" | awk -F ' => ' '{print $2}')
php_conf_dir=$(echo $(php --ini | grep "Scan") | awk -F ': ' '{print $2}')

if [ ! -z "$php_conf_dir" ]; then
	default_php_conf=$php_conf_dir"/php.ini"
fi

# xdebug-2.4.0,xhprof-php7/extension

installZephir() {
    dependency="$1"
    # Install zephir
    aaLog ":  Installing $dependency"
    #remove all sudo in zephir shell scripts
    find "${PHP_EXT_SRC}/_dependencies/$dependency" -type f -print0 | xargs -0 sed -i 's/sudo //g'
    sed -i "s/\/usr\/local\/bin\/zephir/\/usr\/sbin\/zephir/g" "${PHP_EXT_SRC}/_dependencies/$dependency/install"
    # go inside to install zephir is required
    cd "${PHP_EXT_SRC}/_dependencies/$dependency"
    ./install -c
    chmod a+x /usr/sbin/zephir
    aaLog ":  Installed zephir"
}
enableExts() {
    if [ ! -z "${PHP_ENABLE_EXTS}" ]; then
        aaLog "Enabling Extensions: ${PHP_ENABLE_EXTS}"
        for enable_ext in $(echo "${PHP_ENABLE_EXTS}" | tr ',' "\n"); do
            ext=$(echo "$enable_ext" | awk -F '-' '{print $1}')
			pecl_channel=''
            aaLog "Handling Extension: $ext"
            case "$ext" in
                phpredis)
                    aaLog " chang extension name phpredis to redis.so"
                    ext="redis"
                ;;
            esac
            
            if [ ! -f "$php_ext_dir/"$ext".so" ]; then
                aaLog " $ext doesn't exist. compile it..."
                cd "${PHP_EXT_SRC}"
                is_standard_php_ext=1
                config_opt=""
                
                case "$ext" in
					'cassandra')
						yum install -y gmp gmp-devel libuv libuv-devel
						if [ -z "${CASSANDRA_CPP_DRIVER}" ]; then
							# https://github.com/datastax/cpp-driver/archive/2.5.0.tar.gz
							for cpp_driver in $(ls "${PHP_EXT_SRC}" | grep ^cpp-driver); do
								if [ -f $cpp_driver'/cassconfig.hpp.in' ]; then
									CASSANDRA_CPP_DRIVER=$cpp_driver
									break
								fi
							done
						fi
						mkdir -p "${PHP_EXT_SRC}/${CASSANDRA_CPP_DRIVER}/build"
						cd "${PHP_EXT_SRC}/${CASSANDRA_CPP_DRIVER}/build"
						cmake --INSTALL-DIR /usr/local/cassandra-cpp-driver --SHARED ..
						make && make install
						
						[ ! -f '/usr/lib64/libcassandra.so' ] && ln -s /usr/local/lib64/libcassandra.so /usr/lib64/libcassandra.so
						[ ! -f '/usr/lib64/libcassandra.so.2' ] && ln -s /usr/local/lib64/libcassandra.so.2 /usr/lib64/libcassandra.so.2
						[ ! -f '/usr/lib64/libcassandra.so.2.5.0' ] && ln -s /usr/local/lib64/libcassandra.so.2.5.0 /usr/lib64/libcassandra.so.2.5.0
					;;
					'rdkafka')
						if [ -z "${LIBRDKAFKA_VER}" ]; then
							for librdkafka in $(ls "${PHP_EXT_SRC}" | grep ^librdkafka); do
								if [ -f ${PHP_EXT_SRC}'/'$librdkafka'/Makefile' ]; then
									LIBRDKAFKA_VER=$librdkafka
									break
								fi
							done
						fi
						aaLog "LibRdKafka: ${LIBRDKAFKA_VER}"
						cd ${PHP_EXT_SRC}'/'${LIBRDKAFKA_VER}
						./configure
						make && make install
					;;
					'zookeeper')
						# requires libzookeeper
						# libzookeeper is in  zookeeper/src/c/
						if [ -z "${LIBZOOKEEPER_VER}" ]; then
							for libzookeeper in $(ls "${PHP_EXT_SRC}" | grep ^zookeeper); do
								if [ -f ${PHP_EXT_SRC}'/'$libzookeeper'/src/c/configure' ]; then
									LIBZOOKEEPER_VER=$libzookeeper
									break
								fi
							done
						fi
						cd ${PHP_EXT_SRC}'/'${LIBZOOKEEPER_VER}'/src/c'
						./configure --prefix=/usr/local/zookeeper-c-cli
						make && make install
						config_opt+=' --with-libzookeeper-dir=/usr/local/zookeeper-c-cli'
					;;
					'composer')
						cd '/tmp'
						curl -sSL https://getcomposer.org/installer -o composer-installer.php
						php composer-installer.php --install-dir=/usr/bin --filename=composer
						rm -f composer-installer.php
					continue
					;;
                    'curl')
                        yum install -y curl-devel libcurl libcurl-devel
                    ;;
                    'gd')
                        yum install -y gd freetype freetype-devel libjpeg libjpeg-devel libpng libpng-devel
						config_opt+=" --enable-gd-native-ttf --with-jpeg-dir --with-freetype-dir"
                    ;;
					'pcre')
						yum install -y pcre pcre-devel
					;;
					'xml')
						yum install -y libxml2 libxml2-devel
					;;
                    'openssl')
                        yum install -y openssl openssl-devel
                    ;;
                    # pdo_pgsql/pgsql needs a pre-installed postgresql 
                    'pgsql' | 'pdo_pgsql') 
                        yum install -y postgresql-devel
                    ;;
                    'imagick')
                        yum install -y ImageMagick ImageMagick-devel
                    ;;
                    'lua')
                        mkdir /usr/include/lua/
                        ln -s /usr/include/lua.h /usr/include/lua/lua.h
                    ;;
                    'zlib')
                        yum install -y zlib zlib-devel
                    ;;
					'xdebug')
						if [ ! -d "${PHP_EXT_SRC}/$enable_ext" ]; then
							cd ${PHP_EXT_SRC}
							if  curl -sSL "https://xdebug.org/files/"$enable_ext".tgz" -o ${PHP_EXT_SRC}"/"$enable_ext".tgz"; then
								tar -zxvf ${PHP_EXT_SRC}"/"$enable_ext".tgz"
								rm -f ${PHP_EXT_SRC}"/"$enable_ext".tgz"
							fi
						fi
					;;
                    'redis')
                        if [ ! -d "${PHP_EXT_SRC}/$enable_ext" ]; then
                            cd ${PHP_EXT_SRC}
                            if  curl -sSL "http://pecl.php.net/get/$enable_ext.tgz" -o "${PHP_EXT_SRC}/$enable_ext.tgz"; then
                                tar -zxvf "${PHP_EXT_SRC}/$enable_ext.tgz"
                                rm -f "${PHP_EXT_SRC}/$enable_ext.tgz"
                            fi
                        fi
                    ;;
                    'phalcon')
                        # https://gist.github.com/michael34435/c682271492a03f0af686
                        
                        is_standard_php_ext=0
                        
                        aaLog ": Installing phalcon dependencies..."
                        
                        if yum install -y re2c; then
                            aaLog "re2c yum depository exists"
                        else
                            declare epel_rpm
                            # ls "*.rpm"    --> "*.rpm" file only;    
                            # ls *.rpm      --> regexp, all .rpm files
                            cd "${PHP_EXT_SRC}/_dependencies"
                            for rpm_file in $(ls *.rpm); do
                                case "${rpm_file:0:4}" in
                                    epel)
                                        aaLog "local $rpm_file exits"
                                        epel_rpm="${PHP_EXT_SRC}/_dependencies/$rpm_file"
                                    ;;
                                esac    
                                
                            done
                            
                            epel_rpm=${epel_rpm:-'http://download.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm'}
                            aaLog ": rpm -Uvh $epel_rpm"
                            rpm -Uvh "$epel_rpm"
                            yum update -y
                            yum install -y re2c
                            aaLog ": rpm success"
                           
                        fi
                        
                        yum install -y make gcc file git
                        
                        declare zephir_ver
                        declare cphalcon_ver
                        
                        cd "${PHP_EXT_SRC}"
                        for dependency in $(ls "_dependencies"); do
                            if [ -d "${PHP_EXT_SRC}/_dependencies/$dependency" ]; then
                                case "${dependency:0:4}" in
                                    #re2c)
                                    #    # Install re2c
                                    #    aaLog ":  Installing $dependency"
                                    #    
                                    #    cd "${PHP_EXT_SRC}/_dependencies/$dependency"
                                    #    
                                    #    if [ -d "${PHP_EXT_SRC}/_dependencies/$dependency/re2c/" ]; then
                                    #        cd "${PHP_EXT_SRC}/_dependencies/$dependency/re2c"
                                    #    fi
                                    #    
                                    #    mkdir -p "/usr/local/re2c"
                                    #    
                                    #    ./configure --prefix="/usr/local/re2c"
                                    #    make
                                    #    make install
                                    #    if [ -f "/usr/local/re2c/bin/re2c" ]; then
                                    #        aaLog "[Error] re2c installed failed"
                                    #        exit 1
                                    #    fi
                                    #    ln "/usr/local/re2c/bin/re2c" "/usr/sbin/re2c"
                                    #    chmod a+x "/usr/sbin/re2c"
                                    #    aaLog ":  Installed $dependency"
                                    #;;
                                    zeph)
                                        # if [ -z $zephir_ver ] --> git clone
                                        zephir_ver="$dependency"
                                        installZephir "$zephir_ver"
                                    ;;
                                    cpha)
                                        cphalcon_ver="$dependency"
                                    ;;
                                esac
                            fi
                        done
                        ## Install re2c ############################################################
                        #if [ ! -d "${PHP_EXT_SRC}/_dependencies/re2c" ]; then
                        
                        #    aaLog " re2c source doesn't exist; git clone it from remote"
                            
                        #    cd "${PHP_EXT_SRC}/_dependencies"
                        #    git clone https://github.com/skvadrik/re2c.git re2c
                            
                            
                        #fi
                        
                        #if [ -d "${PHP_EXT_SRC}/_dependencies/re2c/re2c" ]; then
                        #    cd "${PHP_EXT_SRC}/_dependencies"
                            
                        #    aaLog "  Compiling re2c/autogen | autogen.sh"
                        #    if [ -f "${PHP_EXT_SRC}/_dependencies/re2c/re2c/autogen.sh" ]; then
                        #        ./re2c/re2c/autogen.sh
                        #    elif [ -f"${PHP_EXT_SRC}/_dependencies/re2c/re2c/autogen" ]; then
                        #        ./re2c/re2c/autogen
                        #    fi
                        #    aaLog "  Compiled re2c/autogen | autogen.sh"
                        #    rm -rf "/tmp/re2c"
                        #    aaLog "  Moving re2c/re2c to re2c"
                        #    mv ./re2c/re2c /tmp/re2c
                        #    mv /tmp/re2c/re2c "${PHP_EXT_SRC}/_dependencies/re2c"
                        #fi
                        
                        
                        
                  
                        if [ -z "$zephir_ver" ]; then
                            aaLog ":  zephir source doesn't exist; git clone it from remote"
                            rm -rf zephir
                            git clone https://github.com/phalcon/zephir.git "zephir"
                            installZephir "zephir"
                        fi
                       
                        
                        
                        aaLog "Installing $cphalcon_ver"
                        if [ -z "$cphalcon_ver" ]; then
                            aaLog ":  cphalcon source doesn't exist; git clone it from remote"
                            cphalcon_ver="cphalcon-2.1.x"
                            cd "${PHP_EXT_SRC}/_dependencies"
                            git clone https://github.com/phalcon/cphalcon "$cphalcon_ver"
                        fi
                        
                        if [ -d "${PHP_EXT_SRC}/_dependencies/$cphalcon_ver/.git" ]; then
                            aaLog ":    cphalcon git checkout 2.1.x"
                            cd "${PHP_EXT_SRC}/_dependencies/$cphalcon_ver"
                            git checkout "2.1.x"
                        fi
                        
                        cd "${PHP_EXT_SRC}/_dependencies/$cphalcon_ver/ext"
                        phpize
                        cd "${PHP_EXT_SRC}/_dependencies/$cphalcon_ver"
 
                        # memory_allow in php.ini
                       
                        if [ ! -z "$default_php_conf" -a -f "$default_php_conf" ]; then
                            sed -i "s/^\s*;.*//g" "$default_php_conf"
                            sed -Ei "s/^\s*memory_limit/;&/g" "$default_php_conf"
                            echo -e "\nmemory_limit=384M\n" >> "$default_php_conf"
                        fi
                         
                        aaLog ":  zephir build --backend=ZendEngine3"
                        zephir fullclean
                        zephir build --backend=ZendEngine3
                        echo "extension=phalcon.so" > "$default_php_conf"
                        
                        aaLog ":  Installed $cphalcon_ver"
                        
                        # set back memory_limit
                        if [ ! -z "$default_php_conf" -a -f "$default_php_conf" ]; then
                            sed -i "s/^\s*memory_limit=384M//g" "$default_php_conf"
                            sed -Ei "s/^\s*;\s*//g" "$default_php_conf"
                        fi
                        
                    ;;
                    'pthreads')
                        if [ ! -d "${PHP_EXT_SRC}/$enable_ext"]; then
                            # pthreads-3.1.6  --->  3.1.6
                            pthreads_ver=$(echo $enable_ext | awk -F '-' '{print $2}')
                            if curl -sSL "https://github.com/krakjoe/pthreads/archive/v"$pthreads_ver".tar.gz" -o "${PHP_EXT_SRC}/"$enable_ext".tar.gz"; then
                                cd ${PHP_EXT_SRC}
                                tar -zxvf "${PHP_EXT_SRC}/$enable_ext.tar.gz"
                                rm -f "${PHP_EXT_SRC}/$enable_ext.tar.gz"
                            fi
                        fi
                    ;;
                    'codecept' | 'codeception')
                        is_standard_php_ext=0
                        [ ! -f "${PHP_EXT_SRC}/_dependencies/codecept.phar" ] && curl -sSL http://codeception.com/codecept.phar -o "${PHP_EXT_SRC}/_dependencies/codecept.phar"
                        yes | cp "${PHP_EXT_SRC}/_dependencies/codecept.phar" "/usr/sbin/codecept"
                        chmod a+x /usr/sbin/codecept
                    ;;
                    'mosquitto')
                        yum install -y mosquitto-devel
                        cd "${PHP_EXT_SRC}/"
                        if [ ! -f "${PHP_EXT_SRC}/mosquitto/config.m4" ]; then
                            aaLog "git clone -b php7 --single-branch https://github.com/mgdm/Mosquitto-PHP.git mosquitto"
                            git clone -b master --single-branch "https://github.com/mgdm/Mosquitto-PHP.git" "mosquitto"
                        fi
                    ;;
					'protobuf')
                        if [ ! -d "${PHP_EXT_SRC}/$enable_ext" ]; then
                            aaLog ""
							protobuf_file_prefix='protobuf-php-'
							protobuf_ver=${enable_ext:${#protobuf_file_prefix}}
							curl -sSL "https://github.com/google/protobuf/releases/download/v"$protobuf_ver"/"$enable_ext".tar.gz" -o "${PHP_EXT_SRC}/"$enable_ext".tar.gz"
							tar -zxvf "${PHP_EXT_SRC}/"$enable_ext".tar.gz"
							rm -f "${PHP_EXT_SRC}/"$enable_ext".tar.gz"
                        fi
						
						cd "${PHP_EXT_SRC}/$enable_ext"
						./configure >>  "${ENTRYPOINT_LOG}" 2>&1
						make && make install
						enable_ext=$enable_ext'/php/ext/google/protobuf'
					;;
                    'swoole')
                        ulimit -n 100000
                        [ ${PHP_EXTS_WITH_SSL} -eq 1 ] && config_opt+=" --enable-openssl"
                        [ ${PHP_EXTS_WITH_HTTP2} -eq 1 ] && config_opt+=" --enable-http2"
                        if [ ! -d "${PHP_EXT_SRC}/$enable_ext"]; then
                            # swoole-src-1.8.11-stable  --> 1.8.11-stable
                            swoole_file_prefix="swoole-src-"
                            swoole_file=${enable_ext:${#swoole_file_prefix}}
							aaLog "${PHP_EXT_SRC}/$enable_ext  dosen't exist!"
                            if curl -sSL "https://github.com/swoole/swoole-src/archive/"$swoole_file".tar.gz" -o "${PHP_EXT_SRC}/"$enable_ext".tar.gz"; then
                                cd ${PHP_EXT_SRC}
                                tar -zxvf "${PHP_EXT_SRC}/$enable_ext.tar.gz"
                                rm -f "${PHP_EXT_SRC}/$enable_ext.tar.gz"
                            fi
                        fi
                    ;;
                esac
                
                aaLog "Checking whether $enable_ext is a standard php extension: $is_standard_php_ext"
                
                if [ $is_standard_php_ext -eq 1 ]; then
                    if [ ! -d "${PHP_EXT_SRC}/$enable_ext" -a "$enable_ext" == "$ext" ]; then
						ext_list=$(ls ${PHP_EXT_SRC} | grep ^"$enable_ext"-)
						if [ ! -z "$ext_list" ]; then
							for e in $(ls ${PHP_EXT_SRC} | grep ^"$enable_ext"-); do
								if [ -f "${PHP_EXT_SRC}/$e/config.m4" ]; then
									enable_ext="$e"
									break
								fi
							done
						fi
					fi
					
					if [ ! -d "${PHP_EXT_SRC}/$enable_ext" ]; then
						if [ ! -z "$pecl_channel" ]; then
							$ext="$pecl_channel"
						fi
						${PHP_PREFIX}/bin/pecl install $ext
                    else
                        cd "${PHP_EXT_SRC}/$enable_ext"
                        if [ ! -e "Makefile" ]; then
                            aaLog "phpize"
                            phpize >> "${ENTRYPOINT_LOG}" 2>&1
                            aaLog "./configure $enable_ext $config_opt"
                            ./configure $config_opt >> "${ENTRYPOINT_LOG}" 2>&1
                        fi
                    
						aaLog "make"
                        make >> "${ENTRYPOINT_LOG}" 2>&1
						aaLog "make install"
                        make install >> "${ENTRYPOINT_LOG}" 2>&1
                        find modules -maxdepth 1 -name '*.so' -exec basename '{}' ';' | xargs --no-run-if-empty --verbose docker-php-ext-enable >> "${ENTRYPOINT_LOG}" 2>&1
                        make clean >> "${ENTRYPOINT_LOG}" 2>&1
                    fi
                fi
              
                if [ -f "$php_ext_dir/"$ext".so" ]; then
                    aaLog "$ext Installed Successed"
                else
                    aaLog --aalogpri_severity ERROR "$ext Installed Failured!!!"
                fi
            fi
        done
		
		# PHP_EXTRA_CONFS='yaconf.directory=/tmp/;boc=/love'
		# Warning: PHP_EXTRA_CONFS="'yaconf.directory=/tmp/;boc=/love'"
		if [ ! -z "${PHP_EXTRA_CONFS}" ]; then
			# Remove the extra single-quotations
			extra_confs=$(echo ${PHP_EXTRA_CONFS} | sed "s/^'//")
			if [ "$extra_confs" != ${PHP_EXTRA_CONFS} ]; then
				extra_confs=$(echo $extra_confs | sed "s/'$//")
			fi
			 for extra_conf in $(echo "$extra_confs" | tr ';' "\n"); do
				if [ ! -z "$default_php_conf" -a -f "$default_php_conf" ]; then
					ini="$default_php_conf"
				else
					ini="${PHP_CONF_SCAN_DIR}/aa_$ext.ini"
				fi
				echo -e "\n$extra_conf" >> "$ini"
			done
		fi
		
        aaLog "Enabled Extensions: ${PHP_ENABLE_EXTS}"
        if [ ${PHP_CLEAN_COMPILED_EXT_SRC} -eq 1 ]; then
            aaLog "Cleaning compiled PHP extension sources..."
            rm -rf ${PHP_EXT_SRC}
        fi
		
    fi
}

disableExts() {
    if [ ! -z "${PHP_DISABLE_EXTS}" ]; then
        aaLog "Disabling Extensions: ${PHP_DISABLE_EXTS}"
        disable_exts=$(echo "${PHP_DISABLE_EXTS}" | tr ',' "\n")
        for disable_ext in  $disable_exts; do
            ext=$(echo "$disable_ext" | awk -F '-' '{print $1}')
            case "$ext" in
                phpredis)
                    ext="redis"
            esac
            [ -f "$php_ext_dir/"$ext".so" ] && rm -f "$php_ext_dir/"$ext".so"
        done
        aaLog "Disabled Extensions: ${PHP_DISABLE_EXTS}"
    fi
}

grantPrivileges() {
    [ ! -d "${WWW_HTDOCS}" ] && mkdir -p "${WWW_HTDOCS}"
	[ ! -d "${PHP_LOG_DIR}" ] && mkdir -p "${WWW_HTDOCS}"
	chown -R ${PHP_USER}:${PHP_GROUP} ${WWW_HTDOCS} ${PHP_LOG_DIR}
	chmod -R u+rwx ${WWW_HTDOCS} ${PHP_LOG_DIR}
}

lock_file="${S_P_L_DIR}/php-entrypoint-"$( echo -n "${LOG_TAG}" | md5sum | cut -d ' ' -f1)
if [ ! -f "$lock_file" ]; then
	enableExts
	disableExts
	grantPrivileges
	touch "$lock_file"
fi

for i in $(ls "${AUTORUN_SCRIPT_DIR}"); do
    . "${AUTORUN_SCRIPT_DIR}/"$i &
done

RunningSignal ${RUNING_ID:-''}

if [ $# -gt 0 ]; then
	echo "Running $@"
	if [ "${1: -7}" == 'php-fpm' -o "${1: -3}" == 'php' ]; then
		su - ${PHP_USER} << EOF
		$@
EOF
	else
	    exec "$@"
	fi
fi