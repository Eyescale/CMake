# - Try to Find libfastcgi
# Once done this will define
#  FCGI_FOUND
#  FCGI_INCLUDE_DIRS
#  FCGI_LIBRARIES

# Look for the header file.
find_path(FCGI_INCLUDE_DIR NAMES fastcgi.h fcgi.h fcgio.h)

# Look for the library.
find_library(FCGI_LIBRARY NAMES fcgi)
find_library(FCGIPP_LIBRARY NAMES fcgi++)

# Handle the QUIETLY and REQUIRED arguments and set FCGI_FOUND to TRUE if all listed variables are TRUE.
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(fcgi DEFAULT_MSG FCGI_INCLUDE_DIR FCGI_LIBRARY FCGIPP_LIBRARY)

# Copy the results to the output variables.
if(FCGI_FOUND)
  set(FCGI_LIBRARIES ${FCGI_LIBRARY} ${FCGIPP_LIBRARY})
  set(FCGI_INCLUDE_DIRS ${FCGI_INCLUDE_DIR})
endif()

mark_as_advanced(FCGI_INCLUDE_DIR FCGI_LIBRARY FCGIPP_LIBRARY)

