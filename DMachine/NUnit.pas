unit NUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs;

type
  T2Dimensi=array of array of double;
  T1Dimensi=array of double;
  TForm1 = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  numInput,numHidden,numOutput:integer;
  inputs,hBiases,hOutputs,oBiases,outputs,oGrads,hGrads,hPrevBiasesDelta,oPrevBiasesDelta:T1Dimensi;
  ihWeights,hoWeights,ihPrevWeightsDelta,hoPrevWeightsDelta:T2Dimensi;

implementation

uses Math;

{$R *.dfm}
//--------------------FUNGSI AKTIVASI--------------------
function f(x:double):double;
begin
  result:= (1.0/(1.0+ (exp(-x))));
end;

function derivative(x:double):double;
begin
  result:= (x* (1-x));
end;
//-------------------------------------------------------

//------------------Init Awal----------------------------
procedure initBP(jumInput,jumHidden,jumOutput:integer);
begin
numInput:=jumInput;
numHidden:=jumHidden;
numOutput:=numOutput;

SetLength(inputs,numInput);

SetLength(ihWeights,numInput,numHidden);
SetLength(hBiases,numHidden);
SetLength(hOutputs,numHidden);

SetLength(hoWeights,numHidden,numOutput);
SetLength(oBiases,numOutput);

SetLength(outputs,numOutput);

SetLength(hGrads,numHidden);
SetLength(oGrads,numOutput);

SetLength(ihPrevWeightsDelta,numInput,numHidden);
SetLength(hPrevBiasesDelta,numHidden);
SetLength(hoPrevWeightsDelta,numHidden,numOutput);
SetLength(oPrevBiasesDelta,numOutput);

end;
//-------------------------------------------------------

//-----------------------SET WEIGHTS---------------------
procedure SetWeights(weights:T1Dimensi);
var numWeights,k,i,j:integer;
begin
    numWeights := (numInput * numHidden) + (numHidden * numOutput) + numHidden + numOutput;

    k:=0;
    // 1. Set Bobot input to hidden layer
    for i:=0 to numInput-1 do
    begin
        for j:=0 to numHidden-1 do
        begin
            ihWeights[i][j] := weights[k+1];
        end;
    end;
    // 2. Set Bobot bias to hidden layer
    for i:=0 to numHidden-1 do
    begin
         hBiases[i] := weights[k+1];
    end;
    // 3. Set Bobot hidden to output layer
    for i:=0 to numHidden-1 do
    begin
        for j:=0 to numOutput-1 do
        begin
            hoWeights[i][j] := weights[k+1];
        end;
    end;
    // 4. Set Bobot bias to output
    for i:=0 to numOutput-1 do
    begin
         oBiases[i] := weights[k+1];
    end;
end;
//-------------------------------------------------------

//------------------Inisialisasi Bobot From DB-----------
procedure initWeightDB(oldWeights:T1Dimensi);
var
 i:integer;
 numweights:integer;
 initialWeights:T1Dimensi;
begin
    numweights := (numInput * numHidden) + (numHidden * numOutput) + numHidden + numOutput;
    SetLength(initialWeights,numweights);
    for i:=0 to numweights-1 do
    begin
         initialWeights[i] := oldWeights[i];
    end;
    SetWeights(initialWeights);
end;
//-------------------------------------------------------

//--------------------Inisialisasi Random Value----------
procedure initRandom;
var
 i:integer;
 numweights:integer;
 initialWeights:T1Dimensi;
begin
    numweights := (numInput * numHidden) + (numHidden * numOutput) + numHidden + numOutput;
    SetLength(initialWeights,numweights);
    for i:=0 to numweights-1 do
    begin
        initialWeights[i]:=0.1;
    end;
    SetWeights(initialWeights);
end;
//-------------------------------------------------------
//------------------Ambil Bobot Habis Training-----------
function GetWeights:T1Dimensi;
var
numweights:integer;
hasil:T1Dimensi;
i,k,j:integer;
begin
   numWeights := (numInput * numHidden) + (numHidden * numOutput) + numHidden + numOutput;
   SetLength(hasil,numweights);
   k:=0;
   //1. Ambil Bobot input to Hidden
   for i:=0 to length(ihWeights)-1 do
   begin
        for j:=0 to length(ihWeights[0])-1 do
        begin
            hasil[k+1]:=ihWeights[i][j];
        end;
   end;
   //2. Ambil Bobot Bias weight to Hidden
   for i:=0 to length(hBiases)-1 do
   begin
      hasil[k+1]:=hBiases[i];
   end;
   //3. Ambil Bobot Hidden to Output
   for i:=0 to length(hoWeights)-1 do
   begin
      for j:=0 to length(hoWeights[0])-1 do
      begin
          hasil[k+1]:=hoWeights[i][j];
      end;
   end;
   //4. Ambil BBobot Bias Hidden to Ouput
   for i:=0 to length(oBiases)-1 do
   begin
      hasil[k+1]:=oBiases[i];
   end;
   result:=hasil;
