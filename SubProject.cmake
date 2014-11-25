
# Simple macro to add subprojects from subdirs to form a super project
# ARGS:
#  name = the Project name as declared in project(xxx) of the sub-project
#  (path) = The source directory (defaults to ${name})
#
# Using a simple top level CMakeLists, several CMake subprojects
# (which may depend on each other) can be built. Each subproject can
# be added to the superproject with an add_subproject(*name*)
# directive.
#
# To use the SubProject feature, the sub projects should modify their
# CMake scripts. In the scripts CMAKE_BINARY_DIR should be changed to
# PROJECT_BINARY_DIR and CMAKE_SOURCE_DIR should be changed to
# PROJECT_SOURCE_DIR. A sample project can be found at
# https://github.com/bilgili/SubProjects.git

include(${CMAKE_CURRENT_LIST_DIR}/GitExternal.cmake)

function(add_subproject name)
  string(TOUPPER ${name} NAME)
  if(CMAKE_MODULE_PATH)
    # We're adding a sub project here: Remove parent's CMake
    # directories so they don't take precendence over the sub project
    # directories. Change is scoped to this function.
    list(REMOVE_ITEM CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake
      ${PROJECT_SOURCE_DIR}/CMake/common)
  endif()

  list(LENGTH ARGN argc)
  if(argc GREATER 0)
    list(GET ARGN 0 path)
  else()
    set(path ${name})
  endif ()

  if(NOT EXISTS "${CMAKE_SOURCE_DIR}/${path}/")
    message(FATAL_ERROR "Sub project ${path} not found in ${CMAKE_SOURCE_DIR}")
  endif()

  option(SUBPROJECT_${name} "Build ${name} " ON)
  if(SUBPROJECT_${name})
    # if the project needs to do anything special when configured as a
    # sub project then it can check the variable ${PROJECT}_IS_SUBPROJECT
    set(${name}_IS_SUBPROJECT ON)
    set(${NAME}_FOUND ON PARENT_SCOPE)

    # set ${PROJECT}_DIR to the location of the new build dir for the project
    if(NOT ${name}_DIR)
      set(${name}_DIR "${CMAKE_BINARY_DIR}/${name}" CACHE PATH
        "Location of ${name} project" FORCE)
    endif()

    # add the source sub directory to our build and set the binary dir
    # to the build tree
    message("========== ${path} ==========")
    add_subdirectory("${CMAKE_SOURCE_DIR}/${path}" "${CMAKE_BINARY_DIR}/${name}")
    message("========== ${PROJECT_NAME} ==========")
  endif()
endfunction()

macro(add_git_subproject name url tag)
  string(TOUPPER ${name} NAME)
  if(NOT ${NAME}_FOUND)
    if(NOT ${name}_DIR)
      find_package(${name})
    endif()
    if(NOT ${NAME}_FOUND)
      git_external(${CMAKE_SOURCE_DIR}/${name} ${url} ${tag})
      add_subproject(${name})
      find_package(${name} REQUIRED) # find subproject "package"
      include_directories(${${NAME}_INCLUDE_DIRS})
    endif()
  endif()
endmacro()
