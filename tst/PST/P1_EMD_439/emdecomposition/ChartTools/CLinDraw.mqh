﻿//------------------------------------------------------------------------------------
//                                                                        CLinDraw.mqh
//                                                                       2012, victorg
//                                                                 http://www.mql5.com
//------------------------------------------------------------------------------------
#property copyright "2012, victorg"
#property link      "http://www.mql5.com"

#include <Object.mqh>
#import "shell32.dll"
int ShellExecuteW(int hwnd,string lpOperation,string lpFile,string lpParameters,
                  string lpDirectory,int nShowCmd);
#import
#import "kernel32.dll"
int DeleteFileW(string lpFileName);
int MoveFileW(string lpExistingFileName,string lpNewFileName);
#import
//------------------------------------------------------------------------------------
// type = "line","spline","scatter"
// col  = "r,g,b,y"
// Leg  = "true","false"
// Reference: http://www.highcharts.com/
//------------------------------------------------------------------------------------
class CLinDraw:public CObject
  {
protected:
  int     Fhandle;           // File handle
  int     Num;               // Internal number of chart line
  string  Tit;               // Title chart
  string  SubTit;            // Subtitle chart
  string  Leg;               // Legend enable/disable
  string  Ytit;              // Title Y scale
  string  Xtit;              // Title X scale
  string  Fnam;              // File name
  
public:
  void    CLinDraw(void);
  void    Title(string s)      { Tit=s; }
  void    SubTitle(string s)   { SubTit=s; }
  void    Legend(string s)     { Leg=s; }
  void    YTitle(string s)     { Ytit=s; }
  void    XTitle(string s)     { Xtit=s; }
  int     AddGraph(double &y[],string type,string name,int w=0,string col="");
  int     AddGraph(double &x[],double &y[],string type,string name,int w=0,string col="");
  int     AddGraph(double &x[],double y,string type,string name,int w=0,string col="");
  int     LDraw(int ashow=1);
  };
//------------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------------
void CLinDraw::CLinDraw(void)
  {
  Num=0;
  Tit="";
  SubTit="";
  Leg="true";
  Ytit="";
  Xtit="";
  Fnam="CLinDraw.txt";
  Fhandle=FileOpen(Fnam,FILE_WRITE|FILE_TXT|FILE_ANSI);
  if(Fhandle<0)
    {
    Print(__FUNCTION__,": Error! FileOpen() error.");
    return;
    }
  FileSeek(Fhandle,0,SEEK_SET);                               // if file exist
  }
//------------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------------
int CLinDraw::AddGraph(double &y[],string type,string name,int w=0,string col="")
  {
  int i,k,n;
  string str;
  
  if(Fhandle<0)return(-1);
  if(Num==0)
    {
    str="$(document).ready(function(){\n"
    "var lp=new Highcharts.Chart({\n"
    "chart:{renderTo:'lplot'},\n"
    "exporting:{enabled:false},\n"
    "title:{text:'"+Tit+"'},\n"
    "subtitle:{text:'"+SubTit+"'},\n"
    "legend:{enabled:"+Leg+"},\n"
    "yAxis:{title:{text:'"+Ytit+"'}},\n"
    "xAxis:{title:{text:'"+Xtit+"'},showLastLabel:true},\n"
    "series:[\n";
    FileWriteString(Fhandle,str);
    }
  n=ArraySize(y);
  if(Num==0)str="{type:'"+type+"',name:'"+name+"',";
  else str=",{type:'"+type+"',name:'"+name+"',";
  if(col!="")str+="color:'rgba("+col+")',";
  if(w!=0)str+="lineWidth:"+(string)w+",";
  str+="data:[";
  k=0;
  for(i=0;i<n-1;i++)
    {
    str+=StringFormat("%.5g,",y[i]);
    if(20<k++){k=0; str+="\n";}
    }
  str+=StringFormat("%.5g]}\n",y[n-1]);
  FileWriteString(Fhandle,str);
  Num++;
  return(0);
  }
