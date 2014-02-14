# Common.cmake include and cpp files and setting, do not use directly

include(GitInfo)
include(UpdateFile)

set(OUTPUT_INCLUDE_DIR ${CMAKE_BINARY_DIR}/include)
file(MAKE_DIRECTORY ${OUTPUT_INCLUDE_DIR})
include_directories(BEFORE ${CMAKE_SOURCE_DIR} ${OUTPUT_INCLUDE_DIR})
if(NOT PROJECT_INCLUDE_NAME)
  set(PROJECT_INCLUDE_NAME ${LOWER_PROJECT_NAME})
endif()

update_file(${CMAKE_CURRENT_LIST_DIR}/cpp/api.h
  ${CMAKE_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/api.h)
update_file(${CMAKE_CURRENT_LIST_DIR}/cpp/defines.h
  ${CMAKE_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/defines.h)
update_file(${CMAKE_CURRENT_LIST_DIR}/cpp/version.h
  ${CMAKE_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/version.h)
update_file(${CMAKE_CURRENT_LIST_DIR}/cpp/version.cpp
  ${CMAKE_CURRENT_BINARY_DIR}/version.cpp)

list(APPEND COMMON_INCLUDES
  ${CMAKE_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/api.h
  ${CMAKE_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/defines.h
  ${CMAKE_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/version.h)
list(APPEND COMMON_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/version.cpp)
