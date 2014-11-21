# Find the capnproto schema compiler
#
# Output Variables:
# * CAPNP_EXECUTABLE the Cap'n Proto compiler executable
# * CAPNPROTO_FOUND
#
# Provides:
# * CAPNP_TARGET(Name <files>) creates the C++ headers for the given
#   capnproto schema files. Returns the header files in ${Name}_OUTPUTS

find_program(CAPNP_EXECUTABLE NAMES capnp)
find_path(CAPNPROTO_INCLUDE_DIR NAMES capnp/generated-header-support.h)
find_library(CAPNPROTO_LIBRARY NAMES capnp)
find_library(CAPNPROTO_KJ_LIBRARY NAMES kj)
set(CAPNPROTO_LIBRARIES ${CAPNPROTO_LIBRARY} ${CAPNPROTO_KJ_LIBRARY})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(capnproto DEFAULT_MSG CAPNP_EXECUTABLE
  CAPNPROTO_INCLUDE_DIR CAPNPROTO_LIBRARIES)

if(CAPNPROTO_FOUND)
  function(CAPNP_TARGET Name)
    set(CAPNP_OUTPUTS)
    get_filename_component(CAPNP_DIR ${CAPNP_EXECUTABLE} DIRECTORY)
    foreach(FILE ${ARGN})
      get_filename_component(CAPNP_OUTPUT ${FILE} NAME_WE)
      set(CAPNP_OUTPUT
        "${PROJECT_BINARY_DIR}/${CAPNP_OUTPUT}_generated.h")
      list(APPEND CAPNP_OUTPUTS ${CAPNP_OUTPUT})

      add_custom_command(OUTPUT ${CAPNP_OUTPUT}
        COMMAND PATH=${CAPNP_DIR} ${CAPNP_EXECUTABLE}
        ARGS compile -oc++:"${PROJECT_BINARY_DIR}/" ${FILE}
        COMMENT "Building C++ header for ${FILE}"
        DEPENDS ${FILE}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
    endforeach()
    set(${Name}_OUTPUTS ${CAPNP_OUTPUTS} PARENT_SCOPE)
  endfunction()

  set(CAPNPROTO_INCLUDE_DIRS ${CAPNPROTO_INCLUDE_DIR})
  include_directories(${PROJECT_BINARY_DIR})
else()
  set(CAPNPROTO_INCLUDE_DIR)
endif()

