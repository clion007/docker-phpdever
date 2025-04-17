#!/bin/bash

# 从环境变量获取目录路径，如果未设置则使用默认值
SOURCE_DIR=${PHP_LIB_DIR:-"/usr/local/php/lib"}
TARGET_DIR=${PHP_DEP_DIR:-"/phpdever/lib"}

# 创建目标目录
mkdir -p ${TARGET_DIR}

# 复制PHP相关的动态库
cp_lib_files() {
    local file=$1
    local dest_dir=$2
    
    # 复制文件
    cp -L ${file} ${dest_dir}/
    
    # 获取依赖
    deps=$(ldd ${file} 2>/dev/null | awk '{print $3}' | grep -v "not found" | grep -v "^$")
    
    # 递归复制依赖
    for dep in ${deps}; do
        if [ -f "${dep}" ] && [ ! -f "${dest_dir}/$(basename ${dep})" ]; then
            cp_lib_files ${dep} ${dest_dir}
        fi
    done
}

# 复制PHP和相关扩展的动态库
for lib in $(find ${SOURCE_DIR} -name "*.so" -o -name "*.so.*"); do
    cp_lib_files ${lib} ${TARGET_DIR}
done

# 复制PHP可执行文件的依赖
for bin in /usr/local/php/bin/php /usr/local/php/sbin/php-fpm; do
    if [ -f "${bin}" ]; then
        deps=$(ldd ${bin} 2>/dev/null | awk '{print $3}' | grep -v "not found" | grep -v "^$")
        for dep in ${deps}; do
            if [ -f "${dep}" ] && [ ! -f "${TARGET_DIR}/$(basename ${dep})" ]; then
                cp_lib_files ${dep} ${TARGET_DIR}
            fi
        done
    fi
done

# 复制其他必要的库
for lib in $(find /usr/lib -name "libphp*.so*"); do
    if [ -f "${lib}" ] && [ ! -f "${TARGET_DIR}/$(basename ${lib})" ]; then
        cp_lib_files ${lib} ${TARGET_DIR}
    fi
done

echo "PHP动态库复制完成！共复制了$(find ${TARGET_DIR} -type f | wc -l)个文件"
