# Copyright (c) 2014 Stefan.Eilemann@epfl.ch

# - Try to find the Leveldb library
# Once done this will define
#
#  LEVELDB_ROOT - Set this variable to the root installation
#
# Read-Only variables:
#  LEVELDB_FOUND - system has the Leveldb library
#  LEVELDB_INCLUDE_DIR - the Leveldb include directory
#  LEVELDB_LIBRARIES - The libraries needed to use Leveldb
#  LEVELDB_VERSION - This is set to $major.$minor.$patch (eg. 0.9.8)

include(FindPackageHandleStandardArgs)

if(leveldb_FIND_REQUIRED)
  set(_LEVELDB_output_type FATAL_ERROR)
else()
  set(_LEVELDB_output_type STATUS)
endif()

if(leveldb_FIND_QUIETLY)
  set(_LEVELDB_output)
else()
  set(_LEVELDB_output 1)
endif()

find_path(_LEVELDB_INCLUDE_DIR leveldb/db.h
  HINTS ${CMAKE_SOURCE_DIR}/../../.. $ENV{LEVELDB_ROOT} ${LEVELDB_ROOT}
  PATH_SUFFIXES include
  PATHS /usr /usr/local /opt /opt/local)

if(_LEVELDB_INCLUDE_DIR AND EXISTS "${_LEVELDB_INCLUDE_DIR}/leveldb/db.h")
  set(_LEVELDB_Version_file "${_LEVELDB_INCLUDE_DIR}/leveldb/db.h")
  file(READ ${_LEVELDB_Version_file} _LEVELDB_header_contents)
  string(REGEX REPLACE ".*kMajorVersion = ([0-9]+).*kMinorVersion = ([0-9]+).*"
    "\\1.\\2" _LEVELDB_VERSION "${_LEVELDB_header_contents}")
  set(LEVELDB_VERSION ${_LEVELDB_VERSION} CACHE INTERNAL
    "The version of leveldb which was detected")
else()
  set(_LEVELDB_EPIC_FAIL TRUE)
  if(_LEVELDB_output)
    message(${_LEVELDB_output_type}
      "Can't find leveldb header file leveldb/db.h.")
  endif()
endif()

# Version checking
if(LEVELDB_FIND_VERSION AND LEVELDB_VERSION)
  if(LEVELDB_FIND_VERSION_EXACT)
    if(NOT LEVELDB_VERSION VERSION_EQUAL ${LEVELDB_FIND_VERSION})
      set(_LEVELDB_version_not_exact TRUE)
    endif()
  else()
    # version is too low
    if(NOT LEVELDB_VERSION VERSION_EQUAL ${LEVELDB_FIND_VERSION} AND
        NOT LEVELDB_VERSION VERSION_GREATER ${LEVELDB_FIND_VERSION})
      set(_LEVELDB_version_not_high_enough TRUE)
    endif()
  endif()
endif()

find_library(LEVELDB_LIBRARY leveldb
  HINTS ${CMAKE_SOURCE_DIR}/../../.. $ENV{LEVELDB_ROOT} ${LEVELDB_ROOT}
  PATH_SUFFIXES lib lib64
  PATHS /usr /usr/local /opt /opt/local)

# Inform the users with an error message based on what version they
# have vs. what version was required.
if(NOT LEVELDB_VERSION)
  set(_LEVELDB_EPIC_FAIL TRUE)
  if(_LEVELDB_output)
    message(${_LEVELDB_output_type}
      "Version not found in ${_LEVELDB_Version_file}.")
  endif()
elseif(_LEVELDB_version_not_high_enough)
  set(_LEVELDB_EPIC_FAIL TRUE)
  if(_LEVELDB_output)
    message(${_LEVELDB_output_type}
      "Version ${LEVELDB_FIND_VERSION} or higher of leveldb is required. "
      "Version ${LEVELDB_VERSION} was found in ${_LEVELDB_Version_file}.")
  endif()
elseif(_LEVELDB_version_not_exact)
  set(_LEVELDB_EPIC_FAIL TRUE)
  if(_LEVELDB_output)
    message(${_LEVELDB_output_type}
      "Version ${LEVELDB_FIND_VERSION} of leveldb is required exactly. "
      "Version ${LEVELDB_VERSION} was found.")
  endif()
else()
  if(leveldb_FIND_REQUIRED)
    if(LEVELDB_LIBRARY MATCHES "LEVELDB_LIBRARY-NOTFOUND")
      message(FATAL_ERROR "Missing the leveldb library.\n"
        "Consider using CMAKE_PREFIX_PATH or the LEVELDB_ROOT environment variable. "
        "See the ${CMAKE_CURRENT_LIST_FILE} for more details.")
    endif()
  endif()
  find_package_handle_standard_args(leveldb DEFAULT_MSG
                                    LEVELDB_LIBRARY _LEVELDB_INCLUDE_DIR)
endif()

if(_LEVELDB_EPIC_FAIL)
  # Zero out everything, we didn't meet version requirements
  set(LEVELDB_FOUND FALSE)
  set(LEVELDB_LIBRARY)
  set(_LEVELDB_INCLUDE_DIR)
  set(LEVELDB_INCLUDE_DIRS)
  set(LEVELDB_LIBRARIES)
else()
  set(LEVELDB_INCLUDE_DIRS ${_LEVELDB_INCLUDE_DIR})
  set(LEVELDB_LIBRARIES ${LEVELDB_LIBRARY})
  if(_LEVELDB_output)
    message(STATUS
      "Found leveldb ${LEVELDB_VERSION} in ${LEVELDB_INCLUDE_DIRS};${LEVELDB_LIBRARIES}")
  endif()
endif()
