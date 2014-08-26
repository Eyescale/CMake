#--------------------------------------------------
# Simple macro to add subprojects from subdirs
# ARGS :
#  name = the Project name as declared in project(xxx) of the sub-project
#  path = location of sub-project CMakeLists relative to this source dir
#--------------------------------------------------
INCLUDE_DIRECTORIES("${CMAKE_BINARY_DIR}/include")

MACRO(ADD_SUBPROJECT name path)
  IF(EXISTS "${PROJECT_SOURCE_DIR}/${path}/")
    OPTION("SUBPROJECT_${name}" "Build ${name} " ON)
    IF(SUBPROJECT_${name})
      # if the project needs to do anything special when configured as a sub project
      # then it should check the variable ${PROJECT_NAME}_EXTERNALLY_CONFIGURED
      set(${name}_EXTERNALLY_CONFIGURED ON)

      # set ${PROJECT}_DIR to the location of the new build dir for the project
      if (NOT ${name}_DIR)      
        set(${name}_DIR "${CMAKE_CURRENT_BINARY_DIR}/${name}" CACHE PATH "Location of ${name} project" FORCE)
        message("${name}_DIR has been set to ${CMAKE_CURRENT_BINARY_DIR}/${name}")
      endif()

      # add the source sub directory to our build and set the binary dir to the build tree
      ADD_SUBDIRECTORY("${CMAKE_CURRENT_SOURCE_DIR}/${path}" "${CMAKE_CURRENT_BINARY_DIR}/${name}")
    ENDIF(SUBPROJECT_${name})
  ENDIF(EXISTS "${PROJECT_SOURCE_DIR}/${path}/")
ENDMACRO(ADD_SUBPROJECT)

