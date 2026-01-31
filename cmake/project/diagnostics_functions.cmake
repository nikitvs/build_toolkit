include_guard()

# Подключить служебный модуль
include(${CMAKE_CURRENT_LIST_DIR}/../service/service.cmake)

#[[
ИСПОЛЬЗОВАНИЕ
    use_diagnostics(TARGET <target>
                    [PUBLIC | PRIVATE]
                    [NO_SANITIZERS])

АРГУМЕНТЫ
    TARGET          - целевой таргет
    PUBLIC, PRIVATE - (опционально) модификаторы распространения опций компиляции на внешние таргеты
    NO_SANITIZERS   - (опционально) флаг отмены включения санитайзеров

ОПИСАНИЕ
    Включить для таргета дополнительные опции компиляции с проверками и санитайзеры (ASan, UbSan)
    Для игнорирования утечек библиотек следует создать файл <suppressions_file.txt>,
    а также задать переменную окружения для запуска: LSAN_OPTIONS=suppressions=<path>/<suppressions_file.txt>
#]]

function(use_diagnostics)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__DIAGNOSTICS_USING__")

    # Задать конфигурацию аргументов парсинга
    set(__OPTIONS__ "NO_SANITIZERS")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__EXCLUSIVE_MODIFIERS__ "PUBLIC" "PRIVATE")

    # Парсить аргументы функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__OPTIONS__};${__EXCLUSIVE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__}"
                          ""
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}"
                        EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование целевого таргета
    __check_targets_existence__(TARGETS "${__TARGET__}")

    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")

        # Включить основные предупреждения
        list(APPEND __SANITIZE_COMPILE_OPTIONS__ "-Wall" "-Wpedantic" "-Wextra")

        # Включить дополнительные предупреждения
        list(APPEND __SANITIZE_COMPILE_OPTIONS__ "-Wcast-align" "-Wcast-qual" "-Wctor-dtor-privacy" "-Wduplicated-branches" "-Wredundant-decls"
                                                 "-Wduplicated-cond" "-Wextra-semi" "-Wfloat-equal" "-Wconversion" "-Wlogical-op"
                                                 "-Wnon-virtual-dtor" "-Wsign-conversion" "-Wsign-promo" "-Wzero-as-null-pointer-constant")

        # Включить санитайзеры
        if(NOT ${__PARSING_PREFIX__}_NO_SANITIZERS)

            # Санитайзеры GCC не работают на Windows :(
            if(NOT WIN32)
                list(APPEND __SANITIZE_COMPILE_OPTIONS__ "-fsanitize=address,undefined" "-ggdb3" "-fno-omit-frame-pointer")
                list(APPEND __SANITIZE_LINK_OPTIONS__ "-fsanitize=address,undefined")
            endif()

        endif()

    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")

        # Включить основные предупреждения
        list(APPEND __SANITIZE_COMPILE_OPTIONS__ "-Wall" "-Wpedantic" "-Wextra")

        # Включить дополнительные предупреждения
        list(APPEND __SANITIZE_COMPILE_OPTIONS__ "-Wcast-align" "-Wcast-qual" "-Wctor-dtor-privacy" "-Wredundant-decls"
                                                 "-Wextra-semi" "-Wfloat-equal" "-Wconversion" "-Wnon-virtual-dtor"
                                                 "-Wsign-conversion" "-Wsign-promo" "-Wzero-as-null-pointer-constant"
                                                 "-Wabstract-vbase-init" "-Walloca" "-Warc-maybe-repeated-use-of-weak"
                                                 "-Warc-repeated-use-of-weak" "-Warray-bounds-pointer-arithmetic"
                                                 "-Warray-parameter" "-Wassign-enum" "-Wlong-long" "-Wbad-function-cast"
                                                 "-Wbitfield-width" "-Wbitwise-instead-of-logical" "-Wc++11-extensions"
                                                 "-Wgnu")

        # Включить санитайзеры
        if(NOT ${__PARSING_PREFIX__}_NO_SANITIZERS)

            list(APPEND __SANITIZE_COMPILE_OPTIONS__ "-fsanitize=address,undefined" "-g" "-O1" "-fno-omit-frame-pointer")
            list(APPEND __SANITIZE_LINK_OPTIONS__ "-g" "-fsanitize=address,undefined")

        endif()

    else()

        message(WARNING "Неизвестный тип компилятора! Санитайзеры не заданы")
        return()

    endif()

    # Извлечь модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "PRIVATE")

    target_compile_options("${__TARGET__}" ${__MODIFIER__} ${__SANITIZE_COMPILE_OPTIONS__})
    target_link_options("${__TARGET__}" ${__MODIFIER__} ${__SANITIZE_LINK_OPTIONS__})

endfunction()
