# Copyright (c) 2010 Daniel Pfeifer
#               2010-2014, Stefan Eilemann <eile@eyescale.ch>
#               2014, Juan Hernando <jhernando@fi.upm.es>

include(CommonCPPCTest)

if(NOT TARGET tests)
  add_custom_target(tests)
  set_target_properties(tests PROPERTIES FOLDER "Tests")
endif()
if(NOT TARGET ${PROJECT_NAME}_tests)
  add_custom_target(${PROJECT_NAME}_tests DEPENDS ${PROJECT_NAME}_run_cpp_tests)
  set_target_properties(${PROJECT_NAME}_tests PROPERTIES FOLDER "Tests")
  add_dependencies(tests ${PROJECT_NAME}_tests)
endif()

if(COVERAGE)
  coverage_report(${PROJECT_NAME}_run_cpp_tests)
endif()
