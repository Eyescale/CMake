# Find a specific Python module.
#
# Will set:
# PYTHON${NAME_UPPER}_FOUND if found;
# PYTHON${NAME_UPPER}_VERSION if module __version__ is defined;
# where ${NAME_UPPER} is the capitalized module name.
#
# find_python_module(${MODULE}) will emulate find_package()'s 'quiet' behaviour
# if Python${MODULE}_FIND_QUIETLY is set to a true value, and similarly
# will emulate 'required' behaviour if Python${MODULE}_FIND_REQUIRED
# is set to a true value. (MODULE is case-sensitive.)

macro(cache_test_and_set KEY MSG FOUND)
    if("${MSG}" STREQUAL "${MESSAGE_CACHE_BY_${KEY}}")
        set("${FOUND}" 1)
    else()
        set("${FOUND}" 0)
        set("MESSAGE_CACHE_BY_${KEY}" "${MSG}" CACHE INTERNAL "cached reporting message")
    endif()
endmacro()

# Don't repeat a message; check by looking up key in cache
macro(fail_message key msg)
    if(REQUIRED) 
        message(FATAL_ERROR "${msg}")
    elseif (NOT QUIET)
        cache_test_and_set("${key}" "${msg}" FOUND)
        if(NOT FOUND)
            message(STATUS "${msg}")
        endif()
    endif()
endmacro()

macro(success_message key msg)
    if(NOT QUIET)
        cache_test_and_set("${key}" "${msg}" FOUND)
        if(NOT FOUND)
            message(STATUS "${msg}")
        endif()
    endif()
endmacro()

function(find_python_module MODULENAME)
    string(TOUPPER ${MODULENAME} NAME_UPPER)

    set(QUIET ${Python${MODULENAME}_FIND_QUIETLY})
    set(REQUIRED ${Python${MODULENAME}_FIND_REQUIRED})

    find_package(PythonInterp ${QUIET} ${REQUIRED})

    if(NOT PYTHON_EXECUTABLE)
        fail_message(PYTHON_${MODULENAME} "No python interpreter found")
        set(PYTHON${NAME_UPPER}_FOUND 0)
    else()
        execute_process(COMMAND ${PYTHON_EXECUTABLE} -c
                            "import ${MODULENAME} as x; print x.__version__ if hasattr(x,'__version__') else ''"
                        ERROR_QUIET
                        RESULT_VARIABLE RV
                        OUTPUT_VARIABLE MODVER
                        OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(NOT RV)
            set(PYTHON${NAME_UPPER}_FOUND 1 CACHE INTERNAL "Python module ${MODULENAME} found")
            set(PYTHON${NAME_UPPER}_VERSION "${MODVER}" CACHE INTERNAL "Python module ${MODULENAME} version")
            success_message(PYTHON${MODULENAME} "Found python module ${MODULENAME}: (found version \"${MODVER}\")")
        else()
            fail_message(PYTHON${MODULENAME} "Could NOT find python module ${MODULENAME}")
        endif()
    endif()
endfunction()

