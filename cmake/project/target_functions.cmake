cmake_minimum_required(VERSION 3.25)

# Функции для работы с исходниками проекта

# Подключить служебный модуль
include(__auxiliary)

#[====[.rst:

    **Описание**

    Функция назначает целевому таргету исходные файлы из выбранных директорий.
    Для выбранных директорий производится рекурсивный поиск исходных файлов c++ (.cpp и .h).
    По умолчанию берется директория файла, вызвшего функцию.
    Опционально можно указать регулярные выражения для исключения нежелательных файлов.
    По умолчанию всегда добавляется регулярное выражение для исключения build директории.

    В качестве аргументов должны быть переданы:
        - целевой таргет для назначения исходных файлов;
        - (опционально) список директорий с исходными файлами;
        - (опционально) список регулярных выражений для исключения нежелательных файлов.

    Функция проверяет свою сигнатуру.

    **Функция**::

     assign_sources_to_target(TARGET <target>
                              [SOURCE_DIRECTORIES <dir1> <dir2> ...]
                              [EXCLUSIVE_REGEXP <regexp1> <regexp2> ...])

    **Аргументы**

    -             ``TARGET`` - Целевой таргет
    - ``SOURCE_DIRECTORIES`` - (опционально) Список директорий поиска исходных файлов
    -   ``EXCLUSIVE_REGEXP`` - (опционально) Список регулярных выражений для исключения файлов

#]====]

function(assign_sources_to_target)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__SOURCES_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__OPTIONAL_MULTIPLE_VALUE_ARGS__ "SOURCE_DIRECTORIES" "EXCLUSIVE_REGEXP")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}" "" "${__ONE_VALUE_ARGS__}" "${__OPTIONAL_MULTIPLE_VALUE_ARGS__}" "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}" PARAMETERS "${__ONE_VALUE_ARGS__}" OPTIONAL_PARAMETERS "${__OPTIONAL_MULTIPLE_VALUE_ARGS__}")

    # Взять целевой таргет из аргумента
    set(__TARGET__ "${${__PARSING_PREFIX__}_TARGET}")

    # Проверить существование таргета
    if (NOT TARGET "${__TARGET__}")
        message(FATAL_ERROR "Не существует таргета: ${__TARGET__}")
    endif()

    # Если задан список директорий
    if(DEFINED "${__PARSING_PREFIX__}_SOURCE_DIRECTORIES")

        # Взять список директорий из аргумента
        set(__SEARCH_DIRECTORIES__ "${${__PARSING_PREFIX__}_SOURCE_DIRECTORIES}")

    else()

        # Задать директорию вызова функции как диреторию поиска
        set(__SEARCH_DIRECTORIES__ "${CMAKE_CURRENT_LIST_DIR}")

    endif()

    # Проверить что директории поиска существуют
    __check_directories_existence__(DIRS "${__SEARCH_DIRECTORIES__}")

    # Для всех директорий поиска
    foreach(__DIR__ ${__SEARCH_DIRECTORIES__})

        # Взять абсолютный путь к директории
        get_filename_component(__PATH_TO_DIR__ "${__DIR__}" ABSOLUTE)

        # Найти исходники
        file(GLOB_RECURSE __SEARCH_RESULT__
            "${__PATH_TO_DIR__}/*.cpp"
            "${__PATH_TO_DIR__}/*.h")

        # Добавить результат поиска к общему списку
        list(APPEND __SOURCES__ "${__SEARCH_RESULT__}")

    endforeach()

    # Всегда добавлять выражение для отсева директории сборки
    set(__DEFAULT_REGULAR_EXPRESSIONS__ ".*build.*/")

    # Для каждого регулярного выражения
    foreach(__REGEXP__ ${${__PARSING_PREFIX__}_EXCLUSIVE_REGEXP} ${__DEFAULT_REGULAR_EXPRESSIONS__})

        # Отсеять нежелательные файлы
        list(FILTER __SOURCES__ EXCLUDE REGEX "${__REGEXP__}")

    endforeach()

    # Задать исходники таргету
    target_sources("${${__PARSING_PREFIX__}_TARGET}" PRIVATE "${__SOURCES__}")

endfunction()

#[====[.rst:

    **Описание**

    Функция назначает целевому таргету выбранные директории со всеми поддиректориями.
    Опционально можно указать модификатор видимости для внешних таргетов.
    По умолчанию берется модификатор PUBLIC.

    В качестве аргументов должны быть переданы:
        - целевой таргет для назначения исходных файлов;
        - список назначаемых директорий;
        - (опционально) модификатор видимости для внешних таргетов.

    Функция проверяет свою сигнатуру.

    **Функция**::

     assign_include_dirs_to_target(TARGET <target>
                                   INCLUDE_DIRS <dir1> <dir2> ...
                                   [PUBLIC | PRIVATE | INTERFACE])

    **Аргументы**

    -                       ``TARGET`` - Целевой таргет
    -                 ``INCLUDE_DIRS`` - Список директорий для назначения
    - ``PUBLIC | PRIVATE | INTERFACE`` - (опционально) Модификатор доступа

#]====]

function(assign_include_dirs_to_target)

    # Задать префикс парсинга
    set(__PARSING_PREFIX__ "__INCLUDE_DIRS_ASSIGNMENT_PREFIX__")

    # Задать конфигурацию параметров парсинга
    set(__EXCLUSIVE_MODIFIERS__ "PUBLIC" "PRIVATE" "INTERFACE")
    set(__ONE_VALUE_ARGS__ "TARGET")
    set(__MULTIPLE_VALUE_ARGS__ "INCLUDE_DIRS")

    # Парсить параметры функции
    cmake_parse_arguments("${__PARSING_PREFIX__}" "${__EXCLUSIVE_MODIFIERS__}" "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}" "${ARGN}")

    # Проверить параметры функции
    __check_parameters__(PREFIX "${__PARSING_PREFIX__}" PARAMETERS "${__ONE_VALUE_ARGS__}" "${__MULTIPLE_VALUE_ARGS__}" EXCLUSIVE_FLAGS "${__EXCLUSIVE_MODIFIERS__}")

    # Задать текущий модификатор в зависимости параметров
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
