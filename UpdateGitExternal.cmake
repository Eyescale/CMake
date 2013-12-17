# Updates GitExternal.cmake copy in source trees from the CMake repo
if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/GitExternal.cmake" AND
    EXISTS "${CMAKE_CURRENT_LIST_DIR}/../GitExternal.cmake")

  include(UpdateFile)
  update_file("${CMAKE_CURRENT_LIST_DIR}/GitExternal.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/../GitExternal.cmake")
endif()
