# Copyright (c) 2014-2016 Stefan.Eilemann@epfl.ch
#                         Daniel.Nachbaur@epfl.ch

# Configures the build for a simple library:
#   common_library(<Name>)
#
# Uses:
# * NAME_SOURCES for all compilation units
# * NAME_HEADERS for all internal header files
# * NAME_PUBLIC_HEADERS for public, installed header files
# * NAME_PUBLIC_INCLUDE_DIRECTORIES for transitive dependencies of name which
#   are not targets (e.g. Boost_INCLUDE_DIRS).
# * NAME_LINK_LIBRARIES for dependencies of name. Use targets rather than
#   NAME_LIBRARIES variable. Also use PUBLIC and PRIVATE for declaring
#   transitive dependencies for export target generation.
# * NAME_LIBRARY_TYPE or COMMON_LIBRARY_TYPE for SHARED or STATIC library, with
#   COMMON_LIBRARY_TYPE being an option stored in the CMakeCache.
# * NAME_OMIT_LIBRARY_HEADER when set, no library header (name.h) is generated.
# * NAME_OMIT_VERSION_HEADERS when set, no api.h, version.h|cpp are generated.
# * NAME_INCLUDE_NAME for the include directory and library header
# * NAME_NAMESPACE for api.h and version.h
# * NAME_OMIT_CHECK_TARGETS do not create cppcheck targets
# * NAME_OMIT_EXPORT do not export target in CommonPackageConfig.cmake
# * NAME_OMIT_INSTALL do not install, for example a library for unit tests
# * ${PROJECT_NAME}_VERSION for the API version
# * ${PROJECT_NAME}_VERSION_ABI for the ABI version
#
# Output global property:
# * ${PROJECT_NAME}_COVERAGE_INPUT_DIRS: Each library's CURRENT_BINARY_DIR
#   is appended to this list consumed by CommonCoverage.cmake.
#
# If NAME_LIBRARY_TYPE is a list, libraries are built of each specified
# (i.e. shared and static) type. Whichever is first becomes the library
# target associated with <Name>.
#
# Builds libName and installs it. Installs the public headers to include/name.
# Generates a NAME_INCLUDE_NAME/{BASE_NAME of NAME_INCLUDE_NAME}.h
# including all public headers.
#
# Options
# By default on windows platforms "_D" is appended to libraries
# if COMMON_LIBRARY_DEBUG_POSTFIX is ON then "_debug" is added on other platforms
#

include(CommonCheckTargets)
include(InstallFiles)

set(COMMON_LIBRARY_TYPE SHARED CACHE STRING
  "Library type {any combination of SHARED, STATIC}")
set_property(CACHE COMMON_LIBRARY_TYPE PROPERTY STRINGS SHARED STATIC)

