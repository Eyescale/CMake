# - Try to find MUSIC headers and library
# Once done this will define:
#
#  MUSIC_FOUND - system has Poppler and specified components
#  MUSIC_INCLUDE_DIRS - The include directories for Poppler headers
#  MUSIC_LIBRARIES - Link these to use Poppler

if(MUSIC_LIBRARIES )
   # in cache already
   set(MUSIC_FIND_QUIETLY TRUE)
endif(MUSIC_LIBRARIES)

set(MUSIC_FOUND FALSE)
set(MUSIC_INCLUDE_DIRS)
set(MUSIC_LIBRARIES)

find_path(MUSIC_INCLUDE_DIR NAMES music.hh PATH_SUFFIXES include
  HINTS $ENV{MUSIC_ROOT} ${MUSIC_ROOT})
if(MUSIC_INCLUDE_DIR)
 list(APPEND MUSIC_INCLUDE_DIRS ${MUSIC_INCLUDE_DIR})
endif()

find_library(MUSIC_LIBRARY NAMES music PATH_SUFFIXES lib
             HINTS $ENV{MUSIC_ROOT} ${MUSIC_ROOT})
if(MUSIC_LIBRARY)
 list(APPEND MUSIC_LIBRARIES ${MUSIC_LIBRARY})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MUSIC DEFAULT_MSG
                                  MUSIC_INCLUDE_DIRS MUSIC_LIBRARIES)

mark_as_advanced(MUSIC_INCLUDE_DIR MUSIC_LIBRARIES)
