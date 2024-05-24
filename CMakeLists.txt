cmake_minimum_required(VERSION 3.10)
set(projectName openssl3s)
project(${projectName} C CXX)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# 设置共用的include目录
include_directories(${CMAKE_SOURCE_DIR}/include)

# 控制是否启用测试的变量
option(ENABLE_TEST "Enable test" ON)

add_subdirectory(src)