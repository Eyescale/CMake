# - Run cpplint on c++ source files as a custom target and a test
#
#  include(CpplintTargets)
#  add_cpplint(TARGET target [CATEGORY_FILTER_OUT category ...]
#              [EXTENSIONS extension ...] [VERBOSE level]
#              [COUNTING level_of_detail] [ROOT subdir] [LINELENGTH digits])
#  Create a target to check a target's sources with cpplint and the indicated
#  options
#
# Input variables:
# * CPPLINT_ADD_TESTS: When set to ON, add cpplint targets to tests

if(TARGET ${PROJECT_NAME}-cpplint)
  return()
endif()

include(CMakeParseArguments)

if(NOT CPPLINT_FOUND)
  find_package(cpplint QUIET)
endif()

if(NOT CPPLINT_FOUND)
  add_custom_target(${PROJECT_NAME}-cpplint COMMENT "${CPPLINT_NOT_FOUND_MSG}")
  set_target_properties(${PROJECT_NAME}-cpplint PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests/cpplint)
endif(NOT CPPLINT_FOUND)

if(NOT TARGET cpplint)
  add_custom_target(cpplint)
  set_target_properties(cpplint PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON)
endif()

function(add_cpplint _name _files)
  if(NOT CPPLINT_FOUND)
    return()
  endif()

  set(oneValueArgs VERBOSE COUNTING ROOT LINELENGTH)
  set(multiValueArgs CATEGORY_FILTER_OUT EXTENSIONS)
  cmake_parse_arguments(add_cpplint "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  set(_cpplint_args)

  # handles category filters
  set(_category_filter)
  set(_category_filter_in "+build,+legal,+readability,+runtime,+whitespace")
  if (add_cpplint_CATEGORY_FILTER_OUT)
    string(REPLACE ";" ",-" add_cpplint_CATEGORY_FILTER_OUT "${add_cpplint_CATEGORY_FILTER_OUT}")
    set(_category_filter "--filter=${_category_filter_in},-${add_cpplint_CATEGORY_FILTER_OUT}")
  endif()
  list(APPEND _cpplint_args ${_category_filter})

  # handles allowed extensions
  if (add_cpplint_EXTENSIONS)
    string(REPLACE ";" "," add_cpplint_EXTENSIONS "${add_cpplint_EXTENSIONS}")
    set(add_cpplint_EXTENSIONS "--extensions=${add_cpplint_EXTENSIONS}")
    list(APPEND _cpplint_args ${add_cpplint_EXTENSIONS})
  endif()

  # handles verbosity level ([0-5])
  if (add_cpplint_VERBOSE)
    list(APPEND _cpplint_args "--verbose=${add_cpplint_VERBOSE}")
  endif()

  # handles counting level of detail (total|toplevel|detailed)
  if (add_cpplint_COUNTING)
    list(APPEND _cpplint_args "--counting=${add_cpplint_COUNTING}")
  endif()

  # handles root directory used for deriving header guard CPP variable
  if(add_cpplint_ROOT)
    list(APPEND _cpplint_args "--root=${add_cpplint_ROOT}")
  endif()

  # handles line length
  if (add_cpplint_LINELENGTH)
    list(APPEND _cpplint_args "--linelength=${add_cpplint_LINELENGTH}")
  endif()

  if(CPPLINT_ADD_TESTS)
    if(NOT TARGET ${PROJECT_NAME}-tests)
      add_custom_target(${PROJECT_NAME}-tests)
      set_target_properties(${PROJECT_NAME}-tests PROPERTIES
        EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)
    endif()
    add_dependencies(${PROJECT_NAME}-tests cpplint_run_${_name})
  endif()

  add_custom_target(cpplint_run_${_name}
    COMMAND ${CPPLINT_SCRIPT} ${_cpplint_args} ${_files}
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
  set_target_properties(cpplint_run_${_name} PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests/cpplint)

  if(NOT TARGET ${PROJECT_NAME}-cpplint)
    add_custom_target(${PROJECT_NAME}-cpplint)
    set_target_properties(${PROJECT_NAME}-cpplint PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests/cpplint)
  endif()
  add_dependencies(${PROJECT_NAME}-cpplint cpplint_run_${_name})
  add_dependencies(cpplint ${PROJECT_NAME}-cpplint)
endfunction()
