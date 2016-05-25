# Copyright (c) 2010 Daniel Pfeifer
#               2010-2015, Stefan Eilemann <eile@eyescale.ch>
#               2014, Juan Hernando <jhernando@fi.upm.es>
#
# Creates per project cpptests, perftests and nightlytests targets.
# The first one creates a test for each .c or .cpp file in the current
# directory tree, excluding the ones which start with perf or nightly (either
# as top-level directory name or filename).
# For each file starting with perf or nightly a test is created and added to
# pertests and nightlytests respectively. These two targets are not meant
# to be executed with each test run. All targets will update and compile the
# test executables before invoking ctest. The nightlytests target will also
# run pertests.
# The per project targets are included into the global 'tests', 'perftests' and
# 'nightlytests' from CommonCTest.cmake.
#
# Input:
# * TEST_LIBRARIES link each test executables against these libraries
# * EXCLUDE_FROM_TESTS relative paths to test files to exclude; optional
# * For each test ${NAME}_INCLUDE_DIRECTORIES and ${NAME}_LINK_LIBRARIES can
#   be set to configure target specific includes and link libraries, where
#   NAME is the test filename without the .cpp extension. Per test include
#   directories are only supported for for CMake 2.8.8
# * For each test ${TEST_PREFIX} and ${TEST_ARGS}, or if present,
#   ${NAME}_TEST_PREFIX and ${NAME}_TEST_ARGS, can be
#   set to customise the actual test command, supplying a prefix command
#   and additional arguments to follow the test executable.
# * TEST_LABEL sets the LABEL property on each generated test;
#   ${NAME}_TEST_LABEL specifies an additional label.
# * UNIT_AND_PERF_TESTS a list with files which should be compiled
#   also as performance tests. The unit test will be named 'file',
#   whereas the performance test will be named 'perf-file'.
# * TEST_ENABLE_BOOST_HEADER adds -DBOOST_TEST_DYN_LINK to tests

include(CommonCheckTargets)

if(NOT WIN32) # tests want to be with DLLs on Windows - no rpath support
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endif()

file(GLOB_RECURSE TEST_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.c *.cpp)
foreach(FILE ${EXCLUDE_FROM_TESTS})
  list(REMOVE_ITEM TEST_FILES ${FILE})
endforeach()
list(SORT TEST_FILES)

set(ALL_CPP_UNIT_TESTS)
set(ALL_CPP_PERF_TESTS)
set(ALL_CPP_NIGHTLY_TESTS)

# backwards compat: generate main() for unit tests
#  should really #define BOOST_TEST_DYN_LINK if using boost
if(NOT DEFINED TEST_ENABLE_BOOST_HEADER)
  set(TEST_ENABLE_BOOST_HEADER ON)
endif()
if(NOT Boost_USE_STATIC_LIBS AND TEST_ENABLE_BOOST_HEADER)
  add_definitions(-DBOOST_TEST_DYN_LINK)
endif()

