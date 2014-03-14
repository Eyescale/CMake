# Configure a copy of the 'UseQt4.cmake' system file with the following properties:
# * Change all include_directories() to use the SYSTEM option

function(configure_use_qt4 target_file)
  if(NOT EXISTS ${QT_USE_FILE})
    message(WARNING "Can't find QT_USE_FILE, configuration aborted.")
    return()
  endif()

  file(READ ${QT_USE_FILE} content)

  # Inlcude as system libraries
  string(REPLACE "include_directories(" "include_directories(SYSTEM "
         content ${content})

  file(WRITE ${target_file} ${content})
endfunction()

