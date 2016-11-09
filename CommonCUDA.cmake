# Copyright (c) 2016 Juan.Hernando@epfl.ch
#               2016 Jafet.VillafrancaDiaz@epfl.ch
#
# Provides three functions for common configuration checks and setup for
# projects using CUDA.
# In particular:
# * find_cuda_compatible_host_compiler() tries to set CUDA_HOST_COMPILER to a
#   version compatible with the CUDA version detected.
# * common_cuda_compile_options() sets the default architecture to a minimum
#   value that does not cause deprecation warnings with newer version of nvcc.
# * find_cuda_device() tries to compile and run a simple CUDA application to
#   detect the number of CUDA-capable devices, and sets CUDA_DEVICE_FOUND if
#   at least one is present.

function(find_cuda_compatible_host_compiler)
  if(NOT CMAKE_COMPILER_IS_GNUCXX)
    # Only implemented for gcc
    return()
  endif()

  set(_host_config "${CUDA_INCLUDE_DIRS}/host_config.h")
  if(NOT EXISTS "${_host_config}")
    message(SEND_ERROR "host_config.h CUDA header not found")
    return()
  endif()

  # Finding the maximum version of gcc supported by the CUDA installation
  # detected

  file(STRINGS "${_host_config}" _host_config_content REGEX "#if __GNUC__")
  # Different versions of host_config.h differ in how they check if the
  # version of gcc is supported.
  string(REGEX REPLACE "#if __GNUC__ > ([0-9]) \\|\\| \\(__GNUC__ == ([0-9]) && __GNUC_MINOR__ > ([0-9]*)\\)"
    "\\2.\\3" _max_gcc_version_supported ${_host_config_content})
  string(REGEX REPLACE "#if __GNUC__ == ([0-9]) && __GNUC_MINOR__ > ([0-9]+)"
    "\\1.\\2" _max_gcc_version_supported ${_max_gcc_version_supported})
  string(REGEX REPLACE "#if __GNUC__ > ([0-9])"
    "\\1" _max_gcc_version_supported ${_max_gcc_version_supported})
  string(REPLACE "." "" _maxgccversionsupported ${_max_gcc_version_supported})

  if(# Rejecting ccache as the host compiler as this causes errors later on.
     CMAKE_C_COMPILER MATCHES ".*/ccache/.*" OR
     # Then comparing the highest version supported by the CUDA SDK with the
     # version of the default compiler.
     ${_max_gcc_version_supported} VERSION_LESS ${GCC_COMPILER_VERSION})

    if(${GCC_COMPILER_VERSION} VERSION_LESS ${_max_gcc_version_supported})
      set(_max_gcc_version_supported ${GCC_COMPILER_VERSION})
    endif()

    # Finding a suitable compiler
    find_program(_gcc_binary gcc-${_max_gcc_version_supported})
    if(NOT _gcc_binary)
      # RHEL package mantainers use this naming convention for symbolic links
      find_program(_gcc_binary gcc${_maxgccversionsupported})
    endif()

    macro(CHECK_GCC_VERSION)
      execute_process(COMMAND ${_gcc_binary} -dumpversion
        OUTPUT_VARIABLE _gcc_version OUTPUT_STRIP_TRAILING_WHITESPACE)
      # Reducing the version number to 1 or 2 digits depending on how
      # host_config.h checks the version.
      if (${_max_gcc_version_supported} MATCHES "[0-9]+\\.[0-9]+")
        string(REGEX REPLACE "([0-9])\\.([0-9])(\\.[0-9])?" "\\1.\\2"
          _gcc_version "${_gcc_version}")
      else()
        string(REGEX REPLACE "([0-9])\\.([0-9])(\\.[0-9])?" "\\1"
          _gcc_version "${_gcc_version}")
      endif()
      if(${_gcc_version} VERSION_GREATER ${_max_gcc_version_supported})
        unset(_gcc_binary CACHE)
      endif()
    endmacro()

    if(NOT _gcc_binary)
      # Try with the default compiler on the path.
      # This is needed for example when not using a system level binary.
      find_program(_gcc_binary gcc)
      check_gcc_version()

      if(NOT _gcc_binary)
        # Finally try with the default system compiler.
        find_program(_gcc_binary gcc PATHS /usr/bin NO_DEFAULT_PATH)
        check_gcc_version()
      endif()
    endif()

    if(NOT _gcc_binary)
      message(WARNING "A version of gcc compatible with CUDA ${CUDA_VERSION} was not found.")
    else()
      set(CUDA_HOST_COMPILER ${_gcc_binary} PARENT_SCOPE)
    endif()
    unset(_gcc_binary CACHE)
  endif()

endfunction()

# CUDA compile flags
function(common_cuda_compile_options)
  if(CUDA_VERSION VERSION_LESS 6.0)
    set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -arch=sm_11" PARENT_SCOPE)
  else()
    set(CUDA_NVCC_FLAGS "${CUDA_NVCC_FLAGS} -arch=sm_20" PARENT_SCOPE)
  endif()
endfunction()

# find CUDA capable device
function(find_cuda_device)
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/hasCudaDevice.cpp
    "#include <cuda_runtime.h>
     int main()
     {
         int deviceCount = 0;
         if( cudaGetDeviceCount( &deviceCount ) != cudaSuccess )
             deviceCount = 0;
         return deviceCount > 0 ? 0 : 1;
     }")

  try_run(RUN_RESULT_VAR COMPILE_RESULT_VAR
          ${CMAKE_CURRENT_BINARY_DIR}/hasCudaDevice
          SOURCES ${CMAKE_CURRENT_BINARY_DIR}/hasCudaDevice.cpp
          CMAKE_FLAGS -DINCLUDE_DIRECTORIES=${CUDA_INCLUDE_DIRS}
                      -DLINK_LIBRARIES=${CUDA_LIBRARIES}
          COMPILE_OUTPUT_VARIABLE COMPILE_OUTPUT_VAR
          RUN_OUTPUT_VARIABLE RUN_OUTPUT_VAR)
  if(COMPILE_RESULT_VAR AND NOT RUN_RESULT_VAR)
    set(CUDA_DEVICE_FOUND TRUE PARENT_SCOPE)
  endif()
endfunction()
