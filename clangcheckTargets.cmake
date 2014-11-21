# - Run clang-check on c++ source files as a custom target and a test
#
#  include(clangcheckTargets)
#  add_clangcheck(<target-name> [UNUSED_FUNCTIONS] [STYLE] [POSSIBLE_ERROR]
#                               [FAIL_ON_WARNINGS] [EXCLUDE_QT_MOC_FILES]) -
#    Create a target to check a target's sources with clang-check and the
#    indicated options

if(__add_clangcheck)
  return()
endif()
set(__add_clangcheck YES)

if(NOT CLANGCHECK)
  find_program(CLANGCHECK clang-check)
endif()

if(NOT CLANGCHECK)
  if(NOT TARGET clangcheck)
    add_custom_target(clangcheck COMMENT "clang-check executable not found")
    set_target_properties(clangcheck PROPERTIES EXCLUDE_FROM_ALL TRUE)
  endif()
endif()

if(NOT TARGET clangcheck)
  add_custom_target(clangcheck)
endif()

function(add_clangcheck _name)
  if(NOT TARGET ${_name})
    message(FATAL_ERROR "add_clangcheck given non-existing target '${_name}'")
  endif()
  if(NOT CLANGCHECK)
    return()
  endif()

  set(_clangcheck_args -p "${PROJECT_BINARY_DIR}" -analyze -fixit
    -fatal-assembler-warnings -extra-arg=-Qunused-arguments
    ${CLANGCHECK_EXTRA_ARGS})
  set(_exclude_pattern ".*moc_.*\\.cxx$") # Qt moc files

  get_target_property(_clangcheck_sources "${_name}" SOURCES)
  set(_files)
  foreach(_source ${_clangcheck_sources})
    get_source_file_property(_clangcheck_lang "${_source}" LANGUAGE)
    get_source_file_property(_clangcheck_loc "${_source}" LOCATION)
    if("${_clangcheck_lang}" MATCHES "CXX" AND
        NOT ${_clangcheck_loc} MATCHES ${_exclude_pattern} AND
        ${_clangcheck_loc} MATCHES "\\.(cpp|cxx)$")
      list(APPEND _files "${_clangcheck_loc}")
    endif()
  endforeach()

  if(NOT _files) # nothing to check
    return()
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
endfunction()
