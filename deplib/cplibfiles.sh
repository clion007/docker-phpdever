#!/bin/sh
set -e

TARGET_LIB_DIR="${1:-/phpdever/lib}"
mkdir -p "${TARGET_LIB_DIR}"

# 复制 PHP 依赖的系统库
echo "Copying PHP binary dependencies..."
for bin in $(find ${PHP_INSTALL_DIR}/bin ${PHP_INSTALL_DIR}/sbin -type f -executable); do
    ldd "${bin}" 2>/dev/null | while read -r line; do
        if echo "${line}" | grep -q "=> /lib/" || echo "${line}" | grep -q "=> /usr/lib/"; then
            src=$(echo "${line}" | awk '{print $3}')
            if [ -f "${src}" ] && [ ! -f "${TARGET_LIB_DIR}/$(basename "${src}")" ]; then
                cp -L "${src}" "${TARGET_LIB_DIR}/"
            fi
        fi
    done
done

# 复制 PHP 扩展依赖的系统库
echo "Copying PHP extension dependencies..."
for ext in $(find /usr/local/php/lib/php/extensions -type f -name "*.so"); do
    ldd "${ext}" 2>/dev/null | while read -r line; do
        if echo "${line}" | grep -q "=> /lib/" || echo "${line}" | grep -q "=> /usr/lib/"; then
            src=$(echo "${line}" | awk '{print $3}')
            if [ -f "${src}" ] && [ ! -f "${TARGET_LIB_DIR}/$(basename "${src}")" ]; then
                cp -L "${src}" "${TARGET_LIB_DIR}/"
            fi
        fi
    done
done

# 复制 Composer 全局工具依赖的系统库
echo "Copying Composer global tools dependencies..."
for bin in $(find /opt/composer/vendor/bin -type f); do
    if [ -x "${bin}" ]; then
        ldd "${bin}" 2>/dev/null | while read -r line; do
            if echo "${line}" | grep -q "=> /lib/" || echo "${line}" | grep -q "=> /usr/lib/"; then
                src=$(echo "${line}" | awk '{print $3}')
                if [ -f "${src}" ] && [ ! -f "${TARGET_LIB_DIR}/$(basename "${src}")" ]; then
                    cp -L "${src}" "${TARGET_LIB_DIR}/"
                fi
            fi
        done
    fi
done

echo "Library copy completed."
