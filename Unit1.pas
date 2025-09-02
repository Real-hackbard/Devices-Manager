unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, ImgList, SetupAPI, DeviceHelper,
  Menus;

const
  CfgMgr32ModuleName        = 'cfgmgr32.dll';
  SetupApiModuleName        = 'SetupApi.dll';
  REGSTR_VAL_NODISPLAYCLASS = 'NoDisplayClass';
  CR_SUCCESS                = $00000000;
  CR_REMOVE_VETOED          = $00000017;
  DN_HAS_PROBLEM            = $00000400;
  DN_DISABLEABLE            = $00002000;
  DN_REMOVABLE              = $00004000;
  DN_NO_SHOW_IN_DM          = $40000000;
  CM_PROB_DISABLED          = $00000016;
  CM_PROB_HARDWARE_DISABLED = $0000001D;
type
  _PNP_VETO_TYPE = (
     PNP_VetoTypeUnknown,
     PNP_VetoLegacyDevice,
     PNP_VetoPendingClose,
     PNP_VetoWindowsApp,
     PNP_VetoWindowsService,
     PNP_VetoOutstandingOpen,
     PNP_VetoDevice,
     PNP_VetoDriver,
     PNP_VetoIllegalDeviceRequest,
     PNP_VetoInsufficientPower,
     PNP_VetoNonDisableable,
     PNP_VetoLegacyDriver
  );
  PNP_VETO_TYPE = _PNP_VETO_TYPE;
  PPNP_VETO_TYPE = ^_PNP_VETO_TYPE;
  TPNPVetoType = _PNP_VETO_TYPE;
  PPNPVetoType = PPNP_VETO_TYPE;
  function CM_Get_DevNode_Status(pulStatus: PULong; pulProblemNumber: PULong;
  dnDevInst: DWord; ulFlags: ULong): DWord; stdcall;
  external CfgMgr32ModuleName name 'CM_Get_DevNode_Status';
  function CM_Request_Device_Eject(dnDevInst: DWord; out pVetoType: TPNPVetoType;
  pszVetoName: PChar; ulNameLength: ULong; ulFlags: ULong): DWord; stdcall;
  external SetupApiModuleName name 'CM_Request_Device_EjectA';

type
  TForm1 = class(TForm)
    ilDevices: TImageList;
    StatusBar: TStatusBar;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    pnSetting: TPanel;
    cbShowHidden: TCheckBox;
    tvDevices: TTreeView;
    lvAdvancedInfo: TListView;
    MainMenu: TMainMenu;
    mFile: TMenuItem;
    mExit: TMenuItem;
    mChange: TMenuItem;
    mEnableDevice: TMenuItem;
    mDisableDevice: TMenuItem;
    mRemoveDevice: TMenuItem;
    mOptions: TMenuItem;
    mRefreshDisplay: TMenuItem;
    mN: TMenuItem;
    mShowHiddenDevices: TMenuItem;
    TreeView: TTreeView;
    ImageList: TImageList;
    Splitter1: TSplitter;
    procedure FormCreate(Sender: TObject);
    procedure cbShowHiddenClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tvDevicesCompare(Sender: TObject; Node1, Node2: TTreeNode;
      Data: Integer; var Compare: Integer);
    procedure lvAdvancedInfoCompare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
    procedure tvDevicesChange(Sender: TObject; Node: TTreeNode);
    procedure FormDestroy(Sender: TObject);
    procedure mExitClick(Sender: TObject);
    procedure mRefreshDisplayClick(Sender: TObject);
    procedure mShowHiddenDevicesClick(Sender: TObject);
    procedure TreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure TreeViewDblClick(Sender: TObject);
    procedure ChangeEnableDevice(Sender: TObject);
    procedure ChangeDisableDevice(Sender: TObject);
    procedure EjectDevice(Sender: TObject);
  private
    hAllDevices: HDEVINFO;
    ClassImageListData: TSPClassImageListData;
    DeviceHelper: TDeviceHelper;

    procedure InitImageList;
    procedure ReleaseImageList;
    function FindRootNode(const DeviceClassName: String): TTreeNode;
  public
    DevInfo: hDevInfo;
    //ClassImageListData: TSPClassImageListData;
    ShowHidden: Boolean;
    function CheckStatus(SelectedItem: DWord; hDevInfo: hDevInfo; StatusFlag: LongWord): Boolean;
    function IsDisabled(SelectedItem: DWord; hDevInfo: hDevInfo): Boolean;
    function StateChange(NewState: DWord; SelectedItem: DWord; hDevInfo: hDevInfo): Boolean;
    function GetRegistryProperty(PnPHandle: hDevInfo; DevData: TSPDevInfoData;
             Prop: DWord; Buffer: PChar; dwLength: DWord): Boolean;
    function ConstructDeviceName(DeviceInfoSet: hDevInfo;
             DeviceInfoData: TSPDevInfoData; Buffer: PChar; dwLength: DWord): Boolean;
    function IsClassHidden(ClassGuid: TGuid): Boolean;
    function EnumAddDevices(ShowHidden: Boolean; hwndTree: TTreeView; DevInfo: hDevInfo): Boolean;
    function GetClassImageIndex(ClassGuid: TGuid; Index: PInt): Boolean;
    procedure WMDeviceChange(var Msg: TMessage); message WM_DEVICECHANGE;
    procedure GetDevInfo;


    procedure InitDeviceList;
    procedure FillDeviceList;
    procedure ReleaseDeviceList;
    procedure ShowDeviceAdvancedInfo(const DeviceIndex: Integer);
    procedure ShowDeviceInterfaces(const DeviceIndex: Integer);
    function GetDeviceImageIndex(DeviceGUID: TGUID): Integer;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses
  ListViewHelper;

