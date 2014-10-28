
# Copyright (c) 2013 Daniel Nachbaur <daniel.nachbaur@epfl.ch>

# This file creates package information for find_package by generating
# ${PROJECT_NAME}Config.cmake and ${PROJECT_NAME}ConfigVersion.cmake
# files. Those files are used in the config-mode of find_package which
# supersedes the Find${PROJECT_NAME}.cmake file.
#
# Input variables
#   CPACK_PACKAGE_NAME - The package name
#   ${UPPER_PROJECT_NAME}_DEPENDENT_LIBRARIES - A list of dependent link
#     libraries, format is ${PROJECT_NAME}
#   ${UPPER_PROJECT_NAME}_FIND_FILES - A list of files to find if no libraries
#     are produced
#   ${UPPER_PROJECT_NAME}_EXCLUDE_LIBRARIES - A list of library targets
#     to remove from the list of exported libraries
#
# Output variables
#   ${UPPER_PROJECT_NAME}_FOUND - Was the project and all of the specified
#     components found?
#   ${PROJECT_NAME}_FOUND - Same as above
#
#   ${UPPER_PROJECT_NAME}_VERSION - The version of the project which was found
#   ${UPPER_PROJECT_NAME}_VERSION_ABI - The ABI version of the project which was found
#   ${UPPER_PROJECT_NAME}_INCLUDE_DIRS - Where to find the headers
#   ${UPPER_PROJECT_NAME}_LIBRARIES - The project link libraries
#   ${UPPER_PROJECT_NAME}_LIBRARY - The produced (core) library
#   ${UPPER_PROJECT_NAME}_COMPONENTS - A list of components found
#   ${UPPER_PROJECT_NAME}_${component}_LIBRARY - The path & name of the
#     ${component} library
#   ${UPPER_PROJECT_NAME}_DEB_DEPENDENCIES - A list of dependencies for the
#     CPack deb generator
#   ${UPPER_PROJECT_NAME}_DEB_LIB_DEPENDENCY - The runtime dependency for the
#     CPack deb generator
#   ${UPPER_PROJECT_NAME}_DEB_DEV_DEPENDENCY - The compile-time dependency for
#     the CPack deb generator


if(PACKAGECONFIG_DONE)
  return()
endif()
set(PACKAGECONFIG_DONE ON)

include(CMakePackageConfigHelpers)
include(${CMAKE_CURRENT_LIST_DIR}/CMakeInstallPath.cmake)

# Write the ProjectConfig.cmake.in file for configure_package_config_file
# this will be copied eventually into the install directory
set(_config_file_prefix
  "\n"
# add helper stuff from CMakePackageConfigHelpers
  "@PACKAGE_INIT@\n"
  "\n"
  "set(${PROJECT_NAME}_PREFIX_DIR \${PACKAGE_PREFIX_DIR})\n"
  "if(CMAKE_VERSION VERSION_LESS 2.8.3) # WAR bug\n"
  "  get_filename_component(CMAKE_CURRENT_LIST_DIR \${CMAKE_CURRENT_LIST_FILE} PATH)\n"
  "endif()\n"
  "list(APPEND CMAKE_MODULE_PATH \${CMAKE_CURRENT_LIST_DIR})\n"
)

set(_config_file_body
# reset before using them
  "set(_output_type)\n"
  "set(_out)\n"
  "set(_req)\n"
  "set(_quiet)\n"
  "set(_fail)\n"
  "set(${UPPER_PROJECT_NAME}_COMPONENTS)\n"
  "if(NOT ${UPPER_PROJECT_NAME}_FOUND)\n"
  "  set(${UPPER_PROJECT_NAME}_STATUS ON)\n"
  "else()\n"
  "  set(${UPPER_PROJECT_NAME}_STATUS)\n"
  "endif()\n"
  "\n"
# add dependent library finding
  "@DEPENDENTS@"
  "set(${UPPER_PROJECT_NAME}_FIND_FILES ${${UPPER_PROJECT_NAME}_FIND_FILES})\n"
)

