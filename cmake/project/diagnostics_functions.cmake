include_guard()

# Подключить служебный модуль
include(${CMAKE_CURRENT_LIST_DIR}/../service/service.cmake)

#[[
ИСПОЛЬЗОВАНИЕ
    use_sanitizers(TARGET <target>)

АРГУМЕНТЫ
    TARGET  - целевой таргет

ОПИСАНИЕ
    Включить для таргета санитайзеры (ASan, UbSan)
    Для игнорирования утечек библиотек следует создать файл <suppressions_file.txt>,
    а также задать переменную окружения для запуска: LSAN_OPTIONS=suppressions=<path>/<suppressions_file.txt>
#]]

function(use_sanitizers)

    # Задать префикс парсинга
    set(__EXCLUSIVE_MODIFIERS__ "PUBLIC" "PRIVATE")
    set(__PARSING_PREFIX__ "__SANITIZERS_USING__")

    # Задать конфигурацию аргументов парсинга
    set(__ONE_VALUE_ARGS__ "TARGET")

    # Парсить аргументы функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__EXCLUSIVE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__}"
                          ""
                          "${ARGN}")

    # Проверить аргументы функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование целевого таргета
    __check_targets_existence__(TARGETS "${__TARGET__}")

    if(CMAKE_CXX_COMPILER_ID MATCHES "GNU")

        set(__SANITIZE_COMPILE_OPTIONS__ "-fsanitize=address,undefined" "-ggdb3" "-fno-omit-frame-pointer")
        set(__SANITIZE_LINK_OPTIONS__ "-fsanitize=address,undefined")

    elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")

        set(__SANITIZE_COMPILE_OPTIONS__ "-fsanitize=address,undefined" "-g" "-O1" "-fno-omit-frame-pointer")
        set(__SANITIZE_LINK_OPTIONS__ "-g" "-fsanitize=address,undefined")

    else()

        message(WARNING "Неизвестный тип компилятора! Опции компиляции не заданы")
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
