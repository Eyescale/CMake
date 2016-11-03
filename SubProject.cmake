
# Include this file in a top-level CMakeLists to build several CMake
# subprojects (which may depend on each other).
#
# When included, it will automatically parse a .gitsubprojects file if one is
# present in the same CMake source directory. The .gitsubprojects file
# contains lines in the form:
#   "git_subproject(<project> <giturl> <gittag>)"
#
# All the subprojects will be cloned and configured during the CMake configure
# step thanks to the 'git_subproject(project giturl gittag)' macro
# (also usable separately).
# The latter relies on the add_subproject(name) function to add projects as
# sub directories. See also: cmake command 'add_subdirectory'.
#
# The following targets are created by SubProject.cmake:
# - An '${PROJECT_NAME}-update-git-subprojects' target to update the <gittag> of
#   all the .gitsubprojects entries to their latest respective origin/master ref
# - A generic 'update' target to execute 'update-git-subrojects' recursively
#
# To be compatible with the SubProject feature, (sub)projects might need to
# adapt their CMake scripts in the following way:
# - CMAKE_BINARY_DIR should be changed to PROJECT_BINARY_DIR
# - CMAKE_SOURCE_DIR should be changed to PROJECT_SOURCE_DIR
#
# They must also be locatable by CMake's find_package(name), which can be
# achieved in any of the following ways:
# - include(CommonPackageConfig) at the end of the top-level CMakeLists.txt
# - include(CommonCPack), which indirectly includes CommonPackageConfig
# - Provide a compatible Find<Name>.cmake script (not recommended)
#
# If the project needs to do anything special when configured as a sub project
# then it can check the variable ${PROJECT_NAME}_IS_SUBPROJECT.
#
# SubProject.cmake respects the following variables:
# - DISABLE_SUBPROJECTS: when set, does not load sub projects. Useful for
#   example for continuous integration builds
# - SUBPROJECT_${name}: If set to OFF, the subproject is not added.
# - INSTALL_PACKAGES: command line cache variable which will "apt-get", "yum" or
#   "port install" the known system packages. This variable is unset after this
#   script is parsed by top level projects.
#   The packages to install are taken from ${PROJECT_NAME}_${type}_DEPENDS
#   where type is DEB, RPM or PORT depending on the system.
# - COMMON_SOURCE_DIR: When set, the source code of subprojects will be
#   downloaded in this path instead of CMAKE_SOURCE_DIR.
# A sample project can be found at https://github.com/Eyescale/Collage.git
#
# How to create a dependency graph:
#  cmake --graphviz=graph.dot
#  tred graph.dot > graph2.dot
#  neato -Goverlap=prism -Goutputorder=edgesfirst graph2.dot -Tpdf -o graph.pdf
#
# Output Variables:
# - SUBPROJECT_PATHS: list of paths to subprojects, useful for exclusion lists

include(${CMAKE_CURRENT_LIST_DIR}/GitExternal.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/CommonGraph.cmake)

if(TARGET git_subproject_${PROJECT_NAME}_done)
  return()
endif()
add_custom_target(git_subproject_${PROJECT_NAME}_done)
set_target_properties(git_subproject_${PROJECT_NAME}_done PROPERTIES
  EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/zzphony)

set(COMMON_SOURCE_DIR "${CMAKE_SOURCE_DIR}" CACHE PATH
  "Location of common directory of all sources")
set(__common_source_dir ${COMMON_SOURCE_DIR})
get_filename_component(__common_source_dir ${__common_source_dir} ABSOLUTE)
file(MAKE_DIRECTORY ${__common_source_dir})

function(subproject_install_packages name)
  if(NOT INSTALL_PACKAGES)
    return()
  endif()

  string(TOUPPER ${name} NAME)
  list(APPEND ${NAME}_DEB_DEPENDS pkg-config git cmake git-review doxygen ccache
    graphviz ${OPTIONAL_DEBS})
  set(${NAME}_BUILD_DEBS ${NAME}_DEB_DEPENDS)
  list(APPEND ${NAME}_DEB_DEPENDS ninja-build lcov cppcheck clang
    clang-format-3.5) # optional deb packages, not added to build spec
  list(APPEND ${NAME}_PORT_DEPENDS cppcheck)

  if(CMAKE_SYSTEM_NAME MATCHES "Linux" )
    # Detecting the package manager to use
    find_program(__pkg_mng apt-get)
    if(__pkg_mng)
      set(__pkg_type DEB)
    else()
      find_program(__pkg_mng yum)
      if(__pkg_mng)
        set(__pkg_type RPM)
      endif()
    endif()
  elseif(APPLE)
    find_program(__pkg_mng port)
  endif()

  if(NOT __pkg_mng)
    message(WARNING "Could not find the package manager tool for installing dependencies in this system")
    # Removing INSTALL_PACKAGES so the warning is not printed repeatedly.
    unset(INSTALL_PACKAGES CACHE)
    return()
  else()
    # We don't want __pkg_mng to appear in ccmake.
    set(__pkg_mng ${__pkg_mng} CACHE INTERNAL "")
  endif()

  if(CMAKE_SYSTEM_NAME MATCHES "Linux" AND ${NAME}_${__pkg_type}_DEPENDS)
    list(SORT ${NAME}_${__pkg_type}_DEPENDS)
    list(REMOVE_DUPLICATES ${NAME}_${__pkg_type}_DEPENDS)
    message(
      "Running 'sudo ${__pkg_mng} install ${${NAME}_${__pkg_type}_DEPENDS}'")
    execute_process(
      COMMAND sudo ${__pkg_mng} install ${${NAME}_${__pkg_type}_DEPENDS})
  endif()

  if(${NAME}_PORT_DEPENDS AND APPLE)
    list(SORT ${NAME}_PORT_DEPENDS)
    list(REMOVE_DUPLICATES ${NAME}_PORT_DEPENDS)
    set(${NAME}_PORT_DEPENDS_UNI)
    foreach(__port ${${NAME}_PORT_DEPENDS})
      list(APPEND ${NAME}_PORT_DEPENDS_UNI ${__port} +universal)
    endforeach()
    message(
      "Running 'sudo port install ${${NAME}_PORT_DEPENDS} (+universal)'")
    execute_process(COMMAND sudo port install -p ${${NAME}_PORT_DEPENDS_UNI})
  endif()
