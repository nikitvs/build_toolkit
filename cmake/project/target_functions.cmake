include_guard()

# Подключить служебный модуль
include(${CMAKE_CURRENT_LIST_DIR}/../service/service.cmake)

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

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__SOURCES_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию аргументов парсинга
    set(__OPTIONS__ "NO_RECURSION")
    set(__INCOMPATIBLE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__OPTIONAL_MULTIPLE_VALUE_ARGS__ "SOURCE_DIRS" "REGEXP" "EXCLUDE_REGEXP")

    # Парсить аргументы функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__OPTIONS__};${__INCOMPATIBLE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__}"
                          "${__OPTIONAL_MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}"
                        OPTIONAL_ARGS "${__OPTIONAL_MULTIPLE_VALUE_ARGS__}"
                        INCOMPATIBLE_ARGS "${__INCOMPATIBLE_MODIFIERS__}")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование целевого таргета
    __check_targets_existence__(TARGETS "${__TARGET__}")

    # Задать список директорий поиска
    __extract_arg_value__(ARG "SOURCE_DIRS"
                          OUT_VAR "__SEARCH_DIRECTORIES__"
                          FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                          DEFAULT "${CMAKE_CURRENT_LIST_DIR}")

    # Проверить существование директорий
    __check_directories_existence__(DIRS "${__SEARCH_DIRECTORIES__}")

    # Задать список регулярных выражений
    __extract_arg_value__(ARG "REGEXP"
                          OUT_VAR "__SEARCH_REG_EXPRESSIONS__"
                          FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                          DEFAULT "*.cpp" "*.h")

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

    # Извлечь модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__INCOMPATIBLE_MODIFIERS__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "PRIVATE")

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

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__INCLUDE_DIRS_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию аргументов парсинга
    set(__INCOMPATIBLE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__MULTIPLE_VALUE_ARGS__ "INCLUDE_DIRS")

    # Парсить аргументы функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__INCOMPATIBLE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                        INCOMPATIBLE_ARGS "${__INCOMPATIBLE_MODIFIERS__}")

    # Извлечь модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__INCOMPATIBLE_MODIFIERS__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "PRIVATE")

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
        collect_subdirs(DIRECTORY "${__PATH_TO_DIR__}" OUT_VAR "__INCLUDE_DIRS__")

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

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__INTERFACE_DIRS_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию аргументов парсинга
    set(__OPTIONS__ "NO_RECURSION")
    set(__INCOMPATIBLE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__MULTIPLE_VALUE_ARGS__ "INTERFACE_DIRS")

    # Парсить аргументы
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__OPTIONS__};${__INCOMPATIBLE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                        INCOMPATIBLE_ARGS "${__INCOMPATIBLE_MODIFIERS__}")

    # Извлечь модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__INCOMPATIBLE_MODIFIERS__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "PUBLIC")

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
                set_include_dirs_to_target(${__MODIFIER__} TARGET "${__TARGET__}" INCLUDE_DIRS "${__SUBDIR__}")
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

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__TARGETS_BINARY_DIR_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию аргументов парсинга
    set(__ONE_VALUE_ARGS__ BINARY_DIR)
    set(__MULTIPLE_VALUE_ARGS__ TARGETS)

    # Парсить аргументы
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          ""
                          "${__ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}")

    # Взять директорию сборки из аргумента
    set(__BINARY_DIR__ "${${__PARSING_PREFIX__}_BINARY_DIR}")

    # Создать директорию сборки
    file(MAKE_DIRECTORY "${__BINARY_DIR__}")

    # Проверить существование таргетов
    __check_targets_existence__(TARGETS ${${__PARSING_PREFIX__}_TARGETS})

    # Задать директорию сборки
    foreach(__TARGET__ ${${__PARSING_PREFIX__}_TARGETS})

        set_target_properties("${__TARGET__}"
                              PROPERTIES
                              RUNTIME_OUTPUT_DIRECTORY "${__BINARY_DIR__}"
                              LIBRARY_OUTPUT_DIRECTORY "${__BINARY_DIR__}"
                              ARCHIVE_OUTPUT_DIRECTORY "${__BINARY_DIR__}")

    endforeach()

endfunction()

#[[
ИСПОЛЬЗОВАНИЕ
    add_prepared_target(EXECUTABLE | LIBRARY
                        TARGET <target>
                        SOURCES <source>...
                        [STATIC | SHARED | MODULE | OBJECT]
                        [DEBUG_OPTIONS <options>]
                        [RELEASE_OPTIONS <options>]
                        [PUBLIC | PRIVATE | INTERFACE]
                        [NO_SANITIZERS]
                        [EXCLUDE_FROM_ALL])

АРГУМЕНТЫ
    EXECUTABLE | LIBRARY            - тип создаваемого таргета (исполняемый файл или библиотека)
    TARGET                          - имя создаваемого таргета
    SOURCES                         - список исходных текстов
    STATIC, SHARED, MODULE, OBJECT  - (опционально) модификаторы, определяющие тип библиотеки
    DEBUG_OPTIONS                   - (опционально) опции компиляции для отладки
    RELEASE_OPTIONS                 - (опционально) опции компиляции для релиза
    PUBLIC, PRIVATE, INTERFACE      - (опционально) модификаторы распространения опций компиляции на внешние таргеты
    NO_SANITIZERS                   - (опционально) флаг отключения санитайзеров
    EXCLUDE_FROM_ALL                - (опционально) исключить из таргета 'all'

ОПИСАНИЕ
    Создать подготовленный таргет исполняемого файла или библиотеки
