
# Copyright (c) 2012-2013 Daniel Nachbaur <daniel.nachbaur@epfl.ch>

# Offers 'module' and 'snapshot' targets to create a GNU module
# (http://modules.sourceforge.net/) of your software. A regular module
# requires dependencies to be available as their own modules, whereas
# a snapshot module contains all dependencies. The first one is meant
# for full toolchain releases, the second one for intermediate feature
# snapshots.
#
# The GNUModules.cmake is supposed to be included after Common.cmake,
# CPackConfig.cmake and all targets to gather required variables from
# them.
#
# Following variables you can change to override defaults:
# - MODULE_ENV: default setup is:
#                 setenv ${UPPER_PROJECT_NAME}_INCLUDE_DIR  $root/include
#                 setenv ${UPPER_PROJECT_NAME}_ROOT         $root
#                 prepend-path PATH            $root/bin
#                 prepend-path LD_LIBRARY_PATH $root/lib
#                 prepend-path PYTHONPATH      $root/${PYTHON_LIBRARY_PREFIX}
#
# - MODULE_SW_BASEDIR: the directory for the module's binaries on a machine.
#                      default /usr/share/Modules
#
# - MODULE_SW_CLASS: the category/subdirectory inside the basedir for this software.
#                    default ${CPACK_PACKAGE_VENDOR}
#
# - MODULE_MODULEFILES: the directory for the modulefiles.
#                       default /usr/share/Modules/modulefiles
#
# - MODULE_WHATIS: the whatis description of the module.
#                  default ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}

if(MSVC OR APPLE)
  return()
endif()

# Need variables defined by (Common)CPackConfig
if(NOT CPACK_PACKAGE_VENDOR OR NOT CPACK_PACKAGE_DESCRIPTION_SUMMARY OR
   NOT VERSION)
  add_custom_target(module
    COMMENT "No module target, need CPACK_PACKAGE_VENDOR, CPACK_PACKAGE_DESCRIPTION_SUMMARY and VERSION")
  add_custom_target(snapshot
    COMMENT "No snapshot target, need CPACK_PACKAGE_VENDOR, CPACK_PACKAGE_DESCRIPTION_SUMMARY, VERSION and GIT_REVISION")
  return()
endif()

# Common file setup
################################################################################
if(NOT MODULE_ENV)
  string(TOUPPER ${PROJECT_NAME} UPPER_PROJECT_NAME)
  set(MODULE_ENV
    "setenv ${UPPER_PROJECT_NAME}_INCLUDE_DIR  $root/include\\n"
    "setenv ${UPPER_PROJECT_NAME}_ROOT         $root\\n\\n"
    "prepend-path PATH            $root/bin\\n"
    "prepend-path LD_LIBRARY_PATH $root/lib\\n")
  if(PYTHON_LIBRARY_PREFIX)
    list(APPEND MODULE_ENV
      "prepend-path PYTHONPATH      $root/${PYTHON_LIBRARY_PREFIX}\\n")
  endif()
endif()

# Load dependend modules if any
if(NOT MODULE_SNAPSHOT_DIR) # comes from Buildyard
  if(${UPPER_PROJECT_NAME}_DEPENDS)
    foreach(MODULE_DEP ${${UPPER_PROJECT_NAME}_DEPENDS})
      if(${MODULE_DEP}_MODULE_FILENAME) # comes from PackageConfig.cmake
        list(INSERT MODULE_ENV 0
          "module load ${${MODULE_DEP}_MODULE_FILENAME}\\n"
          "prereq      ${${MODULE_DEP}_MODULE_FILENAME}\\n\\n")
      endif()
    endforeach()
  endif()
endif()

string(REGEX REPLACE ";" "" MODULE_ENV ${MODULE_ENV})

if(NOT MODULE_SW_BASEDIR)
  set(MODULE_SW_BASEDIR $ENV{MODULE_SW_BASEDIR})
endif()
if(NOT MODULE_SW_BASEDIR)
  set(MODULE_SW_BASEDIR "/usr/share/modules")
endif()

if(NOT MODULE_SW_CLASS)
  set(MODULE_SW_CLASS ${CPACK_PACKAGE_VENDOR})
endif()
if(MODULE_SW_CLASS MATCHES "^http://")
  string(REGEX REPLACE "^http://(.*)" "\\1" MODULE_SW_CLASS ${MODULE_SW_CLASS})
endif()

if(NOT MODULE_MODULEFILES)
  set(MODULE_MODULEFILES "/usr/share/modules/modulefiles")
endif()

if(NOT MODULE_WHATIS)
  set(MODULE_WHATIS "${CPACK_PACKAGE_DESCRIPTION_SUMMARY}")
endif()

# get the used compiler + its version
get_filename_component(MODULE_COMPILER_NAME ${CMAKE_C_COMPILER} NAME CACHE)
include(CompilerVersion)
compiler_dumpversion(MODULE_COMPILER_VERSION)

# setup the module file content
set(MODULE_PACKAGE_NAME ${PROJECT_NAME})
set(MODULE_VERSION ${VERSION_MAJOR}.${VERSION_MINOR})
if(LSB_DISTRIBUTOR_ID MATCHES "RedHatEnterpriseServer")
  set(MODULE_PLATFORM "rhel${LSB_RELEASE}-${CMAKE_SYSTEM_PROCESSOR}")
elseif(LSB_DISTRIBUTOR_ID MATCHES "Ubuntu")
  set(MODULE_PLATFORM "ubuntu${LSB_RELEASE}-${CMAKE_SYSTEM_PROCESSOR}")
elseif(LSB_DISTRIBUTOR_ID MATCHES "Scientific")
  set(MODULE_PLATFORM "scientific${LSB_RELEASE}-${CMAKE_SYSTEM_PROCESSOR}")
