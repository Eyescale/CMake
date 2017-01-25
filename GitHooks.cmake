# Copyright (c) 2017, Juan Hernando <juan.hernando@epfl.ch>
#

if(NOT GIT_FOUND)
  find_package(Git QUIET)
endif()

if(NOT CLANG_FORMAT)
  find_program(CLANG_FORMAT clang-format)
endif()

# Installing clang-format precommit hook if prerequisites are met and it doesn't
# exist yet.
if(GIT_FOUND AND CLANG_FORMAT AND EXISTS ${PROJECT_SOURCE_DIR}/.git AND
   NOT EXISTS ${PROJECT_SOURCE_DIR}/.git/hooks/pre-commit)

   # We cannot write the file from here because we need exec permissions
   configure_file(${CMAKE_SOURCE_DIR}/CMake/common/util/git_pre-commit.in
                  ${PROJECT_SOURCE_DIR}/.git/hooks/pre-commit)
endif()



