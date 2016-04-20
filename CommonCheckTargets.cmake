# Copyright (c) 2015 Daniel.Nachbaur@epfl.ch
#
# Provide the function common_check_targets to add check targets (clangcheck,
# cppcheck, cpplint) to the given target.

include(GetSourceFilesFromTarget)
include(CommonClangCheck)
include(CommonCPPCheck)
include(CommonCPPLint)

function(common_check_targets _name)
  # Qt moc & qrc files, C and Objective-C files
  set(_exclude_pattern ".*moc_|.*qrc_.*\\.c.*|.*\\.mm.*$")

  # Get the list of files once for all check targets
  get_source_files(${_name} ${_exclude_pattern})
  if(NOT ${_name}_FILES)
    return()
  endif()

  common_clangcheck(${_name} FILES ${${_name}_FILES})
  common_cppcheck(${_name} FILES ${${_name}_FILES}
    POSSIBLE_ERROR FAIL_ON_WARNINGS)
  common_cpplint(${_name} FILES ${${_name}_FILES} CATEGORY_FILTER_OUT readability/streams)
endfunction()
