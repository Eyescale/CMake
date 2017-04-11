# Copyright (c) 2013-2017 Stefan.Eilemann@epfl.ch
#                         Raphael.Dumusc@epfl.ch
#
# Info: http://www.itk.org/Wiki/CMake:Component_Install_With_CPack
#
# Configures the packaging of the project using CPack.
#
# Also includes CommonPackageConfig (legacy, to be removed in the future).
#
# Input
# * UPPER_PROJECT_NAME           used as "NAME" for other input below
# * LOWER_PROJECT_NAME           used as package name on Linux
# * NAME_LICENSE                 package license (e.g. "LGPL")
# * NAME_MAINTAINER              contact information (e.g. "Name <name@xy.org>")
# * NAME_URL                     homepage of the project (from GitHubInfo.cmake)
# * NAME_VENDOR                  organisation name (e.g. "Eyescale")
# * NAME_PACKAGE_DEB_DEPENDS     list of required deb packages
# * NAME_PACKAGE_RPM_DEPENDS     list of required rpm packages
# * NAME_PACKAGE_REPLACES        list of packages replaced by this (optional)
# * NAME_PACKAGE_CONFLICTS       list of conflicting packages (optional)
# * NAME_PACKAGE_USE_ABI         add ABI version to package name (default: OFF)
#
# Input with defaults
# * CPACK_COMPONENTS_ALL         default: apps dev doc examples lib unspecified
# * CPACK_PACKAGE_FILE_NAME      default: follow platform-specific convention
# * CPACK_RESOURCE_FILE_LICENSE  default: ${PROJECT_SOURCE_DIR}/LICENSE.txt
#
# Cached input
# * COMMON_PACKAGE_RELEASE       extra version number for re-releasing a package

include(CommonPackageConfig)

# No support for subproject packaging
if(NOT PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  return()
endif()

# MSVC: add compiler-provided system runtime libraries to install(PROGRAMS ...)
include(InstallRequiredSystemLibraries)

set(COMMON_PACKAGE_RELEASE "" CACHE
  STRING "Additional version number when re-releasing an existing package")
mark_as_advanced(COMMON_PACKAGE_RELEASE)

function(common_cpack_determine_generator OUTPUT_GENERATOR)
  # Heuristics to figure out cpack generator
  if(MSVC)
    set(CPACK_GENERATOR "NSIS")
    set(CPACK_NSIS_MODIFY_PATH ON)
  elseif(APPLE)
    set(CPACK_GENERATOR "PackageMaker")
    set(CPACK_OSX_PACKAGE_VERSION "${${UPPER_PROJECT_NAME}_OSX_VERSION}")
  else() # Linux
    include(LSBInfo)
    if(LSB_DISTRIBUTOR_ID MATCHES "Ubuntu")
      set(CPACK_GENERATOR "DEB")
    elseif(LSB_DISTRIBUTOR_ID MATCHES "RedHatEnterpriseServer")
      set(CPACK_GENERATOR "RPM")
    else()
      find_program(DEB_EXE debuild)
      find_program(RPM_EXE rpmbuild)
      if(DEB_EXE)
        set(CPACK_GENERATOR "DEB")
      elseif(RPM_EXE)
        set(CPACK_GENERATOR "RPM")
      else()
        set(CPACK_GENERATOR "TGZ")
      endif()
    endif()
  endif()
  set(${OUTPUT_GENERATOR} ${CPACK_GENERATOR} PARENT_SCOPE)
endfunction()

macro(common_cpack_set_base_parameters)
  if(NOT CPACK_PACKAGE_NAME)
    if(CMAKE_SYSTEM_NAME MATCHES "Linux")
      set(CPACK_PACKAGE_NAME ${LOWER_PROJECT_NAME})
    else()
      set(CPACK_PACKAGE_NAME ${PROJECT_NAME}) # default CPack behaviour
    endif()
  endif()

  if(NOT CPACK_PACKAGE_VENDOR)
    set(CPACK_PACKAGE_VENDOR ${${UPPER_PROJECT_NAME}_VENDOR})
  endif()

  set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
  set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
  set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})

  if(COMMON_PACKAGE_RELEASE)
    set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION}-${COMMON_PACKAGE_RELEASE})
  else()
    set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
  endif()

  if(NOT CPACK_PACKAGE_CONTACT)
    set(CPACK_PACKAGE_CONTACT ${${UPPER_PROJECT_NAME}_MAINTAINER})
  endif()

  if(NOT CPACK_PACKAGE_DESCRIPTION_SUMMARY)
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY ${${UPPER_PROJECT_NAME}_DESCRIPTION})
  endif()

  set(CPACK_STRIP_FILES TRUE) # strip binaries from symbols of other arch
