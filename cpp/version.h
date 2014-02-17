/* Copyright (c) 2014 Stefan.Eilemann@epfl.ch */

#ifndef @UPPER_PROJECT_NAME@_VERSION_H
#define @UPPER_PROJECT_NAME@_VERSION_H

#include <@PROJECT_INCLUDE_NAME@/api.h>
#include <string>

namespace @PROJECT_INCLUDE_NAME@
{
    /** The current major version. */
#   define @UPPER_PROJECT_NAME@_VERSION_MAJOR @VERSION_MAJOR@

    /** The current minor version. */
#   define @UPPER_PROJECT_NAME@_VERSION_MINOR @VERSION_MINOR@

    /** The current patch level. */
#   define @UPPER_PROJECT_NAME@_VERSION_PATCH @VERSION_PATCH@

    /** The current SCM revision. */
#   define @UPPER_PROJECT_NAME@_VERSION_REVISION 0x@GIT_REVISION@

/** True if the current version is newer than the given one. */
#   define @UPPER_PROJECT_NAME@_VERSION_GT( MAJOR, MINOR, PATCH )       \
    ( (@UPPER_PROJECT_NAME@_VERSION_MAJOR>MAJOR) ||                     \
      (@UPPER_PROJECT_NAME@_VERSION_MAJOR==MAJOR && (@UPPER_PROJECT_NAME@_VERSION_MINOR>MINOR || \
          (@UPPER_PROJECT_NAME@_VERSION_MINOR==MINOR && @UPPER_PROJECT_NAME@_VERSION_PATCH>PATCH))))

/** True if the current version is equal or newer to the given. */
#   define @UPPER_PROJECT_NAME@_VERSION_GE( MAJOR, MINOR, PATCH )       \
    ( (@UPPER_PROJECT_NAME@_VERSION_MAJOR>MAJOR) ||                     \
      (@UPPER_PROJECT_NAME@_VERSION_MAJOR==MAJOR && (@UPPER_PROJECT_NAME@_VERSION_MINOR>MINOR || \
          (@UPPER_PROJECT_NAME@_VERSION_MINOR==MINOR && @UPPER_PROJECT_NAME@_VERSION_PATCH>=PATCH))))

/** True if the current version is older than the given one. */
#   define @UPPER_PROJECT_NAME@_VERSION_LT( MAJOR, MINOR, PATCH )       \
    ( (@UPPER_PROJECT_NAME@_VERSION_MAJOR<MAJOR) ||                     \
      (@UPPER_PROJECT_NAME@_VERSION_MAJOR==MAJOR && (@UPPER_PROJECT_NAME@_VERSION_MINOR<MINOR || \
          (@UPPER_PROJECT_NAME@_VERSION_MINOR==MINOR && @UPPER_PROJECT_NAME@_VERSION_PATCH<PATCH))))

/** True if the current version is older or equal to the given. */
#   define @UPPER_PROJECT_NAME@_VERSION_LE( MAJOR, MINOR, PATCH )       \
    ( (@UPPER_PROJECT_NAME@_VERSION_MAJOR<MAJOR) ||                     \
      (@UPPER_PROJECT_NAME@_VERSION_MAJOR==MAJOR && (@UPPER_PROJECT_NAME@_VERSION_MINOR<MINOR || \
        (@UPPER_PROJECT_NAME@_VERSION_MINOR==MINOR && @UPPER_PROJECT_NAME@_VERSION_PATCH<=PATCH))))

/** Information about the current @CMAKE_PROJECT_NAME@ version. */
class @UPPER_PROJECT_NAME@_API Version
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
        return getMajor()==@UPPER_PROJECT_NAME@_VERSION_MAJOR &&
               getMinor()==@UPPER_PROJECT_NAME@_VERSION_MINOR;
    }
};

}

#endif
