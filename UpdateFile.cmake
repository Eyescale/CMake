
# Copyright (c) 2012-2014 Stefan Eilemann <eile@eyescale.ch>

# Similar to configure_file, but overwrites target only if content differs.
# Deprecated since configure_file in fact does the same.

function(UPDATE_FILE IN OUT)
  message(WARNING "Update_file is deprecated, use configure_file(... @ONLY)")
  if(NOT EXISTS ${OUT})
    configure_file(${IN} ${OUT} @ONLY)
    return()
  endif()

  configure_file(${IN} ${OUT}.tmp @ONLY)
  file(READ ${OUT} _old_contents)
  file(READ ${OUT}.tmp _new_contents)
  if("${_old_contents}" STREQUAL "${_new_contents}")
    file(REMOVE ${OUT}.tmp)
  else()
    file(RENAME ${OUT}.tmp ${OUT})
  endif()
endfunction()
