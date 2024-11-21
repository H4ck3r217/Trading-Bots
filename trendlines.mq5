//+------------------------------------------------------------------+
//|                                        Indicator: trendlines.mq5 |
//|                                       Created with EABuilder.com |
//|                                        https://www.eabuilder.com |
//+------------------------------------------------------------------+
#property copyright "Created with EABuilder.com"
#property link      "https://www.eabuilder.com"
#property version   "1.00"
#property description ""

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 3
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 3
#property indicator_color2 0x0000FF
#property indicator_label2 "Sell"

#define PLOT_MAXIMUM_BARS_BACK 5000
#define OMIT_OLDEST_BARS 50

//--- indicator buffers
double Buffer1[];
double Buffer2[];

double myPoint; //initialized in OnInit
double Low[];
double High[];

void myAlert(string type, string message){
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | trendlines @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
}

void DrawLine(string objname, double price, int count, int start_index) //creates or modifies existing object if necessary
  {
   if((price < 0) && ObjectFind(0, objname) >= 0)
     {
      ObjectDelete(0, objname);
     }
   else if(ObjectFind(0, objname) >= 0 && ObjectGetInteger(0, objname, OBJPROP_TYPE) == OBJ_TREND)
     {
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, start_index+count, cTime);
      ObjectSetInteger(0, objname, OBJPROP_TIME, cTime[start_index]);
      ObjectSetDouble(0, objname, OBJPROP_PRICE, price);
      ObjectSetInteger(0, objname, OBJPROP_TIME, 1, cTime[start_index+count-1]);
      ObjectSetDouble(0, objname, OBJPROP_PRICE, 1, price);
     }
   else
     {
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, start_index+count, cTime);
      ObjectCreate(0, objname, OBJ_TREND, 0, cTime[start_index], price, cTime[start_index+count-1], price);
      ObjectSetInteger(0, objname, OBJPROP_RAY_LEFT, 0);
      ObjectSetInteger(0, objname, OBJPROP_RAY_RIGHT, 0);
      ObjectSetInteger(0, objname, OBJPROP_COLOR, C'0x00,0x00,0xFF');
      ObjectSetInteger(0, objname, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, objname, OBJPROP_WIDTH, 2);
     }
}

double Support(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {
   int start_index = shift;
   int count = time_interval / PeriodSeconds();
   if(fixed_tod)
     {
      datetime start_time;
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, Bars(Symbol(), Period())-count, cTime);
      if(shift == 0)
	     start_time = TimeCurrent();
      else
         start_time = cTime[shift-1];
      datetime dt = StringToTime(TimeToString(start_time, TIME_DATE)+" "+IntegerToString(hh)+":"+IntegerToString(mm)); //closest time hh:mm
      if (dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(Symbol(), Period(), dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > cTime[Bars(Symbol(), Period())-1-count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(Symbol(), Period(), dt, true);
        }
      if (dt_index < 0) //still not found => find nearest bar
         dt_index = iBarShift(Symbol(), Period(), dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double cLow[];
   ArraySetAsSeries(cLow, true);
   CopyLow(Symbol(), Period(), start_index, count, cLow);
   double ret = cLow[ArrayMinimum(cLow, 0, count)];
   if (draw) DrawLine("Support", ret, count, start_index);
   return(ret);
  }

double Resistance(int time_interval, bool fixed_tod, int hh, int mm, bool draw, int shift)
  {
   int start_index = shift;
   int count = time_interval / PeriodSeconds();
   if(fixed_tod)
     {
      datetime start_time;
      datetime cTime[];
      ArraySetAsSeries(cTime, true);
      CopyTime(Symbol(), Period(), 0, Bars(Symbol(), Period())-count, cTime);
      if(shift == 0)
	     start_time = TimeCurrent();
      else
         start_time = cTime[shift-1];
      datetime dt = StringToTime(TimeToString(start_time, TIME_DATE)+" "+IntegerToString(hh)+":"+IntegerToString(mm)); //closest time hh:mm
      if (dt > start_time)
         dt -= 86400; //go 24 hours back
      int dt_index = iBarShift(Symbol(), Period(), dt, true);
      datetime dt2 = dt;
      while(dt_index < 0 && dt > cTime[Bars(Symbol(), Period())-1-count]) //bar not found => look a few days back
        {
         dt -= 86400; //go 24 hours back
         dt_index = iBarShift(Symbol(), Period(), dt, true);
        }
      if (dt_index < 0) //still not found => find nearest bar
         dt_index = iBarShift(Symbol(), Period(), dt2, false);
      start_index = dt_index + 1; //bar after S/R opens at dt
     }
   double cHigh[];
   ArraySetAsSeries(cHigh, true);
   CopyHigh(Symbol(), Period(), start_index, count, cHigh);
   double ret = cHigh[ArrayMaximum(cHigh, 0, count)];
   if (draw) DrawLine("Resistance", ret, count, start_index);
   return(ret);
  }

double getBid()
  {
   MqlTick last_tick;
   SymbolInfoTick(Symbol(), last_tick);
   return(last_tick.bid);
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   SetIndexBuffer(0, Buffer1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
   PlotIndexSetInteger(0, PLOT_ARROW, 241);
   SetIndexBuffer(1, Buffer2);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
   PlotIndexSetInteger(1, PLOT_ARROW, 242);
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   ArraySetAsSeries(Buffer2, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
      ArrayInitialize(Buffer2, EMPTY_VALUE);
     }
   else
      limit++;
   
   if(CopyLow(Symbol(), PERIOD_CURRENT, 0, rates_total, Low) <= 0) return(rates_total);
   ArraySetAsSeries(Low, true);
   if(CopyHigh(Symbol(), PERIOD_CURRENT, 0, rates_total, High) <= 0) return(rates_total);
   ArraySetAsSeries(High, true);
   //--- main loop
   for(int i = limit-1; i >= 0; i--)
     {
      if (i >= MathMin(PLOT_MAXIMUM_BARS_BACK-1, rates_total-1-OMIT_OLDEST_BARS)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      
      //Indicator Buffer 1
      if(Support(15 * 60, false, 00, 00, false, i) > getBid()
      && Support(15 * 60, false, 00, 00, false, i+1) < getBid() //Support crosses above Price
      )
        {
         Buffer1[i] = Low[i]; //Set indicator value at Candlestick Low
        }
      else
        {
         Buffer1[i] = EMPTY_VALUE;
        }
      //Indicator Buffer 2
      if(Resistance(15 * 60, false, 00, 00, false, i) < getBid()
      && Resistance(15 * 60, false, 00, 00, false, i+1) > getBid() //Resistance crosses below Price
      )
        {
         Buffer2[i] = High[i]; //Set indicator value at Candlestick High
        }
      else
        {
         Buffer2[i] = EMPTY_VALUE;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+