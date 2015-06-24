# Copyright (c) 2015 raphael.dumusc@epfl.ch

# Provides Qt support for CommonLibrary and CommonApplication:
#   common_qt_support(<Name>)
#
# Uses:
# * NAME_MOC_HEADERS, NAME_MOC_PUBLIC_HEADERS list of all moc input headers
# * NAME_UI_FORMS list of all .ui input files
# * NAME_RESOURCES list of all .qrc resource files
# * Sets the output to the following variables in parent scope:
# * COMMON_QT_SUPPORT_SOURCES

macro(COMMON_QT_SUPPORT NAME)
  set(COMMON_QT_SUPPORT_SOURCES "")
  if(${NAME}_MOC_HEADERS)
    if(NOT Qt5Core_FOUND)
      message(FATAL_ERROR "Qt5Core not found, needed for MOC of application ${Name}")
    endif()
    qt5_wrap_cpp(MOC_SOURCES ${${NAME}_MOC_HEADERS})
    list(APPEND COMMON_QT_SUPPORT_SOURCES ${MOC_SOURCES})
  endif()
  if(${NAME}_MOC_PUBLIC_HEADERS)
    if(NOT Qt5Core_FOUND)
      message(FATAL_ERROR "Qt5Core not found, needed for MOC of application ${Name}")
    endif()
    qt5_wrap_cpp(MOC_SOURCES ${${NAME}_MOC_PUBLIC_HEADERS})
    list(APPEND COMMON_QT_SUPPORT_SOURCES ${MOC_SOURCES})
  endif()
  if(${NAME}_UI_FORMS)
    if(NOT Qt5Widgets_FOUND)
      message(FATAL_ERROR "Qt5Widgets not found, needed for UIC of application ${Name}")
    endif()
    qt5_wrap_ui(UI_SOURCES ${${NAME}_UI_FORMS})
    list(APPEND COMMON_QT_SUPPORT_SOURCES ${UI_SOURCES})
    include_directories(${PROJECT_BINARY_DIR})
  endif()
  if(${NAME}_RESOURCES)
    if(NOT Qt5Core_FOUND)
      message(FATAL_ERROR "Qt5Core not found, needed for QRC of application ${Name}")
    endif()
    qt5_add_resources(QRC_SOURCES ${${NAME}_RESOURCES})
    list(APPEND COMMON_QT_SUPPORT_SOURCES ${QRC_SOURCES})
  endif()
  set(COMMON_QT_SUPPORT_SOURCES ${COMMON_QT_SUPPORT_SOURCES} PARENT_SCOPE)
endmacro()
