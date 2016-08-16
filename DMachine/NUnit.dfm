object Form1: TForm1
  Left = 192
  Top = 125
  Width = 563
  Height = 451
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Terminal: TListBox
    Left = 8
    Top = 40
    Width = 249
    Height = 361
    ItemHeight = 13
    TabOrder = 0
  end
  object btnTrain: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnTrain'
    TabOrder = 1
    OnClick = btnTrainClick
  end
  object Terminal2: TListBox
    Left = 264
    Top = 40
    Width = 273
    Height = 137
    ItemHeight = 13
    TabOrder = 2
  end
  object ListBox1: TListBox
    Left = 264
    Top = 184
    Width = 273
    Height = 217
    ItemHeight = 13
    TabOrder = 3
  end
end
