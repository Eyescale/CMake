# CMake Modules

This repository contains common CMake modules. To use it, create a
.gitexternals in your project:

    # -*- mode: cmake -*-
    # CMake/common https://github.com/Eyescale/CMake.git master

Copy [GitExternal](GitExternal.cmake) from this repository to CMake/,
and use it in your top-level CMakeLists.txt:

    list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake
                                  ${PROJECT_SOURCE_DIR}/CMake/common)
    include(GitExternal)
    include(Common)

## Documentation

* [Common](Common.cmake) does a common CMake setup, including:
    * [CommonLibrary](CommonLibrary.cmake) *common_library* function to
      build a shared library using a standard recipe.
    * [CommonApplication](CommonApplication.cmake) *common_application*
      function to build an application using a standard recipe.
    * [CommonCode](CommonCode.cmake) generates standard header files for
      the project (api.h, defines.h, version.h).
    * **GNUModules**: *module* target to create a
      [GNUModules](GNUModules.cmake) *module* and *snapshot* targets to
      create [GNU modules](http://modules.sourceforge.net/).
    * [GitTargets](GitTargets.cmake) *branch*, *cut*, *tag*, *erase*,
      *retag*, *tarball* targets.
    * [Compiler](Compiler.cmake): Default compiler flags, useful default
      warnings and 'safe' C++11 features.
    * [GitInfo](GitInfo.cmake) sets variables with information about the
      git source tree.
* [CommonCTest](CommonCTest.cmake) does a common CTest setup, including
    * Automatically adding all .cpp files as tests
    * [Coverage](Coverage.cmake) Create code coverage report as html, if
      ENABLE_COVERAGE is set. Buildyard has 'make Coverage' target to
      enable this in a separate build, since coverage flags may break
      downstream projects.
    * [CppcheckTargets](CppcheckTargets.cmake): *cppcheck* target for
      static code analysis. Also adds all cppcheck targets to tests.
    * [clangcheckTargets](clangcheckTargets.cmake): *clangcheck* target for
      clang-check code analysis. Adds all cppcheck targets to tests if
      ENABLE_CLANGCHECK_TESTS is set.
* [DoxygenRule](DoxygenRule.cmake): *doxygen* target to build
  documentation into PROJECT_BINARY_DIR/doc. Optional *doxygit* target to
  copy result to ../GITHUB_ORGANIZATION/Project-M.m/. Must be included
  after all targets.
* [SubProject](SubProject.cmake): Using a top level simple CMake 
  superproject, several CMake subprojects (which may depend on each other) 
  can be build. Each subproject can be added to the superproject 
  with an add_subdirectory( *subproject* ) directive. To use the SubProject
  feature, the sub projects should modify their CMake scripts.
  In the scripts CMAKE_BINARY_DIR should be changed to PROJECT_BINARY_DIR 
  and CMAKE_SOURCE_DIR should be changed to PROJECT_SOURCE_DIR. A
  sample project can be found at https://github.com/bilgili/SubProjects.git

* Find scripts for non-CMake projects.
