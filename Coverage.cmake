# Code coverage reporting
#   ENABLE_COVERAGE has to be set since code coverage compiler flags
#   may break downstream projects. Use Buildyard 'make coverage'
#   target.

option(ENABLE_COVERAGE "Enable code coverage testing" OFF)
if(ENABLE_COVERAGE)
  if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANG)
    find_program(GENHTML genhtml)
    find_program(LCOV lcov)
    if(LCOV)
      execute_process(COMMAND
        ${LCOV} --version OUTPUT_VARIABLE LCOV_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE)
      string(REGEX REPLACE ".+([0-9]+\\.[0-9]+)" "\\1" LCOV_VERSION
        ${LCOV_VERSION})
    endif()
    if( GCC_COMPILER_VERSION VERSION_GREATER 4.6.99 AND
        LCOV_VERSION VERSION_LESS 1.10)
      message(FATAL_ERROR "Need lcov >= 1.10 for gcc ${GCC_COMPILER_VERSION}, found lcov ${LCOV_VERSION}")
    endif()
    if(LCOV AND GENHTML)
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
      message(FATAL_ERROR "No code coverage report, ${COVERAGE_MISSING}")
    endif()
  else()
    message(FATAL_ERROR "No code coverage report, unsupported compiler")
  endif()

  # success!
  set(CMAKE_CXX_FLAGS_DEBUG
    "${CMAKE_CXX_FLAGS_DEBUG} -fprofile-arcs -ftest-coverage")
  set(CMAKE_C_FLAGS_DEBUG
    "${CMAKE_C_FLAGS_DEBUG} -fprofile-arcs -ftest-coverage")
endif()
