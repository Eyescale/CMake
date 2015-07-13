##
# Copyright (c) 2010 Daniel Pfeifer <daniel@pfeifer-mail.de>
#               2011-2014 Stefan Eilemann <eile@eyescale.ch>
#
#  sudo apt-get install devscripts
##

if(NOT LSB_DISTRIBUTOR_ID STREQUAL "Ubuntu")
  return()
endif()

find_program(DEBUILD_EXECUTABLE debuild)
find_program(DPUT_EXECUTABLE dput)

if(NOT DEBUILD_EXECUTABLE)
  message(STATUS "debuild not found, no PPA upload")
  return()
endif()
if(NOT DPUT_EXECUTABLE)
  message(STATUS "dput not found, no PPA upload")
  return()
endif()
if(NOT GIT_EXECUTABLE)
  message(STATUS "git not found, no PPA upload")
  return()
endif()
if(NOT CPACK_PACKAGE_NAME)
  message(STATUS "CPACK_PACKAGE_NAME not set, no PPA upload")
  return()
endif()
if(NOT DPUT_HOST)
  message(STATUS "DPUT_HOST not set, no PPA upload")
  return()
endif()

set(UPLOADPPA_FOUND TRUE)
include(Ubuntu)

# DEBIAN/control
# debian policy enforce lower case for package name
# Package: (mandatory)
IF(NOT CPACK_DEBIAN_PACKAGE_NAME)
  STRING(TOLOWER "${CPACK_PACKAGE_NAME}" CPACK_DEBIAN_PACKAGE_NAME)
ENDIF(NOT CPACK_DEBIAN_PACKAGE_NAME)

# Section: (recommended)
IF(NOT CPACK_DEBIAN_PACKAGE_SECTION)
  SET(CPACK_DEBIAN_PACKAGE_SECTION "devel")
ENDIF(NOT CPACK_DEBIAN_PACKAGE_SECTION)

# Priority: (recommended)
IF(NOT CPACK_DEBIAN_PACKAGE_PRIORITY)
  SET(CPACK_DEBIAN_PACKAGE_PRIORITY "optional")
ENDIF(NOT CPACK_DEBIAN_PACKAGE_PRIORITY)

file(STRINGS ${CPACK_PACKAGE_DESCRIPTION_FILE} DESC_LINES)
foreach(LINE ${DESC_LINES})
  set(DEB_LONG_DESCRIPTION "${DEB_LONG_DESCRIPTION} ${LINE}\n")
endforeach(LINE ${DESC_LINES})

