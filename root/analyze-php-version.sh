#!/bin/sh

# 分析PHP版本兼容性的脚本
# 用法: analyze-php-version.sh <目标PHP版本> <代码目录>

TARGET_VERSION=$1
CODE_DIR=$2

if [ -z "$TARGET_VERSION" ] || [ -z "$CODE_DIR" ]; then
    echo "用法: analyze-php-version.sh <目标PHP版本> <代码目录>"
    echo "例如: analyze-php-version.sh 8.1 /app/src"
    exit 1
fi

echo "===== 开始分析代码与PHP $TARGET_VERSION 的兼容性 ====="

# 使用PHP_CodeSniffer检查兼容性
echo ">> 运行PHP兼容性检查..."
phpcs --standard=PHPCompatibility --runtime-set testVersion $TARGET_VERSION $CODE_DIR

# 使用Rector分析可能需要升级的代码
echo ">> 运行Rector分析..."
VERSION_NO_DOT=$(echo "$TARGET_VERSION" | tr -d '.')
rector process "$CODE_DIR" --dry-run --set "php${VERSION_NO_DOT}"

# 使用PHPStan进行静态分析
echo ">> 运行PHPStan静态分析..."
phpstan analyse $CODE_DIR --level=3 # 降低级别，提高兼容性

echo "===== 分析完成 ====="