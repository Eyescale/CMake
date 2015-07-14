# CMake Modules

This repository contains common CMake modules and a collection of find scripts
to locate non-CMake dependencies. To use it, create a .gitexternals file in your
project:

    # -*- mode: cmake -*-
    # CMake/common https://github.com/Eyescale/CMake.git master

Copy [GitExternal](GitExternal.cmake) from this repository to CMake/,
and use it in your top-level CMakeLists.txt as follows:

    list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMake
                                  ${CMAKE_SOURCE_DIR}/CMake/common)
    include(GitExternal)
    include(Common)

This will clone the latest version of this repository into your project at
the beginning of the CMake run, and make all its features available.

## Documentation

The following CMake modules can be included in your project:

* [Common](Common.cmake) does a common CMake setup, and also includes:
    * [CommonLibrary](CommonLibrary.cmake) *common_library* function to build a
      shared library using a standard recipe and generates header files for the
      library (api.h, version.h).
    * [CommonApplication](CommonApplication.cmake) *common_application*
      function to build an application using a standard recipe.
    * [CommonPackage](CommonPackage.cmake) *common_package* for more convenience
      over find_package and *common_package_post* (last after all common_package
      calls) to generate defines.h and options.cmake for feature checking.
    * [Compiler](Compiler.cmake): Default compiler flags applied via
      common_compiler_flags(), useful default warnings and 'safe' C++11
      features.
    * [GitInfo](GitInfo.cmake) sets variables with information about the git
      source tree.
    * [GitTargets](GitTargets.cmake) *branch*, *cut*, *tag*, *erase*, *retag*,
      *tarball* targets.
* [CommonCTest](CommonCTest.cmake) should be included from a tests subfolder.
      Does a common CTest setup, automatically adding all .cpp files in the
      current folder as unit tests to a *tests* target. It also includes:
    * [Coverage](Coverage.cmake) *coverage* target to generate a code coverage
      report as html, if ENABLE_COVERAGE option is also set. Additional compiler
      flags are set in that case, so it should be enabled only for debug builds.
    * [CppcheckTargets](CppcheckTargets.cmake): *cppcheck* target for
      static code analysis. Also adds all cppcheck targets to *tests* target.
    * [clangcheckTargets](clangcheckTargets.cmake): *clangcheck* target for
      clang-check code analysis. Adds all clangcheck targets to *tests* if
      ENABLE_CLANGCHECK_TESTS is set.
* [DoxygenRule](DoxygenRule.cmake): *doxygen* target to build documentation into
  PROJECT_BINARY_DIR/doc. Optional *doxycopy* target to copy the results to
  ../GITHUB_ORGANIZATION/Project-M.m/. Must be included after all other targets.
* [SubProject](SubProject.cmake): Include this module right after GitExternal in
  your top-level CMakeLists to build several CMake subprojects (which may depend
  on each other).
  To be compatible with the SubProject feature, (sub)projects might need to
  adapt their CMake scripts. Generally, CMAKE_BINARY_DIR should be changed to
  PROJECT_BINARY_DIR and CMAKE_SOURCE_DIR should be changed to
  PROJECT_SOURCE_DIR. See [SubProject](SubProject.cmake) documentation for
  more details.
  A simple example project can be found at
  https://github.com/Eyescale/Collage.git, and a complex one at
  https://github.com/BlueBrain/Livre.git.

Additional features:
* Users can use "cmake -DINSTALL_PACKAGES=1" during the initial configuration to
  install known system packages (Ubuntu and OS X only).
