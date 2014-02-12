# Copyright (c) 2010 Daniel Pfeifer
#               2010-2014, Stefan Eilemann <eile@eyescale.ch>

if(NOT WIN32) # tests want to be with DLLs on Windows - no rpath
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/tests)
endif()

include_directories(${CMAKE_CURRENT_LIST_DIR}/include
  ${CMAKE_CURRENT_SOURCE_DIR})

file(GLOB_RECURSE TEST_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.cpp)
list(SORT TEST_FILES)

set(ALL_TESTS)
foreach(FILE ${TEST_FILES})
  string(REGEX REPLACE ".cpp" "" NAME ${FILE})
  string(REGEX REPLACE "[./]" "_" NAME ${NAME})
  source_group(\\ FILES ${FILE})

  list(APPEND ALL_TESTS ${NAME})
  add_executable(${NAME} ${FILE})
  set_target_properties(${NAME} PROPERTIES FOLDER "Tests")
  target_link_libraries(${NAME} ${TEST_LIBRARIES})

  get_target_property(EXECUTABLE ${NAME} LOCATION)
  STRING(REGEX REPLACE "\\$\\(.*\\)" "\${CTEST_CONFIGURATION_TYPE}"
    EXECUTABLE "${EXECUTABLE}")
  add_test(${NAME} ${EXECUTABLE})

  if(COVERAGE)
    add_dependencies(${NAME} lcov-clean)
  endif()
endforeach(FILE ${TEST_FILES})

add_custom_target(runtests
  COMMAND ${CMAKE_CTEST_COMMAND} \${ARGS} DEPENDS ${ALL_TESTS}
  COMMENT "Running all unit tests"
  WORKING_DIRECTORY "${CMAKE_BINARY_DIR}")

if(COVERAGE)
  add_custom_target(lcov-gather
    COMMAND ${LCOV} -q --directory . --capture --output-file lcov.info
    COMMENT "Capturing code coverage counters"
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    DEPENDS runtests)
  add_custom_target(lcov-remove
    COMMAND ${LCOV} -q --remove lcov.info 'tests/*' '/usr/*' '/opt/*' '*.l' 'CMake/test/*' '*/install/*' '/Applications/Xcode.app/*' '${CMAKE_BINARY_DIR}/*' --output-file lcov2.info
    COMMENT "Cleaning up code coverage counters"
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    DEPENDS lcov-gather)
  add_custom_target(lcov-html
    COMMAND ${GENHTML} -q -o CoverageReport ${CMAKE_BINARY_DIR}/lcov2.info
    COMMENT "Creating html coverage report, open ${CMAKE_BINARY_DIR}/doc/html/CoverageReport/index.html "
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/doc/html
    DEPENDS lcov-remove)
  make_directory(${CMAKE_BINARY_DIR}/doc/html)

  # workaround: 'make test' does not build tests beforehand
  add_custom_target(tests DEPENDS lcov-html)
else()
  add_custom_target(tests DEPENDS runtests)
endif()

set_target_properties(tests PROPERTIES FOLDER "Tests")
