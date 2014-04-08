# Copyright (c) 2012-2014 Stefan Eilemann <eile@eyescale.ch>

# Configures a Doxyfile and provides doxygen and doxygit targets. Relies on
# TargetHooks installed by Common and must be included after all targets!
#
# Input Variables
# * DOXYGEN_EXTRA_INPUT additional parsed input files, appended to INPUT in
#   Doxyfile
# * DOXYGEN_EXTRA_EXCLUDE additional excluded input files, appended to EXCLUDE
#   in Doxyfile
# * DOXYGEN_EXTRA_FILES additional files to be copied to documentation,
#   appended to HTML_EXTRA_FILES in Doxyfile
# * DOXYGEN_PROJECT_NAME the name to use in the documentation title. Defaults
#   to CMAKE_PROJECT_NAME is not provided.
# * DOXYGEN_MAINPAGE_MD markdown file to use as main page. See
#   USE_MDFILE_AS_MAINPAGE doxygen documentation for details.
# * DOXYGIT_MAX_VERSIONS number of versions to keep in directory
#
# IO Variables (set if not set as input)
# * GIT_DOCUMENTATION_REPO or GIT_ORIGIN_org is used
# * DOXYGEN_CONFIG_FILE or one is auto-configured
# * COMMON_ORGANIZATION_NAME (from GithubInfo)
#
# * doxygen runs doxygen after compiling and installing the project
# * doxygit runs doxygen and installs the documentation in
#   CMAKE_SOURCE_DIR/../GIT_DOCUMENTATION_REPO or
#   CMAKE_SOURCE_DIR/../GIT_ORIGIN_org

find_package(Doxygen)
if(NOT DOXYGEN_FOUND)
  return()
endif()

get_property(INSTALL_DEPENDS GLOBAL PROPERTY ALL_DEP_TARGETS)
if(NOT INSTALL_DEPENDS)
  message(FATAL_ERROR "No targets in CMake project, Common.cmake not used?")
endif()

if(NOT GIT_DOCUMENTATION_REPO)
  include(GithubInfo)
  set(GIT_DOCUMENTATION_REPO ${GIT_ORIGIN_org})
endif()

if(NOT PROJECT_PACKAGE_NAME)
  set(PROJECT_PACKAGE_NAME ${COMMON_PROJECT_DOMAIN}.${LOWER_PROJECT_NAME})
  message(STATUS "Using ${PROJECT_PACKAGE_NAME} for documentation")
endif()

if(NOT DOXYGEN_PROJECT_NAME)
  set(DOXYGEN_PROJECT_NAME ${CMAKE_PROJECT_NAME})
endif()

if(NOT COMMON_ORGANIZATION_NAME)
  set(COMMON_ORGANIZATION_NAME Unknown)
  message(STATUS "Using ${COMMON_ORGANIZATION_NAME} as organization")
endif()

if(NOT DOXYGEN_CONFIG_FILE)
  # Assuming there exists a Doxyfile and that needs configuring
  configure_file(${CMAKE_CURRENT_LIST_DIR}/Doxyfile
    ${CMAKE_BINARY_DIR}/doc/Doxyfile @ONLY)
  set(DOXYGEN_CONFIG_FILE ${CMAKE_BINARY_DIR}/doc/Doxyfile)
endif()

add_custom_target(doxygen_install
  ${CMAKE_COMMAND} -P ${CMAKE_BINARY_DIR}/cmake_install.cmake
  DEPENDS ${INSTALL_DEPENDS})

add_custom_target(doxygen_html
  ${DOXYGEN_EXECUTABLE} ${DOXYGEN_CONFIG_FILE}
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/doc
  COMMENT "Generating API documentation using doxygen" VERBATIM
  DEPENDS doxygen_install project_info)
if(COVERAGE)
  # CoverageReport generated in this case
  add_custom_target(doxygen DEPENDS doxygen_html tests)
else()
  add_custom_target(doxygen DEPENDS doxygen_html)
endif()

make_directory(${CMAKE_BINARY_DIR}/doc/html)
install(DIRECTORY ${CMAKE_BINARY_DIR}/doc/html
  DESTINATION ${DOC_DIR}/API
  COMPONENT doc CONFIGURATIONS Release)

if(GIT_DOCUMENTATION_REPO)
  set(GIT_DOCUMENTATION_DIR
    ${CMAKE_SOURCE_DIR}/../${GIT_DOCUMENTATION_REPO}/${PROJECT_NAME}-${VERSION_MAJOR}.${VERSION_MINOR})
  add_custom_target(doxycopy
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${GIT_DOCUMENTATION_DIR}
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_BINARY_DIR}/doc/html ${GIT_DOCUMENTATION_DIR}
    COMMENT "Copying API documentation to ${GIT_DOCUMENTATION_DIR}"
    DEPENDS doxygen VERBATIM)

  add_custom_target(doxygit
    COMMAND ${CMAKE_COMMAND} -DCMAKE_SOURCE_DIR="${CMAKE_SOURCE_DIR}"
    -DCMAKE_CURRENT_BINARY_DIR="${CMAKE_CURRENT_BINARY_DIR}"
    -DCMAKE_PROJECT_NAME="${GIT_DOCUMENTATION_REPO}"
    -DDOXYGIT_TOC_POST="${DOXYGIT_TOC_POST}"
    -DDOXYGIT_MAX_VERSIONS="${DOXYGIT_MAX_VERSIONS}"
    -P ${CMAKE_CURRENT_LIST_DIR}/Doxygit.cmake
    COMMENT "Updating ${GIT_DOCUMENTATION_REPO}"
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}/../${GIT_DOCUMENTATION_REPO}"
    DEPENDS doxycopy)
else()
  add_custom_target(doxygit
    COMMENT "doxygit target not available, missing GIT_DOCUMENTATION_REPO")
endif()
