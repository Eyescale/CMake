# Copyright (c) 2012-2014 Fabien Delalondre <fabien.delalondre@epfl.ch>
#                         Stefan.Eilemann@epfl.ch
#
# Sets compiler optimization, definition and warnings according to
# chosen compiler. Supported compilers are XL, Intel, Clang, gcc (4.4
# or later) and Visual Studio (2008 or later).
#
# This defines the common_compiler_flags() macro to set
# CMAKE_C[XX]_FLAGS[_CMAKE_BUILD_TYPE] flags accordingly.
#
# Input Variables
# * COMMON_MINIMUM_GCC_VERSION check for a minimum gcc version, default 4.4
# * COMMON_USE_CXX03 When set, do not enable C++11 language features
#
# Output Variables
# * GCC_COMPILER_VERSION The compiler version if gcc is used
# * COMMON_C_FLAGS The common flags for C compiler
# * COMMON_C_FLAGS_DEBUG The common flags for C compiler in Debug build
# * COMMON_C_FLAGS_RELWITHDEBINFO The common flags for C compiler in RelWithDebInfo build
# * COMMON_C_FLAGS_RELEASE The common flags for C compiler in Release build
# * COMMON_CXX_FLAGS The common flags for C++ compiler
# * COMMON_CXX_FLAGS_DEBUG The common flags for C++ compiler in Debug build
# * COMMON_CXX_FLAGS_RELWITHDEBINFO The common flags for C++ compiler in RelWithDebInfo build
# * COMMON_CXX_FLAGS_RELEASE The common flags for C++ compiler in Release build
# * C_DIALECT_OPT_C89    Compiler flag to select C89 C dialect
# * C_DIALECT_OPT_C89EXT Compiler flag to select C89 C dialect with extensions
# * C_DIALECT_OPT_C99    Compiler flag to select C99 C dialect
# * C_DIALECT_OPT_C99EXT Compiler flag to select C99 C dialect with extensions

# OPT: necessary only once, included by Common.cmake
if(COMPILER_DONE)
  return()
endif()
set(COMPILER_DONE ON)

include(TestBigEndian)
test_big_endian(BIGENDIAN)

if(BIGENDIAN)
  add_definitions(-DCOMMON_BIGENDIAN)
else()
  add_definitions(-DCOMMON_LITTLEENDIAN)
endif()

# Compiler name
if(CMAKE_CXX_COMPILER_ID STREQUAL "XL")
  set(CMAKE_COMPILER_IS_XLCXX ON)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Intel")
  set(CMAKE_COMPILER_IS_INTEL ON)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(CMAKE_COMPILER_IS_CLANG ON)
elseif(CMAKE_COMPILER_IS_GNUCXX)
  set(CMAKE_COMPILER_IS_GNUCXX_PURE ON)
endif()
# use MSVC for Visual Studio

if(NOT COMMON_MINIMUM_GCC_VERSION)
  set(COMMON_MINIMUM_GCC_VERSION 4.4)
endif()

option(ENABLE_WARN_DEPRECATED "Enable deprecation warnings" ON)
option(ENABLE_CXX11_STDLIB "Enable C++11 stdlib" OFF)

if(ENABLE_WARN_DEPRECATED)
  add_definitions(-DWARN_DEPRECATED) # projects have to pick this one up
endif()

set(COMMON_C_FLAGS
  "-Wall -Wextra -Winvalid-pch -Winit-self -Wno-unknown-pragmas")

