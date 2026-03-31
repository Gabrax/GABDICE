cmake_minimum_required(VERSION 3.5)
project(metal-cpp)

add_library(metal-cpp STATIC src/Metal.cpp)

target_include_directories(metal-cpp PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(metal-cpp
    "-framework Metal"
    "-framework QuartzCore"
    "-framework Foundation"
)
