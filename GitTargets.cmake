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
# * tarball: Create an archive of LAST_RELEASE

if(GITTARGETS_FOUND)
  return()
endif()
set(GITTARGETS_FOUND 1)

find_package(Git)
if(NOT GIT_EXECUTABLE)
  return()
endif()

if(NOT GITTARGETS_RELEASE_BRANCH)
  set(GITTARGETS_RELEASE_BRANCH "even_minor")
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

add_custom_target(make-branch
  COMMAND ${GIT_EXECUTABLE} checkout -b ${BRANCH_VERSION}
  COMMENT "Create local branch ${BRANCH_VERSION}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  )

if(TARGET flatten_git_external)
  set(BRANCH_DEP flatten_git_external)
else()
  set(BRANCH_DEP make-branch)
endif()

add_custom_target(branch
  COMMAND ${GIT_EXECUTABLE} push origin ${BRANCH_VERSION}
  COMMENT "Add remote branch ${BRANCH_VERSION}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  DEPENDS ${BRANCH_DEP}
  )

# remove branch
add_custom_target(cut
  COMMAND ${GIT_EXECUTABLE} branch -d ${BRANCH_VERSION}
  COMMAND ${GIT_EXECUTABLE} push origin --delete ${BRANCH_VERSION}
  COMMENT "Remove branch ${BRANCH_VERSION}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  )

# tag on branch
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/gitbranchandtag.cmake
  "# Branch:
   if(\"${GITTARGETS_RELEASE_BRANCH}\" STREQUAL current)
     set(TAG_BRANCH)
   else()
     execute_process(COMMAND ${GIT_EXECUTABLE} branch ${BRANCH_VERSION}
       RESULT_VARIABLE hadbranch ERROR_VARIABLE error
       WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
     if(NOT hadbranch)
       execute_process(COMMAND ${GIT_EXECUTABLE} push origin ${BRANCH_VERSION}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
     endif()
     set(TAG_BRANCH ${BRANCH_VERSION})
   endif()

   # Create or move tag
   execute_process(
     COMMAND ${GIT_EXECUTABLE} tag -f ${VERSION} ${TAG_BRANCH}
     COMMAND ${GIT_EXECUTABLE} push --tags
     RESULT_VARIABLE notdone WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
   if(notdone)
     message(FATAL_ERROR
        \"Error creating tag ${VERSION} on branch ${TAG_BRANCH}\")
   endif()")

add_custom_target(tag
  COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/gitbranchandtag.cmake
  COMMENT "Add tag ${VERSION}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  )

# remove tag
add_custom_target(erase
  COMMAND ${GIT_EXECUTABLE} tag -d ${VERSION}
  COMMAND ${GIT_EXECUTABLE} push origin :${VERSION}
  COMMENT "Remove tag ${VERSION}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  )

# move tag
add_custom_target(retag
  COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/gitbranchandtag.cmake
  COMMENT "Add tag ${VERSION}"
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  DEPENDS erase)

# tarball
set(TARBALL "${CMAKE_BINARY_DIR}/${CMAKE_PROJECT_NAME}-${LAST_RELEASE}.tar")

add_custom_target(tarball-create
  COMMAND ${GIT_EXECUTABLE} archive --worktree-attributes
    --prefix ${CMAKE_PROJECT_NAME}-${LAST_RELEASE}/ -o ${TARBALL}
    ${LAST_RELEASE}
  WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
  COMMENT "Creating ${TARBALL}"
  )

if(GZIP_EXECUTABLE)
  add_custom_target(tarball
    COMMAND ${CMAKE_COMMAND} -E remove ${TARBALL}.gz
    COMMAND ${GZIP_EXECUTABLE} ${TARBALL}
    DEPENDS tarball-create
    WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
    COMMENT "Compressing ${TARBALL}.gz"
  )
  set(TARBALL_GZ "${TARBALL}.gz")
else()
  add_custom_target(tarball DEPENDS tarball-create)
endif()

set(_gittargets_TARGETS branch cut tag erase tarball tarball-create)
foreach(_gittargets_TARGET ${_gittargets_TARGETS})
  set_target_properties(${_gittargets_TARGET} PROPERTIES EXCLUDE_FROM_ALL ON)
  set_target_properties(${_gittargets_TARGET} PROPERTIES FOLDER "git")
endforeach()
