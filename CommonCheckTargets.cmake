# Copyright (c) 2015 Daniel.Nachbaur@epfl.ch
#
# Provide the function common_check_targets to add check targets (clangcheck,
# cppcheck, cpplint) to the given target.

include(clangcheckTargets)
include(CppcheckTargets)
include(CpplintTargets)

function(common_check_targets _name)
  set(_exclude_pattern ".*moc_|.*qrc_.*\\.c.*$") # Qt moc and qrc files

  # Get the list of files once for all check targets
  get_target_property(_sources "${_name}" SOURCES)
  set(_files)
  foreach(_source ${_sources})
    get_source_file_property(_lang "${_source}" LANGUAGE)
    get_source_file_property(_loc "${_source}" LOCATION)
    if("${_lang}" MATCHES "CXX" AND NOT ${_loc} MATCHES ${_exclude_pattern})
      list(APPEND _files "${_loc}")
    endif()
  endforeach()

  if(NOT _files)
    return()
  endif()

  add_clangcheck(${_name} ${_files})
  add_cppcheck(${_name} ${_files} POSSIBLE_ERROR FAIL_ON_WARNINGS)
  add_cpplint(${_name} ${_files} CATEGORY_FILTER_OUT readability/streams)
endfunction()