elseif(LSB_DISTRIBUTOR_ID MATCHES "Arch")
  set(MODULE_PLATFORM "arch-${CMAKE_SYSTEM_PROCESSOR}")
elseif(APPLE)
  set(MODULE_PLATFORM "darwin${CMAKE_SYSTEM_VERSION}-${CMAKE_SYSTEM_PROCESSOR}")
else()
  message(WARNING "Unsupported platform for GNUModules, please add support here")
  return()
endif()
set(MODULE_COMPILER "${MODULE_COMPILER_NAME}${MODULE_COMPILER_VERSION}")
set(MODULE_ARCHITECTURE "$platform/$compiler")
set(MODULE_ROOT "$sw_basedir/$sw_class/$package_name/$version/$architecture")

include(WriteModuleFile)


# 'Regular' module
################################################################################
set(MODULE_PACKAGE_NAME ${PROJECT_NAME})
set(MODULE_VERSION ${VERSION_MAJOR}.${VERSION_MINOR})
set(MODULE_FILENAME "${MODULE_PACKAGE_NAME}/${MODULE_VERSION}-${MODULE_PLATFORM}-${MODULE_COMPILER}")
set(MODULE_SRC_INSTALL "${MODULE_SW_BASEDIR}/${MODULE_SW_CLASS}/${MODULE_PACKAGE_NAME}/${MODULE_VERSION}/${MODULE_PLATFORM}/${MODULE_COMPILER}")

get_property(INSTALL_DEPENDS GLOBAL PROPERTY ${PROJECT_NAME}_ALL_DEP_TARGETS)
add_custom_target(module_install
  COMMAND ${CMAKE_COMMAND} -DCMAKE_INSTALL_PREFIX=${MODULE_SRC_INSTALL} -P ${PROJECT_BINARY_DIR}/cmake_install.cmake
  COMMENT "Installing GNU module source at ${MODULE_SRC_INSTALL}" VERBATIM
  DEPENDS ${${PROJECT_NAME}_ALL_DEP_TARGETS})

add_custom_target(module
  COMMAND ${CMAKE_COMMAND} -DMODULE_PACKAGE_NAME=${MODULE_PACKAGE_NAME}
                           -DMODULE_VERSION=${MODULE_VERSION}
                           -DMODULE_FILENAME=${MODULE_FILENAME}
                           -P WriteModuleFile.cmake
  COMMAND ${CMAKE_COMMAND} -E copy ${MODULE_FILENAME} ${MODULE_MODULEFILES}/${MODULE_FILENAME}
  WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
  COMMENT "Creating GNU module ${MODULE_FILENAME} at ${MODULE_MODULEFILES}" VERBATIM
  DEPENDS module_install)

# 'return value' for metamodule
file(WRITE ${PROJECT_BINARY_DIR}/Module.txt "${MODULE_FILENAME}")

# Snapshot module
################################################################################
if(NOT GIT_REVISION OR NOT MODULE_SNAPSHOT_DIR)
  # MODULE_SNAPSHOT_DIR comes from Buildyard
  add_custom_target(snapshot
    COMMENT "No snapshot target, need GIT_REVISION and MODULE_SNAPSHOT_DIR")
  return()
endif()

execute_process(COMMAND date "+%Y-%m-%d" OUTPUT_VARIABLE MODULE_DATE
  OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND date "+%Y-%m-%d" "-d now + 6 months"
  OUTPUT_VARIABLE MODULE_EXPIRATION_DATE OUTPUT_STRIP_TRAILING_WHITESPACE)
set(MODULE_PACKAGE_NAME ${MODULE_PACKAGE_NAME}-snapshot)
set(MODULE_VERSION ${MODULE_VERSION}.${GIT_REVISION}-${MODULE_DATE})
set(MODULE_FILENAME "${MODULE_PACKAGE_NAME}/${MODULE_VERSION}-${MODULE_PLATFORM}-${MODULE_COMPILER}")
set(MODULE_SRC_INSTALL "${MODULE_SW_BASEDIR}/${MODULE_SW_CLASS}/${MODULE_PACKAGE_NAME}/${MODULE_VERSION}/${MODULE_PLATFORM}/${MODULE_COMPILER}")
set(MODULE_MESSAGE_AFTER_LOAD "Note: This module will expire on ${MODULE_EXPIRATION_DATE}")

add_custom_target(snapshot_install
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${MODULE_SNAPSHOT_DIR} ${MODULE_SRC_INSTALL}
  COMMENT "Installing snapshot module source at ${MODULE_SRC_INSTALL}" VERBATIM)

add_custom_target(snapshot
  COMMAND ${CMAKE_COMMAND} -DMODULE_PACKAGE_NAME=${MODULE_PACKAGE_NAME} -DMODULE_VERSION=${MODULE_VERSION} -DMODULE_FILENAME=${MODULE_FILENAME} -DMODULE_MESSAGE_AFTER_LOAD=${MODULE_MESSAGE_AFTER_LOAD} -P WriteModuleFile.cmake
  COMMAND ${CMAKE_COMMAND} -E copy ${MODULE_FILENAME} ${MODULE_MODULEFILES}/${MODULE_FILENAME}
  COMMAND ${CMAKE_COMMAND} -E create_symlink ${MODULE_MODULEFILES}/${MODULE_FILENAME} ${MODULE_MODULEFILES}/${MODULE_PACKAGE_NAME}/latest
  WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
  COMMENT "Creating snapshot module ${MODULE_FILENAME} at ${MODULE_MODULEFILES}"
  VERBATIM DEPENDS snapshot_install)
