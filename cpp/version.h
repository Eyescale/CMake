/* Copyright (c) 2014 Stefan.Eilemann@epfl.ch */

#ifndef @UPPER_PROJECT_NAME@_VERSION_H
#define @UPPER_PROJECT_NAME@_VERSION_H

#include <@PROJECT_INCLUDE_NAME@/api.h>
#include <string>

namespace @PROJECT_namespace@
{
    /** The current major version. */
#   define @PROJECT_NAMESPACE@_VERSION_MAJOR @VERSION_MAJOR@

    /** The current minor version. */
#   define @PROJECT_NAMESPACE@_VERSION_MINOR @VERSION_MINOR@

    /** The current patch level. */
#   define @PROJECT_NAMESPACE@_VERSION_PATCH @VERSION_PATCH@

    /** The current SCM revision. */
#   define @PROJECT_NAMESPACE@_VERSION_REVISION 0x@GIT_REVISION@

    /** The current binary interface. */
#   define @PROJECT_NAMESPACE@_VERSION_ABI @VERSION_ABI@

/** True if the current version is newer than the given one. */
#   define @PROJECT_NAMESPACE@_VERSION_GT( MAJOR, MINOR, PATCH )       \
    ( (@PROJECT_NAMESPACE@_VERSION_MAJOR>MAJOR) ||                     \
      (@PROJECT_NAMESPACE@_VERSION_MAJOR==MAJOR && (@PROJECT_NAMESPACE@_VERSION_MINOR>MINOR || \
          (@PROJECT_NAMESPACE@_VERSION_MINOR==MINOR && @PROJECT_NAMESPACE@_VERSION_PATCH>PATCH))))

/** True if the current version is equal or newer to the given. */
#   define @PROJECT_NAMESPACE@_VERSION_GE( MAJOR, MINOR, PATCH )       \
    ( (@PROJECT_NAMESPACE@_VERSION_MAJOR>MAJOR) ||                     \
      (@PROJECT_NAMESPACE@_VERSION_MAJOR==MAJOR && (@PROJECT_NAMESPACE@_VERSION_MINOR>MINOR || \
          (@PROJECT_NAMESPACE@_VERSION_MINOR==MINOR && @PROJECT_NAMESPACE@_VERSION_PATCH>=PATCH))))

/** True if the current version is older than the given one. */
#   define @PROJECT_NAMESPACE@_VERSION_LT( MAJOR, MINOR, PATCH )       \
    ( (@PROJECT_NAMESPACE@_VERSION_MAJOR<MAJOR) ||                     \
      (@PROJECT_NAMESPACE@_VERSION_MAJOR==MAJOR && (@PROJECT_NAMESPACE@_VERSION_MINOR<MINOR || \
          (@PROJECT_NAMESPACE@_VERSION_MINOR==MINOR && @PROJECT_NAMESPACE@_VERSION_PATCH<PATCH))))

/** True if the current version is older or equal to the given. */
#   define @PROJECT_NAMESPACE@_VERSION_LE( MAJOR, MINOR, PATCH )       \
    ( (@PROJECT_NAMESPACE@_VERSION_MAJOR<MAJOR) ||                     \
      (@PROJECT_NAMESPACE@_VERSION_MAJOR==MAJOR && (@PROJECT_NAMESPACE@_VERSION_MINOR<MINOR || \
        (@PROJECT_NAMESPACE@_VERSION_MINOR==MINOR && @PROJECT_NAMESPACE@_VERSION_PATCH<=PATCH))))

/** Information about the current @CMAKE_PROJECT_NAME@ version. */
class @PROJECT_NAMESPACE@_API Version
{
public:
    /** @return the current major version of @CMAKE_PROJECT_NAME@. */
    static int getMajor();

    /** @return the current minor version of @CMAKE_PROJECT_NAME@. */
    static int getMinor();

    /** @return the current patch level of @CMAKE_PROJECT_NAME@. */
    static int getPatch();

    /** @return the current @CMAKE_PROJECT_NAME@ version (MM.mm.pp). */
    static std::string getString();

    /** @return the SCM revision. */
    static int getRevision();

    /** @return the current binary interface version of @CMAKE_PROJECT_NAME@. */
    static int getABI();

    /** @return the current @CMAKE_PROJECT_NAME@ version plus the git SHA hash (MM.mm.pp.rev). */
    static std::string getRevString();

    /**
     * Runtime check for ABI compatibility.
     *
     * Call from code using @CMAKE_PROJECT_NAME@. Will fail if the executable
     * was compiled against a version incompatible with the runtime version.
     *
     * @return true if the link-time and compile-time DSO are compatible.
     */
    static bool check()
    {
        return getMajor()==@PROJECT_NAMESPACE@_VERSION_MAJOR &&
               getMinor()==@PROJECT_NAMESPACE@_VERSION_MINOR;
    }
};

}

#endif
