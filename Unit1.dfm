object Form1: TForm1
  Left = 1514
  Top = 224
  Width = 864
  Height = 500
  Caption = 'Devices Manager'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar: TStatusBar
    Left = 0
    Top = 422
    Width = 848
    Height = 19
    Panels = <
      item
        Width = 150
      end
      item
        Width = 150
      end
      item
        Width = 150
      end>
  end
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 848
    Height = 422
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 1
    TabStop = False
    object TabSheet1: TTabSheet
      Caption = 'Device Information'
      object Splitter1: TSplitter
        Left = 233
        Top = 31
        Height = 363
      end
      object pnSetting: TPanel
        Left = 0
        Top = 0
        Width = 840
        Height = 31
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 0
        object cbShowHidden: TCheckBox
          Left = 8
          Top = 8
          Width = 129
          Height = 17
          Caption = 'Show Hidden Devices'
          TabOrder = 0
          OnClick = cbShowHiddenClick
        end
      end
      object tvDevices: TTreeView
        Left = 0
        Top = 31
        Width = 233
        Height = 363
        Align = alLeft
        Images = ilDevices
        Indent = 19
        ReadOnly = True
        RowSelect = True
        SortType = stText
        TabOrder = 1
        OnChange = tvDevicesChange
        OnCompare = tvDevicesCompare
      end
      object lvAdvancedInfo: TListView
        Left = 236
        Top = 31
        Width = 604
        Height = 363
        Align = alClient
        Columns = <
          item
            Caption = 'Name'
            Width = 150
          end
          item
            Caption = 'Data'
            Width = 300
          end>
        ReadOnly = True
        RowSelect = True
        SortType = stText
        TabOrder = 2
        ViewStyle = vsReport
        OnCompare = lvAdvancedInfoCompare
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Device Manager'
      ImageIndex = 1
      object TreeView: TTreeView
        Left = 0
        Top = 0
        Width = 840
        Height = 394
        Align = alClient
        Indent = 19
        ReadOnly = True
        TabOrder = 0
        OnChange = TreeViewChange
        OnDblClick = TreeViewDblClick
      end
    end
  end
  object ilDevices: TImageList
    DrawingStyle = dsTransparent
    ShareImages = True
    Left = 56
    Top = 96
  end
  object MainMenu: TMainMenu
    Left = 96
    Top = 96
    object mFile: TMenuItem
      Caption = '&File'
      object mExit: TMenuItem
        Caption = '&Exit'
        OnClick = mExitClick
      end
    end
    object mChange: TMenuItem
      Caption = '&Change'
      object mEnableDevice: TMenuItem
        Caption = '&Enable Device'
        Enabled = False
      end
      object mDisableDevice: TMenuItem
        Caption = '&Disable Device'
        Enabled = False
      end
      object mRemoveDevice: TMenuItem
        Caption = 'E&ject Device'
        Enabled = False
      end
    end
    object mOptions: TMenuItem
      Caption = '&Options'
      object mRefreshDisplay: TMenuItem
        Caption = 'Refresh Display'
        OnClick = mRefreshDisplayClick
      end
      object mN: TMenuItem
        Caption = '-'
      end
      object mShowHiddenDevices: TMenuItem
        Caption = '&Show hidden devices'
        OnClick = mShowHiddenDevicesClick
      end
    end
  end
  object ImageList: TImageList
    DrawingStyle = dsTransparent
    ShareImages = True
    Left = 16
    Top = 96
  end
end
