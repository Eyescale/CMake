# - Run cpplint on c++ source files as a custom target and a test
#
#  include(CpplintTargets)
#  common_cpplint(<target-name> [FILES files] [CATEGORY_FILTER_OUT category ...]
#                 [EXTENSIONS extension ...] [VERBOSE level]
#                 [COUNTING level_of_detail] [ROOT subdir] [LINELENGTH digits]
#                 [EXCLUDE_PATTERN pattern ...])
#  Create a target to check a target's sources with cpplint and the indicated
#  options
#
# Input variables:
# * CPPLINT_ADD_TESTS: When set to ON, add cpplint targets to tests

if(TARGET ${PROJECT_NAME}-cpplint)
  return()
endif()

include(CMakeParseArguments)
include(GetSourceFilesFromTarget)

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

function(common_cpplint _name)
  if(NOT CPPLINT_FOUND)
    return()
  endif()

  set(oneValueArgs VERBOSE COUNTING ROOT LINELENGTH EXCLUDE_PATTERN)
  set(multiValueArgs FILES CATEGORY_FILTER_OUT EXTENSIONS)
  cmake_parse_arguments(common_cpplint "${options}" "${oneValueArgs}"
    "${multiValueArgs}" ${ARGN})
  if(NOT TARGET ${_name})
    message(FATAL_ERROR
      "common_cpplint is given a target name that does not exist: '${_name}' !")
  endif()

  set(_cpplint_args)

  # handles category filters
  set(_category_filter)
  set(_category_filter_in "+build,+legal,+readability,+runtime,+whitespace")
  if (common_cpplint_CATEGORY_FILTER_OUT)
    string(REPLACE ";" ",-" common_cpplint_CATEGORY_FILTER_OUT "${common_cpplint_CATEGORY_FILTER_OUT}")
    set(_category_filter "--filter=${_category_filter_in},-${common_cpplint_CATEGORY_FILTER_OUT}")
  endif()
  list(APPEND _cpplint_args ${_category_filter})

  # handles allowed extensions
  if (common_cpplint_EXTENSIONS)
    string(REPLACE ";" "," common_cpplint_EXTENSIONS "${common_cpplint_EXTENSIONS}")
    set(common_cpplint_EXTENSIONS "--extensions=${common_cpplint_EXTENSIONS}")
    list(APPEND _cpplint_args ${common_cpplint_EXTENSIONS})
  endif()

  # handles verbosity level ([0-5])
  if (common_cpplint_VERBOSE)
    list(APPEND _cpplint_args "--verbose=${common_cpplint_VERBOSE}")
  endif()

  # handles counting level of detail (total|toplevel|detailed)
  if (common_cpplint_COUNTING)
    list(APPEND _cpplint_args "--counting=${common_cpplint_COUNTING}")
  endif()

  # handles root directory used for deriving header guard CPP variable
  if(common_cpplint_ROOT)
    list(APPEND _cpplint_args "--root=${common_cpplint_ROOT}")
  endif()

  # handles line length
  if (common_cpplint_LINELENGTH)
    list(APPEND _cpplint_args "--linelength=${common_cpplint_LINELENGTH}")
  endif()

  set(_files ${common_cpplint_FILES})
  if(NOT _files)
    # handles exclude pattern
    if(NOT common_cpplint_EXCLUDE_PATTERN)
      set(common_cpplint_EXCLUDE_PATTERN "^$") # Empty string regex
    endif()

    get_source_files(${_name} ${common_cpplint_EXCLUDE_PATTERN})
    if(NOT ${_name}_FILES) # nothing to check
      return()
    endif()
    set(_files ${${_name}_FILES})
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
