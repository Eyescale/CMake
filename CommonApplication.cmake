# Copyright (c) 2014-2017 Stefan.Eilemann@epfl.ch
#                         Raphael.Dumusc@epfl.ch

# Configures the build for a simple application:
#   common_application(<Name> [GUI] [EXAMPLE] [NOHELP])
#
# Arguments:
# * GUI: if set, build cross-platform GUI application
# * EXAMPLE: install all sources in share/Project/examples/Name
# * NOHELP: opt out of doxygen help extraction
#
# Input:
# * NAME_SOURCES for all compilation units
# * NAME_HEADERS for all internal header files
# * NAME_SHADERS for all internal shader files (see StringifyShaders.cmake)
# * NAME_LINK_LIBRARIES for dependencies of name
# * NAME_OMIT_CHECK_TARGETS do not create cppcheck targets
# * ARGN for optional add_executable parameters
# * NAME_DATA files for share/Project/data (in binary and install dir)
# * NAME_ICON optional .icns file (Mac OS GUI applications only)
# * NAME_COPYRIGHT optional copyright notice (Mac OS GUI applications only)
#
# Output Global Properties
# * ${PROJECT_NAME}_HELP help page names generated (see DoxygenRule.cmake)
#
# Builds Name application and installs it.

include(AppleCheckOpenGL)
include(CommonCheckTargets)
include(CMakeParseArguments)
include(StringifyShaders)

function(common_application Name)
  set(_opts GUI EXAMPLE NOHELP WIN32)
  set(_singleArgs)
  set(_multiArgs)
  cmake_parse_arguments(THIS "${_opts}" "${_singleArgs}" "${_multiArgs}"
    ${ARGN})

  string(TOUPPER ${Name} NAME)
  string(TOLOWER ${Name} name)
  set(SOURCES ${${NAME}_SOURCES})
  set(HEADERS ${${NAME}_HEADERS})
  set(LINK_LIBRARIES ${${NAME}_LINK_LIBRARIES})
  set(_ICON ${${NAME}_ICON}) # also used to configure Info.plist

  if(${NAME}_SHADERS)
    stringify_shaders(${${NAME}_SHADERS})
    list(APPEND SOURCES ${SHADER_SOURCES})
  endif()

  set(OPTIONS)
  if(THIS_GUI)
    if(APPLE)
      set(OPTIONS MACOSX_BUNDLE)
    endif()
  endif()

  if(THIS_WIN32)
    if(MSVC)
      set(OPTIONS WIN32)
    endif()
  endif()

  add_executable(${Name} ${OPTIONS} ${_ICON} ${HEADERS} ${SOURCES})
  set_target_properties(${Name} PROPERTIES FOLDER ${PROJECT_NAME})
  common_compile_options(${Name})
  add_dependencies(${PROJECT_NAME}-all ${Name})
  target_link_libraries(${Name} ${LINK_LIBRARIES})
  install(TARGETS ${Name} DESTINATION bin COMPONENT apps)

  if(THIS_GUI AND APPLE)
    if(${NAME}_ICON)
      set_source_files_properties(${${NAME}_ICON}
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources)
    endif()
    # Configure bundle property file using current version, copyright and icon
    set(_BUNDLE_NAME ${Name})
    set(_COPYRIGHT ${${NAME}_COPYRIGHT})
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
    # run binary with --help to capture output for doxygen
    set(_doc "${PROJECT_BINARY_DIR}/help/${Name}.md")
    set(_cmake "${CMAKE_CURRENT_BINARY_DIR}/${Name}.cmake")
    file(WRITE ${_cmake} "
      execute_process(COMMAND \${APP} --help
      OUTPUT_FILE ${_doc} ERROR_FILE ${_doc}.error)
      file(READ ${_doc} _doc_content)
      if(NOT _doc_content)
        message(FATAL_ERROR \"${Name} is missing --help\")
      endif()
      file(WRITE ${_doc} \"${Name} {#${Name}}
============

```
\${_doc_content}
```
\")
")
    add_custom_command(OUTPUT ${_doc}
      COMMAND ${CMAKE_COMMAND} -DAPP=$<TARGET_FILE:${Name}> -P ${_cmake}
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
  endif()

  if(NOT ${NAME}_OMIT_CHECK_TARGETS)
    common_check_targets(${Name})
  endif()
  apple_check_opengl(${Name})
endfunction()
