# generates MacPorts Portfiles

if(NOT APPLE)
  return()
endif()
if(NOT CPACK_MACPORTS_CATEGORY)
  message("Missing CPACK_MACPORTS_CATEGORY for MacPorts generation")
  return()
endif()

include(GithubInfo)

# Configurables
if(NOT CMAKE_MACPORTS_NAME)
  set(CMAKE_MACPORTS_NAME ${PROJECT_NAME})
endif()
if(NOT CPACK_MACPORTS_VERSION)
  set(CPACK_MACPORTS_VERSION ${VERSION})
endif()
if(NOT MACPORTS_DIR)
  set(MACPORTS_DIR "${GIT_ORIGIN_org}Ports")
endif()

# format dependencies list into port:name string
foreach(CPACK_MACPORTS_DEPEND ${CPACK_MACPORTS_DEPENDS})
  if(${CPACK_MACPORTS_DEPEND} MATCHES "port:")
    set(CPACK_MACPORTS_TEMP "${CPACK_MACPORTS_TEMP} ${CPACK_MACPORTS_DEPEND}")
  else()
    set(CPACK_MACPORTS_TEMP
      "${CPACK_MACPORTS_TEMP} port:${CPACK_MACPORTS_DEPEND}")
  endif()
endforeach()
set(CPACK_MACPORTS_DEPENDS "${CPACK_MACPORTS_TEMP}")

# Create and install Portfile
set(PORTFILE_DIR "ports/${CPACK_MACPORTS_CATEGORY}/${CMAKE_MACPORTS_NAME}")
set(PORTFILE_GH_DIR "${PROJECT_SOURCE_DIR}/../${MACPORTS_DIR}")
set(PORTFILE "${PROJECT_BINARY_DIR}/${PORTFILE_DIR}/Portfile")
set(PORTFILE_GH "${PORTFILE_GH_DIR}/${PORTFILE_DIR}/Portfile")

configure_file(${CMAKE_CURRENT_LIST_DIR}/Portfile ${PORTFILE} @ONLY)
install(FILES ${PORTFILE} DESTINATION ${PORTFILE_DIR} COMPONENT lib)
install(CODE
  "execute_process(COMMAND /opt/local/bin/portindex ${CMAKE_INSTALL_PREFIX}/ports)"
  COMPONENT lib)

file(WRITE ${PROJECT_BINARY_DIR}/MacPortfile.cmake
    "list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake)\n"
    "configure_file(${PORTFILE} ${PORTFILE_GH} COPYONLY)\n"
    "execute_process(COMMAND /opt/local/bin/portindex ${PORTFILE_GH_DIR}/ports)"
  )

add_custom_target(portfile_${PROJECT_NAME}
  COMMAND ${CMAKE_COMMAND} -P ${PROJECT_BINARY_DIR}/MacPortfile.cmake
  COMMENT "Updating ${MACPORTS_DIR}")