endmacro()

macro(common_cpack_set_components_all NAME)
  set(CPACK_COMPONENTS_ALL apps dev doc examples lib unspecified)

  set(CPACK_COMPONENT_APPS_DISPLAY_NAME "${NAME} Applications")
  set(CPACK_COMPONENT_APPS_DESCRIPTION "${NAME} Applications")
  set(CPACK_COMPONENT_APPS_DEPENDS lib)

  set(CPACK_COMPONENT_DEV_DISPLAY_NAME "${NAME} Development Files")
  set(CPACK_COMPONENT_DEV_DESCRIPTION
    "Header and Library Files for ${NAME} Development")
  set(CPACK_COMPONENT_DEV_DEPENDS lib)

  set(CPACK_COMPONENT_DOC_DISPLAY_NAME "${NAME} Documentation")
  set(CPACK_COMPONENT_DOC_DESCRIPTION "${NAME} Documentation")
  set(CPACK_COMPONENT_DOC_DEPENDS lib)

  set(CPACK_COMPONENT_EXAMPLES_DISPLAY_NAME "${NAME} Examples")
  set(CPACK_COMPONENT_EXAMPLES_DESCRIPTION "${NAME} Example Source Code")
  set(CPACK_COMPONENT_EXAMPLES_DEPENDS dev)

  set(CPACK_COMPONENT_LIB_DISPLAY_NAME "${NAME} Libraries")
  set(CPACK_COMPONENT_LIB_DESCRIPTION "${NAME} Runtime Libraries")

  set(CPACK_COMPONENT_UNSPECIFIED_DISPLAY_NAME "Unspecified")
  set(CPACK_COMPONENT_UNSPECIFIED_DESCRIPTION
    "Unspecified Component - set COMPONENT in CMake install() command")
endmacro()

function(get_old_package_names PACKAGE_NAME ABI_VERSION OUTPUT)
  math(EXPR _num_old_packages "${ABI_VERSION} - 1")
  set(_old_packages)
  foreach(i RANGE ${_num_old_packages})
    list(APPEND _old_packages "${PACKAGE_NAME}${i}")
  endforeach()
  list(APPEND _old_packages "${PACKAGE_NAME}")
  set(${OUTPUT} ${_old_packages} PARENT_SCOPE)
endfunction()

