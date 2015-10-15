# Copyright (c) 2012-2014 Stefan.Eilemann@epfl.ch

# Called as a script by 'doxygit' target set by CommonDocumentation.cmake
#
# It is meant to be invoked inside a documentation repository
# (e.g. CMAKE_CURRENT_SOURCE_DIR = src/BBPDocumentation).
#
# Its tasks are to:
# * 'git add' all the changes introduced in the documentation repo.
# * 'git rm' old versions of documentation to keep only the latest in HEAD.
# * Copy the latest css and image files from the source CMake subtree.
# * Optional: generate an 'index.html' page that references all the projects.
#   This assumes the presence of a ProjectInfo.cmake file in each documentation
#   folder, and has been deprecated in favor of a Jekyll-generated index page
#   on github.io (GitHub pages).
#
# Input Variables:
# * PROJECT_NAME The name of the documentation project (e.g. 'BBPDocumentation')
#
# Optional Input Variables:
# * DOXYGIT_GENERATE_INDEX generate an index.html page (default: OFF)
# * DOXYGIT_MAX_VERSIONS number of versions to keep in directory (default: 10)
# * DOXYGIT_TOC_POST html content to insert in 'index.html' (default: '')
#
# Input files:
# ${CMAKE_CURRENT_SOURCE_DIR}/${Entry}/ProjectInfo.cmake additional project info

# CMake escapes the whitespaces when passing a string to a script
if(DOXYGIT_TOC_POST)
  string(REPLACE "\\ " " " DOXYGIT_TOC_POST ${DOXYGIT_TOC_POST})
endif()

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})

if(NOT GIT_FOUND)
  find_package(Git REQUIRED QUIET)
endif()

include(CommonProcess)
include(Maturity)
include(VersionUtils)

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

# generate version table
file(GLOB Entries RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *-*)
if(NOT DOXYGIT_MAX_VERSIONS)
  set(DOXYGIT_MAX_VERSIONS 10)
endif()

# sort entries forward for names, backwards for versions
list(SORT Entries)
set(LAST_Project)
set(RemovedEntries)
foreach(Entry ${Entries})
  string(REGEX REPLACE "^(.+)-.+$" "\\1" Project ${Entry})
  if(NOT Project STREQUAL LAST_Project)
    if(SubEntries)
      list(REVERSE SubEntries)
      # We have added the sorting of SubEntries according to version numbers
      # because list(SORT ... ) sorts entries by alpha numeric order.
      # old behavior: 1.4, 1,3, 1.10 is sorted as 1.10, 1.3, 1.4
      # new behavior: 1.4, 1,3, 1.10 is sorted as 1.3, 1.4, 1.10
      set(VersionList)
      set(ProjectName)
      foreach(SubEntry ${SubEntries})
        if(SubEntry MATCHES "^([A-Za-z0-9_]+)-([0-9]+\\.[0-9]+)")
            set(ProjectName ${CMAKE_MATCH_1})
            list(APPEND VersionList ${CMAKE_MATCH_2})
        endif()
      endforeach()
      _version_sort("${VersionList}" SortedVersionList )
      list(REVERSE SortedVersionList) #versions are descending order
      set(SubEntries)
      foreach(version ${SortedVersionList})
        list(APPEND SubEntries "${ProjectName}-${version}")
      endforeach()
    endif()

    foreach(i RANGE ${DOXYGIT_MAX_VERSIONS}) # limit # of entries
      if(SubEntries)
        list(GET SubEntries 0 SubEntry)
        list(APPEND Entries2 ${SubEntry})
        list(REMOVE_AT SubEntries 0)
      endif()
    endforeach()

    foreach(SubEntry ${SubEntries}) # remove old documentation
      list(APPEND RemovedEntries ${SubEntry})
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

if(DOXYGIT_GENERATE_INDEX)
  set(_index_html_file "${CMAKE_CURRENT_SOURCE_DIR}/index.html")

  set(LAST_Project)
  set(BODY)

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

endif()

if(IS_DIRECTORY _projects)
  set(PROJECTS "_projects/*.md")
endif()

execute_process(
  COMMAND "${GIT_EXECUTABLE}" add --all images ${Entries} ${RemovedEntries}
  css/github.css index.html ${PROJECTS}
  WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")
