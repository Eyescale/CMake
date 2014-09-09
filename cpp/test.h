
/* Copyright (c) 2005-2014, Stefan Eilemann <eile@equalizergraphics.com>
 *
 * This library is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License version 2.1 as published
 * by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef LBTEST_TEST_H
#define LBTEST_TEST_H

#include <lunchbox/log.h>
#include <lunchbox/sleep.h>
#include <lunchbox/thread.h>

#include <cstdlib>
#include <fstream>
#include <stdexcept>

#define OUTPUT lunchbox::Log::instance( __FILE__, __LINE__ )

#define TEST( x )                                                       \
    {                                                                   \
        LBVERB << "Test " << #x << std::endl;                           \
        if( !(x) )                                                      \
        {                                                               \
            OUTPUT << #x << " failed (l." << __LINE__ << ')' << std::endl; \
            lunchbox::abort();                                          \
            ::exit( EXIT_FAILURE );                                     \
        }                                                               \
    }

#define TESTINFO( x, info )                                           \
    {                                                                 \
        LBVERB << "Test " << #x << ": " << info << std::endl;         \
        if( !(x) )                                                    \
        {                                                             \
            OUTPUT << #x << " failed (l." << __LINE__ << "): " << info  \
                   << std::endl;                                        \
            lunchbox::abort();                                          \
            ::exit( EXIT_FAILURE );                                     \
        }                                                               \
    }

#define TESTRESULT( x, type )                                           \
    {                                                                   \
        LBVERB << "Test " << #x << std::endl;                           \
        const type& testRes = (x);                                      \
        if( !testRes )                                                  \
        {                                                               \
            OUTPUT << #x << " failed with " << testRes << " (l."        \
                   << __LINE__ << ")" << std::endl;                     \
            lunchbox::abort();                                          \
            ::exit( EXIT_FAILURE );                                     \
        }                                                               \
    }

int testMain( int argc, char **argv );

namespace
{
class Watchdog : public lunchbox::Thread
{
public:
    explicit Watchdog( const std::string& name ) : _name( name ) {}

    virtual void run()
        {
            lunchbox::Thread::setName( "Watchdog" );
#ifdef TEST_RUNTIME
            lunchbox::sleep( TEST_RUNTIME * 1000 );
            TESTINFO( false,
                      "Watchdog triggered - " << _name <<
                      " did not terminate within " << TEST_RUNTIME << "s" );
#else
            lunchbox::sleep( 60000 );
            TESTINFO( false,
                      "Watchdog triggered - " << _name <<
                      " did not terminate within 1 minute" );
#endif
        }

private:
    const std::string _name;
};
}

int main( int argc, char **argv )
{
#ifndef TEST_NO_WATCHDOG
    Watchdog watchdog( argv[0] );
    watchdog.start();
#endif

    try
    {
        const int result = testMain( argc, argv );
        if( result != EXIT_SUCCESS )
            return result;
    }
    catch( const std::runtime_error& e )
    {
        LBINFO << e.what() << std::endl;
        return EXIT_FAILURE;
    }

#ifndef TEST_NO_WATCHDOG
    watchdog.cancel();
    lunchbox::sleep( 10 ); // give watchdog time to terminate
#endif
    return EXIT_SUCCESS;
}

#  define main testMain

#endif // LBTEST_TEST_H