endfunction()

function(add_subproject name)
  string(TOUPPER ${name} NAME)
  if(CMAKE_MODULE_PATH)
    # We're adding a sub project here: Remove parent's CMake
    # directories so they don't take precendence over the sub project
    # directories. Change is scoped to this function.
    list(REMOVE_ITEM CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake)
  endif()

  list(LENGTH ARGN argc)
  if(argc GREATER 0)
    list(GET ARGN 0 path)
  else()
    set(path ${name})
  endif ()

  if(NOT EXISTS "${__common_source_dir}/${path}/")
    message(FATAL_ERROR
      "Subproject ${path} not found in ${__common_source_dir}")
  endif()
  # enter again to catch direct add_subproject() calls
  common_graph_dep(${PROJECT_NAME} ${name} TRUE TRUE)

  # allow exclusion of subproject via set(SUBPROJECT_${name} OFF)
  if(DEFINED SUBPROJECT_${name} AND NOT SUBPROJECT_${name})
    option(SUBPROJECT_${name} "Build ${name} " OFF)
  else()
    option(SUBPROJECT_${name} "Build ${name} " ON)
  endif()
  if(NOT SUBPROJECT_${name})
    return()
  endif()

  # Hint for the sub project, in case it needs to do anything special when
  # configured as a sub project
  set(${name}_IS_SUBPROJECT ON)

  # set ${PROJECT}_DIR to the location of the new build dir for the project
  if(NOT ${name}_DIR)
    set(${name}_DIR "${CMAKE_BINARY_DIR}/${name}" CACHE PATH
      "Location of ${name} project" FORCE)
  endif()

  subproject_install_packages(${name})

  # add the source sub directory to our build and set the binary dir
  # to the build tree

  add_subdirectory("${__common_source_dir}/${path}"
    "${CMAKE_BINARY_DIR}/${name}")
  set(${name}_IS_SUBPROJECT ON PARENT_SCOPE)

  # Mark globally that we've already used name as a sub project
  set_property(GLOBAL PROPERTY ${name}_IS_SUBPROJECT ON)
endfunction()

macro(git_subproject name url tag)
  if(__subprojects_collect)
    list(APPEND __subprojects "${name} ${url} ${tag}")
  else()
    # enter early to catch all dependencies
    common_graph_dep(${PROJECT_NAME} ${name} TRUE TRUE)
    if(NOT DISABLE_SUBPROJECTS)
      string(TOUPPER ${name} NAME)
      if(NOT ${NAME}_FOUND AND NOT ${name}_FOUND)
        get_property(__included GLOBAL PROPERTY ${name}_IS_SUBPROJECT)
        if(NOT __included)
          if(NOT EXISTS ${__common_source_dir}/${name})
            # Always try first using Config mode, then Module mode.
            find_package(${name} QUIET CONFIG)
            if(NOT ${NAME}_FOUND AND NOT ${name}_FOUND)
              find_package(${name} QUIET MODULE)
            endif()
          endif()
          if((NOT ${NAME}_FOUND AND NOT ${name}_FOUND) OR
              ${NAME}_FOUND_SUBPROJECT)
            # not found externally, add as sub project
            git_external(${__common_source_dir}/${name} ${url} ${tag})
            add_subproject(${name})
          endif()
        endif()
      endif()
      get_property(__included GLOBAL PROPERTY ${name}_IS_SUBPROJECT)
      if(__included)
        list(APPEND __subprojects "${name} ${url} ${tag}")
      endif()
    endif()
  endif()
endmacro()

