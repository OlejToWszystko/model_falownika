unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Math;

type

  { TForm1 }

  TForm1 = class(TForm)
    kpEdit: TEdit;
    Label4: TLabel;
    nzadEdit: TEdit;
    Label3: TLabel;
    nminEdit: TEdit;
    nmaxEdit: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    saveCheckBox: TCheckBox;
    saveEdit: TEdit;
    stopButton: TButton;
    doneLabel: TLabel;
    done2Label: TLabel;
    symulacjaButton: TButton;
    readButton: TButton;
    Wykres: TShape;
    procedure FormCreate(Sender: TObject);
    procedure readButtonClick(Sender: TObject);
    procedure stopButtonClick(Sender: TObject);
    procedure symulacjaButtonClick(Sender: TObject);
    procedure rysujWykres();
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  p1 : Array[0..200] of Real;
  Mp1 : Array[0..200] of Real;
  n : Array[0..200] of Real;
  // zmienne do symulacji
  Mop, nsr : Real;
  nzad : Real;
  wzad, ws, ns, dws, Ew : Real;
  Mprop, Mcal, dMcal, Ms, dMs : Real;
  kp : Real = 0.34;
  Tc : Real = 0.018;
  Tz : Real = 0.001;
  Iz : Real = 0.002544;
  t, t1 : real;
  dt : real = 0.0001;
  dt1 : real = 0.02;
  tsym : real = 4;
  // zmienne do wykresu
  szer : Integer = 800;
  wys : Integer = 600;
  skt, skM, skn, ske : Real;
  Mmax : Real = 20;
  nmax, nmin : Real;


  plik1 : text;
  nazwa : string;


const
  qp = 5; // [cm^3/obr]

implementation

{$R *.lfm}

{ TForm1 }

procedure otw_plik;
  begin
    assignfile (plik1,nazwa);
    rewrite(plik1);
  end;

procedure TForm1.readButtonClick(Sender: TObject);
var
  i : Integer;
  s : string;
  plik : text;
begin
  AssignFile(plik, 'p600.txt');
  Reset(plik);

  for i:=0 to 200 do
  begin
    ReadLN(plik, s);
    p1[i]:=strtofloat(s);
    Mp1[i]:=((p1[i]*power(10,5))*qp*power(10,-6)/(2*pi))/0.96;
  end;

  AssignFile(plik, 'n600.txt');
  Reset(plik);

  for i:=0 to 200 do
  begin
    ReadLN(plik, s);
    n[i]:=strtofloat(s);
  end;
  doneLabel.Caption:='OK';
end;

procedure TForm1.stopButtonClick(Sender: TObject);
begin
  halt;
end;

procedure TForm1.symulacjaButtonClick(Sender: TObject);
var
  i : LongInt;
  j : LongInt;
  k : LongInt;
  Time, dTime : LongInt;
  pp : Real;
begin
  doneLabel.Caption:='';
  done2Label.Caption:='';
  // czyszczenie wykresu
  Wykres.Canvas.Rectangle(0,0,szer,wys);
  // wczytanie danych
  nmax:=strtofloat(nmaxEdit.Text);
  nmin:=strtofloat(nminEdit.Text);
  nzad:=strtofloat(nzadEdit.Text);
  kp:=strtofloat(kpEdit.Text);
  // obliczenia wstępne
  skt:=szer/tsym;
  skM:=wys/Mmax;
  skn:=wys/(nmax-nmin);
  k:=round(dt1/dt);
  dTime:=round(1/dt);
  wzad:=nzad*(2*pi/60);
  // warunki początkowe
  t:=0; i:=0; j:=0;
  Time:=0;
  ws:=wzad;
  Ms:=Mp1[0];
  Mcal:=Ms;
  if saveCheckBox.Checked then
  begin
    nazwa:=saveEdit.Text;
    otw_plik;
    writeln(plik1, 't':12,';','pp':12,';','Mop':12,
       ';','Ms':12,';','nsr':12,';','ns':12);
  end;

  // pętla symulacji
  repeat
    if i<200 then
       begin
       pp:= p1[i]+(p1[i+1]-p1[i])*(j/k);
       Mop:=Mp1[i]+(Mp1[i+1]-Mp1[i])*(j/k);
       nsr:=n[i]+(n[i+1]-n[i])*(j/k);
       end
       else
       begin
       pp:=p1[i];
       Mop:=Mp1[i];
       nsr:=n[i];
       end;
    ns:=ws*(30/pi);
    Ew:=wzad-ws;
    Mprop:=Ew*kp;
    dMcal:=(kp/Tc)*Ew;
    dMs:=(1/Tz)*Mprop+(1/Tz)*Mcal-(1/Tz)*Ms;
    dws:=(1/Iz)*(Ms-Mop);
    rysujWykres();
    Mcal:=Mcal+dMcal*dt;
    Ms:=Ms+dMs*dt;
    ws:=ws+dws*dt;
    if saveCheckBox.Checked then
       begin
       if (Time MOD 200) = 0 then writeln(plik1, t:12:7,';',pp:12:7,';',Mop:12:7,
       ';',Ms:12:7,';',nsr:12:7,';',ns:12:7);
       end;
    j:=j+1;
    Time:=Time+1;
    t:=Time/dTime;
    if j=k then
       begin
         i:=i+1;
         j:=0;
       end;
  until t>tsym;
  if saveCheckBox.Checked then
     begin
          writeln(plik1);
          writeln(plik1, 'kp':7,';','Tc':7,';','Tz':7,';','nzad':7,';','Iz':9);
          writeln(plik1,kp:7:3,';',Tc:7:3,';',Tz:7:3,';',nzad:7:0,';',Iz:9:6);
          closefile(plik1);
     end;
  done2Label.Caption:='OK';
end;

procedure TForm1.rysujWykres();
begin
  Wykres.Canvas.Pixels[round(t*skt), round(skM*(Mmax-Mop))]:=clblue;
  Wykres.Canvas.Pixels[round(t*skt), round(skM*(Mmax-Ms))]:=clgreen;
  Wykres.Canvas.Pixels[round(t*skt), round(skn*(nmax-ns))]:=clred;
  Wykres.Canvas.Pixels[round(t*skt), round(skn*(nmax-nsr))]:=clblue;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Wykres.Width:=szer;
  Wykres.Height:=wys;
end;

end.

