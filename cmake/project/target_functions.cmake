# Фильровать многочисленные включения
include_guard()

# Подключить служебный модуль
include(__auxiliary)

#[[
    ИСПОЛЬЗОВАНИЕ
        set_sources_to_target(TARGET <target>
                              [SOURCE_DIRS <dir>...]
                              [EXCLUDE_REGEXP <regexp>...]
                              [PUBLIC | PRIVATE | INTERFACE]
                              [NO_RECURSION])

    АРГУМЕНТЫ
        TARGET                      - целевой таргет
        SOURCE_DIRS                 - (опционально) список директорий поиска исходных файлов
        EXCLUDE_REGEXP              - (опционально) список регулярных выражений для исключения файлов
        PUBLIC, PRIVATE, INTERFACE  - (опционально) модификаторы видимости исходников для внешних таргетов
        NO_RECURSION                - (опционально) флаг отмены рекурсивного поиска в поддирекориях

    ОПИСАНИЕ
        Функция назначает целевому таргету исходные файлы из выбранных директорий
        Для выбранных директорий производится рекурсивный поиск исходных файлов c++ ('.cpp' и '.h')
        По умолчанию берется директория файла вызова функции
        Опционально можно указать регулярные выражения для исключения нежелательных файлов или директорий
        По умолчанию всегда добавляется регулярное выражение для исключения build директории
#]]

function(set_sources_to_target)

    #============================ Парсинг параметров функции ================================

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__SOURCES_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__OPTIONS__ "NO_RECURSION")
    set(__EXCLUSIVE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__OPTIONAL_MULTIPLE_VALUE_ARGS__ "SOURCE_DIRS" "EXCLUDE_REGEXP")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__OPTIONS__};${__EXCLUSIVE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__}"
                          "${__OPTIONAL_MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}"
                         OPTIONAL_PARAMETERS "${__OPTIONAL_MULTIPLE_VALUE_ARGS__}"
                         EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    #======================== Конец парсинга параметров функции =============================

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование целевого таргета
    __check_targets_existence__(TARGETS "${__TARGET__}")

    # Если задан список директорий
    if(DEFINED "${__PARSING_PREFIX__}_SOURCE_DIRS")
        # Взять список директорий из аргумента
        set(__SEARCH_DIRECTORIES__ "${${__PARSING_PREFIX__}_SOURCE_DIRS}")
    else()
        # Задать директорию вызова функции как диреторию поиска
        set(__SEARCH_DIRECTORIES__ "${CMAKE_CURRENT_LIST_DIR}")
    endif()

    # Проверить что директории поиска существуют
    __check_directories_existence__(DIRS "${__SEARCH_DIRECTORIES__}")

    # Задать параметр рекурсивного поиска
    if (${__PARSING_PREFIX__}_NO_RECURSION)
        set(__GLOB__ GLOB)
    else()
        set(__GLOB__ GLOB_RECURSE)
    endif()

    # Для всех директорий поиска
    foreach(__DIR__ ${__SEARCH_DIRECTORIES__})

        # Взять абсолютный путь к директории
        get_filename_component(__PATH_TO_DIR__ "${__DIR__}" ABSOLUTE)

        # Найти исходники
        file(${__GLOB__} __SEARCH_RESULT__
            "${__PATH_TO_DIR__}/*.cpp"
            "${__PATH_TO_DIR__}/*.h"
            "${__PATH_TO_DIR__}/*.ui") #TODO Qt

        # Добавить результат поиска к общему списку
        list(APPEND __SOURCES__ "${__SEARCH_RESULT__}")

        # TODO Qt
        # Найти файлы ресурсов Qt
        file(${__GLOB__} __SEARCH_RESULT__
            "${__PATH_TO_DIR__}/*.qrc")

        # Добавить результат поиска к общему списку
        list(APPEND __QRC_SOURCES__ "${__SEARCH_RESULT__}")

    endforeach()

    # Для каждого регулярного выражения
    foreach(__REGEXP__ ${${__PARSING_PREFIX__}_EXCLUDE_REGEXP})

        # Отсеять нежелательные файлы
        list(FILTER __SOURCES__ EXCLUDE REGEX "${__REGEXP__}")
        list(FILTER __QRC_SOURCES__ EXCLUDE REGEX "${__REGEXP__}")

    endforeach()

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         DEFAULT "PRIVATE"
                         OUT_VAR "__MODIFIER__")

    # Задать исходники таргету
    target_sources("${__TARGET__}" ${__MODIFIER__} "${__SOURCES__}")

    # Задать файлы ресурсов таргету (публично)
    target_sources("${__TARGET__}" PUBLIC "${__QRC_SOURCES__}")

endfunction()

#[[
    ИСПОЛЬЗОВАНИЕ
        set_include_dirs_to_target(TARGET <target>
                                   INCLUDE_DIRS <dir1> <dir2> ...
                                   [PUBLIC | PRIVATE | INTERFACE])

    АРГУМЕНТЫ
        TARGET                          - целевой таргет
        INCLUDE_DIRS                    - список директорий для назначения
        PUBLIC | PRIVATE | INTERFACE    - (опционально) модификаторы доступа

    ОПИСАНИЕ
        Функция назначает целевому таргету выбранные директории со всеми поддиректориями
        Опционально можно указать модификатор видимости для внешних таргетов
        По умолчанию берется модификатор PUBLIC
#]]

function(set_include_dirs_to_target)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__INCLUDE_DIRS_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__EXCLUSIVE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__MULTIPLE_VALUE_ARGS__ "INCLUDE_DIRS")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__EXCLUSIVE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                         EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         DEFAULT "PUBLIC"
                         OUT_VAR "__MODIFIER__")

    # Для всех директорий
    foreach(__DIR__ ${${__PARSING_PREFIX__}_INCLUDE_DIRS})

        # Взять абсолютный путь к директории
        get_filename_component(__PATH_TO_DIR__ "${__DIR__}" ABSOLUTE)

        # Проверить существование директории
        __check_directories_existence__(DIRS "${__PATH_TO_DIR__}")

        # Собрать все поддиректории
        __collect_subdirectories__(DIRECTORY "${__PATH_TO_DIR__}" OUT_VAR __INCLUDE_DIRS__)

        # Назначить директории таргету
        target_include_directories("${${__PARSING_PREFIX__}_TARGET}" ${__MODIFIER__} "${__INCLUDE_DIRS__}")

    endforeach()

endfunction()
