#
# Copyright 2016 Stefan.Eilemann@epfl.ch
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
# - Neither the name of Eyescale Software GmbH nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# =============================================================================
#
# HTTPXX
#
#==============================================================================
# This module uses the following input variables:
#
# HTTPXX_ROOT - Path to the httpxx module
#
# This module defines the following output variables:
#
# HTTPXX_FOUND - Was httpxx and all of the specified components found?
#
# HTTPXX_INCLUDE_DIRS - Where to find the headers
#
# HTTPXX_LIBRARIES - The httpxx libraries
#==============================================================================
#

# Assume not found.
set(HTTPXX_FOUND FALSE)
set(HTTPXX_PATH)

# Find headers
find_path(HTTPXX_INCLUDE_DIR httpxx/Message.hpp
  HINTS ${HTTPXX_ROOT}/include $ENV{HTTPXX_ROOT}/include
  ${COMMON_SOURCE_DIR}/httpxx ${CMAKE_SOURCE_DIR}/httpxx
  /usr/local/include /opt/local/include /usr/include)

if(HTTPXX_INCLUDE_DIR)
  set(HTTPXX_PATH "${HTTPXX_INCLUDE_DIR}/..")
endif()

# Find dynamic libraries
if(HTTPXX_PATH)
  set(__libraries httpxx)

  foreach(__library ${__libraries})
    if(TARGET ${__library})
      list(APPEND HTTPXX_LIBRARIES ${__library})
      set(HTTPXX_FOUND_SUBPROJECT ON)
    else()
      find_library(${__library} NAMES ${__library}
        HINTS ${HTTPXX_ROOT} $ENV{HTTPXX_ROOT}
        PATHS ${HTTPXX_PATH}/lib64 ${HTTPXX_PATH}/lib)
      list(APPEND HTTPXX_LIBRARIES ${${__library}})
    endif()
  endforeach()
  mark_as_advanced(HTTPXX_LIBRARIES)
endif()

if(NOT httpxx_FIND_QUIETLY)
  set(_httpxx_output 1)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(httpxx DEFAULT_MSG HTTPXX_LIBRARIES
  HTTPXX_INCLUDE_DIR)

if(HTTPXX_FOUND)
  set(HTTPXX_INCLUDE_DIRS ${HTTPXX_INCLUDE_DIR})
  if(_httpxx_output )
    message(STATUS "Found httpxx in ${HTTPXX_INCLUDE_DIR}:${HTTPXX_LIBRARIES}")
  endif()
else()
  set(HTTPXX_FOUND)
  set(HTTPXX_INCLUDE_DIR)
  set(HTTPXX_INCLUDE_DIRS)
  set(HTTPXX_LIBRARIES)
endif()
