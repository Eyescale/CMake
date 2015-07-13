# Copyright (c) 2014-2015 Stefan.Eilemann@epfl.ch
#                         Daniel.Nachbaur@epfl.ch

# Provides common_package(Name args) and common_package_post() which improves
# find_package.
#
# common_package()
#  - QUIET if COMMON_PACKAGE_QUIET option is set
#  - -isystem if SYSTEM argument is passed; for convenience, Boost is always SYSTEM
#  - first tries find_package with all the given arguments, and then falls back
#    to using pkg_config if available (no component support for pkg_config though)
#  - processes ${PROJECT_SOURCE_DIR}/CMake/FindPackagesPost.cmake to tweak result
#    of common_package_post()
#  - sets include_directories() and link_directories() accordingly
#
# common_package_post()
#  - generates defines${SYSTEM}.h and options.cmake for found packages
#  - prints status message of found and not-found packages

if(NOT PKGCONFIG_FOUND AND NOT MSVC)
  find_package(PkgConfig QUIET)
endif()
set(ENV{PKG_CONFIG_PATH}
  "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")

option(COMMON_PACKAGE_QUIET "Use QUIET for common_package command" ON)

include(System)
set(FIND_PACKAGES_DEFINES ${SYSTEM})

macro(common_package Name)
  string(TOUPPER ${Name} COMMON_PACKAGE_NAME)
  set(COMMON_PACKAGE_ARGS ${ARGN}) # ARGN is not a list. make one.

  # SYSTEM specified?
  if(COMMON_PACKAGE_ARGS)
    string(REGEX MATCH "SYSTEM?" COMMON_PACKAGE_SYSTEM ${COMMON_PACKAGE_ARGS})
    list(REMOVE_ITEM COMMON_PACKAGE_ARGS "SYSTEM")
  endif()

  # Boost is always SYSTEM
  if(${Name} STREQUAL "Boost")
    set(COMMON_PACKAGE_SYSTEM ON)
  endif()

  # COMPONENTS specified?
  if(COMMON_PACKAGE_ARGS)
    string(REGEX MATCH "COMPONENTS?" COMMON_PACKAGE_COMPONENTS ${COMMON_PACKAGE_ARGS})
    if(COMMON_PACKAGE_COMPONENTS)
      set(COMMON_PACKAGE_COMPONENTS ON)
    else()
      set(COMMON_PACKAGE_COMPONENTS)
    endif()
  endif()

  # OPT: only forward to find_package if not found or component find (tbd
  # implement found_components check)
  if((NOT ${Name}_FOUND AND NOT ${COMMON_PACKAGE_NAME}_FOUND) OR COMMON_PACKAGE_COMPONENTS)
    set(COMMON_PACKAGE_VERSION)
    if(COMMON_PACKAGE_ARGS)
      list(GET COMMON_PACKAGE_ARGS 0 COMMON_PACKAGE_VERSION)
      if(COMMON_PACKAGE_VERSION MATCHES "^[0-9.]+$") # is a version
        set(COMMON_PACKAGE_VERSION ">=${COMMON_PACKAGE_VERSION}")
      else()
        set(COMMON_PACKAGE_VERSION)
      endif()
    endif()

    if(COMMON_PACKAGE_QUIET)
      set(COMMON_PACKAGE_FIND_QUIET "QUIET")
    else()
      list(FIND COMMON_PACKAGE_ARGS "QUIET" COMMON_PACKAGE_QUIET_POS)
      if(COMMON_PACKAGE_QUIET_POS EQUAL -1)
        set(COMMON_PACKAGE_FIND_QUIET)
      else()
        set(COMMON_PACKAGE_FIND_QUIET "QUIET")
      endif()
    endif()

    list(FIND COMMON_PACKAGE_ARGS "REQUIRED" COMMON_PACKAGE_REQUIRED_POS)
    if(COMMON_PACKAGE_REQUIRED_POS EQUAL -1) # Optional find
      find_package(${Name} ${COMMON_PACKAGE_FIND_QUIET} ${COMMON_PACKAGE_ARGS}) # try standard cmake way
      if((NOT ${Name}_FOUND) AND (NOT ${COMMON_PACKAGE_NAME}_FOUND) AND PKG_CONFIG_EXECUTABLE)
        pkg_check_modules(${Name} ${Name}${COMMON_PACKAGE_VERSION}
          ${COMMON_PACKAGE_FIND_QUIET}) # try pkg_config way
      endif()
    else() # required find
      list(REMOVE_AT COMMON_PACKAGE_ARGS ${COMMON_PACKAGE_REQUIRED_POS})
      find_package(${Name} ${COMMON_PACKAGE_FIND_QUIET} ${COMMON_PACKAGE_ARGS}) # try standard cmake way
      if((NOT ${Name}_FOUND) AND (NOT ${COMMON_PACKAGE_NAME}_FOUND) AND PKG_CONFIG_EXECUTABLE)
        pkg_check_modules(${Name} REQUIRED ${Name}${COMMON_PACKAGE_VERSION}
          ${COMMON_PACKAGE_FIND_QUIET}) # try pkg_config way (and fail if needed)
      endif()
    endif()
  endif()

  if(EXISTS ${PROJECT_SOURCE_DIR}/CMake/FindPackagesPost.cmake)
    include(${PROJECT_SOURCE_DIR}/CMake/FindPackagesPost.cmake)
  endif()

  string(TOUPPER ${PROJECT_NAME} UPPER_PROJECT_NAME)
  set(DEFDEP "${UPPER_PROJECT_NAME}_USE_${COMMON_PACKAGE_NAME}")
  string(REGEX REPLACE "-" "_" DEFDEP ${DEFDEP})

  if(${COMMON_PACKAGE_NAME}_FOUND)
    set(${Name}_name ${COMMON_PACKAGE_NAME})
    set(${Name}_FOUND TRUE)
  elseif(${Name}_FOUND)
    set(${Name}_name ${Name})
    set(${COMMON_PACKAGE_NAME}_FOUND TRUE)
  else()
    set(${PROJECT_NAME}_FIND_PACKAGES_NOTFOUND "${${PROJECT_NAME}_FIND_PACKAGES_NOTFOUND} ${Name}")
  endif()
  if(${Name}_name)
    list(APPEND FIND_PACKAGES_DEFINES ${DEFDEP})
    if(NOT COMMON_LIBRARY_TYPE MATCHES "SHARED")
      list(APPEND ${UPPER_PROJECT_NAME}_DEPENDENT_LIBRARIES ${Name})
    endif()
    set(${PROJECT_NAME}_FIND_PACKAGES_FOUND "${${PROJECT_NAME}_FIND_PACKAGES_FOUND} ${Name}")
    link_directories(${${${Name}_name}_LIBRARY_DIRS})
    if(NOT "${${${Name}_name}_INCLUDE_DIRS}" MATCHES "-NOTFOUND")
      if(COMMON_PACKAGE_SYSTEM)
        include_directories(BEFORE SYSTEM ${${${Name}_name}_INCLUDE_DIRS})
      else()
        include_directories(${${${Name}_name}_INCLUDE_DIRS})
      endif()
    endif()
    if(NOT "${${${Name}_name}_INCLUDE_DIR}" MATCHES "-NOTFOUND")
      if(COMMON_PACKAGE_SYSTEM)
        include_directories(BEFORE SYSTEM ${${${Name}_name}_INCLUDE_DIR})
      else()
        include_directories(${${${Name}_name}_INCLUDE_DIR})
      endif()
    endif()
  endif()
