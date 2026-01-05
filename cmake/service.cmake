# Фильровать многочисленные включения
include_guard()

# Служебные функции cmake

#[[
    ИСПОЛЬЗОВАНИЕ
        __check_parameters__(PREFIX <prefix>
                             PARAMETERS <par>...
                             [OPTIONAL_PARAMETERS <optionalParam>...]
                             [EXCLUSIVE_MODIFIERS <modifier>...])

    АРГУМЕНТЫ
        PREFIX              - префикс парсинга параметров проверяемой функции
        PARAMETERS          - список обязательных параметров проверяемой функции
        OPTIONAL_PARAMETERS - (опционально) список опциональных параметров проверяемой функции
        EXCLUSIVE_MODIFIERS - (опционально) список взаимно исключающих модификаторов проверяемой функции

    ОПИСАНИЕ
        Функция предназначена для проверки входных параметров кастомных CMake функций
        Данная функция должна вызываться после парсинга параметров проверяемой функции
#]]

function(__check_parameters__)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__FUNCTION_PARAMETERS_CHECKING_PREFIX__")

    # Если это старт функции
    if(NOT DEFINED __SELF_CHECKING__)

        # Отметить начало этапа самопроверки
        set(__SELF_CHECKING__ True)

        # Парсить аргументы функции (для всех проверок одного раза достаточно)
        cmake_parse_arguments("${__PARSING_PREFIX__}"
                              ""
                              "PREFIX"
                              "PARAMETERS;OPTIONAL_PARAMETERS;EXCLUSIVE_MODIFIERS"
                              "${ARGN}")

        # Запустить самопроверку (одноуровневая рекурсия)
        __check_parameters__()

        # Отметить завершение этапа самопроверки
        set(__SELF_CHECKING__ False)

    endif()

    # В данный момент ИДЕТ самопроверка?
    if(${__SELF_CHECKING__})

        # Задать префикс вызывающей функции как префикс парсинга
        set(__FUNCTION_PREFIX__ "${__PARSING_PREFIX__}")

        # Задать обязательные параметры для проверки
        set(__REQUIRED_PARAMETERS__ "PREFIX")

        # Задать опциональные параметры для проверки
        set(__OPTIONAL_PARAMETERS__ "PARAMETERS;OPTIONAL_PARAMETERS;EXCLUSIVE_MODIFIERS")

    else()

        # Взять префикс вызывающей функции из значения аргумента
        set(__FUNCTION_PREFIX__ "${${__PARSING_PREFIX__}_PREFIX}")

        # Взять обязательные параметры для проверки из значения аргумента
        set(__REQUIRED_PARAMETERS__ "${${__PARSING_PREFIX__}_PARAMETERS}")

        # Взять опциональные параметры для проверки из значения аргумента
        set(__OPTIONAL_PARAMETERS__ "${${__PARSING_PREFIX__}_OPTIONAL_PARAMETERS}")

        # Для каждого возможного уникального флага
        foreach(__FLAG__ ${${__PARSING_PREFIX__}_EXCLUSIVE_MODIFIERS})

            # Если флаг активен -> запомнить его
            if(${__FUNCTION_PREFIX__}_${__FLAG__})
                list(APPEND __FLAGS_NAMES__ "${__FLAG__}")
            endif()

        endforeach()

        # Посчитать количество активных флагов
        list(LENGTH __FLAGS_NAMES__ __ACTIVE_FLAGS_COUNT__)

        # Проверить, что активно не более одного флага
        if(${__ACTIVE_FLAGS_COUNT__} GREATER 1)
            message(FATAL_ERROR "Флаги не могут быть использованны одновременно: ${__FLAGS_NAMES__}")
        endif()

    endif()

    # Для каждого параметра (обязательного и опционального)
    foreach(__PAR__ ${__REQUIRED_PARAMETERS__} ${__OPTIONAL_PARAMETERS__})

        # Проверить, что для параметра задано значение
        list(FIND "${__FUNCTION_PREFIX__}_KEYWORDS_MISSING_VALUES" ${__PAR__} __ARG_INDEX__)
        if(NOT ${__ARG_INDEX__} EQUAL -1)
            message(FATAL_ERROR "У параметра '${__PAR__}' должно быть задано значение")
        endif()

    endforeach()

    # Для каждого обязательного параметра
    foreach(__PAR__ ${__REQUIRED_PARAMETERS__})

        # Проверить, что параметр определен
        if(NOT DEFINED "${__FUNCTION_PREFIX__}_${__PAR__}")
            message(FATAL_ERROR "Параметр '${__PAR__}' должен быть определен")
        endif()

    endforeach()

    # Проверить наличие лишних параметров
    if(DEFINED "${__FUNCTION_PREFIX__}_UNPARSED_ARGUMENTS")
        message(FATAL_ERROR "Присутствуют лишние параметры: ${${__FUNCTION_PREFIX__}_UNPARSED_ARGUMENTS}")
    endif()

