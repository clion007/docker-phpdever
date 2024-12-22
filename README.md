# Phpdever Docker Image
[![Build](https://github.com/clion007/docker-phpdever/actions/workflows/build.yaml/badge.svg?branch=main)](https://github.com/clion007/docker-phpdever/actions/workflows/build.yaml)
[![License](https://img.shields.io/github/license/clion007/docker-phpdever)](https://github.com/clion007/docker-phpdever/blob/main/LICENSE)
![GitHub top language](https://img.shields.io/github/languages/top/clion007/docker-phpdever)
[![Packages retention policy](https://github.com/clion007/docker-phpdever/actions/workflows/packages-retention-policy.yaml/badge.svg?branch=main)](https://github.com/clion007/docker-phpdever/actions/workflows/packages-retention-policy.yaml)

This repository is a docker image based on official php, composer and alpine docker images to help you to build and test your PHP projects with different PHP version.<br>
This docker image contains a necessary tools you need to analyze and test your PHP project
* xdebug
* phpunit
* rector
* phpstan
* psalm
* phpcs
* php-cs-fixer
* phpmd
* phpcpd (available from php 7.3 version)

Below is the list of docker images available by PHP versions:

| PHP version | Docker image tags                                                                        |
|-------------|------------------------------------------------------------------------------------------|
| PHP 8.4     | `registry.cn-chengdu.aliyuncs.com/clion/Phpdever:latest`<br>`registry.cn-chengdu.aliyuncs.com/clion/Phpdever:v2-php8.4-alpine` |
| PHP 8.3     | `registry.cn-chengdu.aliyuncs.com/clion/Phpdever:v2-php8.3-alpine`                                          |
| PHP 8.2     | `registry.cn-chengdu.aliyuncs.com/clion/Phpdever:v2-php8.2-alpine`                                          |
| PHP 8.1     | `registry.cn-chengdu.aliyuncs.com/clion/Phpdever:v2-php8.1-alpine`                                          |
| PHP 8.0     | `registry.cn-chengdu.aliyuncs.com/clion/Phpdever:v2-php8.0-alpine`                                          |
| PHP 7.4     | `registry.cn-chengdu.aliyuncs.com/clion/Phpdever:v2-php7.4-alpine`                                          |
| PHP 7.3     | `registry.cn-chengdu.aliyuncs.com/clion/Phpdever:v2-php7.3-alpine`                                          |
| PHP 7.2     | `registry.cn-chengdu.aliyuncs.com/clion/Phpdever:v2-php7.2-alpine`                                          |

## Application Setup

* Webui can be found at http://\<your-ip\>:8096
* More information can be found on the official documentation.

## Hardware Acceleration

Many desktop applications need access to a GPU to function properly and even some Desktop Environments have compositor effects that will not function without a GPU. However this is not a hard requirement and all base images will function without a video device mounted into the container.

For Intel/ATI/AMD to leverage hardware acceleration you will need to mount /dev/dri video device inside of the container.
```
--device=/dev/dri:/dev/dri
```
I will automatically ensure the jellyfin user inside of the container has the proper permissions to access this device.

## Usage

To help you get started creating a container from this image you can either use docker-compose or the docker cli.

### docker-compose (recommended, [click here for more info](https://https://docs.docker.com/compose/))

```
services:
  jellyfin:
    container_name: Jellyfin
    image: registry.cn-chengdu.aliyuncs.com/clion/jellyfin:latest
    environment:
      - UMASK=022
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - JELLYFIN_PublishedServerUrl=192.168.0.5 #optional
    ports:
      - 8096:8096
      - 8920:8920 #optional
      - 7359:7359/udp #optional
      - 1900:1900/udp #optional
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /path/to/jellyfin/library:/config
      - /path/to/media:/media/nas
    restart: unless-stopped
```

### Docker cli
```
docker run -d \
  --name=Jellyfin \
  -e UMASK=022 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -e JELLYFIN_PublishedServerUrl=192.168.0.5 `#optional` \
  -p 8096:8096 \
  -p 8920:8920 `#optional` \
  -p 7359:7359/udp `#optional` \
  -p 1900:1900/udp `#optional` \
  -v /path/to/config:/config \
  -v /path/to/media:/media/nas \
  -v /etc/localtime:/etc/localtime:ro \
  --restart unless-stopped \
  registry.cn-chengdu.aliyuncs.com/clion/jellyfin:latest
```
## Parameters

Containers are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate <external>:<internal> respectively. For example, -p 8080:80 would expose port 80 from inside the container to be accessible from the host's IP on port 8080 outside the container.

* ```-p 8096``` Http webUI.
* ```-p 8920``` Optional - Https webUI (you need to set up your own certificate).
* ```-p 7359/udp``` Optional - Allows clients to discover Jellyfin on the local network.
* ```-p 1900/udp``` Optional - Service discovery used by DNLA and clients.
* ```-e PUID=1000``` for UserID - see below for explanation.
* ```-e PUID=1000``` for GroupID - see below for explanation.
* ```-e TZ=Asia/Shanghai``` specify a timezone to use in your local area.
* ```-e JELLYFIN_PublishedServerUrl=192.168.0.5``` Set the autodiscovery response domain or IP address.
* ```-v /config``` Jellyfin data storage location. This can grow very large, 50gb+ is likely for a large collection.
* ```-v /media/nas``` Media goes here. Add as many as needed e.g. /media/nas/movies, /media/nas/tv, etc.

## Umask for running applications

For all of my images I provide the ability to override the default umask settings for services started within the containers using the optional -e UMASK=022 setting. Keep in mind umask is not chmod it subtracts from permissions based on it's value it does not add.

## User / Group Identifiers

When using volumes (-v flags), permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user PUID and group PGID.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.
