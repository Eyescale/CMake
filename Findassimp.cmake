#
# Copyright 2015 Cyrille Favreau <cyrille.favreau@epfl.ch>
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
# ASSIMP
#
#==============================================================================
# This module uses the following input variables:
#
#  ASSIMP_FOUND - system has Assimp
#
#  ASSIMP_INCLUDE_DIRS - the Assimp include directory
#
#  ASSIMP_LIBRARIES - Link these to use Assimp
#
#==============================================================================
#

set(ASSIMP_FOUND FALSE)
set(ASSIMP_NAME assimp)

set(ASSIMP_ROOT $ENV{ASSIMP_ROOT})

# Find headers
find_path(ASSIMP_INCLUDE_DIRS
  NAMES assimp/scene.h
  HINTS ${ASSIMP_ROOT}/include
  /usr/local/include
  /usr/include
)

# Find dynamic libraries
find_library(ASSIMP_LIBRARIES
  NAMES assimp
  HINTS ${ASSIMP_ROOT}/lib
  /usr/local/lib/
  /usr/lib/
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ASSIMP DEFAULT_MSG
    ASSIMP_INCLUDE_DIRS
    ASSIMP_LIBRARIES)

if(ASSIMP_FOUND)
  set(ASSIMP_INCLUDE_DIRS ${ASSIMP_INCLUDE_DIR})
  message(STATUS "Found assimp in ${ASSIMP_INCLUDE_DIR}:${ASSIMP_LIBRARIES}")
else()
  set(ASSIMP_FOUND)
  set(ASSIMP_INCLUDE_DIR)
  set(ASSIMP_INCLUDE_DIRS)
  set(ASSIMP_LIBRARIES)
endif()
