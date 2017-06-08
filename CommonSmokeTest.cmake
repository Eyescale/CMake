# Copyright (c) 2017 Stefan.Eilemann@epfl.ch

# Create a smoke test target for the given target executable,
# running it from the installation folder with the given arguments as a smoke
# test to check installation:
#   common_smoke_test(<Target> [args])
#
# Output targets
# - smoketests: run all smoke tests of the given (sub)project
# - <project>-smoketests: run all smoke tests of the given (sub)project
# - <Target>-smoketest: run the given smoke test

if(NOT TARGET smoketests)
  add_custom_target(smoketests)
  set_target_properties(smoketests PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)
endif()

if(NOT TARGET ${PROJECT_NAME}-smoketests)
  add_custom_target(${PROJECT_NAME}-smoketests)
  set_target_properties(${PROJECT_NAME}-smoketests PROPERTIES
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)
  add_dependencies(smoketests ${PROJECT_NAME}-smoketests)
endif()

function(common_smoke_test Target)
  set(_cmake "${CMAKE_CURRENT_BINARY_DIR}/${Target}.smoke.cmake")
  file(WRITE ${_cmake} "
    set(ENV{LD_LIBRARY_PATH} ${CMAKE_INSTALL_PREFIX}/lib:\$ENV{LD_LIBRARY_PATH})
    set(ENV{DYLD_LIBRARY_PATH} ${CMAKE_INSTALL_PREFIX}/lib:\$ENV{DYLD_LIBRARY_PATH})
    execute_process(COMMAND \${APP} ${ARGN} TIMEOUT 60
    OUTPUT_VARIABLE _output ERROR_VARIABLE _output RESULT_VARIABLE _result)
    if(NOT _result EQUAL 0)
      message(FATAL_ERROR \"${Target} failed to run:\${_output}\")
    endif()
  ")

  set(_app $<TARGET_FILE_NAME:${Target}>)
  get_target_property(_isMacGUI ${Target} MACOSX_BUNDLE_INFO_PLIST)
  if(_isMacGUI)
    set(_app ${_app}.app/Contents/MacOS/${_app})
  endif()

  add_custom_target(${Target}-smoketest DEPENDS ${PROJECT_NAME}-install
    COMMAND ${CMAKE_COMMAND} -DAPP="${CMAKE_INSTALL_PREFIX}/bin/${_app}" -P ${_cmake}
    COMMENT "Running smoke test ${Name}"
    EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)
  add_dependencies(${PROJECT_NAME}-smoketests ${Target}-smoketest)
endfunction()
