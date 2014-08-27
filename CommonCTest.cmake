# Copyright (c) 2010 Daniel Pfeifer
#               2010-2014, Stefan Eilemann <eile@eyescale.ch>
#               2014, Juan Hernando <jhernando@fi.upm.es>

include(CommonCPPCTest)

if(NOT TARGET tests)
  add_custom_target(tests)
  set_target_properties(tests PROPERTIES FOLDER "Tests")
endif()

if(COVERAGE)
  coverage_report(run_cpp_tests)
  # workaround: 'make test' does not build tests beforehand
  add_custom_target(${PROJECT_NAME}_tests DEPENDS lcov-html)
else()
  add_custom_target(${PROJECT_NAME}_tests DEPENDS run_cpp_tests)
endif()

set_target_properties(${PROJECT_NAME}_tests PROPERTIES FOLDER "Tests")
add_dependencies(tests ${PROJECT_NAME}_tests)
