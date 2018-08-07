unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,SynCrypto, StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);

   var
    PassW, FileName, Data, NewData, FilePath: string;
    i,j, CryptFiles,TotalFiles: integer;
    Digest: TSHA256Digest;
    F: TFileStream;
    A: TAESFull;
    FT: TFileTime;
   procedure NewFile;
     begin
       if FileExists(FileName) then begin
        F := TFileStream.Create(FileName,fmOpenWrite);
        F.Size := 0;
      end else
       F := TFileStream.Create(FileName,fmCreate);
   end;
procedure DoFile(Encrypt: boolean);
begin
  A.outStreamCreated := nil;
  F := TFileStream.Create(FileName,fmOpenRead);
  try
    GetFileTime(F.Handle,nil,nil,@FT);
    if A.EncodeDecode(Digest,256,F.Size,Encrypt,F,nil,nil,nil)<0 then
      MessageBox(Handle,PChar(Format(Msg[6],[FileName])),MsgP(4),0);
  finally
    F.Free;
  end;
end;
procedure WriteFile;
begin
  NewFile;
  with A.outStreamCreated do begin
    F.Write(Memory^,Size);
    Free;
  end;
  SetFileTime(F.Handle,nil,nil,@FT);
  F.Free;
end;
begin
  PassW := trim(Pass.Text);
  if PassW='' then exit;
  Hide;
  SHA256Weak(PassW,Digest);
  if Files.Count=0 then begin // Notepad version:
    FileName := ChangeFileExt(paramstr(0),'.crypt');
    if FileExists(FileName) then begin
      DoFile(false);
      if A.outStreamCreated=nil then begin
        Close;
        exit;
      end else
      with A.outStreamCreated do begin
        SetString(Data,PChar(Memory),Size);
        Free;
      end;
    end;
    with MemoForm do begin
      Memo.Text := Data;
      Caption := Label1.Caption;
      ShowModal;
      NewData := trim(Memo.Text);
      if (NewData<>Data) and (MessageBox(Handle,MSGP(7),MSGP(5),
        MB_ICONQUESTION or MB_YESNO)=IDYES) then begin
        NewFile;
        try
          A.EncodeDecode(Digest,256,length(NewData),true,nil,F,PChar(NewData),nil);
        finally
          F.Free;
        end;
      end;
    end;
  end else begin // multiple files:
    CryptFiles := 0;
    TotalFiles := Files.Count;
    for i := 0 to TotalFiles-1 do begin
      FileName := Files[i];
      if not FileExists(FileName) then begin
        dec(TotalFiles);
        Files[i] := '';
        continue;
      end;
      j := pos('.crypt',FileName);
      if j>0 then begin
        DoFile(false);
        if A.outStreamCreated=nil then begin
          dec(TotalFiles);
          Files[i] := '';
          continue;
        end;
        inc(CryptFiles);
        DeleteFile(FileName);
        SetLength(FileName,j-1);
        FilePath := extractFilePath(FileName);
        FileName := extractFileName(FileName);
        while FileExists(FilePath+FileName) do
          FileName := '~~'+FileName;
        FileName := FilePath+FileName;
        Files[i] := FileName;
        WriteFile;
      end;
    end;
    if TotalFiles>0 then
    if (CryptFiles=0) or (MessageBox(Handle,MSGP(8),
      MSGP(5),MB_ICONQUESTION or MB_YESNO)=IDYES) then begin
      for i := 0 to Files.Count-1 do begin
        FileName := Files[i];
        if (FileName='') or not FileExists(FileName) then continue;
        DoFile(true);
        assert(A.outStreamCreated<>nil);
        DeleteFile(FileName);
        repeat
          j := pos('~~',FileName);
          if j=0 then break else delete(FileName,j,2);
        until false;
        FileName := FileName+'.crypt';
        Writefile;
      end;
      if CryptFiles=0 then
        MessageBox(Handle,MSGP(9),MSGP(5),MB_ICONINFORMATION);
    end;
    Files.Clear;
  end;
  Close; // quit
end;

end;

end.