{ TdlgMain }
procedure TForm1.ChangeDisableDevice(Sender: TObject);
begin
  if (MessageBox(Handle, 'Disable this Device?', 'Change Device Status', MB_OKCANCEL) = IDOK) then
  begin
    if (StateChange(DICS_DISABLE, TreeView.Selected.Index, DevInfo)) then EnumAddDevices(ShowHidden, TreeView, DevInfo);
  end;
end;

procedure TForm1.ChangeEnableDevice(Sender: TObject);
begin
  if (MessageBox(Handle, 'Enable this Device?', 'Change Device Status', MB_OKCANCEL) = IDOK) then
  begin
    if (StateChange(DICS_ENABLE, TreeView.Selected.Index, DevInfo)) then EnumAddDevices(ShowHidden, TreeView, DevInfo);
  end;
end;

function TForm1.CheckStatus(SelectedItem: DWord; hDevInfo: hDevInfo; StatusFlag: LongWord): Boolean;
var
  DeviceInfoData: TSPDevInfoData;
  Status, Problem: DWord;
begin
  DeviceInfoData.cbSize := SizeOf(TSPDevInfoData);
  if (not SetupDiEnumDeviceInfo(hDevInfo, SelectedItem, DeviceInfoData)) then
  begin
    Result := false;
    exit;
  end;
  if (CM_Get_DevNode_Status(@Status, @Problem, DeviceInfoData.DevInst, 0) <> CR_SUCCESS) then
  begin
    Result := false;
    exit;
  end;
  Result := ((Status and StatusFlag = StatusFlag) and not (CM_PROB_HARDWARE_DISABLED = Problem));
end;
function TForm1.IsDisabled(SelectedItem: DWord; hDevInfo: hDevInfo): Boolean;
var
  DeviceInfoData: TSPDevInfoData;
  Status, Problem: DWord;
begin
  DeviceInfoData.cbSize := SizeOf(TSPDevInfoData);
  if (not SetupDiEnumDeviceInfo(hDevInfo, SelectedItem, DeviceInfoData)) then
  begin
    Result := false;
    exit;
  end;
  if (CM_Get_DevNode_Status(@Status, @Problem, DeviceInfoData.DevInst, 0) <> CR_SUCCESS) then
  begin
    Result := false;
    exit;
  end;
  Result := ((Status and DN_HAS_PROBLEM = DN_HAS_PROBLEM) and (CM_PROB_DISABLED = Problem));