function(common_library Name)
  string(TOUPPER ${Name} NAME)

  set(INCLUDE_NAME ${${NAME}_INCLUDE_NAME})
  if(NOT INCLUDE_NAME)
    set(INCLUDE_NAME ${PROJECT_INCLUDE_NAME})
  endif()

  set(namespace ${${NAME}_NAMESPACE})
  if(NOT namespace)
    set(namespace ${PROJECT_namespace})
  endif()
  string(TOUPPER ${namespace} NAMESPACE)

  set(SOURCES ${${NAME}_SOURCES})
  set(HEADERS ${${NAME}_HEADERS})
  set(PUBLIC_HEADERS ${${NAME}_PUBLIC_HEADERS})
  set(LINK_LIBRARIES ${${NAME}_LINK_LIBRARIES})

  # Generate api.h and version.h/cpp for non-interface libraries
  if(${NAME}_SOURCES AND NOT ${NAME}_OMIT_VERSION_HEADERS)
    generate_version_headers()
  endif()

  if(NOT ${NAME}_OMIT_LIBRARY_HEADER)
    generate_library_header(${NAME})
  endif()

  if(SOURCES)
    list(SORT SOURCES)
  endif()
  if(HEADERS)
    list(SORT HEADERS)
  endif()
  if(PUBLIC_HEADERS)
    list(SORT PUBLIC_HEADERS)
  endif()

  source_group(\\ FILES CMakeLists.txt)
  source_group(${INCLUDE_NAME} FILES ${SOURCES} ${HEADERS} ${PUBLIC_HEADERS})

  if(NOT ${NAME}_LIBRARY_TYPE)
    set(${NAME}_LIBRARY_TYPE ${COMMON_LIBRARY_TYPE})
    if(NOT ${NAME}_LIBRARY_TYPE)
      set(${NAME}_LIBRARY_TYPE SHARED)
    endif()
  endif()
  foreach(LIBRARY_TYPE ${${NAME}_LIBRARY_TYPE})
    set(LibName ${Name})
    if(TARGET ${Name})
      set(LibName "${Name}_${LIBRARY_TYPE}")
    endif()

    if(NOT ${NAME}_SOURCES)
      add_library(${LibName} INTERFACE)
      _target_include_directories(INTERFACE)
    else()
      # append a debug suffix to library name on windows or if user requests it
      common_set_lib_name_postfix()

      add_library(${LibName} ${LIBRARY_TYPE}
        ${SOURCES} ${HEADERS} ${PUBLIC_HEADERS})
      set_target_properties(${LibName} PROPERTIES
        VERSION ${${PROJECT_NAME}_VERSION}
        SOVERSION ${${PROJECT_NAME}_VERSION_ABI}
        OUTPUT_NAME ${Name} FOLDER ${PROJECT_NAME})
      target_link_libraries(${LibName} ${LINK_LIBRARIES})

      _target_include_directories(PUBLIC)

      if(NOT ${NAME}_OMIT_CHECK_TARGETS)
        common_check_targets(${LibName})
      endif()

      common_enable_dlopen_usage(${LibName})
    endif()

    common_compile_options(${LibName})
    add_dependencies(${PROJECT_NAME}-all ${LibName})

    # add an alias with PROJECT_NAME to the target to ease detection of
    # subproject inclusion in CommonConfig.cmake
    if(NOT TARGET ${PROJECT_NAME}_ALIAS)
      add_library(${PROJECT_NAME}_ALIAS ALIAS ${LibName})
    endif()

    if(NOT ${NAME}_OMIT_INSTALL)
      # add target to export set if not excluded, written by
      # CommonPackageConfig.cmake
      if(${NAME}_OMIT_EXPORT)
        install(TARGETS ${LibName}
          ARCHIVE DESTINATION lib COMPONENT dev
          RUNTIME DESTINATION bin COMPONENT lib
          LIBRARY DESTINATION lib COMPONENT lib
          INCLUDES DESTINATION include)
      else()
        install(TARGETS ${LibName}
          EXPORT ${PROJECT_NAME}Targets
          ARCHIVE DESTINATION lib COMPONENT dev
          RUNTIME DESTINATION bin COMPONENT lib
          LIBRARY DESTINATION lib COMPONENT lib
          INCLUDES DESTINATION include)
      endif()
    endif()
  endforeach()

  if(NOT ${NAME}_OMIT_INSTALL)
    if(MSVC AND "${${NAME}_LIBRARY_TYPE}" MATCHES "SHARED")
      install(FILES ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/Debug/${Name}${CMAKE_DEBUG_POSTFIX}.pdb
        DESTINATION bin COMPONENT lib CONFIGURATIONS Debug)
      install(FILES ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/RelWithDebInfo/${Name}.pdb
        DESTINATION bin COMPONENT lib CONFIGURATIONS RelWithDebInfo)
    endif()

    # install(TARGETS ... PUBLIC_HEADER ...) flattens directories
    install_files(include/${INCLUDE_NAME} FILES ${PUBLIC_HEADERS}
      COMPONENT dev BASE ${PROJECT_BINARY_DIR}/include/${INCLUDE_NAME})

    # for CommonCoverage.cmake
    set_property(GLOBAL APPEND PROPERTY ${PROJECT_NAME}_COVERAGE_INPUT_DIRS ${CMAKE_CURRENT_BINARY_DIR})
  endif()
endfunction()

