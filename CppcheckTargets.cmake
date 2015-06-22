# - Run cppcheck on c++ source files as a custom target and a test
#
#  include(CppcheckTargets)
#  add_cppcheck(<target-name> [UNUSED_FUNCTIONS] [STYLE] [POSSIBLE_ERROR]
#                             [FAIL_ON_WARNINGS] [EXCLUDE_QT_MOC_FILES]) -
#    Create a target to check a target's sources with cppcheck and the
#    indicated options
#
# Requires these CMake modules:
#  Findcppcheck
#
# Accepts the following input variables:
# * CPPCHECK_EXTRA_ARGS for additional command line parameters to cppcheck
#
# Original Author:
# 2009-2010 Ryan Pavlik <rpavlik@iastate.edu> <abiryan@ryand.net>
# http://academic.cleardefinition.com
# Iowa State University HCI Graduate Program/VRAC
#
# Copyright Iowa State University 2009-2010.
# Distributed under the Boost Software License, Version 1.0.
# (See accompanying file LICENSE_1_0.txt or copy at
# http://www.boost.org/LICENSE_1_0.txt)

if(__add_cppcheck)
  return()
endif()
set(__add_cppcheck YES)

if(NOT CPPCHECK_FOUND)
  find_package(cppcheck 1.61 QUIET)
endif()

if(NOT CPPCHECK_FOUND)
  add_custom_target(cppcheck_${PROJECT_NAME}
    COMMENT "cppcheck executable not found")
  set_target_properties(cppcheck_${PROJECT_NAME} PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER "Tests/${PROJECT_NAME}/cppcheck")
endif()

if(NOT TARGET cppcheck)
  add_custom_target(cppcheck)
  set_target_properties(cppcheck PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER "Tests")
endif()

function(add_cppcheck _name)
  if(NOT TARGET ${_name})
    message(FATAL_ERROR
      "add_cppcheck given a target name that does not exist: '${_name}' !")
  endif()
  if(NOT CPPCHECK_FOUND)
    return()
  endif()

  if (CPPCHECK_IGNORED_PATHS)
    string(REPLACE " " " -i" _ignored_paths ${CPPCHECK_IGNORED_PATHS})
    set(CPPCHECK_IGNORED_PATHS -i${_ignored_paths})
  endif(CPPCHECK_IGNORED_PATHS)

  set(_cppcheck_args ${CPPCHECK_IGNORED_PATHS} --error-exitcode=2
    --inline-suppr --suppress=unusedFunction --suppress=unmatchedSuppression
    --suppress=missingInclude --suppress=preprocessorErrorDirective
    ${CPPCHECK_EXTRA_ARGS})

  list(FIND ARGN UNUSED_FUNCTIONS _unused_func)
  if("${_unused_func}" GREATER "-1")
    list(APPEND _cppcheck_args ${CPPCHECK_UNUSEDFUNC_ARG})
  endif()

  list(FIND ARGN STYLE _style)
  if("${_style}" GREATER "-1")
    list(APPEND _cppcheck_args ${CPPCHECK_STYLE_ARG})
  endif()

  list(FIND ARGN POSSIBLE_ERROR _poss_err)
  if("${_poss_err}" GREATER "-1")
    list(APPEND _cppcheck_args ${CPPCHECK_POSSIBLEERROR_ARG})
  endif()

  list(FIND _input FAIL_ON_WARNINGS _fail_on_warn)
  if("${_fail_on_warn}" GREATER "-1")
    list(APPEND CPPCHECK_FAIL_REGULAR_EXPRESSION
      ${CPPCHECK_WARN_REGULAR_EXPRESSION})
  endif()

  list(FIND ARGN EXCLUDE_QT_MOC_FILES _exclude_moc_files)
  if("${_exclude_moc_files}" GREATER "-1")
    SET(_exclude_pattern ".*moc_.*\\.cxx$")
  endif()

  get_target_property(_imported_target "${_name}" IMPORTED)
  if(_imported_target)
    return()
  endif()

  get_target_property(_cppcheck_sources "${_name}" SOURCES)
  set(_files)
  foreach(_source ${_cppcheck_sources})
    get_source_file_property(_cppcheck_lang "${_source}" LANGUAGE)
    get_source_file_property(_cppcheck_loc "${_source}" LOCATION)
    if("${_cppcheck_lang}" MATCHES "CXX" AND NOT ${_cppcheck_loc} MATCHES ${_exclude_pattern})
      list(APPEND _files "${_cppcheck_loc}")
    endif()
  endforeach()

  if(NOT _files) # nothing to check
    return()
  endif()

  add_custom_target(cppcheck_run_${_name}
    COMMAND ${CPPCHECK_EXECUTABLE} ${CPPCHECK_QUIET_ARG}
      ${CPPCHECK_TEMPLATE_ARG} ${_cppcheck_args} ${_files}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "cppcheck_run_${_name}: Running cppcheck on target ${_name}..."
    VERBATIM)
  set_target_properties(cppcheck_run_${_name} PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER "Tests/${PROJECT_NAME}/cppcheck")

  if(NOT TARGET cppcheck_${PROJECT_NAME})
    add_custom_target(cppcheck_${PROJECT_NAME})
    set_target_properties(cppcheck_${PROJECT_NAME} PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER "Tests/${PROJECT_NAME}/cppcheck")
  endif()
  if(NOT TARGET ${PROJECT_NAME}-tests)
    add_custom_target(${PROJECT_NAME}-tests)
  endif()

  add_dependencies(cppcheck_${PROJECT_NAME} cppcheck_run_${_name})
  add_dependencies(${PROJECT_NAME}-tests cppcheck_run_${_name})
  add_dependencies(cppcheck cppcheck_${PROJECT_NAME})
endfunction()
