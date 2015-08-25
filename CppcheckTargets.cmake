# - Run cppcheck on c++ source files as a custom target and a test
#
#  include(CppcheckTargets)
#  add_cppcheck(<target-name> [UNUSED_FUNCTIONS] [STYLE] [POSSIBLE_ERROR]
#                             [FAIL_ON_WARNINGS]) -
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

if(TARGET ${PROJECT_NAME}-cppcheck)
  return()
endif()

include(CMakeParseArguments)

if(NOT CPPCHECK_FOUND)
  find_package(cppcheck 1.66 QUIET)
endif()

if(NOT CPPCHECK_FOUND)
  add_custom_target(${PROJECT_NAME}-cppcheck
    COMMENT "cppcheck executable not found")
  set_target_properties(${PROJECT_NAME}-cppcheck PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests/cppcheck)
endif()

if(NOT TARGET cppcheck)
  add_custom_target(cppcheck)
  set_target_properties(cppcheck PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON)
endif()

function(add_cppcheck _name _files)
  if(NOT CPPCHECK_FOUND)
    return()
  endif()

  if(CPPCHECK_IGNORED_PATHS)
    string(REPLACE " " " -i" _ignored_paths ${CPPCHECK_IGNORED_PATHS})
    set(CPPCHECK_IGNORED_PATHS -i${_ignored_paths})
  endif()

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

  add_test(NAME ${_name}-cppcheck
    COMMAND ${CPPCHECK_EXECUTABLE} ${CPPCHECK_QUIET_ARG}
      ${CPPCHECK_TEMPLATE_ARG} ${_cppcheck_args} ${_files}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  set_tests_properties(${_name}-cppcheck PROPERTIES LABELS ${PROJECT_NAME}-unit)

  add_custom_target(${_name}-runcppcheck
    COMMAND ${CPPCHECK_EXECUTABLE} ${CPPCHECK_QUIET_ARG}
      ${CPPCHECK_TEMPLATE_ARG} ${_cppcheck_args} ${_files}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
  set_target_properties(${_name}-runcppcheck PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests/cppcheck)

  if(NOT TARGET ${PROJECT_NAME}-cppcheck)
    add_custom_target(${PROJECT_NAME}-cppcheck)
    set_target_properties(${PROJECT_NAME}-cppcheck PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests/cppcheck)
  endif()
  add_dependencies(${PROJECT_NAME}-cppcheck ${_name}-runcppcheck)
  add_dependencies(cppcheck ${PROJECT_NAME}-cppcheck)
endfunction()