#]]

function(add_prepared_target)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__ADDING_PREPARED_TARGET__")

    # Задать конфигурацию аргументов парсинга
    set(__OPTIONS__ "NO_SANITIZERS" "EXCLUDE_FROM_ALL")
    set(__INCOMPATIBLE_MODIFIERS_TARGET_TYPE__ "EXECUTABLE" "LIBRARY")
    set(__INCOMPATIBLE_MODIFIERS_LIBRARY_TYPE__ "STATIC" "SHARED" "MODULE" "OBJECT")
    set(__INCOMPATIBLE_MODIFIERS_VISIBILITY__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "RELEASE_OPTIONS" "DEBUG_OPTIONS")
    set(__OPTIONAL_MULTIPLE_VALUE_ARGS__ "SOURCES")

    # Парсить аргументы
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__OPTIONS__};${__INCOMPATIBLE_MODIFIERS_TARGET_TYPE__};${__INCOMPATIBLE_MODIFIERS_LIBRARY_TYPE__};${__INCOMPATIBLE_MODIFIERS_VISIBILITY__}"
                          "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}"
                          "${__OPTIONAL_MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}"
                        OPTIONAL_ARGS "${__OPTIONAL_ONE_VALUE_ARGS__};${__OPTIONAL_MULTIPLE_VALUE_ARGS__}"
                        INCOMPATIBLE_ARGS "${__INCOMPATIBLE_MODIFIERS_TARGET_TYPE__}")

    # Отдельно проверить на пересечения типы библиотеки
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        INCOMPATIBLE_ARGS "${__INCOMPATIBLE_MODIFIERS_LIBRARY_TYPE__}")

    # Отдельно проверить на пересечения модификаторы видимости
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        INCOMPATIBLE_ARGS "${__INCOMPATIBLE_MODIFIERS_VISIBILITY__}")

    # Проверить, что тип библиотеки нельзя задать для исполняемого файла
    __check_incompatible_groups_intersections__(GROUP_1 "EXECUTABLE"
                                                GROUP_2 "${__INCOMPATIBLE_MODIFIERS_LIBRARY_TYPE__}"
                                                FUNCTION_PREFIX "${__PARSING_PREFIX__}")

    # Взять имя целевого таргета из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Извлечь модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "EXCLUDE_FROM_ALL"
                         OUT_VAR "__EXCLUDE__")

    # Создать таргет
    if(${__PARSING_PREFIX__}_EXECUTABLE)

        add_executable("${__TARGET__}" ${__EXCLUDE__} ${${__PARSING_PREFIX__}_SOURCES})

    elseif(${__PARSING_PREFIX__}_LIBRARY)

        # Извлечь модификатор
        __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                             AVAILABLE_MODIFIERS "${__INCOMPATIBLE_MODIFIERS_LIBRARY_TYPE__}"
                             OUT_VAR "__LIBRARY_TYPE__")

        add_library("${__TARGET__}" ${__LIBRARY_TYPE__} ${__EXCLUDE__} ${${__PARSING_PREFIX__}_SOURCES})

    else()

        message(FATAL_ERROR "Должен быть задан тип создаваемого таргета: ${__INCOMPATIBLE_MODIFIERS_TARGET_TYPE__}")

    endif()

    # Извлечь модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__INCOMPATIBLE_MODIFIERS_VISIBILITY__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "PRIVATE")

    # Подключить модуль библиотечных функций
    include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/libs_functions.cmake)

    # Подключить библиотеку дополнительных функций
    link_module_libraries(
        PUBLIC
        TARGET "${__TARGET__}"
        MODULE_PATH "${__BUILD_TOOLKIT_CPP_TOOLS_DIR__}/lib_additional"
        MODULE_LIBS "BuildToolkitAdditional")

    if(CMAKE_BUILD_TYPE MATCHES "Release")

        # Определить опции сборки
        __extract_arg_value__(ARG "RELEASE_OPTIONS"
                              OUT_VAR "__COMPILE_OPTIONS__"
                              FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                              DEFAULT "-O2")

        # Определить c++ макрос выключенной отладки
        target_compile_definitions("${__TARGET__}" ${__MODIFIER__} NDEBUG)

    elseif(CMAKE_BUILD_TYPE MATCHES "Debug")

        # Определить опции сборки
        __extract_arg_value__(ARG "DEBUG_OPTIONS"
                              OUT_VAR "__COMPILE_OPTIONS__"
                              FUNCTION_PREFIX "${__PARSING_PREFIX__}")

        # Подключить либу с фичами для отладки
        link_module_libraries(
            PUBLIC
            TARGET "${__TARGET__}"
            MODULE_PATH "${__BUILD_TOOLKIT_CPP_TOOLS_DIR__}/lib_dev_tools"
            MODULE_LIBS "BuildToolkitDevTools")

        # Подключить модуль диагностики
        include(${CMAKE_CURRENT_FUNCTION_LIST_DIR}/diagnostics_functions.cmake)

        # Извлечь модификатор
        __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                             AVAILABLE_MODIFIERS "NO_SANITIZERS"
                             OUT_VAR "__NO_SANITIZERS__")

        # Подключить диагностику
        # TODO
        use_diagnostics(${__MODIFIER__} ${__NO_SANITIZERS__} TARGET "${__TARGET__}")

# TODO
#        # Использовать анализатор кода
#        use_pvs(TARGET "${__TARGET__}")

    endif()

    # Задать опции сборки
    target_compile_options("${__TARGET__}" ${__MODIFIER__} "${__COMPILE_OPTIONS__}")

endfunction()
