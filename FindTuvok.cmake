# Copyright (c) 2015 Ahmet Bilgili <ahmet.bilgili@epfl.ch>
# Modified from: FindTuvok.cmake

# - Try to find the TUVOK library
# Once done this will define
#
#  TUVOK_ROOT - Set this variable to the root installation of Tuvok
#
# Read-Only variables:
#  TUVOK_FOUND - system has the TUVOK library
#  TUVOK_INCLUDE_DIR - the TUVOK include directory
#  TUVOK_LIBRARY - The libraries needed to use SAGE
include(FindPackageHandleStandardArgs)

if(Tuvok_FIND_REQUIRED)
  set(_TUVOK_required REQUIRED)
endif()
if(NOT Tuvok_FIND_QUIETLY)
  set(_TUVOK_output 1)
endif()

find_path(_TUVOK_INCLUDE_DIR NAMES Tuvok/StdTuvokDefines.h
  HINTS ${PROJECT_SOURCE_DIR}/../../.. $ENV{TUVOK_ROOT} ${TUVOK_ROOT}
  ${CMAKE_SOURCE_DIR} ${COMMON_SOURCE_DIR}
  PATH_SUFFIXES include
  PATHS /usr/local /usr /opt )

if(_TUVOK_INCLUDE_DIR AND EXISTS "${_TUVOK_INCLUDE_DIR}/Tuvok/StdTuvokDefines.h")
  set(_TUVOK_FAIL FALSE)
else()
  set(_TUVOK_FAIL TRUE)
  if(_TUVOK_output)
    message(STATUS "Can't find Tuvok header file StdTuvokDefines.h.")
  endif()
endif()

if(TARGET Tuvok)
  set(TUVOK_LIBRARY Tuvok)
  set(TUVOK_FOUND_SUBPROJECT ON)
else()
  find_library(TUVOK_LIBRARY Tuvok
    HINTS ${PROJECT_SOURCE_DIR}/../../.. $ENV{TUVOK_ROOT} ${TUVOK_ROOT}
    PATH_SUFFIXES lib lib64
    PATHS /usr/local /usr /usr/local /opt /opt/local)
endif()

if(Tuvok_FIND_REQUIRED)
 if(TUVOK_LIBRARY MATCHES "TUVOK_LIBRARY-NOTFOUND")
   message(FATAL_ERROR "Missing the Tuvok library.\n"
     "Consider using CMAKE_PREFIX_PATH or the TUVOK_ROOT environment variable. "
     "See the ${CMAKE_CURRENT_LIST_FILE} for more details.")
 endif()
endif()
find_package_handle_standard_args(Tuvok DEFAULT_MSG TUVOK_LIBRARY _TUVOK_INCLUDE_DIR)

if(_TUVOK_FAIL)
  # Zero out everything, we didn't meet version requirements
  set(TUVOK_FOUND FALSE)
  set(TUVOK_LIBRARY)
  set(_TUVOK_INCLUDE_DIR)
  set(TUVOK_INCLUDE_DIR)
  set(TUVOK_LIBRARY)
else()
  set(TUVOK_INCLUDE_DIR ${_TUVOK_INCLUDE_DIR} ${_TUVOK_INCLUDE_DIR}/Tuvok)
endif()