end;
function TForm1.StateChange(NewState: DWord; SelectedItem: DWord; hDevInfo: hDevInfo): Boolean;
var
  PropChangeParams: TSPPropChangeParams;
  DeviceInfoData: TSPDevInfoData;
begin
  PropChangeParams.ClassInstallHeader.cbSize := SizeOf(TSPClassInstallHeader);
  DeviceInfoData.cbSize := SizeOf(TSPDevInfoData);
  if (not SetupDiEnumDeviceInfo(hDevInfo, SelectedItem, DeviceInfoData)) then
  begin
    Result := false;
    ShowMessage('EnumDeviceInfo');
    exit;
  end;
  PropChangeParams.ClassInstallHeader.InstallFunction := DIF_PROPERTYCHANGE;
  PropChangeParams.Scope := DICS_FLAG_GLOBAL;
  PropChangeParams.StateChange := NewState;
  if (not SetupDiSetClassInstallParams(hDevInfo, @DeviceInfoData,
     PSPClassInstallHeader(@PropChangeParams), SizeOf(PropChangeParams))) then
  begin
    Result := false;
    ShowMessage('SetClassInstallParams');
    exit;
  end;
  if (not SetupDiCallClassInstaller(DIF_PROPERTYCHANGE, hDevInfo, @DeviceInfoData)) then
  begin
    Result := false;
    ShowMessage('SetClassInstallParams');
    exit;
  end;
  Result := true;
end;
function TForm1.GetClassImageIndex(ClassGuid: TGuid; Index: PInt): Boolean;
begin
  Result := SetupDiGetClassImageIndex(ClassImageListData, ClassGuid, Index^);
end;
function TForm1.GetRegistryProperty(PnPHandle: hDevInfo; DevData: TSPDevInfoData; Prop: DWord; Buffer: PChar; dwLength: DWord): Boolean;
var
  aBuffer: array[0..256] of Char;
begin
  dwLength := 0;
  aBuffer[0] := #0;
  SetupDiGetDeviceRegistryProperty(PnPHandle, DevData, Prop, Prop, PBYTE(@aBuffer[0]), SizeOf(aBuffer), dwLength);
  StrCopy(Buffer, aBuffer);
  Result := Buffer^ <> #0;
end;
function TForm1.ConstructDeviceName(DeviceInfoSet: hDevInfo;
         DeviceInfoData: TSPDevInfoData; Buffer: PChar; dwLength: DWord): Boolean;
const
  UnknownDevice = '<Unknown Device>';
begin
  if (not GetRegistryProperty(DeviceInfoSet, DeviceInfoData, SPDRP_FRIENDLYNAME, Buffer, dwLength)) then
  begin
    if (not GetRegistryProperty(DeviceInfoSet, DeviceInfoData, SPDRP_DEVICEDESC, Buffer, dwLength)) then
    begin
      if (not GetRegistryProperty(DeviceInfoSet, DeviceInfoData, SPDRP_CLASS, Buffer, dwLength)) then
      begin
        if (not GetRegistryProperty(DeviceInfoSet, DeviceInfoData, SPDRP_CLASSGUID, Buffer, dwLength)) then
        begin
          dwLength := DWord(SizeOf(UnknownDevice));
          Buffer := Pointer(LocalAlloc(LPTR, Cardinal(dwLength)));
          StrCopy(Buffer, UnknownDevice);
        end;
      end;
    end;
  end;
  Result := true;
end;
function TForm1.IsClassHidden(ClassGuid: TGuid): Boolean;
var
  bHidden: Boolean;
  hKeyClass: HKey;
begin
  bHidden := false;
  hKeyClass := SetupDiOpenClassRegKey(@ClassGuid, KEY_READ);
  if (hKeyClass <> 0) then
  begin
    bHidden := (RegQueryValueEx(hKeyClass, REGSTR_VAL_NODISPLAYCLASS, nil, nil, nil, nil) = ERROR_SUCCESS);
    RegCloseKey(hKeyClass);
  end;
  Result := bHidden;
