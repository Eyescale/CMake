# Copyright (c) 2012-2015, Stefan Eilemann <eile@eyescale.ch>
#               2013-2015, Daniel Nachbaur <daniel.nachbaur@epfl.ch>
#               2013-2015, Ahmet Bilgili <ahmet.bilgili@epfl.ch>
#                    2015, Raphael Dumuc <raphael.dumusc@epfl.ch>
#
# Boost settings to ensure that the Boost finder works in some platforms
# (e.g. RHEL 6.5)

set(Boost_NO_BOOST_CMAKE ON CACHE BOOL "Enable fix for FindBoost.cmake" )
set(Boost_DETAILED_FAILURE_MSG ON) # Output which components are missing
add_definitions(-DBOOST_ALL_NO_LIB) # Don't use 'pragma lib' on Windows
add_definitions(-DBoost_NO_BOOST_CMAKE) # Fix for CMake problem in FindBoost
if(NOT "$ENV{BOOST_ROOT}" STREQUAL "" OR
    NOT "$ENV{BOOST_LIBRARYDIR}" STREQUAL "")
  # Fix find of non-system Boost
  option(Boost_NO_SYSTEM_PATHS "Disable system paths for FindBoost" ON)
endif()

if(CMAKE_COMPILER_IS_XLCXX AND XLC_BACKEND)
  set(Boost_NO_BOOST_CMAKE TRUE)
  set(Boost_USE_STATIC_LIBS TRUE)
endif()
