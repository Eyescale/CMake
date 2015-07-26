# - Run cpplint on c++ source files as a custom target and a test
#
#  include(CpplintTargets)
#  add_cpplint(TARGET target [CATEGORY_FILTER_OUT category ...]
#              [EXTENSIONS extension ...] [VERBOSE level]
#              [COUNTING level_of_detail] [ROOT subdir] [LINELENGTH digits]
#              [EXCLUDE_PATTERN pattern ...])
#  Create a target to check a target's sources with cpplint and the indicated
#  options
#
# Input variables:
# * CPPLINT_ADD_TESTS: When set to ON, add cpplint targets to tests

include(CMakeParseArguments)

if(__add_cpplint)
  return()
endif(__add_cpplint)

set(__add_cpplint YES)

if(NOT CPPLINT_FOUND)
  find_package(cpplint QUIET)
endif(NOT CPPLINT_FOUND)

if(NOT CPPLINT_FOUND)
  add_custom_target(cpplint_${PROJECT_NAME} COMMENT "${CPPLINT_NOT_FOUND_MSG}")
  set_target_properties(cpplint_${PROJECT_NAME} PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests/cpplint)
endif(NOT CPPLINT_FOUND)

if(NOT TARGET cpplint)
  add_custom_target(cpplint)
  set_target_properties(cpplint PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON)
endif()

function(add_cpplint _name)
  set(oneValueArgs VERBOSE COUNTING ROOT LINELENGTH EXCLUDE_PATTERN)
  set(multiValueArgs CATEGORY_FILTER_OUT EXTENSIONS)
  cmake_parse_arguments(add_cpplint "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  if(NOT TARGET ${_name})
    message(FATAL_ERROR
      "add_cpplint is given a target name that does not exist: '${_name}' !")
  endif()
  if(NOT CPPLINT_FOUND)
    return()
  endif( )

  set(_cpplint_args)

  # handles category filters
  set(_category_filter)
  set(_category_filter_in "+build,+legal,+readability,+runtime,+whitespace")
  if (add_cpplint_CATEGORY_FILTER_OUT)
    string(REPLACE ";" ",-" add_cpplint_CATEGORY_FILTER_OUT "${add_cpplint_CATEGORY_FILTER_OUT}")
    set(_category_filter "--filter=${_category_filter_in},-${add_cpplint_CATEGORY_FILTER_OUT}")
  endif(add_cpplint_CATEGORY_FILTER_OUT)
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

  get_target_property(_imported_target "${_name}" IMPORTED)
  if(_imported_target)
    return()
  endif()

  get_target_property(_cpplint_sources "${_name}" SOURCES)
  set(_files)
  #set(_exclude_pattern ".*moc_.*\\.cxx|Buildyard/Build")
  foreach(_source ${_cpplint_sources})
    get_source_file_property(_cpplint_lang "${_source}" LANGUAGE)
    get_source_file_property(_cpplint_loc "${_source}" LOCATION)
    if("${_cpplint_lang}" MATCHES "CXX" AND NOT ${_cpplint_loc} MATCHES ${add_cpplint_EXCLUDE_PATTERN})
      list(APPEND _files "${_cpplint_loc}")
    endif()
  endforeach()

  if(NOT _files) # nothing to check
    return()
  endif(NOT _files)

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

  if(NOT TARGET cpplint_${PROJECT_NAME})
    add_custom_target(cpplint_${PROJECT_NAME})
    set_target_properties(cpplint_${PROJECT_NAME} PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests/cpplint)
  endif()
  add_dependencies(cpplint_${PROJECT_NAME} cpplint_run_${_name})
  add_dependencies(cpplint cpplint_${PROJECT_NAME})
endfunction(add_cpplint)
