#!/usr/bin/env python
###############################################################################
## Read env_mach_specific.xml in NorESM2 case dir for environment settings
## Usage:
##      ./parse_mach_specific.py CASEDIR
## Output the export and module load commands for bash, ex.:
##      export VAR1=value1
##      export VAR2=value2
##      export VAR3=value3
##      module --quiet restore system
##      module --quiet load StdEnv
##      module --quiet load iomkl/2020a
##      module --quiet load netCDF-Fortran/4.5.2-iompi-2020a
##      module --quiet load CMake/3.12.1
##
## bash useage with save to file example:
##      ./parse_mach_specific.py CASEDIR  > env.bash
##      source env.bash
## bash useage without file example ( " char is necessary):
##      eval "$(./parse_mach_specific.py CASEDIR)"
##
##
## Reversion history:
##      2023-08-18, Ping-Gin, Created
###############################################################################

import xml.etree.ElementTree as ET
from sys import argv

case = argv[1]+'/' if len(argv) > 1 else  ''
fn = 'env_mach_specific.xml'

modulecmd='module'
exportcmd='export'

root = ET.parse(case+fn).getroot()
env = root.find('environment_variables')
module_system = root.find('module_system')
modules = module_system.find('modules')
modcmd = module_system

for i in modules: print(modulecmd+" "+i.attrib['name']+' '+ i.text)
print('')
for i in env: print(exportcmd+" "+i.attrib['name']+'='+i.text)

