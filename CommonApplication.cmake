# Copyright (c) 2014-2017 Stefan.Eilemann@epfl.ch
#                         Raphael.Dumusc@epfl.ch

# Configures the build for a simple application:
#   common_application(<Name> [GUI] [EXAMPLE] [NOHELP] [WIN32])
#
# Arguments:
# * GUI: if set, build cross-platform GUI application
# * EXAMPLE: install all sources in share/Project/examples/Name
# * NOHELP: opt out of doxygen help extraction
# * WIN32: build an executable with a WinMain entry point on Windows
#
# Input:
# * NAME_SOURCES for all compilation units
# * NAME_HEADERS for all internal header files
# * NAME_SHADERS for all internal shader files (see StringifyShaders.cmake)
# * NAME_LINK_LIBRARIES for dependencies of name
# * NAME_OMIT_CHECK_TARGETS do not create cppcheck targets
# * ARGN for optional add_executable parameters
# * NAME_DATA files for share/Project/data (in binary and install dir)
# * NAME_DESKTOP optional .desktop file (Linux GUI applications only).
#   Default: "lowercase(Name).desktop" if the file exists
# * NAME_ICON optional .icns (Mac OS) or .png (Linux) file (GUI app. only)
#   Default: "lowercase(Name).{icns|png}" if the file exists
# * NAME_COPYRIGHT optional copyright notice (Mac OS GUI applications only)
#
# Builds Name application, generates doxygen help page and installs it.

include(AppleCheckOpenGL)
include(CommonCheckTargets)
include(CommonHelp)
include(CMakeParseArguments)
include(StringifyShaders)

function(common_application Name)
  set(_opts GUI EXAMPLE NOHELP WIN32)
  set(_singleArgs)
  set(_multiArgs)
  cmake_parse_arguments(THIS "${_opts}" "${_singleArgs}" "${_multiArgs}"
    ${ARGN})

  if(THIS_WIN32 AND MSVC)
    set(_options WIN32)
  elseif(THIS_GUI AND APPLE)
    set(_options MACOSX_BUNDLE)
  endif()

  string(TOUPPER ${Name} NAME)
  string(TOLOWER ${Name} name)
  set(_sources ${${NAME}_SOURCES})
  set(_headers ${${NAME}_HEADERS})
  set(_libraries ${${NAME}_LINK_LIBRARIES})

  if(${NAME}_SHADERS)
    stringify_shaders(${${NAME}_SHADERS})
    list(APPEND _sources ${SHADER_SOURCES})
  endif()

  if(THIS_GUI)
    if(APPLE)
      set(_icon_file_candidate ${name}.icns)
    elseif(NOT MSVC)
      set(_icon_file_candidate ${name}.png)
      set(_desktop_file_candidate ${name}.desktop)
      if(DEFINED ${NAME}_DESKTOP)
        set(_desktop ${${NAME}_DESKTOP})
      elseif(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${_desktop_file_candidate})
        set(_desktop ${_desktop_file_candidate})
      endif()
    endif()

    # EXISTS only works with absolute file path
    if(DEFINED ${NAME}_ICON)
      set(_icon ${${NAME}_ICON})
    elseif(EXISTS ${CMAKE_CURRENT_LIST_DIR}/${_icon_file_candidate})
      set(_icon ${_icon_file_candidate})
    endif()
  endif()

  add_executable(${Name} ${_options} ${_icon} ${_desktop} ${_headers}
                 ${_sources})
  set_target_properties(${Name} PROPERTIES FOLDER ${PROJECT_NAME})
  common_compile_options(${Name})
  add_dependencies(${PROJECT_NAME}-all ${Name})
  target_link_libraries(${Name} ${_libraries})
  install(TARGETS ${Name} DESTINATION bin COMPONENT apps)

  if(THIS_GUI AND NOT APPLE AND NOT MSVC)
    if(_icon)
      install(FILES ${_icon} DESTINATION share/pixmaps COMPONENT apps)
    endif()
    if(_desktop)
      install(FILES ${_desktop} DESTINATION share/applications COMPONENT apps)
    endif()
  endif()

  if(THIS_GUI AND APPLE)
    if(_icon)
      set_source_files_properties(${_icon} PROPERTIES MACOSX_PACKAGE_LOCATION
        Resources)
    endif()
    # Configure bundle property file using current version, copyright and icon
    set(_BUNDLE_NAME ${Name})
    set(_COPYRIGHT ${${NAME}_COPYRIGHT})
    set(_ICON ${_icon})
    set(_VERSION ${${PROJECT_NAME}_VERSION})
    configure_file(${CMAKE_SOURCE_DIR}/CMake/common/Info.plist.in
      ${CMAKE_CURRENT_BINARY_DIR}/Info.plist @ONLY)

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

    set(_target_dmg "${Name}-${PROJECT_VERSION}.dmg")
    install(CODE "execute_process(COMMAND macdeployqt ${Name}.app -dmg
      WORKING_DIRECTORY ${_INSTALLDIR})" COMPONENT apps)
    install(CODE "execute_process(COMMAND mv ${Name}.dmg ${_target_dmg}
      WORKING_DIRECTORY ${_INSTALLDIR})" COMPONENT apps)
  endif()

  if(THIS_EXAMPLE)
    install_files(share/${PROJECT_NAME}/examples/${Name}
      FILES ${${NAME}_HEADERS} ${${NAME}_SOURCES} ${${NAME}_SHADERS}
      COMPONENT examples)

    if(${NAME}_DATA)
      file(COPY ${${NAME}_DATA}
        DESTINATION ${CMAKE_BINARY_DIR}/share/${PROJECT_NAME}/data)
      install(FILES ${${NAME}_DATA}
        DESTINATION share/${PROJECT_NAME}/data COMPONENT examples)
    endif()
  endif()

  if(NOT THIS_NOHELP)
    common_help(${Name})
  endif()

  if(NOT ${NAME}_OMIT_CHECK_TARGETS)
    common_check_targets(${Name})
  endif()
  apple_check_opengl(${Name})
endfunction()
