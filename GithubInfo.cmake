# Copyright (c) 2012-2014 Stefan Eilemann <eile@eyescale.ch>
#
# sets GIT_ORIGIN_ORG based on root or origin remote github.com/<Org>/...
# sets GIT_ORIGIN_org to lower-case of GIT_ORIGIN_ORG
# sets COMMON_ORGANIZATION_NAME to GIT_ORIGIN_ORG if not already set
# CI_ROOT_URL: The travis-ci.org URL for the root remote
# CI_ROOT_PNG: The travis-ci.org status png for the root remote
# ${UPPER_PROJECT_NAME}_ISSUES_URL: The URL for tickets on the root remote

include(GitInfo)

set(CI_ROOT_URL)
set(CI_ROOT_PNG)
set(ISSUES_ROOT_URL)

if(GIT_ROOT_URL)
  set(_git_origin_url ${GIT_ROOT_URL})
elseif(GIT_ORIGIN_URL)
  set(_git_origin_url ${GIT_ORIGIN_URL})
endif()

if(_git_origin_url)
  string(REGEX REPLACE ".*github.com[\\/:](.*)\\/.*" "\\1" GIT_ORIGIN_ORG
    "${_git_origin_url}")
endif()

if(NOT GIT_ORIGIN_ORG OR GIT_ORIGIN_ORG STREQUAL _git_origin_url)
  message(STATUS "Can't determine github organization for ${_git_origin_url}")
  set(GIT_ORIGIN_ORG)
else()
  string(TOLOWER ${GIT_ORIGIN_ORG} GIT_ORIGIN_org)
  if(NOT COMMON_ORGANIZATION_NAME)
    set(COMMON_ORGANIZATION_NAME ${GIT_ORIGIN_ORG})
  endif()
endif()

if(GIT_ROOT_URL MATCHES ".*github.com.*")
  string(REPLACE "github.com" "travis-ci.org" CI_ROOT_URL ${GIT_ROOT_URL})
  string(REPLACE ".git" "" CI_ROOT_URL ${CI_ROOT_URL})
  set(CI_ROOT_PNG ${CI_ROOT_URL}.png)
  if(NOT ${UPPER_PROJECT_NAME}_ISSUES_URL)
    string(REPLACE ".git" "/issues"
           ${UPPER_PROJECT_NAME}_ISSUES_URL ${GIT_ROOT_URL})
  endif()
endif()