//------------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------------
int CLinDraw::AddGraph(double &x[],double &y[],string type,string name,int w=0,string col="")
  {
  int i,k,n;
  string str;
  
  if(Fhandle<0)return(-1);
  if(Num==0)
    {
    str="$(document).ready(function(){\n"
    "var lp=new Highcharts.Chart({\n"
    "chart:{renderTo:'lplot'},\n"
    "exporting:{enabled:false},\n"
    "title:{text:'"+Tit+"'},\n"
    "subtitle:{text:'"+SubTit+"'},\n"
    "legend:{enabled:"+Leg+"},\n"
    "yAxis:{title:{text:'"+Ytit+"'}},\n"
    "xAxis:{title:{text:'"+Xtit+"'},showLastLabel:true},\n"
    "series:[\n";
    FileWriteString(Fhandle,str);
    }
  n=ArraySize(x);
  if(Num==0)str="{type:'"+type+"',name:'"+name+"',";
  else str=",{type:'"+type+"',name:'"+name+"',";
  if(col!="")str+="color:'rgba("+col+")',";
  if(w!=0)str+="lineWidth:"+(string)w+",";
  str+="data:[";
  k=0;
  for(i=0;i<n-1;i++)
    {
    str+=StringFormat("[%.5g,%.5g],",x[i],y[i]);
    if(20<k++){k=0; str+="\n";}
    }
  str+=StringFormat("[%.5g,%.5g]]}\n",x[n-1],y[n-1]);
  FileWriteString(Fhandle,str);
  Num++;
  return(0);
  }
//------------------------------------------------------------------------------------
//
//------------------------------------------------------------------------------------
int CLinDraw::AddGraph(double &x[],double y,string type,string name,int w=0,string col="")
  {
  int i,k,n;
  string str;
  
  if(Fhandle<0)return(-1);
  if(Num==0)
    {
    str="$(document).ready(function(){\n"
    "var lp=new Highcharts.Chart({\n"
    "chart:{renderTo:'lplot'},\n"
    "exporting:{enabled:false},\n"
    "title:{text:'"+Tit+"'},\n"
    "subtitle:{text:'"+SubTit+"'},\n"
    "legend:{enabled:"+Leg+"},\n"
    "yAxis:{title:{text:'"+Ytit+"'}},\n"
    "xAxis:{title:{text:'"+Xtit+"'},showLastLabel:true},\n"
    "series:[\n";
    FileWriteString(Fhandle,str);
    }
  n=ArraySize(x);
  if(Num==0)str="{type:'"+type+"',name:'"+name+"',";
  else str=",{type:'"+type+"',name:'"+name+"',";
  if(col!="")str+="color:'rgba("+col+")',";
  if(w!=0)str+="lineWidth:"+(string)w+",";
  str+="data:[";
  k=0;
  for(i=0;i<n-1;i++)
    {
    str+=StringFormat("[%.5g,%.5g],",x[i],y);
    if(20<k++){k=0; str+="\n";}
    }
  str+=StringFormat("[%.5g,%.5g]]}\n",x[n-1],y);
  FileWriteString(Fhandle,str);
  Num++;
  return(0);
  }
//------------------------------------------------------------------------------------
int CLinDraw::LDraw(int ashow=1)
  {
  int i,k;
  string pfnam,to,p[];
  
  FileWriteString(Fhandle,"]});\n});");
  if(Fhandle<0)return(-1);
  FileClose(Fhandle);
  
  pfnam=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\"+Fnam;
  k=StringSplit(MQL5InfoString(MQL5_PROGRAM_PATH),StringGetCharacter("\\",0),p);
  to="";
  for(i=0;i<k-1;i++)to+=p[i]+"\\";
  to+="ChartTools\\";                          // Folder name
  DeleteFileW(to+Fnam);
  MoveFileW(pfnam,to+Fnam);
  if(ashow==1)ShellExecuteW(NULL,"open",to+"LinDraw.htm",NULL,NULL,1);
  return(0);
  }
//------------------------------------------------------------------------------------
