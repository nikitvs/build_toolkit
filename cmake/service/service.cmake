include_guard()

# Служебные функции cmake

include(${CMAKE_CURRENT_LIST_DIR}/details.cmake)

#[[
    ИСПОЛЬЗОВАНИЕ
        collect_subdirs(DIRECTORY <dir>
                        OUT_VAR <outputVariable>
                        [MAX_DEPTH <maxDepth>]
                        [NO_ROOT])

    АРГУМЕНТЫ
        DIRECTORY   - корневая директория, для которой будет осуществлен поиск поддиректорий
        OUT_VAR     - имя переменной, куда запишется результат
        MAX_DEPTH   - (опционально) максимальная уровень вложенности, до которого следует искать поддиректории
        NO_ROOT     - (опционально) не добавлять корневую директорию в результирующий список

    ОПИСАНИЕ
        Функция предназначена для поиска и формирования списка поддиректорий для заданной директории
        По умолчанию поиск будет осуществляться рекурсивно до нахождения директорий на всех уровнях вложенности
        Опционально можно задать максимальную глубину вложенности, до которой будет осуществляться поиск
        По умолчанию исходная директория также добавляется в итоговый список. Опционально это можно запретить
#]]

function(collect_subdirs)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__SUBDIRECTORIES_COLLECTING_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__FLAGS__ "NO_ROOT")
    set(__ONE_VALUE_ARGS__ "DIRECTORY" "OUT_VAR")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "MAX_DEPTH")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__FLAGS__}"
                          "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}"
                          ""
                          "${ARGN}")

    # Проверить параметры функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        PARAMETERS "${__ONE_VALUE_ARGS__}"
                        OPTIONAL_PARAMETERS "${__OPTIONAL_ONE_VALUE_ARGS__}")

    # Взять исходную директорию из аргумента
    set(__ROOT_DIR__ "${${__PARSING_PREFIX__}_DIRECTORY}")

    # Проверить существование исходной директории
    __check_directories_existence__(DIRS "${__ROOT_DIR__}")

    # Если не было специального флага -> добавить исходную директорию в итоговый список
    if(NOT ${__PARSING_PREFIX__}_NO_ROOT)
        # Задать переменную для записи всех найденных файлов и директорий
        list(APPEND __RESULT__ "${__ROOT_DIR__}")
    endif()

    # В случае, если НЕ задана максимальная глубина
    if(NOT DEFINED "${__PARSING_PREFIX__}_MAX_DEPTH")

        # Найти на всех уровнях файлы с директориями
        file(GLOB_RECURSE __SEARCH_RESULT__
            LIST_DIRECTORIES true
            ${__ROOT_DIR__}/*)

        # Для всех найденных файлов с директориями
        foreach(__ELEM__ ${__SEARCH_RESULT__})

            # Запомнить директории
            if (IS_DIRECTORY ${__ELEM__})
                list(APPEND __RESULT__ ${__ELEM__})
            endif()

        endforeach()

    else()

        # Взять значение максимальной глубины из аргумента
        set(__MAX_DEPTH__ "${${__PARSING_PREFIX__}_MAX_DEPTH}")

        # Проверить значение максимальной глубины
        if(NOT ${__MAX_DEPTH__} MATCHES "^(0|[1-9][0-9]*)$")
            message(FATAL_ERROR "Значение MAX_DEPTH должно быть целым беззнаковым числом: ${__MAX_DEPTH__}")
        endif()

        # Если еще не конец
        if(NOT ${__MAX_DEPTH__} EQUAL 0)

            # Найти на текущем уровне все файлы с директориями
            file(GLOB __SEARCH_RESULT__
                LIST_DIRECTORIES true
                ${__ROOT_DIR__}/*)

            # Уменьшить уровень глубины
            math(EXPR __REDUCED_MAX_DEPTH__ "${__MAX_DEPTH__} - 1")

            # Для найденных файлов с директориями
            foreach(__ELEM__ ${__SEARCH_RESULT__})

                # Если это директория
                if (IS_DIRECTORY ${__ELEM__})

                    # Рекурсивно запустить поиск директорий (включая ее саму как исходную) на следующем уровне
                    collect_subdirs(DIRECTORY "${__ELEM__}"
                                    OUT_VAR "__CURRENT_OUT_VAR__"
                                    MAX_DEPTH "${__REDUCED_MAX_DEPTH__}")

                    # Добавить найденные директории к результату
                    list(APPEND __RESULT__ "${__CURRENT_OUT_VAR__}")

                endif()

            endforeach()

        endif()

    endif()

    # Взять имя выходной переменной из аргумента
    set(__OUT_VAR__ "${${__PARSING_PREFIX__}_OUT_VAR}")

    # Записать результат (если есть) в выходную переменную
    __extract_arg_value__(ARG "__RESULT__" OUT_VAR "${__OUT_VAR__}")

    # Вернуть значение выходной переменной
    return(PROPAGATE ${__OUT_VAR__})

endfunction()

#[[
ИСПОЛЬЗОВАНИЕ
    add_subdirs([FATAL_ERROR | WARNING])

АРГУМЕНТЫ
    FATAL_ERROR, WARNING    - (опционально) модификаторы проверки наличия CMake-проектов в директориях (по умолчанию WARNING)

ОПИСАНИЕ
    Подключить как CMake-проекты все директории рядом с файлом вызова функции
#]]

function(add_subdirs)

    set(__PARSING_PREFIX__ "__ADDING_SUBDIRECTORIES_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__EXCLUSIVE_MODIFIERS__ "FATAL_ERROR" "WARNING")

    # Парсить параметры
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__EXCLUSIVE_MODIFIERS__}"
                          ""
                          ""
                          "${ARGN}")

    # Проверить обязательные параметры функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    #======================== Конец парсинга параметров функции =============================

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "WARNING")

    get_filename_component(__CMAKE_FILENAME__ "${CMAKE_CURRENT_LIST_FILE}" NAME)

    # Найти все поддиректории
    file(GLOB __SUBDIRS__
         LIST_DIRECTORIES true
         "*")

    foreach(__DIR__ ${__SUBDIRS__})

        # Искать только директории
        if(NOT IS_DIRECTORY ${__DIR__})
            continue()
        endif()

        # Проверять наличие файла 'CMakeLists.txt'
        if(EXISTS ${__DIR__}/${__CMAKE_FILENAME__})
            add_subdirectory(${__DIR__})
        else()
            message(${__MODIFIER__} "Директория ${__DIR__} не имеет файла ${__CMAKE_FILENAME__}!")
        endif()

    endforeach()

endfunction()

