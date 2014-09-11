# Copyright (c) 2012-2014 Raphael Dumusc <raphael.dumusc@epfl.ch>

# Used by documentation projects and by DoxygenRule to setup a 'doxygit' target

# Configure the build for a documentation project:
#   common_documentation()

function(COMMON_DOCUMENTATION)
  add_doxygit_target(${PROJECT_NAME} ${PROJECT_SOURCE_DIR})

  file(GLOB Folders RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *-*)

  foreach(FOLDER ${Folders})
    install(DIRECTORY ${FOLDER} DESTINATION share/${PROJECT_NAME}
      CONFIGURATIONS Release)
  endforeach()
  # need at least one file for 'make install'
  install(FILES index.html DESTINATION share/${PROJECT_NAME}
    CONFIGURATIONS Release)

endfunction()

# Add a 'doxygit' target for a documentation git repo:
#   add_doxygit_target(<DocumentationName> <GitDocumentationDir>)
#
# The doxygit target executes Doxygit.cmake as a script in the source directory
# of a documentation project to update the index page, remove outdated versions
# and 'git add' the changes.
#
# Optional Input Variables:
# * DOXYGIT_MAX_VERSIONS number of versions to keep in directory (default: 10)
# * DOXYGIT_TOC_POST html content to insert in 'index.html' (default: '')

function(ADD_DOXYGIT_TARGET DocumentationName GitDocumentationDir)
  add_custom_target(${PROJECT_NAME}_doxygit
    COMMAND ${CMAKE_COMMAND}
    -DPROJECT_NAME="${DocumentationName}"
    -DPROJECT_BINARY_DIR="${PROJECT_BINARY_DIR}"
    -DDOXYGIT_TOC_POST="${DOXYGIT_TOC_POST}"
    -DDOXYGIT_MAX_VERSIONS="${DOXYGIT_MAX_VERSIONS}"
    -P "${GitDocumentationDir}/CMake/common/Doxygit.cmake"
    COMMENT "Updating documentation in ${GitDocumentationDir}"
    WORKING_DIRECTORY "${GitDocumentationDir}")

  # For meta project, separate doxygit and ${PROJECT_NAME}_doxygit
  if(NOT TARGET doxygit)
    add_custom_target(doxygit)
  endif()
  add_dependencies(doxygit ${PROJECT_NAME}_doxygit)

endfunction()
