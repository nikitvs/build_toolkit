include_guard()

# Определить версию CMake
cmake_minimum_required(VERSION 3.25)

# Подключить служебный модуль
include(${CMAKE_CURRENT_LIST_DIR}/service/service.cmake)

# Собрать все директории модулей cmake (включая текущую директорию)
collect_subdirs(DIRECTORY ${CMAKE_CURRENT_LIST_DIR} OUT_VAR "__CMAKE_MODULES_DIRS__")

# Добавить директории модулей cmake в список стандартных путей
list(APPEND CMAKE_MODULE_PATH "${__CMAKE_MODULES_DIRS__}")

# "Вытащить наружу" пути к модулям cmake
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" PARENT_SCOPE)