set(_config_file_standard_find
  "if(NOT _fail)\n"
# setup INCLUDE_DIRS and DEB_DEPENDENCIES
  "  list(APPEND ${UPPER_PROJECT_NAME}_INCLUDE_DIRS \${${PROJECT_NAME}_PREFIX_DIR}/include)\n"
  "  set(${UPPER_PROJECT_NAME}_DEB_DEPENDENCIES \"${CPACK_PACKAGE_NAME} (>= ${VERSION_MAJOR}.${VERSION_MINOR})\")\n"
  "  set(${UPPER_PROJECT_NAME}_DEB_LIB_DEPENDENCY \"${CPACK_PACKAGE_NAME}-lib (>= ${VERSION_MAJOR}.${VERSION_MINOR})\")\n"
  "  set(${UPPER_PROJECT_NAME}_DEB_DEV_DEPENDENCY \"${CPACK_PACKAGE_NAME}-dev (>= ${VERSION_MAJOR}.${VERSION_MINOR})\")\n"
  "\n"
# find components if specified
  "  if(${PROJECT_NAME}_FIND_COMPONENTS)\n"
  "    find_library(\${UPPER_PROJECT_NAME}_LIBRARY ${PROJECT_NAME} NO_DEFAULT_PATH\n"
  "                 PATHS \${${PROJECT_NAME}_PREFIX_DIR} PATH_SUFFIXES lib ${PYTHON_LIBRARY_PREFIX})\n"
  "    list(APPEND ${UPPER_PROJECT_NAME}_LIBRARIES \${${UPPER_PROJECT_NAME}_LIBRARY})\n"
  "    foreach(_component \${${PROJECT_NAME}_FIND_COMPONENTS})\n"
  "      find_library(\${_component}_libraryname ${PROJECT_NAME}_\${_component} NO_DEFAULT_PATH\n"
  "        PATHS \${${PROJECT_NAME}_PREFIX_DIR} PATH_SUFFIXES lib ${PYTHON_LIBRARY_PREFIX})\n"
  "\n"
  "      if(\${_component}_libraryname MATCHES \"\${_component}_libraryname-NOTFOUND\")\n"
  "        if(${PROJECT_NAME}_FIND_REQUIRED_\${_component})\n"
  "          set(_fail \"Component library \${_component} not found\")\n"
  "          message(FATAL_ERROR \"   ${PROJECT_NAME}_\${_component} \"\n"
  "            \"not found in \${${PROJECT_NAME}_PREFIX_DIR}/lib\")\n"
  "        elseif(NOT _quiet)\n"
  "          message(STATUS \"   ${PROJECT_NAME}_\${_component} \"\n"
  "            \"not found in \${${PROJECT_NAME}_PREFIX_DIR}/lib\")\n"
  "        endif()\n"
  "      else()\n"
  "        string(TOUPPER \${_component} _COMPONENT)\n"
  "        set(${UPPER_PROJECT_NAME}_\${_COMPONENT}_FOUND TRUE)\n"
  "        set(${UPPER_PROJECT_NAME}_\${_COMPONENT}_LIBRARY \${\${_component}_libraryname})\n"
  "        list(APPEND ${UPPER_PROJECT_NAME}_LIBRARIES \${\${_component}_libraryname})\n"
  "        list(APPEND ${UPPER_PROJECT_NAME}_COMPONENTS \${_component})\n"
  "      endif()\n"
  "    endforeach()\n"
# search for ${UPPER_PROJECT_NAME}_FIND_FILES
  "  elseif(${UPPER_PROJECT_NAME}_FIND_FILES)\n"
  "    find_file(${UPPER_PROJECT_NAME}_FILE NAMES ${${UPPER_PROJECT_NAME}_FIND_FILES} NO_DEFAULT_PATH\n"
  "              PATHS \${${PROJECT_NAME}_PREFIX_DIR} PATH_SUFFIXES include)\n"
  "    if(${UPPER_PROJECT_NAME}_FILE MATCHES \"${UPPER_PROJECT_NAME}_FILE-NOTFOUND\")\n"
  "      set(_fail \"${${UPPER_PROJECT_NAME}_FIND_FILES} not found\")\n"
  "      if(_out)\n"
  "        message(\${_output_type} \"   Missing the ${PROJECT_NAME} \"\n"
  "          \"file in \${${PROJECT_NAME}_PREFIX_DIR}/include.\")\n"
  "      endif()\n"
  "    endif()\n"
  "  else()\n"
# if no component or file was specified, find all produced libraries
  "    set(${UPPER_PROJECT_NAME}_LIBRARY_NAMES \"@LIBRARY_NAMES@\")\n"
  "    foreach(_libraryname \${${UPPER_PROJECT_NAME}_LIBRARY_NAMES})\n"
  "      string(TOUPPER \${_libraryname} _LIBRARYNAME)\n"
  "      find_library(\${_LIBRARYNAME}_LIBRARY \${_libraryname} NO_DEFAULT_PATH\n"
  "                   PATHS \${${PROJECT_NAME}_PREFIX_DIR} PATH_SUFFIXES lib ${PYTHON_LIBRARY_PREFIX})\n"
  "      if(\${_LIBRARYNAME}_LIBRARY MATCHES \"\${_LIBRARYNAME}_LIBRARY-NOTFOUND\")\n"
  "        set(_fail \"\${_libraryname} not found\")\n"
  "        if(_out)\n"
  "          message(\${_output_type}\n"
  "            \"   Missing \${_libraryname} in \${${PROJECT_NAME}_PREFIX_DIR}/lib\")\n"
  "        endif()\n"
  "      else()\n"
  "        list(APPEND ${UPPER_PROJECT_NAME}_LIBRARIES \${\${_LIBRARYNAME}_LIBRARY})\n"
  "        string(REPLACE \"${PROJECT_NAME}_\" \"\" _component \${_libraryname})\n"
  "        string(TOUPPER \${_component} _COMPONENT)\n"
  "        set(${UPPER_PROJECT_NAME}_\${_COMPONENT}_FOUND TRUE)\n"
  "        list(APPEND ${UPPER_PROJECT_NAME}_COMPONENTS \${_component})\n"
  "      endif()\n"
  "    endforeach()\n"
  "  endif()\n"
  "\n"
# include options.cmake if existing
  "  if(EXISTS \${${PROJECT_NAME}_PREFIX_DIR}/${CMAKE_MODULE_INSTALL_PATH}/options.cmake)\n"
  "    include(\${${PROJECT_NAME}_PREFIX_DIR}/${CMAKE_MODULE_INSTALL_PATH}/options.cmake)\n"
  "  endif()\n"
  "endif()\n"
  "\n"
)

