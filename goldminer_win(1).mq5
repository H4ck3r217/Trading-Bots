//+------------------------------------------------------------------+
//|                                         Indicator: MACDSTOCH.mq5 |
//|                                       Created with EABuilder.com |
//|                                        https://www.eabuilder.com |
//+------------------------------------------------------------------+
#property copyright "Created with EABuilder.com"
#property link      "https://www.eabuilder.com"
#property version   "1.00"
#property description ""

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 8
#property indicator_plots 8

#property indicator_type1 DRAW_ARROW
#property indicator_width1 3
#property indicator_color1 clrYellow
#property indicator_label1 "Stoch Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 3
#property indicator_color2 clrMagenta
#property indicator_label2 "Stoch Sell"

#property indicator_type3 DRAW_ARROW
#property indicator_width3 3
#property indicator_color3 clrLime
#property indicator_label3 "Macd Buy"

#property indicator_type4 DRAW_ARROW
#property indicator_width4 3
#property indicator_color4 clrRed
#property indicator_label4 "Macd Sell"

#property indicator_type5 DRAW_ARROW
#property indicator_width5 3
#property indicator_color5 C'124,69,69'
#property indicator_label5 "Rsi Buy"

#property indicator_type6 DRAW_ARROW
#property indicator_width6 3
#property indicator_color6 clrBlue
#property indicator_label6 "Rsi Sell"

#property indicator_type7 DRAW_ARROW
#property indicator_width7 3
#property indicator_color7 clrBlack
#property indicator_label7 "MA Buy"

#property indicator_type8 DRAW_ARROW
#property indicator_width8 3
#property indicator_color8 C'204,186,25'
#property indicator_label8 "MA Sell"

#define PLOT_MAXIMUM_BARS_BACK 5000
#define OMIT_OLDEST_BARS 50
#define Arrow_BUY 1
#define Arrow_SELL 2

//--- indicator buffers
double BufferStochBuy[];
double BufferStochSell[];
double BufferMacdBuy[];
double BufferMacdSell[];
double BufferRsiBuy[];
double BufferRsiSell[];
double BufferMABuy[];
double BufferMASell[];

input group "==== SIGNALS ===="
input ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
input bool isStochActive = false;     // Show Stoch Signals
input bool isStochCrossActive = false;   // Show StochCrossing Signals
input bool isMacdActive = false;    // Show Macd Signals
input bool isRsiActive = false;      // Show Rsi Signals
input bool isMAActive = false;      // Show MA Signals

input group "==== STOCHASTIC INPUTS ===="
input int stoch_k = 9;
input int stoch_d = 5;
input int Slowing = 3;
input double stoch_oversold = 10;
input double stoch_overbought = 90;

input group "==== MACD INPUTS ===="
input int Fast_EMA = 8;
input int Slow_EMA = 21;
input int MACD_SMA = 5;
input double macd_lower_level = -5;
input double macd_upper_level = 3;

input group "==== RSI INPUTS ===="
input int rsi_period = 14;
input double rsi_oversold = 30;
input double rsi_overbought = 70;

input group "==== Moving Average INPUTS ===="
input int EMA9 = 9;                                          // EMA9 Period
input int EMA50 = 50;                                       // EMA50 Period
input int EMA200 = 200;                                       // EMA200 Period
input ENUM_MA_METHOD EMAMode = MODE_EMA;                        // Type of Moving Average
input ENUM_APPLIED_PRICE EMAAppPrice = PRICE_CLOSE;             // MA applied Price

input group "==== VARIABLE INPUTS ===="
input bool Audible_Alerts = true;
input double ArrowDist = 0.5;
datetime time_alert; //used when sending alert

