include_guard()

# Подключить служебный модуль
include(${CMAKE_CURRENT_LIST_DIR}/../service/service.cmake)

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
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}"
                        OPTIONAL_ARGS "${__OPTIONAL_ONE_VALUE_ARGS__}")

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

    # Задать путь сборки модуля
    __extract_arg_value__(ARG "MODULE_DESTINATION_PATH"
                          OUT_VAR "__MODULE_BINARY_DIR__"
                          FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                          DEFAULT "${CMAKE_BINARY_DIR}/${__REL_PATH_TO_MODULE__}")

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
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                        OPTIONAL_ARGS "${__OPTIONAL_ONE_VALUE_ARGS__}"
                        EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование основного таргета
    __check_targets_existence__(TARGETS "${__TARGET__}")

    # Подключить модуль
    if (DEFINED "${__PARSING_PREFIX__}_MODULE_DESTINATION_PATH")

        add_module(MODULE_PATH "${${__PARSING_PREFIX__}_MODULE_PATH}"
                   MODULE_DESTINATION_PATH "${${__PARSING_PREFIX__}_MODULE_DESTINATION_PATH}")

    else()

        add_module(MODULE_PATH "${${__PARSING_PREFIX__}_MODULE_PATH}")

    endif()

    # Извлечь модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "PUBLIC")

    __check_targets_existence__(TARGETS "${${__PARSING_PREFIX__}_MODULE_LIBS}")

    # Подключить модули
    foreach(__LIB__ ${${__PARSING_PREFIX__}_MODULE_LIBS})

        # Пропускать подключение таргета самого к себе
        if ("${__TARGET__}" STREQUAL "${__LIB__}")
            continue()
        endif()

        # Подключить библиотеку
        target_link_libraries("${__TARGET__}" ${__MODIFIER__} "${__LIB__}")

    endforeach()

endfunction()

#[[
    ИСПОЛЬЗОВАНИЕ
        link_qt_libraries(TARGET <target>
                          QT_LIBS <lib>...
                          [VERSION <version>]
                          [PUBLIC | PRIVATE | INTERFACE])

    АРГУМЕНТЫ
        TARGET                      - целевой таргет
        QT_LIBS                     - список библиотек Qt
        VERSION                     - (опционально) версия пакета Qt
        PUBLIC, PRIVATE, INTERFACE  - (опционально) модификаторы доступа

    ОПИСАНИЕ
        Найти и подключить к целевому таргету указанные библиотеки Qt
        Опционально можно указать версию пакета Qt, из которого будут браться библиотеки
        По умолчанию берется наибольшая версия из доступных
        Также опционально можно указать модификатор видимости для внешних таргетов
        По умолчанию берется модификатор PUBLIC
#]]

function(link_qt_libraries)

    # TODO проверить, что поиск пакетов внутри функции работает нормально
    # TODO потом перенести в общий .cmake файл
    # Найти пакеты Qt
    find_package(QT NAMES Qt6 Qt5 REQUIRED)

    # Запомнить глобально версию Qt
    set(QT_VERSION_MAJOR "${QT_VERSION_MAJOR}" CACHE STRING "Максимальная версия Qt")

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__QT_LIBS_LINKING_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__EXCLUSIVE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__MULTIPLE_VALUE_ARGS__ "QT_LIBS")
    set(__OPTIONAL_ONE_VALUE_ARGS__ "VERSION")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}"
                          "${__EXCLUSIVE_MODIFIERS__}"
                          "${__ONE_VALUE_ARGS__};${__OPTIONAL_ONE_VALUE_ARGS__}"
                          "${__MULTIPLE_VALUE_ARGS__}"
                          "${ARGN}")

    # Проверить параметры функции
    __check_arguments__(PREFIX "${__PARSING_PREFIX__}"
                        ARGS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                        OPTIONAL_ARGS "${__OPTIONAL_ONE_VALUE_ARGS__}"
                        EXCLUSIVE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование таргета
    if (NOT TARGET "${__TARGET__}")
        message(FATAL_ERROR "Не существует таргета: ${__TARGET__}")
    endif()

    # Задать наибольшую версию Qt
    __extract_arg_value__(ARG "VERSION"
                          OUT_VAR "__VERSION__"
                          FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                          DEFAULT "${QT_VERSION_MAJOR}")

    # Извлечь модификатор
    __extract_modifier__(FUNCTION_PREFIX "${__PARSING_PREFIX__}"
                         AVAILABLE_MODIFIERS "${__EXCLUSIVE_MODIFIERS__}"
                         OUT_VAR "__MODIFIER__"
                         DEFAULT "PUBLIC")

    # Найти библиотеки Qt
    find_package("Qt${__VERSION__}" COMPONENTS "${${__PARSING_PREFIX__}_QT_LIBS}" REQUIRED)

    # Включить MOC для таргета
    # NOTE атрибуты наследуются хреново, поэтому следует вызывать текущую функцию (хотя бы для подключения Core)
    # для всех таргетов, наследующих таргетам, использующим Qt
    set_target_properties("${__TARGET__}" PROPERTIES
                          AUTOUIC ON
                          AUTOMOC ON
                          AUTORCC ON
    )

    # Подключить библиотеки Qt
    foreach(__LIB__ ${${__PARSING_PREFIX__}_QT_LIBS})
        target_link_libraries("${__TARGET__}" ${__MODIFIER__} "Qt${__VERSION__}::${__LIB__}")
    endforeach()

    # Подключить дополнительных функций Qt
    link_module_libraries(
        ${__MODIFIER__}
        TARGET "${__TARGET__}"
        MODULE_PATH "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/cpp_tools/lib_additional_qt"
        MODULE_LIBS "BuildToolkitAdditionalQt")

endfunction()
