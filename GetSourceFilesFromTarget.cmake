# Copyright (c) 2015 Daniel.Nachbaur@epfl.ch
#
# Provide the function get_source_files() to get all (C++) source files from the
# given target and filtering them with a regex pattern. The returned list of
# files is stored in ${_target}_FILES.

function(get_source_files _target _exclude_pattern)
  get_target_property(_imported_target "${_name}" IMPORTED)
  if(_imported_target)
    return()
  endif()

  get_target_property(_sources "${_target}" SOURCES)
  set(${_target}_FILES)
  foreach(_source ${_sources})
    get_source_file_property(_lang "${_source}" LANGUAGE)
    get_source_file_property(_loc "${_source}" LOCATION)
    if("${_lang}" MATCHES "CXX" AND NOT ${_loc} MATCHES ${_exclude_pattern})
      list(APPEND ${_target}_FILES "${_loc}")
    endif()
  endforeach()
  set(${_target}_FILES ${${_target}_FILES} PARENT_SCOPE)
endfunction()
