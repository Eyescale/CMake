# sets ${SYSTEM}

if(WIN32)
  set(SYSTEM Win32)
endif(WIN32)
if(APPLE)
  set(SYSTEM Darwin)
  execute_process(COMMAND sw_vers -productVersion OUTPUT_VARIABLE OSX_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE)
endif(APPLE)
if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  set(SYSTEM Linux)
endif(CMAKE_SYSTEM_NAME MATCHES "Linux")
if(NOT SYSTEM)
  message(FATAL_ERROR "Unable to determine OS")
endif()
