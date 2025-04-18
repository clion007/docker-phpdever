# syntax=docker/dockerfile:1

# Docker build arguments - 无默认值，完全依赖工作流传值
ARG PHP_VERSION
ARG COMPOSER_VERSION
ARG PHP_INSTALL_DIR=/usr/local/php
ARG PHP_LIB_DIR=/usr/local/php/lib
ARG PHP_TMP_LIB_DIR=/phpdever/lib
ARG COMPOSER_INSTALL_DIR=/usr/local/bin
ARG BUILDKIT_INLINE_CACHE=1

# 构建基础PHP环境
FROM alpine:latest AS builder

ARG PHP_VERSION
ARG COMPOSER_VERSION
ARG PHP_INSTALL_DIR
ARG PHP_LIB_DIR
ARG PHP_TMP_LIB_DIR
ARG COMPOSER_INSTALL_DIR

WORKDIR /tmp

# 添加需要文件
COPY deplib/cplibfiles.sh /usr/local/bin/
ADD https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz php.tar.gz
ADD https://getcomposer.org/installer composer-setup.php
# ADD http://pear.php.net/go-pear.phar go-pear.php

# 安装构建依赖并编译PHP
RUN --mount=type=cache,target=/var/cache/apk \
    set -ex; \
    \
    # 安装依赖
    apk add --no-cache --virtual .build-deps \
        git \
        alpine-sdk \
        autoconf \
        argon2-dev \
        bison \
        bzip2-dev \
        curl-dev \
        enchant2-dev \
        freetype-dev \
        gdbm-dev \
        gettext-dev \
        gmp-dev \
        icu-dev \
        libavif-dev \
        libedit-dev \
        libical-dev \
        libjpeg-turbo-dev \
        libpng-dev \
        libpq-dev \
        lmdb-dev \
        readline-dev \
        oniguruma-dev \
        libsodium-dev \
        libwebp-dev \
        libxml2-dev \
        libxpm-dev \
        libxslt-dev \
        libzip-dev \
        net-snmp-dev \
        openldap-dev \
        openssl-dev \
        pcre2-dev \
        postgresql-dev \
        sqlite-dev \
        tidyhtml-dev \
        unixodbc-dev \
        zlib-dev \
    ; \
    \
    # 编译安装PHP
    tar -xzf php.tar.gz; \
    cd php-${PHP_VERSION}; \
    \
    ./configure \
        --prefix=${PHP_INSTALL_DIR} \
        --with-config-file-path=${PHP_INSTALL_DIR}/etc \
        --with-config-file-scan-dir=${PHP_INSTALL_DIR}/etc/conf.d \
        --enable-fpm \
        --with-fpm-user=phpdever \
        --with-fpm-group=phpdever \
        --enable-bcmath \
        --enable-calendar \
        --enable-ctype \
        --enable-dom \
        --enable-exif \
        --enable-ftp \
        --enable-gd \
        --enable-intl \
        --enable-mbstring \
        --enable-mysqlnd \
        --enable-opcache \
        --enable-soap \
        --enable-sockets \
        --enable-xml \
        --enable-xmlreader \
        --enable-xmlwriter \
        --enable-cgi \
        --enable-phpdbg \
        --enable-debug \
        --enable-short-tags \
        --enable-pcntl \
        --enable-posix \
        --enable-ast \
        --with-pcre-jit \
        --with-bz2 \
        --with-curl \
        --with-freetype \
        --with-iconv \
        --with-jpeg \
        --with-mysqli=mysqlnd \
        --with-openssl \
        --with-pdo-mysql=mysqlnd \
        --with-pdo-sqlite \
        --with-phar \
        --with-readline \
        --with-sodium \
        --with-sqlite3 \
        --with-xsl \
        --with-zip \
        --with-zlib \
        --with-pgsql \
        --with-pdo-pgsql \
    ; \
    \
    make -j$(nproc); \
    make install; \
    \
    # 编译安装pecl扩展
    cd /tmp; \
    # 安装 xdebug
    git clone --depth=1 https://github.com/xdebug/xdebug.git; \
    cd xdebug; \
    ${PHP_INSTALL_DIR}/bin/phpize; \
    ./configure --with-php-config=${PHP_INSTALL_DIR}/bin/php-config; \
    make -j$(nproc); \
    make install; \
    \
    # 安装 redis
    cd /tmp; \
    git clone --depth=1 https://github.com/phpredis/phpredis.git; \
    cd phpredis; \
    ${PHP_INSTALL_DIR}/bin/phpize; \
    ./configure --with-php-config=${PHP_INSTALL_DIR}/bin/php-config; \
    make -j$(nproc); \
    make install; \
    \
    # 安装 memcached
    cd /tmp; \
    apk add --no-cache libmemcached-dev; \
    git clone --depth=1 https://github.com/php-memcached-dev/php-memcached.git; \
    cd php-memcached; \
    ${PHP_INSTALL_DIR}/bin/phpize; \
    ./configure --with-php-config=${PHP_INSTALL_DIR}/bin/php-config; \
    make -j$(nproc); \
    make install;

