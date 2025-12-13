# Фильровать многочисленные включения
include_guard()

# Подключить служебный модуль
include(__auxiliary)

# Подключить модуль работы с библиотеками
include(${CMAKE_CURRENT_LIST_DIR}/libs_settings.cmake)

# Найти пакеты Qt
find_package(QT NAMES Qt6 Qt5 REQUIRED)

# Запомнить глобально версию Qt
set(QT_VERSION_MAJOR "${QT_VERSION_MAJOR}" CACHE STRING "Максимальная версия Qt")

#[[
    **Описание**

    Найти и подключить к целевому таргету указанные библиотеки Qt
    Опционально можно указать версию пакета Qt, из которого будут браться библиотеки
    По умолчанию берется наибольшая возможная версия
    Также опционально можно указать модификатор видимости для внешних таргетов
    По умолчанию берется модификатор PUBLIC

    В качестве аргументов должны быть переданы:
        - целевой таргет для подключения библиотек;
        - список подключаемых библиотек;
        - (опционально) требуемая версия пакета Qt;
        - (опционально) модификатор видимости для внешних таргетов.

    Функция проверяет свою сигнатуру

    **Функция**::

     link_qt_libraries(TARGET <target>
                       QT_LIBS <lib1> <lib2> ...
                       [VERSION <version>]
                       [PUBLIC | PRIVATE | INTERFACE])

    **Аргументы**

    -                       ``TARGET`` - Целевой таргет
    -                      ``QT_LIBS`` - Список библиотек Qt
    -                      ``VERSION`` - (опционально) версия пакета Qt
    - ``PUBLIC | PRIVATE | INTERFACE`` - (опционально) Модификатор доступа
#]]

function(link_qt_libraries)

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
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}"
                         PARAMETERS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}"
                         OPTIONAL_PARAMETERS "${__OPTIONAL_ONE_VALUE_ARGS__}"
                         EXCLUSIVE_FLAGS "${__EXCLUSIVE_MODIFIERS__}")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование таргета
    if (NOT TARGET "${__TARGET__}")
        message(FATAL_ERROR "Не существует таргета: ${__TARGET__}")
    endif()

    # Если задана версия
    if(DEFINED "${__PARSING_PREFIX__}_VERSION")
        # Взять версию из аргумента
        set(__VERSION__ "${${__PARSING_PREFIX__}_VERSION}")
    else()
        # Задать наибольшую возможную версию
        set(__VERSION__ "${QT_VERSION_MAJOR}")
    endif()

    # Задать текущий модификатор в зависимости аргументов
    if (${__PARSING_PREFIX__}_PUBLIC)
        set(__MODIFIER__ "PUBLIC")
    elseif (${__PARSING_PREFIX__}_PRIVATE)
        set(__MODIFIER__ "PRIVATE")
    elseif (${__PARSING_PREFIX__}_INTERFACE)
        set(__MODIFIER__ "INTERFACE")
    else()
        # Значение по умолчанию
        set(__MODIFIER__ "PUBLIC")
    endif()

    # Найти библиотеки Qt
    find_package("Qt${__VERSION__}" COMPONENTS "${${__PARSING_PREFIX__}_QT_LIBS}" REQUIRED)

    # Включить MOC для таргета
    # NOTE атрибуты наследуются хреново, поэтому следует вызывать текущую функцию (хотя бы для подключения Core)
    # для всех таргетов, наследующих таргетам, использующим Qt
    set_target_properties("${${__PARSING_PREFIX__}_TARGET_NAME}" PROPERTIES
                          AUTOUIC ON
                          AUTOMOC ON
                          AUTORCC ON
    )

    # Подключить библиотеки Qt
    foreach(__LIB__ ${${__PARSING_PREFIX__}_QT_LIBS})
        target_link_libraries("${${__PARSING_PREFIX__}_TARGET}" ${__MODIFIER__} "Qt${__VERSION__}::${__LIB__}")
    endforeach()

    # Подключить дополнительных функций Qt
    link_modules(
        ${__MODIFIER__}
        TARGET_NAME "${${__PARSING_PREFIX__}_TARGET_NAME}"
        MODULE_PATH "${__ABS_PATH_TO_LIBS_SETTINGS__}/cpp_tools/lib_additional_qt"
        MODULE_TARGETS "LibAdditionalQt"
    )

endfunction()
