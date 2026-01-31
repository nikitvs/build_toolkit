include_guard()

# Функции cmake для разработки функций

#[[
    ИСПОЛЬЗОВАНИЕ
        __check_arguments__(PREFIX <prefix>
                            ARGS <arg>...
                            [OPTIONAL_ARGS <arg>...]
                            [INCOMPATIBLE_ARGS <arg>...])

    АРГУМЕНТЫ
        PREFIX              - префикс парсинга аргументов проверяемой функции
        ARGS                - список обязательных аргументов проверяемой функции
        OPTIONAL_ARGS       - (опционально) список опциональных аргументов проверяемой функции
        INCOMPATIBLE_ARGS   - (опционально) список взаимно исключающих аргументов проверяемой функции

    ОПИСАНИЕ
        Функция предназначена для проверки входных аргументов кастомных CMake функций
        Данная функция должна вызываться после парсинга аргументов проверяемой функции
#]]

function(__check_arguments__)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__FUNCTION_ARGS_CHECKING_PREFIX__")

    # Если это старт функции
    if(NOT DEFINED __SELF_CHECKING__)

        # Отметить начало этапа самопроверки
        set(__SELF_CHECKING__ True)

        # Парсить аргументы функции (для всех проверок одного раза достаточно)
        cmake_parse_arguments("${__PARSING_PREFIX__}"
                              ""
                              "PREFIX"
                              "ARGS;OPTIONAL_ARGS;INCOMPATIBLE_ARGS"
                              "${ARGN}")

        # Запустить самопроверку (одноуровневая рекурсия)
        __check_arguments__()

        # Отметить завершение этапа самопроверки
        set(__SELF_CHECKING__ False)

    endif()

    # В данный момент ИДЕТ самопроверка?
    if(${__SELF_CHECKING__})

        # Задать префикс вызывающей функции как префикс парсинга
        set(__FUNCTION_PREFIX__ "${__PARSING_PREFIX__}")

        # Задать обязательные аргументы для проверки
        set(__REQUIRED_ARGS__ "PREFIX")

        # Задать опциональные аргументы для проверки
        set(__OPTIONAL_ARGS__ "ARGS;OPTIONAL_ARGS;INCOMPATIBLE_ARGS")

    else()

        # Взять префикс вызывающей функции из значения аргумента
        set(__FUNCTION_PREFIX__ "${${__PARSING_PREFIX__}_PREFIX}")

        # Взять обязательные аргументы для проверки из значения аргумента
        set(__REQUIRED_ARGS__ "${${__PARSING_PREFIX__}_ARGS}")

        # Взять опциональные аргументы для проверки из значения аргумента
        set(__OPTIONAL_ARGS__ "${${__PARSING_PREFIX__}_OPTIONAL_ARGS}")

        # Для каждого возможного уникального флага
        foreach(__ARG__ ${${__PARSING_PREFIX__}_INCOMPATIBLE_ARGS})

            # Если флаг активен -> запомнить его
            if(${__FUNCTION_PREFIX__}_${__ARG__})
                list(APPEND __INC_ARGS_NAMES__ "${__ARG__}")
            endif()

        endforeach()

        # Посчитать количество активных флагов
        list(LENGTH __INC_ARGS_NAMES__ __ACTIVE_INC_ARGS_COUNT__)

        # Проверить, что активно не более одного флага
        if(${__ACTIVE_INC_ARGS_COUNT__} GREATER 1)
            message(FATAL_ERROR "Следующие аргументы не могут быть использованны одновременно: ${__INC_ARGS_NAMES__}")
        endif()

    endif()

    # Для каждого аргумента (обязательного и опционального)
    foreach(__ARG__ ${__REQUIRED_ARGS__} ${__OPTIONAL_ARGS__})

        # Проверить, что для аргумента задано значение
        list(FIND "${__FUNCTION_PREFIX__}_KEYWORDS_MISSING_VALUES" ${__ARG__} __ARG_INDEX__)
        if(NOT ${__ARG_INDEX__} EQUAL -1)
            message(FATAL_ERROR "У аргумента '${__ARG__}' должно быть задано значение")
        endif()

    endforeach()

    # Для каждого обязательного аргумента
    foreach(__ARG__ ${__REQUIRED_ARGS__})

        # Проверить, что аргумент определен
        if(NOT DEFINED "${__FUNCTION_PREFIX__}_${__ARG__}")
            message(FATAL_ERROR "Аргумент '${__ARG__}' должен быть определен")
        endif()

    endforeach()

    # Проверить наличие лишних аргументов
    if(DEFINED "${__FUNCTION_PREFIX__}_UNPARSED_ARGUMENTS")
        message(FATAL_ERROR "Присутствуют лишние аргументы: ${${__FUNCTION_PREFIX__}_UNPARSED_ARGUMENTS}")
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

    # Задать конфигурацию аргументов парсинга
    set(__MULTIPLE_VALUE_ARGS__ "DIRS")

    # Парсить аргументы функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          ""
                          ""
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__MULTIPLE_VALUE_ARGS__}")

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
        __extract_arg_value__(ARG <name>
                              OUT_VAR <outputVariable>
                              [FUNCTION_PREFIX <prefix>]
                              [DEFAULT <value>])

    АРГУМЕНТЫ
        ARG                 - имя аргумента функции для извлечения значения
        OUT_VAR             - имя переменной, куда запишется результат
        FUNCTION_PREFIX     - (опционально) префикс функции, для которой вызвано извлечение модификатора
        DEFAULT             - (опционально) модификатор по умолчанию

    ОПИСАНИЕ
        Извлечь значение аргумента и записать его в выходную переменную
        Если аргумент не задан, то записать значение по умолчанию
        Если значение по умалчанию не задано, то выходная переменная не инициализируется
