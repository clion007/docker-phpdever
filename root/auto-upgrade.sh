#!/bin/bash

# 自动升级PHP代码的脚本
# 用法: auto-upgrade.sh <目标PHP版本> <代码目录>

TARGET_VERSION=$1
CODE_DIR=$2

if [ -z "$TARGET_VERSION" ] || [ -z "$CODE_DIR" ]; then
    echo "用法: auto-upgrade.sh <目标PHP版本> <代码目录>"
    echo "例如: auto-upgrade.sh 8.1 /app/src"
    exit 1
fi

echo "===== 开始自动升级代码到PHP $TARGET_VERSION ====="

# 使用Rector自动升级代码
echo ">> 运行Rector自动升级..."
rector process $CODE_DIR --set php${TARGET_VERSION/./}

# 使用PHP-CS-Fixer修复代码风格
echo ">> 修复代码风格..."
php-cs-fixer fix $CODE_DIR

echo "===== 升级完成 ====="
echo "请检查修改并测试代码功能"