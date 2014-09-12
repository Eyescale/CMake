# Copyright (c) 2012-2014 Stefan.Eilemann@epfl.ch

# Called as an executable script by 'doxygit' target set by DoxygenRule.cmake
# and CommonDocumentation.cmake
#
# It is meant to be invoked inside a documentation repository
# (e.g. CMAKE_CURRENT_SOURCE_DIR = src/BBPDocumentation).
#
# Its tasks are to:
# * Generate the 'index.html' page that references all the projects.
# * Copy the latest 'github.css' from the source CMake subtree.
# * 'git add' all the changes introduced in the documentation repo.
#
# Input Variables:
# * PROJECT_NAME The name of the documentation project (e.g. 'BBPDocumentation')
# * PROJECT_BINARY_DIR destination for generating index.html (e.g. Build/Brion)
# Optional Input Variables:
# * DOXYGIT_MAX_VERSIONS number of versions to keep in directory (default: 10)
# * DOXYGIT_TOC_POST html content to insert in 'index.html' (default: '')

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

find_package(Git REQUIRED)

include(CommonProcess)
include(Maturity)

# Project_NAME = PROJECT_NAME with capitalized first letter
string(SUBSTRING ${PROJECT_NAME} 0 1 FIRST_LETTER)
string(TOUPPER ${FIRST_LETTER} FIRST_LETTER)
string(REGEX REPLACE "^.(.*)" "${FIRST_LETTER}\\1" Project_NAME
  "${PROJECT_NAME}")

configure_file("${CMAKE_CURRENT_LIST_DIR}/github.css"
  "${CMAKE_CURRENT_SOURCE_DIR}/css/github.css" COPYONLY)
common_process("Copy icons to documentation repository" FATAL_ERROR
  COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_LIST_DIR}/icons
  ${CMAKE_CURRENT_SOURCE_DIR}/images)

set(_index_html_file "${PROJECT_BINARY_DIR}/index.html")

file(WRITE ${_index_html_file}
"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd\">\n"
"<html>\n"
"  <head>\n"
"    <title>${Project_NAME} Software Directory</title>\n"
"    <link rel=\"stylesheet\" href=\"css/github.css\" type=\"text/css\">"
"  </head>\n"
"  <body>\n"
"  <div class=\"toc\">"
"    <h2 style=\"text-align: center;\">Projects</h2>")

file(GLOB Entries RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *-*)
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
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
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
set(LAST_Project)

macro(DOXYGIT_WRITE_ENTRY)
  # Verbose entry in main body
  set(BODY "${BODY} <a name=\"${Project}\"></a><h2>${Project} ${VERSION}</h2>
    <p>${${PROJECT}_DESCRIPTION}</p>")

  # start entry
  file(APPEND ${_index_html_file}
    "<a href=\"#${Project}\">${Project} ${VERSION}</a>
    <div class=\"badges\">")
  set(BODY "${BODY}
    <div class=\"factoid\"><a href=\"${Entry}/index.html\"><img src=\"images/help.png\"> API Documentation</a></div>")

  if(${PROJECT}_GIT_ROOT_URL)
    file(APPEND ${_index_html_file}
      "<a href=\"${${PROJECT}_GIT_ROOT_URL}\"><img src=\"images/git.png\" alt=\"Source Repository\"></a>")
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_GIT_ROOT_URL}\"><img src=\"images/git.png\" alt=\"Git source repository\"> Source Repository</a></div>")
  endif()

  if(${PROJECT}_ISSUES_URL)
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_ISSUES_URL}\"><img src=\"images/issues.png\" alt=\"Project Issues\"> Project Issues</a></div>")
  endif()

  if(${PROJECT}_PACKAGE_URL)
    file(APPEND ${_index_html_file}
      "<a href=\"${${PROJECT}_PACKAGE_URL}\"><img src=\"images/package.png\" alt=\"Packages\"></a>")
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_PACKAGE_URL}\"><img src=\"images/package.png\" alt=\"Packages\"> Packages</a></div>")
  endif()

  if(${PROJECT}_CI_URL)
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${${PROJECT}_CI_URL}\"><img src=\"${${PROJECT}_CI_PNG}\" alt=\"Continuous Integration\"> Continuous Integration</a></div>")
  endif()

  if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${Entry}/CoverageReport/index.html")
    set(BODY "${BODY}<div class=\"factoid\"><a href=\"${Entry}/CoverageReport/index.html\"><img src=\"images/search.png\" alt=\"Test Coverage Report\"> Test Coverage Report</a></div>")
  endif()

  file(APPEND ${_index_html_file}
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
  if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${Entry}/ProjectInfo.cmake)
    include(${CMAKE_CURRENT_SOURCE_DIR}/${Entry}/ProjectInfo.cmake)
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

endforeach()

file(APPEND ${_index_html_file} "${DOXYGIT_TOC_POST}
  </div>
  <div class=\"content\">
    <h1>${Project_NAME} Software Directory</h1>
    ${BODY}</div>
</html>")

configure_file(${_index_html_file}
  "${CMAKE_CURRENT_SOURCE_DIR}/index.html" COPYONLY)

execute_process(COMMAND "${GIT_EXECUTABLE}" add --all images ${Entries}
  css/github.css index.html WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
