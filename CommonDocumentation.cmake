# Copyright (c) 2012-2014 Raphael Dumusc <raphael.dumusc@epfl.ch>

# Configure the build for a documentation project:
#   common_documentation()
#
# Generates:
# * doxygit target
# * install target (optional)
#
# The doxygit target executes Doxygit.cmake as a script in the source
# directory of the project. It updates the index page, removes outdated
# documentation folders and 'git add' the changes.
#
# Input (optional):
# * DOXYGIT_GENERATE_INDEX generate an index.html page (default: OFF)
# * DOXYGIT_MAX_VERSIONS number of versions to keep in directory (default: 10)
# * DOXYGIT_TOC_POST html content to insert in 'index.html' (default: '')
#
# * COMMON_INSTALL_DOCUMENTATION if set to ON, generate a 'make install' target
#   which installs all the documentation under share/${PROJECT_NAME}/.
#   Default: OFF because it is called by each dependant project when doing a
#   regular release build using Buildyard, which can be very time consuming.

function(COMMON_DOCUMENTATION)
  add_custom_target(${PROJECT_NAME}-doxygit ALL
    COMMAND ${CMAKE_COMMAND}
    -DPROJECT_NAME="${PROJECT_NAME}"
    -DDOXYGIT_GENERATE_INDEX="${DOXYGIT_GENERATE_INDEX}"
    -DDOXYGIT_TOC_POST:STRING="${DOXYGIT_TOC_POST}"
    -DDOXYGIT_MAX_VERSIONS="${DOXYGIT_MAX_VERSIONS}"
    -P "${CMAKE_SOURCE_DIR}/CMake/common/Doxygit.cmake"
    COMMENT "Updating ${PROJECT_NAME} pages in ${PROJECT_SOURCE_DIR}"
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")
  set_property(GLOBAL APPEND PROPERTY
    ${PROJECT_NAME}_ALL_DEP_TARGETS ${PROJECT_NAME}-doxygit)

  # For meta project, separate doxygit and ${PROJECT_NAME}-doxygit
  if(NOT TARGET doxygit)
    add_custom_target(doxygit ALL)
  endif()
  add_dependencies(doxygit ${PROJECT_NAME}-doxygit)

  if(COMMON_INSTALL_DOCUMENTATION)
    file(GLOB Folders RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *-*)

    foreach(FOLDER ${Folders})
      install(DIRECTORY ${FOLDER} DESTINATION share/${PROJECT_NAME}
        CONFIGURATIONS Release)
    endforeach()
    # need at least one file for 'make install'
    install(FILES index.html DESTINATION share/${PROJECT_NAME}
      CONFIGURATIONS Release)
  else()
    # Buildyard expects an install target for all projects
    install(CODE "MESSAGE(\"Nothing to install, done.\")")
  endif()
endfunction()
