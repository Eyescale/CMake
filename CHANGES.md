# git master

* [556](https://github.com/Eyescale/CMake/pull/556):
  Fix rare bug with project-install missing dependencies
* [555](https://github.com/Eyescale/CMake/pull/555):
  Add missing defines to version.h to ease usage w/o the need for linking

# 2017.05 (23-May-2017)

* [551](https://github.com/Eyescale/CMake/pull/551):
  Subproject changes:
    * Cloning of subprojects has been disabled by default. Users must explicitly
      set -DCLONE_SUBPROJECTS=ON to clone missing dependencies during the cmake
      run.
    * CMake/common can be integrated as a .gitmodule without getting an
      unnecessary copy in each subproject.
* [550](https://github.com/Eyescale/CMake/pull/550):
  CommonLibrary: NAME_OMIT_VERSION_HEADERS to disable api.h/version.h|cpp
* [549](https://github.com/Eyescale/CMake/pull/549):
  Remove Tuvok finder in favor of provided package config
* [545](https://github.com/Eyescale/CMake/pull/545):
  CommonCPack fixes: follow Debian package naming conventions, make ABI version
  in package name optional
* [545](https://github.com/Eyescale/CMake/pull/545):
  common_application(GUI): install application icon and launcher on Linux
* [544](https://github.com/Eyescale/CMake/pull/544):
  FindLibJpegTurbo.cmake parses jconfig.h for version check
* [540](https://github.com/Eyescale/CMake/pull/540):
  Add CommonSmokeTest.cmake to check execution of installed applications
* [539](https://github.com/Eyescale/CMake/pull/539):
  Add Findrados.cmake
* [538](https://github.com/Eyescale/CMake/pull/538):
  Allow integration of subprojects outside of COMMON_SOURCE_DIR
* [537](https://github.com/Eyescale/CMake/pull/537):
  Automatically add a pre-commit hook to git repos for running clang-format
* [535](https://github.com/Eyescale/CMake/pull/535):
  New common_help() to generate help page for doxygen
* [534](https://github.com/Eyescale/CMake/pull/534):
  Remove unneeded zmq finder
* [533](https://github.com/Eyescale/CMake/pull/533):
  Add application-help-to-doxygen extraction
* [532](https://github.com/Eyescale/CMake/pull/532):
  Only update SHA-1s in .gitsubprojects after ```update``` instead of rewriting
  the whole file
* [532](https://github.com/Eyescale/CMake/pull/532):
  Fix missing ```git submodule update``` after ```rebase```
* [531](https://github.com/Eyescale/CMake/pull/531):
  Revert parallel clone due to failure of clones in CI
* [530](https://github.com/Eyescale/CMake/pull/530):
  Fix return value of Version::getRevision to 64 bit for longer git SHAs
* [529](https://github.com/Eyescale/CMake/pull/529):
  Fix python3 finding on OSX with -DUSE_PYTHON_VERSION=3

# 2016.12 (09-Dec-2016)

* [529](https://github.com/Eyescale/CMake/pull/529):
  Fix python3 finding on OSX with -DUSE_PYTHON_VERSION=3
* [527](https://github.com/Eyescale/CMake/pull/527):
  Refactor INSTALL_PACKAGES out of SubProject.cmake, also fixing a bug that
  the dependencies of a project were not installed if it did not have a
  .gitsubprojects file.
* [526](https://github.com/Eyescale/CMake/pull/526):
  Provide getSchema() and toJSON() for generated version.h
* [517](https://github.com/Eyescale/CMake/pull/517):
  Clone sub projects in parallel. This feature can be optionally disabled with
  COMMON_SUBPROJECT_PARALLEL_CLONE set to OFF.
* [516](https://github.com/Eyescale/CMake/pull/516):
  Support for GCC 6
* [515](https://github.com/Eyescale/CMake/pull/515):
  Tweaked configure output to only list not found dependencies; show all with
  COMMON_FIND_PACKAGE_QUIET set to OFF
* [512](https://github.com/Eyescale/CMake/pull/512):
  Add COMMON_DISABLE_WERROR option
* [510](https://github.com/Eyescale/CMake/pull/510):
  Also create project-all target for super project
* [507](https://github.com/Eyescale/CMake/pull/507):
  Handle required version in FindNumPy.cmake
* [506](https://github.com/Eyescale/CMake/pull/506):
  Added CommonPythonTest.cmake to ease adding Python tests to project under
  CTest.
* [505](https://github.com/Eyescale/CMake/pull/505):
  Added CommonCUDA.cmake with some common configuration checks for CUDA.
* [504](https://github.com/Eyescale/CMake/pull/504):
    * Add support for yum to subproject_install_packages
    * Make sure that package installation is only attempted if INSTALL_PACKAGES
      is in the command line (i.e. do not cache the variable).
* [503](https://github.com/Eyescale/CMake/pull/503):
  Added optional MODULE argument to common_find_package() as a hint for
  pkg_config. Example usage: common_find_package(RSVG MODULE librsvg-2.0)
* [500](https://github.com/Eyescale/CMake/pull/500):
  Added WIN32 option to CommonApplication to be able to build WinMain-based
  apps (no console).

# 2016.06 (30-Jun-2016)

* [497](https://github.com/Eyescale/CMake/pull/497):
  Fix install directory of common_application data
* [494](https://github.com/Eyescale/CMake/pull/494):
  Fix include paths in project header file for generated files within the binary
  dir
* [493](https://github.com/Eyescale/CMake/pull/493):
  Do not mess with LCOV_EXCLUDE which is set by outside users
* [486](https://github.com/Eyescale/CMake/pull/486):
  Fix coverage report generation for the top-level project
* [478](https://github.com/Eyescale/CMake/pull/478):
  CMake3 port and various cleanups
    * CMake 3.1 is now required
    * Renames of files
        * CommonPackage.cmake -> CommonFindPackage.cmake
        * Compiler.cmake -> CommonCompiler.cmake
        * Coverage.cmake -> CommonCoverage.cmake
    * Renames of variables and options
        * CMAKE_COMPILER_IS_GNUCXX -> CMAKE_COMPILER_IS_GCC
        * COMMON_PACKAGE_DEFINES -> COMMON_FIND_PACKAGE_DEFINES
        * COMMON_PACKAGE_USE_QUIET -> COMMON_FIND_PACKAGE_QUIET
        * DOC_DIR -> COMMON_DOC_DIR
        * ENABLE_CLANGCHECK_TESTS -> COMMON_ENABLE_CLANGCHECK_TESTS
        * ENABLE_COVERAGE -> COMMON_ENABLE_COVERAGE
        * ENABLE_CXX11_STDLIB -> COMMON_ENABLE_CXX11_STDLIB
        * ENABLE_WARN_DEPRECATED -> COMMON_WARN_DEPRECATED
        * GIT_EXTERNAL_VERBOSE -> COMMON_GIT_EXTERNAL_VERBOSE
        * VERSION_ABI -> ${PROJECT_NAME}_VERSION_ABI
        * VERSION -> ${PROJECT_NAME}_VERSION
    * Renames of functions
        * common_compiler_flags() -> common_compiler_options(${target})
        * common_package() -> common_find_package()
        * common_package_post() -> common_find_package_post()
    * VERSION_MAJOR, VERSION_MINOR, VERSION_PATCH are now part of project()
    * OUTPUT_INCLUDE_DIR removed; use ${PROJECT_BINARY_DIR}/include instead
    * Per-target include directories and definitions instead of global pollution
    * Qt support is now implicit thanks to AUTOMOC, AUTORCC and AUTOUIC feature:
      NAME_MOC_HEADERS, NAME_UI_FORMS and NAME_RESOURCES are not supported
      anymore; use NAME_PUBLIC_HEADERS, NAME_HEADERS and NAME_SOURCES
      accordingly
* [477](https://github.com/Eyescale/CMake/pull/477):
  Rename functions to common_cppcheck, common_clangcheck and
  common_cpplint to solve a name clash with ITK
* [474](https://github.com/Eyescale/CMake/pull/474):
  common_library() : add an option to omit install (useful for test libs)
* [472](https://github.com/Eyescale/CMake/pull/472):
  Remove common_gui_application, add GUI and EXAMPLE arguments to
  common_application

# 2016.04 (08-Apr-2016)

* Add COMMON_OSX_TARGET_VERSION - OS X target version
* Add OPTIONAL argument to git_external. This gives users the possibility of
  cloning a repository without aborting the configuration if the operation fails
* Coverage.cmake fixes:
    * Fix missing coverage report for multiple project directories
    * Rename targets to match PROJECT_NAME-target syntax
    * Exclude only generated files from COMMON_GENERATED_FILES property,
      not everything from PROJECT_BINARY_DIR
* Added new test targets called nightlytests and Project-nightlytests. This
  targets depend on perf tests, and cpp test files with the prefix "nightly".
* Add c++11 noexcept test (CXX_NOEXCEPT_SUPPORTED define)
* Add Findhttpxx.cmake
* Add Sanitizer.cmake for gcc and clang runtime sanitizer support
* Add CoverageGcovr.cmake for gcovr support
* FindGLEW_MX considers GLEW_ROOT as environment and CMake variable
* Fix install in common_library() with subfolders
* Ignore moc and qrc files in coverage report
* Make CPACK_RESOURCE_FILE_LICENSE configurable
* New CompilerIdentification.cmake, resulted from splitting Compiler.cmake
* Remove Findzeromqcpp.cmake, use Findlibzmq.cmake instead
* Remove obsolete GIT_TARGETS_RELEASE_BRANCH
* Remove -DBOOST_TEST_DYN_LINK from all translation units

# 2015.11

* cmake 2.8.9 or later is now required; reduced cmake 3 warnings
* cmake 3 is required for finding a project with find_package() from
  outside the build tree/from the install tree.
* Optimized cmake run speed significantly
* New PROJECT_NAME-graph target generating a .png dependency graph if graphviz
  is found
* New explicit rebase target to update sub projects and externals to
  configured revision
* FindPackages.cmake should no longer be used; use common_package() for each
  dependency and common_package_post() at last (will write defines.h, hence
  after the last call to common_package)
* New variable COMMON_SOURCE_DIR to define the place for all sub
  projects and externals, defaults to CMAKE_SOURCE_DIR
* Sub projects do not FATAL_ERROR on missing required dependencies, are
  deactivated instead
* GitExternal.cmake:
    * 'user' remote for cloned github repositories (added if GITHUB_USER) is
      used default for 'git push'
    * Added SHALLOW and VERBOSE options
    * new targets *DIR-rebase* and *rebase* to update git externals and sub
      projects
* CommonPackageConfig.cmake replaces PackageConfig.cmake. It uses the
  export(EXPORT) feature from CMake 3 to generate ${PROJECT_NAME}Targets.cmake
  file which provides IMPORTED targets. Client projects should use those targets
  in target_link_libraries() (or NAME_LINK_LIBRARIES if common_library) rather
  than ${PROJECT_NAME}_LIBRARIES.
* New variable NAME_OMIT_EXPORT for common_library() excludes a target from the
  list of exported targets. This replaces the project-wide
  ${PROJECT_NAME}_EXCLUDE_LIBRARIES variable.
* Exported targets provided by CommonPackageConfig.cmake are now generated by
  common_application() and common_library(); generic target hook for
  add_executable() and add_library() does not exist anymore.
* common_check_targets() now adds cppcheck, cpplint and clangcheck targets
  to targets added by common_application() and common_library() instead of
  adding them via add_executable() and add_library().
* Removed legacy RELEASE_VERSION magic
* common_compiler_flags() macro replaces globally set CMAKE_C[XX]_FLAGS; is
  automatically applied when using common_application, common_library and
  CommonCTest
* api.h & version.h/cpp are now generated by common_library, not anymore
  globally per project (COMMON_INCLUDES and COMMON_SOURCES are not needed/used
  anymore)
* Added AppleCheckOpenGL.cmake to check for conflicting OpenGL link
  libraries on OS X
* Added CommonDate.cmake to provide today's date

# 2015.06

* New SubProject module based on GitExternal
* Subprojects share a single copy of CMake/common
* Buildyard bootstrapping mechanism deprecated and removed
* Using "cmake -DINSTALL_PACKAGES=1" installs system packages required by a
  project (Debian/Ubuntu + OSX)
* Added Qt5 support in common_library() and common_application()
* New common_gui_application() for configuring GUI applications (OSX app bundle)
* New common_documentation() for documentation repositories. Deprecated
  generation of index.html by CMake in favor of Jekyll for github projects
* Fixed *doxygen* and *coverage* targets for subprojects, enforce LCOV >= 1.11
* Fixed *cppcheck* and *cpplint* targets for subprojects
* New common_package() macro to find a dependency consistently
* PackageConfig searches for ABI-matching upstream dependencies.
  If VERSION_ABI is not available, fallback to matching VERSION MAJOR+MINOR
* Support for detecting both Python2 and Python3 versions
* Removed LAST_RELEASE variable from projects and use VERSION instead
* Separate unit tests from performance tests
* Arch Linux added to the list of supported platforms
* Multiple fixes for CMake3
* More quiet runs
* Merged and retired CMakeBBP fork
* Removed obsolete components:
    * GNUModules
    * WriteModuleFile
    * BuildLibrary
    * FindDisplayCluster
    * FindFlatBuffers
    * FindTuio
* Windows-specific improvements:
    * Targets are properly organized into folders in VisualStudio IDE
    * Unwanted targets removed from VisualStudio "All Build" target
    * Many fixes for Boost detection
* Mac-specific improvements:
    * common_gui_application() installs a relocatable app bundle packaged into
      a .dmg (if macdeployqt is available)
    * Use C++11 std and stdlib on OSX >= 10.9, C++03 on <= 10.8

# 2014.6

* Flatten git externals in release branches
    Needed for some build services which do not allow to pull in git
    externals at runtime.
* Decouple RELEASE_VERSION from VERSION_ABI. The first is detected
    automatically when build from a release branch or non-git source
    folder. The latter now has to be set explicitely in the top-level
    CMakeLists.
* Add COMMON_USE_CXX03 to disable c++11 features for incompatible
    projects.
* Unify active ubuntu codenames in Ubuntu.cmake
* Denoised output of find_package() generated by PackageConfig
* Match lcov colors to BBP quality metrics
