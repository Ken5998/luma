#ifndef AppVersion
  #error AppVersion is required
#endif
[Setup]
AppId={{AE5327E7-474B-47B6-BF01-2D5352A418AF}
AppName=Luma
AppVersion={#AppVersion}
AppPublisher=Kenan Kasumović
AppPublisherURL=https://luma.ksmvc.ch
AppSupportURL=https://github.com/Ken5998/luma/issues
AppUpdatesURL=https://github.com/Ken5998/luma/releases
DefaultDirName={localappdata}\Luma\Screensaver
DisableDirPage=yes
UsePreviousAppDir=no
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
CloseApplications=no
RestartApplications=no
LicenseFile=..\..\LICENSE
OutputDir={#OutputDir}
OutputBaseFilename=Luma-{#AppVersion}-Setup-x64
; Keep the executable payload directly inspectable instead of solid compression.
Compression=none
SolidCompression=no
WizardStyle=modern
UninstallDisplayIcon={app}\Luma.scr
VersionInfoVersion={#AppVersion}.0
VersionInfoDescription=Luma Screensaver Setup
VersionInfoProductName=Luma

[Files]
Source: "{#PayloadDir}\Luma.scr"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#PayloadDir}\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#HelperPath}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#HelperPath}"; Flags: dontcopy
Source: "setup-uninstall.cmd"; DestDir: "{app}"; DestName: "Uninstall.cmd"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "Control Panel\Desktop"; ValueType: string; ValueName: "SCRNSAVE.EXE"; ValueData: "{app}\Luma.scr"

[Run]
Filename: "{sys}\rundll32.exe"; Parameters: "shell32.dll,Control_RunDLL desk.cpl,,1"; Description: "Open Windows Screen Saver Settings"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\installation.json"
Type: files; Name: "{app}\Luma.log"

[InstallDelete]
; Explicit files owned by the old setup/ZIP installation; no user preferences.
Type: files; Name: "{app}\setup-actions.ps1"
Type: files; Name: "{app}\deployment.ps1"
Type: files; Name: "{app}\Uninstall.ps1"

[Code]
function RunAction(HelperPath, Action: String): Boolean;
var ExitCode: Integer;
begin
  Result := Exec(HelperPath,
    Action + ' "' + ExpandConstant('{app}') + '"',
    '', SW_HIDE, ewWaitUntilTerminated, ExitCode);
  if Result then Result := ExitCode = 0;
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  ExtractTemporaryFile('luma-install-helper.exe');
  if not RunAction(ExpandConstant('{tmp}\luma-install-helper.exe'), 'Prepare') then
    Result := 'Close Luma and Windows Screen Saver Settings, then retry. Installation metadata must be valid.'
  else Result := '';
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    if not RunAction(ExpandConstant('{app}\luma-install-helper.exe'), 'Restore') then
      RaiseException('Close Luma and Windows Screen Saver Settings, then retry. Uninstall could not restore the previous selection.');
end;
