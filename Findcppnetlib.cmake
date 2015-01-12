# _____________________________________________________________________________
#
# CPP-NETLIB 
# _____________________________________________________________________________

# Assume not found.
SET(CPPNETLIB_FOUND FALSE)

# PATH ________________________________________________________________________

if (CPPNETLIB_PATH)
    # Set by user...
else (CPPNETLIB_PATH)
    find_path(CPPNETLIB_PATH include/boost/network.hpp
	HINTS ${CPP_NETLIB_ROOT} $ENV{CPP_NETLIB_ROOT}
        /usr/local/
        /usr/
    )
endif (CPPNETLIB_PATH)

message(**************************** cppnetlib path: ${CPPNETLIB_PATH} **************************)

if (CPPNETLIB_PATH)
    set (CPPNETLIB_FOUND TRUE)
endif (CPPNETLIB_PATH)

# HEADERS _____________________________________________________________________

if (CPPNETLIB_FOUND)
    set (CPPNETLIB_INCLUDE_DIR ${CPPNETLIB_PATH}/include)
    mark_as_advanced (CPPNETLIB_INCLUDE_DIR)
endif (CPPNETLIB_FOUND)

message(**************************** cppnetlib include path: ${CPPNETLIB_INCLUDE_DIR} **************************)

# DINAMYIC LIBRARY ______________________________________________________________

if (CPPNETLIB_FOUND)
    find_library(CPPNETLIB_LIBRARY1 NAMES cppnetlib-client-connections
	HINTS ${CPPNETLIB_ROOT} $ENV{CPPNETLIB_ROOT}
        PATHS ${CPPNETLIB_PATH}/lib64
    )
    find_library(CPPNETLIB_LIBRARY2 NAMES cppnetlib-server-parsers
        HINTS ${CPPNETLIB_ROOT} $ENV{CPPNETLIB_ROOT}
        PATHS ${CPPNETLIB_PATH}/lib64
    )
    find_library(CPPNETLIB_LIBRARY3 NAMES cppnetlib-uri
        HINTS ${CPPNETLIB_ROOT} $ENV{CPPNETLIB_ROOT}
        PATHS ${CPPNETLIB_PATH}/lib64
    )
    SET(CPPNETLIB_LIBRARIES ${CPPNETLIB_LIBRARY1} ${CPPNETLIB_LIBRARY2} ${CPPNETLIB_LIBRARY3})
    mark_as_advanced(CPPNETLIB_LIBRARIES)
endif (CPPNETLIB_FOUND)

# FOUND _______________________________________________________________________
if(CPPNETLIB_FOUND)
    message(STATUS
      "Found cpp-netlib in ${CPPNETLIB_INCLUDE_DIR};${CPPNETLIB_LIBRARIES}")
endif()

if (NOT CPPNETLIB_FOUND)
   if (CPPNETLIB_FIND_REQUIRED)
      message(FATAL_ERROR "Could not find cpp-netlib")
   endif (CPPNETLIB_FIND_REQUIRED)
endif (NOT CPPNETLIB_FOUND)
