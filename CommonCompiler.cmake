# Copyright (c) 2012-2016 Fabien Delalondre <fabien.delalondre@epfl.ch>
#                         Stefan.Eilemann@epfl.ch
#
# Sets compiler optimization, definition and warnings according to
# chosen compiler. Supported compilers are XL, Intel, Clang, gcc (4.4
# or later) and Visual Studio (2008 or later).
#
# This defines the common_compile_options() function to apply compiler flags and
# features for the given target.
#
# CMake options:
# * COMMON_WARN_DEPRECATED: Enable compiler deprecation warnings, default ON
# * COMMON_ENABLE_CXX11_STDLIB: Enable C++11 stdlib, default OFF
# * COMMON_DISABLE_WERROR: Disable -Werror flags, default OFF
# * COMMON_ENABLE_CXX11_ABI: Enable C++11 ABI for gcc 5 or later, default ON,
#   can be set to OFF with env variable CMAKE_COMMON_USE_CXX03_ABI
#
# Input Variables
# * COMMON_MINIMUM_GCC_VERSION check for a minimum gcc version, default 4.8
#
# Output Variables
# * CMAKE_COMPILER_IS_XLCXX for IBM XLC
# * CMAKE_COMPILER_IS_INTEL for Intel C++ Compiler
# * CMAKE_COMPILER_IS_CLANG for clang
# * CMAKE_COMPILER_IS_GCC for gcc
# * GCC_COMPILER_VERSION The compiler version if gcc is used

# OPT: necessary only once, included by Common.cmake
if(COMPILER_DONE)
  return()
endif()
set(COMPILER_DONE ON)

# Compiler name
if(CMAKE_CXX_COMPILER_ID STREQUAL "XL")
  set(CMAKE_COMPILER_IS_XLCXX ON)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
  set(CMAKE_COMPILER_IS_INTEL ON)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR
       CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  set(CMAKE_COMPILER_IS_CLANG ON)
elseif(CMAKE_COMPILER_IS_GNUCXX)
  set(CMAKE_COMPILER_IS_GCC ON)
endif()
# use MSVC for Visual Studio

option(COMMON_WARN_DEPRECATED "Enable compiler deprecation warnings" ON)
option(COMMON_ENABLE_CXX11_STDLIB "Enable C++11 stdlib" OFF)
option(COMMON_DISABLE_WERROR "Disable -Werror flag" OFF)
if($ENV{CMAKE_COMMON_USE_CXX03_ABI}) # set by viz/env module
  option(COMMON_ENABLE_CXX11_ABI "Enable C++11 ABI for gcc 5 or later" OFF)
else()
  option(COMMON_ENABLE_CXX11_ABI "Enable C++11 ABI for gcc 5 or later" ON)
endif()

if(COMMON_WARN_DEPRECATED)
  add_definitions(-DWARN_DEPRECATED) # projects have to pick this one up
endif()

# https://cmake.org/cmake/help/v3.1/prop_gbl/CMAKE_CXX_KNOWN_FEATURES.html
set(COMMON_CXX11_FEATURES
  cxx_alias_templates cxx_nullptr cxx_override cxx_final)
if(NOT MSVC OR MSVC_VERSION VERSION_GREATER 1800)
  list(APPEND COMMON_CXX11_FEATURES cxx_noexcept)
endif()

function(compiler_dumpversion OUTPUT_VERSION)
  execute_process(COMMAND
    ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1} -dumpversion
    OUTPUT_VARIABLE DUMP_COMPILER_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  string(REGEX REPLACE "([0-9])\\.([0-9])(\\.[0-9])?" "\\1.\\2"
    DUMP_COMPILER_VERSION "${DUMP_COMPILER_VERSION}")

  set(${OUTPUT_VERSION} ${DUMP_COMPILER_VERSION} PARENT_SCOPE)
endfunction()

