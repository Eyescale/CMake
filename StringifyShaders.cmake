##
# Copyright (c) 2010 Daniel Pfeifer <daniel@pfeifer-mail.de>
#               2014 Stefan.Eilemann@epfl.ch
#
# Returns source file names in SHADER_SOURCES
##

set(STRINGIFY_SHADERS_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(STRINGIFY_SHADERS)
  set(OUTPUTS)
  foreach(FILE ${ARGV})
    set(INPUT ${CMAKE_CURRENT_SOURCE_DIR}/${FILE})
    set(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${FILE})
    set(OUTPUT_FILES ${OUTPUT}.h ${OUTPUT}.cpp)

    add_custom_command(OUTPUT ${OUTPUT_FILES}
      COMMAND ${CMAKE_COMMAND} -DSTRINGIFY_SHADERS_PROCESSING_MODE=ON
        -DINPUT="${INPUT}" -DOUTPUT="${OUTPUT}"
        -P ${STRINGIFY_SHADERS_DIR}/StringifyShaders.cmake
      DEPENDS ${INPUT}
      )
    list(APPEND OUTPUTS ${OUTPUT_FILES})
  endforeach(FILE ${ARGN})

  set(SHADER_SOURCES ${OUTPUTS} PARENT_SCOPE)
endfunction()

if(STRINGIFY_SHADERS_PROCESSING_MODE)
  get_filename_component(FILENAME ${INPUT} NAME)
  string(REGEX REPLACE "[.]" "_" NAME ${FILENAME})

  file(STRINGS ${INPUT} LINES)

  file(WRITE ${OUTPUT}.h
    "/* Generated file, do not edit! */\n\n"
    "extern char const* const ${NAME};\n"
    )

  file(WRITE ${OUTPUT}.cpp
    "/* Generated file, do not edit! */\n\n"
    "#include \"${FILENAME}.h\"\n\n"
    "char const* const ${NAME} = \n"
    )

  foreach(LINE ${LINES})
    string(REPLACE "\"" "\\\"" LINE "${LINE}")
    file(APPEND ${OUTPUT}.cpp "   \"${LINE}\\n\"\n")
  endforeach(LINE)

  file(APPEND ${OUTPUT}.cpp "   ;\n")
endif()
