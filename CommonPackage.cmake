# Copyright (c) 2014-2015 Stefan.Eilemann@epfl.ch
#                         Daniel.Nachbaur@epfl.ch

# Provides common_package(Package_Name args) and common_package_post() which
# improves find_package.
#
# common_package()
#  - QUIET if COMMON_PACKAGE_USE_QUIET option is set
#  - -isystem if SYSTEM argument is passed; for convenience, Boost is always
#    SYSTEM
#  - first tries find_package with all the given arguments, and then falls back
#    to using pkg_config if available (no component support for pkg_config though)
#  - processes ${PROJECT_SOURCE_DIR}/CMake/FindPackagesPost.cmake to tweak result
#    of common_package_post()
#  - sets include_directories() and link_directories() accordingly
#
# common_package_post()
#  - generates defines.h and options.cmake for found packages.
#  - prints status message of found and not-found packages
#
# Input variables
#  - CMAKE_INSTALL_PREFIX - install prefix, comes from Common.cmake
#  - CMAKE_MODULE_INSTALL_PATH - module install prefix, comes from CMakeInstallPath.cmake
#  - UPPER_PROJECT_NAME - upper-case project name, comes from Common.cmake
#
# Output variables
#  - COMMON_PACKAGE_DEFINES - accumulated defines of found packages for
#    options.cmake and defines.h, written by common_package_post()
#  - ${PROJECT_NAME}_FIND_PACKAGES_FOUND - string of found packages
#  - ${PROJECT_NAME}_FIND_PACKAGES_NOTFOUND - string of not-found packages

if(NOT PKGCONFIG_FOUND AND NOT MSVC)
  find_package(PkgConfig QUIET)
endif()
set(ENV{PKG_CONFIG_PATH}
  "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")

option(COMMON_PACKAGE_USE_QUIET "Use QUIET for common_package command" ON)

include(System)
set(COMMON_PACKAGE_DEFINES ${SYSTEM})

macro(common_package Package_Name)
  string(TOUPPER ${Package_Name} PACKAGE_NAME)
  set(__args ${ARGN}) # ARGN is not a list. make one.

  # SYSTEM specified?
  if(__args)
    string(REGEX MATCH "SYSTEM?" __is_system_package ${__args})
    list(REMOVE_ITEM __args "SYSTEM")
  endif()

  # Boost is always SYSTEM
  if(${Package_Name} STREQUAL "Boost")
    set(__is_system_package ON)
  endif()

  # COMPONENTS specified?
  if(__args)
    string(REGEX MATCH "COMPONENTS?" __has_components ${__args})
    if(__has_components)
      set(__has_components ON)
    else()
      set(__has_components)
    endif()
  endif()

  # OPT: only forward to find_package if not found or component find (tbd
  # implement found_components check)
  if((NOT ${Package_Name}_FOUND AND NOT ${PACKAGE_NAME}_FOUND) OR __has_components)
    set(__package_version)
    if(__args)
      list(GET __args 0 __package_version)
      if(__package_version MATCHES "^[0-9.]+$") # is a version
        set(__package_version ">=${__package_version}")
      else()
        set(__package_version)
      endif()
    endif()

    if(COMMON_PACKAGE_USE_QUIET)
      set(__find_quiet "QUIET")
    else()
      list(FIND __args "QUIET" __quiet_pos)
      if(__quiet_pos EQUAL -1)
        set(__find_quiet)
      else()
        set(__find_quiet "QUIET")
      endif()
    endif()

    list(FIND __args "REQUIRED" __is_required)
    if(__is_required EQUAL -1) # Optional find
      find_package(${Package_Name} ${__find_quiet} ${__args}) # try standard cmake way
      if((NOT ${Package_Name}_FOUND) AND (NOT ${PACKAGE_NAME}_FOUND) AND PKG_CONFIG_EXECUTABLE)
        pkg_check_modules(${Package_Name} ${Package_Name}${__package_version}
          ${__find_quiet}) # try pkg_config way
      endif()
    else() # required find
      list(REMOVE_AT __args ${__is_required})
      find_package(${Package_Name} ${__find_quiet} ${__args}) # try standard cmake way
      if((NOT ${Package_Name}_FOUND) AND (NOT ${PACKAGE_NAME}_FOUND) AND PKG_CONFIG_EXECUTABLE)
        pkg_check_modules(${Package_Name} REQUIRED ${Package_Name}${__package_version}
          ${__find_quiet}) # try pkg_config way (and fail if needed)
      endif()
    endif()
  endif()

  if(EXISTS ${PROJECT_SOURCE_DIR}/CMake/FindPackagesPost.cmake)
    include(${PROJECT_SOURCE_DIR}/CMake/FindPackagesPost.cmake)
  endif()

  if(${PACKAGE_NAME}_FOUND)
    set(${Package_Name}_name ${PACKAGE_NAME})
    set(${Package_Name}_FOUND TRUE)
  elseif(${Package_Name}_FOUND)
    set(${Package_Name}_name ${Package_Name})
    set(${PACKAGE_NAME}_FOUND TRUE)
  else()
    set(${PROJECT_NAME}_FIND_PACKAGES_NOTFOUND
      "${${PROJECT_NAME}_FIND_PACKAGES_NOTFOUND} ${Package_Name}")
  endif()
  if(${Package_Name}_name)
    set(__use_package_define "${UPPER_PROJECT_NAME}_USE_${PACKAGE_NAME}")
    string(REGEX REPLACE "-" "_" __use_package_define ${__use_package_define})
    list(APPEND COMMON_PACKAGE_DEFINES ${__use_package_define})
    if(NOT COMMON_LIBRARY_TYPE MATCHES "SHARED")
      list(APPEND ${UPPER_PROJECT_NAME}_DEPENDENT_LIBRARIES ${Package_Name})
    endif()
    set(${PROJECT_NAME}_FIND_PACKAGES_FOUND
      "${${PROJECT_NAME}_FIND_PACKAGES_FOUND} ${Package_Name}")
    link_directories(${${${Package_Name}_name}_LIBRARY_DIRS})
    if(NOT "${${${Package_Name}_name}_INCLUDE_DIRS}" MATCHES "-NOTFOUND")
      if(__is_system_package)
        include_directories(BEFORE SYSTEM ${${${Package_Name}_name}_INCLUDE_DIRS})
      else()
        include_directories(${${${Package_Name}_name}_INCLUDE_DIRS})
      endif()
    endif()
    if(NOT "${${${Package_Name}_name}_INCLUDE_DIR}" MATCHES "-NOTFOUND")
      if(__is_system_package)
        include_directories(BEFORE SYSTEM ${${${Package_Name}_name}_INCLUDE_DIR})
      else()
        include_directories(${${${Package_Name}_name}_INCLUDE_DIR})
      endif()
    endif()
  endif()