end;
//------------------------------------------------------
function ComputeOutputs(xValues:T1Dimensi):T1Dimensi;
var
hsums,osums,_y,retResults:T1Dimensi;
i,j:integer;
begin
    SetLength(hsums,numHidden);
    SetLength(osums,numOutput);
    // --------Ambil Input --------
    for i:=0 to Length(xValues)-1 do
    begin
        inputs[i]:= xValues[i];
    end;

    //1. Hitung Total (input*weights)
    for j:=0 to numHidden-1 do
    begin
        for i:=0 to numInput-1 do
        begin
            hsums[j]:=hsums[j]+ (inputs[i]* ihWeights[i][j]);
        end;
    end;

    //2. Hitung Total (Bias * BiasWeights)
    for i:=0 to numHidden-1 do
    begin
        hsums[i]:=hsums[i]+ (hBiases[i]);
    end;
    //3. Hitung Z menggunakan aktivasi
    for i:=0 to numHidden-1 do
    begin
        hOutputs[i]:=f(hsums[i]);
    end;
    //4. Hitung Total(Hidden to Ouput)
    for j:=0 to numOutput-1 do
    begin
        for i:=0 to numHidden-1 do
        begin
            osums[j]:=osums[j]+ (hOutputs[i]*hoWeights[i][j]);
        end;
    end;
    //5. Hitung Total Bias Hidden to Ouput
    for i:=0 to numOutput-1 do
    begin
         osums[i]:=osums[i]+ (oBiases[i]);
    end;
    //6. Hitung yValues
    SetLength(_y,Length(osums));
    for i:=0 to numOutput-1 do
    begin
        _y[i]:=f(osums[i]);
    end;
    outputs:=copy(_y,0,length(_y));
    SetLength(retResults,numOutput);
    retResults:=copy(outputs,0,length(retResults));
    result:=retResults;
end;
//-------------------Update Bobot------------------------
procedure UpdateWeights(tValues:T1Dimensi;learnRate,momentum:double);
var i,j,k:integer;
sum,x,delta:double;
begin
  //1. Hitung Teta Output
  for i:=0 to length(oGrads)-1 do
  begin
      oGrads[i]:=derivative(outputs[i]) * (tValues[i] - outputs[i]);
  end;
  //2. Hitung Teta Hidden
  for i:=0 to length(hGrads)-1 do
  begin
      sum:=0;
      for j:=0 to numOutput-1 do
      begin
          x:=oGrads[j] * hoWeights[i][j];
          sum:=sum+x;
      end;
      hGrads[i] := derivative(hOutputs[i]) * sum;
  end;
  //3. Update Input-Hidden Weight
  for i:=0 to length(ihWeights)-1 do
  begin
      for j:=0 to length(ihWeights[0])-1 do
      begin
          delta:=0;
          delta := learnRate * hGrads[j] * inputs[i];
          ihWeights[i][j] := ihWeights[i][j]+delta;// Update
          ihWeights[i][j] := ihWeights[i][j]+(momentum * ihPrevWeightsDelta[i][j]);
          ihPrevWeightsDelta[i][j] := delta;
      end;
  end;
  //4. Update Hidden Bias
  for i:=0 to length(hBiases)-1 do
  begin
      delta:=0;
      delta := learnRate * hGrads[i] * 1.0;
      hBiases[i] :=hBiases[i]+ delta;
      hBiases[i] :=hBiases[i]+( momentum * hPrevBiasesDelta[i]);// add Momentum
      hPrevBiasesDelta[i] := delta;
  end;
  //5. Update Bobot Hidden to Ouput
  for i:=0 to length(hoWeights)-1 do
  begin
      for j:=0 to length(hoWeights[0])-1 do
      begin
          delta:=0;
          delta := learnRate * oGrads[j] * hOutputs[i];
          hoWeights[i][j] := hoWeights[i][j]+delta;
          hoWeights[i][j] :=hoWeights[i][j]+( momentum * hoPrevWeightsDelta[i][j]);// Momentum
          hoPrevWeightsDelta[i][j] := delta;
      end;
  end;
  //6. Update Output Bias
  for i:=0 to length(oBiases)-1 do
  begin
      delta:=0;
      delta := learnRate * oGrads[i] * 1.0;
      oBiases[i] :=oBiases[i]+ delta;
      oBiases[i] :=oBiases[i]+ (momentum * oPrevBiasesDelta[i]);//Momentum
      oPrevBiasesDelta[i] := delta;
  end;
end;
//-------------------------------------------------------

//--------------------- Hitung MSE ----------------------
function MSE(traindata:integer;xValues,tValues:T1Dimensi):double;
var
 sumError,err:double;
 yValues:T1Dimensi;
 i,j,k:integer;
begin
    sumError:=0.0;

    for i:=0 to traindata-1 do
    begin
        yValues:=ComputeOutputs(xValues);
        for j:=0 to numOutput-1 do
        begin
            err:=0;
            err := tValues[j] - yValues[j];
            sumError:=sumError+ Power(err,2);
        end;
    end;
    result:=(sumError/traindata);
end;
//-------------------------------------------------------


end.
