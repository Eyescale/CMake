# Copyright (c) 2012-2014 Stefan.Eilemann@epfl.ch

# Used by Documentation projects, which include it in their CMakeLists
#
# Input Variables
# * DOXYGIT_MAX_VERSIONS number of versions to keep in directory
#
# Also used by 'doxygit' target from DoxygenRule.cmake

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake/common)
list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake/common/oss)

find_package(Git REQUIRED)
option(COMMON_INSTALL_DOCUMENTATION "Install documentation projects" OFF)

include(CommonProcess)
include(Maturity)

# Project_NAME = PROJECT_NAME with capitalized first letter
string(SUBSTRING ${PROJECT_NAME} 0 1 FIRST_LETTER)
string(TOUPPER ${FIRST_LETTER} FIRST_LETTER)
string(REGEX REPLACE "^.(.*)" "${FIRST_LETTER}\\1" Project_NAME
  "${PROJECT_NAME}")

configure_file("${CMAKE_CURRENT_LIST_DIR}/github.css"
  "${PROJECT_SOURCE_DIR}/CMake/github.css" COPYONLY)
common_process("Copy icons to documentation repository" FATAL_ERROR
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_LIST_DIR}/icons
  ${PROJECT_SOURCE_DIR}/images)

file(WRITE "${PROJECT_BINARY_DIR}/index.html"
"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd\">\n"
"<html>\n"
"  <head>\n"
"    <title>${Project_NAME} Software Directory</title>\n"
"    <link rel=\"stylesheet\" href=\"CMake/github.css\" type=\"text/css\">"
"  </head>\n"
"  <body>\n"
"  <div class=\"toc\">"
"    <h2 style=\"text-align: center;\">Projects</h2>")

file(GLOB Entries RELATIVE ${PROJECT_SOURCE_DIR} *-*)
if(NOT DOXYGIT_MAX_VERSIONS)
  set(DOXYGIT_MAX_VERSIONS 10)
endif()

# sort entries forward for names, backwards for versions
list(SORT Entries)
set(LAST_Project)
foreach(Entry ${Entries})
  string(REGEX REPLACE "^(.+)-.+$" "\\1" Project ${Entry})
  if(NOT Project STREQUAL LAST_Project)
    if(SubEntries)
      list(REVERSE SubEntries)
    endif()

    foreach(i RANGE ${DOXYGIT_MAX_VERSIONS}) # limit # of entries
      if(SubEntries)
        list(GET SubEntries 0 SubEntry)
        list(APPEND Entries2 ${SubEntry})
        list(REMOVE_AT SubEntries 0)
      endif()
    endforeach()

    foreach(SubEntry ${SubEntries}) # remove old documentation
      common_process("Remove old ${SubEntry}" FATAL_ERROR
        COMMAND ${CMAKE_COMMAND} -E remove_directory ${SubEntry}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
    endforeach()

    set(LAST_Project ${Project})
    set(SubEntries)
  endif()
  list(APPEND SubEntries ${Entry})
endforeach()

list(REVERSE SubEntries)
set(Entries ${Entries2} ${SubEntries})

set(LAST_Project)
set(BODY)

# generate version table
set(GIT_DOCUMENTATION_INSTALL)
set(LAST_Project)

macro(DOXYGIT_WRITE_ENTRY)
  # Verbose entry in main body
  set(BODY "${BODY} <a name=\"${Project}\"></a><h2>${Project} ${VERSION}</h2>
    <p>${${PROJECT}_DESCRIPTION}</p>")

  # start entry
  file(APPEND "${PROJECT_BINARY_DIR}/index.html"
    "<a href=\"#${Project}\">${Project} ${VERSION}</a>
    <div class=\"badges\">")
  set(BODY "${BODY}
    <div class=\"factoid\"><a href=\"${Entry}/index.html\"><img src=\"images/help.png\"> API Documentation</a></div>")

  if(${PROJECT}_GIT_ROOT_URL)
    file(APPEND "${PROJECT_BINARY_DIR}/index.html"
      "<a href=\"${${PROJECT}_GIT_ROOT_URL}\"><img src=\"images/git.png\" alt=\"Source Repository\"></a>")
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_GIT_ROOT_URL}\"><img src=\"images/git.png\" alt=\"Git source repository\"> Source Repository</a></div>")
  endif()

  if(${PROJECT}_ISSUES_URL)
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_ISSUES_URL}\"><img src=\"images/issues.png\" alt=\"Project Issues\"> Project Issues</a></div>")
  endif()

  if(${PROJECT}_PACKAGE_URL)
    file(APPEND "${PROJECT_BINARY_DIR}/index.html"
      "<a href=\"${${PROJECT}_PACKAGE_URL}\"><img src=\"images/package.png\" alt=\"Packages\"></a>")
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_PACKAGE_URL}\"><img src=\"images/package.png\" alt=\"Packages\"> Packages</a></div>")
  endif()

  if(${PROJECT}_CI_URL)
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_CI_URL}\"><img src=\"${${PROJECT}_CI_PNG}\" alt=\"Continuous Integration\"> Continuous Integration</a></div>")
  endif()

  if(EXISTS "${PROJECT_SOURCE_DIR}/${Entry}/CoverageReport/index.html")
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${Entry}/CoverageReport/index.html\"><img src=\"images/search.png\" alt=\"Test Coverage Report\"> Test Coverage Report</a></div>")
  endif()

  file(APPEND "${PROJECT_BINARY_DIR}/index.html"
    "<a href=\"${Entry}/index.html\"><img src=\"images/help.png\"></a>
      <img src=\"images/${MATURITY}.png\" alt=\"${MATURITY_LONG}\">
    </div><div class=\"flush\"></div>")
  set(BODY "${BODY}
    <div class=\"factoid\"><img src=\"images/${MATURITY}.png\" alt=\"${MATURITY_LONG}\"> ${MATURITY_LONG} Code Quality</div>")

