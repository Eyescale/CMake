# CMake Modules

This repository contains common CMake modules. To use it, create a
.gitexternals in your project:

    # -*- mode: cmake -*-
    # CMake/common https://github.com/Eyescale/CMake.git 1778185

Copy GitExternals.cmake from this repository to CMake/, and use it in
your top-level CMakeLists.txt:

    list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake
      ${CMAKE_SOURCE_DIR}/CMake/common)
    include(GitExternals)
    include(Common)

Run 'make update' to change the SHA hash in .gitexternals to the newest
origin/master version.

## Documentation

* [Common](Common.cmake) does a common CMake setup, including:
    * [BuildLibrary](BuildLibrary.cmake) provides a build_library
      function to build a shared library using a standard recipe.
    * **DoxygenRule**: *doxygen* target to build documentation into
      CMAKE_BINARY_DIR/doc. Optional *github* target to copy result to
      ../GITHUB_ORGANIZATION/Project-M.m/.
    * **GNUModules**: *module* target to create a
      [GNU module](http://modules.sourceforge.net/). See file for details.
    * [GitTargets documentation](doc/GitTargets.md)
    * **UpdateFile**: *update_file* CMake function which uses configure_file
      but leaves target untouched if unchanged. Uses @ONLY.
    * **CppcheckTargets**: *cppcheck* target for static code analysis. Also
      adds all cppcheck targets to tests.
    * **Compiler**: Compiler flags, useful default warnings and 'safe'
      C++11 features.
* [CommonCTest](CommonCTest.cmake) does a common CTest setup, including
    * Automatically adding all .cpp files as tests
    * **Coverage**: Create code coverage report as html, if
      ENABLE_COVERAGE is set. Buildyard has 'make Coverage' target to
      enable this in a separate build, since coverage flags may break
      downstream projects.
    * **CppcheckTargets**: Hook library and executable sources into
        cppcheck target and add them as unit tests.
* [DoxygenRule](DoxygenRule.cmake) provides the doxygen and doxygit
  targets. Must be included after all targets.
