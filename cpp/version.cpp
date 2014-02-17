/* Copyright (c) 2014 Stefan.Eilemann@epfl.ch */

#include <@LOWER_PROJECT_NAME@/version.h>
#include <sstream>

namespace @LOWER_PROJECT_NAME@
{

int Version::getMajor()
{
    return @UPPER_PROJECT_NAME@_VERSION_MAJOR;
}

int Version::getMinor()
{
    return @UPPER_PROJECT_NAME@_VERSION_MINOR;
}

int Version::getPatch()
{
    return @UPPER_PROJECT_NAME@_VERSION_PATCH;
}

std::string Version::getString()
{
    std::ostringstream version;
    version << getMajor() << '.' << getMinor() << '.' << getPatch();
    return version.str();
}

int Version::getRevision()
{
    return @UPPER_PROJECT_NAME@_VERSION_REVISION;
}

std::string Version::getRevString()
{
    std::ostringstream version;
    version << getString() << '.' << std::hex << getRevision() << std::dec;
    return version.str();
}

}
