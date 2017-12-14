# Copyright (c) 2017 Raphael.Dumusc@epfl.ch
#
# Helper function for packaging subprojects using CommonCPack.
#
# Add subproject dependencies to the current project's package:
#   add_deb_depends(<Subproject>
#     [PACKAGE_NAME <subproject_package_name>]
#     [MIN_VERSION <subproject_min_version>] [<subproject_deb_depends>])
#
# Arguments:
# * Subproject: name of the subproject
# * PACKAGE_NAME: if subproject package name differs from lower_case(Subproject)
# * MIN_VERSION: minimum version of the subproject's package
# * ARGN: list of dependencies of the subproject
#
# Output (list append):
# * NAME_PACKAGE_REPLACES: Subproject package name if it is being built
# * NAME_PACKAGE_DEB_DEPENDS: the list of Subproject's dependencies if it is
#   being built; otherwise its package name.

macro(add_deb_depends Subproject)
  set(_opts)
  set(_singleArgs PACKAGE_NAME MIN_VERSION)
  set(_multiArgs)
  cmake_parse_arguments(THIS "${_opts}" "${_singleArgs}" "${_multiArgs}"
    ${ARGN})
  set(_packages ${THIS_UNPARSED_ARGUMENTS})

  if(THIS_PACKAGE_NAME)
    set(_subproject_pkg ${THIS_PACKAGE_NAME})
  else()
    string(TOLOWER ${Subproject} _subproject_pkg)
  endif()

  if(${Subproject}_IS_SUBPROJECT)
    list(APPEND ${UPPER_PROJECT_NAME}_PACKAGE_REPLACES ${_subproject_pkg})
    list(APPEND ${UPPER_PROJECT_NAME}_PACKAGE_DEB_DEPENDS ${_packages})
  else()
    if(THIS_MIN_VERSION)
      set(_subproject_pkg "${_subproject_pkg} (>= ${THIS_MIN_VERSION})")
    endif()
    list(APPEND ${UPPER_PROJECT_NAME}_PACKAGE_DEB_DEPENDS "${_subproject_pkg}")
  endif()
endmacro()
