//+------------------------------------------------------------------+
//|                                            GOLDMINER Signals.mq5 |
//|                                       Hacker217, Copyright 2024. |
//|                                     https://github.com/hacker217 |
//+------------------------------------------------------------------+
#property copyright "Hacker217, Copyright 2024."
#property link      "https://github.com/hacker217"
#property version   "1.1"

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots 8

#define PLOT_MAXIMUM_BARS_BACK 
#define OMIT_OLDEST_BARS 
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

input group "==== Number of Bars ===="
input int PLOT_MAXIMUM_BARS_BACK maxBars = 200;
input int OMIT_OLDEST_BARS oldBars = 50;
input int arrows_num = 50;
input double ArrowDist = 1;

input group "==== SIGNALS ===="
input ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
input bool isSupResActive = false;  // Show Support and Resistance Signals
input bool isStochArrowActive = false;  // Show Stoch Signals
input bool isStochXArrowActive = false;  // Show StochX Signals
input bool isMacdArrowActive = false;  // Show Macd Signals
input bool isRsiArrowActive = false;  // Show  Rsi Signals
input bool isMAArrowActive = false;  // Show MA  Signals 


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
input int EMA200 = 500;                                       // EMA200 Period
input ENUM_MA_METHOD EMAMode = MODE_EMA;                        // Type of Moving Average
input ENUM_APPLIED_PRICE EMAAppPrice = PRICE_CLOSE;             // MA applied Price

