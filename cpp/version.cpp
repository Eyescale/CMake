/* Copyright (c) 2014 Stefan.Eilemann@epfl.ch */

#include <@PROJECT_INCLUDE_NAME@/version.h>
#include <sstream>

namespace @PROJECT_namespace@
{

int Version::getMajor()
{
    return @PROJECT_NAMESPACE@_VERSION_MAJOR;
}

int Version::getMinor()
{
    return @PROJECT_NAMESPACE@_VERSION_MINOR;
}

int Version::getPatch()
{
    return @PROJECT_NAMESPACE@_VERSION_PATCH;
}

int Version::getABI()
{
    return @PROJECT_NAMESPACE@_VERSION_ABI;
}

std::string Version::getString()
{
    std::ostringstream version;
    version << getMajor() << '.' << getMinor() << '.' << getPatch();
    return version.str();
}

int Version::getRevision()
{
    return @PROJECT_NAMESPACE@_VERSION_REVISION;
}

std::string Version::getRevString()
{
    std::ostringstream version;
    version << getString() << '.' << std::hex << getRevision() << std::dec;
    return version.str();
}

}
