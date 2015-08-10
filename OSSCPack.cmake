
# Configures rules for publishing open source packages.

# No support for subproject packaging
if(NOT PROJECT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  return()
endif()

include(UploadPPA)
include(MacPorts)
if(UPLOADPPA_FOUND)
  upload_ppas()
endif()
