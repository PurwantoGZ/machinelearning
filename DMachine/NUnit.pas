unit NUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  T2Dimensi=array of array of double;
  T1Dimensi=array of double;
  TForm1 = class(TForm)
    Terminal: TListBox;
    btnTrain: TButton;
    Terminal2: TListBox;
    ListBox1: TListBox;
    procedure btnTrainClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    
    procedure TrainDataBP(traindata:T2Dimensi;maxError:double;maxEpoch:integer;learnRate:double;momentum:double);
    procedure TestDataBP(testData:T2Dimensi);
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
numOutput:=jumOutput;

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
        initialWeights[i]:=Round((Random*1000))/1000;
        //initialWeights[i]:=1;
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
            Form1.ListBox1.Items.Add(floattostr(ihWeights[i][j]));
        end;
   end;
   //2. Ambil Bobot Bias weight to Hidden
   for i:=0 to length(hBiases)-1 do
   begin
      hasil[k+1]:=hBiases[i];
      Form1.ListBox1.Items.Add(floattostr(hBiases[i]));
   end;
   //3. Ambil Bobot Hidden to Output
   for i:=0 to length(hoWeights)-1 do
   begin
      for j:=0 to length(hoWeights[0])-1 do
      begin
          hasil[k+1]:=hoWeights[i][j];
          Form1.ListBox1.Items.Add(floattostr(hoWeights[i][j]));
      end;
   end;
   //4. Ambil BBobot Bias Hidden to Ouput
   for i:=0 to length(oBiases)-1 do
   begin
      hasil[k+1]:=oBiases[i];
      Form1.ListBox1.Items.Add(floattostr(oBiases[i]));
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
function MSE(traindata:T2Dimensi):double;
var
 sumError,err:double;
 yValues,xValues,tValues:T1Dimensi;
 i,j,k:integer;
begin
    sumError:=0.0;
    SetLength(tValues,numOutput);
    SetLength(xValues,numInput);

    for i:=0 to length(traindata)-1 do
    begin

        for j:=0 to numInput-1 do
        begin
            xValues[j]:=traindata[i][j];
        end;
        for k:=0 to numOutput-1 do
        begin
            tValues[k]:=traindata[i][k+numInput];
        end;
        yValues:=ComputeOutputs(xValues);
        for j:=0 to numOutput-1 do
        begin
            err:=0;
            err := tValues[j] - yValues[j];
            sumError:=sumError+ sqr(err);
        end;
    end;
    result:=(sumError/length(traindata));
end;
//-------------------------------------------------------
//---------------------TRAIN DATA -----------------------
procedure TForm1.TrainDataBP(traindata:T2Dimensi;maxError:double;maxEpoch:integer;learnRate:double;momentum:double);
var
epoch,i,j,k:integer;
Tmse:double;
xValues,tValues:T1Dimensi;
begin
Terminal.Items.Clear;
epoch:=0;
Tmse:=0;
SetLength(xValues,numInput);
SetLength(tValues,numOutput);
    repeat
    Inc(epoch);
    Tmse:=MSE(traindata);

    for i:=0 to length(traindata)-1 do
    begin
        for j:=0 to numInput-1 do
        begin
            xValues[j]:=traindata[i][j];
        end;
        for k:=0 to numOutput-1 do
        begin
            tValues[k]:=traindata[i][numInput+k];
        end;

        ComputeOutputs(xValues);
        UpdateWeights(tValues,learnRate,momentum);
    end;
    Terminal.Items.Add('iterasi-'+inttostr(epoch)+' MSE: '+floattostr(Tmse));
    until (epoch>maxEpoch) or (Tmse<maxError);
end;
//-------------------------------------------------------
//---------------------------TEST DATA TERLATIH----------
procedure TForm1.TestDataBP(testData:T2Dimensi);
var
yValues,xValues,tValues:T1Dimensi;
 i,j,k:integer;
begin
SetLength(xValues,numInput);
SetLength(tValues,numOutput);
Terminal2.Items.Clear;
 for i:=0 to length(testData)-1 do
 begin
      for j:=0 to numInput-1 do
      begin
        xValues[j]:=testData[i][j];
      end;
      for k:=0 to numOutput-1 do
      begin
        tValues[k]:=testData[i][numInput+k];
      end;
      yValues:=ComputeOutputs(xValues);
      for k:=0 to numOutput-1 do
      begin
        Terminal2.Items.Add(floattostr(yValues[k]));
      end;
      Terminal2.Items.add('---------------------------------');
 end;
end;
//-------------------------------------------------------

procedure TForm1.btnTrainClick(Sender: TObject);
var
traindata,testData:T2Dimensi;
newBobot:T1Dimensi;
numDataTraining,numColms,i,j:integer;
numInput,numHidden,numOutput,numBobot:integer;
begin
  numInput:=6;
  numHidden:=5;
  numOutput:=3;
  numDataTraining:=2;
  numColms:=numInput+numOutput;
  SetLength(traindata,numDataTraining,numColms);
  SetLength(testData,numDataTraining,numColms);

  traindata[0][0]:=0.1;
  traindata[0][1]:=0.2;
  traindata[0][2]:=0.3;
  traindata[0][3]:=0.4;
  traindata[0][4]:=0.1;
  traindata[0][5]:=0.2;
  traindata[0][6]:=0;//Target
  traindata[0][7]:=0;
  traindata[0][8]:=0;

  traindata[1][0]:=0.5;
  traindata[1][1]:=0.6;
  traindata[1][2]:=0.6;
  traindata[1][3]:=0.56;
  traindata[1][4]:=0.8;
  traindata[1][5]:=0.7;
  traindata[1][6]:=0;//Target
  traindata[1][7]:=0;
  traindata[1][8]:=1;

  testData:=traindata;
  // Buat BP
  initBP(numInput,numHidden,numOutput);
  initRandom;
  TrainDataBP(traindata,0.01,1000,0.6,0.1);
  TestDataBP(testData);

  numBobot := (numInput * numHidden) + (numHidden * numOutput) + numHidden + numOutput;
  SetLength(newBobot,numBobot);
  newBobot:=GetWeights;
  
end;



end.