# GCC (+clang)
if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANG)
  include(${CMAKE_CURRENT_LIST_DIR}/CompilerVersion.cmake)
  compiler_dumpversion(GCC_COMPILER_VERSION)
  if(NOT WIN32 AND NOT XCODE_VERSION)
    set(COMMON_C_FLAGS "${COMMON_C_FLAGS} -Werror")
  endif()
  if(GCC_COMPILER_VERSION VERSION_GREATER 4.1)
    set(COMMON_C_FLAGS "${COMMON_C_FLAGS} -Wshadow")
  endif()
  if(CMAKE_COMPILER_IS_CLANG)
    set(COMMON_C_FLAGS
      "${COMMON_C_FLAGS} -Qunused-arguments -ferror-limit=5 -ftemplate-depth-1024 -Wheader-hygiene")
    set(COMMON_CXX11_STDLIB "-stdlib=libc++")
  else()
    if(GCC_COMPILER_VERSION VERSION_LESS COMMON_MINIMUM_GCC_VERSION)
      message(FATAL_ERROR "Using gcc ${GCC_COMPILER_VERSION}, need at least ${COMMON_MINIMUM_GCC_VERSION}")
    endif()
    if(GCC_COMPILER_VERSION VERSION_GREATER 4.5)
      set(COMMON_C_FLAGS "${COMMON_C_FLAGS} -fmax-errors=5")
    endif()
  endif()

  set(COMMON_CXX_FLAGS "-Wnon-virtual-dtor -Wsign-promo -Wvla -fno-strict-aliasing")
  set(COMMON_CXX_FLAGS_RELEASE "${COMMON_CXX_FLAGS_RELEASE} -Wuninitialized")

  if(APPLE AND OSX_VERSION VERSION_LESS 10.9)
    # use C++03 std and stdlib, which is the default used by all
    # software, including all MacPorts.
  elseif(NOT COMMON_USE_CXX03)
    if(CMAKE_COMPILER_IS_CLANG)
      set(COMMON_CXXSTD_FLAGS "-std=c++11")
    elseif(NOT GCC_COMPILER_VERSION VERSION_LESS 4.3)
      if(GCC_COMPILER_VERSION VERSION_LESS 4.7)
        set(COMMON_CXXSTD_FLAGS "-std=c++0x")
      else()
        if(GCC_COMPILER_VERSION VERSION_LESS 4.8)
          add_definitions(-D_GLIBCXX_USE_NANOSLEEP) # http://stackoverflow.com/questions/4438084
        endif()
        set(COMMON_CXXSTD_FLAGS "-std=c++11")
      endif()
    endif()
  endif()

  set(C_DIALECT_OPT_C89    "-std=c89")
  set(C_DIALECT_OPT_C89EXT "-std=gnu89")
  set(C_DIALECT_OPT_C99    "-std=c99")
  set(C_DIALECT_OPT_C99EXT "-std=gnu99")

# icc
elseif(CMAKE_COMPILER_IS_INTEL)
  set(COMMON_CXX_FLAGS
    "-Wno-deprecated -Wno-unknown-pragmas -Wshadow -fno-strict-aliasing -Wuninitialized -Wsign-promo -Wnon-virtual-dtor")

  # Release: automatically generate instructions for the highest
  # supported compilation host
  set(COMMON_C_FLAGS_RELEASE "${COMMON_C_FLAGS_RELEASE} -xhost")
  set(COMMON_CXX_FLAGS_RELEASE "${COMMON_CXX_FLAGS_RELEASE} -xhost")
  if(NOT COMMON_USE_CXX03)
    set(COMMON_CXXSTD_FLAGS "-std=c++11")
  endif()

  set(C_DIALECT_OPT_C89    "-std=c89")
  set(C_DIALECT_OPT_C89EXT "-std=gnu89")
  set(C_DIALECT_OPT_C99    "-std=c99")
  set(C_DIALECT_OPT_C99EXT "-std=gnu99")

