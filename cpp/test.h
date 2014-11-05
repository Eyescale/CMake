
/* Copyright (c) 2005-2014, Stefan Eilemann <eile@equalizergraphics.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *   this list of conditions and the following disclaimer in the documentation
 *   and/or other materials provided with the distribution.
 * - Neither the name of Eyescale Software GmbH nor the names of its
 *   contributors may be used to endorse or promote products derived from this
 *   software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
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
