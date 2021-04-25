cmake_minimum_required(VERSION 3.13)
set(PROJECT_NAME "gpiod")
project(${PROJECT_NAME} LANGUAGES C)

add_library(${PROJECT_NAME} SHARED
    "lib/core.c"
    "lib/ctxless.c"
    "lib/helpers.c"
    "lib/iter.c"
    "lib/misc.c"
)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    HAVE_CONFIG_H
)
target_compile_options(${PROJECT_NAME} PRIVATE
    -Wall
    -Wextra
    -pedantic
    -Wshadow
    -include ${CMAKE_CURRENT_SOURCE_DIR}/config.h
)
set_target_properties(${PROJECT_NAME} PROPERTIES C_VISIBILITY_PRESET hidden)
target_include_directories(${PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
)