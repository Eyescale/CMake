# Copyright (c) 2010 Daniel Pfeifer
#               2010-2014, Stefan Eilemann <eile@eyescale.ch>
#               2014, Juan Hernando <jhernando@fi.upm.es>
#
# Input:
# * TEST_LIBRARIES link each test executables against these libraries
# * EXCLUDE_FROM_TESTS a relative paths to test files to exclude; optional
# * From CMake 2.8.8 on, a custom include path and library linking can be
#   provided for each test. This customization will go in a separate .cmake
#   file whose base name matches the .cpp file basename. The variables to set
#   in that file are ${NAME}_INCLUDE_DIRECTORIES and ${NAME}_LINK_LIBRARIES
#   (verbatim names, the value of NAME will be set by the code including the
#    .cmake file). As a fallback a defaults.cmake file can be also provided

if(NOT WIN32) # tests want to be with DLLs on Windows - no rpath
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
endif()

file(GLOB_RECURSE TEST_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.cpp)
foreach(FILE ${EXCLUDE_FROM_TESTS})
  list(REMOVE_ITEM TEST_FILES ${FILE})
endforeach()
list(SORT TEST_FILES)

set(ALL_CPP_TESTS)
foreach(FILE ${TEST_FILES})
  string(REGEX REPLACE ".cpp" "" NAME ${FILE})
  string(REGEX REPLACE "[./]" "_" NAME ${NAME})
  source_group(\\ FILES ${FILE})

  list(APPEND ALL_CPP_TESTS ${NAME})
  add_executable(${NAME} ${FILE})
  set_target_properties(${NAME} PROPERTIES FOLDER "Tests")

  if(CMAKE_VERSION VERSION_GREATER 2.8.7)
    # If per target INCLUDE_DIRECTORIES are supported this code will load
    # a per test config file to fine tune its compilation.
    # This can be to create per-tests mock-ups if needed.
    if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${NAME}.cmake)
      include(${CMAKE_CURRENT_SOURCE_DIR}/${NAME}.cmake)
    elseif(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/defaults.cmake)
      include(${CMAKE_CURRENT_SOURCE_DIR}/defaults.cmake)
    endif()

    # Test includes
    # Clearing all includes first
    set_target_properties(${NAME} PROPERTIES INCLUDE_DIRECTORIES "")
    if (${NAME}_INCLUDE_DIRECTORIES)
      set_target_properties(${NAME} PROPERTIES
        INCLUDE_DIRECTORIES "${${NAME}_INCLUDE_DIRECTORIES}")
    else()
      # Default includes
      set(${NAME}_INCLUDE_DIRECTORIES
        ${CMAKE_CURRENT_LIST_DIR}/cpp ${CMAKE_CURRENT_SOURCE_DIR})
    endif()

    # Test link libraries
    if (${NAME}_LINK_LIBRARIES)
      target_link_libraries(${NAME} ${${NAME}_LINK_LIBRARIES})
    endif()
  endif()
  target_link_libraries(${NAME} ${TEST_LIBRARIES})

  get_target_property(EXECUTABLE ${NAME} LOCATION)
  string(REGEX REPLACE "\\$\\(.*\\)" "\${CTEST_CONFIGURATION_TYPE}"
         EXECUTABLE "${EXECUTABLE}")
  add_test(${NAME} ${EXECUTABLE})
endforeach()

add_custom_target(run_cpp_tests
  COMMAND ${CMAKE_CTEST_COMMAND} \${ARGS} DEPENDS ${ALL_CPP_TESTS}
  COMMENT "Running all cpp unit tests")
if(COVERAGE)
  add_dependencies(run_cpp_tests lcov-clean)
endif()

