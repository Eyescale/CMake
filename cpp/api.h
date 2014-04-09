/* Copyright (c) 2014 Stefan.Eilemann@epfl.ch */

/**
 * @file @PROJECT_INCLUDE_NAME@/api.h
 * Defines export visibility macros for @CMAKE_PROJECT_NAME@.
 */

#ifndef @UPPER_PROJECT_NAME@_API_H
#define @UPPER_PROJECT_NAME@_API_H

#include <@PROJECT_INCLUDE_NAME@/defines.h>

#if defined(_MSC_VER) || defined(__declspec)
#  define @PROJECT_NAMESPACE@_DLLEXPORT __declspec(dllexport)
#  define @PROJECT_NAMESPACE@_DLLIMPORT __declspec(dllimport)
#else // _MSC_VER
#  define @PROJECT_NAMESPACE@_DLLEXPORT
#  define @PROJECT_NAMESPACE@_DLLIMPORT
#endif // _MSC_VER

#if defined(@UPPER_PROJECT_NAME@_STATIC)
#  define @PROJECT_NAMESPACE@_API
#elif defined(@UPPER_PROJECT_NAME@_SHARED)
#  define @PROJECT_NAMESPACE@_API @PROJECT_NAMESPACE@_DLLEXPORT
#else
#  define @PROJECT_NAMESPACE@_API @PROJECT_NAMESPACE@_DLLIMPORT
#endif

#if defined(@UPPER_PROJECT_NAME@_SHARED_INL)
#  define @PROJECT_NAMESPACE@_INL @PROJECT_NAMESPACE@_DLLEXPORT
#else
#  define @PROJECT_NAMESPACE@_INL @PROJECT_NAMESPACE@_DLLIMPORT
#endif

#endif
