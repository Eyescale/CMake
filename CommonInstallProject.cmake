# Copyright (c) 2017 Stefan.Eilemann@epfl.ch
#
# Generates ${PROJECT_NAME}-install rule. Adds common_add_install_dependencies
# function which takes a list of dependencies and adds their install target to
# the project install, if available.
#
# This rule is for targets which depend on the installed artefacts, e.g.,
# doxygen and smoke tests. CMake does not provide this, so this is a workaround.
# install naturally depends on all, which depends on all common_library and
# common_application targets. Furthermore, ${PROJECT_NAME}-install depends on
# all subprojects which have an install rule, so that all necessary artefacts in
# a superproject build are installed. The list of subprojects is extracted from
# ${PROJECT_NAME}_FIND_PACKAGES_FOUND, set by common_find_package.

if(NOT TARGET ${PROJECT_NAME}-install)
  add_custom_target(${PROJECT_NAME}-install
    ${CMAKE_COMMAND} -P ${PROJECT_BINARY_DIR}/cmake_install.cmake
    DEPENDS ${PROJECT_NAME}-all)
  set_target_properties(${PROJECT_NAME}-install PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON)
endif()

function(COMMON_ADD_INSTALL_DEPENDENCIES)
  string(REPLACE " " ";" __deps "${ARGN}") # string-to-list
  foreach(__dep ${__deps})
    if(TARGET ${PROJECT_NAME}-install AND TARGET ${__dep}-install)
      add_dependencies(${PROJECT_NAME}-install ${__dep}-install)
    endif()
  endforeach()
endfunction()
