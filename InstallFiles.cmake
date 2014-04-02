# Copyright (c) 2012 Stefan.Eilemann@epfl.ch

# Usage: install_files(<prefix> FILES <files> [COMPONENT <name>])
#   Installs files while preserving their relative directory. Files
#   with an absolute path are installed directly into prefix.

include(CMakeParseArguments)

function(INSTALL_FILES PREFIX)
  set(ARG_NAMES COMPONENT)
  set(ARGS_NAMES FILES)
  cmake_parse_arguments(THIS "" "${ARG_NAMES}" "${ARGS_NAMES}" ${ARGN})

  foreach(FILE ${THIS_FILES})
    if(IS_ABSOLUTE ${FILE})
      set(DIR)
    else()
      string(REGEX MATCH "(.*)[/\\]" DIR ${FILE})
    endif()
    if(THIS_COMPONENT)
      install(FILES ${FILE} DESTINATION ${PREFIX}/${DIR}
        COMPONENT ${THIS_COMPONENT})
    else()
      install(FILES ${FILE} DESTINATION ${PREFIX}/${DIR})
    endif()
  endforeach()
endfunction()
