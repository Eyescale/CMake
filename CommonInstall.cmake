# Copyright (c) 2015 Stefan.Eilemann@epfl.ch

# Uses a compatible subset of the install() syntax, but can install
# files while preserving their relative directory, and additionally
# installing them into the PROJECT_BINARY_DIR for compatibility with
# superprojects. Files with an absolute filename are installed
# directly into the DESTINATION, that is, their directory is not
# preserved. If RELATIVE is set, directories are ignored on all files.

# Usage: common_install(FILES <files> [COMPONENT <name>] [DESTINATION <prefix>]
#                       [RELATIVE])

include(CMakeParseArguments)

function(COMMON_INSTALL)
  set(OPT_NAMES RELATIVE)
  set(ARG_NAMES COMPONENT DESTINATION)
  set(ARGS_NAMES FILES)
  cmake_parse_arguments(THIS "${OPT_NAMES}" "${ARG_NAMES}" "${ARGS_NAMES}"
    ${ARGN})

  if(THIS_COMPONENT)
    set(THIS_COMPONENT COMPONENT ${THIS_COMPONENT})
  endif()
  if(NOT THIS_DESTINATION)
    set(THIS_DESTINATION ".")
  endif()

  foreach(FILE ${THIS_FILES})
    if(IS_ABSOLUTE ${FILE} OR THIS_RELATIVE)
      set(DIR)
    else()
      string(REGEX MATCH "(.*)[/\\]" DIR ${FILE})
    endif()
    get_filename_component(BASENAME ${FILE} NAME)

    install(FILES ${FILE} DESTINATION ${THIS_DESTINATION}/${DIR}
      ${THIS_COMPONENT})
    configure_file(${FILE}
      ${PROJECT_BINARY_DIR}/${THIS_DESTINATION}/${DIR}/${BASENAME} @COPYONLY)
  endforeach()
endfunction()
