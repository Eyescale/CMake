# CMake Modules

This repository contains common CMake modules. To use it, create a
.gitexternals in your project:

    # -*- mode: cmake -*-
    include(GitExternal)
    git_external("${CMAKE_CURRENT_LIST_DIR}/CMake/common"
      "https://github.com/Eyescale/CMake.git" "fca9d25")

Copy GitExternals.cmake from this repository to CMake/, and use it in
your top-level CMakeLists.txt:

    list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake
      ${CMAKE_SOURCE_DIR}/CMake/common)
    include(.gitexternals)
    include(Common)

To update, simply change the SHA hash in .gitexternals.

## Documentation

* **Common** does a common CMake setup, including:
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
