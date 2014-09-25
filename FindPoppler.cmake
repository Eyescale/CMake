# - Try to find Poppler and specified components: {cpp, Qt4, Qt5}
# Once done this will define:
#
#  POPPLER_FOUND - system has Poppler and specified components
#  POPPLER_INCLUDE_DIRS - The include directories for Poppler headers
#  POPPLER_LIBRARIES - Link these to use Poppler
#  POPPLER_NEEDS_FONTCONFIG - A boolean indicating if libpoppler depends on libfontconfig
#  POPPLER_HAS_XPDF - A boolean indicating if libpoppler headers are available
#  POPPLER_INCLUDE_DIR - the include directory for libpoppler XPDF headers
#
# Redistribution and use of this file is allowed according to the terms of the
# MIT license. For details see the file COPYING-CMAKE-MODULES.

if( POPPLER_LIBRARIES )
   # in cache already
   set( Poppler_FIND_QUIETLY TRUE )
endif( POPPLER_LIBRARIES )

# Check which components we need to find
list(FIND Poppler_FIND_COMPONENTS "cpp" FIND_POS)
if(${FIND_POS} EQUAL -1)
  set(FIND_CPP FALSE)
else()
  set(FIND_CPP TRUE)
endif()

list(FIND Poppler_FIND_COMPONENTS "Qt4" FIND_POS)
if(${FIND_POS} EQUAL -1)
  set(FIND_QT4 FALSE)
else()
  set(FIND_QT4 TRUE)
endif()

list(FIND Poppler_FIND_COMPONENTS "Qt5" FIND_POS)
if(${FIND_POS} EQUAL -1)
  set(FIND_QT5 FALSE)
else()
  set(FIND_QT5 TRUE)
endif()

# Default values
set(POPPLER_FOUND FALSE)
set(POPPLER_INCLUDE_DIRS)
set(POPPLER_LIBRARIES)
set(POPPLER_REQUIRED "POPPLER_LIBRARY")

# use pkg-config to get the directories and then use these values
# in the find_path() and find_library() calls
if( NOT WIN32 )
  find_package(PkgConfig)

  pkg_check_modules(POPPLER_PKG QUIET poppler)
  if( FIND_CPP )
    pkg_check_modules(POPPLER_CPP_PKG QUIET poppler-cpp)
  endif()
  if( FIND_QT4 )
    pkg_check_modules(POPPLER_QT4_PKG QUIET poppler-qt4)
  endif()
  if( FIND_QT5 )
    pkg_check_modules(POPPLER_QT5_PKG QUIET poppler-qt5)
  endif()
endif( NOT WIN32 )

# Check for Poppler headers (optional)
find_path( POPPLER_INCLUDE_DIR NAMES poppler-config.h PATH_SUFFIXES poppler )
if( NOT( POPPLER_INCLUDE_DIR ) )
  if( NOT Poppler_FIND_QUIETLY )
    message( STATUS "Could not find poppler-config.h, recompile Poppler with "
                    "ENABLE_XPDF_HEADERS to link against libpoppler directly." )
  endif()
  set( POPPLER_HAS_XPDF FALSE )
else()
  set( POPPLER_HAS_XPDF TRUE )
  list(APPEND POPPLER_INCLUDE_DIRS ${POPPLER_INCLUDE_DIR})
endif()

# Find libpoppler (Required)
find_library(POPPLER_LIBRARY NAMES poppler ${POPPLER_CPP_PKG_LIBRARIES})
if( NOT(POPPLER_LIBRARY) )
  if( NOT Poppler_FIND_QUIETLY )
    message(STATUS "Could not find libpoppler." )
  endif( NOT Poppler_FIND_QUIETLY )