end;
function TForm1.EnumAddDevices(ShowHidden: Boolean; hwndTree: TTreeView; DevInfo: hDevInfo): Boolean;
var
  i, Status, Problem: DWord;
  pszText: PChar;
  DeviceInfoData: TSPDevInfoData;
  iImage: Integer;
begin
  TTreeView(hWndTree).Items.BeginUpdate;
  DeviceInfoData.cbSize := SizeOf(TSPDevInfoData);
  TTreeView(hWndTree).Items.Clear;
  i := 0;
  while SetupDiEnumDeviceInfo(DevInfo, i, DeviceInfoData) do
  begin
    inc(i);
    if (CM_Get_DevNode_Status(@Status, @Problem, DeviceInfoData.DevInst, 0) <> CR_SUCCESS) then
    begin
      break;
    end;
    if (not (ShowHidden or not(Boolean(Status and DN_NO_SHOW_IN_DM) or IsClassHidden(DeviceInfoData.ClassGuid)))) then
    begin
      break;
    end;
    GetMem(pszText, 256);
    try
      ConstructDeviceName(DevInfo, DeviceInfoData, pszText, DWord(nil));
      if (GetClassImageIndex(DeviceInfoData.ClassGuid, @iImage)) then
      begin
        with TTreeView(hWndTree).Items.AddObject(nil, pszText, nil) do
        begin
          TTreeView(hWndTree).Items[i-1].ImageIndex := iImage;
          TTreeView(hWndTree).Items[i-1].SelectedIndex := iImage;
        end;
        if (Problem = CM_PROB_DISABLED) then 
        begin
            TTreeView(hWndTree).Items[i-1].OverlayIndex := IDI_DISABLED_OVL - IDI_CLASSICON_OVERLAYFIRST;
        end else
        begin
          if (Boolean(Problem)) then 
          begin
              TTreeView(hWndTree).Items[i-1].OverlayIndex := IDI_PROBLEM_OVL - IDI_CLASSICON_OVERLAYFIRST;
          end;
        end;
        if (Status and DN_NO_SHOW_IN_DM = DN_NO_SHOW_IN_DM) then 
        begin
          TTreeView(hWndTree).Items[i-1].Cut := true;
        end;
      end;
    finally
      FreeMem(pszText);
    end;
  end;
  TTreeView(hWndTree).Items.EndUpdate;
  Result := true;
end;
procedure TForm1.GetDevInfo;
begin
  if (assigned(DevInfo)) then
  begin
    SetupDiDestroyDeviceInfoList(DevInfo);
    SetupDiDestroyClassImageList(ClassImageListData);
  end;
  DevInfo := SetupDiGetClassDevs(nil, nil, 0, DIGCF_PRESENT or DIGCF_ALLCLASSES);
  if (DevInfo = Pointer(INVALID_HANDLE_VALUE)) then
  begin
    ShowMessage('GetClassDevs');
    exit;
  end;
  ClassImageListData.cbSize := SizeOf(TSPClassImageListData);
  if (not SetupDiGetClassImageList(ClassImageListData)) then
  begin
    ShowMessage('GetClassImageList');
    exit;
  end;
  ImageList.Handle := ClassImageListData.ImageList;
  TreeView.Images := ImageList;
end;

procedure TForm1.cbShowHiddenClick(Sender: TObject);
begin
  tvDevices.Items.Clear;
  ReleaseDeviceList;
  InitDeviceList;
  FillDeviceList;
    
end;

procedure TForm1.FillDeviceList;
var
  dwIndex: DWORD;  
  DeviceInfoData: SP_DEVINFO_DATA;
  DeviceName, DeviceClassName: String;
  tvRoot: TTreeNode;
  ClassGUID: TGUID;
  DeviceClassesCount, DevicesCount: Integer;
