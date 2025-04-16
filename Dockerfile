# syntax=docker/dockerfile:1

# Docker build arguments - 无默认值，完全依赖工作流传值
ARG PHP_VERSION
ARG COMPOSER_VERSION

# 构建基础PHP环境
FROM alpine:latest AS builder

ARG PHP_VERSION
ARG COMPOSER_VERSION

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
    ; \
    # 下载并编译PHP
    mkdir -p /usr/src; \
    cd /usr/src; \
    curl -fsSL "https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz" -o php.tar.gz; \
    tar -xzf php.tar.gz; \
    cd php-${PHP_VERSION}; \
    # 配置PHP
    ./configure \
        --prefix=/usr/local/php \
        --with-config-file-path=/usr/local/php/etc \
        --with-config-file-scan-dir=/usr/local/php/etc/conf.d \
        --enable-fpm \
        --with-fpm-user=phpdever \
        --with-fpm-group=phpdever \
        --enable-opcache \
        --enable-mbstring \
        --enable-mysqlnd \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --with-pdo-sqlite \
        --with-sqlite3 \
        --with-curl \
        --with-openssl \
        --with-zip \
        --with-zlib \
        --enable-gd \
        --with-jpeg \
        --with-freetype \
        --enable-intl \
        --with-sodium \
        --enable-bcmath \
        --enable-exif \
        --enable-sockets \
        --with-bz2 \
        --enable-calendar \
        --enable-soap \
        --with-readline \
        --with-pgsql \
        --with-pdo-pgsql \
    ; \
    # 编译和安装PHP
    make -j$(nproc); \
    make install; \
    # 创建配置目录
    mkdir -p /usr/local/php/etc/conf.d; \
    # 复制配置文件
    cp php.ini-development /usr/local/php/etc/php.ini; \
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf; \
    cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf; \
    # 安装PECL扩展
    cd /usr/src; \
    /usr/local/php/bin/pecl install xdebug; \
    # 安装Composer
    curl -sS https://getcomposer.org/installer | /usr/local/php/bin/php -- --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION}; \
    # 安装全局工具
    /usr/local/bin/composer global require \
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

LABEL maintainer="Clion Nihe Email: clion007@126.com"
LABEL description="PHP代码分析工具集，用于项目版本升级和兼容性分析"

ARG PHP_VERSION
ARG COMPOSER_VERSION

# 设置环境变量
ENV PATH="/usr/local/php/bin:/usr/local/php/sbin:/root/.composer/vendor/bin:${PATH}"
ENV PHP_VERSION=${PHP_VERSION}
ENV COMPOSER_VERSION=${COMPOSER_VERSION}
ENV XDEBUG_MODE=off

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
        git \
        bash \
        shadow \
        su-exec \
        jq \
        grep \
        diffutils \
    ; \
    # 创建用户和组
    groupadd -g 1000 phpdever; \
    useradd -u 1000 -s /bin/bash -g 1000 phpdever; \
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
COPY --from=builder /usr/local/php /usr/local/php
COPY --from=builder /usr/local/bin/composer /usr/local/bin/composer
COPY --from=builder /root/.composer/vendor /root/.composer/vendor

# 添加分析脚本
COPY --chmod=755 root/ /

# 工作目录
WORKDIR /app

# 暴露PHP-FPM端口
EXPOSE 9000

# 入口点
ENTRYPOINT ["/init"]
CMD ["php-fpm", "-F"]
