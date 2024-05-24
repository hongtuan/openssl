#!/bin/sh
target_path=$(pwd)/openssl_3.3
echo $target_path
# 记录编译开始时间
start_time=$(date +%s)
./Configure --prefix="$target_path" --openssldir="$target_path" \
    "-Wl,--enable-new-dtags,-rpath,$target_path"

make
make test

# 记录编译结束时间
end_time=$(date +%s)
# 计算编译耗时
build_duration=$((end_time - start_time))
echo "OpenSSL库编译耗时: $build_duration seconds"
if [ $build_duration -gt 60 ]; then
    build_duration_minutes=$(echo "scale=2; $build_duration/60" | bc)
    echo "OpenSSL编译耗时: $build_duration_minutes 分钟"
fi