set(_config_file_subproject_find
  "if(NOT _fail)\n"
# setup INCLUDE_DIRS and DEB_DEPENDENCIES
  "  list(APPEND ${UPPER_PROJECT_NAME}_INCLUDE_DIRS \${${PROJECT_NAME}_PREFIX_DIR}/include)\n"
  "  set(${UPPER_PROJECT_NAME}_DEB_DEPENDENCIES \"${CPACK_PACKAGE_NAME} (>= ${VERSION_MAJOR}.${VERSION_MINOR})\")\n"
  "  set(${UPPER_PROJECT_NAME}_DEB_LIB_DEPENDENCY \"${CPACK_PACKAGE_NAME}-lib (>= ${VERSION_MAJOR}.${VERSION_MINOR})\")\n"
  "  set(${UPPER_PROJECT_NAME}_DEB_DEV_DEPENDENCY \"${CPACK_PACKAGE_NAME}-dev (>= ${VERSION_MAJOR}.${VERSION_MINOR})\")\n"
  "\n"
# find components if specified
  "  if(${PROJECT_NAME}_FIND_COMPONENTS)\n"
  "    list(APPEND ${UPPER_PROJECT_NAME}_LIBRARIES \${${PROJECT_NAME}})\n"
  "    foreach(_component \${${PROJECT_NAME}_FIND_COMPONENTS})\n"
  "      string(TOUPPER \${_component} _COMPONENT)\n"
  "      set(${UPPER_PROJECT_NAME}_\${_COMPONENT}_FOUND TRUE)\n"
  "      set(${UPPER_PROJECT_NAME}_\${_COMPONENT}_LIBRARY \${\${_component}_libraryname})\n"
  "      list(APPEND ${UPPER_PROJECT_NAME}_LIBRARIES \${\${_component}_libraryname})\n"
  "      list(APPEND ${UPPER_PROJECT_NAME}_COMPONENTS \${_component})\n"
  "    endforeach()\n"
# search for ${UPPER_PROJECT_NAME}_FIND_FILES
  "  elseif(${UPPER_PROJECT_NAME}_FIND_FILES)\n"
  "  else()\n"
# if no component or file was specified, find all produced libraries
  "    set(${UPPER_PROJECT_NAME}_LIBRARY_NAMES \"@LIBRARY_NAMES@\")\n"
  "    foreach(_libraryname \${${UPPER_PROJECT_NAME}_LIBRARY_NAMES})\n"
  "      list(APPEND ${UPPER_PROJECT_NAME}_LIBRARIES \${_libraryname})\n"
  "    endforeach()\n"
  "  endif()\n"
  "\n"
# include options.cmake if existing
  "  if(EXISTS \${${PROJECT_NAME}_PREFIX_DIR}/options.cmake)\n"
  "    include(\${${PROJECT_NAME}_PREFIX_DIR}/options.cmake)\n"
  "  endif()\n"
  "endif()\n"
  "\n"
)


