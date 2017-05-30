# Copyright (c) 2017 Stefan.Eilemann@epfl.ch
#                    Raphael.Dumusc@epfl.ch
#
# Provides functions to generate .png dependency graph images using graphviz:
#   common_graph_dep(From To Required Source):
#     Write a dependency From->To into global properties, called by
#     common_find_package() and add_subproject().
#   common_graph(Name):
#     Write .dot from the global properties and add Name-graph target, called by
#     common_find_package_post().
#
# CMake options:
# * COMMON_GRAPH_SHOW_EXTERNAL include external dependencies in graphs.
# * COMMON_GRAPH_SHOW_OPTIONAL include optional dependencies in graphs.
#
# Targets generated:
# * graphs: generate .png graphs for all (sub)projects.
# * ${PROJECT_NAME}-graph generate a .png graph for the project.

include(CommonTarget)
if(COMMON_GRAPH_DONE)
  return()
endif()
set(COMMON_GRAPH_DONE ON)

option(COMMON_GRAPH_SHOW_EXTERNAL "Include external dependencies in graphs" ON)
option(COMMON_GRAPH_SHOW_OPTIONAL "Include optional dependencies in graphs" OFF)

find_program(DOT_EXECUTABLE dot)
find_program(TRED_EXECUTABLE tred)

function(common_graph_dep From To Required Source)
  string(REPLACE "-" "_" Title ${From})
  string(REPLACE "-" "_" Dep ${To})
  # prevent syntax error in tred, e.g. Magick++ -> MagickPP
  string(REPLACE "+" "P" Title ${Title})
  string(REPLACE "+" "P" Dep ${Dep})

  if(Source)
    set(style "style=bold")
  elseif(NOT COMMON_GRAPH_SHOW_EXTERNAL)
    return()
  elseif(Required)
    set(style "style=solid")
  elseif(COMMON_GRAPH_SHOW_OPTIONAL)
    set(style "style=dashed")
  else()
    return()
  endif()

  set_property(GLOBAL APPEND_STRING PROPERTY ${From}_COMMON_GRAPH
    "${Title} [label=\"${From}\"]\n")
  if(Required)
    set_property(GLOBAL APPEND_STRING PROPERTY ${From}_COMMON_GRAPH
      "${Dep} [${style}, label=\"${To}\"]\n"
      "\"${Dep}\" -> \"${Title}\" [${style}]\n" )
  else()
    set_property(GLOBAL APPEND_STRING PROPERTY ${From}_COMMON_GRAPH
      "${Dep} [${style}, label=\"${To}\", fontsize=10]\n"
      "\"${Dep}\" -> \"${Title}\" [${style}]\n" )
  endif()
  set_property(GLOBAL APPEND PROPERTY ${From}_COMMON_GRAPH_DEPENDS ${To})
endfunction()

function(common_graph Name)
  # collect graph recursively
  get_property(graph GLOBAL PROPERTY ${Name}_COMMON_GRAPH)
  get_property(graph_depends GLOBAL PROPERTY ${Name}_COMMON_GRAPH_DEPENDS)

  list(LENGTH graph_depends nDepends)
  while(nDepends)
    list(GET graph_depends 0 dep)
    list(REMOVE_AT graph_depends 0)
    get_property(graph_dep GLOBAL PROPERTY ${dep}_COMMON_GRAPH)
    get_property(graph_dep_depends GLOBAL PROPERTY ${dep}_COMMON_GRAPH_DEPENDS)

    set(graph "${graph_dep} ${graph}")
    list(APPEND graph_dep ${graph_dep_depends})
    list(LENGTH graph_depends nDepends)
  endwhile()

  if(DOT_EXECUTABLE AND TRED_EXECUTABLE)
    set(_dot_file ${CMAKE_CURRENT_BINARY_DIR}/${Name}.dot)
    file(GENERATE OUTPUT ${_dot_file}
      CONTENT "strict digraph G { rankdir=\"RL\"; ${graph} }")

    set(_tred_dot_file ${CMAKE_CURRENT_BINARY_DIR}/${Name}_tred.dot)
    add_custom_command(OUTPUT ${_tred_dot_file}
      COMMAND ${TRED_EXECUTABLE} ${_dot_file} > ${_tred_dot_file}
      DEPENDS ${_dot_file})

    set(_image_folder ${PROJECT_BINARY_DIR}/doc/images)
    set(_image_file ${_image_folder}/${Name}.png)
    add_custom_command(OUTPUT ${_image_file}
      COMMAND ${CMAKE_COMMAND} -E make_directory ${_image_folder}
      COMMAND ${DOT_EXECUTABLE} -o ${_image_file} -Tpng ${_tred_dot_file}
      DEPENDS ${_tred_dot_file})

    add_custom_target(${Name}-graph DEPENDS ${_image_file})
    set_target_properties(${Name}-graph PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD ON
      FOLDER ${Name}/doxygen)
    common_target(graphs doxygen)
    add_dependencies(graphs ${Name}-graph)
  endif()
endfunction()
