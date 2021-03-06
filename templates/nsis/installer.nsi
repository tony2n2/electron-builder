!include "common.nsh"
!include "MUI2.nsh"
!include "multiUser.nsh"
!include "allowOnlyOneInstallerInstace.nsh"

!ifdef ONE_CLICK
  !include "oneClick.nsh"
!else
  !include "boringInstaller.nsh"
!endif

!ifmacrodef customHeader
  !insertmacro customHeader
!endif

Var startMenuLink
Var desktopLink

!ifdef BUILD_UNINSTALLER
  SilentInstall silent
!endif

Function .onInit
  !ifdef BUILD_UNINSTALLER
    WriteUninstaller "${UNINSTALLER_OUT_FILE}"
    # avoid exit code 2
    SetErrorLevel 0
    Quit
  !else
    !insertmacro check64BitAndSetRegView
    !insertmacro initMultiUser ""

    !ifdef ONE_CLICK
      !insertmacro ALLOW_ONLY_ONE_INSTALLER_INSTACE
    !else
      ${IfNot} ${UAC_IsInnerInstance}
        !insertmacro ALLOW_ONLY_ONE_INSTALLER_INSTACE
      ${EndIf}
    !endif

    InitPluginsDir

    SetCompress off
    !ifdef APP_32
      File /oname=$PLUGINSDIR\app-32.7z "${APP_32}"
    !endif
    !ifdef APP_64
      File /oname=$PLUGINSDIR\app-64.7z "${APP_64}"
    !endif
    SetCompress "${COMPRESS}"

    !ifdef HEADER_ICO
      File /oname=$PLUGINSDIR\installerHeaderico.ico "${HEADER_ICO}"
    !endif

    !ifmacrodef customInit
      !insertmacro customInit
    !endif
  !endif
FunctionEnd

!ifndef BUILD_UNINSTALLER
  Section "install"
    ${IfNot} ${Silent}
      SetDetailsPrint none

      !ifdef ONE_CLICK
        !ifdef HEADER_ICO
          SpiderBanner::Show /MODERN /ICON "$PLUGINSDIR\installerHeaderico.ico"
        !else
          SpiderBanner::Show /MODERN
       !endif
      !endif
    ${EndIf}

    !insertmacro CHECK_APP_RUNNING "install"

    RMDir /r $INSTDIR
    SetOutPath $INSTDIR

    !ifdef APP_64
      ${If} ${RunningX64}
        Nsis7z::Extract "$PLUGINSDIR\app-64.7z"
      ${Else}
        Nsis7z::Extract "$PLUGINSDIR\app-32.7z"
      ${EndIf}
    !else
      Nsis7z::Extract "$PLUGINSDIR\app-32.7z"
    !endif

    File "/oname=${UNINSTALL_FILENAME}" "${UNINSTALLER_OUT_FILE}"

    !insertmacro registryAddInstallInfo

    StrCpy $startMenuLink "$SMPROGRAMS\${PRODUCT_FILENAME}.lnk"
    StrCpy $desktopLink "$DESKTOP\${PRODUCT_FILENAME}.lnk"

    # create shortcuts in the start menu and on the desktop
    # shortcut for uninstall is bad cause user can choose this by mistake during search, so, we don't add it
    CreateShortCut "$startMenuLink" "$INSTDIR\${APP_EXECUTABLE_FILENAME}" "" "$INSTDIR\${APP_EXECUTABLE_FILENAME}" 0 "" "" "${APP_DESCRIPTION}"
    CreateShortCut "$desktopLink" "$INSTDIR\${APP_EXECUTABLE_FILENAME}" "" "$INSTDIR\${APP_EXECUTABLE_FILENAME}" 0 "" "" "${APP_DESCRIPTION}"

    WinShell::SetLnkAUMI "$startMenuLink" "${APP_ID}"
    WinShell::SetLnkAUMI "$desktopLink" "${APP_ID}"

    !ifmacrodef registerFileAssociations
      !insertmacro registerFileAssociations
    !endif

    !ifmacrodef customInstall
      !insertmacro customInstall
    !endif

    ${IfNot} ${Silent}
      !ifdef ONE_CLICK
        # otherwise app window will be in backround
        HideWindow
        !ifdef RUN_AFTER_FINISH
          Call StartApp
        !endif
      !endif
    ${EndIf}
  SectionEnd
!else
  Section
  SectionEnd
  !include "uninstaller.nsh"
!endif