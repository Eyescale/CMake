# Copyright (c) 2015 Daniel.Nachbaur@epfl.ch
#
# Provide the function common_check_targets to add check targets (clangcheck,
# cppcheck, cpplint) to the given target.

include(GetSourceFilesFromTarget)
include(clangcheckTargets)
include(CppcheckTargets)
include(CpplintTargets)

function(common_check_targets _name)
  set(_exclude_pattern ".*moc_|.*qrc_.*\\.c.*$") # Qt moc and qrc files

  # Get the list of files once for all check targets
  get_source_files(${_name} ${_exclude_pattern})
  if(NOT ${_name}_FILES)
    return()
  endif()

  add_clangcheck(${_name} FILES ${${_name}_FILES})
  add_cppcheck(${_name} FILES ${${_name}_FILES} POSSIBLE_ERROR FAIL_ON_WARNINGS)
  add_cpplint(${_name} FILES ${${_name}_FILES} CATEGORY_FILTER_OUT readability/streams)
endfunction()
