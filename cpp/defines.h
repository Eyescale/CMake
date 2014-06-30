
/* Copyright (c) 2014 Stefan.Eilemann@epfl.ch */

#ifndef @UPPER_PROJECT_NAME@_DEFINES_H
#define @UPPER_PROJECT_NAME@_DEFINES_H

#ifdef __APPLE__
#  include <@PROJECT_INCLUDE_NAME@/definesDarwin.h>
#elif defined (__linux__)
#  include <@PROJECT_INCLUDE_NAME@/definesLinux.h>
#elif defined (_WIN32)
#  include <@PROJECT_INCLUDE_NAME@/definesWin32.h>
#else
#  error Unknown OS
#endif

#endif
