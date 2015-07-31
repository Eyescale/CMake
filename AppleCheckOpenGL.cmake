
# Provides the following function:
# * apple_check_opengl(<target>): Adds a test to ${PROJECT_NAME}-tests to check
#   that only one OpenGL (X11 lib or OpenGL framework) is linked to the given
#   <target> on OS X

function(apple_check_opengl Target)
  if(NOT APPLE)
    return()
  endif()

  add_test(NAME ${Target}-AppleCheckOpenGL
    COMMAND ${CMAKE_COMMAND} -DAPPLE_CHECK_OPENGL_FILE="$<TARGET_FILE:${Target}>"
            -P ${CMAKE_SOURCE_DIR}/CMake/common/AppleCheckOpenGL.cmake)
  add_custom_target(${Target}-AppleCheckOpenGL
    COMMAND ${CMAKE_COMMAND} -DAPPLE_CHECK_OPENGL_FILE="$<TARGET_FILE:${Target}>"
            -P ${CMAKE_SOURCE_DIR}/CMake/common/AppleCheckOpenGL.cmake
    COMMENT "Verifying OpenGL link libraries of ${Target}")

  if(NOT TARGET ${PROJECT_NAME}-tests)
    add_custom_target(${PROJECT_NAME}-tests)
    set_target_properties(${PROJECT_NAME}-tests PROPERTIES
      EXCLUDE_FROM_DEFAULT_BUILD ON FOLDER ${PROJECT_NAME}/tests)
  endif()
  add_dependencies(${PROJECT_NAME}-tests ${Target}-AppleCheckOpenGL)
endfunction()

if(APPLE_CHECK_OPENGL_FILE)
  find_program(OTOOL otool)
  set(OPENGL_X11 libGL...dylib)
  set(OPENGL_FRAMEWORK OpenGL.framework)

  execute_process(COMMAND ${OTOOL} -L ${APPLE_CHECK_OPENGL_FILE}
    OUTPUT_VARIABLE LINKLIBS ERROR_VARIABLE ERROR)
  if(ERROR)
    message(FATAL_ERROR "Can't determine link libraries of ${APPLE_CHECK_OPENGL_FILE}: ${ERROR}")
  endif()
  if(LINKLIBS MATCHES ${OPENGL_X11} AND LINKLIBS MATCHES ${OPENGL_FRAMEWORK})
    message(FATAL_ERROR "Both ${OPENGL_X11} and ${OPENGL_FRAMEWORK} linked to ${APPLE_CHECK_OPENGL_FILE}")
  endif()
  string(REGEX MATCHALL "[^ \)]+${OPENGL_X11}" OPENGL_X11_LIBS ${LINKLIBS})
  if(OPENGL_X11_LIBS)
    list(LENGTH OPENGL_X11_LIBS NUM_OPENGL_X11_LIBS)
    if(NUM_OPENGL_X11_LIBS GREATER 1)
      message(FATAL_ERROR "Found ${NUM_OPENGL_X11_LIBS} different X11 OpenGL libraries in ${APPLE_CHECK_OPENGL_FILE}: ${OPENGL_X11_LIBS}")
    endif()
  endif()
endif()
