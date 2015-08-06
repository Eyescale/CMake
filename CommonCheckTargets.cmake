# Copyright (c) 2015 Daniel.Nachbaur@epfl.ch
#
# Provide the function common_check_targets to add check targets (clangcheck,
# cppcheck, cpplint) to the given target.

include(clangcheckTargets)
include(CppcheckTargets)
include(CpplintTargets)

function(common_check_targets _name)
  set(_exclude_pattern ".*moc_|.*qrc_.*\\.c.*$") # Qt moc and qrc files
  add_clangcheck(${_name} EXCLUDE_PATTERN ${_exclude_pattern})
  add_cppcheck(${_name} POSSIBLE_ERROR FAIL_ON_WARNINGS
    EXCLUDE_PATTERN ${_exclude_pattern})
  add_cpplint(${_name} CATEGORY_FILTER_OUT readability/streams
    EXCLUDE_PATTERN ${_exclude_pattern})
endfunction()
