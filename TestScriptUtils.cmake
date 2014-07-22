# @author Sam Yates

# Utility functions for manipulating test labels and producing
# tests from scripts.

function(add_test_label NAME)
  set_property(TEST ${NAME} APPEND PROPERTY LABELS ${ARGN})
endfunction()

# If TEST_LABEL is defined, set the label(s) in this variable on the new test.
# If TEST_ENVIRONMENT is defined, add to the test properties.
# If TEST_PREFIX or ${NAME}_TEST_PREFIX is defined, preface the interpreter
# with this prefix.

function(add_test_script NAME SCRIPT INTERP)
  set(RUN_PREFIX ${TEST_PREFIX})
  if(${NAME}_TEST_PREFIX)
    set(RUN_PREFIX ${${NAME}_TEST_PREFIX})
  endif()

  if(NOT INTERP)
    set(INTERP "/bin/sh")
  endif()
  add_test(NAME ${NAME}
           COMMAND ${RUN_PREFIX} ${INTERP} "${CMAKE_CURRENT_SOURCE_DIR}/${SCRIPT}"
           WORKING_DIRECTORY "${CMAKE_BINARY_DIR}") 
  if(TEST_LABEL)
    add_test_label(${NAME} ${TEST_LABEL})
  endif()
  if(TEST_ENVIRONMENT)
    set_property(TEST ${NAME} PROPERTY ENVIRONMENT ${TEST_ENVIRONMENT})
  endif()
endfunction()

# Generate test targets from a series of test labels. 
# Example usage: add_test_class_target(foo bar) will create a new test target:
#
# test-foo-bar:
#      ctest -L ^foo$ -L ^bar$
#
# which will run all tests which have both the label 'foo' and 'bar'.

function(add_test_class_target)
  string(REPLACE ";" "-" TEST_SUFFIX "${ARGN}")
  string(REPLACE ";" "$$;-L;^" TEST_LOPTS "${ARGN}")

  add_custom_target("test-${TEST_SUFFIX}"
    COMMAND ${CMAKE_CTEST_COMMAND} -L ^${TEST_LOPTS}$$
    WORKING_DIRECTORY ${${CMAKE_PROJECT_NAME}_BINARY_DIR}
    COMMENT "Running all ${ARGN} tests")
endfunction()