input group "==== VARIABLE INPUTS ===="
input bool Audible_Alerts = true;

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
double Close[];
string resistance;
string support;
int arrow_count = 0;
int lastArrowBarIndex = -1;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit(){ 

  SetIndexBuffer(0, BufferStochBuy);
  SetIndexBuffer(1, BufferStochSell); 
  SetIndexBuffer(2, BufferMacdBuy);
  SetIndexBuffer(3, BufferMacdSell);
  SetIndexBuffer(4, BufferRsiBuy);
  SetIndexBuffer(5, BufferRsiSell);
  SetIndexBuffer(6, BufferMABuy);
  SetIndexBuffer(7, BufferMASell);

  IndicatorSetString(INDICATOR_SHORTNAME, "GoldMiner");
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
    Print("The creation of iRSI has failed: handlersi=", INVALID_HANDLE);
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

  if(!IsNewBar()) return 0; // Exit if it's not a new bar 

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
  if(CopyClose(Symbol(), PERIOD_CURRENT, 0, rates_total, Close) <= 0) return(rates_total);
  ArraySetAsSeries(Close, true);
  if(CopyTime(Symbol(), Period(), 0, rates_total, Time) <= 0) return(rates_total);
  ArraySetAsSeries(Time, true);


    //--- main loop
    for(int i = limit-1; i >= 0; i--){
  
        //omit some old rates to prevent "Array out of range" or slow calculation
        
        if (i >= MathMin(maxBars-1, rates_total-1-oldBars)) continue;    
        
        double range = High[i] - Low[i];
        double dynamic_arrow_dist = range * ArrowDist;
        resistance = "";
        support = "";
        double price = SymbolInfoDouble(_Symbol,SYMBOL_BID);
        int totalObjects = ObjectsTotal(0, 0, OBJ_RECTANGLE);
        
        // SUPPORT AND RESISTANCE ZONES SIGNALS
        for(int j=0; j<totalObjects; j++){

        if(isSupResActive){

            string objectName = ObjectName(0, j, 0, OBJ_RECTANGLE);

            // Sell Signals
            if(StringFind(objectName, "SSSR#R")>-1){

            resistance = objectName;
            //Print("\nResistance: ", resistance);

            double resistanceHigh = ObjectGetDouble(0, resistance, OBJPROP_PRICE,0);
            double resistanceLow = ObjectGetDouble(0, resistance, OBJPROP_PRICE,1);
            double range = (resistanceHigh-resistanceLow)/2;
            double sellRange = resistanceLow-range;
            double sellStop = resistanceHigh+range;

            string name = "Res_Sell#"+string(arrow_count+1);
        
            datetime object_time = (datetime)ObjectGetInteger(0, resistance, OBJPROP_TIME);
            int object_bar = iBarShift(Symbol(), Period(), TimeLocal());
            double candle = iClose(Symbol(), Period(), object_bar); // Retrieve the low price of the candle where the sell arrow appears
            double candleHigh = iHigh(Symbol(), Period(), object_bar);
            double candleLow = iLow(Symbol(), Period(), object_bar);
            ObjectSetDouble(0, name, OBJPROP_PRICE, candle); // Attach the close price to the sell arrow object

            // Ensure object_bar is within the range of available bars
            if (object_bar < 0 || object_bar >= Bars(Symbol(), Period())) {
                Print("Invalid object_bar index: ", object_bar);
                continue;
            }

            if(price<resistanceHigh && candleHigh>resistanceLow){ 
            
                //PrintFormat("\nEntered Resistance Zone: Time = %s, Price = %f", TimeToString(TimeLocal()), price);
            }
            
            //if(price < resistanceHigh && candleHigh > resistanceLow && price > sellRange && price < resistanceLow && arrow_count < arrows_num) continue;
            
            if (Close[i+1] > resistanceLow && Close[i] < resistanceLow && object_bar != lastArrowBarIndex){

                PrintFormat("Price below Resistance Zone: %s, (Sell Arrow should appear)",resistance);

                // Sell Arrow Signals  

                color SellColor = clrBlack;
                string obj_name="Res_Sell#"+string(arrow_count+1);
                
                if(object_bar >= 0 && object_bar < Bars(Symbol(), Period())){

                ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[object_bar], High[object_bar] + dynamic_arrow_dist);
                //ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], High[i]+dynamic_arrow_dist);
                ObjectSetInteger(0, obj_name, OBJPROP_COLOR, SellColor);
                ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
                ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 234);
                ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_TOP);
                ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
                ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
                arrow_count++;       
                lastArrowBarIndex = object_bar;  
                }
            }

            
            if(price<sellStop && price>resistanceHigh){
                PrintFormat("Price above Resistance Zone, Price=%f, Don't put SELL orders!!!",price);
            }
            if(price>sellStop){
                Print("Stop Loss");
            }
            }
            
            // Buy Signals
            if(StringFind(objectName, "SSSR#S")>-1){

            support = objectName;
            //Print("\nSupport: ", support);
            double supportHigh = ObjectGetDouble(0, support, OBJPROP_PRICE,0);
            double supportLow = ObjectGetDouble(0, support, OBJPROP_PRICE,1);
            double range = (supportHigh-supportLow)/2;
            double buyRange = supportHigh+range;
            double buyStop = supportLow-range;

            string name = "Sup_Buy#"+string(arrow_count+1);
            
            datetime object_time = (datetime)ObjectGetInteger(0, support, OBJPROP_TIME);
            int object_bar = iBarShift(Symbol(), Period(), TimeLocal());
            double candle = iClose(Symbol(), Period(), object_bar); // Retrieve the low price of the candle where the sell arrow appears
            double candleHigh = iHigh(Symbol(), Period(), object_bar);
            double candleLow = iLow(Symbol(), Period(), object_bar);
            ObjectSetDouble(0, name, OBJPROP_PRICE, candle);

            // Ensure object_bar is within the range of available bars
            if (object_bar < 0 || object_bar >= Bars(Symbol(), Period())) {
                Print("Invalid object_bar index: ", object_bar);
                continue;
            }
    
            if(price>supportLow && candleLow<supportHigh){ 
                
                //PrintFormat("\nEntered Support Zone: Time = %s, Price = %f", TimeToString(TimeLocal()), price);
            }
            //if(price > supportLow && candleLow < supportHigh && price < buyRange && price > supportHigh && arrow_count < arrows_num)continue;
                
            if(Close[i+1] < supportHigh && Close[i] > supportHigh && object_bar != lastArrowBarIndex){

                PrintFormat("Price above the Support Zone: %s,  (Buy Arrow should appear)",support);
                
                // Buy Arrow Signal 
                color BuyColor = clrBlack;
                string obj_name = "Sup_Buy#"+string(arrow_count+1);

                if(object_bar >= 0 && object_bar < Bars(Symbol(), Period())){

                ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[object_bar], High[object_bar] + dynamic_arrow_dist);
                //ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], Low[i]-dynamic_arrow_dist);
                ObjectSetInteger(0, obj_name, OBJPROP_COLOR, BuyColor);
                ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
                ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 233);
                ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
                ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
                ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
                arrow_count++;  
                lastArrowBarIndex = object_bar;
                }
            }  
            
            if(price>buyStop && price<supportLow){
                PrintFormat("Price below Support Zone, Price=%f, Don't put BUY orders!!!", price);
            }
            if(price<buyStop){
                Print("Stop Loss");
            }
            }
        }
        }

        //Indicator  Buffer Stoch Buy
        if(stoch_main[i]>stoch_oversold && stoch_main[i+1]<stoch_oversold){  
        
        if (isStochArrowActive && arrow_count<arrows_num){

            color BuyColor = clrBrown;

            string obj_name="StochBuy#"+string(arrow_count+1);
            ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], Low[i]-dynamic_arrow_dist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, BuyColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 233);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            arrow_count++;             
        }

        }    

        //Indicator  Buffer StochX Buy
        else if(stoch_main[i]>stoch_signal[i]&& stoch_main[i+1]<stoch_signal[i+1] && stoch_main[i]<10 && stoch_signal[i]<10){ 
        
        if (isStochXArrowActive && arrow_count<arrows_num){

            color BuyColor = clrBrown;
            string obj_name="StochXBuy#"+string(arrow_count+1);
            ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], Low[i]-dynamic_arrow_dist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, BuyColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 233);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            arrow_count++;             
        }

        }
        else{
        BufferStochBuy[i] = EMPTY_VALUE;
        }
        
        //Indicator Buffer Stoch Sell
        if(stoch_main[i]<stoch_overbought && stoch_main[i+1]>stoch_overbought){

        if (isStochArrowActive && arrow_count<arrows_num){

            color SellColor = clrMagenta;

            string obj_name="StochSell#"+string(arrow_count+1);
            ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], High[i]+dynamic_arrow_dist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, SellColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 234);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_TOP);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            arrow_count++;
        }

        }

        //Indicator Buffer StochX Sell
        else if(stoch_main[i]<stoch_signal[i] && stoch_main[i+1]>stoch_signal[i+1] && stoch_main[i]>90 && stoch_signal[i]>90){  

        if (isStochXArrowActive && arrow_count<arrows_num){
    
            color SellColor = clrMagenta;
            string obj_name="StochXSell#"+string(arrow_count+1);
            ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], High[i]+dynamic_arrow_dist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, SellColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 234);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_TOP);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            arrow_count++;
        }
        }
        else{
        BufferStochSell[i] = EMPTY_VALUE;
        }
        
        //Indicator Buffer Macd Buy
        if(macd_main[i]>macd_signal[i] && macd_main[i+1]<macd_signal[i+1] && macd_main[i]<macd_lower_level){

        if (isMacdArrowActive && arrow_count<arrows_num){
    
            color BuyColor = clrGreen;
            string obj_name="MacdBuy#"+string(arrow_count+1);
            ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], Low[i]-ArrowDist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, BuyColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 233);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            arrow_count++; 
                        
        }

        }
        else{
        BufferMacdBuy[i] = EMPTY_VALUE;
        }
        
        //Indicator Buffer Macd Sell
        if(macd_main[i]<macd_signal[i] && macd_main[i+1]>macd_signal[i+1] && macd_main[i]>macd_upper_level){

        if (isMacdArrowActive && arrow_count<arrows_num){
        
            color SellColor = clrRed;
            string obj_name="MacdSell#"+string(arrow_count+1);
            ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], High[i]+ArrowDist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, SellColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 234);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_TOP);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            arrow_count++;
        }
        }
        else{
        BufferMacdSell[i] = EMPTY_VALUE;
        }

        //Indicator Buffer Rsi Buy   
        if(rsi_main[i]>rsi_oversold && rsi_main[i+1]<rsi_oversold){

        if (isRsiArrowActive && arrow_count<arrows_num){
    
            color BuyColor = C'124,69,69';
            string obj_name="RsiBuy#"+string(arrow_count+1);
            ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], Low[i]-dynamic_arrow_dist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, BuyColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 233);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            arrow_count++;           
            
        }

        }
        else{
        BufferRsiBuy[i] = EMPTY_VALUE;
        }
        
        //Indicator Buffer Rsi Sell   
        if(rsi_main[i] < rsi_overbought && rsi_main[i+1] > rsi_overbought){ 

        if (isRsiArrowActive && arrow_count<arrows_num){

            color SellColor = clrBlue;
            string obj_name="RsiSell#"+string(arrow_count+1);
            ObjectCreate(0,obj_name, OBJ_ARROW, 0, Time[i], High[i]+dynamic_arrow_dist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, SellColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 234);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_TOP);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            arrow_count++; 
        }
        }
        else{
        BufferRsiSell[i] = EMPTY_VALUE;
        }

        //Indicator Buffer MA Buy   
        if(ema9[i] > ema50[i] && ema9[i+1] < ema50[i+1]){

        if (isMAArrowActive && arrow_count<arrows_num){
    
            color BuyColor = clrGold;
            string obj_name="MABuy#"+IntegerToString(arrow_count+1);
            ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], Low[i]-dynamic_arrow_dist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, BuyColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 233);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            
            arrow_count++;              
        }
        }
        else{
        BufferMABuy[i] = EMPTY_VALUE;
        }
        
        //Indicator Buffer MA Sell
        
        if(ema9[i] < ema50[i] && ema9[i+1] > ema50[i+1]){ 

        if (isMAArrowActive && arrow_count<arrows_num){
    
            color SellColor = C'204,186,25';
            string obj_name="MASell#"+string(arrow_count+1);
            ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], High[i]+dynamic_arrow_dist);
            ObjectSetInteger(0, obj_name, OBJPROP_COLOR, SellColor);
            ObjectSetInteger(0, obj_name,OBJPROP_WIDTH,3); // Adjust width as needed
            ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 234);
            ObjectSetInteger(0,obj_name,OBJPROP_ANCHOR,ANCHOR_TOP);
            ObjectSetInteger(0,obj_name,OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,obj_name,OBJPROP_BACK,true);
            arrow_count++;
        }
        }
        else{
        BufferMASell[i] = EMPTY_VALUE;
        }
    }
   
  /*Comment("+------------------------------------------------------+",
          "\n| GOLDMINER Version: 2.0 by Hacker217|",
          "\n+------------------------------------------------------+"); */
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

bool IsNewBar(){
  static datetime previousTime = 0;
  datetime currentTime = iTime(_Symbol,PERIOD_M1,0);
  if(previousTime != currentTime){

    previousTime = currentTime;
    return true;
  }
  return false;
}