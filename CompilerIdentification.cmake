# Detects the compiler, and sets the following:
# CMAKE_COMPILER_IS_XLCXX for IBM XLC
# CMAKE_COMPILER_IS_INTEL for Intel C++ Compiler
# CMAKE_COMPILER_IS_CLANG for clang
# CMAKE_COMPILER_IS_GNUCXX_PURE for *real* gcc
#
# Also sets the following, so that the correct C dialect flags can be used
# * C_DIALECT_OPT_C89    Compiler flag to select C89 C dialect
# * C_DIALECT_OPT_C89EXT Compiler flag to select C89 C dialect with extensions
# * C_DIALECT_OPT_C99    Compiler flag to select C99 C dialect
# * C_DIALECT_OPT_C99EXT Compiler flag to select C99 C dialect with extensions
#
# COMMON_USE_CXX03 Set if the compiler only supports C++03
#
# C++ dialect options are setup as follows:
# * CXX_DIALECT_PRE_11  Pre-C++11, note: this could be C++98 or C++03, largely
#                       because g++ aliases the two, and the other compilers
#                       don't allow one to distinguish
# * CXX_DIALECT_11      C++11 standard

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

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANG)
  include(${CMAKE_CURRENT_LIST_DIR}/CompilerVersion.cmake)
  compiler_dumpversion(GCC_COMPILER_VERSION)

  set(CXX_DIALECT_PRE_11 "-std=c++98")

  set(CXX_DIALECT_11 "-std=c++11")
  if(CMAKE_COMPILER_IS_GNUCXX_PURE AND GCC_COMPILER_VERSION VERSION_LESS 4.7)
    set(CXX_DIALECT_11 "-std=c++0x")
  endif()

  if(CMAKE_COMPILER_IS_GNUCXX_PURE AND GCC_COMPILER_VERSION VERSION_LESS 4.5)
    set(COMMON_USE_CXX03 ON)
  endif()

  set(C_DIALECT_OPT_C89 "-std=c89")
  set(C_DIALECT_OPT_C99 "-std=c99")
  set(C_DIALECT_OPT_C89EXT "-std=gnu89")
  set(C_DIALECT_OPT_C99EXT "-std=gnu99")

elseif(CMAKE_COMPILER_IS_INTEL)
  set(CXX_DIALECT_11 "-std=c++11")
  set(CXX_DIALECT_PRE_11 "-std=gnu++98")

  set(C_DIALECT_OPT_C89 "-std=c89")
  set(C_DIALECT_OPT_C99 "-std=c99")
  set(C_DIALECT_OPT_C89EXT "-std=gnu89")
  set(C_DIALECT_OPT_C99EXT "-std=gnu99")

elseif(CMAKE_COMPILER_IS_XLCXX)
  #read up on the features with 'xlc++ -qhelp'
  set(COMMON_USE_CXX03 ON)
  set(CXX_DIALECT_PRE_11 "-qlanglvl=extended") #strict98, with some ... extra features
  set(CXX_DIALECT_11 "-qlanglvl=extended0x")

  set(C_DIALECT_OPT_C89 "-qlanglvl=stdc89")
  set(C_DIALECT_OPT_C99 "-qlanglvl=stdc99")
  set(C_DIALECT_OPT_C89EXT "-qlanglvl=extc89")
  set(C_DIALECT_OPT_C99EXT "-qlanglvl=extc99")
endif()