set(_config_file_final
# finally report about found or not found
  "if(_fail)\n"
  "  set(${UPPER_PROJECT_NAME}_FOUND)\n"
  "  set(${PROJECT_NAME}_FOUND)\n"
  "  set(${UPPER_PROJECT_NAME}_VERSION)\n"
  "  set(${UPPER_PROJECT_NAME}_VERSION_ABI)\n"
  "  set(${UPPER_PROJECT_NAME}_INCLUDE_DIRS)\n"
  "  set(${UPPER_PROJECT_NAME}_LIBRARIES)\n"
  "  set(${UPPER_PROJECT_NAME}_DEB_DEPENDENCIES)\n"
  "  set(${UPPER_PROJECT_NAME}_LIBRARY)\n"
  "  set(${UPPER_PROJECT_NAME}_COMPONENTS)\n"
  "  if(_out)\n"
  "    message(STATUS \"Could not find ${PROJECT_NAME}: \${_fail}\")\n"
  "  endif()\n"
  "else()\n"
  "  set(${UPPER_PROJECT_NAME}_FOUND TRUE)\n"
  "  set(${PROJECT_NAME}_FOUND TRUE)\n"
  "  set(${UPPER_PROJECT_NAME}_VERSION ${VERSION})\n"
  "  set(${UPPER_PROJECT_NAME}_VERSION_ABI ${VERSION_ABI})\n"
  "  set(${UPPER_PROJECT_NAME}_MODULE_FILENAME ${MODULE_FILENAME})\n"
  "  list(SORT ${UPPER_PROJECT_NAME}_INCLUDE_DIRS)\n"
  "  list(REMOVE_DUPLICATES ${UPPER_PROJECT_NAME}_INCLUDE_DIRS)\n"
  "  if(${UPPER_PROJECT_NAME}_LIBRARIES)\n"
  "    list(REMOVE_DUPLICATES ${UPPER_PROJECT_NAME}_LIBRARIES)\n"
  "  endif()\n"
  "  if(_out AND ${UPPER_PROJECT_NAME}_STATUS)\n"
  "    message(STATUS \"Found ${PROJECT_NAME} ${VERSION}-${VERSION_ABI} [\${${UPPER_PROJECT_NAME}_COMPONENTS}] in \"\n"
  "      \"\${${UPPER_PROJECT_NAME}_INCLUDE_DIRS}:\${${UPPER_PROJECT_NAME}_LIBRARY}\")\n"
  "  endif()\n"
  "endif()\n"
)

file(WRITE ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}Config.cmake.in
  ${_config_file_prefix}
  ${_config_file_body}
  ${_config_file_standard_find}
  ${_config_file_final}
)

# write a project config which will be used to find packages in the build directory
# when projects are compiled as subprojects of another larger project
file(WRITE ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}Config.cmake.build.in
  "set(${PROJECT_NAME}_PREFIX_DIR ${PROJECT_BINARY_DIR})\n"
  "set(${UPPER_PROJECT_NAME}_INCLUDE_DIRS ${PROJECT_SOURCE_DIR})\n"
  "\n"
  ${_config_file_body}
  ${_config_file_subproject_find}
  ${_config_file_final}
)

# location of the includes
set(INCLUDE_INSTALL_DIR include)