endfunction()

#[[
    ИСПОЛЬЗОВАНИЕ
        __check_directories_existence__(DIRS <dir>...)

    АРГУМЕНТЫ
        DIRS    - пути к проверяемым директориям

    ОПИСАНИЕ
        Функция предназначена для проверки существования указанных директорий
#]]

function(__check_directories_existence__)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__DIRECTORIES_EXISTENCE_CHECKING_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__MULTIPLE_VALUE_ARGS__ "DIRS")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          ""
                          ""
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__MULTIPLE_VALUE_ARGS__}")

    # Для каждой директории
    foreach(__DIR__ ${${__PARSING_PREFIX__}_DIRS})

        # Взять абсолютный путь к директории
        get_filename_component(__PATH_TO_DIR__ "${__DIR__}" ABSOLUTE)

        # Проверить что директория существует
        if (NOT IS_DIRECTORY "${__PATH_TO_DIR__}")
            message(FATAL_ERROR "Не существует директории: ${__PATH_TO_DIR__}")
        endif()

    endforeach()

endfunction()

#[[
    ИСПОЛЬЗОВАНИЕ
        __collect_subdirectories__(DIRECTORY <dir>
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

function(__collect_subdirectories__)

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
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}"
                         OPTIONAL_PARAMETERS "${__OPTIONAL_ONE_VALUE_ARGS__}")

    # Взять исходную директорию из аргумента
    set(__ROOT_DIR__ "${${__PARSING_PREFIX__}_DIRECTORY}")

    # Проверить существование исходной директории
    __check_directories_existence__(DIRS "${__ROOT_DIR__}")

    # Задать переменную для записи всех найденных файлов и директорий
    set(__RESULT__)

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
                    __collect_subdirectories__(DIRECTORY "${__ELEM__}"
                                               OUT_VAR __CURRENT_OUT_VAR__
                                               MAX_DEPTH "${__REDUCED_MAX_DEPTH__}")

                    # Добавить найденные директории к результату
                    list(APPEND __RESULT__ "${__CURRENT_OUT_VAR__}")

                endif()

            endforeach()

        endif()

    endif()

    # Взять имя выходной переменной из аргумента
    set(__OUT_VAR__ "${${__PARSING_PREFIX__}_OUT_VAR}")

    # Записать в выходную переменную все собранные директории
    set(${__OUT_VAR__} "${__RESULT__}")

    # Если не было специального флага -> добавить исходную директорию в итоговый список
    if(NOT ${__PARSING_PREFIX__}_NO_ROOT)
        list(APPEND ${__OUT_VAR__} "${__ROOT_DIR__}")
    endif()

    # Вернуть значение выходной переменной
    return(PROPAGATE ${__OUT_VAR__})

endfunction()

#[[
    ИСПОЛЬЗОВАНИЕ
        __extract_modifier__(FUNCTION_PREFIX <prefix>
                             AVAILABLE_MODIFIERS <modifier>...
                             DEFAULT <modifier>
                             OUT_VAR <outputVariable>)

    АРГУМЕНТЫ
        FUNCTION_PREFIX     - префикс функции, для которой вызвано извлечение модификатора
        AVAILABLE_MODIFIERS - допустимые модификаторы
        DEFAULT             - модификатор по умолчанию
        OUT_VAR             - имя переменной, куда запишется результат

    ОПИСАНИЕ
        Извлечь использованный при вызове фукции модификатор
        Если модификатор не выбран, вернуть значение по умолчанию
        Результат записывается в указанную переменную
