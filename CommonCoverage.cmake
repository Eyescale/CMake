# Code coverage reporting
# - sets compiler flags to enable code coverage reporting (optional)
# - provides a function to add 'coverage' targets
#
# CMake options:
#   COMMON_ENABLE_COVERAGE Must be explicitly enabled by the user since adding
#   code coverage compiler flags may break downstream projects.
#
# Input variables:
# * LCOV_EXCLUDE Extra files to exclude from the coverage report
# * COVERAGE_LIMITS Optional genhml flags to tweak the color codes of the report
#
# Input global property:
# * COMMON_GENERATED_FILES: List of files to exclude from coverage report
# * ${PROJECT_NAME}_COVERAGE_INPUT_DIRS: List of BINARY_DIRs containing .gcda
#   files to generate the report. Filled by common_library() in
#   CommonLibrary.cmake.
#
# Targets generated:
# * ${PROJECT_NAME}-lcov-clean for internal use - clean before running cpptests
# * ${PROJECT_NAME}-lcov-gather for internal use
# * ${PROJECT_NAME}-lcov-remove for internal use
# * ${PROJECT_NAME}-coverage generate a coverage report for a specific project
# * coverage run all ${PROJECT_NAME}-coverage

option(COMMON_ENABLE_COVERAGE "Enable code coverage testing" OFF)

if(COMMON_ENABLE_COVERAGE)
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
    if(LCOV_VERSION VERSION_LESS 1.11)
      message(FATAL_ERROR "lcov >= 1.11 needed, found lcov ${LCOV_VERSION}")
    endif()
    if(NOT LCOV OR NOT GENHTML)
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

  if(COMMON_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR)
    message(WARNING "The coverage report for ${PROJECT_NAME} will include all "
                    "the subprojects present in PROJECT_SOURCE_DIR="
                    "'${PROJECT_SOURCE_DIR}'.\n"
                    "To avoid this, make sure the subprojects are located "
                    "outside of ${PROJECT_NAME}'s source tree by defining an "
                    "external COMMON_SOURCE_DIR at the CMake configure step.")
  endif()

  # success!
  set(CMAKE_CXX_FLAGS_DEBUG
    "${CMAKE_CXX_FLAGS_DEBUG} -fprofile-arcs -ftest-coverage")
  set(CMAKE_C_FLAGS_DEBUG
    "${CMAKE_C_FLAGS_DEBUG} -fprofile-arcs -ftest-coverage")
endif()

function(add_coverage_targets TEST_TARGET)
  if(NOT COVERAGE_LIMITS)
    # Tweak coverage limits to yellow 40%/green 80%
    set(COVERAGE_LIMITS --rc genhtml_med_limit=40 --rc genhtml_hi_limit=80)
  endif()

  if(NOT TARGET ${PROJECT_NAME}-lcov-clean)
    add_custom_target(${PROJECT_NAME}-lcov-clean
      COMMAND ${LCOV} -q --directory ${PROJECT_BINARY_DIR} --zerocounters
      COMMENT "Resetting code coverage counters")
  endif()
  add_dependencies(${TEST_TARGET} ${PROJECT_NAME}-lcov-clean)

  if(NOT TARGET ${PROJECT_NAME}-lcov-gather)
    # Only include coverage report files from all common_library() calls in the project
    get_property(__binary_dirs GLOBAL PROPERTY ${PROJECT_NAME}_COVERAGE_INPUT_DIRS)
    foreach(__binary_dir ${__binary_dirs})
      list(APPEND __directories --directory ${__binary_dir})
    endforeach()

    if(__directories)
      # Add the tests folder (needed for header-only/interface libraries);
      # lcov-gather needs to find at least one gdca file to generate lcov.info
      # and gdca files are only generated for source/cpp files.
      list(APPEND __directories --directory ${PROJECT_BINARY_DIR}/tests)
    else()
      # If no common_library() used, include every gcda file that's reachable
      # from the build dir
      list(APPEND __directories --directory ${PROJECT_BINARY_DIR})
    endif()
    # Allow all headers from the PROJECT_SOURCE_DIR. If subprojects are not
    # located outside of the source tree they will be part of the report.
    list(APPEND __directories --directory ${PROJECT_SOURCE_DIR})

    add_custom_target(${PROJECT_NAME}-lcov-gather
      COMMAND ${LCOV} -q --capture ${__directories} --no-external --output-file lcov.info
      COMMENT "Capturing code coverage counters"
      WORKING_DIRECTORY ${PROJECT_BINARY_DIR})
  endif()
  add_dependencies(${PROJECT_NAME}-lcov-gather ${TEST_TARGET})

  if(NOT TARGET ${PROJECT_NAME}-lcov-remove)
    get_property(GENERATED_FILES GLOBAL PROPERTY COMMON_GENERATED_FILES)
    # 'tests/*' excluded otherwise unit test source file coverage is produced
    add_custom_target(${PROJECT_NAME}-lcov-remove
      COMMAND ${LCOV} -q --remove lcov.info '*.l*' '*.y*' 'tests/*' 'CMake/test/*'
        '*/install/*' 'moc_*' 'qrc_*' ${GENERATED_FILES} ${LCOV_EXCLUDE}
        --output-file lcov2.info
      COMMENT "Cleaning up code coverage counters"
      WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
      DEPENDS ${PROJECT_NAME}-lcov-gather)
  endif()

  if(NOT TARGET ${PROJECT_NAME}-coverage)
    add_custom_target(${PROJECT_NAME}-coverage
      COMMAND ${GENHTML} -q --title ${PROJECT_NAME} ${COVERAGE_LIMITS}
        -o CoverageReport ${PROJECT_BINARY_DIR}/lcov2.info
      COMMENT "Creating html coverage report, open ${PROJECT_BINARY_DIR}/doc/html/CoverageReport/index.html "
      WORKING_DIRECTORY ${PROJECT_BINARY_DIR}/doc/html
      DEPENDS ${PROJECT_NAME}-lcov-remove)
    make_directory(${PROJECT_BINARY_DIR}/doc/html)
  endif()

  if(NOT TARGET coverage)
    add_custom_target(coverage)
  endif()
  add_dependencies(coverage ${PROJECT_NAME}-coverage)
endfunction()
