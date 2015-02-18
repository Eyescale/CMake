# Copyright (c) 2012-2014 Stefan.Eilemann@epfl.ch
# See doc/GitTargets.md for documentation

# Options:
#  GITTARGETS_RELEASE_BRANCH current | even_minor | minor
#      create tags on the current, the next even minor version (e.g. 1.6) or for
#      each minor version
#
# Targets:
# * branch: Create a new branch for developing the current version and
#   push it to origin. The branch name is MAJOR.MINOR, where the minor
#   version is rounded up to the next even version. Odd minor numbers
#   are considered development versions, and might still be used when
#   releasing a pre-release version (e.g., 1.3.9 used for 1.4-beta).
# * cut: Delete the current version branch locally and remote.
# * tag: Create the version branch if needed, and create a tag
#   release-VERSION on the version branch HEAD. Pushes the tag to the
#   origin repository.
# * erase: Delete the current tag locally and remote
# * retag: Move an existing tag to HEAD
# * tarball: Create an archive of VERSION

if(GITTARGETS_FOUND)
  return()
endif()
set(GITTARGETS_FOUND 1)

find_package(Git)
if(NOT GIT_EXECUTABLE)
  return()
endif()

if(NOT GITTARGETS_RELEASE_BRANCH)
  set(GITTARGETS_RELEASE_BRANCH "minor")
endif()

find_program(GZIP_EXECUTABLE gzip)

# branch
math(EXPR _gittargets_ODD_MINOR "${VERSION_MINOR} % 2")
if(_gittargets_ODD_MINOR AND ${GITTARGETS_RELEASE_BRANCH} STREQUAL even_minor)
  math(EXPR BRANCH_VERSION "${VERSION_MINOR} + 1")
  set(BRANCH_VERSION ${VERSION_MAJOR}.${BRANCH_VERSION})
else()
  set(BRANCH_VERSION ${VERSION_MAJOR}.${VERSION_MINOR})
endif()

add_custom_target(make_branch_${PROJECT_NAME}
  COMMAND ${GIT_EXECUTABLE} checkout ${BRANCH_VERSION} || ${GIT_EXECUTABLE} checkout -b ${BRANCH_VERSION}
  COMMENT "Create local branch ${BRANCH_VERSION}"
  WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
  )

if(TARGET flatten_git_external)
  set(BRANCH_DEP flatten_git_external)
else()
  set(BRANCH_DEP make_branch_${PROJECT_NAME})
endif()

add_custom_target(branch_${PROJECT_NAME}
  COMMAND ${GIT_EXECUTABLE} push origin ${BRANCH_VERSION}
  COMMENT "Add remote branch ${BRANCH_VERSION}"
  WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
  DEPENDS ${BRANCH_DEP}
  )

if(NOT TARGET branch)
  add_custom_target(branch)
endif()
add_dependencies(branch branch_${PROJECT_NAME})

# remove branch
add_custom_target(cut_${PROJECT_NAME}
  COMMAND ${GIT_EXECUTABLE} branch -d ${BRANCH_VERSION}
  COMMAND ${GIT_EXECUTABLE} push origin --delete ${BRANCH_VERSION}
  COMMENT "Remove branch ${BRANCH_VERSION}"
  WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
  )

if(NOT TARGET cut)
  add_custom_target(cut)
endif()
add_dependencies(cut cut_${PROJECT_NAME})

# tag on branch
file(WRITE ${PROJECT_BINARY_DIR}/gitbranchandtag.cmake
  "# Branch:
   if(\"${GITTARGETS_RELEASE_BRANCH}\" STREQUAL current)
     set(TAG_BRANCH)
   else()
     execute_process(COMMAND ${GIT_EXECUTABLE} branch ${BRANCH_VERSION}
       RESULT_VARIABLE hadbranch ERROR_VARIABLE error
       WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
     if(NOT hadbranch)
       execute_process(COMMAND ${GIT_EXECUTABLE} push origin ${BRANCH_VERSION}
        WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
     endif()
     set(TAG_BRANCH ${BRANCH_VERSION})
   endif()

   # Create or move tag
   execute_process(
     COMMAND ${GIT_EXECUTABLE} tag -f ${VERSION} ${TAG_BRANCH}
     COMMAND ${GIT_EXECUTABLE} push --tags
     RESULT_VARIABLE notdone WORKING_DIRECTORY ${PROJECT_SOURCE_DIR})
   if(notdone)
     message(FATAL_ERROR
        \"Error creating tag ${VERSION} on branch ${TAG_BRANCH}\")
   endif()")

add_custom_target(tag_${PROJECT_NAME}
  COMMAND ${CMAKE_COMMAND} -P ${PROJECT_BINARY_DIR}/gitbranchandtag.cmake
  COMMENT "Add tag ${VERSION}"
  WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
  )

# remove tag
add_custom_target(erase_${PROJECT_NAME}
  COMMAND ${GIT_EXECUTABLE} tag -d ${VERSION}
  COMMAND ${GIT_EXECUTABLE} push origin :${VERSION}
  COMMENT "Remove tag ${VERSION}"
  WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
  )

if(NOT TARGET erase)
  add_custom_target(erase)
endif()
add_dependencies(erase erase_${PROJECT_NAME})

# move tag
add_custom_target(retag_${PROJECT_NAME}
  COMMAND ${CMAKE_COMMAND} -P ${PROJECT_BINARY_DIR}/gitbranchandtag.cmake
  COMMENT "Add tag ${VERSION}"
  WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
  DEPENDS erase_${PROJECT_NAME})

if(NOT TARGET retag)
  add_custom_target(retag)
endif()
add_dependencies(retag retag_${PROJECT_NAME})

# tarball
set(TARBALL "${PROJECT_BINARY_DIR}/${PROJECT_NAME}-${VERSION}.tar")

add_custom_target(tarball-create_${PROJECT_NAME}
  COMMAND ${GIT_EXECUTABLE} archive --worktree-attributes
    --prefix ${PROJECT_NAME}-${VERSION}/ -o ${TARBALL}
    ${VERSION}
  WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
  COMMENT "Creating ${TARBALL}"
  )

if(NOT TARGET tarball-create)
  add_custom_target(tarball-create)
endif()
add_dependencies(tarball-create tarball-create_${PROJECT_NAME})

if(GZIP_EXECUTABLE)
  add_custom_target(tarball_${PROJECT_NAME}
    COMMAND ${CMAKE_COMMAND} -E remove ${TARBALL}.gz
    COMMAND ${GZIP_EXECUTABLE} ${TARBALL}
    DEPENDS tarball-create_${PROJECT_NAME}
    WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
    COMMENT "Compressing ${TARBALL}.gz"
  )
  set(TARBALL_GZ "${TARBALL}.gz")
else()
  add_custom_target(tarball_${PROJECT_NAME} DEPENDS tarball-create_${PROJECT_NAME})
endif()

if(NOT TARGET tarball)
  add_custom_target(tarball)
endif()
add_dependencies(tarball tarball_${PROJECT_NAME})

set(_gittargets_TARGETS branch_${PROJECT_NAME} cut_${PROJECT_NAME} tag_${PROJECT_NAME} erase_${PROJECT_NAME} tarball_${PROJECT_NAME} tarball-create_${PROJECT_NAME})
foreach(_gittargets_TARGET ${_gittargets_TARGETS})
  set_target_properties(${_gittargets_TARGET} PROPERTIES EXCLUDE_FROM_ALL ON)
  set_target_properties(${_gittargets_TARGET} PROPERTIES FOLDER "git")
endforeach()