if(CMAKE_COMPILER_IS_GCC OR CMAKE_COMPILER_IS_CLANG)
  compiler_dumpversion(GCC_COMPILER_VERSION)
  if(NOT COMMON_MINIMUM_GCC_VERSION)
    set(COMMON_MINIMUM_GCC_VERSION 4.8)
  endif()
  if(CMAKE_COMPILER_IS_GCC)
    if(GCC_COMPILER_VERSION VERSION_LESS COMMON_MINIMUM_GCC_VERSION)
      message(FATAL_ERROR "Using gcc ${GCC_COMPILER_VERSION}, need at least ${COMMON_MINIMUM_GCC_VERSION}")
    endif()
    if(NOT COMMON_ENABLE_CXX11_ABI)
      # http://stackoverflow.com/questions/30668560
      add_definitions("-D_GLIBCXX_USE_CXX11_ABI=0")
    endif()
  endif()

  set(COMMON_C_FLAGS
    -Wall -Wextra -Winvalid-pch -Winit-self -Wno-unknown-pragmas -Wshadow)
  set(COMMON_CXX_FLAGS
    -Wnon-virtual-dtor -Wsign-promo -Wvla -fno-strict-aliasing)

  if(NOT WIN32 AND NOT XCODE_VERSION AND NOT COMMON_DISABLE_WERROR)
    list(APPEND COMMON_C_FLAGS -Werror)
  endif()

  if(CMAKE_COMPILER_IS_CLANG)
    list(APPEND COMMON_C_FLAGS
      -Qunused-arguments -ferror-limit=5 -ftemplate-depth-1024 -Wheader-hygiene)
    if(COMMON_ENABLE_CXX11_STDLIB)
      list(APPEND COMMON_CXX_FLAGS -stdlib=libc++)
    endif()
  else()
    if(GCC_COMPILER_VERSION VERSION_GREATER 4.5)
      list(APPEND COMMON_C_FLAGS -fmax-errors=5)
    endif()
  endif()

  list(APPEND COMMON_CXX_FLAGS_RELEASE -Wuninitialized)

elseif(CMAKE_COMPILER_IS_INTEL)
  set(COMMON_C_FLAGS -Wno-unknown-pragmas)
  set(COMMON_CXX_FLAGS -Wno-deprecated -Wno-unknown-pragmas -fno-strict-aliasing)

  # Release: automatically generate instructions for the highest
  # supported compilation host
  set(COMMON_C_FLAGS_RELEASE -xhost)
  set(COMMON_CXX_FLAGS_RELEASE -xhost)

  set(CMAKE_CXX11_COMPILE_FEATURES ${COMMON_CXX11_FEATURES})
  set(CMAKE_CXX_COMPILE_FEATURES ${CMAKE_CXX11_COMPILE_FEATURES})
  set(CMAKE_CXX11_STANDARD_COMPILE_OPTION "-std=c++11")
  set(CMAKE_CXX11_EXTENSION_COMPILE_OPTION "-std=c++11")
  list(APPEND COMMON_CXX_FLAGS -std=c++11)
  if(NOT COMMON_ENABLE_CXX11_ABI)
    # http://stackoverflow.com/questions/30668560
    add_definitions("-D_GLIBCXX_USE_CXX11_ABI=0")
  endif()

elseif(CMAKE_COMPILER_IS_XLCXX)
  # default: Maintain code semantics Fix to link dynamically. On the
  # next pass should add an if statement: 'if shared ...'.  Overriding
  # default release flags since the default were '-O -NDEBUG'. By
  # default, set flags for backend since this is the most common use
  # case
  option(XLC_BACKEND "Compile for BlueGene compute nodes using XLC compilers"
    ON)
  if(XLC_BACKEND)
    set(COMMON_CXX_FLAGS_RELEASE
      -O3 -qtune=qp -qarch=qp -q64 -qstrict -qnohot -qnostaticlink -DNDEBUG)
    set(COMMON_C_FLAGS_RELEASE ${COMMON_CXX_FLAGS_RELEASE})
    set(COMMON_LIBRARY_TYPE STATIC)
    set(COMPILE_LIBRARY_TYPE STATIC)
  else()
    set(COMMON_CXX_FLAGS_RELEASE
      -O3 -q64 -qstrict -qnostaticlink -qnostaticlink=libgcc -DNDEBUG)
    set(COMMON_C_FLAGS_RELEASE ${COMMON_CXX_FLAGS_RELEASE})
  endif()

