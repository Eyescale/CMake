# Copyright (c) 2014 Stefan.Eilemann@epfl.ch

# Configures the build for a simple application:
#   common_application(<Name>)
#
# Input:
# * NAME_SOURCES for all compilation units
# * NAME_HEADERS for all internal header files
# * NAME_LINK_LIBRARIES for dependencies of name
# * ARGN for optional add_executable parameters
# * Optional Qt support:
# ** NAME_MOC_HEADERS list of all moc input headers
# ** NAME_UI_FORMS list of all .ui input files
# ** NAME_RESOURCES list of all .qrc resource files
#
# Builds Name application and installs it.

# include(CMakeParseArguments)

function(COMMON_APPLICATION Name)
  string(TOUPPER ${Name} NAME)
  string(TOLOWER ${Name} name)
  set(SOURCES ${${NAME}_SOURCES})
  set(HEADERS ${${NAME}_HEADERS})
  set(LINK_LIBRARIES ${${NAME}_LINK_LIBRARIES})

  if(${NAME}_MOC_HEADERS)
    if(NOT QT4_FOUND)
      message(FATAL_ERROR "Qt4 not found, needed for application ${Name}")
    endif()
    qt4_wrap_cpp(MOC_SOURCES ${${NAME}_MOC_HEADERS})
    list(APPEND HEADERS ${${NAME}_MOC_HEADERS})
    list(APPEND SOURCES ${MOC_SOURCES})
  endif()
  if(${NAME}_UI_FORMS)
    qt4_wrap_ui(UI_SOURCES ${${NAME}_UI_FORMS})
    list(APPEND SOURCES ${UI_SOURCES})
    include_directories(${PROJECT_BINARY_DIR})
  endif()
  if(${NAME}_RESOURCES)
    qt4_add_resources(QRC_SOURCES ${LIVREGUI_RESOURCES})
    list(APPEND SOURCES ${QRC_SOURCES})
  endif()

  add_executable(${Name} ${ARGN} ${HEADERS} ${SOURCES})
  target_link_libraries(${Name} ${LINK_LIBRARIES})
  install(TARGETS ${Name} DESTINATION bin COMPONENT apps)
endfunction()