int handleStoch;
double stoch_main[];
double stoch_signal[];
int handleMacd;
double macd_main[];
double macd_signal[];
int handleRsi;
double rsi_main[];
int handleEMA9, handleEMA50;
int handleEMA200;
double ema9[], ema50[];
double ema200[];
double Low[];
double High[];
int arrow_count = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit(){ 

  SetIndexBuffer(0, BufferStochBuy);
  PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(0, PLOT_ARROW, 233);
  
  SetIndexBuffer(1, BufferStochSell);
  PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(1, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(1, PLOT_ARROW, 234);

  SetIndexBuffer(2, BufferMacdBuy);
  PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(2, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(2, PLOT_ARROW, 233);

  SetIndexBuffer(3, BufferMacdSell);
  PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(3, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(3, PLOT_ARROW, 234);

  SetIndexBuffer(4, BufferRsiBuy);
  PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(4, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(4, PLOT_ARROW, 233);

  SetIndexBuffer(5, BufferRsiSell);
  PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(5, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(5, PLOT_ARROW, 234);

  SetIndexBuffer(6, BufferMABuy);
  PlotIndexSetDouble(6, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(6, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(6, PLOT_ARROW, 233);

  SetIndexBuffer(7, BufferMASell);
  PlotIndexSetDouble(7, PLOT_EMPTY_VALUE, EMPTY_VALUE);
  PlotIndexSetInteger(7, PLOT_DRAW_BEGIN, MathMax(Bars(Symbol(), PERIOD_CURRENT)-PLOT_MAXIMUM_BARS_BACK+1, OMIT_OLDEST_BARS+1));
  PlotIndexSetInteger(7, PLOT_ARROW, 234);

  IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

  ArraySetAsSeries(BufferStochBuy, true);
  ArraySetAsSeries(BufferStochSell, true);
  ArraySetAsSeries(BufferMacdBuy, true);
  ArraySetAsSeries(BufferMacdSell, true);
  ArraySetAsSeries(BufferRsiBuy, true);
  ArraySetAsSeries(BufferRsiSell, true);
  ArraySetAsSeries(BufferMABuy, true);
  ArraySetAsSeries(BufferMASell, true);

  handleStoch = iStochastic(_Symbol, PERIOD_CURRENT, stoch_k, stoch_d, Slowing, MODE_SMA, STO_LOWHIGH);
  if(handleStoch < 0){
    Print("The creation of iStochastic has failed: handleStoch=", INVALID_HANDLE);
    Print("Runtime error = ", GetLastError());
    return(INIT_FAILED);
  }

  handleMacd = iMACD(_Symbol, PERIOD_CURRENT, Fast_EMA, Slow_EMA, MACD_SMA, PRICE_CLOSE);
  if(handleMacd < 0){
    Print("The creation of iMACD has failed: handleMacd=", INVALID_HANDLE);
    Print("Runtime error = ", GetLastError());
    return(INIT_FAILED);
  }

  handleRsi = iRSI(_Symbol, PERIOD_CURRENT, rsi_period, PRICE_CLOSE);
  if(handleRsi < 0){
    Print("The creation of irsi has failed: handlersi=", INVALID_HANDLE);
    Print("Runtime error = ", GetLastError());
    return(INIT_FAILED);
  }

  handleEMA9 = iMA(_Symbol,timeframe,EMA9,0,EMAMode,EMAAppPrice);
  if(handleEMA9 < 0){
    Print("The creation of EMA9 has failed: handleEMA9=", INVALID_HANDLE);
    Print("Runtime error = ", GetLastError());
    return(INIT_FAILED);
  }

  handleEMA50 = iMA(_Symbol,timeframe,EMA50,0,EMAMode,EMAAppPrice);
  if(handleEMA50 < 0){
    Print("The creation of EMA50 has failed: handleEMA50=", INVALID_HANDLE);
    Print("Runtime error = ", GetLastError());
    return(INIT_FAILED);
  }

  handleEMA200 = iMA(_Symbol,timeframe,EMA200,0,EMAMode,EMAAppPrice);
  if(handleEMA200 < 0){
    Print("The creation of EMA200 has failed: handleEMA200=", INVALID_HANDLE);
    Print("Runtime error = ", GetLastError());
    return(INIT_FAILED);
  }

  return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,const int prev_calculated,const datetime& time[],const double& open[],const double& high[],const double& low[],const double& close[],const long& tick_volume[],const long& volume[],const int& spread[]){

  int limit = rates_total - prev_calculated;
  //--- counting from 0 to rates_total
  ArraySetAsSeries(BufferStochBuy, true);
  ArraySetAsSeries(BufferStochSell, true);
  ArraySetAsSeries(BufferMacdBuy, true);
  ArraySetAsSeries(BufferMacdSell, true);
  ArraySetAsSeries(BufferRsiBuy, true);
  ArraySetAsSeries(BufferRsiSell, true);
  ArraySetAsSeries(BufferMABuy, true);
  ArraySetAsSeries(BufferMASell, true);
  
  //--- initial zero
  if(prev_calculated < 1){
    ArrayInitialize(BufferStochBuy, EMPTY_VALUE);
    ArrayInitialize(BufferStochSell, EMPTY_VALUE);
    ArrayInitialize(BufferMacdBuy, EMPTY_VALUE);
    ArrayInitialize(BufferMacdSell, EMPTY_VALUE);
    ArrayInitialize(BufferRsiBuy, EMPTY_VALUE);
    ArrayInitialize(BufferRsiSell, EMPTY_VALUE);
    ArrayInitialize(BufferMABuy, EMPTY_VALUE);
    ArrayInitialize(BufferMASell, EMPTY_VALUE);
    
  }
  else{
    limit++;
  }

  datetime Time[];
  if(BarsCalculated(handleStoch) <= 0)return(0); 
  if(CopyBuffer(handleStoch, MAIN_LINE, 0, rates_total, stoch_main) <= 0) return(rates_total);
  ArraySetAsSeries(stoch_main, true);
  if(CopyBuffer(handleStoch, SIGNAL_LINE, 0, rates_total, stoch_signal) <= 0) return(rates_total);
  ArraySetAsSeries(stoch_signal, true);
  
  if(BarsCalculated(handleMacd) <= 0) return(0);  
  if(CopyBuffer(handleMacd, MAIN_LINE, 0, rates_total, macd_main) <= 0) return(rates_total);
  ArraySetAsSeries(macd_main, true);
  if(BarsCalculated(handleMacd) <= 0) return(0);
  if(CopyBuffer(handleMacd, SIGNAL_LINE, 0, rates_total, macd_signal) <= 0) return(rates_total);
  ArraySetAsSeries(macd_signal, true);

  if(BarsCalculated(handleRsi) <= 0) return(0);
  if(CopyBuffer(handleRsi, MAIN_LINE, 0, rates_total, rsi_main) <= 0) return(rates_total);
  ArraySetAsSeries(rsi_main, true);

  if(BarsCalculated(handleEMA9) <= 0) return(0);
  if(CopyBuffer(handleEMA9, MAIN_LINE, 0, rates_total, ema9) <= 0) return(rates_total);
  ArraySetAsSeries(ema9, true);
 
  if(BarsCalculated(handleEMA50) <= 0) return(0);
  if(CopyBuffer(handleEMA50, MAIN_LINE, 0, rates_total, ema50) <= 0) return(rates_total);
  ArraySetAsSeries(ema50, true);

  if(BarsCalculated(handleEMA200) <= 0) return(0);
  if(CopyBuffer(handleEMA200, MAIN_LINE, 0, rates_total, ema200) <= 0) return(rates_total);
  ArraySetAsSeries(ema200, true);

  if(CopyLow(Symbol(), PERIOD_CURRENT, 0, rates_total, Low) <= 0) return(rates_total);
  ArraySetAsSeries(Low, true);
  if(CopyHigh(Symbol(), PERIOD_CURRENT, 0, rates_total, High) <= 0) return(rates_total);
  ArraySetAsSeries(High, true);
  if(CopyTime(Symbol(), Period(), 0, rates_total, Time) <= 0) return(rates_total);
  ArraySetAsSeries(Time, true);

  //--- main loop
  for(int i = limit-1; i >= 0; i--){
  
    //omit some old rates to prevent "Array out of range" or slow calculation

    if (i >= MathMin(PLOT_MAXIMUM_BARS_BACK-1, rates_total-1-OMIT_OLDEST_BARS)) continue;    
    
    //Indicator  Buffer Stoch Buy
    
    if(stoch_main[i+1]<stoch_oversold && stoch_main[i]>stoch_oversold){  
      
      if(isStochActive){
        BufferStochBuy[i] = Low[i]-ArrowDist;             //Set indicator value at Candlestick Low
        if(i == 1 && Time[1] != time_alert){ time_alert = Time[1];  /*myAlert("indicator", "STOCH Buy");*/ }    //Alert on next bar open
      }

    }    
    else if(stoch_main[i]>stoch_signal[i]&& stoch_main[i+1]<stoch_signal[i+1] && stoch_main[i]<10 && stoch_signal[i]<10){ 
      
      if(isStochCrossActive){
        BufferStochBuy[i] = Low[i]; //Set indicator value at Candlestick Low
        if(i == 0 && Time[0] != time_alert) { time_alert = Time[0]; /*myAlert("indicator", "Buy");*/ } //Instant alert, only once per bar
      }
    }
    else{
      BufferStochBuy[i] = EMPTY_VALUE;
    }
      
    //Indicator Buffer Stoch Sell
    
    if(stoch_main[i]<stoch_overbought && stoch_main[i+1]>stoch_overbought){

      if(isStochActive){  
        BufferStochSell[i] = High[i]+ArrowDist;         //Set indicator value at Candlestick High
        if(i == 1 && Time[1] != time_alert) //myAlert("indicator", "STOCH Sell");         //Alert on next bar open
        time_alert = Time[1];
      }
    }
    else if(stoch_main[i]<stoch_signal[i] && stoch_main[i+1]>stoch_signal[i+1] && stoch_main[i]>90 && stoch_signal[i]>90){  

      if(isStochCrossActive){
        BufferStochSell[i] = High[i]+ArrowDist;     //Set indicator value at Candlestick High
        if(i == 1 && Time[1] != time_alert) //myAlert("indicator", "STOCH Sell");                              //Alert on next bar open
        time_alert = Time[1];
      }
  
    }
    else{
      BufferStochSell[i] = EMPTY_VALUE;
    }
      
    //Indicator Buffer Macd Buy
    
    if(macd_main[i]>macd_signal[i] && macd_main[i+1]<macd_signal[i+1] && macd_main[i]<macd_lower_level){
      
      if(isMacdActive){
        BufferMacdBuy[i] = Low[i]-ArrowDist;              //Set indicator value at Candlestick Low
        if(i == 1 && Time[1] != time_alert) //myAlert("indicator", "MACD_Buy");    //Alert on next bar open
        time_alert = Time[1];
      }

    }
    else{
      BufferMacdBuy[i] = EMPTY_VALUE;
    }
      
    //Indicator Buffer Macd Sell
    
    if(macd_main[i]<macd_signal[i] && macd_main[i+1]>macd_signal[i+1] && macd_main[i]>macd_upper_level){
      
      if(isMacdActive){
        BufferMacdSell[i] = High[i]+ArrowDist;      //Set indicator value at Candlestick High
        if(i == 1 && Time[1] != time_alert) //myAlert("indicator", "MACD_Sell");         //Alert on next bar open
        time_alert = Time[1];
      }

    }
    else{
      BufferMacdSell[i] = EMPTY_VALUE;
    }
      
    //Indicator Buffer Rsi Buy
    
    if(rsi_main[i]>rsi_oversold && rsi_main[i+1]<rsi_oversold){

      if(isRsiActive){
        BufferRsiBuy[i] = Low[i]-ArrowDist;                  //Set indicator value at Candlestick Low
        if(i == 1 && Time[1] != time_alert) //myAlert("indicator", "RSI_Buy");         //Alert on next bar open
        time_alert = Time[1];
      }
 
    }
    else{
      BufferRsiBuy[i] = EMPTY_VALUE;
    }
      
    //Indicator Buffer Rsi Sell
    
    if(rsi_main[i] < rsi_overbought && rsi_main[i+1] > rsi_overbought){ 

      if(isRsiActive){   
        BufferRsiSell[i] = High[i]+ArrowDist;   //Set indicator value at Candlestick Low
        if(i == 1 && Time[1] != time_alert) //myAlert("indicator", "RSI_Sell");        //Alert on next bar open
        time_alert = Time[1]; 
      }
    
    }
    else{
      BufferRsiSell[i] = EMPTY_VALUE;
    }

    //Indicator Buffer MA Buy
    
    if(ema9[i] > ema50[i] && ema9[i+1] < ema50[i+1]){
      
      if(isMAActive){
        BufferMABuy[i] = Low[i]-ArrowDist;                  //Set indicator value at Candlestick Low
        if(i == 1 && Time[1] != time_alert) //myAlert("indicator", "RSI_Buy");         //Alert on next bar open
        time_alert = Time[1];
      }
  
    }
    else{
      BufferMABuy[i] = EMPTY_VALUE;
    }
      
    //Indicator Buffer MA Sell
    
    if(ema9[i] < ema50[i] && ema9[i+1] > ema50[i+1]){ 

      if(isMAActive){ 
        BufferMASell[i] = High[i]+ArrowDist;   //Set indicator value at Candlestick Low
        if(i == 1 && Time[1] != time_alert) //myAlert("indicator", "RSI_Sell");        //Alert on next bar open
        time_alert = Time[1]; 
      }
    }
    else{
      BufferMASell[i] = EMPTY_VALUE;
    }
  }

  return(rates_total);
}

bool inTimeInterval(datetime t, int From_Hour, int From_Min, int To_Hour, int To_Min){
   string TOD = TimeToString(t, TIME_MINUTES);
   string TOD_From = StringFormat("%02d", From_Hour)+":"+StringFormat("%02d", From_Min);
   string TOD_To = StringFormat("%02d", To_Hour)+":"+StringFormat("%02d", To_Min);
   return((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, TOD_To) <= 0)
     || (StringCompare(TOD_From, TOD_To) > 0
       && ((StringCompare(TOD, TOD_From) >= 0 && StringCompare(TOD, "23:59") <= 0)
         || (StringCompare(TOD, "00:00") >= 0 && StringCompare(TOD, TOD_To) <= 0))));
}

void myAlert(string type, string message){
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | MACDSTOCH @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order"){

    }
   else if(type == "modify"){
    
    }

    else if(type == "indicator"){

      Print(type+" | MACDSTOCH @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      //if(Audible_Alerts) Alert(type+" | MACDSTOCH @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
      //if(Push_Notifications) SendNotification(type+" | MACDSTOCH @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
    }
}
