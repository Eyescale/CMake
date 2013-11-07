# Copyright (c) 2010 Daniel Pfeifer
#               2010-2013, Stefan Eilemann <eile@eyescale.ch>

if(NOT WIN32) # tests want to be with DLLs on Windows - no rpath
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/tests)
endif()

find_program(LCOV lcov)
find_program(GENHTML genhtml)
if(LCOV AND GENHTML AND (CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANG))
  set(COVERAGE ON)
  add_custom_target(lcov-clean
    COMMAND ${LCOV} -q --directory ${CMAKE_BINARY_DIR} --zerocounters
    COMMENT "Resetting code coverage counters")
else()
  set(COVERAGE_MISSING)
  if(NOT LCOV)
    set(COVERAGE_MISSING " lcov")
  endif()
  if(NOT GENHTML)
    set(COVERAGE_MISSING "${COVERAGE_MISSING} genhtml")
  endif()
  if(COVERAGE_MISSING)
    set(COVERAGE_MISSING "missing${COVERAGE_MISSING}")
  else()
    set(COVERAGE_MISSING "unsupported compiler")
  endif()
  message(STATUS "No code coverage report, ${COVERAGE_MISSING}")
endif()

include_directories(
  ${CMAKE_CURRENT_LIST_DIR}/test
  ${CMAKE_CURRENT_SOURCE_DIR}
  )

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
  target_link_libraries(${NAME} Lunchbox ${Boost_LIBRARIES})

  get_target_property(EXECUTABLE ${NAME} LOCATION)
  STRING(REGEX REPLACE "\\$\\(.*\\)" "\${CTEST_CONFIGURATION_TYPE}"
    EXECUTABLE "${EXECUTABLE}")
  add_test(${NAME} ${EXECUTABLE})

  if(COVERAGE)
    add_dependencies(${NAME} lcov-clean)
  endif()
endforeach(FILE ${TEST_FILES})

add_custom_target(runtests
  COMMAND ${CMAKE_CTEST_COMMAND} DEPENDS any ${ALL_TESTS}
  COMMENT "Running all unit tests")

if(COVERAGE)
  add_custom_target(lcov-gather
    COMMAND ${LCOV} -q --directory . --capture --output-file lcov.info
    COMMENT "Capturing code coverage counters"
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    DEPENDS runtests)
  add_custom_target(lcov-remove
    COMMAND ${LCOV} -q --remove lcov.info 'tests/*' '/usr/*' '/opt/*' --output-file lcov2.info
    COMMENT "Cleaning up code coverage counters"
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    DEPENDS lcov-gather)
  add_custom_target(lcov-html
    COMMAND ${GENHTML} -q -o CoverageReport lcov2.info
    COMMENT "Creating html coverage report, open ${CMAKE_BINARY_DIR}/CoverageReport/index.html "
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    DEPENDS lcov-remove)

  # workaround: 'make test' does not build tests beforehand
  add_custom_target(tests DEPENDS lcov-html)
else()
  add_custom_target(tests DEPENDS runtests)
endif()

set_target_properties(tests PROPERTIES FOLDER "Tests")