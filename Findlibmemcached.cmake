# Copyright (c) 2016 Daniel.Nachbaur@epfl.ch

# - Try to find the libmemcached library
# Once done this will define
#
#  libmemcached_ROOT - Set this variable to the root installation
#
# Read-Only variables:
#  libmemcached_FOUND - system has the libmemcached library
#  libmemcached_INCLUDE_DIR - the libmemcached include directory
#  libmemcached_LIBRARIES - The libraries needed to use libmemcached

include(FindPackageHandleStandardArgs)

if(libmemcached_FIND_REQUIRED)
  set(_libmemcached_output_type FATAL_ERROR)
else()
  set(_libmemcached_output_type STATUS)
endif()

if(libmemcached_FIND_QUIETLY)
  set(_libmemcached_output)
else()
  set(_libmemcached_output 1)
endif()

find_path(_libmemcached_INCLUDE_DIR libmemcached/memcached.h
  HINTS ${CMAKE_SOURCE_DIR}/../../.. $ENV{LIBMEMCACHED_ROOT} ${LIBMEMCACHED_ROOT}
  PATH_SUFFIXES include
  PATHS /usr /usr/local /opt /opt/local)

if(_libmemcached_INCLUDE_DIR AND EXISTS "${_libmemcached_INCLUDE_DIR}/libmemcached/memcached.h")
  set(_libmemcached_Version_file "${_libmemcached_INCLUDE_DIR}/libmemcached/memcached.h")
else()
  set(_libmemcached_EPIC_FAIL TRUE)
  if(_libmemcached_output)
    message(${_libmemcached_output_type}
      "Can't find libmemcached header file libmemcached/memcached.h.")
  endif()
endif()

find_library(libmemcached_LIBRARY memcached
  HINTS ${CMAKE_SOURCE_DIR}/../../.. $ENV{LIBMEMCACHED_ROOT} ${LIBMEMCACHED_ROOT}
  PATH_SUFFIXES lib lib64
  PATHS /usr /usr/local /opt /opt/local)

if(libmemcached_FIND_REQUIRED)
  if(libmemcached_LIBRARY MATCHES "libmemcached_LIBRARY-NOTFOUND")
    message(FATAL_ERROR "Missing the libmemcached library.\n"
      "Consider using CMAKE_PREFIX_PATH or the LIBMEMCACHED_ROOT environment variable. "
      "See the ${CMAKE_CURRENT_LIST_FILE} for more details.")
  endif()
endif()
find_package_handle_standard_args(libmemcached DEFAULT_MSG
                                  libmemcached_LIBRARY _libmemcached_INCLUDE_DIR)

if(_libmemcached_EPIC_FAIL)
  set(libmemcached_FOUND FALSE)
  set(libmemcached_LIBRARY)
  set(_libmemcached_INCLUDE_DIR)
  set(libmemcached_INCLUDE_DIRS)
  set(libmemcached_LIBRARIES)
else()
  set(libmemcached_INCLUDE_DIRS ${_libmemcached_INCLUDE_DIR})
  set(libmemcached_LIBRARIES ${libmemcached_LIBRARY})
  if(_libmemcached_output)
    message(STATUS
      "Found libmemcached ${libmemcached_VERSION} in ${libmemcached_INCLUDE_DIRS};${libmemcached_LIBRARIES}")
  endif()
endif()
