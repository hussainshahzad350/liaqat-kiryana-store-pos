#ifndef BundleDir
  #error BundleDir must point to the verified release bundle
#endif
#ifndef OutputDir
  #error OutputDir must point to the release output directory
#endif

[Setup]
AppId={{53462769-922B-4C19-AE10-FD9D75E2178C}
AppName=Liaqat Kiryana Store POS
AppVersion=1.0.0
AppPublisher=Liaqat Kiryana Store
DefaultDirName={localappdata}\Programs\LiaqatKiryanaStore
DefaultGroupName=Liaqat Kiryana Store POS
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=Liaqat-Kiryana-POS-1.0.0-Windows-x64-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\liaqat_kiryana_store_pos.exe
CloseApplications=yes
RestartApplications=no
SetupLogging=yes

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"

[Files]
Source: "{#BundleDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Liaqat Kiryana Store POS"; Filename: "{app}\liaqat_kiryana_store_pos.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\Liaqat Kiryana Store POS"; Filename: "{app}\liaqat_kiryana_store_pos.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\liaqat_kiryana_store_pos.exe"; WorkingDir: "{app}"; Description: "Open Liaqat Kiryana Store POS"; Flags: nowait postinstall skipifsilent

; No database is shipped. Runtime-created store files are deliberately absent
; from the uninstall list, so an uninstall/reinstall does not erase the store.
