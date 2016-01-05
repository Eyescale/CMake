# Used to turn on certain sanitizers, if available:
# 
# clang:
#    -dumpcompiler: 4.2.1
#       address
#       thread
#       undefined
# gcc:
#    -dumpcompiler: 4.8.3
#       address
#       thread
#
# Note: This modifies CMAKE_CXX_FLAGS and CMAKE_EXE_LINKER_FLAGS
# Usage: add this when doing cmake configuration: -DSANITIZER=address

if(NOT SANITIZER)
  return()
endif()

include(Compiler)

#According to: http://clang.llvm.org/docs/AddressSanitizer.html#usage
# the following compiler flags allow us to keep -O1 on, if desired, but
# still get pretty call stacks
set(_SANITIZER_COMPILE_OPTIONS "-g -fno-omit-frame-pointer -fno-optimize-sibling-calls")

string(TOLOWER ${SANITIZER} SANITIZER)

if(CMAKE_COMPILER_IS_GNUCXX_PURE)
  if(GCC_COMPILER_VERSION VERSION_GREATER 4.7)
    set(_GCC_SANITIZERS address thread)
  endif()
  list(FIND _GCC_SANITIZERS ${SANITIZER} _SANITIZER_FOUND)

elseif(CMAKE_COMPILER_IS_CLANG)
  if(GCC_COMPILER_VERSION VERSION_GREATER 4.1)
    set(_CLANG_SANITIZERS address thread undefined)
  endif()
  list(FIND _CLANG_SANITIZERS ${SANITIZER} _SANITIZER_FOUND)

endif()

if(${_SANITIZER_FOUND} GREATER -1)
  set(_SANITIZER "-fsanitize=${SANITIZER}")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${_SANITIZER_COMPILE_OPTIONS} ${_SANITIZER}" )
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${_SANITIZER}")
else()
  message(WARNING "Sanitizer '${SANITIZER}' not set, check compiler support")
endif()