elseif(MSVC)
  # By default, do not warn when built on machines using only VS Express
  # http://cmake.org/gitweb?p=cmake.git;a=commit;h=fa4a3b04d0904a2e93242c0c3dd02a357d337f77
  if(NOT DEFINED CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS)
    set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS ON)
  endif()

  # http://www.ogre3d.org/forums/viewtopic.php?f=2&t=60015&start=0
  set(COMMON_CXX_FLAGS /DWIN32 /D_WINDOWS /W3 /Zm500 /EHsc /GR
    /D_CRT_SECURE_NO_WARNINGS /D_SCL_SECURE_NO_WARNINGS
    /wd4068 # disable unknown pragma warnings
    /wd4244 # conversion from X to Y, possible loss of data
    /wd4800 # forcing value to bool 'true' or 'false' (performance warning)
    /wd4351 # new behavior: elements of array 'array' will be default initialized
  )
  set(COMMON_CXX_FLAGS_DEBUG /WX)
else()
  message(FATAL_ERROR "Unknown/unsupported compiler ${CMAKE_CXX_COMPILER_ID}")
endif()

set(COMMON_C_FLAGS_RELWITHDEBINFO -DNDEBUG)
set(COMMON_CXX_FLAGS_RELWITHDEBINFO -DNDEBUG)

list(APPEND COMMON_CXX_FLAGS ${COMMON_C_FLAGS})

function(common_compile_options Name)
  get_target_property(__type ${Name} TYPE)
  set(__visibility PUBLIC)
  if(__type STREQUAL INTERFACE_LIBRARY)
    set(__interface 1)
    set(__visibility INTERFACE)
  endif()
  if(NOT __interface)
    set_property(TARGET ${Name} PROPERTY C_STANDARD 11)
    set_property(TARGET ${Name} PROPERTY CXX_STANDARD 11)
  endif()
  target_compile_features(${Name} ${__visibility} ${COMMON_CXX11_FEATURES})
  if(APPLE)
    target_compile_definitions(${Name} ${__visibility} Darwin)
  endif()
  if(NOT __interface)
    if(CMAKE_VERSION VERSION_LESS 3.3 OR MSVC)
      target_compile_options(${Name} PRIVATE
        "$<$<CONFIG:Debug>:${COMMON_CXX_FLAGS_DEBUG}>"
        "$<$<CONFIG:RelWithDebInfo>:${COMMON_CXX_FLAGS_RELWITHDEBINFO}>"
        "$<$<CONFIG:Release>:${COMMON_CXX_FLAGS_RELEASE}>"
        "${COMMON_CXX_FLAGS}"
        "$<$<CONFIG:Debug>:${COMMON_C_FLAGS_DEBUG}>"
        "$<$<CONFIG:RelWithDebInfo>:${COMMON_C_FLAGS_RELWITHDEBINFO}>"
        "$<$<CONFIG:Release>:${COMMON_C_FLAGS_RELEASE}>"
        "${COMMON_C_FLAGS}"
      )
    else()
      target_compile_options(${Name} PRIVATE
        "$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:Debug>>:${COMMON_CXX_FLAGS_DEBUG}>"
        "$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RelWithDebInfo>>:${COMMON_CXX_FLAGS_RELWITHDEBINFO}>"
        "$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:Release>>:${COMMON_CXX_FLAGS_RELEASE}>"
        "$<$<COMPILE_LANGUAGE:CXX>:${COMMON_CXX_FLAGS}>"
        "$<$<AND:$<COMPILE_LANGUAGE:C>,$<CONFIG:Debug>>:${COMMON_C_FLAGS_DEBUG}>"
        "$<$<AND:$<COMPILE_LANGUAGE:C>,$<CONFIG:RelWithDebInfo>>:${COMMON_C_FLAGS_RELWITHDEBINFO}>"
        "$<$<AND:$<COMPILE_LANGUAGE:C>,$<CONFIG:Release>>:${COMMON_C_FLAGS_RELEASE}>"
        "$<$<COMPILE_LANGUAGE:C>:${COMMON_C_FLAGS}>"
      )
    endif()
    if(TARGET Qt5::Core)
      set_target_properties(${Name} PROPERTIES AUTOMOC TRUE AUTORCC TRUE)
    endif()
    if(TARGET Qt5::Widgets)
      set_target_properties(${Name} PROPERTIES AUTOUIC TRUE)
    endif()
    if(CMAKE_COMPILER_IS_GCC AND NOT APPLE)
      set_target_properties(${Name} PROPERTIES LINK_FLAGS "-Wl,--no-as-needed")
    endif()
  endif()
endfunction()
