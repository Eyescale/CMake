# Common settings
#
# Input Variables
#
# IO Variables (set if not set as input)
# * COMMON_PROJECT_DOMAIN a reverse DNS name
#
# Output Variables
# * COMMON_INCLUDES: generated include files (version, defines, api)
# * COMMON_SOURCES: generated cpp files (version)

cmake_minimum_required(VERSION 2.8 FATAL_ERROR)
if(CMAKE_VERSION VERSION_LESS 2.8.3)
  # WAR bug
  get_filename_component(CMAKE_CURRENT_LIST_DIR ${CMAKE_CURRENT_LIST_FILE} PATH)
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/2.8.3)
endif()
if(CMAKE_VERSION VERSION_LESS 2.8.8)
  list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/2.8.8)
endif()

if(EXISTS ${CMAKE_SOURCE_DIR}/CMake/${CMAKE_PROJECT_NAME}.cmake)
  include(${CMAKE_SOURCE_DIR}/CMake/${CMAKE_PROJECT_NAME}.cmake)
endif()
include(${CMAKE_CURRENT_LIST_DIR}/System.cmake)
include(GitInfo)

enable_testing()
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

if(GIT_BRANCH)
  if(GIT_BRANCH MATCHES "^[0-9].*")
    set(RELEASE_VERSION ON)
  else()
    set(RELEASE_VERSION OFF)
  endif()
else()
  set(RELEASE_VERSION ON) # standalone tarball or similar
endif()

if(NOT CMAKE_BUILD_TYPE)
  if(RELEASE_VERSION)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  else()
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Build type" FORCE)
  endif()
endif(NOT CMAKE_BUILD_TYPE)
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} -DNDEBUG")

set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH})
string(TOUPPER ${CMAKE_PROJECT_NAME} UPPER_PROJECT_NAME)
string(TOLOWER ${CMAKE_PROJECT_NAME} LOWER_PROJECT_NAME)
add_definitions(-D${UPPER_PROJECT_NAME}_VERSION=${VERSION})
if(NOT VERSION_ABI)
  if(VERSION_MAJOR VERSION_GREATER 0)
    set(VERSION_ABI "${VERSION_MAJOR}${VERSION_MINOR}0")
  else()
    set(VERSION_ABI ${VERSION_MINOR}${VERSION_PATCH})
  endif()
endif()
if(NOT LAST_RELEASE)
  set(LAST_RELEASE ${VERSION})
endif()

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT AND NOT MSVC)
  set(CMAKE_INSTALL_PREFIX "/usr" CACHE PATH
    "${CMAKE_PROJECT_NAME} install prefix" FORCE)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

if(NOT DOC_DIR)
  set(DOC_DIR share/${CMAKE_PROJECT_NAME}/doc)
endif()
if(NOT COMMON_PROJECT_DOMAIN)
  set(COMMON_PROJECT_DOMAIN org.doxygen)
  message(STATUS "Set COMMON_PROJECT_DOMAIN to ${COMMON_PROJECT_DOMAIN}")
endif()

if(NOT DPUT_HOST)
  if(RELEASE_VERSION)
    set(DPUT_HOST "ppa:eilemann/equalizer")
  else()
    set(DPUT_HOST "ppa:eilemann/equalizer-dev")
  endif()
endif()

include(${CMAKE_CURRENT_LIST_DIR}/CMakeInstallPath.cmake)

# Boost settings
set(Boost_NO_BOOST_CMAKE ON CACHE BOOL "Enable fix for FindBoost.cmake" )
add_definitions(-DBOOST_ALL_NO_LIB) # Don't use 'pragma lib' on Windows
add_definitions(-DBoost_NO_BOOST_CMAKE) # Fix for CMake problem in FindBoost
if(NOT Boost_USE_STATIC_LIBS)
  add_definitions(-DBOOST_TEST_DYN_LINK) # generates main() for unit tests
endif()

include(TestBigEndian)
test_big_endian(BIGENDIAN)
if(BIGENDIAN)
  add_definitions(-D${UPPER_PROJECT_NAME}_BIGENDIAN)
else()
  add_definitions(-D${UPPER_PROJECT_NAME}_LITTLEENDIAN)
endif()

if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  set(LINUX TRUE)
  if(REDHAT AND CMAKE_SYSTEM_PROCESSOR MATCHES "64$")
    set(LIB_SUFFIX 64 CACHE STRING "Library directory suffix")
  endif()
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "ppc")
    set(LINUX_PPC 1)
  else()
    add_definitions(-fPIC)
  endif()
endif()
set(LIBRARY_DIR lib${LIB_SUFFIX})

if(APPLE)
  list(APPEND CMAKE_PREFIX_PATH /opt/local/ /opt/local/lib) # Macports
  set(ENV{PATH} "/opt/local/bin:$ENV{PATH}") # dito
  if(NOT CMAKE_OSX_ARCHITECTURES OR CMAKE_OSX_ARCHITECTURES STREQUAL "")
    if(_CMAKE_OSX_MACHINE MATCHES "ppc")
      set(CMAKE_OSX_ARCHITECTURES "ppc;ppc64" CACHE
        STRING "Build architectures for OS X" FORCE)
    else()
      set(CMAKE_OSX_ARCHITECTURES "i386;x86_64" CACHE
        STRING "Build architectures for OS X" FORCE)
    endif()
  endif()
  set(CMAKE_INCLUDE_SYSTEM_FLAG_C "-isystem ")
  set(CMAKE_INCLUDE_SYSTEM_FLAG_CXX "-isystem ")
  if (NOT CMAKE_INSTALL_NAME_DIR)
    set(CMAKE_INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib")
  endif (NOT CMAKE_INSTALL_NAME_DIR)
  message(STATUS
    "Building ${CMAKE_PROJECT_NAME} ${VERSION} for ${CMAKE_OSX_ARCHITECTURES}")
endif(APPLE)

if($ENV{TRAVIS})
  set(TRAVIS ON)
endif()

include(CommonApplication)
include(CommonCode)
include(CommonLibrary)
include(Compiler)
include(Coverage)
include(GitTargets)
include(Maturity)
include(ProjectInfo)
include(TargetHooks)
include(TestCPP11)
include(UpdateGitExternal)