else( NOT(POPPLER_LIBRARY) )
  list(APPEND POPPLER_LIBRARIES ${POPPLER_LIBRARY})

  # Scan poppler libraries for dependencies on Fontconfig
  include(GetPrerequisites)
  mark_as_advanced(gp_cmd)
  GET_PREREQUISITES("${POPPLER_LIBRARY}" POPPLER_PREREQS 1 0 "" "")
  if("${POPPLER_PREREQS}" MATCHES "fontconfig")
    set(POPPLER_NEEDS_FONTCONFIG TRUE)
  else()
    set(POPPLER_NEEDS_FONTCONFIG FALSE)
  endif()

  # cpp Component
  if( FIND_CPP )
    list(APPEND POPPLER_REQUIRED POPPLER_CPP_INCLUDE_DIR POPPLER_CPP_LIBRARY)
    find_path( POPPLER_CPP_INCLUDE_DIR NAMES poppler-version.h
               PATH_SUFFIXES cpp poppler/cpp )
    if( NOT(POPPLER_CPP_INCLUDE_DIR) )
      if( NOT Poppler_FIND_QUIETLY )
        message(STATUS "Could not find Poppler cpp wrapper headers." )
      endif( NOT Poppler_FIND_QUIETLY )
    else()
      list(APPEND POPPLER_INCLUDE_DIRS ${POPPLER_CPP_INCLUDE_DIR})
    endif()
    find_library( POPPLER_CPP_LIBRARY NAMES poppler-cpp ${POPPLER_CPP_PKG_LIBRARIES} )
    if( NOT(POPPLER_CPP_LIBRARY) )
      if( NOT Poppler_FIND_QUIETLY )
        message(STATUS "Could not find libpoppler-cpp." )
      endif( NOT Poppler_FIND_QUIETLY )
    else()
      list(APPEND POPPLER_LIBRARIES ${POPPLER_CPP_LIBRARY})
    endif()
  endif()

  # Qt4 Component
  if( FIND_QT4 )
    list(APPEND POPPLER_REQUIRED POPPLER_QT4_INCLUDE_DIR POPPLER_QT4_LIBRARY)
    find_path(POPPLER_QT4_INCLUDE_DIR NAMES poppler-qt4.h poppler-link.h
              PATH_SUFFIXES qt4 poppler/qt4)
    if( NOT(POPPLER_QT4_INCLUDE_DIR) )
      if( NOT Poppler_FIND_QUIETLY )
        message(STATUS "Could not find Poppler-Qt4 headers." )
      endif( NOT Poppler_FIND_QUIETLY )
    else()
      list(APPEND POPPLER_INCLUDE_DIRS ${POPPLER_QT4_INCLUDE_DIR})
    endif()
    find_library(POPPLER_QT4_LIBRARY NAMES poppler-qt4 ${POPPLER_QT4_PKG_LIBRARIES})
    if( NOT(POPPLER_QT4_LIBRARY) )
      if( NOT Poppler_FIND_QUIETLY )
        message(STATUS "Could not find libpoppler-qt4." )
      endif( NOT Poppler_FIND_QUIETLY )
    else()
      list(APPEND POPPLER_LIBRARIES ${POPPLER_QT4_LIBRARY})
    endif()
  endif()

  # Qt5 Component
  if( FIND_QT5 )
    list(APPEND POPPLER_REQUIRED POPPLER_QT5_INCLUDE_DIR POPPLER_QT5_LIBRARY)
    find_path(POPPLER_QT5_INCLUDE_DIR NAMES poppler-qt5.h poppler-link.h
              PATH_SUFFIXES qt5 poppler/qt5)
    if( NOT(POPPLER_QT5_INCLUDE_DIR) )
      if( NOT Poppler_FIND_QUIETLY )
        message( STATUS "Could not find Poppler-Qt5 headers." )
      endif( NOT Poppler_FIND_QUIETLY )
    else()
      list(APPEND POPPLER_INCLUDE_DIRS ${POPPLER_QT5_INCLUDE_DIR})
    endif()
    find_library(POPPLER_QT5_LIBRARY NAMES poppler-qt5 ${POPPLER_QT5_PKG_LIBRARIES})
    if( NOT(POPPLER_QT5_LIBRARY) )
      if( NOT Poppler_FIND_QUIETLY )
        message(STATUS "Could not find libpoppler-qt5." )
      endif( NOT Poppler_FIND_QUIETLY )
    else()
      list(APPEND POPPLER_LIBRARIES ${POPPLER_QT5_LIBRARY})
    endif()
  endif()
endif( NOT(POPPLER_LIBRARY) )

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Poppler DEFAULT_MSG ${POPPLER_REQUIRED})

mark_as_advanced(POPPLER_CPP_INCLUDE_DIR POPPLER_QT4_INCLUDE_DIR
                 POPPLER_QT5_INCLUDE_DIR POPPLER_LIBRARIES POPPLER_CPP_LIBRARY
                 POPPLER_QT4_LIBRARY POPPLER_QT5_LIBRARY)
