//+------------------------------------------------------------------+
//|                                               GoldMiner v2.0.mq5 |
//|                                          H4ck37, Copyright 2024. |
//|                                     https://github.com/hacker217 |
//+------------------------------------------------------------------+
#property copyright "H4ck37, Copyright 2024."
#property link      "https://github.com/hacker217"
#property version   "1.00"

string NamePart;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit(){

  NamePart = "MacdSell#";
  ChartSetInteger(0,CHART_EVENT_OBJECT_CREATE,true);
  

  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+

void OnDeinit(const int reason){

   
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick(){
   
  int total_objects = ObjectsTotal(OBJ_ARROW);
  Comment("Total number of objects on the chart: ", total_objects);

}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){
                  
  if(id==CHARTEVENT_OBJECT_CREATE){

    NewObject(sparam);
    return;
  }                   
}

//+------------------------------------------------------------------+

void NewObject(string name){

  if(StringSubstr(name,0,StringLen(NamePart))!=NamePart) return;

  int sub_window = ObjectFind(0,name);
  if(sub_window!=0) return;

  long type = ObjectGetInteger(0,name,OBJPROP_TYPE);
  if(type!=OBJ_ARROW) return;

  ReportObject("New",name);
}

void ReportObject(string event,string name){

  datetime object_time = (datetime)ObjectGetInteger(0,name,OBJPROP_TIME);
  ENUM_OBJECT object_type = (ENUM_OBJECT)ObjectGetInteger(0,name,OBJPROP_TYPE);
  int object_bar = iBarShift(Symbol(),Period(),object_time);
  double object_price = ObjectGetDouble(0,name,OBJPROP_PRICE);
  double bar_high = iHigh(Symbol(),Period(),object_bar);
  double bar_low = iLow(Symbol(),Period(),object_bar);

  Print("This is where you trade on your strategy using information from the objects");
  PrintFormat("Event = %s ",event);
  PrintFormat("Object Name = %s ",name);
  PrintFormat("Object Type = %s ",EnumToString(object_type));
  PrintFormat("Time = %s, Bar =%i, Price =%f, High =%f, Low =%f",TimeToString(object_time),object_bar,object_price,bar_high,bar_low);

}