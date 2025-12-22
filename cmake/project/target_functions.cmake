# Фильровать многочисленные включения
include_guard()

# Подключить служебный модуль
include(service)

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
        NO_RECURSION                - (опционально) флаг отмены рекурсивного поиска в поддиректориях

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
    set(__OPTIONAL_MULTIPLE_VALUE_ARGS__ "SOURCE_DIRS" "REGEXP" "EXCLUDE_REGEXP")

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

    # Проверить существование директорий
    __check_directories_existence__(DIRS "${__SEARCH_DIRECTORIES__}")

    # Если задан список регулярных выражений
    if(DEFINED "${__PARSING_PREFIX__}_REGEXP")
        # Взять список регулярных выражений из аргумента
        set(__SEARCH_REG_EXPRESSIONS__ "${${__PARSING_PREFIX__}_REGEXP}")
    else()
        # Взять список регулярных выражений по умолчанию
        set(__SEARCH_REG_EXPRESSIONS__ "*.cpp" "*.h")
    endif()

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

        foreach(__REGEXP__ ${__SEARCH_REG_EXPRESSIONS__})

            # Найти исходники
            file(${__GLOB__} __SEARCH_RESULT__
                "${__PATH_TO_DIR__}/${__REGEXP__}")

            # Добавить результат поиска к общему списку
            list(APPEND __SOURCES__ "${__SEARCH_RESULT__}")

        endforeach()

    endforeach()

    # Для каждого регулярного выражения
    foreach(__REGEXP__ ${${__PARSING_PREFIX__}_EXCLUDE_REGEXP})
        # Отсеять нежелательные файлы
        list(FILTER __SOURCES__ EXCLUDE REGEX "${__REGEXP__}")
    endforeach()

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         DEFAULT "PRIVATE"
                         OUT_VAR "__MODIFIER__")

    # Задать исходники таргету
    target_sources("${__TARGET__}" ${__MODIFIER__} "${__SOURCES__}")

endfunction()

#[[
    ИСПОЛЬЗОВАНИЕ
        set_include_dirs_to_target(TARGET <target>
                                   INCLUDE_DIRS <dir1> <dir2> ...
                                   [PUBLIC | PRIVATE | INTERFACE])

    АРГУМЕНТЫ
        TARGET                      - целевой таргет
        INCLUDE_DIRS                - список директорий
        PUBLIC, PRIVATE, INTERFACE  - (опционально) модификаторы видимости для внешних таргетов

    ОПИСАНИЕ
        Функция назначает целевому таргету выбранные директории со всеми поддиректориями
        Опционально можно указать модификатор видимости для внешних таргетов
        По умолчанию берется модификатор PUBLIC
#]]

function(set_include_dirs_to_target)

    #============================ Парсинг параметров функции ================================

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

    #======================== Конец парсинга параметров функции =============================

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         DEFAULT "PUBLIC"
                         OUT_VAR "__MODIFIER__")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование целевого таргета
    __check_targets_existence__(TARGETS "${__TARGET__}")

    # Для всех директорий
    foreach(__DIR__ ${${__PARSING_PREFIX__}_INCLUDE_DIRS})

        # Взять абсолютный путь к директории
        get_filename_component(__PATH_TO_DIR__ "${__DIR__}" ABSOLUTE)

        # Проверить существование директорий
        __check_directories_existence__(DIRS "${__PATH_TO_DIR__}")

        # Собрать все поддиректории
        __collect_subdirectories__(DIRECTORY "${__PATH_TO_DIR__}" OUT_VAR __INCLUDE_DIRS__)

        # Назначить директории таргету
        target_include_directories("${__TARGET__}" ${__MODIFIER__} "${__INCLUDE_DIRS__}")

    endforeach()

endfunction()

#[[
ИСПОЛЬЗОВАНИЕ
    set_interface_to_target(TARGET <target>
                            INTERFACE_DIRS <dir>...
                            [PUBLIC | PRIVATE | INTERFACE]
                            [NO_RECURSION])