endmacro()


macro(common_package_post)
  # Write defines.h and options.cmake
  if(NOT PROJECT_INCLUDE_NAME)
    message(FATAL_ERROR "PROJECT_INCLUDE_NAME not set, old or missing Common.cmake?")
  endif()
  if(NOT OPTIONS_CMAKE)
    set(OPTIONS_CMAKE ${CMAKE_CURRENT_BINARY_DIR}/options.cmake)
  endif()

  configure_file(${CMAKE_SOURCE_DIR}/CMake/common/cpp/defines.h
    ${OUTPUT_INCLUDE_DIR}/${PROJECT_INCLUDE_NAME}/defines.h @ONLY)
  set(DEFINES_FILE "${CMAKE_CURRENT_BINARY_DIR}/include/${PROJECT_INCLUDE_NAME}/defines${SYSTEM}.h")
  list(APPEND COMMON_INCLUDES
    ${OUTPUT_INCLUDE_DIR}/${PROJECT_INCLUDE_NAME}/defines.h ${DEFINES_FILE})
  set(DEFINES_FILE_IN ${DEFINES_FILE}.in)
  file(WRITE ${DEFINES_FILE_IN}
    "// generated by CommonPackage.cmake, do not edit.\n\n"
    "#ifndef ${PROJECT_NAME}_DEFINES_${SYSTEM}_H\n"
    "#define ${PROJECT_NAME}_DEFINES_${SYSTEM}_H\n\n")
  file(WRITE ${OPTIONS_CMAKE} "# Optional modules enabled during build\n")
  foreach(DEF ${FIND_PACKAGES_DEFINES})
    add_definitions(-D${DEF}=1)
    file(APPEND ${DEFINES_FILE_IN}
      "#ifndef ${DEF}\n"
      "#  define ${DEF} 1\n"
      "#endif\n")
    if(NOT DEF STREQUAL SYSTEM)
      file(APPEND ${OPTIONS_CMAKE} "set(${DEF} ON)\n")
    endif()
  endforeach()
  file(APPEND ${DEFINES_FILE_IN}
    "\n#endif\n")

  if(CMAKE_MODULE_INSTALL_PATH)
    install(FILES ${OPTIONS_CMAKE} DESTINATION ${CMAKE_MODULE_INSTALL_PATH}
      COMPONENT dev)
  else()
    message(FATAL_ERROR "CMAKE_MODULE_INSTALL_PATH not set, old or missing Common.cmake?")
  endif()
  configure_file(${DEFINES_FILE_IN} ${DEFINES_FILE} COPYONLY)

  if(Boost_FOUND) # another WAR for broken boost stuff...
    set(Boost_VERSION ${Boost_MAJOR_VERSION}.${Boost_MINOR_VERSION}.${Boost_SUBMINOR_VERSION})
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

  set(CONFIGURE_MSG "Configured ${PROJECT_NAME} [${GIT_REVISION}]")
  if(${PROJECT_NAME}_FIND_PACKAGES_FOUND)
    set(CONFIGURE_MSG "${CONFIGURE_MSG} with${${PROJECT_NAME}_FIND_PACKAGES_FOUND}")
  endif()
  if(${PROJECT_NAME}_FIND_PACKAGES_NOTFOUND)
    set(CONFIGURE_MSG "${CONFIGURE_MSG} WITHOUT${${PROJECT_NAME}_FIND_PACKAGES_NOTFOUND}")
  endif()
  message(STATUS ${CONFIGURE_MSG})
endmacro()
