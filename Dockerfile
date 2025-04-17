# syntax=docker/dockerfile:1

# Docker build arguments - 无默认值，完全依赖工作流传值
ARG PHP_VERSION
ARG COMPOSER_VERSION
ARG PHP_INSTALL_DIR=/usr/local/php
ARG PHP_LIB_DIR=/usr/local/php/lib
ARG PHP_TMP_LIB_DIR=/phpdever/lib
ARG COMPOSER_INSTALL_DIR=/usr/local/bin

# 构建基础PHP环境
FROM alpine:latest AS builder

ARG PHP_VERSION
ARG COMPOSER_VERSION
ARG PHP_INSTALL_DIR
ARG PHP_LIB_DIR
ARG PHP_TMP_LIB_DIR
ARG COMPOSER_INSTALL_DIR

# 安装构建依赖
RUN set -ex; \
    apk add --no-cache --virtual .build-deps \
        alpine-sdk \
        autoconf \
        curl \
        curl-dev \
        libxml2-dev \
        openssl-dev \
        openssl \
        libpng-dev \
        jpeg-dev \
        freetype-dev \
        oniguruma-dev \
        libzip-dev \
        icu-dev \
        sqlite-dev \
        libsodium-dev \
        linux-headers \
        bison \
        re2c \
        git \
        unzip \
        tar \
        ca-certificates \
        bzip2-dev \
        libtool \
        readline-dev \
        postgresql-dev \
        libmemcached-dev \
        xsl-dev \
    ; \
    # 下载并编译PHP
    mkdir -p /usr/src; \
    cd /usr/src; \
    curl -fsSL "https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz" -o php.tar.gz; \
    tar -xzf php.tar.gz; \
    cd php-${PHP_VERSION}; \
    # 配置PHP
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
    # 编译和安装PHP
    make -j$(nproc); \
    make install; \
    # 创建配置目录
    mkdir -p ${PHP_INSTALL_DIR}/etc/conf.d; \
    # 复制配置文件
    cp php.ini-development ${PHP_INSTALL_DIR}/etc/php.ini; \
    cp ${PHP_INSTALL_DIR}/etc/php-fpm.conf.default ${PHP_INSTALL_DIR}/etc/php-fpm.conf; \
    cp ${PHP_INSTALL_DIR}/etc/php-fpm.d/www.conf.default ${PHP_INSTALL_DIR}/etc/php-fpm.d/www.conf; \
    # 安装PECL扩展
    cd /usr/src; \
    ${PHP_INSTALL_DIR}/bin/pecl install xdebug; \
    ${PHP_INSTALL_DIR}/bin/pecl install redis; \
    ${PHP_INSTALL_DIR}/bin/pecl install memcached; \
    # 启用扩展
    echo "extension=redis.so" > ${PHP_INSTALL_DIR}/etc/conf.d/redis.ini; \
    echo "extension=memcached.so" > ${PHP_INSTALL_DIR}/etc/conf.d/memcached.ini; \
    echo "zend_extension=xdebug.so" > ${PHP_INSTALL_DIR}/etc/conf.d/xdebug.ini; \
    # 安装Composer
    curl -sS https://getcomposer.org/installer | ${PHP_INSTALL_DIR}/bin/php -- --install-dir=${COMPOSER_INSTALL_DIR} --filename=composer --version=${COMPOSER_VERSION}; \
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
    # 配置PHPCompatibility
    mkdir -p /root/.composer/vendor/squizlabs/php_codesniffer/src/Standards/; \
    ln -s /root/.composer/vendor/phpcompatibility/php-compatibility /root/.composer/vendor/squizlabs/php_codesniffer/src/Standards/PHPCompatibility; \
    # 复制动态库到指定目录
    mkdir -p ${PHP_TMP_LIB_DIR}; \
    # 复制PHP相关的动态库
    for lib in $(find ${PHP_LIB_DIR} -name "*.so" -o -name "*.so.*"); do \
        cp -L ${lib} ${PHP_TMP_LIB_DIR}/; \
        # 获取依赖并复制
        deps=$(ldd ${lib} 2>/dev/null | awk '{print $3}' | grep -v "not found" | grep -v "^$"); \
        for dep in ${deps}; do \
            if [ -f "${dep}" ] && [ ! -f "${PHP_TMP_LIB_DIR}/$(basename ${dep})" ]; then \
                cp -L ${dep} ${PHP_TMP_LIB_DIR}/; \
            fi \
        done \
    done; \
    # 清理
    cd /; \
    rm -rf /usr/src/*; \
    apk del --no-network .build-deps; \
    rm -rf \
        /var/cache/apk/* \
        /var/tmp/* \
        /tmp/* \
    ;

# 构建最终镜像
FROM alpine:latest

ARG PHP_VERSION
ARG COMPOSER_VERSION
ARG PHP_INSTALL_DIR
ARG PHP_LIB_DIR
ARG PHP_TMP_LIB_DIR
ARG COMPOSER_INSTALL_DIR

LABEL maintainer="Clion Nihe Email: clion007@126.com"
LABEL description="PHP代码分析工具集，用于项目版本升级和兼容性分析"

# 设置环境变量
ENV PATH="${PHP_INSTALL_DIR}/bin:${PHP_INSTALL_DIR}/sbin:/root/.composer/vendor/bin:${PATH}"
ENV PHP_VERSION=${PHP_VERSION}
ENV COMPOSER_VERSION=${COMPOSER_VERSION}
ENV XDEBUG_MODE=off
ENV PHP_LIB_DIR=${PHP_LIB_DIR}

# 安装运行时依赖
RUN set -ex; \
    apk add --no-cache \
        libxml2 \
        openssl \
        libpng \
        jpeg \
        freetype \
        oniguruma \
        libzip \
        icu-libs \
        sqlite-libs \
        libsodium \
        bzip2-libs \
        readline \
        postgresql-libs \
        libmemcached-libs \
        libxslt \
        git \
        shadow \
        su-exec \
        jq \
        grep \
        diffutils \
    ; \
    # 创建用户和组
    groupadd -g 1000 phpdever; \
    useradd -u 1000 -s /bin/sh -g 1000 phpdever; \
    # 创建配置目录
    mkdir -p /config; \
    chown phpdever:phpdever /config; \
    # 清理
    rm -rf \
        /var/cache/apk/* \
        /var/tmp/* \
        /tmp/* \
    ;

# 从构建阶段复制PHP和工具
COPY --from=builder ${PHP_INSTALL_DIR} ${PHP_INSTALL_DIR}
COPY --from=builder ${COMPOSER_INSTALL_DIR}/composer ${COMPOSER_INSTALL_DIR}/composer
COPY --from=builder /root/.composer/vendor /root/.composer/vendor
COPY --from=builder ${PHP_TMP_LIB_DIR} /usr/lib/

# 添加分析脚本
COPY --chmod=755 root/ /

# 工作目录
WORKDIR /app

# 暴露PHP-FPM端口
EXPOSE 9000

# 入口点
ENTRYPOINT ["/init"]
CMD ["php-fpm", "-F"]
