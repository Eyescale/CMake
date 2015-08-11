# Copyright (c) 2014 Stefan.Eilemann@epfl.ch
#               2015 Raphael.Dumusc@epfl.ch

# Configures the build for a simple application:
#   common_application(<Name>)
#
# Input:
# * NAME_SOURCES for all compilation units
# * NAME_HEADERS for all internal header files
# * NAME_LINK_LIBRARIES for dependencies of name
# * NAME_OMIT_CHECK_TARGETS do not create cppcheck targets
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

include(AppleCheckOpenGL)
include(CommonCheckTargets)
include(CommonQtSupport)

# applying CMAKE_C(XX)_FLAGS to add_executable only works from parent scope, hence
# the macro calling the function _common_application
macro(COMMON_APPLICATION Name)
  common_compiler_flags()
  _common_application(${Name} ${ARGN})
endmacro()

function(_common_application Name)
  string(TOUPPER ${Name} NAME)
  string(TOLOWER ${Name} name)
  set(SOURCES ${${NAME}_SOURCES})
  set(HEADERS ${${NAME}_HEADERS} ${${NAME}_MOC_HEADERS})
  set(LINK_LIBRARIES ${${NAME}_LINK_LIBRARIES})

  common_qt_support(${NAME})
  list(APPEND SOURCES ${COMMON_QT_SUPPORT_SOURCES})

  add_executable(${Name} ${ARGN} ${HEADERS} ${SOURCES})
  set_target_properties(${Name} PROPERTIES FOLDER ${PROJECT_NAME})
  target_link_libraries(${Name} ${LINK_LIBRARIES})
  install(TARGETS ${Name} DESTINATION bin COMPONENT apps)

  # for DoxygenRule.cmake and SubProject.cmake
  set_property(GLOBAL APPEND PROPERTY ${PROJECT_NAME}_ALL_DEP_TARGETS ${Name})

  if(NOT ${NAME}_OMIT_CHECK_TARGETS)
    common_check_targets(${Name})
  endif()
  apple_check_opengl(${Name})
endfunction()

# applying CMAKE_C(XX)_FLAGS to add_executable only works from parent scope, hence
# the macro calling the function _common_gui_application
macro(common_gui_application Name)
  common_compiler_flags()
  _common_gui_application(${Name} ${ARGN})
endmacro()

function(_common_gui_application Name)
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

    _common_application(${Name} MACOSX_BUNDLE ${${NAME}_ICON} ${ARGN})

    set_target_properties(${Name} PROPERTIES MACOSX_BUNDLE_INFO_PLIST
      ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)

    # Bundle all dependent libraries inside the .app to make it self-contained
    # and generate a disk image containing the .app for redistributing it.
    set(_INSTALLDIR ${CMAKE_INSTALL_PREFIX}/bin)
    set(_BUNDLE ${_INSTALLDIR}/${Name}.app)
    set(_RESOURCES ${_BUNDLE}/Contents/Resources)
    set(_PLUGINS ${_BUNDLE}/Contents/PlugIns)

    # Copy all Qt plugins within the app (this step is missing in macdeployqt)
    set(_QT_ALL_PLUGINS ${Qt5Widgets_PLUGINS} ${Qt5Gui_PLUGINS})
    foreach(plugin ${_QT_ALL_PLUGINS})
      get_target_property(_loc ${plugin} LOCATION)
      get_filename_component(_name ${_loc} NAME)
      string(REGEX REPLACE ".*[/\\]([^/\\]*)[/\\]${_name}" "\\1" _dir ${_loc})
      install(FILES ${_loc} DESTINATION ${_PLUGINS}/${_dir} COMPONENT apps)
    endforeach()
    # Add a qt.conf file to locate plugins after deployment
    set(_QT_CONF "${CMAKE_CURRENT_BINARY_DIR}/qt.conf")
    file(WRITE ${_QT_CONF} "[Paths]\nPlugins = PlugIns\n")
    install(FILES ${_QT_CONF} DESTINATION ${_RESOURCES} COMPONENT apps)

    install(CODE "message(\"-- macdeployqt: ${_BUNDLE} -dmg\")" COMPONENT apps)
    install(CODE "execute_process(COMMAND macdeployqt ${Name}.app -dmg
      WORKING_DIRECTORY ${_INSTALLDIR})" COMPONENT apps)
    install(CODE "execute_process(COMMAND mv ${Name}.dmg ${Name}-${VERSION}.dmg
      WORKING_DIRECTORY ${_INSTALLDIR})" COMPONENT apps)
  elseif(MSVC)
    _common_application(${Name} WIN32 ${ARGN})
    # Qt5 gui applications need to link to WinMain on Windows
    list(FIND ${NAME}_LINK_LIBRARIES Qt5::Core _USING_QT)
    if(NOT _USING_QT EQUAL -1)
      target_link_libraries(${Name} Qt5::WinMain)
    endif()
  else()
    _common_application(${Name} ${ARGN})
  endif()
endfunction()
