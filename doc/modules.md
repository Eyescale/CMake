Modularization
============

This document describes the changes for a more fine grained
modularization of common libraries, e.g., Lunchbox. It is motivated by
the desire to use finer grained modules in downstream projects to ease
the integration, and in consequence to increase code reuse.

## Requirements

* Per-functionality targets
* Improved build times for super projects

## Implementation

* A new super-all target will be introduced, building only the super
  project's targets and dependencies (similar to the existing sub-all).
* Sub projects will exclude applications and tests from the all target
* Sub-libraries have a top-level header, e.g., lunchbox/log.h, and a
  sub-directory with the implementation and CMakeLists, e.g.,
  lunchbox/log/log.h and .cpp. The new common_add_library() cmake module
  auto-generates the top-level header. New sub libraries set
  NAME_OMIT_LIBRARY_HEADER.
* The old common_library is deprecated, and stays during the transition
  period.
* Optional sub-targets are to be avoided and hidden by facades (esp. in
  Lunchbox, see PersistentMap). If they are necessary, e.g, in hwsd,
  downstream code needs to test for the target's availability (as done
  e.g. in eq/server).
* Servus will eventually be reintegrated as a lunchbox sub library.

## Naming

    common_add_library(Lunchbox::Log HEADERS logImpl.h PUBLIC_HEADERS log.h
      SOURCES log.cpp DEPENDS PUBLIC Lunchbox::Bar PRIVATE Lunchbox::Foo)

Generates: .../include/lunchbox/log.h, .../include/lunchbox/log/log.h,
.../lib/libLunchboxLog.so

    common_add_library(Lunchbox DEPENDS PUBLIC Lunchbox::Log)

Generates: .../include/lunchbox.h

## Examples

    #include <zeroeq.h>
    #include <lunchbox/log.h>

### Desired Lunchbox Granularity

    Lunchbox::Any
    Lunchbox::Atomic
    Lunchbox::Attic
    Lunchbox::Bits
    Lunchbox::Buffer
    Lunchbox::Clock
    Lunchbox::Condition
    Lunchbox::DSO
    Lunchbox::File
    Lunchbox::Future
    Lunchbox::Launcher
    Lunchbox::Lock (lock, spinlock, scoped, monitor, queue, lockable)
    Lunchbox::LockFree
    Lunchbox::Log
    Lunchbox::MemoryMap
    Lunchbox::Monitor
    Lunchbox::OS
    Lunchbox::PersistentMap
    Lunchbox::Plugin
    Lunchbox::Process (daemon+launcher)
    Lunchbox::RNG
    Lunchbox::Servus
    Lunchbox::TLS
    Lunchbox::Test
    Lunchbox::Thread
    Lunchbox::URI
    Lunchbox::IntervalSet (was UnorderedIntervalSet)

## Issues

### 1: How do handle optional targets?

_Resolution: Avoid them as possible, downstream projects need to check
with if(TARGET) in cmake:_

We could (re)use the COMPONENTS parameter in common_find_package(), but
this would overload semantics and add magic. Right now we only have a
few use cases (hwsd, ZeroEQ Qt support). We might decide to improve
common_find_package() later if needed.

Alternatively we could generate a package config for each sub library,
so that downstream projects check for each sub library individually,
e.g., common_find_package(Lunchbox::Log REQUIRED). In consequence this
means that each sub library becomes a separate git project: find_package
is designed to find a project, and we eventually want to extend the
common_find_package syntax to include a git url and SHA to get rid of
the redundant .gitsubprojects.

### 2: Can we exclude sub targets from the default build?

_Resolution: Not possible with CMake today. Will introduce super-all
target for this feature_

Sub project targets cannot be excluded from the default build. To
exclude them, one also needs to exclude the install target, otherwise
CMake will complain. Removing the install target is not possible since
the super-install step would then miss sub-libraries.

### 3. What's the granularity of a project?

_Resolution: Unresolved_

For Lunchbox we have three options: one project including Lunchbox and
Servus with sub-libraries, one project per sub-library (eg. LunchboxLog)
and two libraries (mostly for separating the historical bagagge from
more commonly used code).
