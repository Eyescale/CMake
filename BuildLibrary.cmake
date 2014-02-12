# Copyright (c) 2014 Stefan.Eilemann@epfl.ch

# Configures the build for a simple library:
#   build_library(<Name>)
#
# Uses:
# * NAME_SOURCES for all compilation units
# * NAME_HEADERS for all internal header files
# * NAME_PUBLIC_HEADERS for public, installed header files
# * NAME_LINK_LIBRARIES for dependencies of name
# * VERSION for the API version
# * VERSION_ABI for the ABI version
#
# Builds libName and installs it. Installs the public headers to include/name.

function(BUILD_LIBRARY Name)
  string(TOUPPER ${Name} NAME)
  string(TOLOWER ${Name} name)
  set(SOURCES ${${NAME}_SOURCES})
  set(HEADERS ${${NAME}_HEADERS})
  set(PUBLIC_HEADERS ${${NAME}_PUBLIC_HEADERS})
  set(LINK_LIBRARIES ${${NAME}_LINK_LIBRARIES})

  source_group(${name} FILES ${SOURCES} ${HEADERS} ${PUBLIC_HEADERS})
  add_library(${Name} SHARED ${SOURCES} ${HEADERS} ${PUBLIC_HEADERS})
  target_link_libraries(${Name} ${LINK_LIBRARIES})
  set_target_properties(${Name}
    PROPERTIES VERSION ${VERSION} SOVERSION ${VERSION_ABI}
    PUBLIC_HEADER "${PUBLIC_HEADERS}")

  install(TARGETS ${Name}
    PUBLIC_HEADER DESTINATION include/${name} COMPONENT dev
    ARCHIVE DESTINATION lib COMPONENT dev
    RUNTIME DESTINATION bin COMPONENT lib
    LIBRARY DESTINATION lib COMPONENT lib)
endfunction()
