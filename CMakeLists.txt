cmake_minimum_required(VERSION 3.5)
set(CMAKE_POLICY_VERSION_MINIMUM 3.5)

project(gab_dice)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(FetchContent)
set(FETCHCONTENT_QUIET FALSE)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(BUILD_GAMES    OFF CACHE BOOL "" FORCE)

FetchContent_Declare(
    raylib
    GIT_REPOSITORY "https://github.com/raysan5/raylib.git"
    GIT_TAG "master"
    GIT_PROGRESS TRUE
)

FetchContent_Declare(
    JoltPhysics
    GIT_REPOSITORY "https://github.com/jrouwe/JoltPhysics"
    GIT_TAG "v5.5.0"
    SOURCE_SUBDIR "Build"
)

FetchContent_MakeAvailable(JoltPhysics raylib)

file(GLOB_RECURSE PROJECT_SOURCES CONFIGURE_DEPENDS "${CMAKE_CURRENT_LIST_DIR}/src/*.cpp")
set(PROJECT_INCLUDE "${CMAKE_CURRENT_LIST_DIR}/src/")

add_executable("${CMAKE_PROJECT_NAME}")
target_sources(${CMAKE_PROJECT_NAME} PRIVATE ${PROJECT_SOURCES})
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE ${PROJECT_INCLUDE} ${JoltPhysics_SOURCE_DIR}/..)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Jolt raylib)