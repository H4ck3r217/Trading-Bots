//+------------------------------------------------------------------+
//|                                                  PriceAction.mq5 |
//|                           Copyright 2024, Automated Trading Ltd. |
//|                        https://github.com/H4ck3r217/Trading-Bots |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Automated Trading Ltd."
#property link      "https://github.com/H4ck3r217/Trading-Bots"
#property version   "1.0"
#property description "OnChart-drawn support, resistance and trendlines"

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#define PLOT_MAXIMUM_BARS_BACK 250
#define OMIT_OLDEST_BARS 50

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

int OnInit(){


   

  return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],const double &open[],const double &high[],const double &low[],const double &close[],const long &tick_volume[],const long &volume[],const int &spread[]){
                
                
                

                
                
                
                
   return(rates_total);
}


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+

// Check if price has crossed the trendline
if(PriceCrossedTrendline(LowertrendlinePrice)){
  
  // Check if it's a downtrend
  if(iClose(_Symbol, _Period, 0) < LowertrendlinePrice){

    for(int i = 0; i < totalObjects; i++) {

      string LowerTrendline = ObjectName(0, i);  // Get the object name

      if(ObjectFind(0, LowerTrendline) != -1 && ObjectGetInteger(0, LowerTrendline, OBJPROP_TYPE) == OBJ_TREND){

        if(StringFind(LowerTrendline, "l") > -1){ 

          Print("Trendline Name: ", LowerTrendline);

          // Search for the previous green candlestick (resistance order block)
          int green_candle_index = FindPreviousGreenCandleAboveTrendline(LowerTrendline, currentPrice);

          if(green_candle_index != -1){
            
            // Draw the order block (resistance zone)
            DrawOrderBlock(green_candle_index, clrLime);

            // Get high and low of the OB
            double ob_high = iHigh(_Symbol, _Period, green_candle_index);
            double ob_low = iLow(_Symbol, _Period, green_candle_index);

            // Price inside the OB
            if(IsPriceWithinOB(ob_high, ob_low)){
              
              int retest = 0;
              // Wait for price to retest the OB
              if(IsPriceRetestingOB(ob_high, ob_low, retest)){
                
                if(Close[i+1] > ob_low && Close[i] < ob_low && retest >= 1){

                  // Retest confirmed, plot sell arrow
                  if(i == 1 && Time[1] != time_alert) myAlert("indicator", "OrderBlock Retest Sell"); // Alert on next bar open
                  time_alert = Time[1];
                  
                  // Check if the last arrow was drawn more than 10 bars ago
                  bool arrowExists = false;
                  for(int k = 0; k < maxBars-oldBars; k++){

                    string arrowName = ObjectName(0, k);
                    if(StringFind(arrowName, "Retest_Sell#") > -1){

                      datetime arrowTime = (datetime)ObjectGetInteger(0, arrowName, OBJPROP_TIME);
                      if(Time[i] - arrowTime < PeriodSeconds() * arrowSellFilter){

                        arrowExists = true;
                        break;
                      }
                    }
                  }
                  
                  if(!arrowExists){

                    color SellColor = clrBlue;
                    string obj_name="Retest_Sell#"+IntegerToString(Time[i]);
                    ObjectCreate(0, obj_name, OBJ_ARROW, 0, Time[i], High[i+1]);
                    ObjectSetInteger(0, obj_name, OBJPROP_COLOR, SellColor);
                    ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 3); // Adjust width as needed
                    ObjectSetInteger(0, obj_name, OBJPROP_ARROWCODE, 234);
                    ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR, ANCHOR_TOP);
                    ObjectSetInteger(0, obj_name, OBJPROP_HIDDEN, false);
                    ObjectSetInteger(0, obj_name, OBJPROP_BACK, true);
                    arrow_count++;   
                  }
                }
              }
            }
          }
        }
      }
    }  
  }
}

bool IsPriceRetestingOB(double high_price, double low_price, int &retest){

  double current_price = iClose(_Symbol, _Period, 0); // Current price
  double price =  iHigh(_Symbol, _Period, 0);

  if(current_price < low_price && price > low_price){

    retest++;
    Print("Price retesting OB, retest count: ", retest);
    return true;  // Price is retesting the OB
  }
  return false;  // No retest detected
}

bool IsPriceWithinOB(double high_price, double low_price){

  double current_price = iClose(_Symbol, _Period, 0); // Current price

  // Check if price is within the OB range
  if(current_price >= low_price && current_price <= high_price){

    Print("Price within OB");
    return true;  // Price is within the OB
  }
  return false;  // No retest detected
}

