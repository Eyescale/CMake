# Common settings
#
# Output variables
#   VERSION - ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}
#   UPPER_PROJECT_NAME - lower-case ${PROJECT_NAME}
#   LOWER_PROJECT_NAME - upper-case ${PROJECT_NAME}
#   TRAVIS - if environment is travis build system
#   BLUEGENE - if machine is BlueGene
#   LINUX - if machine is Linux
#   LINUX_PPC - if machine is PowerPC Linux
#   DOC_DIR - folder for documentation, share/${PROJECT_NAME}/doc
#

if(CMAKE_INSTALL_PREFIX STREQUAL PROJECT_BINARY_DIR)
  message(FATAL_ERROR "Cannot install into build directory")
endif()

cmake_minimum_required(VERSION 2.8.9 FATAL_ERROR)

string(TOUPPER ${PROJECT_NAME} UPPER_PROJECT_NAME)
string(TOLOWER ${PROJECT_NAME} LOWER_PROJECT_NAME)

include(ChoosePython) # Must be before any find_package to python

if(EXISTS ${PROJECT_SOURCE_DIR}/CMake/${PROJECT_NAME}.cmake)
  include(${PROJECT_SOURCE_DIR}/CMake/${PROJECT_NAME}.cmake)
endif()

include(CommonPackage)

enable_testing()
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_INSTALL_MESSAGE LAZY) # no up-to-date messages on installation

set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH})
add_definitions(-D${UPPER_PROJECT_NAME}_VERSION=${VERSION})
# Linux libraries must have an SONAME to expose their ABI version to users.
# If VERSION_ABI has not been declared, use the following common conventions:
# - ABI version matches MAJOR version (ABI only changes with MAJOR releases)
# - MINOR and PATCH releases preserve backward ABI compatibility
# - PATCH releases preseve forward+backward API compatibility (no new features)
if(NOT DEFINED VERSION_ABI)
  set(VERSION_ABI ${VERSION_MAJOR})
  message(STATUS "VERSION_ABI not set for ${PROJECT_NAME}. Using VERSION_MAJOR=${VERSION_MAJOR} as the ABI version.")
endif()

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT AND NOT MSVC)
  set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH
    "${PROJECT_NAME} install prefix" FORCE)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

set(DOC_DIR share/${PROJECT_NAME}/doc)
include(${CMAKE_CURRENT_LIST_DIR}/CMakeInstallPath.cmake)

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  include(LSBInfo)
  set(LINUX TRUE)
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "ppc")
    set(LINUX_PPC 1)
  else()
    add_definitions(-fPIC)
  endif()
endif()
set(LIBRARY_DIR lib)

if(APPLE)
  cmake_policy(SET CMP0042 NEW)
  list(APPEND CMAKE_PREFIX_PATH /opt/local/ /opt/local/lib
    /opt/local/libexec/qt5-mac) # Macports
  set(ENV{PATH} "/opt/local/bin:$ENV{PATH}") # dito
  if(NOT CMAKE_OSX_ARCHITECTURES OR CMAKE_OSX_ARCHITECTURES STREQUAL "")
    set(CMAKE_OSX_ARCHITECTURES "i386;x86_64" CACHE
      STRING "Build architectures for OS X" FORCE)
  endif()
  set(CMAKE_INCLUDE_SYSTEM_FLAG_C "-isystem ")
  set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX "-isystem ")
  if(NOT CMAKE_INSTALL_NAME_DIR)
    set(CMAKE_INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib")
  endif()
endif()
if(MSVC)
  # http://www.cmake.org/cmake/help/v3.0/policy/CMP0020.html
  cmake_policy(SET CMP0020 NEW)
endif()

if($ENV{TRAVIS})
  set(TRAVIS ON)
endif()

if(IS_DIRECTORY "/bgsys")
  set(BLUEGENE TRUE)
endif()

# OPT
if(NOT DOXYGEN_FOUND)
  find_package(Doxygen QUIET)
endif()

include(CommonApplication)
include(CommonCode)
include(CommonDocumentation)
include(CommonInstall)
include(CommonLibrary)
include(Compiler)
include(Coverage)
include(GitInfo)
include(GitTargets)
include(Maturity)
include(ProjectInfo)
include(TestCPP11)
include(UpdateGitExternal)

include(SubProject)