# compile the list of generated libraries excluding those
# from ${UPPER_PROJECT_NAME}_EXCLUDE_LIBRARY_TARGETS
get_property(_all_lib_targets GLOBAL PROPERTY ${PROJECT_NAME}_ALL_LIB_TARGETS)
set(LIBRARY_NAMES)
foreach(_target ${_all_lib_targets})
  list(FIND ${UPPER_PROJECT_NAME}_EXCLUDE_LIBRARIES ${_target}
       _contains_${target})
  if(${_contains_${target}} STREQUAL -1)
    get_target_property(_libraryname ${_target} OUTPUT_NAME)
    if(${_libraryname} MATCHES "_libraryname-NOTFOUND")
      set(_libraryname ${_target})
    endif()
    list(APPEND LIBRARY_NAMES ${_libraryname})
  endif()
endforeach()

# compile finding of dependent libraries (ProjectConfig.cmake)
# 1. set the search mode for the dependent projects [ required | optional ]
set(DEPENDENTS
  "if(${PROJECT_NAME}_FIND_REQUIRED)\n"
  "  set(_output_type FATAL_ERROR)\n"
  "  set(_out 1)\n"
  "  set(_req REQUIRED)\n"
  "else()\n"
  "  set(_output_type STATUS)\n"
  "  if(NOT ${PROJECT_NAME}_FIND_QUIETLY)\n"
  "    set(_out 1)\n"
  "  endif()\n"
  "endif()\n"
  "if(${PROJECT_NAME}_FIND_QUIETLY)\n"
  "  set(_quiet QUIET)\n"
  "endif()\n\n"
)

# 2. add code to find each individual dependency
foreach(_dependent ${${UPPER_PROJECT_NAME}_DEPENDENT_LIBRARIES})
  string(TOUPPER ${_dependent} _DEPENDENT)
  # Check if the dependant project uses mixed case or upper case for its name
  # (e.g. Boost_FOUND or BOOST_FOUND) and set ${_dependent}_name accordingly.
  # This is generally already done by FindPackages.cmake
  if(NOT ${_dependent}_name)
    if(${_DEPENDENT}_FOUND)
      set(${_dependent}_name ${_DEPENDENT})
    elseif(${_dependent}_FOUND)
      set(${_dependent}_name ${_dependent})
    else()
      message(FATAL_ERROR
        "Dependent library ${_dependent} was not properly resolved")
    endif()
  endif()

  # determine the appropriate version of the dependency
  if(${${_dependent}_name}_VERSION)
    set(_FIND_VERSION "${${${_dependent}_name}_VERSION}")
    if("${_FIND_VERSION}" MATCHES "^([0-9]+\\.[0-9]+)")
      set(_FIND_VERSION "${CMAKE_MATCH_1}")
    endif()
  else()
    set(_FIND_VERSION)
  endif()

  # Use the components specified by FindPackages.cmake
  set(${_dependent}_components "${${UPPER_PROJECT_NAME}_${_DEPENDENT}_COMPONENTS}")
  if(${_dependent}_components)
     set(_components "COMPONENTS ${${_dependent}_components}" )
  else()
     set(_components)
  endif()
  list(APPEND DEPENDENTS
    "set(_${${_dependent}_name}_libraries_backup \${${${_dependent}_name}_LIBRARIES})\n"
    "set(_${${_dependent}_name}_found_backup \${${${_dependent}_name}_FOUND})\n"
    # Reset previously found dependent libraries
    "set(${${_dependent}_name}_LIBRARIES)\n"
    "set(${${_dependent}_name}_FOUND)\n"
    "find_package(${_dependent} ${_FIND_VERSION} QUIET \${_req} ${_components})\n"
    "if(${${_dependent}_name}_FOUND)\n" )

  # if possible, look for the exact ABI version of the dependency that was used to build this project.
  # PackageConfig.cmake files generated by Buildyard have this value, but external projects do not have it
  if(${${_dependent}_name}_VERSION_ABI)
    set(_find_abi_version ${${${_dependent}_name}_VERSION_ABI})
    list(APPEND DEPENDENTS
      "  if(NOT \${${${_dependent}_name}_VERSION_ABI} VERSION_EQUAL ${_find_abi_version})\n"
      "    message(FATAL_ERROR \"${${_dependent}_name} ABI version '\${${${_dependent}_name}_VERSION_ABI}' not compatible with expected version '${_find_abi_version}'\")\n"
      "  endif()\n")
  # if it is not possible to match the ABI version, work around by looking for a close version match,
  # i.e. VERSION_MAJOR + VERSION_MINOR. For example, Boost 1.54.x.
  elseif(_FIND_VERSION)
    list(APPEND DEPENDENTS
      "  if(\"\${${${_dependent}_name}_VERSION}\" MATCHES \"^([0-9]+\\\\.[0-9]+)\")\n"
      "    if(NOT CMAKE_MATCH_1 VERSION_EQUAL ${_FIND_VERSION})\n"
      "      message(FATAL_ERROR \"${${_dependent}_name} \${CMAKE_MATCH_1} does not match expected version ${_FIND_VERSION}\")\n"
      "    endif()\n"
      "  endif()\n")
  endif()
  list(APPEND DEPENDENTS
    "  list(APPEND ${UPPER_PROJECT_NAME}_LIBRARIES \${${${_dependent}_name}_LIBRARIES})\n"
    "  list(APPEND ${UPPER_PROJECT_NAME}_INCLUDE_DIRS \${${${_dependent}_name}_INCLUDE_DIRS})\n"
    "else()\n"
    "  set(_fail \"${_dependent} not found\")\n"
    "endif()\n"
    # Restore the situation of the dependent library without accumulating the dependent libraries
    "set(${${_dependent}_name}_LIBRARIES \${_${${_dependent}_name}_libraries_backup})\n"
    "set(${${_dependent}_name}_FOUND \${_${${_dependent}_name}_found_backup})\n\n")
