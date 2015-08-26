# Copyright (c) 2015 Daniel.Nachbaur@epfl.ch
#
# Write ${PROJECT_NAME}ConfigVersion.cmake, ${PROJECT_NAME}Config.cmake, and
# ${PROJECT_NAME}Targets.cmake like CMake suggests to create a 'package' that
# can be found by downstream projects, either from the build tree (subproject)
# or from the install tree (package/module).
# http://www.cmake.org/cmake/help/v3.2/manual/cmake-packages.7.html#creating-packages
#
# Note that the install tree export target set creation is only supported if
# CMake 3 is used. On the other hand, a CMake 3 generated install tree can be
# consumed either by CMake 2 or 3.
#
# Uses:
# * ${UPPER_PROJECT_NAME}_DEPENDENT_LIBRARIES - list of 'leaking'/public
#   dependent libraries that need to be 'found' first to provide targets that
#   this project is depending on. Usually this matches the list of targets that
#   are used PUBLIC in target_link_libraries().
# * ${PROJECT_NAME}Targets - the set of targets to export, added by
#   CommonLibrary.cmake

# Generate ${PROJECT_NAME}ConfigVersion.cmake
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
  VERSION ${VERSION} COMPATIBILITY SameMajorVersion
)

# Add find_package/find_dependency (CMake2/3) calls for leaking dependent
# libraries to ${PROJECT_NAME}Config.cmake
if(${UPPER_PROJECT_NAME}_DEPENDENT_LIBRARIES)
  set(DEPENDENT_LIBRARIES
    "  # find dependent libraries which provide dependent targets\n"
    "  if(CMAKE_MAJOR_VERSION GREATER 2)\n"
    "    include(CMakeFindDependencyMacro)\n")

  foreach(_dependent ${${UPPER_PROJECT_NAME}_DEPENDENT_LIBRARIES})
    list(APPEND DEPENDENT_LIBRARIES "    find_dependency(${_dependent})\n")
  endforeach()
  list(APPEND DEPENDENT_LIBRARIES "  else()\n")
  foreach(_dependent ${${UPPER_PROJECT_NAME}_DEPENDENT_LIBRARIES})
    list(APPEND DEPENDENT_LIBRARIES "    find_package(${_dependent} QUIET)\n")
  endforeach()
  list(APPEND DEPENDENT_LIBRARIES "  endif()\n")
  string(REGEX REPLACE ";" " " DEPENDENT_LIBRARIES ${DEPENDENT_LIBRARIES})
endif()

# Generate ${PROJECT_NAME}Config.cmake; is consumed by any find_package() call
# to this project. Does an inclusion of ${PROJECT_NAME}Targets.cmake if the
# target ${PROJECT_NAME} is not defined, which should only be the case when
# finding this project from the install tree.
configure_package_config_file("${CMAKE_CURRENT_LIST_DIR}/CommonConfig.cmake.in"
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
  INSTALL_DESTINATION ${CMAKE_MODULE_INSTALL_PATH}
)

install(FILES "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
              "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
        DESTINATION ${CMAKE_MODULE_INSTALL_PATH}
)

# No export(EXPORT) in CMake 2 or if common_library has not been used.
if(CMAKE_MAJOR_VERSION LESS 3 OR NOT TARGET ${PROJECT_NAME}_ALIAS)
  return()
endif()

# Generate ${PROJECT_NAME}Targets.cmake; is written after the CMake run
# succeeds. Provides IMPORTED targets when using this project from the install
# tree.
export(EXPORT ${PROJECT_NAME}Targets
  FILE "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake"
)

install(EXPORT ${PROJECT_NAME}Targets FILE ${PROJECT_NAME}Targets.cmake
        DESTINATION ${CMAKE_MODULE_INSTALL_PATH}
)
