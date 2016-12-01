# Copyright (c) 2014-2016 Stefan.Eilemann@epfl.ch
#                         Raphael.Dumusc@epfl.ch

# Provides install_dependencies(name) to ease the installation of the system
# packages that a project declares as dependencies.
#
# Usage: install_dependencies(<name>)
# Installs a list of packages using a system-specific package manager.
#
# Input variables
# - ${NAME}_<type>_DEPENDS - the list of packages to install, where <type> is
#  automatically determined and can be one of:
#   - DEB (apt-get)
#   - RPM (yum)
#   - PORT (port, OSX)
#
# Example usage
# set(HELLO_DEB_DEPENDS qtbase5-dev)
# set(HELLO_PORT_DEPENDS qt5)
# install_dependencies(hello)

function(install_dependencies name)
  string(TOUPPER ${name} NAME)

  # Detect the package manager to use
  if(NOT DEFINED __pkg_mng)
    if(CMAKE_SYSTEM_NAME MATCHES "Linux" )
      find_program(__pkg_mng apt-get)
      if(__pkg_mng)
        set(__pkg_type DEB)
      else()
        find_program(__pkg_mng yum)
        if(__pkg_mng)
          set(__pkg_type RPM)
        endif()
      endif()
    elseif(APPLE)
      find_program(__pkg_mng port)
      if(__pkg_mng)
        set(__pkg_type PORT)
      endif()
    endif()

    if(NOT __pkg_mng)
      message(WARNING "Could not find the package manager tool for installing dependencies in this system")
    endif()

    # Cache variables to do the detection only once, but hide them so they don't
    # appear in ccmake.
    set(__pkg_mng ${__pkg_mng} CACHE INTERNAL "")
    set(__pkg_type ${__pkg_type} CACHE INTERNAL "")
  endif()

  if(NOT __pkg_mng OR NOT ${NAME}_${__pkg_type}_DEPENDS)
    return()
  endif()

  message("Installing '${NAME}_${__pkg_type}_DEPENDS'")

  # add common build requirements
  if(__pkg_type STREQUAL DEB)
    set(_dependencies cmake ccache doxygen git git-review graphviz
      ninja-build pkg-config lcov cppcheck clang clang-format-3.5)
  elseif(APPLE)
    set(_dependencies cppcheck)
  else()
    set(_dependencies)
  endif()

  list(APPEND _dependencies ${${NAME}_${__pkg_type}_DEPENDS})
  list(SORT _dependencies)
  list(REMOVE_DUPLICATES _dependencies)

  if(CMAKE_SYSTEM_NAME MATCHES "Linux")
    message("Running 'sudo ${__pkg_mng} install ${_dependencies}'")
    execute_process(COMMAND sudo ${__pkg_mng} install ${_dependencies})
  elseif(APPLE)
    set(_universal_ports)
    foreach(_port ${_dependencies})
      list(APPEND _universal_ports ${_port} +universal)
    endforeach()
    message("Running 'sudo port install ${_dependencies} (+universal)'")
    execute_process(COMMAND sudo port install -p ${_universal_ports})
  endif()
endfunction()
