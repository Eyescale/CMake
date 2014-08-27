#--------------------------------------------------
# Simple macro to add subprojects from subdirs
# ARGS :
#  name = the Project name as declared in project(xxx) of the sub-project
#  (optional) path = location of sub-project CMakeLists relative to this source dir
#--------------------------------------------------
include_directories("${PROJECT_BINARY_DIR}/include")

macro(add_subproject name)
 set(extra_args ${ARGN})
 list(LENGTH extra_args argc)
 if(argc GREATER 0)
   list(GET extra_args 0 path)
 else()
    set(path ${name})
 endif () 
 
 if(EXISTS "${PROJECT_SOURCE_DIR}/${path}/")
    option("SUBPROJECT_${name}" "Build ${name} " ON)
    if(SUBPROJECT_${name})
      # if the project needs to do anything special when configured as a sub project
      # then it should check the variable ${PROJECT_NAME}_EXTERNALLY_CONFIGURED
      set(${name}_IS_SUBPROJECT ON)

      # set ${PROJECT}_DIR to the location of the new build dir for the project
      if (NOT ${name}_DIR)      
        set(${name}_DIR "${PROJECT_BINARY_DIR}/${name}" CACHE PATH "Location of ${name} project" FORCE)
        message("${name}_DIR has been set to ${PROJECT_BINARY_DIR}/${name}")
      endif()

      # add the source sub directory to our build and set the binary dir to the build tree
      add_subdirectory("${PROJECT_SOURCE_DIR}/${path}" "${PROJECT_BINARY_DIR}/${name}")
    endif()
  endif()
endmacro(add_subproject)