begin

  tvDevices.Items.BeginUpdate;
  try
    dwIndex := 0;
    DeviceClassesCount := 0;
    DevicesCount := 0;

    ZeroMemory(@DeviceInfoData, SizeOf(SP_DEVINFO_DATA));
    DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);
    while SetupDiEnumDeviceInfo(hAllDevices, dwIndex, DeviceInfoData) do
    begin
      DeviceHelper.DeviceInfoData := DeviceInfoData;
      DeviceName := DeviceHelper.FriendlyName;
      if DeviceName = '' then
        DeviceName := DeviceHelper.Description;
      ClassGUID := DeviceHelper.ClassGUID;
      DeviceClassName := DeviceHelper.DeviceClassDescription(ClassGUID);
      tvRoot := FindRootNode(DeviceClassName);
      if tvRoot = nil then
      begin
        tvRoot := tvDevices.Items.Add(nil, DeviceClassName);
        tvRoot.ImageIndex :=
          GetDeviceImageIndex(ClassGUID);
        tvRoot.SelectedIndex := tvRoot.ImageIndex;
        tvRoot.StateIndex := -1;
        Inc(DeviceClassesCount);
      end;

      with tvDevices.Items.AddChild(tvRoot, DeviceName) do
      begin
        ImageIndex :=
          GetDeviceImageIndex(DeviceInfoData.ClassGuid);
        SelectedIndex := ImageIndex;
        StateIndex := Integer(dwIndex);
        Inc(DevicesCount);
      end;

      Inc(dwIndex);
    end;

    tvDevices.AlphaSort;
    StatusBar.Panels[0].Text := 'DeviceClasses Count: ' +
      IntToStr(DeviceClassesCount);
    StatusBar.Panels[1].Text := 'Devices Count: ' +
      IntToStr(DevicesCount);
    
  finally
    tvDevices.Items.EndUpdate;
  end;
end;

function TForm1.FindRootNode(const DeviceClassName: String): TTreeNode;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to tvDevices.Items.Count - 1 do
    if tvDevices.Items[I].Level = 0 then
      if tvDevices.Items[I].Text = DeviceClassName then
      begin
        Result := tvDevices.Items[I];
        Break;
      end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ReleaseImageList;
  DeviceHelper.Free;
  ReleaseDeviceList;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  if (not LoadSetupAPI) then
  begin
    ShowMessage('Could not load SetupAPI.dll');
    exit;
  end;
  DevInfo := nil;
  ShowHidden := false;
  GetDevInfo;
  EnumAddDevices(ShowHidden, TreeView, DevInfo);

  lvAdvancedInfo.DoubleBuffered := True;
  if not LoadSetupApi then
    RaiseLastOSError;
  DeviceHelper := TDeviceHelper.Create;
  InitImageList;
  InitDeviceList;
  FillDeviceList;
end;

function TForm1.GetDeviceImageIndex(DeviceGUID: TGUID): Integer;
begin
  Result := -1;
  SetupDiGetClassImageIndex(ClassImageListData, DeviceGUID, Result);
end;

procedure TForm1.InitDeviceList;
const
  PINVALID_HANDLE_VALUE = Pointer(INVALID_HANDLE_VALUE);
var
  dwFlags: DWORD;
begin
  dwFlags := DIGCF_ALLCLASSES;// or DIGCF_DEVICEINTERFACE;
  if not cbShowHidden.Checked then
    dwFlags := dwFlags or DIGCF_PRESENT;
  hAllDevices := SetupDiGetClassDevsExA(nil, nil, 0,
    dwFlags, nil, nil, nil);
  if hAllDevices = PINVALID_HANDLE_VALUE then RaiseLastOSError;
  DeviceHelper.DeviceListHandle := hAllDevices;
end;

procedure TForm1.InitImageList;
begin
  ZeroMemory(@ClassImageListData, SizeOf(TSPClassImageListData));
  ClassImageListData.cbSize := SizeOf(TSPClassImageListData);
  if SetupDiGetClassImageList(ClassImageListData) then
    ilDevices.Handle := ClassImageListData.ImageList;
end;

