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
# Cross-platform wrapper around common_application() for GUI applications:
#   common_gui_application(<Name>)
#
# Optional OSX bundle support (in conjunction with MACOSX_BUNDLE argument):
# * NAME_ICON optional .icns file
# * NAME_COPYRIGHT optional copyright notice
#
# Builds Name application and installs it.

include(CommonQtSupport)

function(COMMON_APPLICATION Name)
  string(TOUPPER ${Name} NAME)
  string(TOLOWER ${Name} name)
  set(SOURCES ${${NAME}_SOURCES})
  set(HEADERS ${${NAME}_HEADERS} ${${NAME}_MOC_HEADERS})
  set(LINK_LIBRARIES ${${NAME}_LINK_LIBRARIES})

  common_qt_support(${NAME})
  list(APPEND SOURCES ${COMMON_QT_SUPPORT_SOURCES})

  add_executable(${Name} ${ARGN} ${HEADERS} ${SOURCES})
  target_link_libraries(${Name} ${LINK_LIBRARIES})
  install(TARGETS ${Name} DESTINATION bin COMPONENT apps)
endfunction()

function(COMMON_GUI_APPLICATION Name)
string(TOUPPER ${Name} NAME)

if(APPLE)
  if(${NAME}_ICON)
    set_source_files_properties(${${NAME}_ICON}
      PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
  endif()
  # Configure bundle property file using current version, copyright and icon
  set(_BUNDLE_NAME ${Name})
  set(_COPYRIGHT ${${NAME}_COPYRIGHT})
  set(_ICON ${${NAME}_ICON})
  configure_file(${CMAKE_SOURCE_DIR}/CMake/common/Info.plist.in
    ${CMAKE_CURRENT_BINARY_DIR}/Info.plist @ONLY)

  common_application(${Name} MACOSX_BUNDLE ${${NAME}_ICON} ${ARGN})

  set_target_properties(${Name} PROPERTIES MACOSX_BUNDLE_INFO_PLIST
    ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)

  # Bundle all dependent libraries inside the .app to make it self-contained
  # and generate a disk image containing the .app for redistributing it.
  set(_INSTALLDIR ${CMAKE_INSTALL_PREFIX}/bin)
  install(CODE "message(\"-- macdeployqt: ${_INSTALLDIR}/${Name}.app -dmg\")"
    COMPONENT apps)
  install(CODE "execute_process(COMMAND macdeployqt ${Name}.app -dmg
    WORKING_DIRECTORY ${_INSTALLDIR})" COMPONENT apps)
  install(CODE "execute_process(COMMAND mv ${Name}.dmg ${Name}-${VERSION}.dmg
    WORKING_DIRECTORY ${_INSTALLDIR})" COMPONENT apps)
elseif(MSVC)
  common_application(${Name} WIN32 ${ARGN})
  # Qt5 gui applications need to link to WinMain on Windows
  list(FIND ${NAME}_LINK_LIBRARIES Qt5::Core _USING_QT)
  if(NOT _USING_QT EQUAL -1)
    target_link_libraries(${Name} Qt5::WinMain)
  endif()
else()
  common_application(${Name} ${ARGN})
endif()
endfunction()