АРГУМЕНТЫ
    TARGET                      - целевой таргет
    INTERFACE_DIRS              - список интерфейсных директорий
    PUBLIC, PRIVATE, INTERFACE  - (опционально) модификаторы видимости для внешних таргетов
    NO_RECURSION                - (опционально) флаг отмены рекурсивного поиска в поддиректориях

ОПИСАНИЕ
    Задать целевому таргету интерфейсные директории
#]]

function(set_interface_to_target)

    #============================ Парсинг параметров функции ================================

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__INTERFACE_DIRS_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__OPTIONS__ "NO_RECURSION")
    set(__EXCLUSIVE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__MULTIPLE_VALUE_ARGS__ "INTERFACE_DIRS")

    # Парсить параметры
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__OPTIONS__};${__EXCLUSIVE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить обязательные параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                         EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    #======================== Конец парсинга параметров функции =============================

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         DEFAULT "PUBLIC"
                         OUT_VAR "__MODIFIER__")

    # Взять список интерфейсных директорий из аргумента
    set(__INTERFACE_DIRS__ "${${__PARSING_PREFIX__}_INTERFACE_DIRS}")

    # Проверить существование директорий
    __check_directories_existence__(DIRS "${__INTERFACE_DIRS__}")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование целевого таргета
    __check_targets_existence__(TARGETS "${__TARGET__}")

    # Для всех интерфейсных директорий
    foreach(__DIR__ ${__INTERFACE_DIRS__})

        # Найти все файлы и поддиректории интерфейса
        if (NOT ${__PARSING_PREFIX__}_NO_RECURSION)

            file(GLOB_RECURSE __SEARCH_RESULT__
                LIST_DIRECTORIES true
                "${__DIR__}/*")

        endif()

        # Пробросить основную директорию и все поддиректории интерфейса
        foreach(__SUBDIR__ ${__DIR__} ${__SEARCH_RESULT__})

            if (IS_DIRECTORY "${__SUBDIR__}")
                target_include_directories("${__TARGET__}" ${__MODIFIER__} "${__SUBDIR__}")
            endif()

        endforeach()

    endforeach()

endfunction()

#[[
ИСПОЛЬЗОВАНИЕ
    set_targets_binary_dir(BINARY_DIR <dir>
                           TARGETS <target>...)

АРГУМЕНТЫ
    BINARY_DIR  - путь сборки
    TARGETS     - список таргетов

ОПИСАНИЕ
    Задать путь сборки для таргетов. Если указанная директория не существует, она будет создана
#]]

function(set_targets_binary_dir)

    #============================ Парсинг параметров функции ================================

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__TARGETS_BINARY_DIR_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__ONE_VALUE_ARGS__ BINARY_DIR)
    set(__MULTIPLE_VALUE_ARGS__ TARGETS)

    # Парсить параметры
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          ""
                          "${__ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}")

    #======================== Конец парсинга параметров функции =============================

    # Взять директорию сборки из аргумента
    set(__BINARY_DIR__ "${${__PARSING_PREFIX__}_BINARY_DIR}")

    # Создать директорию сборки
    file(MAKE_DIRECTORY "${__BINARY_DIR__}")

    # Проверить существование целевого таргета
    __check_targets_existence__(TARGETS ${${__PARSING_PREFIX__}_TARGETS})

    # Подключить либы
    foreach(__TARGET__ ${${__PARSING_PREFIX__}_TARGETS})

        set_target_properties("${__TARGET__}"
                              PROPERTIES
                              RUNTIME_OUTPUT_DIRECTORY "${__BINARY_DIR__}"
                              LIBRARY_OUTPUT_DIRECTORY "${__BINARY_DIR__}"
                              ARCHIVE_OUTPUT_DIRECTORY "${__BINARY_DIR__}")

    endforeach()

endfunction()
