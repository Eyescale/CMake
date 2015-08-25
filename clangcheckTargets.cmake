# - Run clang-check on c++ source files as a custom target and a test
#
#  include(clangcheckTargets)
#  add_clangcheck(<target-name> [FILES] [EXCLUDE_PATTERN]) -
#    Create a target to check a target's sources with clang-check and the
#    indicated options

if(TARGET ${_name}_clangcheck)
  return()
endif()

include(CMakeParseArguments)
include(GetSourceFilesFromTarget)

if(NOT CLANGCHECK)
  find_program(CLANGCHECK clang-check)
endif()

if(NOT CLANGCHECK)
  if(NOT TARGET clangcheck)
    add_custom_target(clangcheck COMMENT "clang-check executable not found")
    set_target_properties(clangcheck PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD ON)
  endif()
endif()

if(NOT TARGET clangcheck)
  add_custom_target(clangcheck)
endif()

function(add_clangcheck _name)
  if(NOT CLANGCHECK)
    return()
  endif()

  set(_clangcheck_args -p "${PROJECT_BINARY_DIR}" -analyze -fixit
    -fatal-assembler-warnings -extra-arg=-Qunused-arguments
    ${CLANGCHECK_EXTRA_ARGS})

  cmake_parse_arguments(add_clangcheck "" "EXCLUDE_PATTERN" "FILES" ${ARGN})
  if(NOT add_clangcheck_EXCLUDE_PATTERN)
    set(add_clangcheck_EXCLUDE_PATTERN "^$") # Empty string regex
  endif()

  set(_files ${add_clangcheck_FILES})
  if(NOT _files)
    get_source_files(${_name} ${add_clangcheck_EXCLUDE_PATTERN})
    if(NOT ${_name}_FILES) # nothing to check
      return()
    endif()
    set(_files ${${_name}_FILES})
  endif()

  if(ENABLE_CLANGCHECK_TESTS)
    add_test(NAME ${_name}_clangcheck_test
      COMMAND "${CLANGCHECK}" ${_clangcheck_args} ${_files}
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

    set_tests_properties(${_name}_clangcheck_test
      PROPERTIES FAIL_REGULAR_EXPRESSION " (warning|error): ")
  endif()

  add_custom_target(${_name}_clangcheck
    COMMAND ${CLANGCHECK} ${_clangcheck_args} ${_files}
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMENT "Running clangcheck on target ${_name}..."
    VERBATIM)
  add_dependencies(clangcheck ${_name}_clangcheck)
    set_target_properties(${_name}_clangcheck PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)
endfunction()
