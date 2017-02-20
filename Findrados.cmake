# Copyright (c) 2017 MohamedGhaith.Kaabi@gmail.com

# - Try to find the Rados library
# Once done this will define
#
#  RADOS_ROOT - Set this variable to the root installation
#
# Read-Only variables:
#  RADOS_FOUND - system has the Rados library
#  RADOS_INCLUDE_DIR - the Rados include directory
#  RADOS_LIBRARIES - The libraries needed to use Rados
#  RADOS_VERSION - This is set to $major.$minor.$patch (eg. 0.9.8)

include(FindPackageHandleStandardArgs)

if(rados_FIND_REQUIRED)
  set(_RADOS_output_type FATAL_ERROR)
else()
  set(_RADOS_output_type STATUS)
endif()

if(rados_FIND_QUIETLY)
  set(_RADOS_output)
else()
  set(_RADOS_output 1)
endif()

find_path(_RADOS_INCLUDE_DIR rados/librados.hpp
  HINTS ${CMAKE_SOURCE_DIR}/../../.. $ENV{RADOS_ROOT} ${RADOS_ROOT}
  PATH_SUFFIXES include
  PATHS /usr /usr/local /opt /opt/local)

find_library(RADOS_LIBRARY rados
  HINTS ${CMAKE_SOURCE_DIR}/../../.. $ENV{RADOS_ROOT} ${RADOS_ROOT}
  PATH_SUFFIXES lib lib64
  PATHS /usr /usr/local /opt /opt/local)

if(rados_FIND_REQUIRED)
  if(RADOS_LIBRARY MATCHES "RADOS_LIBRARY-NOTFOUND")
    message(FATAL_ERROR "Missing the rados library.\n"
      "Consider using CMAKE_PREFIX_PATH or the RADOS_ROOT environment variable. "
      "See the ${CMAKE_CURRENT_LIST_FILE} for more details.")
  endif()
endif()
find_package_handle_standard_args(rados DEFAULT_MSG
                                  RADOS_LIBRARY _RADOS_INCLUDE_DIR)

if(_RADOS_EPIC_FAIL)
  set(RADOS_FOUND FALSE)
  set(RADOS_LIBRARY)
  set(_RADOS_INCLUDE_DIR)
  set(RADOS_INCLUDE_DIRS)
  set(RADOS_LIBRARIES)
else()
  set(RADOS_INCLUDE_DIRS ${_RADOS_INCLUDE_DIR})
  set(RADOS_LIBRARIES ${RADOS_LIBRARY})
  if(_RADOS_output)
    message(STATUS
      "Found rados in ${RADOS_INCLUDE_DIRS};${RADOS_LIBRARIES}")
  endif()
endif()
