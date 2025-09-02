program DevicesManager;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  SetupApi in 'SetupApi.pas',
  ModuleLoader in 'ModuleLoader.pas',
  DeviceHelper in 'DeviceHelper.pas',
  Common in 'Common.pas',
  ListViewHelper in 'ListViewHelper.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
