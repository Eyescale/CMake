# Copyright (c) 2014 Stefan.Eilemann@epfl.ch

# Uses execute_process but does parse and print errors
# Usage: common_process( "what does it do" INFO|WARNING|FATAL_ERROR
#                        [execute_process parameters] )

function(COMMON_PROCESS WHAT LEVEL)
  execute_process(${ARGN}
    RESULT_VARIABLE COMMON_PROCESS_RESULT
    OUTPUT_VARIABLE COMMON_PROCESS_OUTPUT
    ERROR_VARIABLE COMMON_PROCESS_OUTPUT)
  if(COMMON_PROCESS_RESULT)
    message(${LEVEL} "${WHAT} failed: ${COMMON_PROCESS_OUTPUT}")
  endif()
endfunction()
