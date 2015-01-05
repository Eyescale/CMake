# Copyright (c) 2010 Daniel Pfeifer
#               2010-2014, Stefan Eilemann <eile@eyescale.ch>
#               2014, Juan Hernando <jhernando@fi.upm.es>
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

if(NOT WIN32) # tests want to be with DLLs on Windows - no rpath
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endif()

include_directories(${CMAKE_CURRENT_LIST_DIR}/cpp ${PROJECT_SOURCE_DIR})

file(GLOB_RECURSE TEST_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.c *.cpp)
foreach(FILE ${EXCLUDE_FROM_TESTS})
  list(REMOVE_ITEM TEST_FILES ${FILE})
endforeach()
list(SORT TEST_FILES)

set(ALL_CPP_TESTS)
foreach(FILE ${TEST_FILES})
  string(REGEX REPLACE "\\.(c|cpp)$" "" NAME ${FILE})
  string(REGEX REPLACE "[./]" "_" NAME ${NAME})
  source_group(\\ FILES ${FILE})

  list(APPEND ALL_CPP_TESTS ${PROJECT_NAME}_${NAME})
  add_executable(${PROJECT_NAME}_${NAME} ${FILE})
  set_target_properties(${PROJECT_NAME}_${NAME} PROPERTIES
    FOLDER "Tests" OUTPUT_NAME ${NAME})

  if(NOT TARGET ${NAME}) # Create target without project prefix if possible
    add_custom_target(${NAME} DEPENDS ${PROJECT_NAME}_${NAME})
  endif()

  # Per target INCLUDE_DIRECTORIES if supported
  if(CMAKE_VERSION VERSION_GREATER 2.8.7 AND ${NAME}_INCLUDE_DIRECTORIES)
    set_target_properties(${PROJECT_NAME}_${NAME} PROPERTIES
      INCLUDE_DIRECTORIES "${${NAME}_INCLUDE_DIRECTORIES}")
  endif()

  # Test link libraries
  target_link_libraries(${PROJECT_NAME}_${NAME}
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

  add_test(NAME ${PROJECT_NAME}_${NAME}
    COMMAND ${RUN_PREFIX} $<TARGET_FILE:${PROJECT_NAME}_${NAME}> ${RUN_ARGS})

  # Add test labels
  set(TEST_LABELS ${TEST_LABEL} ${${NAME}_TEST_LABEL})
  if(TEST_LABELS)
    set_tests_properties(${PROJECT_NAME}_${NAME} PROPERTIES
      LABELS "${TEST_LABELS}")
  endif()
endforeach()

if(TARGET ${PROJECT_NAME}_run_cpp_tests)
  add_dependencies(${PROJECT_NAME}_run_cpp_tests ${ALL_CPP_TESTS})
else()
  add_custom_target(${PROJECT_NAME}_run_cpp_tests
    COMMAND ${CMAKE_CTEST_COMMAND} \${ARGS} DEPENDS ${ALL_CPP_TESTS}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Running all ${PROJECT_NAME} cpp tests")
  if(COVERAGE)
    add_dependencies(${PROJECT_NAME}_run_cpp_tests ${PROJECT_NAME}_lcov-clean)
  endif()
endif()

if(NOT TARGET run_cpp_tests)
  add_custom_target(run_cpp_tests)
endif()
add_dependencies(run_cpp_tests ${PROJECT_NAME}_run_cpp_tests)
