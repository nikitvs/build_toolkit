project("BuildToolkitAdditionalQt"
        VERSION 1.0
        LANGUAGES CXX
        DESCRIPTION "Проект дополнительных функций Qt"
)

# Определить имя таргета проекта
set(TARGET_NAME "${PROJECT_NAME}")

#=========================== Настройки таргетов =================================

# Определить таргет проекта
add_library(${TARGET_NAME} INTERFACE)
