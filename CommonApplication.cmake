# Copyright (c) 2014 Stefan.Eilemann@epfl.ch

# Configures the build for a simple application:
#   common_application(<Name>)
#
# Input:
# * NAME_SOURCES for all compilation units
# * NAME_HEADERS for all internal header files
# * NAME_LINK_LIBRARIES for dependencies of name
# * ARGN for optional add_executable parameters
#
# Builds Name application and installs it.

# include(CMakeParseArguments)

function(COMMON_APPLICATION Name)
  string(TOUPPER ${Name} NAME)
  string(TOLOWER ${Name} name)
  set(SOURCES ${${NAME}_SOURCES})
  set(HEADERS ${${NAME}_HEADERS})
  set(LINK_LIBRARIES ${${NAME}_LINK_LIBRARIES})

  add_executable(${Name} ${ARGN} ${HEADERS} ${SOURCES})
  target_link_libraries(${Name} ${LINK_LIBRARIES})
  install(TARGETS ${Name} DESTINATION bin COMPONENT apps)
endfunction()
