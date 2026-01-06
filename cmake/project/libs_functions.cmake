# Фильровать многочисленные включения
include_guard()

# Подключить служебный модуль
include(service)

#[[
    ИСПОЛЬЗОВАНИЕ
        add_module(MODULE_PATH <path>
                   [MODULE_DESTINATION_PATH <path>])

    АРГУМЕНТЫ
        MODULE_PATH             - исходный путь до модуля
        MODULE_DESTINATION_PATH - (опционально) конечный путь до модуля

    ОПИСАНИЕ
        Найти и подключить в проект указанный модуль
        Функция проверяет свою сигнатуру
#]]

function(add_module)

    #============================ Парсинг параметров функции ================================

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__ADDING_MODULE_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__ONE_VALUE_ARGS__ "MODULE_PATH")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "MODULE_DESTINATION_PATH")

    # Парсить параметры
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          ""
                          "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}"
                          ""
                          "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}"
                         OPTIONAL_PARAMETERS "${__OPTIONAL_ONE_VALUE_ARGS__}")

    #======================== Конец парсинга параметров функции =============================

    # Вычислить абсолютный путь к модулю
    get_filename_component(__ABS_PATH_TO_MODULE__ "${${__PARSING_PREFIX__}_MODULE_PATH}" ABSOLUTE)

    # Вычислить хэш от мути к модулю
    string(SHA256 __MODULE_HASH__ "${__ABS_PATH_TO_MODULE__}")

    # Подключить модуль только один раз за всю конфигурацию
    # (в отличие от кеширования, проверка производится заново на каждом этапе конфигурации)
    if ("$ENV{ALREADY_LINKED_${__MODULE_HASH__}}" STREQUAL "true")

        # Прервать функцию
        return()

    endif()

    # Отметить факт подключения модуля
    set(ENV{ALREADY_LINKED_${__MODULE_HASH__}} "true")

    # Проверить что директория существует
    __check_directories_existence__(DIRS "${__ABS_PATH_TO_MODULE__}")

    # Вычислить путь к модулю относительно корня проекта
    file(RELATIVE_PATH __REL_PATH_TO_MODULE__ ${CMAKE_SOURCE_DIR} "${__ABS_PATH_TO_MODULE__}")

    # Проверить, что модуль является частью проекта
    if (__REL_PATH_TO_MODULE__ MATCHES "^\.\./")
        message(FATAL_ERROR "Модуль '${__ABS_PATH_TO_MODULE__}' не является частью основного проекта")
    endif()

    # Если задан кастомный путь сборки
    if (DEFINED "${__PARSING_PREFIX__}_MODULE_DESTINATION_PATH")

        # Путь сборки модуля
        set(__MODULE_BINARY_DIR__ "${${__PARSING_PREFIX__}_MODULE_DESTINATION_PATH}")

    else()

        # Путь сборки модуля по умолчанию
        set(__MODULE_BINARY_DIR__ "${CMAKE_BINARY_DIR}/${__REL_PATH_TO_MODULE__}")

    endif()

    # Подключить модуль
    add_subdirectory("${__ABS_PATH_TO_MODULE__}" "${__MODULE_BINARY_DIR__}")

endfunction()

#[[
    ИСПОЛЬЗОВАНИЕ
        link_module_libraries(TARGET <target>
                              MODULE_PATH <path>
                              MODULE_LIBS <lib>...
                              [MODULE_DESTINATION_PATH <path>]
                              [PUBLIC | PRIVATE | INTERFACE])

    АРГУМЕНТЫ
        TARGET                      - имя таргета
        MODULE_PATH                 - исходный путь до модуля
        MODULE_LIBS                 - список таргетов библиотек, которые необходимо подключить
        MODULE_DESTINATION_PATH     - (опционально) конечный путь до модуля
        PUBLIC, PRIVATE, INTERFACE  - (опционально) модификаторы видимости модулей для внешних таргетов (по умолчанию PUBLIC)

    ОПИСАНИЕ
        Найти и подключить к целевому таргету указанные модули
        Функция проверяет свою сигнатуру
#]]

function(link_module_libraries)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__LINKING_MODULE_LIBRARIES_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__EXCLUSIVE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET" "MODULE_PATH")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "MODULE_DESTINATION_PATH")
    set(__MULTIPLE_VALUE_ARGS__ "MODULE_LIBS")

    # Парсить параметры
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__EXCLUSIVE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить обязательные параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                         OPTIONAL_PARAMETERS "${__OPTIONAL_ONE_VALUE_ARGS__}"
                         EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    #======================== Конец парсинга параметров функции =============================

    # Проверить существование основного таргета
    __check_targets_existence__(TARGETS "${${__PARSING_PREFIX__}_TARGET}")

    # Подключить модуль
    if (DEFINED "${__PARSING_PREFIX__}_MODULE_DESTINATION_PATH")

        add_module(MODULE_PATH "${${__PARSING_PREFIX__}_MODULE_PATH}"
                   MODULE_DESTINATION_PATH "${${__PARSING_PREFIX__}_MODULE_DESTINATION_PATH}")

    else()

        add_module(MODULE_PATH "${${__PARSING_PREFIX__}_MODULE_PATH}")

    endif()

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "PUBLIC")

    __check_targets_existence__(TARGETS "${${__PARSING_PREFIX__}_MODULE_LIBS}")

    # Подключить модули
    foreach(__LIB__ ${${__PARSING_PREFIX__}_MODULE_LIBS})

        # Пропускать подключение таргета самого к себе
        if ("${${__PARSING_PREFIX__}_TARGET}" STREQUAL "${__LIB__}")
            continue()
        endif()

        # Подключить библиотеку
        target_link_libraries("${${__PARSING_PREFIX__}_TARGET}" ${__MODIFIER__} "${__LIB__}")

    endforeach()

endfunction()
