
/* Copyright (c) 2014 Stefan.Eilemann@epfl.ch */

#ifndef @UPPER_PROJECT_NAME@_DEFINES_H
#define @UPPER_PROJECT_NAME@_DEFINES_H

#ifdef __APPLE__
#  include <@PROJECT_INCLUDE_NAME@/definesDarwin.h>
#endif
#ifdef __linux
#  include <@PROJECT_INCLUDE_NAME@/definesLinux.h>
#endif
#ifdef _WIN32 //_MSC_VER
#  include <@PROJECT_INCLUDE_NAME@/definesWin32.h>
#endif

#endif
