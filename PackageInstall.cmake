
# Copyright (c) 2014 Stefan.Eilemann@epfl.ch
# adds non-default package-install target

if(NOT TARGET package-install AND PACKAGE_FILE_NAME)
  if(LSB_DISTRIBUTOR_ID STREQUAL "Ubuntu")
    set(SYSTEM_INSTALL_CMD dpkg -i)
  elseif(REDHAT)
    set(SYSTEM_INSTALL_CMD rpm -i)
  else()
    message(STATUS "Unknown system installer, using 'make install'")
    set(SYSTEM_INSTALL_CMD
      ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target install)
  endif()

  add_custom_target(package-install
    COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target package
    COMMAND sudo ${SYSTEM_INSTALL_CMD} ${PACKAGE_FILE_NAME}
    COMMENT "Build and sudo install package"
    VERBATIM)
endif()
