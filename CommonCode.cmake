# Common.cmake include and cpp files and setting, do not use directly

set(OUTPUT_INCLUDE_DIR ${PROJECT_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${OUTPUT_INCLUDE_DIR})
include_directories(BEFORE ${PROJECT_SOURCE_DIR} ${OUTPUT_INCLUDE_DIR})

set(PROJECT_INCLUDE_NAME ${${UPPER_PROJECT_NAME}_INCLUDE_NAME})
set(PROJECT_namespace ${${UPPER_PROJECT_NAME}_namespace})

if(NOT PROJECT_INCLUDE_NAME)
  set(PROJECT_INCLUDE_NAME ${LOWER_PROJECT_NAME})
endif()
if(NOT PROJECT_namespace)
  set(PROJECT_namespace ${PROJECT_INCLUDE_NAME})
endif()
string(TOUPPER ${PROJECT_namespace} PROJECT_NAMESPACE)
