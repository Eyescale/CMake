# Detects the compiler, and sets the following:
# CMAKE_COMPILER_IS_XLCXX for IBM XLC
# CMAKE_COMPILER_IS_INTEL for Intel C++ Compiler
# CMAKE_COMPILER_IS_CLANG for clang
# CMAKE_COMPILER_IS_GNUCXX_PURE for *real* gcc

# Also sets the following, so that the correct C dialect flags can be used
# * C_DIALECT_OPT_C89    Compiler flag to select C89 C dialect
# * C_DIALECT_OPT_C89EXT Compiler flag to select C89 C dialect with extensions
# * C_DIALECT_OPT_C99    Compiler flag to select C99 C dialect
# * C_DIALECT_OPT_C99EXT Compiler flag to select C99 C dialect with extensions
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

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANG)
  set(C_DIALECT_OPT_C89    "-std=c89")
  set(C_DIALECT_OPT_C89EXT "-std=gnu89")
  set(C_DIALECT_OPT_C99    "-std=c99")
  set(C_DIALECT_OPT_C99EXT "-std=gnu99")
elseif(CMAKE_COMPILER_IS_INTEL)
  set(C_DIALECT_OPT_C89    "-std=c89")
  set(C_DIALECT_OPT_C89EXT "-std=gnu89")
  set(C_DIALECT_OPT_C99    "-std=c99")
  set(C_DIALECT_OPT_C99EXT "-std=gnu99")
elseif(CMAKE_COMPILER_IS_XLCXX)
  set(C_DIALECT_OPT_C89    "-qlanglvl=stdc89")
  set(C_DIALECT_OPT_C89EXT "-qlanglvl=extc89")
  set(C_DIALECT_OPT_C99    "-qlanglvl=stdc99")
  set(C_DIALECT_OPT_C99EXT "-qlanglvl=extc99")
endif()
