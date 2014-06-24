# Copyright (c) 2011-2014 Stefan Eilemann <eile@eyescale.ch>

# Sets the following variables if git is found:
# GIT_REVISION: The current HEAD sha hash
# GIT_STATE: A description of the working tree, e.g., 1.8.0-48-g6d23f80-dirty
# GIT_ORIGIN_URL: The origin of the working tree
# GIT_ROOT_URL: The root remote of the working tree
# GIT_BRANCH: The name of the current branch

if(GIT_INFO_DONE)
  return()
endif()

cmake_minimum_required(VERSION 2.8)

set(GIT_INFO_DONE ON)
set(GIT_REVISION "0")
set(GIT_STATE)
set(GIT_ORIGIN_URL)
set(GIT_ROOT_URL)
set(GIT_BRANCH)

if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/.git)
  find_package(Git)
  if(GIT_FOUND)
    execute_process( COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      OUTPUT_VARIABLE GIT_REVISION OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process( COMMAND ${GIT_EXECUTABLE} describe --long --tags --dirty
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
      OUTPUT_VARIABLE GIT_STATE OUTPUT_STRIP_TRAILING_WHITESPACE ERROR_QUIET)
    execute_process( COMMAND ${GIT_EXECUTABLE} config --get remote.origin.url
      OUTPUT_VARIABLE GIT_ORIGIN_URL OUTPUT_STRIP_TRAILING_WHITESPACE
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    execute_process( COMMAND ${GIT_EXECUTABLE} config --get remote.root.url
      OUTPUT_VARIABLE GIT_ROOT_URL OUTPUT_STRIP_TRAILING_WHITESPACE
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    execute_process( COMMAND ${GIT_EXECUTABLE} branch --contains HEAD
      OUTPUT_VARIABLE GIT_BRANCH OUTPUT_STRIP_TRAILING_WHITESPACE
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})

    if(NOT GIT_REVISION)
      set(GIT_REVISION "0")
    endif()
    if(NOT GIT_ROOT_URL)
      set(GIT_ROOT_URL ${GIT_ORIGIN_URL})
    endif()
    if(NOT GIT_STATE)
       set(GIT_STATE "<no-tag>")
    endif()
    string(REPLACE "* " "" GIT_BRANCH ${GIT_BRANCH})

    message(STATUS
      "git revision ${GIT_REVISION} state ${GIT_STATE} branch ${GIT_BRANCH}")
  else()
    message(STATUS "No revision version support, git not found")
  endif()
endif()
