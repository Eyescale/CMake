# Copyright (c) 2013 Ahmet Bilgili <ahmet.bilgili@epfl.ch>
# Modified from: FindSAGE.cmake

# - Try to find the FlowVR library
# Once done this will define
#
#  FLOWVR_ROOT - Set this variable to the root installation of FlowVR
#
# Read-Only variables:
#  FLOWVR_FOUND - system has the FlowVR library
#  FLOWVR_INCLUDE_DIRS - the FlowVR include directory
#  FLOWVR_LIBRARIES - The libraries needed to use FlowVR
include(FindPackageHandleStandardArgs)

if(FlowVR_FIND_REQUIRED)
  set(_FlowVR_required REQUIRED)
  set(_FlowVR_output 1)
else()
  if(NOT FlowVR_FIND_QUIETLY)
    set(_FlowVR_output 1)
  endif()
endif()
if(FlowVR_FIND_QUIETLY)
  set(_FlowVR_quiet QUIET)
endif()

set(FLOWVR_INCLUDE_DIRS)

find_path(FLOWVRVR_BASE_INCLUDE_DIR flowvr/buffer.h
  PATH_SUFFIXES include
  PATHS ${PROJECT_SOURCE_DIR}/../../.. $ENV{FLOWVR_PREFIX} /usr/include /usr /opt )

if(FLOWVRVR_BASE_INCLUDE_DIR)
   list(APPEND FLOWVR_INCLUDE_DIRS ${FLOWVRVR_BASE_INCLUDE_DIR})
endif()

find_path(FLOWVRVR_MODULE_INCLUDE_DIR flowvr/module.h
  PATH_SUFFIXES include
  PATHS ${PROJECT_SOURCE_DIR}/../../.. $ENV{FLOWVR_PREFIX} /usr/include /usr /opt )

if(FLOWVRVR_MODULE_INCLUDE_DIR)
   list(APPEND FLOWVR_INCLUDE_DIRS ${FLOWVRVR_MODULE_INCLUDE_DIR})
endif()

if(FLOWVR_INCLUDE_DIRS)
  set(_FLOWVR_FAIL FALSE)
else()
  set(_FLOWVR_FAIL TRUE)
  if(_FLOWVR_output)
    message(STATUS "Can't find FlowVR headers.")
  endif()
endif()

set(_FLOWVR_LIBRARIES "flowvr-base"
                      "flowvr-commands"
                      "flowvr-mod"
                      "flowvr-plugd"
                      "ftlm"
                      "fca" )

set(FLOWVR_LIBRARIES)

foreach(FLOWVR_LIBRARY ${_FLOWVR_LIBRARIES})
   find_library(${FLOWVR_LIBRARY}_LIBRARY ${FLOWVR_LIBRARY}
      PATH_SUFFIXES lib lib64
      PATHS ${PROJECT_SOURCE_DIR}/../../.. $ENV{FLOWVR_PREFIX} /usr/local /usr /usr/local /opt /opt/local )
   if(${FLOWVR_LIBRARY}_LIBRARY)
      list(APPEND FLOWVR_LIBRARIES ${${FLOWVR_LIBRARY}_LIBRARY})
      if(NOT _FlowVR_quiet)
         message(STATUS "FlowVR: ${${FLOWVR_LIBRARY}_LIBRARY} FOUND")
      endif()
   else()
      if(NOT _FlowVR_quiet)
         message(STATUS "FlowVR: ${${FLOWVR_LIBRARY}_LIBRARY} NOT FOUND")
      endif()
   endif()
endforeach(FLOWVR_LIBRARY)

if(FLOWVR_FIND_REQUIRED)
   if(NOT FLOWVR_LIBRARIES)
      message(FATAL_ERROR "Missing the FlowVR libraries.\n"
         "Consider using CMAKE_PREFIX_PATH or the FLOWVR_PREFIX environment variable. "
         "See the ${CMAKE_CURRENT_LIST_FILE} for more details.")
         set(_FLOWVR_FAIL TRUE)
   endif()
endif()
find_package_handle_standard_args(FLOWVR DEFAULT_MSG FLOWVR_LIBRARIES FLOWVR_INCLUDE_DIRS)

if(_FLOWVR_FAIL)
   # Zero out everything, we didn't meet the requirements
   set(FLOWVR_FOUND FALSE)
   set(FLOWVR_LIBRARY)
   set(FLOWVR_INCLUDE_DIRS)
   set(_FLOWVR_LIBRARIES)
   set(FLOWVR_LIBRARIES)
else()
   set(FLOWVR_FOUND TRUE)
endif()
