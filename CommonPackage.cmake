# Copyright (c) 2014 Stefan.Eilemann@epfl.ch

# Provides common_package(Name args) which improves find_package
# First invokes find_package with all the given arguments, and then falls back
# to using pkg_config if available. The pkg_config path does only implement
# the REQUIRED and VERSION find_package arguments (e.g. no COMPONENTS)

find_package(PkgConfig)
set(ENV{PKG_CONFIG_PATH}
  "${CMAKE_INSTALL_PREFIX}/lib/pkgconfig:$ENV{PKG_CONFIG_PATH}")

macro(COMMON_PACKAGE Name)
  string(TOUPPER ${Name} COMMON_PACKAGE_NAME)

  list(FIND ARGN "VERSION" COMMON_PACKAGE_VERSION_POS)
  if(COMMON_PACKAGE_VERSION_POS EQUAL -1) # No version specified
    set(COMMON_PACKAGE_VERSION)
  else()
    math(EXPR COMMON_PACKAGE_VERSION_POS "${COMMON_PACKAGE_VERSION_POS} + 1")
    list(GET ARGN ${COMMON_PACKAGE_VERSION_POS} COMMON_PACKAGE_VERSION)
    set(COMMON_PACKAGE_VERSION ">=${COMMON_PACKAGE_VERSION}")
  endif()

  list(FIND ARGN "REQUIRED" COMMON_PACKAGE_REQUIRED_POS)
  if(COMMON_PACKAGE_REQUIRED_POS EQUAL -1) # Optional find
    find_package(${Name} ${ARGN}) # try standard cmake way
    if((NOT ${Name}_FOUND) AND (NOT ${COMMON_PACKAGE_NAME}_FOUND) AND PKG_CONFIG_EXECUTABLE)
      pkg_check_modules(${Name} ${Name}
        ${COMMON_PACKAGE_VERSION}) # try pkg_config way
    endif()
  else() # required find
    list(REMOVE_AT ARGN ${COMMON_PACKAGE_REQUIRED_POS})
    find_package(${Name} ${ARGN}) # try standard cmake way
    if((NOT ${Name}_FOUND) AND (NOT ${COMMON_PACKAGE_NAME}_FOUND) AND PKG_CONFIG_EXECUTABLE)
      pkg_check_modules(${Name} REQUIRED ${Name}
        ${COMMON_PACKAGE_VERSION}) # try pkg_config way (and fail if needed)
    endif()
  endif()
endmacro()
