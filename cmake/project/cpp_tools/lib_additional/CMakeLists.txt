# Фильтровать повторное подключение таргета
# TODO нужно?
#include_guard(GLOBAL)

project(lib_additional
        VERSION 1.0
        LANGUAGES CXX
        DESCRIPTION "Проект дополнительных функций"
)

# Определить имя таргета проекта
set(TARGET_NAME lib_additional)

#=========================== Настройки таргетов =================================

# Определить таргет проекта
add_library(${TARGET_NAME} INTERFACE)