# xlc/BlueGene/PPC
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
      "-O3 -qtune=qp -qarch=qp -q64 -qstrict -qnohot -qnostaticlink -DNDEBUG")
    set(COMMON_C_FLAGS_RELEASE ${COMMON_CXX_FLAGS_RELEASE})
  else()
    set(COMMON_CXX_FLAGS_RELEASE
      "-O3 -q64 -qstrict -qnostaticlink -qnostaticlink=libgcc -DNDEBUG")
    set(COMMON_C_FLAGS_RELEASE ${COMMON_CXX_FLAGS_RELEASE})
  endif()

  set(CMAKE_C_FLAGS_RELEASE ${COMMON_C_FLAGS_RELEASE})
  set(CMAKE_CXX_FLAGS_RELEASE ${COMMON_CXX_FLAGS_RELEASE})

  set(C_DIALECT_OPT_C89    "-qlanglvl=stdc89")
  set(C_DIALECT_OPT_C89EXT "-qlanglvl=extc89")
  set(C_DIALECT_OPT_C99    "-qlanglvl=stdc99")
  set(C_DIALECT_OPT_C99EXT "-qlanglvl=extc99")
endif()

# Visual Studio
if(MSVC)
  add_definitions(
    /D_CRT_SECURE_NO_WARNINGS
    /D_SCL_SECURE_NO_WARNINGS
    /wd4068 # disable unknown pragma warnings
    /wd4244 # conversion from X to Y, possible loss of data
    /wd4800 # forcing value to bool 'true' or 'false' (performance warning)
    /wd4351 # new behavior: elements of array 'array' will be default initialized
    )

  # By default, do not warn when built on machines using only VS Express
  # http://cmake.org/gitweb?p=cmake.git;a=commit;h=fa4a3b04d0904a2e93242c0c3dd02a357d337f77
  if(NOT DEFINED CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS)
    set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_NO_WARNINGS ON)
  endif()

  set(COMMON_C_FLAGS) # reset, GCC flags not applicable
  # http://www.ogre3d.org/forums/viewtopic.php?f=2&t=60015&start=0
  set(COMMON_CXX_FLAGS "/DWIN32 /D_WINDOWS /W3 /Zm500 /EHsc /GR")
  set(COMMON_CXX_FLAGS_DEBUG "${COMMON_CXX_FLAGS_RELEASE} /WX")
endif()

set(COMMON_C_FLAGS_RELWITHDEBINFO "${COMMON_C_FLAGS_RELWITHDEBINFO} -DNDEBUG")
set(COMMON_CXX_FLAGS_RELWITHDEBINFO "${COMMON_CXX_FLAGS_RELWITHDEBINFO} -DNDEBUG")

set(COMMON_CXX_FLAGS "${COMMON_C_FLAGS} ${COMMON_CXX_FLAGS}")

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_CXXSTD_FLAGS}")
if(ENABLE_CXX11_STDLIB)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_CXX11_STDLIB}")
endif()

macro(common_compiler_flags)
  set(CMAKE_C_FLAGS "${COMMON_C_FLAGS} ${CMAKE_C_FLAGS}")
  set(CMAKE_C_FLAGS_DEBUG "${COMMON_C_FLAGS_DEBUG} ${CMAKE_C_FLAGS_DEBUG}")
  set(CMAKE_C_FLAGS_RELWITHDEBINFO "${COMMON_C_FLAGS_RELWITHDEBINFO} ${CMAKE_C_FLAGS_RELWITHDEBINFO}")
  set(CMAKE_C_FLAGS_RELEASE "${COMMON_C_FLAGS_RELEASE} ${CMAKE_C_FLAGS_RELEASE}")
  set(CMAKE_CXX_FLAGS "${COMMON_CXX_FLAGS} ${CMAKE_CXX_FLAGS}")
  set(CMAKE_CXX_FLAGS_DEBUG "${COMMON_CXX_FLAGS_DEBUG} ${CMAKE_CXX_FLAGS_DEBUG}")
  set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${COMMON_CXX_FLAGS_RELWITHDEBINFO} ${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
  set(CMAKE_CXX_FLAGS_RELEASE "${COMMON_CXX_FLAGS_RELEASE} ${CMAKE_CXX_FLAGS_RELEASE}")
endmacro()

