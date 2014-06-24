
# Creates a FROM->TO symlink during installation
function(INSTALL_SYMLINK)
  cmake_parse_arguments(THIS "" "" "FROM;TO;WORKING_DIRECTORY;COMPONENT" ${ARGN})
  if(MSVC)
    install(CODE
      "message(\"mklink /j \${THIS_TO} \${THIS_FROM}\")
       execute_process(COMMAND mklink /j \${THIS_TO} \${THIS_FROM}
                       WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${THIS_WORKING_DIRECTORY})"
      COMPONENT "${THIS_COMPONENT}")
  else()
    install(CODE
      "execute_process(COMMAND rm -f ${THIS_TO}
                       WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${THIS_WORKING_DIRECTORY})
       execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink ${THIS_FROM} ${THIS_TO}
                       WORKING_DIRECTORY ${CMAKE_INSTALL_PREFIX}/${THIS_WORKING_DIRECTORY})"
      COMPONENT "${THIS_COMPONENT}")
  endif()
endfunction()