endmacro()


macro(common_package_post)
  # Write defines.h and options.cmake
  if(NOT PROJECT_INCLUDE_NAME)
    message(FATAL_ERROR "PROJECT_INCLUDE_NAME not set, old or missing Common.cmake?")
  endif()
  if(NOT __options_cmake_file)
    set(__options_cmake_file ${CMAKE_CURRENT_BINARY_DIR}/options.cmake)
  endif()

  configure_file(${CMAKE_SOURCE_DIR}/CMake/common/cpp/defines.h
    ${OUTPUT_INCLUDE_DIR}/${PROJECT_INCLUDE_NAME}/defines.h @ONLY)
  set(__defines_file
    "${CMAKE_CURRENT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/defines${SYSTEM}.h")
  set(COMMON_DEFINES_FILE
    ${OUTPUT_INCLUDE_DIR}/${PROJECT_INCLUDE_NAME}/defines.h ${__defines_file})

  set(__defines_file_in ${__defines_file}.in)
  set(__options_cmake_file_in ${__options_cmake_file}.in)
  file(WRITE ${__defines_file_in}
    "// generated by CommonPackage.cmake, do not edit.\n\n"
    "#ifndef ${PROJECT_NAME}_DEFINES_${SYSTEM}_H\n"
    "#define ${PROJECT_NAME}_DEFINES_${SYSTEM}_H\n\n")
  file(WRITE ${__options_cmake_file_in} "# Optional modules enabled during build\n")
  foreach(DEF ${COMMON_PACKAGE_DEFINES})
    add_definitions(-D${DEF}=1)
    file(APPEND ${__defines_file_in}
      "#ifndef ${DEF}\n"
      "#  define ${DEF} 1\n"
      "#endif\n")
    if(NOT DEF STREQUAL SYSTEM)
      file(APPEND ${__options_cmake_file_in} "set(${DEF} ON)\n")
    endif()
  endforeach()
  file(APPEND ${__defines_file_in} "\n#endif\n")

  # configure only touches file if changed, saves compilation after reconfigure
  configure_file(${__defines_file_in} ${__defines_file} COPYONLY)
  configure_file(${__options_cmake_file_in} ${__options_cmake_file} COPYONLY)

  if(CMAKE_MODULE_INSTALL_PATH)
    install(FILES ${__options_cmake_file}
            DESTINATION ${CMAKE_MODULE_INSTALL_PATH} COMPONENT dev)
  else()
    message(FATAL_ERROR
      "CMAKE_MODULE_INSTALL_PATH not set, old or missing Common.cmake?")
  endif()

  include(${__options_cmake_file})

  if(Boost_FOUND) # another WAR for broken boost stuff...
    set(Boost_VERSION
      ${Boost_MAJOR_VERSION}.${Boost_MINOR_VERSION}.${Boost_SUBMINOR_VERSION})
  endif()
  if(CUDA_FOUND)
    string(REPLACE "-std=c++11" "" CUDA_HOST_FLAGS "${CUDA_HOST_FLAGS}")
    string(REPLACE "-std=c++0x" "" CUDA_HOST_FLAGS "${CUDA_HOST_FLAGS}")
  endif()
  if(OPENMP_FOUND)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    set(CMAKE_SHARED_LINKER_FLAGS
      "${CMAKE_SHARED_LINKER_FLAGS} ${OpenMP_CXX_FLAGS}")
  endif()
  if(MPI_FOUND)
    include_directories(SYSTEM ${MPI_C_INCLUDE_PATH} ${MPI_CXX_INCLUDE_PATH})
  endif()

  set(__configure_msg "Configured ${PROJECT_NAME} [${GIT_REVISION}]")
  if(${PROJECT_NAME}_FIND_PACKAGES_FOUND)
    set(__configure_msg
      "${__configure_msg} with${${PROJECT_NAME}_FIND_PACKAGES_FOUND}")
  endif()
  if(${PROJECT_NAME}_FIND_PACKAGES_NOTFOUND)
    set(__configure_msg
      "${__configure_msg} WITHOUT${${PROJECT_NAME}_FIND_PACKAGES_NOTFOUND}")
  endif()
  message(STATUS ${__configure_msg})
endmacro()
