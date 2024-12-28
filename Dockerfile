# syntax=docker/dockerfile:1

# Docker build arguments
ARG PHP_NAME
ARG PHP_VERSION
ARG COMPOSER_VERSION

# Build PHP
FROM alpine AS builder

ARG JELLYFIN_VERSION
ARG DOTNET_CLI_TELEMETRY_OPTOUT=1

WORKDIR /tmp/jellyfin

ADD https://github.com/jellyfin/jellyfin/archive/refs/tags/v$JELLYFIN_VERSION.tar.gz ../jellyfin.tar.gz

RUN set -ex; \
    tar xf ../jellyfin.tar.gz --strip-components=1; \
    dotnet publish \
        Jellyfin.Server \
        --self-contained \
        --configuration Release \
        --runtime linux-musl-x64 \
        --output=/server \
        "-p:DebugSymbols=false" \
        "-p:DebugType=none" \
    ; \
    rm -rf \
        /var/cache/apk/* \
        /var/tmp/* \
        ../* \
    ;

# build jellyfin-web client
FROM node:lts-alpine AS web

ARG JELLYFIN_VERSION

ENV JELLYFIN_VERSION=${JELLYFIN_VERSION}

WORKDIR /tmp/jellyfin-web

ADD https://github.com/jellyfin/jellyfin-web/archive/refs/tags/v$JELLYFIN_VERSION.tar.gz ../jellyfin-web.tar.gz

RUN set -ex; \
    apk add --no-cache --virtual .build-deps \
      alpine-sdk \
      autoconf \
      libpng-dev \
      gifsicle \
      automake \
      libtool \
      musl-dev \
      nasm \
      python3 \
    ; \
    tar xf ../jellyfin-web.tar.gz --strip-components=1; \
    npm ci --no-audit --unsafe-perm; \
    npm run build:production; \
    apk del --no-network .build-deps; \
    mv dist /web; \
    rm -rf \
        /var/cache/apk/* \
        /var/tmp/* \
        ../* \
    ;

# Build the final combined image
FROM clion007/alpine

LABEL mantainer="Clion Nihe Email: clion007@126.com"

ARG BRANCH="edge"
ARG JELLYFIN_PATH=/usr/lib/jellyfin/
ARG JELLYFIN_WEB_PATH=/usr/share/jellyfin-web/

# Default environment variables for the Jellyfin invocation
ENV JELLYFIN_LOG_DIR=/config/log \
    JELLYFIN_DATA_DIR=/config/data \
    JELLYFIN_CACHE_DIR=/config/cache \
    JELLYFIN_CONFIG_DIR=/config/config \
    JELLYFIN_WEB_DIR=/usr/share/jellyfin-web
ENV XDG_CACHE_HOME=${JELLYFIN_CACHE_DIR}

# https://github.com/dlemstra/Magick.NET/issues/707#issuecomment-785351620
ENV MALLOC_TRIM_THRESHOLD_=131072

# add jellyfin files
COPY --from=server /server $JELLYFIN_PATH
COPY --from=web /web $JELLYFIN_WEB_PATH
COPY --from=ffmpeg /ffmpeg/bin /usr/bin/
COPY --from=ffmpeg /ffmpeg/library /

# add local files
COPY --chmod=755 root/ /

# install packages
RUN set -ex; \
  apk add --no-cache \
    --repository=http://dl-cdn.alpinelinux.org/alpine/$BRANCH/main \
    --repository=http://dl-cdn.alpinelinux.org/alpine/$BRANCH/community \
    su-exec \
    icu-libs \
    libva-intel-driver \
    intel-media-driver \
    font-droid-nonlatin \
  ; \
  find /usr/share/fonts/droid-nonlatin/ -type f -not -name 'DroidSansFallbackFull.ttf' -delete; \
  apk add --no-cache --virtual .user-deps \
    shadow \
  ; \
  \
  # set jellyfin process user and group
  groupadd -g 101 jellyfin; \
  useradd -u 100 -s /bin/nologin -M -g 101 jellyfin; \
  ln -s /usr/lib/jellyfin/jellyfin /usr/bin/jellyfin; \
  chown jellyfin:jellyfin /usr/bin/jellyfin; \
  \
  # make dir for config and data
  mkdir -p /config; \
  chown jellyfin:jellyfin /config; \
  \
  apk del --no-network .user-deps; \
  rm -rf \
      /var/cache/apk/* \
      /var/tmp/* \
      /tmp/* \
  ;
  
# ports
EXPOSE 8096 8920 7359/udp 1900/udp

# entrypoint set in clion007/alpine base image
CMD ["--ffmpeg=/usr/bin/ffmpeg"]
