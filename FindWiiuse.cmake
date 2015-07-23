# _____________________________________________________________________________
#
# WIIUSE 
# _____________________________________________________________________________

# PATH ________________________________________________________________________

if(NOT WIIUSE_PATH)
  find_path(WIIUSE_PATH include/wiiuse.h
            HINTS ${WIIUSE_ROOT} $ENV{WIIUSE_ROOT}
            /usr/local/
            /usr/)
endif()

# HEADERS _____________________________________________________________________

if(WIIUSE_PATH)
  set (WIIUSE_INCLUDE_DIR ${WIIUSE_PATH}/include)
  mark_as_advanced (WIIUSE_INCLUDE_DIR)
endif()

# STATIC LIBRARY ______________________________________________________________

if(WIIUSE_PATH)
  find_library(WIIUSE_LIBRARIES NAMES wiiuse
               HINTS ${WIIUSE_ROOT} $ENV{WIIUSE_ROOT}
               PATHS ${WIIUSE_PATH}/lib)
  mark_as_advanced(WIIUSE_LIBRARIES)
endif()

find_package_handle_standard_args(Wiiuse DEFAULT_MSG
                                  WIIUSE_LIBRARIES WIIUSE_INCLUDE_DIR)
