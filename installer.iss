; Plexus - Windows Installer Script (Inno Setup)
; Version: 3.2
; Developer: AlpherTech (https://alphertech.com/plexus)
; Lead Engineers: Twale James Massete, Mugenyi Allan
; Support: alphertech@gmail.com | Helpline: +256 708 885 123
;
; Build with: ISCC.exe installer.iss
; Requires Inno Setup 6.x (https://jrsoftware.org/isinfo.php)
; Output: output\Plexus_Setup_v3.2.exe
;

#define MyAppName "Plexus"
#define MyAppVersion "3.2.0"
#define MyAppVersionShort "3.2"
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
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
OutputDir=output
OutputBaseFilename=Plexus_Setup_v{#MyAppVersionShort}
SetupIconFile=windows\runner\resources\app_icon.ico
WizardStyle=modern
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog
ArchitecturesInstallIn64BitMode=x64os
CloseApplications=yes
CloseApplicationsFilter=application
DisableProgramGroupPage=no
UninstallDisplayName={#MyAppName}
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Installer
VersionInfoCopyright=Copyright (C) 2026 AlpherTech. All rights reserved.

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; Source MUST point to your Release folder
; The * means copy all files
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Visual C++ Redistributable dependency (bundled for self-contained deployment)
Source: "windows\installer\vc_redist.x64.exe"; DestDir: {tmp}; Flags: dontcopy

; License and terms documents
Source: "windows\installer\license.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "windows\installer\terms.txt"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
; Start Menu entry
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}\data"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
; Create Desktop shortcut
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

[UninstallDelete]
; Remove the entire installation directory
Type: filesandordirs; Name: "{app}"

[Run]
; Install VC++ Redistributable if not already present
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; Flags: waituntilterminated postinstall skipifdoesntexist; Check: not VCRedistInstalled

; Optional: Run your app after installation
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[Code]
// Check if Visual C++ 2015-2022 Redistributable (x64) is installed
function VCRedistInstalled: Boolean;
var
  Uninstall: String;
begin
  Result := RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{EB76D5A0-4831-4FDB-B7E8-7B3F2A3B4D5E}', 'DisplayName', Uninstall) or
            RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{C9F5C8BC-4D5E-4FDB-B7E8-7B3F2A3B4D5E}', 'DisplayName', Uninstall);
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
