# Common settings
#
# Input variables
# - INSTALL_PACKAGES: command line cache variable which will "apt-get", "yum" or
#   "port install" the known system packages. This variable is unset after this
#   script is parsed by top level project. See InstallDependencies for details.
#
# Output variables
# - UPPER_PROJECT_NAME - upper-case ${PROJECT_NAME}
# - LOWER_PROJECT_NAME - lower-case ${PROJECT_NAME}
# - TRAVIS - if environment is travis build system
# - BLUEGENE - if machine is BlueGene
# - LINUX - if machine is Linux
# - LINUX_PPC - if machine is PowerPC Linux
# - COMMON_DOC_DIR - folder for documentation, share/${PROJECT_NAME}/doc
# - COMMON_OSX_TARGET_VERSION - OS X target version
#
# Output targets
# - A <project>-all target to build only the given (sub)project
# - A <project>-install target to build and install the given (sub)project

cmake_minimum_required(VERSION 3.1 FATAL_ERROR)

if(CMAKE_INSTALL_PREFIX STREQUAL PROJECT_BINARY_DIR)
  message(FATAL_ERROR "Cannot install into build directory")
endif()

cmake_policy(SET CMP0020 NEW) # Automatically link Qt executables to qtmain target on Windows.
cmake_policy(SET CMP0037 NEW) # Target names should not be reserved and should match a validity pattern.
cmake_policy(SET CMP0038 NEW) # Targets may not link directly to themselves.
cmake_policy(SET CMP0048 NEW) # The project() command manages VERSION variables.
cmake_policy(SET CMP0054 OLD) # Only interpret if() arguments as variables or keywords when unquoted.

# WAR for CMake >=3.1 bug (observed with 3.2.3)
# If not set to false, any call to pkg_check_modules() or pkg_search_module()
# ERASES the $ENV{PKG_CONFIG_PATH}, so subsequent calls may fail to locate
# a dependency which depends on this variable (e.g. in FindPoppler.cmake).
set(PKG_CONFIG_USE_CMAKE_PREFIX_PATH FALSE)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)  # -fPIC
set(CMAKE_INSTALL_MESSAGE LAZY) # no up-to-date messages on installation
set(CMAKE_CXX_STANDARD_REQUIRED ON) # value of CXX_STANDARD on targets is required
set_property(GLOBAL PROPERTY USE_FOLDERS ON) # organize targets into folders
enable_testing()

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

if(MSVC)
  set(CMAKE_MODULE_INSTALL_PATH ${PROJECT_NAME}/CMake)
else()
  set(CMAKE_MODULE_INSTALL_PATH share/${PROJECT_NAME}/CMake)
endif()

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT AND NOT MSVC)
  set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH
    "${PROJECT_NAME} install prefix" FORCE)
endif()

# Linux libraries must have an SONAME to expose their ABI version to users.
# If VERSION_ABI has not been declared, use the following common conventions:
# - ABI version matches MAJOR version (ABI only changes with MAJOR releases)
# - MINOR and PATCH releases preserve backward ABI compatibility
# - PATCH releases preserve forward+backward API compatibility (no new features)
if(NOT DEFINED ${PROJECT_NAME}_VERSION_ABI)
  set(${PROJECT_NAME}_VERSION_ABI ${${PROJECT_NAME}_VERSION_MAJOR})
  message(STATUS "VERSION_ABI not set for ${PROJECT_NAME}. Using VERSION_MAJOR=${${PROJECT_NAME}_VERSION_MAJOR} as the ABI version.")
endif()

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  include(LSBInfo)
  set(LINUX TRUE)
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "ppc")
    set(LINUX_PPC 1)
  endif()
elseif(APPLE)
  cmake_policy(SET CMP0042 NEW) # MACOSX_RPATH is enabled by default.
  execute_process(COMMAND sw_vers -productVersion OUTPUT_VARIABLE OSX_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  list(APPEND CMAKE_PREFIX_PATH /opt/local/ /opt/local/lib
    /opt/local/libexec/qt5-mac) # Macports
  set(ENV{PATH} "/opt/local/bin:$ENV{PATH}") # dito
  if(NOT CMAKE_OSX_ARCHITECTURES OR CMAKE_OSX_ARCHITECTURES STREQUAL "")
    set(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE
      STRING "Build architectures for OS X" FORCE)
  endif()
  # https://cmake.org/Bug/view.php?id=15953
  if(CMAKE_VERSION VERSION_LESS 3.6)
    set(CMAKE_INCLUDE_SYSTEM_FLAG_C "-isystem ")
    set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX "-isystem ")
  endif()
  if(NOT CMAKE_INSTALL_NAME_DIR)
    set(CMAKE_INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib")
  endif()
  if(CMAKE_OSX_DEPLOYMENT_TARGET)
    set(COMMON_OSX_TARGET_VERSION ${CMAKE_OSX_DEPLOYMENT_TARGET})
  else()
    execute_process(COMMAND sw_vers -productVersion
      OUTPUT_VARIABLE COMMON_OSX_TARGET_VERSION)
  endif()
elseif(IS_DIRECTORY "/bgsys")
  set(BLUEGENE TRUE)
endif()

if($ENV{TRAVIS})
  set(TRAVIS ON)
endif()

string(TOUPPER ${PROJECT_NAME} UPPER_PROJECT_NAME)
string(TOLOWER ${PROJECT_NAME} LOWER_PROJECT_NAME)

set(PROJECT_INCLUDE_NAME ${${UPPER_PROJECT_NAME}_INCLUDE_NAME})
if(NOT PROJECT_INCLUDE_NAME)
  set(PROJECT_INCLUDE_NAME ${LOWER_PROJECT_NAME})
endif()

set(PROJECT_namespace ${${UPPER_PROJECT_NAME}_namespace})
if(NOT PROJECT_namespace)
  set(PROJECT_namespace ${PROJECT_INCLUDE_NAME})
endif()

if(NOT TARGET ${PROJECT_NAME}-all)
  # Create <project>-all target. Deps are added by common_lib/app/test macros
  add_custom_target(${PROJECT_NAME}-all)
  set_target_properties(${PROJECT_NAME}-all PROPERTIES FOLDER ${PROJECT_NAME})
endif()

set(COMMON_DOC_DIR share/${PROJECT_NAME}/doc)

include(ChoosePython) # Must be before any find_package to python
include(CommonFindPackage)

# OPT: reduce CMake runtime by finding Doxygen only once per superproject, not
# in every include of Doxygen.cmake
if(NOT DOXYGEN_FOUND)
  find_package(Doxygen QUIET)
endif()

include(CommonApplication)
include(CommonInstall)
include(CommonInstallProject)
include(CommonLibrary)
include(CommonCompiler)
include(CommonCoverage)
include(CommonSmokeTest)
include(GitInfo)
include(GitTargets)
include(GitHooks)
include(ProjectInfo)

if(INSTALL_PACKAGES)
  include(InstallDependencies)
  install_dependencies(${PROJECT_NAME})
endif()

include(SubProject)

if(NOT ${PROJECT_NAME}_IS_SUBPROJECT)
  # If this variable was given in the command line, ensure that the package
  # installation is only run in this cmake invocation.
  unset(INSTALL_PACKAGES CACHE)
endif()
