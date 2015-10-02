# Provides functions to generate dependency graph images using graphviz.
# Used by common_package.
# common_graph_dep(): Write a dependency from->to into global properties
# common_graph(): Write .dot from the global properties and add Name-graph rule

include(CommonTarget)
if(COMMON_GRAPH_DONE)
  return()
endif()
set(COMMON_GRAPH_DONE ON)

find_program(DOT_EXECUTABLE dot)
find_program(TRED_EXECUTABLE tred)
common_target(graphs doxygen)

function(common_graph_dep From To Required Source)
  string(REPLACE "-" "_" Title ${From})
  string(REPLACE "-" "_" Dep ${To})

  if(Source)
    set(style "style=bold")
  elseif(Required)
    set(style "style=solid")
  else()
    set(style "style=dashed")
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

  # write .dot
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/${Name}.dot
    "strict digraph G { rankdir=\"RL\"; ${graph} }" )

  if(DOT_EXECUTABLE AND TRED_EXECUTABLE)
    set(dest ${PROJECT_BINARY_DIR}/doc/images)
    add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${Name}_tred.dot
      COMMAND ${TRED_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/${Name}.dot >
               ${CMAKE_CURRENT_BINARY_DIR}/${Name}_tred.dot
      DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${Name}.dot)
    add_custom_command(OUTPUT ${dest}/${Name}.png
      COMMAND ${CMAKE_COMMAND} -E make_directory ${dest}
      COMMAND ${DOT_EXECUTABLE} -o ${dest}/${Name}.png -Tpng ${CMAKE_CURRENT_BINARY_DIR}/${Name}_tred.dot
      DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/${Name}_tred.dot)
    add_custom_target(${Name}-graph DEPENDS ${dest}/${Name}.png)
    set_target_properties(${Name}-graph PROPERTIES EXCLUDE_FROM_DEFAULT_BUILD ON
      FOLDER doxygen)
    add_dependencies(graphs ${Name}-graph)
  endif()
endfunction()
