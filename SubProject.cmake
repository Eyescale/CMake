
# When included, automatically reads, parses and updates a .gitsubprojects file.
# .gitsubprojects contains lines in the form:
#   "git_subproject(<project> <giturl> <gittag>)"
# All projects are cloned, updated and added using the the (separately usable)
# git_subproject(project giturl gittag) macro as a sub project to the parent
# project. The git_subproject macro uses the add_subproject(name) function to add
# the project as a sub directory.
#
# Using a simple top level CMakeLists, several CMake subprojects
# (which may depend on each other) can be built. To use the SubProject
# feature, the sub projects should modify their CMake scripts. In the
# scripts CMAKE_BINARY_DIR should be changed to PROJECT_BINARY_DIR and
# CMAKE_SOURCE_DIR should be changed to PROJECT_SOURCE_DIR. A sample
# project can be found at https://github.com/bilgili/SubProjects.git

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
    add_subdirectory("${CMAKE_SOURCE_DIR}/${path}"
      "${CMAKE_BINARY_DIR}/${name}")
    message("========== ${PROJECT_NAME} ==========")
  endif()
endfunction()

macro(git_subproject name url tag)
  if(NOT BUILDYARD)
    string(TOUPPER ${name} NAME)
    if(NOT ${NAME}_FOUND)
      if(NOT EXISTS ${CMAKE_SOURCE_DIR}/${name})
        find_package(${name})
      endif()
      if(NOT ${NAME}_FOUND)
        git_external(${CMAKE_SOURCE_DIR}/${name} ${url} ${tag})
        add_subproject(${name})
        find_package(${name} REQUIRED) # find subproject "package"
        include_directories(${${NAME}_INCLUDE_DIRS})
        list(APPEND __subprojects "${name} ${url} ${tag}")
      endif()
    endif()
  endif()
endmacro()

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.gitsubprojects")
  set(__subprojects) # appended on each git_subproject invocation
  include(.gitsubprojects)

  if(__subprojects)
    set(GIT_SUBPROJECTS_SCRIPT
      "${CMAKE_CURRENT_BINARY_DIR}/UpdateSubprojects.cmake")
    file(WRITE "${GIT_SUBPROJECTS_SCRIPT}"
      "file(WRITE .gitsubprojects \"# -*- mode: cmake -*-\n\")\n")
    foreach(__subproject ${__subprojects})
      string(REPLACE " " ";" __subproject_list ${__subproject})
      list(GET __subproject_list 0 __subproject_name)
      list(GET __subproject_list 1 __subproject_repo)
      set(__subproject_dir "${CMAKE_SOURCE_DIR}/${__subproject_name}")
      file(APPEND "${GIT_SUBPROJECTS_SCRIPT}"
        "execute_process(COMMAND ${GIT_EXECUTABLE} fetch --all -q\n"
        "  WORKING_DIRECTORY ${__subproject_dir})\n"
        "execute_process(COMMAND \n"
        "  ${GIT_EXECUTABLE} show-ref --hash=7 refs/remotes/origin/master\n"
        "  OUTPUT_VARIABLE newref OUTPUT_STRIP_TRAILING_WHITESPACE\n"
        "  WORKING_DIRECTORY ${__subproject_dir})\n"
        "if(newref)\n"
        "  file(APPEND .gitsubprojects\n"
        "    \"git_subproject(${__subproject_name} ${__subproject_repo} \${newref})\\n\")\n"
        "else()\n"
        "  file(APPEND .gitsubprojects \"git_subproject(${__subproject})\n\")\n"
        "endif()\n")
    endforeach()

    add_custom_target(update_git_subprojects_${PROJECT_NAME}
      COMMAND ${CMAKE_COMMAND} -P ${GIT_SUBPROJECTS_SCRIPT}
      COMMENT "Recreate ${PROJECT_NAME}/.gitsubprojects"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

    if(NOT TARGET update)
      add_custom_target(update)
    endif()
    add_dependencies(update update_git_subprojects_${PROJECT_NAME})
  endif()
endif()
