# Common.cmake include and cpp files and setting, do not use directly

include(GitInfo)

set(OUTPUT_INCLUDE_DIR ${PROJECT_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${OUTPUT_INCLUDE_DIR})
include_directories(BEFORE ${PROJECT_SOURCE_DIR} ${OUTPUT_INCLUDE_DIR})
if(NOT PROJECT_INCLUDE_NAME)
  set(PROJECT_INCLUDE_NAME ${LOWER_PROJECT_NAME})
endif()
if(NOT PROJECT_namespace)
  set(PROJECT_namespace ${PROJECT_INCLUDE_NAME})
endif()
string(TOUPPER ${PROJECT_namespace} PROJECT_NAMESPACE)

configure_file(${CMAKE_CURRENT_LIST_DIR}/cpp/api.h
  ${PROJECT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/api.h @ONLY)
configure_file(${CMAKE_CURRENT_LIST_DIR}/cpp/defines.h
  ${PROJECT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/defines.h @ONLY)
configure_file(${CMAKE_CURRENT_LIST_DIR}/cpp/version.h
  ${PROJECT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/version.h @ONLY)
configure_file(${CMAKE_CURRENT_LIST_DIR}/cpp/version.cpp
  ${PROJECT_BINARY_DIR}/version.cpp @ONLY)

list(APPEND COMMON_INCLUDES
  ${PROJECT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/api.h
  ${PROJECT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/defines.h
  ${PROJECT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/version.h)
list(APPEND COMMON_SOURCES ${PROJECT_BINARY_DIR}/version.cpp)
