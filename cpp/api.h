/* Copyright (c) 2014 Stefan.Eilemann@epfl.ch */

/**
 * @file @PROJECT_INCLUDE_NAME@/api.h
 * Defines export visibility macros for @CMAKE_PROJECT_NAME@.
 */

#ifndef @UPPER_PROJECT_NAME@_API_H
#define @UPPER_PROJECT_NAME@_API_H

#include <@PROJECT_INCLUDE_NAME@/defines.h>

#if defined(_MSC_VER) || defined(__declspec)
#  define @UPPER_PROJECT_NAME@_DLLEXPORT __declspec(dllexport)
#  define @UPPER_PROJECT_NAME@_DLLIMPORT __declspec(dllimport)
#else // _MSC_VER
#  define @UPPER_PROJECT_NAME@_DLLEXPORT
#  define @UPPER_PROJECT_NAME@_DLLIMPORT
#endif // _MSC_VER

#if defined(@UPPER_PROJECT_NAME@_STATIC)
#  define @UPPER_PROJECT_NAME@_API
#elif defined(@UPPER_PROJECT_NAME@_SHARED)
#  define @UPPER_PROJECT_NAME@_API @UPPER_PROJECT_NAME@_DLLEXPORT
#else
#  define @UPPER_PROJECT_NAME@_API @UPPER_PROJECT_NAME@_DLLIMPORT
#endif

#endif