#]]

function(__extract_modifier__)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__MODIFIER_EXTRACTION_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__ONE_VALUE_ARGS__ "FUNCTION_PREFIX" "OUT_VAR")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "DEFAULT")
    set(__MULTIPLE_VALUE_ARGS__ "AVAILABLE_MODIFIERS")

    # Парсить параметры
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          ""
                          "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")


    # Проверить обязательные параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                         OPTIONAL_PARAMETERS "${__OPTIONAL_ONE_VALUE_ARGS__}")

    #======================== Конец парсинга параметров функции =============================

    # Взять список доступных модификаторов из аргумента
    set(__AVAILABLE_MODIFIERS__ "${${__PARSING_PREFIX__}_AVAILABLE_MODIFIERS}")

    # Если задано значение по умолчанию
    if (DEFINED "${__PARSING_PREFIX__}_DEFAULT")

        # Взять значение по умолчанию из аргумента
        set(__DEFAULT__ "${${__PARSING_PREFIX__}_DEFAULT}")

        # Ищем элемент
        list(FIND ${__PARSING_PREFIX__}_AVAILABLE_MODIFIERS "${__DEFAULT__}" __INDEX__)

        if (__INDEX__ EQUAL -1)
            message(FATAL_ERROR "Модификатор '${__DEFAULT__}' отсутствует в списке "
                                "допустимых модификаторов (${__AVAILABLE_MODIFIERS__})")
        endif()

        # Значение по умолчанию
        set(__RESULT__ "${__DEFAULT__}")

    endif()

    # Проверить все доступные модификаторы
    foreach(__MODIFIER__ ${__AVAILABLE_MODIFIERS__})

        # Задать модификатор, если он был использован
        if (${${__PARSING_PREFIX__}_FUNCTION_PREFIX}_${__MODIFIER__})

            # Записать модификатор в выходную переменную
            set(__RESULT__ "${__MODIFIER__}")

            # Прекратить поиск
            break()

        endif()

    endforeach()

    # Взять имя выходной переменной из аргумента
    set(__OUT_VAR__ "${${__PARSING_PREFIX__}_OUT_VAR}")

    # Записать результат в выходную переменную
    set(${__OUT_VAR__} "${__RESULT__}")

    # Вернуть значение выходной переменной
    return(PROPAGATE ${__OUT_VAR__})

endfunction()

#[[
    ИСПОЛЬЗОВАНИЕ
        __check_targets_existence__(TARGETS <target>...
                                    [FATAL_ERROR | WARNING])

    АРГУМЕНТЫ
        TARGETS_NAMES           - имена таргетов для проверки
        FATAL_ERROR, WARNING    - (опционально) модификаторы проверки таргетов на существование (по умолчанию FATAL_ERROR)

    ОПИСАНИЕ
        Проверить существование таргета
#]]

function(__check_targets_existence__)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__TARGET_EXISTENCE_CHECKING_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__EXCLUSIVE_MODIFIERS__ "FATAL_ERROR" "WARNING")
    set(__MULTIPLE_VALUE_ARGS__ "TARGETS")

    # Парсить параметры
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__EXCLUSIVE_MODIFIERS__}"
                          ""
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить обязательные параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__MULTIPLE_VALUE_ARGS__}"
                         EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    #======================== Конец парсинга параметров функции =============================

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         DEFAULT "FATAL_ERROR"
                         OUT_VAR "__MODIFIER__")

    # Для найденных файлов с директориями
    foreach(__TARGET__ ${${__PARSING_PREFIX__}_TARGETS})

        # Проверить существование основного таргета
        if (NOT TARGET "${__TARGET__}")
            message(${__MODIFIER__} "Не существует таргета '${__TARGET__}'")
        endif()

    endforeach()

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
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    #======================== Конец парсинга параметров функции =============================

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         DEFAULT "WARNING"
                         OUT_VAR "__MODIFIER__")

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

