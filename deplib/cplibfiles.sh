#!/bin/bash

# 定义源目录和目标目录
SOURCE_DIR="/usr/lib"
TARGET_DIR="/ffmpeg/library"

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
for lib in $(find /usr/lib/php* -name "*.so"); do
    cp_lib_files ${lib} ${TARGET_DIR}
done

# 复制其他必要的库
for lib in $(find /usr/lib -name "libphp*.so*"); do
    cp_lib_files ${lib} ${TARGET_DIR}
done

echo "动态库复制完成！"
