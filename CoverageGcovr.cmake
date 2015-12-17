# Gcovr code coverage reporting
# - sets compiler flags to enable code coverage reporting (optional)
# - provides a function(add_gcovr_targets) to add 'coverage' targets
#
# CMake options:
#   ENABLE_GCOVR Must be explicitly enabled by the user since adding code
#   coverage compiler flags may break downstream projects.
#   Ex: cmake . -DENABLE_GCOVR=ON
#   Warning: THIS CHANGES CMAKE_C_FLAGS_DEBUG/CMAKE_CXX_FLAGS_DEBUG
#
# add_gcovr_targets(TARGET GCOVR_EXCLUDE)
#   Input variables:
#   * GCOVR_EXCLUDE List of files to exclude from the coverage report 
#
#   Targets generated:
#   * gcovr_html_${PROJECT_NAME} generate a HTML report for a specific project
#   * gcovr_txt_${PROJECT_NAME} generate a XML report for a specific project
#   * gcovr_xml_${PROJECT_NAME} generate a XML report for a specific project
#   * gcovr run all coverage_${PROJECT_NAME}

option(ENABLE_GCOVR "Enable code gcovr testing" OFF)

set(__profiling_flags "-fprofile-arcs -ftest-coverage")

if(ENABLE_GCOVR)
  if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_COMPILER_IS_CLANG)
     find_program(GCOVR gcovr)
     if(NOT GCOVR)
       message(FATAL_ERROR "No code coverage report, ${COVERAGE_MISSING}")
     endif()

     set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} ${__profiling_flags}")
     set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} ${__profiling_flags}")
   endif()
endif()

macro(_gcovr_target)
  #ARGV0 is the output name
  #ARGV1 is the output command line argument
  if(NOT TARGET gcovr_${ARGV0}_${PROJECT_NAME})
    add_custom_target(gcovr_${ARGV0}_${PROJECT_NAME}
      COMMAND ${GCOVR} -s -r ${CMAKE_SOURCE_DIR} ${__gcovr_exclude} ${ARGV1}
        -o gcovr.${ARGV0}
        COMMENT "Creating ${ARGV0} coverage report"
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
      )
  endif()
  add_dependencies(gcovr_${ARGV0}_${PROJECT_NAME} ${TEST_TARGET})
endmacro()

function(add_gcovr_targets TEST_TARGET GCOVR_EXCLUDE)
   foreach(__exclude ${GCOVR_EXCLUDE})
      set(__gcovr_exclude ${__gcovr_exclude} "--exclude=${__exclude}")
   endforeach()

  _gcovr_target(txt "")
  _gcovr_target(xml --xml)
  _gcovr_target(html --html)
  
  if(NOT TARGET gcovr)
    add_custom_target(gcovr)
  endif()
  add_dependencies(gcovr gcovr_txt_${PROJECT_NAME})
  add_dependencies(gcovr gcovr_xml_${PROJECT_NAME})
  add_dependencies(gcovr gcovr_html_${PROJECT_NAME})
endfunction()
