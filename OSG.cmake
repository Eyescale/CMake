
# Copyright (c) 2013-2014, EPFL/Blue Brain Project
#                          jhernando@fi.upm.es

# This script finds the ABI version of a previously detected OpenSceneGraph
# installation and exports the following variables:
#
# OPENSCENEGRAPH_SOVERSION - The ABI version parsed from osg/Version
# OPENSCENEGRAPH_DEB_DEPENDENCIES - The .deb package name compatible with the
#                                   found version

if(NOT OPENSCENEGRAPH_FOUND)
  return()
endif()

set(_osg_Version_file "${OSG_INCLUDE_DIR}/osg/Version")
if(NOT EXISTS "${_osg_Version_file}")
  message(SEND_ERROR
    "OpenSceneGraph version header file not found: ${_osg_Version_file}")
  return()
endif()

file(STRINGS "${_osg_Version_file}" _osg_Version_contents
  REGEX "#define (OPENSCENEGRAPH_SOVERSION)[ \t]+[0-9]+")
string(REGEX REPLACE ".*#define OPENSCENEGRAPH_SOVERSION[ \t]+([0-9]+).*"
  "\\1" _osg_SOVERSION ${_osg_Version_contents})

set(OPENSCENEGRAPH_SOVERSION ${_osg_SOVERSION})
set(OPENSCENEGRAPH_DEB_DEPENDENCIES "libopenscenegraph${_osg_SOVERSION} (>= ${_osg_VERSION_MAJOR}.${_osg_VERSION_MINOR})"
  CACHE INTERNAL "The binary debian package of the OSG version which was detected")