# Interpret .gitsubprojects
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.gitsubprojects")
  subproject_install_packages(${PROJECT_NAME})

  # Gather all subprojects
  set(__subprojects_collect 1)
  set(__subprojects) # all appended on each git_subproject invocation
  include(.gitsubprojects)
  set(__subprojects_collect)

  # Clone all subprojects in parallel
  set(__all_subprojects "${__subprojects}")
  set(__clone_subprojects)
  foreach(__subproject ${__subprojects})
    string(REPLACE " " ";" __subproject_list ${__subproject})
    list(GET __subproject_list 0 __name)
    list(GET __subproject_list 1 __repo)
    list(GET __subproject_list 2 __tag)
    set(__dir "${__common_source_dir}/${__name}")

    if(NOT EXISTS "${__dir}")
      message(STATUS "git clone --recursive ${__repo} ${__name} [${__tag}]")
      file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${__name}Clone.cmake"
        "execute_process("
        "  COMMAND \"${GIT_EXECUTABLE}\" clone --recursive ${__repo} ${__dir}"
        "  RESULT_VARIABLE nok ERROR_VARIABLE error)\n"
        "if(nok)\n"
        "  message(FATAL_ERROR \"${__name} clone failed: \${error}\")\n"
        "endif()\n"
        "execute_process(COMMAND \"${GIT_EXECUTABLE}\" checkout -q ${__tag}"
        "  RESULT_VARIABLE nok ERROR_VARIABLE error"
        "  WORKING_DIRECTORY ${__dir})\n"
        "if(nok)\n"
        "  message(FATAL_ERROR \"git checkout ${__tag} in ${__dir} failed: \${error}\")\n"
        "endif()\n")
      list(APPEND __clone_subprojects COMMAND "${CMAKE_COMMAND}" -P
        "${CMAKE_CURRENT_BINARY_DIR}/${__name}Clone.cmake")
    endif()
  endforeach()
  if(__clone_subprojects)
    execute_process(${__clone_subprojects}
      RESULT_VARIABLE nok ERROR_VARIABLE error
      WORKING_DIRECTORY "${__common_source_dir}")
    if(nok)
      message(FATAL_ERROR "Cloning of projects failed: ${error}")
    endif()
  endif()

  set(__subprojects) # activate projects on each git_subproject invocation
  include(.gitsubprojects)
  if(__subprojects)
    get_property(__subproject_paths GLOBAL PROPERTY SUBPROJECT_PATHS)
    set(GIT_SUBPROJECTS_SCRIPT
      "${CMAKE_CURRENT_BINARY_DIR}/UpdateSubprojects.cmake")
    file(WRITE "${GIT_SUBPROJECTS_SCRIPT}"
      "file(WRITE .gitsubprojects \"# -*- mode: cmake -*-\n\")\n")
    foreach(__subproject ${__subprojects})
      string(REPLACE " " ";" __subproject_list ${__subproject})
      list(GET __subproject_list 0 __subproject_name)
      list(GET __subproject_list 1 __subproject_repo)
      list(APPEND SUBPROJECTS ${__subproject_name})
      set(__subproject_dir "${__common_source_dir}/${__subproject_name}")
      file(APPEND "${GIT_SUBPROJECTS_SCRIPT}"
        "execute_process(COMMAND \"${GIT_EXECUTABLE}\" fetch origin -q\n"
        "  WORKING_DIRECTORY ${__subproject_dir})\n"
        "execute_process(COMMAND \n"
        "  \"${GIT_EXECUTABLE}\" show-ref --hash=7 refs/remotes/origin/master\n"
        "  OUTPUT_VARIABLE newref OUTPUT_STRIP_TRAILING_WHITESPACE\n"
        "  WORKING_DIRECTORY \"${__subproject_dir}\")\n"
        "if(newref)\n"
        "  file(APPEND .gitsubprojects\n"
        "    \"git_subproject(${__subproject_name} ${__subproject_repo} \${newref})\\n\")\n"
        "else()\n"
        "  file(APPEND .gitsubprojects \"git_subproject(${__subproject})\n\")\n"
        "endif()\n")
        list(APPEND __subproject_paths ${__subproject_dir})
    endforeach()

    list(REMOVE_DUPLICATES __subproject_paths)
    set_property(GLOBAL PROPERTY SUBPROJECT_PATHS ${__subproject_paths})

    add_custom_target(${PROJECT_NAME}-update-git-subprojects
      COMMAND ${CMAKE_COMMAND} -P ${GIT_SUBPROJECTS_SCRIPT}
      COMMENT "Update ${PROJECT_NAME}/.gitsubprojects"
      WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
    set_target_properties(${PROJECT_NAME}-update-git-subprojects PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/zzphony)

    if(NOT TARGET update)
      add_custom_target(update)
      set_target_properties(update PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD ON)
    endif()
    add_dependencies(update ${PROJECT_NAME}-update-git-subprojects)
  endif()

  if(NOT ${PROJECT_NAME}_IS_SUBPROJECT)
    # If this variable was given in the command line, ensure that the package
    # installation is only run in this cmake invocation.
    unset(INSTALL_PACKAGES CACHE)
  endif()

endif()
