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
  find_package(cpplint)
endif(NOT CPPLINT_FOUND)

if(NOT CPPLINT_FOUND)
  add_custom_target(cpplint COMMENT "${CPPLINT_NOT_FOUND_MSG}")
  set_target_properties(cpplint PROPERTIES EXCLUDE_FROM_ALL TRUE)
endif(NOT CPPLINT_FOUND)

if(NOT TARGET cpplint)
  add_custom_target(cpplint)
endif()

function(add_cpplint _name)
  set(oneValueArgs VERBOSE COUNTING ROOT LINELENGTH EXCLUDE_PATTERN)
  set(multiValueArgs CATEGORY_FILTER_OUT EXTENSIONS)
  cmake_parse_arguments(add_cpplint "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  if(NOT TARGET ${_name})
    message(FATAL_ERROR
      "add_cpplint is given a target name that does not exist: '${_name}' !")
  endif()
  if(CPPLINT_FOUND)
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
    endif(add_cpplint_EXTENSIONS)

    # handles verbosity level ([0-5])
    if (add_cpplint_VERBOSE)
      list(APPEND _cpplint_args "--verbose=${add_cpplint_VERBOSE}")
    endif(add_cpplint_VERBOSE)

    # handles counting level of detail (total|toplevel|detailed)
    if (add_cpplint_COUNTING)
      list(APPEND _cpplint_args "--counting=${add_cpplint_COUNTING}")
    endif(add_cpplint_COUNTING)

    # handles root directory used for deriving header guard CPP variable
    if(add_cpplint_ROOT)
      list(APPEND _cpplint_args "--root=${add_cpplint_ROOT}")
    endif(add_cpplint_ROOT)

    # handles line length
    if (add_cpplint_LINELENGTH)
      list(APPEND _cpplint_args "--linelength=${add_cpplint_LINELENGTH}")
    endif(add_cpplint_LINELENGTH)

    get_target_property(_cpplint_sources "${_name}" SOURCES)
    set(_files)
    #set(_exclude_pattern ".*moc_.*\\.cxx|Buildyard/Build")
    foreach(_source ${_cpplint_sources})
      get_source_file_property(_cpplint_lang "${_source}" LANGUAGE)
      get_source_file_property(_cpplint_loc "${_source}" LOCATION)
      if("${_cpplint_lang}" MATCHES "CXX" AND NOT ${_cpplint_loc} MATCHES ${add_cpplint_EXCLUDE_PATTERN})
        list(APPEND _files "${_cpplint_loc}")
      endif("${_cpplint_lang}" MATCHES "CXX" AND NOT ${_cpplint_loc} MATCHES ${add_cpplint_EXCLUDE_PATTERN})
    endforeach(_source ${_cpplint_sources})

    if(NOT _files) # nothing to check
      return()
    endif(NOT _files)

    if(CPPLINT_ADD_TESTS)
      add_test(NAME ${_name}_cpplint_test
        COMMAND "${CPPLINT_SCRIPT}" ${_files})
      set_tests_properties(${_name}_cpplint_test
        PROPERTIES PASS_REGULAR_EXPRESSION "Total errors found: 0")
    endif()

    add_custom_target(${_name}_cpplint
      COMMAND ${CPPLINT_SCRIPT} ${_cpplint_args} ${_files}
      WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
      COMMENT "Running cpplint on ${_name}"
      VERBATIM)
    add_dependencies(cpplint ${_name}_cpplint)
  endif()
endfunction(add_cpplint)
