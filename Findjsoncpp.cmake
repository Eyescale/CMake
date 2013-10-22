# Copyright (c) 2013 Stefan Eilemann <eile@eyescale.ch>
#
# - Find jsoncpp
# Find the jsonpp includes and library
# This module defines
#
#  JSONCPP_FOUND
#  JSONCPP_INCLUDE_DIRS, where to find json.h, etc.
#  JSONCPP_LIBRARIES, where to find the jsoncpp library.
 
find_path(JSONCPP_INCLUDE_DIR jsoncpp/json/json.h
    /usr/local/include
    /usr/include
)
 
set(JSONCPP_NAMES ${JSONCPP_NAMES} libjsoncpp.so)
find_library(JSONCPP_LIB
  NAMES ${JSONCPP_NAMES}
  PATHS /usr/lib /usr/local/lib
)

set(JSONCPP_LIBRARIES ${JSONCPP_LIB})
set(JSONCPP_INCLUDE_DIRS ${JSONCPP_INCLUDE_DIR})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(jsoncpp DEFAULT_MSG
				  JSONCPP_LIB
				  JSONCPP_INCLUDE_DIR)

mark_as_advanced(JSONCPP_LIB
  		 JSONCPP_INCLUDE_DIR
)
