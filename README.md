# CMake Modules

This repository contains common CMake modules and a collection of find scripts
to locate non-CMake dependencies. The recommended way to use it is:

## As a git submodule

In your project source dir, do:

    git submodule add https://github.com/Eyescale/CMake CMake/common

And include it in the top-level CMakeLists.txt as follows:

    list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake/common)
    include(Common)

## Documentation

The following CMake modules can be included in your project:

* [Common](Common.cmake) does a common CMake setup, and also includes:
    * [CommonLibrary](CommonLibrary.cmake) *common_library* function to build a
      (shared) library using a standard recipe and generates header files for
      the library (api.h, version.h).
    * [CommonApplication](CommonApplication.cmake) *common_application*
      function to build an application using a standard recipe.
    * [CommonFindPackage](CommonFindPackage.cmake) *common_find_package* for
      more convenience over find_package and *common_find_package_post* (must be
      last after all common_find_package calls) to generate defines.h and
      options.cmake for feature checking.
    * [CommonCompiler](CommonCompiler.cmake): Default compiler flags and useful
      default warnings can be set on given target to common_compile_options();
      automatically applied for targets created with common_application() and
      common_library()
    * [CommonHelp](CommonHelp.cmake) *common_help* function to create a
      documentation page from an application's --help output.
    * [GitInfo](GitInfo.cmake) sets variables with information about the git
      source tree.
    * [GitTargets](GitTargets.cmake) *branch*, *cut*, *tag*, *erase*, *retag*,
      *tarball* targets.
* [CommonCTest](CommonCTest.cmake) should be included from a tests subfolder.
      Does a common CTest setup, automatically adding all .cpp files in the
      current folder as unit tests to a *tests* target. It also includes:
    * [CommonCoverage](CommonCoverage.cmake) *coverage* target to generate a
      code coverage report as html, if COMMON_ENABLE_COVERAGE option is set.
      Additional compiler flags are set in that case, so it should be enabled
      only for debug builds.
    * [CommonCPPCheck](CommonCPPCheck.cmake): *cppcheck* target for
      static code analysis. Also adds all cppcheck targets to *tests* target.
    * [CommonClangCheck](CommonClangCheck.cmake): *clangcheck* target for
      clang-check code analysis. Adds all clangcheck targets to *tests* if
      COMMON_ENABLE_CLANGCHECK_TESTS is set.
* [CommonPackageConfig](CommonPackageConfig.cmake) generates cmake package
  information files for the project. These files let other CMake-based projects
  locate it through find_package (in config mode, without the need for a finder
  script). Must be included at the end of the CMakeLists.txt, after all targets
  have been added via common_library() and common_application().
* [CommonCPack](CommonCPack.cmake) Configures the CPack package generator to
  redistribute the project as an installable package. Also includes
  CommonPackageConfig.
* [DoxygenRule](DoxygenRule.cmake): *doxygen* target to build documentation into
  PROJECT_BINARY_DIR/doc. Optional *doxycopy* target to copy the results to
  ../GITHUB_ORGANIZATION/Project-M.m/. Must be included after all other targets.
* [SubProject](SubProject.cmake): This module is automatically included in
  Common.cmake to build several CMake subprojects (which may depend on each
  other), which are declared in a .gitsubprojects file.
  To be compatible with the SubProject feature, (sub)projects might need to
  adapt their CMake scripts. Generally, CMAKE_BINARY_DIR should be changed to
  PROJECT_BINARY_DIR and CMAKE_SOURCE_DIR should be changed to
  PROJECT_SOURCE_DIR. See [SubProject](SubProject.cmake) documentation for
  more details.
  A simple example project can be found at
  https://github.com/Eyescale/Collage.git, and a complex one at
  https://github.com/BlueBrain/Livre.git.

Additional features:
* [InstallDependencies](InstallDependencies.cmake) lets users install known
  system packages during the initial configuration by doing
  "cmake -DINSTALL_PACKAGES=1".
  This is only implemented for Linux distributions using apt-get and yum
  package managers and MacPorts in OS X. The actual support depends on the
  project declaring its dependencies for each particular case.
* [CommonGraph](CommonGraph.cmake) adds *graphs* target to generate .png tree
  view of dependencies, gathered by CommonFindPackage and SubProject.

[Detailed Change Log](CHANGES.md)
