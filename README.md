# Phpdever Docker Image

[![Docker Publish](https://github.com/clion007/docker-phpdever/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/clion007/docker-phpdever/actions/workflows/docker-publish.yml)
[![License](https://img.shields.io/github/license/clion007/docker-phpdever)](https://github.com/clion007/docker-phpdever/blob/main/LICENSE)
![GitHub top language](https://img.shields.io/github/languages/top/clion007/docker-phpdever)

A lightweight PHP development environment and code analysis toolset based on Alpine Linux, designed for PHP project version upgrades and compatibility analysis.

## Key Features

- Lightweight image based on Alpine Linux
- Support for multiple PHP versions (7.2 - 8.4)
- Integrated PHP code analysis tools
- PHP-FPM support
- Configurable user permissions and timezone

## Built-in Tools

### Debugging & Testing
- xdebug: PHP debugging and code coverage analysis
- phpunit: Unit testing framework
- paratest: PHPUnit parallel testing tool

### Code Analysis
- rector: Automated code upgrade tool
- phpstan: PHP static analysis tool
- psalm: PHP static type checker
- phan: PHP static analyzer
- exakat: PHP static analysis tool

### Code Quality
- phpcs: PHP code style checker
- php-cs-fixer: Code formatting tool
- phpmd: Code quality detector
- phpcpd: Copy/Paste detector (PHP 7.3+)
- phpmetrics: Code quality metrics
- pdepend: PHP dependency analysis

### Additional Tools
- composer: PHP package manager
- infection: PHP mutation testing
- phpinsights: PHP quality checks
- var-dumper: Variable debugging tool

## Available Versions

| PHP Version | Docker Image Tags |
|-------------|------------------|
| PHP 8.4 | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:latest`<br>`registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.4.2` |
| PHP 8.3 | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.3.15` |
| PHP 8.2 | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.2.27` |
| PHP 8.1 | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.1.31` |
| PHP 8.0 | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php8.0.30` |
| PHP 7.4 | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php7.4.33` |
| PHP 7.3 | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php7.3.33` |
| PHP 7.2 | `registry.cn-chengdu.aliyuncs.com/clion/phpdever:php7.2.34` |

## Usage

### Using docker-compose (Recommended)

```yaml
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

### Using Docker CLI

```bash
docker run -d \
  --name=phpdever \
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

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| PUID | 1000 | Process User ID |
| PGID | 1000 | Process Group ID |
| UMASK | 022 | File permission mask |
| TZ | Asia/Shanghai | Timezone setting |

## PHP Extensions

### Core Extensions
- bcmath
- calendar
- ctype
- curl
- dom
- exif
- ftp
- gd
- iconv
- intl
- mbstring
- opcache
- openssl
- phar
- soap
- sockets
- xml
- zip

### Database Support
- mysqli
- mysqlnd
- pdo_mysql
- pdo_sqlite
- pgsql
- pdo_pgsql
- sqlite3

### PECL Extensions
- xdebug
- redis
- memcached

## Analysis Examples

### Version Compatibility Check
```bash
analyze-php-version.sh 7.4 /path/to/code
```

### Automatic Code Upgrade
```bash
auto-upgrade.sh 8.1 /path/to/code
```

### Using Individual Tools

Check PHP version compatibility:
```bash
phpcs --standard=PHPCompatibility --runtime-set testVersion 7.4 your_file.php
```

Upgrade code with Rector:
```bash
rector process your_file.php --set php74
```

Run static analysis:
```bash
phpstan analyse your_file.php --level=5
```

## References

* [PHPUnit Supported Versions](https://phpunit.de/supported-versions.html)
* [Xdebug Compatibility](https://xdebug.org/docs/compat)
* [PHPStan](https://phpstan.org/)
* [Psalm](https://psalm.dev/docs/)
* [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer/wiki)
* [PHP-CS-Fixer](https://cs.symfony.com/)
* [PHPMD](https://phpmd.org/)
* [PHPCPD](https://github.com/sebastianbergmann/phpcpd)