#]]

function(__extract_arg_value__)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__ARG_VALUE_EXTRACTION_PREFIX__")

    # Задать конфигурацию аргументов парсинга
    set(__ONE_VALUE_ARGS__ "ARG" "OUT_VAR")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "FUNCTION_PREFIX")
    set(__OPTIONAL_MULTIPLE_VALUE_ARGS__ "DEFAULT")

    # Парсить аргументы
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          ""
                          "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}"
                          "${__OPTIONAL_MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}"
                        OPTIONAL_ARGS "${__OPTIONAL_MULTIPLE_VALUE_ARGS__}" "${__OPTIONAL_ONE_VALUE_ARGS__}")

    if (DEFINED "${__PARSING_PREFIX__}_FUNCTION_PREFIX")

        set(__FULL_PREFIX__ "${${__PARSING_PREFIX__}_FUNCTION_PREFIX}_")

    endif()

    # Если задано значение по умолчанию
    if (DEFINED "${__PARSING_PREFIX__}_DEFAULT")

        # Взять значение по умолчанию из аргумента
        set(__RESULT__ "${${__PARSING_PREFIX__}_DEFAULT}")

    endif()

    # Собрать имя аргумента функции
    set(__ARG__ "${__FULL_PREFIX__}${${__PARSING_PREFIX__}_ARG}")

    # Проверить использование аргумента
    if (DEFINED "${__ARG__}")

        # Взять значение из аргумента
        set(__RESULT__ "${${__ARG__}}")

    endif()

    # Если есть результат
    if (DEFINED "__RESULT__")

        # Взять имя выходной переменной из аргумента
        set(__OUT_VAR__ "${${__PARSING_PREFIX__}_OUT_VAR}")

        # Записать результат в выходную переменную
        set(${__OUT_VAR__} "${__RESULT__}")

        # Вернуть значение выходной переменной
        return(PROPAGATE ${__OUT_VAR__})

    endif()

endfunction()

#[[
    ИСПОЛЬЗОВАНИЕ
        __extract_modifier__(FUNCTION_PREFIX <prefix>
                             AVAILABLE_MODIFIERS <modifier>...
                             OUT_VAR <outputVariable>
                             [DEFAULT <modifier>])

    АРГУМЕНТЫ
        FUNCTION_PREFIX     - префикс функции, для которой вызвано извлечение модификатора
        AVAILABLE_MODIFIERS - допустимые модификаторы
        OUT_VAR             - имя переменной, куда запишется результат
        DEFAULT             - (опционально) модификатор по умолчанию

    ОПИСАНИЕ
        Извлечь использованный при вызове фукции модификатор и записать его в выходную переменную
        Если модификатор не выбран, то записать значение по умолчанию
        Если значение по умалчанию не задано, то выходная переменная не инициализируется
#]]

function(__extract_modifier__)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__MODIFIER_EXTRACTION_PREFIX__")

    # Задать конфигурацию аргументов парсинга
    set(__ONE_VALUE_ARGS__ "FUNCTION_PREFIX" "OUT_VAR")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "DEFAULT")
    set(__MULTIPLE_VALUE_ARGS__ "AVAILABLE_MODIFIERS")

    # Парсить аргументы
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          ""
                          "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")


    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                        OPTIONAL_ARGS "${__OPTIONAL_ONE_VALUE_ARGS__}")

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

    # Записать результат (если есть) в выходную переменную
    __extract_arg_value__(ARG "__RESULT__" OUT_VAR "${__OUT_VAR__}")

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

    # Задать конфигурацию аргументов парсинга
    set(__INCOMPATIBLE_MODIFIERS__ "FATAL_ERROR" "WARNING")
    set(__MULTIPLE_VALUE_ARGS__ "TARGETS")

    # Парсить аргументы
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__INCOMPATIBLE_MODIFIERS__}"
                          ""
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__MULTIPLE_VALUE_ARGS__}"
                        INCOMPATIBLE_ARGS "${__INCOMPATIBLE_MODIFIERS__}")

    # Извлечь использованный модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__INCOMPATIBLE_MODIFIERS__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "FATAL_ERROR")

    # Для найденных файлов с директориями
    foreach(__TARGET__ ${${__PARSING_PREFIX__}_TARGETS})

        # Проверить существование основного таргета
        if (NOT TARGET "${__TARGET__}")
            message(${__MODIFIER__} "Не существует таргета '${__TARGET__}'")
        endif()

    endforeach()

endfunction()