macro(common_add_cpp_test NAME FILE)
  set(TEST_NAME ${PROJECT_NAME}-${NAME})
  if(NOT TARGET ${NAME} AND NOT MSVC) # Create target without project prefix if possible
    set(TEST_NAME ${NAME})
  endif()

  add_executable(${TEST_NAME} ${FILE})
  common_compile_options(${TEST_NAME})
  common_check_targets(${TEST_NAME})
  set_target_properties(${TEST_NAME} PROPERTIES FOLDER ${PROJECT_NAME}/tests
    OUTPUT_NAME ${NAME})

  # for DoxygenRule.cmake and SubProject.cmake
  set_property(GLOBAL APPEND PROPERTY ${PROJECT_NAME}_ALL_DEP_TARGETS ${TEST_NAME})

  # Per target INCLUDE_DIRECTORIES
  if(${NAME}_INCLUDE_DIRECTORIES)
    set_target_properties(${TEST_NAME} PROPERTIES
      INCLUDE_DIRECTORIES "${${NAME}_INCLUDE_DIRECTORIES}")
  endif()

  # Test link libraries
  target_link_libraries(${TEST_NAME}
    ${${NAME}_LINK_LIBRARIES} ${TEST_LIBRARIES})
  # Per target test command customisation with
  # ${NAME}_TEST_PREFIX and ${NAME}_TEST_ARGS
  set(RUN_PREFIX ${TEST_PREFIX})
  if(${NAME}_TEST_PREFIX)
    set(RUN_PREFIX ${${NAME}_TEST_PREFIX})
  endif()
  set(RUN_ARGS ${TEST_ARGS})
  if(${NAME}_TEST_ARGS)
    set(RUN_ARGS ${${NAME}_TEST_ARGS})
  endif()

  add_test(NAME ${TEST_NAME}
    COMMAND ${RUN_PREFIX} $<TARGET_FILE:${TEST_NAME}> ${RUN_ARGS}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

  if(${NAME} MATCHES "^perf" OR ${NAME} MATCHES "perf-")
    list(APPEND ALL_CPP_PERF_TESTS ${TEST_NAME})
    set(TEST_LABELS ${PROJECT_NAME}-perf)
    install(TARGETS ${TEST_NAME} DESTINATION share/${PROJECT_NAME}/benchmarks
      COMPONENT apps)
  elseif("${NAME}" MATCHES "^nightly" OR "${NAME}" MATCHES "nightly-")
    list(APPEND ALL_CPP_NIGHTLY_TESTS ${TEST_NAME})
    set(TEST_LABELS ${PROJECT_NAME}-nightly)
  else()
    list(APPEND ALL_CPP_UNIT_TESTS ${TEST_NAME})
    set(TEST_LABELS ${PROJECT_NAME}-unit)
  endif()

  # Add test labels
  list(APPEND TEST_LABELS ${TEST_LABEL} ${${NAME}_TEST_LABEL})
  if(TEST_LABELS)
    set_tests_properties(${TEST_NAME} PROPERTIES LABELS "${TEST_LABELS}")
  endif()
endmacro()

foreach(FILE ${TEST_FILES})
  string(REGEX REPLACE "\\.(c|cpp)$" "" NAME ${FILE})
  string(REGEX REPLACE "[./]" "-" NAME ${NAME})
  source_group(\\ FILES ${FILE})

  if(MSVC)
    # need unique target name:
    # - case insensitivity can result to duplicated targets
    # - PDB files of library and test executable could overwrite each other
    common_add_cpp_test(test-${NAME} ${FILE})
  else()
    common_add_cpp_test(${NAME} ${FILE})
  endif()
  list(FIND UNIT_AND_PERF_TESTS ${FILE} ADD_PERF_TEST)
  if(ADD_PERF_TEST GREATER -1)
    common_add_cpp_test(perf-${NAME} ${FILE})
  endif()
endforeach()

set(__CONSOLE)
if(CMAKE_VERSION VERSION_GREATER 3.1.99)
  set(__CONSOLE USES_TERMINAL)
endif()

macro(ADD_TEST_TARGET display_name target_part label_part)
  if(NOT TARGET ${PROJECT_NAME}-${target_part}tests)
    add_custom_target(${PROJECT_NAME}-${target_part}tests ${__CONSOLE}
      COMMAND ${CMAKE_CTEST_COMMAND} -T test --no-compress-output
      --output-on-failure -L ${PROJECT_NAME}-${label_part} -C $<CONFIGURATION> \${ARGS}
      WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
      COMMENT "Running ${PROJECT_NAME} ${display_name} tests")
  endif()
  set_target_properties(${PROJECT_NAME}-${target_part}tests PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)
  string(TOUPPER ${label_part} LABEL_PART)
  if(ALL_CPP_${LABEL_PART}_TESTS)
    add_dependencies(${PROJECT_NAME}-${target_part}tests
                     ${ALL_CPP_${LABEL_PART}_TESTS})
  endif()
  add_dependencies(${target_part}tests ${PROJECT_NAME}-${target_part}tests)
endmacro()

add_test_target(unit cpp unit)
add_test_target(performance perf perf)
add_test_target(nightly nightly nightly)

add_dependencies(${PROJECT_NAME}-tests ${PROJECT_NAME}-cpptests)
add_dependencies(tests ${PROJECT_NAME}-tests)
add_dependencies(${PROJECT_NAME}-nightlytests ${PROJECT_NAME}-perftests)

if(COMMON_ENABLE_COVERAGE)
  add_coverage_targets(${PROJECT_NAME}-cpptests)
endif()