function(UPLOAD_PPA UBUNTU_NAME)
  set(DEBIAN_BASE_DIR ${PROJECT_BINARY_DIR}/Debian/${UBUNTU_NAME})
  file(REMOVE_RECURSE ${DEBIAN_BASE_DIR})
  set(DEBIAN_SOURCE_DIR
    ${DEBIAN_BASE_DIR}/${CPACK_DEBIAN_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-source)
  execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${DEBIAN_BASE_DIR})
  execute_process(
    COMMAND ${GIT_EXECUTABLE} archive --worktree-attributes
    --prefix ${CPACK_DEBIAN_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-source/
    -o ${DEBIAN_BASE_DIR}.tar HEAD
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
  execute_process(COMMAND ${CMAKE_COMMAND} -E tar xzf ${DEBIAN_BASE_DIR}.tar
    WORKING_DIRECTORY ${DEBIAN_BASE_DIR})

  file(MAKE_DIRECTORY ${DEBIAN_SOURCE_DIR}/debian)
  file(REMOVE_RECURSE ${DEBIAN_SOURCE_DIR}/.git)

  ##############################################################################
  # debian/control
  set(DEBIAN_CONTROL ${DEBIAN_SOURCE_DIR}/debian/control)
  file(WRITE ${DEBIAN_CONTROL}
    "Source: ${CPACK_DEBIAN_PACKAGE_NAME}\n"
    "Section: ${CPACK_DEBIAN_PACKAGE_SECTION}\n"
    "Priority: ${CPACK_DEBIAN_PACKAGE_PRIORITY}\n"
    "Maintainer: ${CPACK_PACKAGE_CONTACT}\n"
    "Build-Depends: "
    )

  foreach(DEP ${CPACK_DEBIAN_BUILD_DEPENDS})
    file(APPEND ${DEBIAN_CONTROL} "${DEP}, ")
  endforeach(DEP ${CPACK_DEBIAN_BUILD_DEPENDS})

  file(APPEND ${DEBIAN_CONTROL} "cmake\n"
    "Standards-Version: 3.9.1\n"
    "Homepage: ${CPACK_PACKAGE_VENDOR}\n"
    "\n"
    "Package: ${CPACK_DEBIAN_PACKAGE_NAME}\n"
    "Architecture: any\n"
    "Depends: ")

  foreach(COMPONENT ${CPACK_COMPONENTS_ALL})
    set(PACKAGE ${CPACK_DEBIAN_PACKAGE_NAME}-${COMPONENT})
    file(APPEND ${DEBIAN_CONTROL} "${PACKAGE}, ")
  endforeach()

  file(APPEND ${DEBIAN_CONTROL} "\n"
    "Description: ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}\n"
    "${DEB_LONG_DESCRIPTION}"
    )

  foreach(COMPONENT ${CPACK_COMPONENTS_ALL})
    string(TOUPPER ${COMPONENT} UPPER_COMPONENT)
    set(DEPENDS "${CPACK_DEBIAN_PACKAGE_DEPENDS}")
    foreach(DEP ${CPACK_COMPONENT_${UPPER_COMPONENT}_DEPENDS})
      set(DEPENDS "${DEPENDS}, ${CPACK_DEBIAN_PACKAGE_NAME}-${DEP}")
    endforeach(DEP ${CPACK_COMPONENT_${UPPER_COMPONENT}_DEPENDS})
    file(APPEND ${DEBIAN_CONTROL} "\n"
      "Package: ${CPACK_DEBIAN_PACKAGE_NAME}-${COMPONENT}\n"
      "Architecture: any\n"
      "Depends: ${DEPENDS}\n"
      "Description: ${CPACK_PACKAGE_DESCRIPTION_SUMMARY}"
      ": ${CPACK_COMPONENT_${UPPER_COMPONENT}_DISPLAY_NAME}\n"
      "${DEB_LONG_DESCRIPTION}"
      " .\n"
      " ${CPACK_COMPONENT_${UPPER_COMPONENT}_DESCRIPTION}\n"
      )
  endforeach(COMPONENT ${CPACK_COMPONENTS_ALL})

  ##############################################################################
  # debian/copyright
  set(DEBIAN_COPYRIGHT ${DEBIAN_SOURCE_DIR}/debian/copyright)
  execute_process(COMMAND ${CMAKE_COMMAND} -E
    copy ${CPACK_RESOURCE_FILE_LICENSE} ${DEBIAN_COPYRIGHT}
    )

  ##############################################################################
  # debian/rules
  set(DEBIAN_RULES ${DEBIAN_SOURCE_DIR}/debian/rules)
  file(WRITE ${DEBIAN_RULES}
    "#!/usr/bin/make -f\n"
    "\n"
    "BUILDDIR = build_dir\n"
    "\n"
    "build:\n"
    "	mkdir -p $(BUILDDIR)\n"
    "	cd $(BUILDDIR); cmake ..\n"
    "	make -C $(BUILDDIR) preinstall\n"
    "	touch build\n"
    "\n"
    "binary: binary-indep binary-arch\n"
    "\n"
    "binary-indep: build\n"
    "\n"
    "binary-arch: build\n"
    "	cd $(BUILDDIR); cmake -DCOMPONENT=Unspecified -DCMAKE_INSTALL_PREFIX=../debian/tmp/usr -P cmake_install.cmake\n"
    "	mkdir -p debian/tmp/DEBIAN\n"
    "	dpkg-gencontrol -p${CPACK_DEBIAN_PACKAGE_NAME}\n"
    "	dpkg --build debian/tmp ..\n"
    )

  foreach(COMPONENT ${CPACK_COMPONENTS_ALL})
    set(PATH debian/tmp_${COMPONENT})
    set(PACKAGE ${CPACK_DEBIAN_PACKAGE_NAME}-${COMPONENT})
    file(APPEND ${DEBIAN_RULES}
      "	cd $(BUILDDIR); cmake -DCOMPONENT=${COMPONENT} -DCMAKE_INSTALL_PREFIX=../${PATH}/usr -P cmake_install.cmake\n"
      "	mkdir -p ${PATH}/DEBIAN\n"
      "	dpkg-gencontrol -p${PACKAGE} -P${PATH}\n"
      "	dpkg --build ${PATH} ..\n"
      )
  endforeach(COMPONENT ${CPACK_COMPONENTS_ALL})

  file(APPEND ${DEBIAN_RULES}
    "\n"
    "clean:\n"
    "	rm -f build\n"
    "	rm -rf $(BUILDDIR)\n"
    "\n"
    ".PHONY: binary binary-arch binary-indep clean\n"
    )

  execute_process(COMMAND chmod +x ${DEBIAN_RULES})

  ##############################################################################
  # debian/compat
  file(WRITE ${DEBIAN_SOURCE_DIR}/debian/compat "7")

  ##############################################################################
  # debian/source/format
  file(WRITE ${DEBIAN_SOURCE_DIR}/debian/source/format "3.0 (native)")

  ##############################################################################
  # debian/changelog
  set(DEBIAN_CHANGELOG ${DEBIAN_SOURCE_DIR}/debian/changelog)
  execute_process(COMMAND date -R  OUTPUT_VARIABLE DATE_TIME)
  file(WRITE ${DEBIAN_CHANGELOG}
    "${CPACK_DEBIAN_PACKAGE_NAME} (${CPACK_PACKAGE_VERSION}~${UBUNTU_NAME}) ${UBUNTU_NAME}; urgency=low\n\n"
    "  * Package built with CMake\n"
    )
  if(UBUNTU_LP_BUG)
    file(APPEND ${DEBIAN_CHANGELOG} "  * LP: #${UBUNTU_LP_BUG}\n")
  endif()
  file(APPEND ${DEBIAN_CHANGELOG} "\n -- ${CPACK_PACKAGE_CONTACT}  ${DATE_TIME}")

  ##############################################################################
  # debuild -S
  set(DEB_SOURCE_CHANGES
    ${CPACK_DEBIAN_PACKAGE_NAME}_${CPACK_PACKAGE_VERSION}~${UBUNTU_NAME}_source.changes
    )

  add_custom_command(
    OUTPUT ${DEBIAN_BASE_DIR}/${DEB_SOURCE_CHANGES}
    COMMAND ${DEBUILD_EXECUTABLE} -S
    WORKING_DIRECTORY ${DEBIAN_SOURCE_DIR}
    COMMENT "Generate ${CPACK_DEBIAN_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION} for ${DPUT_HOST}"
    )

  ##############################################################################
  # dput ppa:your-lp-id/ppa <source.changes>
  add_custom_target(${PROJECT_NAME}_dput_${UBUNTU_NAME}
    ${DPUT_EXECUTABLE} ${DPUT_HOST} ${DEB_SOURCE_CHANGES}
    DEPENDS ${DEBIAN_BASE_DIR}/${DEB_SOURCE_CHANGES}
    WORKING_DIRECTORY ${DEBIAN_BASE_DIR}
    COMMENT "Upload ${CPACK_DEBIAN_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION} to ${DPUT_HOST}"
    )

  if(NOT TARGET dput_${UBUNTU_NAME})
    add_custom_target( dput_${UBUNTU_NAME})
  endif()
  add_dependencies(dput_${UBUNTU_NAME} ${PROJECT_NAME}_dput_${UBUNTU_NAME})

  set(DPUT_TARGETS ${DPUT_TARGETS} ${PROJECT_NAME}_dput_${UBUNTU_NAME} PARENT_SCOPE)
endfunction()

function(UPLOAD_PPAS)
  foreach(UBUNTU_CODENAME ${UBUNTU_CODENAMES})
    upload_ppa(${UBUNTU_CODENAME})
  endforeach()
  add_custom_target(${PROJECT_NAME}_dput DEPENDS ${DPUT_TARGETS})
  if(NOT TARGET dput)
    add_custom_target(dput)
  endif()
  add_dependencies(dput ${PROJECT_NAME}_dput)
endfunction()
