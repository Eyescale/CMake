# Copyright (c) 2010 Daniel Pfeifer
#               2010-2015, Stefan Eilemann <eile@eyescale.ch>
#               2014, Juan Hernando <jhernando@fi.upm.es>

if(NOT TARGET tests)
  add_custom_target(tests)
endif()
if(NOT TARGET perftests)
  add_custom_target(perftests)
endif()
if(NOT TARGET ${PROJECT_NAME}-tests)
  add_custom_target(${PROJECT_NAME}-tests)
endif()

set_target_properties(tests PROPERTIES
  EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)
set_target_properties(perftests PROPERTIES
  EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)
set_target_properties(${PROJECT_NAME}-tests PROPERTIES
  EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)

add_dependencies(tests ${PROJECT_NAME}-tests)

include(CommonCPPCTest)
