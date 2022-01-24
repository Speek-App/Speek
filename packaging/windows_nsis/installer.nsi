!include MUI2.nsh

Function .onInit
  InitPluginsDir
  ;Get the skin file to use
  File /oname=$PLUGINSDIR\Windows10Dark.vsf ".\Styles1\Windows10Dark.vsf"
  ;Load the skin using the LoadVCLStyle function 
  NSISVCLStyles::LoadVCLStyle $PLUGINSDIR\Windows10Dark.vsf
FunctionEnd

Function un.onInit
  InitPluginsDir
  File /oname=$PLUGINSDIR\Amakrits.vsf ".\Styles1\Amakrits.vsf"
  ;Load the skin using the LoadVCLStyle function 
  NSISVCLStyles::LoadVCLStyle $PLUGINSDIR\Amakrits.vsf
FunctionEnd

!define MUI_WELCOMEFINISHPAGE_BITMAP "speek-windows-installer-side.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "speek-windows-installer-top.bmp" 
!define MUI_ICON "speek.ico" 

!define APPNAME "Speek"

# define name of installer
OutFile "${APPNAME}.exe"

Name "${APPNAME}"
 
# define installation directory
InstallDir "$PROGRAMFILES\${APPNAME}"
 
# For removing Start Menu shortcut in Windows 7
RequestExecutionLevel user

!insertmacro MUI_PAGE_WELCOME
# !insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_LANGUAGE "English"
 
# start default section
Section
 
    # set the installation directory as the destination for the following actions
    SetOutPath $INSTDIR
 
    # create the uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"
 
    # point the new shortcut at the program uninstaller
    CreateShortcut "$SMPROGRAMS\${APPNAME}.lnk" "$INSTDIR\${APPNAME}.exe"
    CreateShortcut "$SMPROGRAMS\${APPNAME} Uninstall.lnk" "$INSTDIR\uninstall.exe"

    File /r "Speek\*"

SectionEnd
 
# uninstaller section start
Section "uninstall"
 
    # first, delete the uninstaller
    Delete "$INSTDIR\uninstall.exe"
 
    # second, remove the link from the start menu
    Delete "$SMPROGRAMS\${APPNAME}.lnk"
    Delete "$SMPROGRAMS\${APPNAME} Uninstall.lnk"
 
    Delete $INSTDIR

# uninstaller section end
SectionEnd
