# Find the Python Cython package.
# Will set PYTHON_CYTHON_FOUND and PYTHON_CYTHON_VERSION as appropriate

include(FindPythonModule)

if(PYTHONCYTHON_FIND_QUIETLY)
  set(QUIET "QUIET")
endif()

if(PYTHONCYTHON_FIND_REQUIRED)
  set(REQUIRED "REQUIRED")
endif()

find_python_module("Cython" ${QUIET} ${REQUIRED})


