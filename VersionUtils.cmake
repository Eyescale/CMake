# Copyright (c) 2013 Ahmet Bilgili <ahmet.bilgili@epfl.ch>

# This file includes function(s) to do version operations.

# Gets list of versions ( "1.9;1.8;1.6;1.4;1.10" ) and sorts them 
# in ascending order ( "1.4;1.6;1.8;1.9;1.10" ).
function(_version_sort versions sorted_versions)
  set(max_version "9999999.0")
  set(current_smallest ${max_version})
  list(LENGTH versions version_count)
  math(EXPR version_count "${version_count} - 1")
  foreach(i RANGE 0 ${version_count})
    list(LENGTH versions sub_version_count)
    math(EXPR sub_version_count "${sub_version_count} - 1")
    if(${sub_version_count} GREATER 0)
      set(smallest_index -1)
      foreach(j RANGE ${sub_version_count} )
        list(GET versions ${j} version)
        if(${version} VERSION_LESS ${current_smallest})
          set(current_smallest ${version})
          set(smallest_index ${j})
        endif()
    endforeach(j)
    list(APPEND sorted_versions ${current_smallest})
    list(REMOVE_AT versions ${smallest_index})
    set(current_smallest ${max_version})
    endif()
  endforeach(i)
  list(APPEND sorted_versions ${versions})
  set(${sorted_versions} PARENT_SCOPE)
endfunction(_version_sort)