# 安装Composer和工具
RUN --mount=type=cache,target=/root/.composer/cache \
    # 安装 composer
    ${PHP_INSTALL_DIR}/bin/php /tmp/composer-setup.php \
        --install-dir=${COMPOSER_INSTALL_DIR} \
        --filename=composer \
        --version=${COMPOSER_VERSION}; \
    # 安装全局工具
    ${COMPOSER_INSTALL_DIR}/composer global require \
        phpunit/phpunit \
        rector/rector \
        phpstan/phpstan \
        vimeo/psalm \
        squizlabs/php_codesniffer \
        friendsofphp/php-cs-fixer \
        phpmd/phpmd \
        sebastian/phpcpd \
        phpcompatibility/php-compatibility \
        phan/phan \
        infection/infection \
        nunomaduro/phpinsights \
        symfony/var-dumper \
        brianium/paratest \
        phpmetrics/phpmetrics \
        pdepend/pdepend \
        phploc/phploc \
        exakat/exakat \
    ; \
    # 复制系统依赖库
    mkdir -p ${PHP_TMP_LIB_DIR}; \
    chmod +x /usr/local/bin/cplibfiles.sh; \
    /usr/local/bin/cplibfiles.sh ${PHP_TMP_LIB_DIR}; \
    \
    # 清理文件
    apk del --no-network .build-deps; \
    rm -rf \
        /var/cache/apk/* \
        /var/tmp/* \
        /tmp/* \
    ;

# 构建最终镜像
FROM clion007/alpine:latest

ARG PHP_VERSION
ARG COMPOSER_VERSION
ARG PHP_INSTALL_DIR
ARG PHP_LIB_DIR
ARG PHP_TMP_LIB_DIR
ARG COMPOSER_INSTALL_DIR

LABEL maintainer="Clion Nihe Email: clion007@126.com"
LABEL description="PHP代码分析工具集，用于项目版本升级和兼容性分析"

# 设置环境变量
ENV PATH="${PHP_INSTALL_DIR}/bin:${PHP_INSTALL_DIR}/sbin:/.composer/vendor/bin:${PATH}"
ENV PHP_VERSION=${PHP_VERSION}
ENV COMPOSER_VERSION=${COMPOSER_VERSION}
ENV PHP_LIB_DIR=${PHP_LIB_DIR}
ENV PHPDEVER_TOOLS_PATH="/phpdever"

# 从构建阶段复制文件
COPY --from=builder ${PHP_INSTALL_DIR} ${PHP_INSTALL_DIR}
COPY --from=builder ${COMPOSER_INSTALL_DIR}/composer ${COMPOSER_INSTALL_DIR}/composer
COPY --from=builder /root/.composer/vendor /.composer/vendor
COPY --from=builder ${PHP_TMP_LIB_DIR} /usr/lib/

# 安装运行时依赖并配置环境
RUN set -ex; \
    # 安装虚拟包用于用户操作
    apk add --no-cache --virtual .user-deps shadow; \
    # 安装运行时依赖
    apk add --no-cache \
        su-exec \
    ; \
    # 创建用户和组
    groupadd -g 1000 phpdever; \
    useradd -u 1000 -s /bin/sh -g 1000 phpdever; \
    # 创建必要目录
    mkdir -p /config ${PHP_INSTALL_DIR}/etc/conf.d /.composer/vendor/squizlabs/php_codesniffer/src/Standards/; \
    chown phpdever:phpdever /config; \
    # 配置 PHP
    cp ${PHP_INSTALL_DIR}/etc/php.ini.default ${PHP_INSTALL_DIR}/etc/php.ini; \
    cp ${PHP_INSTALL_DIR}/etc/php-fpm.conf.default ${PHP_INSTALL_DIR}/etc/php-fpm.conf; \
    cp ${PHP_INSTALL_DIR}/etc/php-fpm.d/www.conf.default ${PHP_INSTALL_DIR}/etc/php-fpm.d/www.conf; \
    # 确保PHP命令可用
    ln -sf ${PHP_INSTALL_DIR}/bin/php /usr/bin/php; \
    ln -sf ${PHP_INSTALL_DIR}/sbin/php-fpm /usr/sbin/php-fpm; \
    # PHP-FPM配置
    sed -i \
        -e "s#^error_log =.*#error_log = /config/log/php/error.log#g" \
        -e "s#^pid =.*#pid = /run/php-fpm.pid#g" \
        ${PHP_INSTALL_DIR}/etc/php-fpm.conf; \
    # PHP-FPM www池配置
    sed -i \
        -e "s#^user =.*#user = phpdever#g" \
        -e "s#^group =.*#group = phpdever#g" \
        -e "s#^listen =.*#listen = 0.0.0.0:9000#g" \
        -e "s#^listen.owner =.*#listen.owner = phpdever#g" \
        -e "s#^listen.group =.*#listen.group = phpdever#g" \
        -e "s#^;catch_workers_output =.*#catch_workers_output = yes#g" \
        -e "s#^;decorate_workers_output =.*#decorate_workers_output = no#g" \
        ${PHP_INSTALL_DIR}/etc/php-fpm.d/www.conf; \
    # 创建日志目录
    mkdir -p /config/log/php; \
    chown -R phpdever:phpdever /config/log; \
    # 启用扩展
    echo "extension=redis.so" > ${PHP_INSTALL_DIR}/etc/conf.d/redis.ini; \
    echo "extension=memcached.so" > ${PHP_INSTALL_DIR}/etc/conf.d/memcached.ini; \
    echo "zend_extension=xdebug.so" > ${PHP_INSTALL_DIR}/etc/conf.d/xdebug.ini; \
    # 配置 PHPCompatibility
    ln -s /.composer/vendor/phpcompatibility/php-compatibility /.composer/vendor/squizlabs/php_codesniffer/src/Standards/PHPCompatibility; \
    # PHP 配置优化
    sed -i \
        -e 's/expose_php = On/expose_php = Off/' \
        -e 's/memory_limit = 128M/memory_limit = 256M/' \
        -e 's/upload_max_filesize = 2M/upload_max_filesize = 50M/' \
        -e 's/post_max_size = 8M/post_max_size = 50M/' \
        -e 's/max_execution_time = 30/max_execution_time = 600/' \
        -e 's/max_input_time = 60/max_input_time = 600/' \
        -e 's/short_open_tag = Off/short_open_tag = On/' \
        ${PHP_INSTALL_DIR}/etc/php.ini; \
    # 优化PHP-FPM配置
    sed -i \
        -e 's/;emergency_restart_threshold = 0/emergency_restart_threshold = 10/' \
        -e 's/;emergency_restart_interval = 0/emergency_restart_interval = 1m/' \
        -e 's/;process_control_timeout = 0/process_control_timeout = 10s/' \
        ${PHP_INSTALL_DIR}/etc/php-fpm.conf; \
    # 优化www池配置
    sed -i \
        -e 's/pm = dynamic/pm = static/' \
        -e 's/pm.max_children = 5/pm.max_children = 20/' \
        -e 's/pm.start_servers = 2/pm.start_servers = 5/' \
        -e 's/pm.min_spare_servers = 1/pm.min_spare_servers = 5/' \
        -e 's/pm.max_spare_servers = 3/pm.max_spare_servers = 20/' \
        -e 's/;pm.max_requests = 500/pm.max_requests = 1000/' \
        ${PHP_INSTALL_DIR}/etc/php-fpm.d/www.conf; \
    # 删除用户操作相关的虚拟包
    apk del --no-network .user-deps; \
    # 清理
    rm -rf \
        /var/cache/apk/* \
        /var/tmp/* \
        /tmp/* \
    ;

# 添加分析脚本
COPY --chmod=755 root/ /

# 工作目录
WORKDIR /app

# 暴露PHP-FPM端口
EXPOSE 9000

# 入口点
ENTRYPOINT ["/init"]
CMD ["php-fpm", "-F"]