endforeach()
string(REGEX REPLACE ";" " " DEPENDENTS ${DEPENDENTS})

# 3. create ProjectConfig.cmake by adding DEPENDENTS to ProjectConfig.cmake.in
if(LIBRARY_NAMES)
  set(HAS_LIBRARY_NAMES LIBRARY_NAMES)
endif()

configure_package_config_file(
  ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}Config.cmake.in
  ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}Config.cmake
  INSTALL_DESTINATION ${CMAKE_MODULE_INSTALL_PATH}
  PATH_VARS INCLUDE_INSTALL_DIR ${HAS_LIBRARY_NAMES} DEPENDENTS
  NO_CHECK_REQUIRED_COMPONENTS_MACRO)

configure_file(
  ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}Config.cmake.build.in
  ${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
  @ONLY
)

# create and install ProjectConfigVersion.cmake
write_basic_package_version_file(
  ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}ConfigVersion.cmake
  VERSION ${VERSION_MAJOR}.${VERSION_MINOR} COMPATIBILITY SameMajorVersion)

install(
  FILES ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}Config.cmake
        ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}ConfigVersion.cmake
  DESTINATION ${CMAKE_MODULE_INSTALL_PATH} COMPONENT dev)

configure_file(
  ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}ConfigVersion.cmake
  ${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
  COPYONLY
)


# create and install Project.pc
if(NOT LIBRARY_DIR)
  set(LIBRARY_DIR lib)
endif()

file(WRITE ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}.pc
  "prefix=${CMAKE_INSTALL_PREFIX}\n"
  "exec_prefix=\${prefix}\n"
  "libdir=\${exec_prefix}/${LIBRARY_DIR}\n"
  "includedir=\${prefix}/include\n\n"
  "Name: ${PROJECT_NAME}\n"
  "Description: ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}\n"
  "Version: ${VERSION}\n"
  "Requires: ${CPACK_PACKAGE_CONFIG_REQUIRES}\n"
  "Conflicts: ${CPACK_PACKAGE_CONFIG_CONFLICTS}\n"
  "Cflags: -I\${includedir}\n"
  "Libs: -L\${libdir}" )
foreach(_library ${LIBRARY_NAMES})
  file(APPEND ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}.pc
    " -l${_library}")
endforeach()
file(APPEND ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}.pc "\n")

install(FILES ${PROJECT_BINARY_DIR}/pkg/${PROJECT_NAME}.pc
  DESTINATION ${LIBRARY_DIR}/pkgconfig COMPONENT dev)
