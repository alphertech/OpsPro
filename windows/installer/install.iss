; Plexus - Windows Installer Script (Inno Setup)
; Version: 4.0
; Developer: AlpherTech (alphertech.com/plexus)
; Lead Engineers: Twale James Massete, Mugenyi Allan
; Support: alphertech@gmail.com
;
; Build with: ISCC.exe windows\installer\install.iss
; Requires Inno Setup 6.x (https://jrsoftware.org/isinfo.php)
; Output: windows\installer\output\Plexus_Setup_v4.0.exe
;
; For a polished installer, add these images next to this script:
;   - WizardImageFile="wizard.bmp"         (164 x 314 px, modern style)
;   - SmallBitmapImageFile="small.bmp"     (55 x 55 px, shown top-right)
; Both should use the app's green theme (#43A047) and feature the logo.

#define MyAppName "Plexus"
#define MyAppVersion "4.0.0"
#define MyAppVersionShort "4.0"
#define MyAppPublisher "AlpherTech"
#define MyAppURL "https://alphertech.com/plexus"
#define MyAppSupport "alphertech@gmail.com"
#define MyAppHelpline "+256 708 885 123"
#define MyAppLeadEngineers "Twale James Massete, Mugenyi Allan"
#define MyAppExeName "plexus.exe"
#define MyAppId "com.alphertech.plexus"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersionShort}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppPublisher}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=output
OutputBaseFilename=Plexus_Setup_v{#MyAppVersionShort}
SetupIconFile=..\runner\resources\app_icon.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64
LicenseFile=license.txt
AllowNoIcons=no
DisableProgramGroupPage=no
UninstallDisplayName={#MyAppName}
UninstallDisplaySize=1
UninstallDisplayIcon={app}\{#MyAppExeName}
CloseApplications=yes
CloseApplicationsFilter=application
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Installer
VersionInfoCopyright=Copyright (C) 2026 AlpherTech. All rights reserved.
; Uncomment when wizard images are available:
; WizardImageFile=wizard.bmp
; SmallBitmapImageFile=small.bmp

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Main application binaries (built from: flutter build windows --release)
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Visual C++ Redistributable dependency (bundled for self-contained deployment)
Source: "vc_redist.x64.exe"; DestDir: {tmp}; Flags: dontcopy

; License and terms documents
Source: "license.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "terms.txt"; DestDir: "{app}"; Flags: ignoreversion

[Run]
; Install VC++ Redistributable if not already present
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; Flags: waituntilterminated postinstall skipifdoesntexist; Check: not VCRedistInstalled

; Launch the application after install (unless silent)
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Icons]
; Start Menu entry
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}\data"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
; Desktop shortcut
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; WorkingDir: "{app}\data"

[Registry]
; Application information in registry
Root: HKLM; SubKey: "SOFTWARE\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
Root: HKLM; SubKey: "SOFTWARE\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "Version"; ValueData: "{#MyAppVersionShort}"
Root: HKLM; SubKey: "SOFTWARE\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "Developer"; ValueData: "{#MyAppPublisher}"
Root: HKLM; SubKey: "SOFTWARE\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "LeadEngineers"; ValueData: "{#MyAppLeadEngineers}"
Root: HKLM; SubKey: "SOFTWARE\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "SupportEmail"; ValueData: "{#MyAppSupport}"
Root: HKLM; SubKey: "SOFTWARE\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "Helpline"; ValueData: "{#MyAppHelpline}"
Root: HKLM; SubKey: "SOFTWARE\{#MyAppPublisher}\{#MyAppName}"; ValueType: string; ValueName: "Website"; ValueData: "{#MyAppURL}"

; Add/Remove Programs (uninstall) entry is created automatically by Inno Setup
; from AppId — writing a manual entry here would duplicate it.

[UninstallDelete]
; Remove the entire installation directory
Type: filesandordirs; Name: "{app}"

[Code]
// Check if Visual C++ 2015-2022 Redistributable (x64) is installed
function VCRedistInstalled: Boolean;
var
  Uninstall: String;
begin
  Result := RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EB6A5C78-F1C2-43A5-BD2D-7E3C68D6A3F1}_is1', 'DisplayName', Uninstall) or
            RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{C9F5C8BC-4D5E-4FDB-B7E8-7B3F2A3B4D5E}', 'DisplayName', Uninstall);
end;

// Helper function to check if application is running
function IsAppRunning(const ExeName: String): Boolean;
var
  ResultCode: Integer;
begin
  Result := False;
  Exec('cmd.exe', '/C "tasklist /FI ""IMAGENAME eq ' + ExeName + '"" | find /I /C ""' + ExeName + '"""', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := (ResultCode = 0);
end;

// Pre-installation validation
function InitializeSetup(): Boolean;
var
  Response: Integer;
begin
  Result := True;

  // Check architecture
  if not Is64BitInstallMode then
  begin
     MsgBox('Plexus requires a 64-bit version of Windows.' + #13#10 +
           'This installer cannot continue on 32-bit systems.', mbError, MB_OK);
    Result := False;
    Exit;
  end;

  // Check if already installed
  if RegKeyExists(HKLM, 'SOFTWARE\{#MyAppPublisher}\{#MyAppName}') then
  begin
    Response := MsgBox('An existing installation of {#MyAppName} was detected.' + #13#10 +
                       'Do you want to reinstall/upgrade the application?' + #13#10 +
                       'Your data will be preserved.', mbConfirmation, MB_YESNO);
    if Response <> IDYES then
    begin
      Result := False;
      Exit;
    end;
  end;

  // Check if application is running
  if IsAppRunning('{#MyAppExeName}') then
  begin
    MsgBox('Please close {#MyAppName} before installing the new version.' + #13#10 +
           'The installer will now close.', mbError, MB_OK);
    Result := False;
    Exit;
  end;
end;

// Post-installation: show support info
procedure CurPageChanged(CurPageID: Integer);
begin
  if (CurPageID = wpFinished) then
  begin
    MsgBox('Plexus v{#MyAppVersionShort} has been installed successfully.' + #13#10#13#10 +
           'Developer: {#MyAppPublisher}' + #13#10 +
           'Lead Engineers: {#MyAppLeadEngineers}' + #13#10 +
           'Support Email: {#MyAppSupport}' + #13#10 +
           'Helpline: {#MyAppHelpline}' + #13#10 +
           'Website: {#MyAppURL}' + #13#10#13#10 +
           'You can launch the application from the Start Menu or Desktop shortcut.' + #13#10 +
           'Thank you for choosing Plexus!', mbInformation, MB_OK);
  end;
end;