macro(generate_version_headers)
  set(PROJECT_VERSION_ABI ${${PROJECT_NAME}_VERSION_ABI})
  configure_file(${CMAKE_SOURCE_DIR}/CMake/common/cpp/api.h
    ${PROJECT_BINARY_DIR}/include/${INCLUDE_NAME}/api.h @ONLY)
  configure_file(${CMAKE_SOURCE_DIR}/CMake/common/cpp/version.h
    ${PROJECT_BINARY_DIR}/include/${INCLUDE_NAME}/version.h @ONLY)
  configure_file(${CMAKE_SOURCE_DIR}/CMake/common/cpp/version.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/version.cpp @ONLY)

  # Exclude this file for coverage report in CommonCoverage.cmake
  set_property(GLOBAL APPEND PROPERTY
               COMMON_GENERATED_FILES ${CMAKE_CURRENT_BINARY_DIR}/version.cpp)

  # ${NAMESPACE}_API= -> Fix cppcheck error about not including version.h
  list(APPEND CPPCHECK_EXTRA_ARGS
    -D${NAME}_STATIC= -D${NAMESPACE}_API=)

  list(APPEND PUBLIC_HEADERS
    ${PROJECT_BINARY_DIR}/include/${INCLUDE_NAME}/api.h
    ${PROJECT_BINARY_DIR}/include/${INCLUDE_NAME}/version.h)
  list(APPEND SOURCES ${CMAKE_CURRENT_BINARY_DIR}/version.cpp)
endmacro()

macro(generate_library_header NAME)
  get_filename_component(__base_name ${INCLUDE_NAME} NAME)

  set(__generated_header ${PROJECT_BINARY_DIR}/include/${INCLUDE_NAME}/${__base_name}.h)
  set(__generated_header_in ${__generated_header}.in)

  file(WRITE ${__generated_header_in}
    "// generated by CommonLibrary.cmake, do not edit\n"
    "#ifndef ${NAME}_H\n"
    "#define ${NAME}_H\n")
    foreach(PUBLIC_HEADER ${PUBLIC_HEADERS})
      if(IS_ABSOLUTE ${PUBLIC_HEADER})
        set(__base "${PROJECT_BINARY_DIR}/include/${INCLUDE_NAME}/")
        string(REGEX MATCH ${__base} __has_base ${PUBLIC_HEADER})
        if(__has_base)
          string(REPLACE ${__base} "" PUBLIC_HEADER ${PUBLIC_HEADER})
        else()
          get_filename_component(PUBLIC_HEADER ${PUBLIC_HEADER} NAME)
        endif()
      endif()
      if(NOT PUBLIC_HEADER MATCHES "defines.+\\.h" AND
        (PUBLIC_HEADER MATCHES ".*\\.h$" OR PUBLIC_HEADER MATCHES ".*\\.hpp$"))
        file(APPEND ${__generated_header_in}
          "#include <${INCLUDE_NAME}/${PUBLIC_HEADER}>\n")
      endif()
    endforeach()
  file(APPEND ${__generated_header_in} "#endif\n")

  # configure only touches file if changed, saves compilation after reconfigure
  configure_file( ${__generated_header_in} ${__generated_header} COPYONLY)
  list(APPEND PUBLIC_HEADERS ${__generated_header})
endmacro()

macro(common_set_lib_name_postfix)
  if(WIN32)
    set(CMAKE_DEBUG_POSTFIX "_D")
  elseif(COMMON_LIBRARY_DEBUG_POSTFIX)
    set(CMAKE_DEBUG_POSTFIX "_debug")
  else()
    set(CMAKE_DEBUG_POSTFIX "")
  endif()
endmacro()

# add defines TARGET_DSO_NAME and TARGET_SHARED for dlopen() usage
function(common_enable_dlopen_usage Target)
  get_target_property(_compile_definitions ${Target} COMPILE_DEFINITIONS)
  if(NOT _compile_definitions)
    set(_compile_definitions) # clear _compile_definitions-NOTFOUND
  endif()
  string(TOUPPER ${Target} TARGET)
  list(APPEND _compile_definitions
    ${TARGET}_SHARED ${TARGET}_DSO_NAME=\"$<TARGET_FILE_NAME:${Target}>\")
  set_target_properties(${Target} PROPERTIES
    COMPILE_DEFINITIONS "${_compile_definitions}")
endfunction()

# declare include directories for this target when using it in the build
# tree; the install tree include directory is declared via install()
# @param type: must be PUBLIC or INTERFACE
macro(_target_include_directories _type)
  target_include_directories(
      ${LibName} ${_type}
      "$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>"
      "$<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>"
      "$<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>"
  )
  if(${NAME}_PUBLIC_INCLUDE_DIRECTORIES)
    target_include_directories(
      ${LibName} SYSTEM ${_type}
      "$<BUILD_INTERFACE:${${NAME}_PUBLIC_INCLUDE_DIRECTORIES}>"
      "$<INSTALL_INTERFACE:${${NAME}_PUBLIC_INCLUDE_DIRECTORIES}>"
    )
  endif()
endmacro()
