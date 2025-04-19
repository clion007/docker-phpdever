#!/bin/sh
set -e

TARGET_LIB_DIR="${1:-/phpdever/lib}"
PHP_INSTALL_DIR="${PHP_INSTALL_DIR:-/usr/local/php}"
mkdir -p "${TARGET_LIB_DIR}"

# 复制 PHP 依赖的系统库
echo "Copying PHP binary dependencies..."
for bin in $(find ${PHP_INSTALL_DIR}/bin ${PHP_INSTALL_DIR}/sbin -type f -executable); do
    ldd "${bin}" 2>/dev/null | while read -r line; do
        if echo "${line}" | grep -q "=> /lib/" || echo "${line}" | grep -q "=> /usr/lib/"; then
            src=$(echo "${line}" | awk '{print $3}')
            if [ -f "${src}" ] && [ ! -f "${TARGET_LIB_DIR}/$(basename "${src}")" ]; then
                cp -L "${src}" "${TARGET_LIB_DIR}/"
                # 递归复制依赖的依赖
                ldd "${src}" 2>/dev/null | while read -r subline; do
                    if echo "${subline}" | grep -q "=> /lib/" || echo "${subline}" | grep -q "=> /usr/lib/"; then
                        subsrc=$(echo "${subline}" | awk '{print $3}')
                        if [ -f "${subsrc}" ] && [ ! -f "${TARGET_LIB_DIR}/$(basename "${subsrc}")" ]; then
                            cp -L "${subsrc}" "${TARGET_LIB_DIR}/"
                        fi
                    fi
                done
            fi
        fi
    done
done

# 复制 PHP 扩展依赖的系统库
echo "Copying PHP extension dependencies..."
for ext in $(find ${PHP_INSTALL_DIR}/lib/php/extensions -type f -name "*.so"); do
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

# 确保复制了一些基础库，这些库可能不是直接依赖但在运行时需要
echo "Copying additional essential libraries..."
for lib in libc.so.6 libpthread.so.0 libdl.so.2 libm.so.6 librt.so.1; do
    if [ -f "/lib/${lib}" ] && [ ! -f "${TARGET_LIB_DIR}/${lib}" ]; then
        cp -L "/lib/${lib}" "${TARGET_LIB_DIR}/"
    elif [ -f "/usr/lib/${lib}" ] && [ ! -f "${TARGET_LIB_DIR}/${lib}" ]; then
        cp -L "/usr/lib/${lib}" "${TARGET_LIB_DIR}/"
    fi
done

echo "Library copy completed.
