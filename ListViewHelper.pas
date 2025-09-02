unit ListViewHelper;

interface

uses
  Windows,
  Classes,
  ComCtrls,
  CommCtrl;

  procedure ListView_SetSelectedColumn(lvHvnd: THandle; iCol: Integer);
  procedure ListView_EnableGroupView(lvHvnd: THandle; fEnable: BOOL);
  procedure ListView_InsertGroup(lvHvnd: THandle; szCaption: String;
    byID: Byte; Align: TAlignment = taLeftJustify);
  procedure ListView_AddItemsInGroup(ListView: TListView;
    szCaption, szSubItems: String; byID: Byte);
  function ListView_GetItemGroup(lvHvnd: THandle; iIndex: Integer): Integer;

implementation

type
   TLVGROUP = record
     cbSize: UINT;
     mask: UINT;
     pszHeader: LPWSTR;
     cchHeader: Integer;
     pszFooter: LPWSTR;
     cchFooter: Integer;
     iGroupIdL: Integer;
     stateMask: UINT;
     state: UINT;
     uAlign: UINT;
   end;

   tagLVITEMA = packed record
     mask: UINT;
     iItem: Integer;
     iSubItem: Integer;
     state: UINT;
     stateMask: UINT;
     pszText: PAnsiChar;
     cchTextMax: Integer;
     iImage: Integer;
     lParam: lParam;
     iIndent: Integer;
     iGroupId: Integer;
     cColumns: UINT;
     puColumns: PUINT;
   end;
   TLVITEMA = tagLVITEMA;

const   
   LVM_SETSELECTEDCOLUMN  = LVM_FIRST + 140;
   LVM_INSERTGROUP        = LVM_FIRST + 145;
   LVM_MOVEITEMTOGROUP    = LVM_FIRST + 154;
   LVM_ENABLEGROUPVIEW    = LVM_FIRST + 157;

   LVIF_GROUPID = $0100;

   LVGF_HEADER  = $00000001;
   LVGF_FOOTER  = $00000002;
   LVGF_ALIGN   = $00000008;
   LVGF_GROUPID = $00000010;

   LVGA_HEADER_LEFT   = $00000001;
   LVGA_HEADER_CENTER = $00000002;
   LVGA_HEADER_RIGHT  = $00000004;

procedure ListView_SetSelectedColumn(lvHvnd: THandle; iCol: Integer);
begin
  SendMessage(lvHvnd, LVM_SETSELECTEDCOLUMN, iCol, 0);
end;

procedure ListView_EnableGroupView(lvHvnd: THandle; fEnable: BOOL);
begin
  SendMessage(lvHvnd, LVM_ENABLEGROUPVIEW, Integer(fEnable), 0);
end;

procedure ListView_InsertGroup(lvHvnd: THandle; szCaption: String;
  byID: Byte; Align: TAlignment = taLeftJustify);
var
  lvGroup: TLVGROUP;
begin
  FillChar(lvGroup, SizeOf(TLVGROUP), 0);
  with lvGroup do
  begin
    cbSize := SizeOf(TLVGROUP);
    mask := LVGF_HEADER or LVGF_FOOTER or LVGF_ALIGN or LVGF_GROUPID;
    pszHeader := StringToOleStr(szCaption);
    cchHeader := Length(szCaption);
    pszFooter := 'Device End';
    cchFooter := Length(pszFooter);
    iGroupIdL := byID;
    uAlign := LVGA_HEADER_LEFT;
    case Align of
      taLeftJustify:
        uAlign := LVGA_HEADER_LEFT;
      taRightJustify:
        uAlign := LVGA_HEADER_RIGHT;
      taCenter:
        uAlign := LVGA_HEADER_CENTER;
    end;
  end;
  SendMessage(lvHvnd, LVM_INSERTGROUP, 0, Longint(@lvGroup));
end;

procedure ListView_AddItemsInGroup(ListView: TListView; szCaption, szSubItems: String;
  byID: Byte);
var
  LvItemA: TLVITEMA;
begin
  with ListView.Items.Add do
  begin
    Caption := szCaption;
    SubItems.Text := szSubItems;
  end;
  FillChar(LvItemA, SizeOf(TLvItemA), 0);
  with LvItemA do
  begin
    mask := LVIF_GROUPID;
    iItem := ListView.Items.Count - 1;
    iGroupId := byID;
  end;
  SendMessage(ListView.Handle, LVM_SETITEM, 0, Longint(@LvItemA));
end;

function ListView_GetItemGroup(lvHvnd: THandle; iIndex: Integer): Integer;
var
  LvItemA: TLVITEMA;
begin
  FillChar(LvItemA, SizeOf(TLvItemA), 0);
  LvItemA.mask := LVIF_GROUPID;
  LvItemA.iItem := iIndex;
  SendMessage(lvHvnd, LVM_GETITEM, 0, Longint(@LvItemA));
  Result := LvItemA.iGroupId;
end;

end.
