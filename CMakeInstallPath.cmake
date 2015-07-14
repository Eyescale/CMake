# sets CMAKE_MODULE_INSTALL_PATH to where CMake script should be installed

if(MSVC)
  set(CMAKE_MODULE_INSTALL_PATH ${PROJECT_NAME}/CMake)
else()
  set(CMAKE_MODULE_INSTALL_PATH share/${PROJECT_NAME}/CMake)
endif()
