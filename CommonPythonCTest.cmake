# Copyright (c) 2016, Juan Hernando <juan.hernando@fi.upm.es>
#
# Creates a per project pythontests target.
# This target creates a test for each .py file in the current
# directory tree. The per project target is included into the global
# 'tests' from CommonCTest.cmake.
#
# Input:
# * PYTHON_TEST_DEPENDENCIES targets that are required by the tests
# * PYTHON_TEST_EXCLUDE relative paths to test files to exclude; optional
# Output:
# * PYTHON_TEST_OUTPUT_PATH the output path where python tests are copied to
#   in the build dir. Additional modules can be placed in that destination
#   directory if needed by the tests.

set(PYTHON_TEST_OUTPUT_PATH ${PROJECT_BINARY_DIR}/tests/python)

file(GLOB_RECURSE TEST_FILES ${CMAKE_CURRENT_SOURCE_DIR} *.py)
foreach(FILE ${PYTHON_TEST_EXCLUDE})
  list(REMOVE_ITEM TEST_FILES ${FILE})
endforeach()
list(SORT TEST_FILES)

function(common_add_python_test TEST_SOURCE)

  get_filename_component(BASENAME ${TEST_SOURCE} NAME)
  set(TEST_FILE ${PYTHON_TEST_OUTPUT_PATH}/${BASENAME})
  string(REGEX REPLACE "(.*)\\.py" "\\1" BASENAME "${BASENAME}")
  set(TEST_NAME ${PROJECT_NAME}-python-${BASENAME})

  add_custom_command(OUTPUT ${TEST_FILE}
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${TEST_SOURCE} ${TEST_FILE}
    DEPENDS ${TEST_SOURCE})

  add_test(NAME ${TEST_NAME} COMMAND ${PYTHON_EXECUTABLE} ${TEST_FILE})

  add_custom_target(ctest_${TEST_NAME}
    COMMAND ${CMAKE_CTEST_COMMAND} -Q -T test --no-compress-output
      -R '^${TEST_NAME}$$' -C $<CONFIGURATION> \${ARGS}
    DEPENDS ${PYTHON_TEST_DEPENDENCIES} ${TEST_FILE}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Running ${TEST_NAME} python test")
  set_target_properties(ctest_${TEST_NAME} PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER "Tests")

  set(ALL_PYTHON_TESTS ${ALL_PYTHON_TESTS} ctest_${TEST_NAME} PARENT_SCOPE)
endfunction()

set(ALL_PYTHON_TESTS)
foreach(TEST_FILE ${TEST_FILES})
  common_add_python_test(${TEST_FILE})
endforeach()

if(NOT ALL_PYTHON_TESTS)
  return()
endif()

if(NOT TARGET ${PROJECT_NAME}-pythontests)
  add_custom_target(${PROJECT_NAME}-pythontests)
  set_target_properties(${PROJECT_NAME}-pythontests PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER "Tests")

  add_dependencies(${PROJECT_NAME}-tests ${PROJECT_NAME}-pythontests)
  add_dependencies(tests ${PROJECT_NAME}-tests)
endif()

add_dependencies(${PROJECT_NAME}-pythontests ${ALL_PYTHON_TESTS})

