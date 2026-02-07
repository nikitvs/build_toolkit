include_guard(GLOBAL)

project("BuildToolkitAdditional"
        VERSION 1.0
        LANGUAGES CXX
        DESCRIPTION "Проект дополнительных функций"
)

# Модуль основных настроек
#include(general_settings)

# Определить имя таргета проекта
set(TARGET_NAME "${PROJECT_NAME}")

#=========================== Настройки таргетов =================================

# Модуль работы с исходниками
include(target_functions)

# Определить таргет проекта
add_prepared_target(LIBRARY "STATIC" TARGET ${TARGET_NAME})

# Задать исходники таргету
set_sources_to_target(TARGET ${TARGET_NAME})

## Пробросить интерфейс
set_interface_to_target(TARGET ${TARGET_NAME} INTERFACE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/interface)
