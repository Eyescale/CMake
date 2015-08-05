# Copyright (c) 2015 Daniel.Nachbaur@epfl.ch
#
# Provide the function common_check_targets to add check targets (clangcheck,
# cppcheck, cpplint) to the given target.

include(clangcheckTargets)
include(CppcheckTargets)
include(CpplintTargets)

function(common_check_targets _name)
  add_clangcheck(${_name})
  add_cppcheck(${_name} POSSIBLE_ERROR FAIL_ON_WARNINGS
    EXCLUDE_QT_MOC_FILES)
  add_cpplint(${_name} CATEGORY_FILTER_OUT readability/streams
    EXCLUDE_PATTERN ".*moc_.*\\.cxx|Buildyard/Build")
endfunction()