function(get_debian_arch OUTPUT)
  # Get debian architecture name, e.g. amd64. Reference:
  # https://www.debian.org/doc/debian-policy/ch-customized-programs.html#s-arch-spec
  execute_process(COMMAND dpkg --print-architecture OUTPUT_VARIABLE _deb_arch
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  set(${OUTPUT} ${_deb_arch} PARENT_SCOPE)
endfunction()

macro(list_to_string LIST)
  # Convert a list to a comma-separated string without duplicates
  if(${LIST})
    list(REMOVE_DUPLICATES ${LIST})
    string(REGEX REPLACE ";" ", " ${LIST} "${${LIST}}")
  endif()
endmacro()

# Setup all CPACK variables

common_cpack_set_base_parameters()

if(NOT CPACK_COMPONENTS_ALL)
  common_cpack_set_components_all(${PROJECT_NAME})
endif()

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  # Legacy?
  if(EXISTS ${PROJECT_SOURCE_DIR}/CMake/${PROJECT_NAME}.in.spec)
    configure_file(${PROJECT_SOURCE_DIR}/CMake/${PROJECT_NAME}.in.spec
      ${PROJECT_SOURCE_DIR}/CMake/${PROJECT_NAME}.spec @ONLY)
  endif()

  # Optional: append ABI version to package name and make a list of old packages
  if(${UPPER_PROJECT_NAME}_PACKAGE_USE_ABI AND ${PROJECT_NAME}_VERSION_ABI)
    set(_abi_version ${${PROJECT_NAME}_VERSION_ABI})
    get_old_package_names(${CPACK_PACKAGE_NAME} ${_abi_version} _old_packages)
    set(CPACK_PACKAGE_NAME "${CPACK_PACKAGE_NAME}${_abi_version}")
  endif()

  # Convert PACKAGE_[REPLACES|CONFLICTS] list to string format without duplicate
  set(_package_replaces ${${UPPER_PROJECT_NAME}_PACKAGE_REPLACES})
  list(APPEND _package_replaces ${_old_packages}) # TODO is this really needed?
  list_to_string(_package_replaces)

  set(_package_conflicts ${${UPPER_PROJECT_NAME}_PACKAGE_CONFLICTS})
  list_to_string(_package_conflicts)
endif()

common_cpack_determine_generator(CPACK_GENERATOR)

# DEB + RPM specific settings

if(CPACK_GENERATOR STREQUAL "DEB")

  # Follow Debian package naming conventions:
  # https://www.debian.org/doc/manuals/debian-faq/ch-pkg_basics.en.html
  # Build version, e.g. name_1.3.2~xenial_amd64 or name_1.3.2-1~xenial_amd64
  # when re-releasing.
  # Note: the ~codename is not part of any standard and could be omitted.
  if(NOT CPACK_DEBIAN_PACKAGE_VERSION)
    include(LSBInfo)
    set(CPACK_DEBIAN_PACKAGE_VERSION "${CPACK_PACKAGE_VERSION}~${LSB_CODENAME}")
  endif()
  if(NOT CPACK_PACKAGE_FILE_NAME)
    get_debian_arch(_deb_arch)
    set(CPACK_PACKAGE_FILE_NAME
      "${CPACK_PACKAGE_NAME}_${CPACK_DEBIAN_PACKAGE_VERSION}_${_deb_arch}")
  endif()

  if(NOT CPACK_DEBIAN_BUILD_DEPENDS)
    set(CPACK_DEBIAN_BUILD_DEPENDS cmake doxygen git graphviz pkg-config
      ${${UPPER_PROJECT_NAME}_DEB_DEPENDS})
  endif()
  if(NOT CPACK_DEBIAN_PACKAGE_CONFLICTS)
    set(CPACK_DEBIAN_PACKAGE_CONFLICTS ${_package_conflicts})
  endif()
  if(NOT DEFINED CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA)
    # script name must be 'postinst' to avoid lintian W: "unknown-control-file"
    set(_ldconfig_script "${CMAKE_CURRENT_LIST_DIR}/postinst")
    set(CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${_ldconfig_script};")
  endif()
  if(NOT CPACK_DEBIAN_PACKAGE_DEPENDS)
    set(CPACK_DEBIAN_PACKAGE_DEPENDS ${${UPPER_PROJECT_NAME}_PACKAGE_DEB_DEPENDS})
    list_to_string(CPACK_DEBIAN_PACKAGE_DEPENDS)
  endif()
  if(NOT CPACK_DEBIAN_PACKAGE_HOMEPAGE)
    set(CPACK_DEBIAN_PACKAGE_HOMEPAGE ${${UPPER_PROJECT_NAME}_URL})
  endif()
  if(NOT CPACK_DEBIAN_PACKAGE_REPLACES)
    set(CPACK_DEBIAN_PACKAGE_REPLACES ${_package_replaces})
  endif()

elseif(CPACK_GENERATOR STREQUAL "RPM")

  set(CPACK_PACKAGE_FILE_NAME
    "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}.${CMAKE_SYSTEM_PROCESSOR}")

  set(_package_license ${${UPPER_PROJECT_NAME}_LICENSE})
  if(NOT _package_license)
    message(FATAL_ERROR "Missing Package License")
  endif()

  set(CPACK_RPM_PACKAGE_CONFLICTS ${_package_conflicts})
  set(CPACK_RPM_PACKAGE_GROUP "Development/Libraries")
  set(CPACK_RPM_PACKAGE_LICENSE ${_package_license})
  set(CPACK_RPM_PACKAGE_OBSOLETES ${_package_replaces})
  set(CPACK_RPM_PACKAGE_RELEASE ${COMMON_PACKAGE_RELEASE})
  set(CPACK_RPM_PACKAGE_URL ${${UPPER_PROJECT_NAME}_URL})
  set(CPACK_RPM_PACKAGE_VERSION ${PROJECT_VERSION})
  if(NOT CPACK_RPM_PACKAGE_REQUIRES)
    set(CPACK_RPM_PACKAGE_REQUIRES ${${UPPER_PROJECT_NAME}_PACKAGE_RPM_DEPENDS})
    list_to_string(CPACK_RPM_PACKAGE_REQUIRES)
  endif()
  if(NOT CPACK_RPM_POST_INSTALL_SCRIPT_FILE)
    set(_ldconfig_script "${CMAKE_CURRENT_LIST_DIR}/rpmPostInstall.sh")
    set(CPACK_RPM_POST_INSTALL_SCRIPT_FILE "${_ldconfig_script}")
  endif()

else() # NSIS / WIX / etc

  if(NOT CPACK_RESOURCE_FILE_LICENSE)
    set(CPACK_RESOURCE_FILE_LICENSE ${PROJECT_SOURCE_DIR}/LICENSE.txt)
  endif()
  if(NOT EXISTS ${CPACK_RESOURCE_FILE_LICENSE})
    message(AUTHOR_WARNING
      "${CPACK_RESOURCE_FILE_LICENSE} file not found, provide one or set "
      "CPACK_RESOURCE_FILE_LICENSE to point to an existing one.")
  endif()

endif()

include(CPack)
