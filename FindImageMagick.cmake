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

set(IMAGEMAGICK_FOUND FALSE)
set(IMAGEMAGICK_NAME Magick)

set(IMAGEMAGICK_ROOT $ENV{IMAGEMAGICK_ROOT})

# Find headers
find_path(IMAGEMAGICK_INCLUDE_DIRS
  NAMES Magick++.h
  HINTS ${IMAGEMAGICK_ROOT}/include
  /opt/local/include/ImageMagick-6/
  /usr/local/include/${IMAGEMAGICK_NAME}/
  /usr/include/ImageMagick/
  /usr/include/
)

# Find dynamic libraries
find_library(IMAGEMAGICK_LIBRARIES
  NAMES Magick++
  HINTS ${IMAGEMAGICK_ROOT}/lib
  /opt/local/lib/
  /usr/local/lib/
  /usr/lib/x86_64-linux-gnu/
  /usr/lib/
)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(
    imagemagick DEFAULT_MSG
    IMAGEMAGICK_LIBRARIES
    IMAGEMAGICK_INCLUDE_DIRS)

if(IMAGEMAGICK_FOUND)
  set(IMAGEMAGICK_INCLUDE_DIRS ${IMAGEMAGICK_INCLUDE_DIR})
  message(STATUS "Found ImageMagick in ${IMAGEMAGICK_INCLUDE_DIR}:${IMAGEMAGICK_LIBRARIES}")
else()
  set(IMAGEMAGICK_FOUND)
  set(IMAGEMAGICK_INCLUDE_DIR)
  set(IMAGEMAGICK_INCLUDE_DIRS)
  set(IMAGEMAGICK_LIBRARIES)
endif()
