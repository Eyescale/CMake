# Copyright (c) 2013-2015 Stefan.Eilemann@epfl.ch
#                         Daniel.Nachbaur@epfl.ch
#
# Output variables
#  - SYSTEM - a human-readable string identifier for the current platform
#    (Win32, Darwin or Linux)
#  - OSX_VERSION - the two numbers OS X version (e.g. 10.9)

if(SYSTEM)
  return()
endif()

if(WIN32)
  set(SYSTEM Win32)
endif()
if(APPLE)
  set(SYSTEM Darwin)
  execute_process(COMMAND sw_vers -productVersion OUTPUT_VARIABLE OSX_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)
endif()
if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  set(SYSTEM Linux)
endif()
if(NOT SYSTEM)
  message(FATAL_ERROR "Unable to determine OS")
endif()
