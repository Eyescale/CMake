# Copyright (c) 2017 Stefan.Eilemann@epfl.ch
#                    Raphael.Dumusc@epfl.ch
#
# Generate help page for doxygen by running Name application with --help:
#   common_help(<Name> [LOCATION location])
#
# Arguments:
# * Name: an existing application target
# * LOCATION: (Optional) location of the application for custom targets such as
#   python scripts. For EXECUTABLE targets $<TARGET_FILE:${Name}> is used by
#   default.
#
# Output Global Properties:
# * ${PROJECT_NAME}_HELP help page names generated (see DoxygenRule.cmake)
#
# Targets generated:
# * ${Name}-help to generate the help file for a given application
# * ${PROJECT_NAME}-help to generate the help for the current project

include(CMakeParseArguments)
include(CommonTarget)

function(common_help Name)
  set(_opts)
  set(_singleArgs LOCATION)
  set(_multiArgs)
  cmake_parse_arguments(THIS "${_opts}" "${_singleArgs}" "${_multiArgs}"
    ${ARGN})

  # run binary with --help to capture output for doxygen
  set(_doc "${PROJECT_BINARY_DIR}/help/${Name}.md")
  set(_cmake "${CMAKE_CURRENT_BINARY_DIR}/${Name}.cmake")
  file(WRITE ${_cmake} "
    execute_process(COMMAND \${APP} --help TIMEOUT 5 RESULT_VARIABLE _result
      OUTPUT_VARIABLE _help_content OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_VARIABLE _error  ERROR_STRIP_TRAILING_WHITESPACE
    )
    if(NOT _result EQUAL 0 OR NOT _help_content)
      message(FATAL_ERROR \"${Name} is missing --help\n\${_error}\")
    endif()
    file(WRITE ${_doc} \"${Name} {#${Name}}
============

```
\${_help_content}
```
\")
")

  if(THIS_LOCATION)
    set(_app ${THIS_LOCATION})
  else()
    get_property(_type TARGET ${Name} PROPERTY TYPE)
    if(_type STREQUAL "EXECUTABLE")
      set(_app $<TARGET_FILE:${Name}>)
    else()
      message(FATAL_ERROR "common_help(${Name}): application location not "
                          "provided for custom target")
    endif()
  endif()

  add_custom_command(OUTPUT ${_doc}
    COMMAND ${CMAKE_COMMAND} -DAPP=${_app} -P ${_cmake}
    DEPENDS ${Name} COMMENT "Creating help for ${Name}")
  add_custom_target(${Name}-help DEPENDS ${_doc})
  set_target_properties(${Name}-help PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/doxygen)

  set_property(GLOBAL APPEND PROPERTY ${PROJECT_NAME}_HELP ${Name})

  if(NOT TARGET ${PROJECT_NAME}-help)
    add_custom_target(${PROJECT_NAME}-help)
    set_target_properties(${PROJECT_NAME}-help PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/doxygen)
  endif()
  add_dependencies(${PROJECT_NAME}-help ${Name}-help)
endfunction()
