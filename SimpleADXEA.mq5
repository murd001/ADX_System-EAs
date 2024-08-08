//+------------------------------------------------------------------+
//|                                                        ADXea.mq5 |
//|                                        Copyright 2023, Murd. Ltd |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Murd. Ltd."
#property version   "1.00"

#include<Trade\Trade.mqh>
CTrade trade;

input double lotSize = 0.1;
bool is_buy = false;
bool is_sell = false;
double adxPlus[],adxMinus[], tradesProfit[];
int adxIdenti;
double account_balance = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   adxIdenti = iADX(_Symbol, PERIOD_M5, 14);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);

   ArraySetAsSeries(adxPlus,true);
   ArraySetAsSeries(adxMinus, true);
   CopyBuffer(adxIdenti, 1, 0, 3, adxPlus);
   CopyBuffer(adxIdenti, 2, 0, 3, adxMinus);
   double adxPlusValue = NormalizeDouble(adxPlus[0], 2);
   double adxMinusValue = NormalizeDouble(adxMinus[0], 2);

   if(adxPlusValue > adxMinusValue && is_buy == false)
     {
      trade.Buy(lotSize, _Symbol, Ask,0 ,NormalizeDouble((Ask + 2.5), 2), NULL);
      is_buy = true;
     }
   else
      if(adxMinusValue > adxPlusValue && is_sell == false)
        {
         trade.Sell(lotSize, _Symbol, Bid, 0 ,NormalizeDouble((Bid - 2.5), 2), NULL);
         is_sell = true;
        }
        
   
   if((adxPlusValue > adxMinusValue && adxPlus[1] < adxMinus[1])||(adxMinusValue > adxPlusValue && adxMinus[1] < adxPlus[1]))
     {
      for(int i = PositionsTotal()-1; i <= 0; i--)
         {
          trade.PositionClose(_Symbol);
         }
     }
  }
//+------------------------------------------------------------------+