procedure TForm1.lvAdvancedInfoCompare(Sender: TObject; Item1,
  Item2: TListItem; Data: Integer; var Compare: Integer);
begin
  Compare := CompareText(Item1.Caption, Item2.Caption);
end;

procedure TForm1.ReleaseDeviceList;
begin
   SetupDiDestroyDeviceInfoList(hAllDevices);
end;

procedure TForm1.ReleaseImageList;
begin
  if not SetupDiDestroyClassImageList(ClassImageListData) then
    RaiseLastOSError;
end;

procedure TForm1.ShowDeviceAdvancedInfo(const DeviceIndex: Integer);

  procedure AddRow(ACaption, AData: String; const GroupID: Byte);
  begin
    if AData <> '' then
      ListView_AddItemsInGroup(lvAdvancedInfo, ACaption, AData, GroupID);
  end;

var
  DeviceInfoData: SP_DEVINFO_DATA;
  EmptyGUID, AGUID: TGUID;
  dwData: DWORD;
begin
  ZeroMemory(@EmptyGUID, SizeOf(TGUID));
  ZeroMemory(@DeviceInfoData, SizeOf(SP_DEVINFO_DATA));
  DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);
  if not SetupDiEnumDeviceInfo(hAllDevices,
    DeviceIndex, DeviceInfoData) then Exit;
  DeviceHelper.DeviceInfoData := DeviceInfoData;

  ListView_EnableGroupView(lvAdvancedInfo.Handle, True);
  ListView_InsertGroup(lvAdvancedInfo.Handle, 'SP_DEVINFO_DATA', 0);
  AddRow('Device Descriptiion', DeviceHelper.Description, 0);
  AddRow('Hardware IDs', DeviceHelper.HardwareID, 0);
  AddRow('Compatible IDs', DeviceHelper.CompatibleIDS, 0);
  AddRow('Driver', DeviceHelper.DriverName, 0);
  AddRow('Class name', DeviceHelper.DeviceClassName, 0);
  AddRow('Manufacturer', DeviceHelper.Manufacturer, 0);
  AddRow('Friendly Description', DeviceHelper.FriendlyName, 0);
  AddRow('Location Information', DeviceHelper.Location, 0);
  AddRow('Device CreateFile Name', DeviceHelper.PhisicalDriverName, 0);
  AddRow('Capabilities', DeviceHelper.Capabilities, 0);
  AddRow('Service', DeviceHelper.Service, 0);
  AddRow('ConfigFlags', DeviceHelper.ConfigFlags, 0);
  AddRow('UpperFilters', DeviceHelper.UpperFilters, 0);
  AddRow('LowerFilters', DeviceHelper.LowerFilters, 0);
  AddRow('LegacyBusType', DeviceHelper.LegacyBusType, 0);
  AddRow('Enumerator', DeviceHelper.Enumerator, 0);
  AddRow('Characteristics', DeviceHelper.Characteristics, 0);
  AddRow('UINumberDecription', DeviceHelper.UINumberDecription, 0);
  AddRow('PowerData', DeviceHelper.PowerData, 0);
  AddRow('RemovalPolicy', DeviceHelper.RemovalPolicy, 0);
  AddRow('RemovalPolicyHWDefault', DeviceHelper.RemovalPolicyHWDefault, 0);
  AddRow('RemovalPolicyOverride', DeviceHelper.RemovalPolicyOverride, 0);
  AddRow('InstallState', DeviceHelper.InstallState, 0);

  if not CompareMem(@EmptyGUID, @DeviceInfoData.ClassGUID,
    SizeOf(TGUID)) then
    AddRow('Device GUID', GUIDToString(DeviceInfoData.ClassGUID), 0);

  AGUID := DeviceHelper.BusTypeGUID;
  if not CompareMem(@EmptyGUID, @AGUID,
    SizeOf(TGUID)) then
    AddRow('Bus Type GUID', GUIDToString(AGUID), 0);

  dwData := DeviceHelper.UINumber;
  if dwData <> 0 then
    AddRow('UI Number', IntToStr(dwData), 0);

  dwData := DeviceHelper.BusNumber;
  if dwData <> 0 then
    AddRow('Bus Number', IntToStr(dwData), 0);

  dwData := DeviceHelper.Address;
  if dwData <> 0 then
    AddRow('Device Address', IntToStr(dwData), 0);

