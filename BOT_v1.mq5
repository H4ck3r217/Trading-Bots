//+------------------------------------------------------------------+
//|                                                       Bot_v1.mq5 |
//|                           Copyright 2024, Automated Trading Ltd. |
//|                        https://github.com/H4ck3r217/Trading-Bots |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Automated Trading Ltd."
#property link      "https://github.com/H4ck3r217/Trading-Bots"
#property version   "1.0.0"


#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#define PLOT_MAXIMUM_BARS_BACK 250
#define OMIT_OLDEST_BARS 50


input group "==== SIGNALS ===="
input ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
input bool isTrendlineActive = false;  // Show Trendline Signals
input bool isSupResActive = false;  // Show Sup & Res Signals

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit(){

   

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

   
}
//+------------------------------------------------------------------+