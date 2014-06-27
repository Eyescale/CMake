# Find the Python nose package.
# Will set PYTHONNOSE_FOUND and PYTHONNOSE_VERSION as appropriate

include(FindPythonModule)

if(PYTHONNOSE_FIND_QUIETLY)
  set(QUIET "QUIET")
endif()

if(PYTHONNOSE_FIND_REQUIRED)
  set(REQUIRED "REQUIRED")
endif()

find_python_module("nose" ${QUIET} ${REQUIRED})


