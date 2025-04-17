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
| PHP 8.4     | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:latest`<br>`registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.4.2` |
| PHP 8.3     | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.3.15`                                          |
| PHP 8.2     | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.2.27`                                          |
| PHP 8.1     | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.1.31`                                          |
| PHP 8.0     | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.0.30`                                          |
| PHP 7.4     | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php7.4.33`                                          |
| PHP 7.3     | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php7.3.33`                                          |
| PHP 7.2     | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php7.2.34`                                          |

## Usage

To help you get started creating a container from this image you can either use docker-compose or the docker cli.

### docker-compose (recommended, [click here for more info](https://https://docs.docker.com/compose/))

```
services:
  phpdever:
    container_name: phpdever
    image: registry.cn-chengdu.aliyuncs.com/clion/phpdever:latest
    environment:
      - UMASK=022
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    ports:
      - 9090:9000
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /path/to/config:/config
    restart: unless-stopped
```

### Docker cli
```
docker run -d \
  --name=Phpdever \
  -e UMASK=022 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Shanghai \
  -p 9090:9000 \
  -v /path/to/config:/config \
  -v /etc/localtime:/etc/localtime:ro \
  --restart unless-stopped \
  registry.cn-chengdu.aliyuncs.com/clion/phpdever:latest
```
## Parameters

Containers are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate <external>:<internal> respectively. For example, -p 9090:9000 would expose port 9000 from inside the container to be accessible from the host's IP on port 9090 outside the container.

* -v /config	Contains your www content and all relevant configuration files.
* -e PUID=1000	for UserID - see below for explanation
* -e PGID=1000	for GroupID - see below for explanation
* -e TZ="Asia/Shanghai" specify a timezone to use.

## PHP Modules installed
*    php-common
*    php-ctype
*    php-curl
*    php-fpm
*    php-iconv
*    php-json
*    php-mbstring
*    php-openssl
*    php-phar
*    php-session
*    php-simplexml
*    php-xml
*    php-xmlwriter
*    php-zip
*    php-bcmath
*    php-dom
*    php-ftp
*    php-gd
*    php-intl
*    php-mysqli
*    php-mysqlnd
*    php-opcache
*    php-pdo_mysql
*    php-pecl-memcached
*    php-pecl-redis
*    php-soap
*    php-sockets
*    php-sodium
*    php-sqlite3
*    php-xmlreader
*    php-xsl

### Use components
Inside the container, you can run any tool you need from any working directory.<br>
Global vendor binaries are added to the PATH environment.

#### Composer
```shell
composer --help
```
#### PHP Unit
```shell
simple-phpunit --help
```
#### Rector
```shell
rector --help
```
#### PHPStan
```shell
phpstan --help
```
#### Psalm
```shell
psalm --help
```
#### PHP Code sniffer
```shell
phpcs --help
```
#### PHP Coding Standards Fixer
```shell
php-cs-fixer --help
```
#### PHP Mess Detector
```shell
phpmd --help
```
#### PHP Copy Past Detector
```shell
phpcpd --help
```

## Umask for running applications

For all of my images I provide the ability to override the default umask settings for services started within the containers using the optional -e UMASK=022 setting. Keep in mind umask is not chmod it subtracts from permissions based on it's value it does not add.

## User / Group Identifiers

When using volumes (-v flags), permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user PUID and group PGID.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

## References
* [PHP Unit supported versions](https://phpunit.de/supported-versions.html)
* [Xdebug compatibility](https://xdebug.org/docs/compat)
* [PHP Unit](https://symfony.com/doc/current/components/phpunit_bridge.html)
* [Rector](https://packagist.org/packages/rector/rector)
* [PHPStan](https://phpstan.org/)
* [Psalm](https://psalm.dev/docs/)
* [PHP CS](https://github.com/squizlabs/PHP_CodeSniffer/wiki)
* [PHP Coding Standards Fixer](https://cs.symfony.com/)
* [PHP Mess Detector](https://phpmd.org/)
* [PHP Copy Past detector](https://github.com/sebastianbergmann/phpcpd)