//  dwData := DeviceHelper.Security;
//  if dwData <> 0 then
//  AddRow('Security', IntToStr(dwData), 0);
//  AddRow('Device Type', DeviceHelper.DeviceType, 0);
//  AddRow('Exclusive', DeviceHelper.Exclusive, 0);
//  AddRow('SecuritySDS', DeviceHelper.SecuritySDS, 0);

  lvAdvancedInfo.AlphaSort;

end;

procedure TForm1.ShowDeviceInterfaces(const DeviceIndex: Integer);

  procedure AddRow(ACaption, AData: String; const GroupID: Byte);
  begin
    if AData <> '' then
      ListView_AddItemsInGroup(lvAdvancedInfo, ACaption, AData, GroupID);
  end;

var
  hInterfaces: HDEVINFO;
  DeviceInfoData: SP_DEVINFO_DATA;
  DeviceInterfaceData: TSPDeviceInterfaceData;
  I: Integer;
begin
  ListView_InsertGroup(lvAdvancedInfo.Handle, 'Interfaces Data', 1);
  ZeroMemory(@DeviceInfoData, SizeOf(SP_DEVINFO_DATA));
  DeviceInfoData.cbSize := SizeOf(SP_DEVINFO_DATA);
  ZeroMemory(@DeviceInterfaceData, SizeOf(TSPDeviceInterfaceData));
  DeviceInterfaceData.cbSize := SizeOf(TSPDeviceInterfaceData);
  if not SetupDiEnumDeviceInfo(hAllDevices,
    DeviceIndex, DeviceInfoData) then Exit;

  hInterfaces := SetupDiGetClassDevs(@DeviceInfoData.ClassGuid, nil, 0,
    DIGCF_PRESENT or DIGCF_INTERFACEDEVICE);
  if not Assigned(hInterfaces) then
      RaiseLastOSError;
  try
    I := 0;
    while SetupDiEnumDeviceInterfaces(hInterfaces, nil,
      DeviceInfoData.ClassGuid, I, DeviceInterfaceData) do
    begin
      case DeviceInterfaceData.Flags of
        SPINT_ACTIVE:
          AddRow('Interface State', 'SPINT_ACTIVE', 1);
        SPINT_DEFAULT:
          AddRow('Interface State', 'SPINT_DEFAULT', 1);
        SPINT_REMOVED:
          AddRow('Interface State', 'SPINT_REMOVED', 1);
      else
        AddRow('Interface State', 'unknown 0x' +
          IntToHex(DeviceInterfaceData.Flags, 8), 1);
      end;
      Inc(I);
    end;

  finally
    SetupDiDestroyDeviceInfoList(hInterfaces);
  end;

  AddRow('Flags', IntToStr(DeviceInterfaceData.Flags), 1);
end;

procedure TForm1.tvDevicesChange(Sender: TObject; Node: TTreeNode);
var
  ANode: TTreeNode;
begin
  lvAdvancedInfo.Items.BeginUpdate;
  try
    lvAdvancedInfo.Items.Clear;
    ANode := tvDevices.Selected;
    if Assigned(ANode) then
    begin
      if ANode.StateIndex >= 0 then
      begin
        ShowDeviceAdvancedInfo(ANode.StateIndex);
        ShowDeviceInterfaces(ANode.StateIndex);
        ANode := ANode.Parent;
      end;
      StatusBar.Panels[2].Text :=
        Format('Devices Count in DeviceClass "%s": %d',
          [ANode.Text, ANode.Count]);
    end;
  finally
    lvAdvancedInfo.Items.EndUpdate;
  end;
end;

procedure TForm1.tvDevicesCompare(Sender: TObject; Node1, Node2: TTreeNode;
  Data: Integer; var Compare: Integer);
