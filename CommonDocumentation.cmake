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
# * DOXYGIT_MAX_VERSIONS number of versions to keep in directory (default: 10)
# * DOXYGIT_TOC_POST html content to insert in 'index.html' (default: '')
#
# * COMMON_INSTALL_DOCUMENTATION if set to ON, generate a 'make install' target
#   which installs all the documentation under share/${PROJECT_NAME}/.
#   Default: OFF because it is called by each dependant project when doing a
#   regular release build using Buildyard, which can be very time consuming.

function(COMMON_DOCUMENTATION)
  add_custom_target(${PROJECT_NAME}_doxygit
    COMMAND ${CMAKE_COMMAND}
    -DPROJECT_NAME="${PROJECT_NAME}"
    -DDOXYGIT_TOC_POST:STRING="${DOXYGIT_TOC_POST}"
    -DDOXYGIT_MAX_VERSIONS="${DOXYGIT_MAX_VERSIONS}"
    -P "${PROJECT_SOURCE_DIR}/CMake/common/Doxygit.cmake"
    COMMENT "Updating documentation in ${PROJECT_SOURCE_DIR}"
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")

  # For meta project, separate doxygit and ${PROJECT_NAME}_doxygit
  if(NOT TARGET doxygit)
    add_custom_target(doxygit)
  endif()
  add_dependencies(doxygit ${PROJECT_NAME}_doxygit)

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
