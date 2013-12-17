
# Copyright (c) 2013 Daniel Nachbaur <daniel.nachbaur@epfl.ch>

# Writes the generic module file which is consumed by GNUModules.cmake. This
# file is meant to be called in script mode by providing those variables:
# - MODULE_FILENAME: The filename of the module
# - MODULE_PACKAGE_NAME: The name of the package/project
# - MODULE_VERSION: The version of the package/project
# - MODULE_MESSAGE_AFTER_LOAD: A message to be displayed after the module was loaded


file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/WriteModuleFile.cmake
  "\n"
  "if(NOT MODULE_FILENAME OR NOT MODULE_PACKAGE_NAME OR NOT MODULE_VERSION)\n"
  "  message(FATAL_ERROR \"Need MODULE_FILENAME, MODULE_PACKAGE_NAME and MODULE_VERSION for module file generation\")\n"
  "endif()\n"

  # write file
  "file(WRITE ${CMAKE_BINARY_DIR}/\${MODULE_FILENAME}\n"
  "  \"#%Module1.0\\n\"\n"
  "  \"######################################################################\\n\"\n"
  "  \"#\\n\"\n"
  "  \"# Module:      \${MODULE_FILENAME}\\n\"\n"
  "  \"#\\n\"\n"
  "  \"#\\n\"\n"
  "  \"\\n\"\n"
  "  \"# Set internal variables\\n\"\n"
  "  \"set sw_basedir   \\\"${MODULE_SW_BASEDIR}\\\"\\n\"\n"
  "  \"set sw_class     \\\"${MODULE_SW_CLASS}\\\"\\n\"\n"
  "  \"set package_name \\\"\${MODULE_PACKAGE_NAME}\\\"\\n\"\n"
  "  \"set version      \\\"\${MODULE_VERSION}\\\"\\n\"\n"
  "  \"set platform     \\\"${MODULE_PLATFORM}\\\"\\n\"\n"
  "  \"set compiler     \\\"${MODULE_COMPILER}\\\"\\n\"\n"
  "  \"set architecture \\\"${MODULE_ARCHITECTURE}\\\"\\n\"\n"
  "  \"set root         \\\"${MODULE_ROOT}\\\"\\n\"\n"
  "  \"\\n\"\n"
  "  \"module-whatis \\\"${MODULE_WHATIS}\\\"\\n\"\n"
  "  \"\\n\"\n"
  "  \"proc ModulesHelp { } {\\n\"\n"
  "  \"    global package_name version architecture\\n\"\n"
  "  \"\\n\"\n"
  "  \"    puts stderr \\\"This module prepares your environment to run $package_name $version for the architecture: $architecture\\n\"\n"
  "  \"\\n\"\n"
  "  \"Type 'module list' to list all the loaded modules.\\n\"\n"
  "  \"Type 'module avail' to list all the availables ones.\\\"\\n\"\n"
  "  \"}\\n\"\n"
  "  \"if { [ module-info mode load ] || [ module-info mode switch3 ] } {\\n\"\n"
  "  \"    puts stderr \\\"\${MODULE_MESSAGE_AFTER_LOAD}\\\"\\n\"\n"
  "  \"}\\n\"\n"
  "  \"\\n\"\n"
  "  \"${MODULE_ENV}\\n\"\n"
  "  \"conflict \${MODULE_PACKAGE_NAME}\\n\"\n"
  "  \"\\n\"\n"
  ")\n"
)
