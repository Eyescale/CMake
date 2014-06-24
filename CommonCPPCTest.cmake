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
# * For each test ${NAME}_TEST_PREFIX and ${NAME}_TEST_ARGS can be
#   set to customise the actual test command, supplying a prefix command
#   and additional arguments to follow the test executable.

if(NOT WIN32) # tests want to be with DLLs on Windows - no rpath
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endif()

include_directories(${CMAKE_CURRENT_LIST_DIR}/cpp ${CMAKE_CURRENT_SOURCE_DIR})

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

  list(APPEND ALL_CPP_TESTS ${NAME})
  add_executable(${NAME} ${FILE})
  set_target_properties(${NAME} PROPERTIES FOLDER "Tests")

  # Per target INCLUDE_DIRECTORIES if supported
  if(CMAKE_VERSION VERSION_GREATER 2.8.7 AND ${NAME}_INCLUDE_DIRECTORIES)
    set_target_properties(${NAME} PROPERTIES
      INCLUDE_DIRECTORIES "${${NAME}_INCLUDE_DIRECTORIES}")
  endif()

  # Test link libraries
  if (${NAME}_LINK_LIBRARIES)
    target_link_libraries(${NAME} ${${NAME}_LINK_LIBRARIES})
  endif()
  target_link_libraries(${NAME} ${TEST_LIBRARIES})

  get_target_property(EXECUTABLE ${NAME} LOCATION)
  string(REGEX REPLACE "\\$\\(.*\\)" "\${CTEST_CONFIGURATION_TYPE}"
         EXECUTABLE "${EXECUTABLE}")

  # Per target test command customisation with
  # ${NAME}_TEST_PREFIX and ${NAME}_TEST_ARGS
  add_test(${NAME} ${${NAME}_TEST_PREFIX} ${EXECUTABLE} ${${NAME}_TEST_ARGS})
endforeach()

add_custom_target(run_cpp_tests
  COMMAND ${CMAKE_CTEST_COMMAND} \${ARGS} DEPENDS ${ALL_CPP_TESTS}
  WORKING_DIRECTORY ${${CMAKE_PROJECT_NAME}_BINARY_DIR}
  COMMENT "Running all cpp unit tests")
if(COVERAGE)
  add_dependencies(run_cpp_tests lcov-clean)
endif()
