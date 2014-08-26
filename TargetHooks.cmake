# hooks to gather targets in global properties ${PROJECT_NAME}_ALL_DEP_TARGETS and
# ${PROJECT_NAME}_ALL_LIB_TARGETS for future processing
# We add ${PROJECT_NAME}_ to the start of the global property so that when
# multiple subprojects are built in a single go, the properties are unique per project

include(CMakeParseArguments)
include(clangcheckTargets)
include(CppcheckTargets)
include(CpplintTargets)

set(ALL_DEP_TARGETS "")
set(ALL_LIB_TARGETS "")
set(CPPCHECK_EXTRA_ARGS --suppress=unusedFunction --suppress=missingInclude
  -I${OUTPUT_INCLUDE_DIR} -D${UPPER_PROJECT_NAME}_STATIC=)

# only ever define this macro once, just in case sub-projects include the same rules
get_property(ADD_EXE_DEFINED GLOBAL PROPERTY ADD_EXE_MACRO_DEFINED)
if(NOT ADD_EXE_DEFINED)
  set_property(GLOBAL PROPERTY ADD_EXE_MACRO_DEFINED "1")
  macro(add_executable _target)
    _add_executable(${_target} ${ARGN})
    add_clangcheck(${_target})
    add_cppcheck(${_target} POSSIBLE_ERROR FAIL_ON_WARNINGS EXCLUDE_QT_MOC_FILES)
    add_cpplint(${_target} CATEGORY_FILTER_OUT readability/streams
      EXCLUDE_PATTERN ".*moc_.*\\.cxx|Buildyard/Build")
    set_property(GLOBAL APPEND PROPERTY ${PROJECT_NAME}_ALL_DEP_TARGETS ${_target})
  endmacro()
endif()

# only ever define this macro once, just in case sub-projects include the same rules
get_property(ADD_LIBRARY_DEFINED GLOBAL PROPERTY ADD_LIBRARY_MACRO_DEFINED)
if(NOT ADD_LIBRARY_DEFINED)
  set_property(GLOBAL PROPERTY ADD_LIBRARY_MACRO_DEFINED "1")
  macro(add_library _target)
    _add_library(${_target} ${ARGN})
    add_clangcheck(${_target})
    add_cppcheck(${_target} POSSIBLE_ERROR FAIL_ON_WARNINGS EXCLUDE_QT_MOC_FILES)
    add_cpplint(${_target} CATEGORY_FILTER_OUT readability/streams
      EXCLUDE_PATTERN ".*moc_.*\\.cxx|Buildyard/Build")

    # ignore IMPORTED add_library from finders (e.g. Qt)
    cmake_parse_arguments(_arg "IMPORTED" "" "" ${ARGN})

    # ignore user-specified targets, e.g. language bindings
    list(FIND IGNORE_LIB_TARGETS ${_target} _ignore_target)

    if(NOT _arg_IMPORTED AND _ignore_target EQUAL -1)
      # add defines TARGET_DSO_NAME and TARGET_SHARED for dlopen() usage
      get_target_property(THIS_DEFINITIONS ${_target} COMPILE_DEFINITIONS)
      if(NOT THIS_DEFINITIONS)
        set(THIS_DEFINITIONS) # clear THIS_DEFINITIONS-NOTFOUND
      endif()
      string(TOUPPER ${_target} _TARGET)

      if(MSVC OR XCODE_VERSION)
        set(_libraryname ${CMAKE_SHARED_LIBRARY_PREFIX}${_target}${CMAKE_SHARED_LIBRARY_SUFFIX})
      else()
        if(APPLE)
          set(_libraryname ${CMAKE_SHARED_LIBRARY_PREFIX}${_target}.${VERSION_ABI}${CMAKE_SHARED_LIBRARY_SUFFIX})
        else()
          set(_libraryname ${CMAKE_SHARED_LIBRARY_PREFIX}${_target}${CMAKE_SHARED_LIBRARY_SUFFIX}.${VERSION_ABI})
        endif()
      endif()

      list(APPEND THIS_DEFINITIONS
        ${_TARGET}_SHARED ${_TARGET}_DSO_NAME=\"${_libraryname}\")

      set_target_properties(${_target} PROPERTIES
        COMPILE_DEFINITIONS "${THIS_DEFINITIONS}")

      set_property(GLOBAL APPEND PROPERTY ${PROJECT_NAME}_ALL_DEP_TARGETS ${_target})
      set_property(GLOBAL APPEND PROPERTY ${PROJECT_NAME}_ALL_LIB_TARGETS ${_target})

    endif()
  endmacro()
endif()