endmacro()

foreach(Entry ${Entries})
  string(REGEX REPLACE "^(.+)-.+$" "\\1" Project ${Entry})
  string(REGEX REPLACE "^.+-(.+)$" "\\1" VERSION ${Entry})
  string(TOUPPER ${Entry} ENTRY)
  string(TOUPPER ${Project} PROJECT)
  set(${PROJECT}_MATURITY "EP")
  if(EXISTS ${PROJECT_SOURCE_DIR}/${Entry}/ProjectInfo.cmake)
    include(${PROJECT_SOURCE_DIR}/${Entry}/ProjectInfo.cmake)
  endif()
  set(MATURITY ${${PROJECT}_MATURITY})
  set(MATURITY_LONG ${MATURITY_${MATURITY}})

  if(NOT Project STREQUAL LAST_Project) # start new toc entry
    if(LAST_Project) # close previous
      set(BODY "${BODY}</div><div class=\"flush\">")
    endif()
    doxygit_write_entry()
    set(BODY "${BODY}<div class=\"factoid\"><img src=\"images/help.png\"> Old Versions:")

    set(LAST_Project ${Project})
  else()
    set(BODY "${BODY} <a href=\"${Entry}/index.html\">${VERSION}</a>")
  endif()

  list(APPEND GIT_DOCUMENTATION_INSTALL ${Entry})
endforeach()

file(APPEND "${PROJECT_BINARY_DIR}/index.html" "${DOXYGIT_TOC_POST}
  </div>
  <div class=\"content\">
    <h1>${Project_NAME} Software Directory</h1>
    ${BODY}</div>
</html>")

configure_file("${PROJECT_BINARY_DIR}/index.html"
  "${PROJECT_SOURCE_DIR}/index.html" COPYONLY)

execute_process(COMMAND "${GIT_EXECUTABLE}" add --all images ${Entries}
  WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}")

if(COMMON_INSTALL_DOCUMENTATION)
  foreach(FOLDER ${GIT_DOCUMENTATION_INSTALL})
    install(DIRECTORY ${FOLDER} DESTINATION share/${Project_NAME}
      CONFIGURATIONS Release)
  endforeach()
endif()

# need at least one file for 'make install'
install(FILES index.html DESTINATION share/${Project_NAME}
  CONFIGURATIONS Release)
