# - Try to find Poppler and specified components (Qt4, Qt5)
# Once done this will define
#
#  POPPLER_FOUND - system has Poppler and specified components
#  POPPLER_INCLUDE_DIRS - The include directories for Poppler headers
#  POPPLER_LIBRARIES - Link these to use Poppler
#  POPPLER_NEEDS_FONTCONFIG - A boolean indicating if libpoppler depends on libfontconfig
#  POPPLER_HAS_XPDF - A boolean indicating if Poppler XPDF headers are available
#  POPPLER_XPDF_INCLUDE_DIR - the include directory for Poppler XPDF headers
#
# Redistribution and use of this file is allowed according to the terms of the
# MIT license. For details see the file COPYING-CMAKE-MODULES.

if( POPPLER_LIBRARIES )
   # in cache already
   SET( Poppler_FIND_QUIETLY TRUE )
endif( POPPLER_LIBRARIES )

# Check which components we need to find
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

# use pkg-config to get the directories and then use these values
# in the FIND_PATH() and FIND_LIBRARY() calls
if( NOT WIN32 )
  find_package(PkgConfig)

  pkg_check_modules(POPPLER_PKG QUIET poppler)
if( FIND_QT4 )
  pkg_check_modules(POPPLER_QT_PKG QUIET poppler-qt4)
endif()
if( FIND_QT5 )
  pkg_check_modules(POPPLER_QT_PKG QUIET poppler-qt5)
endif()
endif( NOT WIN32 )

# Check for Poppler XPDF headers (optional)
FIND_PATH(POPPLER_XPDF_INCLUDE_DIR NAMES poppler-config.h PATH_SUFFIXES poppler)
IF( NOT(POPPLER_XPDF_INCLUDE_DIR) )
  IF( NOT Poppler_FIND_QUIETLY )
    MESSAGE( STATUS "Could not find poppler-config.h, disabling support for Xpdf headers." )
  ENDIF( NOT Poppler_FIND_QUIETLY )
  SET( POPPLER_HAS_XPDF false )
ELSE( NOT(POPPLER_XPDF_INCLUDE_DIR) )
  SET( POPPLER_HAS_XPDF true )
ENDIF( NOT(POPPLER_XPDF_INCLUDE_DIR) )

# Find Poppler headers
FIND_PATH(POPPLER_INCLUDE_DIR NAMES poppler-version.h PATH_SUFFIXES cpp poppler/cpp)

# Find libpoppler, libpoppler-qt4 and associated header files (Required)
FIND_LIBRARY(POPPLER_LIBRARY NAMES poppler ${POPPLER_PKG_LIBRARIES})
IF ( NOT(POPPLER_LIBRARY) )
  IF ( NOT Poppler_FIND_QUIETLY )
    MESSAGE(STATUS "Could not find libpoppler." )
  ENDIF ( NOT Poppler_FIND_QUIETLY )
ELSE( NOT(POPPLER_LIBRARY) )
  # Scan poppler libraries for dependencies on Fontconfig
  INCLUDE(GetPrerequisites)
  MARK_AS_ADVANCED(gp_cmd)
  GET_PREREQUISITES("${POPPLER_LIBRARY}" POPPLER_PREREQS 1 0 "" "")
  IF ("${POPPLER_PREREQS}" MATCHES "fontconfig")
    SET(POPPLER_NEEDS_FONTCONFIG TRUE)
  ELSE ()
    SET(POPPLER_NEEDS_FONTCONFIG FALSE)
  ENDIF ()

  # Qt4 Component
  IF( FIND_QT4 )
    FIND_PATH(POPPLER_QT4_INCLUDE_DIR NAMES poppler-qt4.h poppler-link.h
              PATH_SUFFIXES qt4 poppler/qt4)
    IF ( NOT(POPPLER_QT4_INCLUDE_DIR) )
      IF ( NOT Poppler_FIND_QUIETLY )
        MESSAGE(STATUS "Could not find Poppler-Qt4 headers." )
      ENDIF ( NOT Poppler_FIND_QUIETLY )
    ENDIF ()
    FIND_LIBRARY(POPPLER_QT4_LIBRARY NAMES poppler-qt4 ${POPPLER_QT_PKG_LIBRARIES})
    IF ( NOT(POPPLER_QT4_LIBRARY) )
      IF ( NOT Poppler_FIND_QUIETLY )
        MESSAGE(STATUS "Could not find libpoppler-qt4." )
      ENDIF ( NOT Poppler_FIND_QUIETLY )
    ENDIF ()
  ENDIF()

  # Qt5 Component
  IF( FIND_QT5 )
    FIND_PATH(POPPLER_QT5_INCLUDE_DIR NAMES poppler-qt5.h poppler-link.h
              PATH_SUFFIXES qt5 poppler/qt5)
    IF ( NOT(POPPLER_QT5_INCLUDE_DIR) )
      IF ( NOT Poppler_FIND_QUIETLY )
        MESSAGE(STATUS "Could not find Poppler-Qt5 headers." )
      ENDIF ( NOT Poppler_FIND_QUIETLY )
    ENDIF ()
    FIND_LIBRARY(POPPLER_QT5_LIBRARY NAMES poppler-qt5 ${POPPLER_QT_PKG_LIBRARIES})
    IF ( NOT(POPPLER_QT5_LIBRARY) )
      IF ( NOT Poppler_FIND_QUIETLY )
        MESSAGE(STATUS "Could not find libpoppler-qt5." )
      ENDIF ( NOT Poppler_FIND_QUIETLY )
    ENDIF ()
  ENDIF()
ENDIF ( NOT(POPPLER_LIBRARY) )

LIST(APPEND POPPLER_INCLUDE_DIRS ${POPPLER_INCLUDE_DIR}
     ${POPPLER_QT4_INCLUDE_DIR} ${POPPLER_QT5_INCLUDE_DIR})

LIST(APPEND POPPLER_LIBRARIES ${POPPLER_LIBRARY}
     ${POPPLER_QT4_LIBRARY} ${POPPLER_QT5_LIBRARY})

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(Poppler DEFAULT_MSG POPPLER_LIBRARIES POPPLER_INCLUDE_DIRS)

MARK_AS_ADVANCED(POPPLER_XPDF_INCLUDE_DIR POPPLER_INCLUDE_DIR
                 POPPLER_QT4_INCLUDE_DIR POPPLER_QT5_INCLUDE_DIR
                 POPPLER_LIBRARIES POPPLER_QT4_LIBRARY POPPLER_QT5_LIBRARY)