begin
  Compare := CompareText(Node1.Text, Node2.Text);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  SetupDiDestroyDeviceInfoList(DevInfo);
  SetupDiDestroyClassImageList(ClassImageListData);
  UnloadSetupApi;
end;

procedure TForm1.mExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.mRefreshDisplayClick(Sender: TObject);
begin
  EnumAddDevices(ShowHidden, TreeView, DevInfo);
end;

procedure TForm1.mShowHiddenDevicesClick(Sender: TObject);
begin
  ShowHidden := not ShowHidden;
  MainMenu.Items[2][2].Checked := ShowHidden;
  EnumAddDevices(ShowHidden, TreeView, DevInfo);
end;

procedure TForm1.TreeViewChange(Sender: TObject; Node: TTreeNode);
begin
  with MainMenu, TreeView.Selected do
  begin
    Items[1][0].enabled := false;
    Items[1][1].enabled := false;
    Items[1][2].enabled := false;
    if (IsDisabled(Index, DevInfo)) then
    begin
      Items[1][0].enabled := true
    end else
    begin
      if (CheckStatus(Index, DevInfo, DN_DISABLEABLE)) then Items[1][1].enabled := true
    end;
    if (CheckStatus(Index, DevInfo, DN_REMOVABLE)) then
    begin
      Items[1][2].enabled := true;
    end;
  end;
end;

procedure TForm1.TreeViewDblClick(Sender: TObject);
begin
  with TreeView.Selected do
  begin
    if (IsDisabled(Index, DevInfo)) then
    begin
      ChangeEnableDevice(Self);
    end else
    begin
      if (CheckStatus(Index, DevInfo, DN_DISABLEABLE and DN_REMOVABLE)) then
      begin
        MessageBox(Handle, 'Device is disableable and ejectable. Please use MainMenu.', 'Change unknown', MB_OK);
      end
      else
      begin
        if (CheckStatus(Index, DevInfo, DN_DISABLEABLE)) then ChangeDisableDevice(Self);
        if (CheckStatus(Index, DevInfo, DN_REMOVABLE)) then EjectDevice(Self);
      end;
    end;
  end;
end;

procedure TForm1.EjectDevice(Sender: TObject);
var
  DeviceInfoData: TSPDevInfoData;
  Status, Problem: DWord;
  VetoType: TPNPVetoType;
  VetoName: array[0..256] of Char;
begin
  if (MessageBox(Handle, 'Eject this Device?', 'Eject Device', MB_OKCANCEL) = IDOK) then
  begin
    DeviceInfoData.cbSize := SizeOf(TSPDevInfoData);
    if (not SetupDiEnumDeviceInfo(DevInfo, TreeView.Selected.Index, DeviceInfoData)) then
    begin
      exit;
    end;
    if (CM_Get_DevNode_Status(@Status, @Problem, DeviceInfoData.DevInst, 0) <> CR_SUCCESS) then
    begin
      exit;
    end;
    VetoName[0] := #0;
    case CM_Request_Device_Eject(DeviceInfoData.DevInst, VetoType, @VetoName, SizeOf(VetoName), 0) of
      CR_SUCCESS:
      begin
        EnumAddDevices(ShowHidden, TreeView, DevInfo);
      end;
      CR_REMOVE_VETOED:
      begin
        MessageBox(Handle, PChar('Failed to eject the Device (Veto: ' + VetoName + ')'), 'Vetoed', MB_OK);
      end;
      else
      begin
        MessageBox(Handle, PChar('Failed to eject the Device (' + SysErrorMessage(GetLastError) + ')'), 'Failure', MB_OK);
      end;
    end;
  end;
end;

procedure TForm1.WMDeviceChange(var Msg: TMessage);
const
  DBT_DEVNODES_CHANGED = $0007;
begin
  case Msg.wParam of
    DBT_DEVNODES_CHANGED:
    begin
      GetDevInfo;
      EnumAddDevices(ShowHidden, TreeView, DevInfo);
    end;
  end;
end;

end.
