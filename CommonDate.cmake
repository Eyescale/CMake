# sets COMMON_DATE to today
if(NOT COMMON_DATE)
  if(WIN32)
    execute_process(COMMAND "cmd" " /C date /T" OUTPUT_VARIABLE COMMON_DATE)
  else()
    execute_process(COMMAND "date" "+%d/%m/%Y" OUTPUT_VARIABLE COMMON_DATE)
  endif()
  string(REGEX REPLACE "(..)/(..)/..(..).*" "\\1/\\2/\\3"
    COMMON_DATE ${COMMON_DATE})
endif()
