#
# Copyright 2015 Grigori Chevtchenko <grigori.chevtchenko@epfl.ch>
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
# CPPNETLIB
#
#==============================================================================
# This module uses the following input variables:
#
# CPPNETLIB_ROOT - Path to the cpp-netlib module
#
# This module defines the following output variables:
#
# CPPNETLIB_FOUND - Was cppnetlib and all of the specified components found?
#
# CPPNETLIB_INCLUDE_DIRS - Where to find the headers
#
# CPPNETLIB_LIBRARIES - The cppnetlib libraries
#==============================================================================
#

# Assume not found.
set(CPPNETLIB_FOUND FALSE)
set(CPPNETLIB_PATH)

# Find headers
find_path(CPPNETLIB_INCLUDE_DIR boost/network.hpp
  HINTS ${CPPNETLIB_ROOT}/include $ENV{CPPNETLIB_ROOT}/include
  ${COMMON_SOURCE_DIR}/cppnetlib ${CMAKE_SOURCE_DIR}/cppnetlib
  /usr/local/include
  /usr/include)

if(CPPNETLIB_INCLUDE_DIR)
    set(CPPNETLIB_PATH "${CPPNETLIB_INCLUDE_DIR}/..")
endif()

# Find dynamic libraries
if(CPPNETLIB_PATH)
    set(__libraries cppnetlib-client-connections
                    cppnetlib-server-parsers
                    cppnetlib-uri)

    foreach(__library ${__libraries})
    if(TARGET ${__library})
      list(APPEND CPPNETLIB_LIBRARIES ${__library})
      set(CPPNETLIB_FOUND_SUBPROJECT ON)
    else()
      find_library(${__library} NAMES ${__library}
        HINTS ${CPPNETLIB_ROOT} $ENV{CPPNETLIB_ROOT}
        PATHS ${CPPNETLIB_PATH}/lib64 ${CPPNETLIB_PATH}/lib)
      list(APPEND CPPNETLIB_LIBRARIES ${${__library}})
    endif()
    endforeach()
    mark_as_advanced(CPPNETLIB_LIBRARIES)
endif()


if(NOT cppnetlib_FIND_QUIETLY)
  set(_cppnetlib_output 1)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(cppnetlib DEFAULT_MSG
                                  CPPNETLIB_LIBRARIES
                                  CPPNETLIB_INCLUDE_DIR)

if(CPPNETLIB_FOUND)
  set(CPPNETLIB_INCLUDE_DIRS ${CPPNETLIB_INCLUDE_DIR})
  if(_cppnetlib_output )
    message(STATUS "Found cppnetlib in ${CPPNETLIB_INCLUDE_DIR}:${CPPNETLIB_LIBRARIES}")
  endif()
else()
  set(CPPNETLIB_FOUND)
  set(CPPNETLIB_INCLUDE_DIR)
  set(CPPNETLIB_INCLUDE_DIRS)
  set(CPPNETLIB_LIBRARIES)
endif()
