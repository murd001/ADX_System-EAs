//+------------------------------------------------------------------+
//|                                                       Vimana.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CPositionInfo d_position = CPositionInfo();
CTrade d_trade = CTrade();

input ENUM_TIMEFRAMES TimeFrame = PERIOD_M5;

input double EquityStepProfit_USD = 5.0;
input double Termination_Usd = 15.0;

double Lot = 0.01;
int adxHandle;
double dPlus[], dMinus[];
double balance;
double StartingBalance;
bool Termination;
double minLot;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   adxHandle = iADX(_Symbol,TimeFrame, 14);
   balance = AccountInfoDouble(ACCOUNT_BALANCE);
   StartingBalance = balance;
   Termination = false;
   minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(Lot < minLot)
     {
      Print("Warning: Input Lot size is below minimum. Adjusting to ", minLot);
      Lot = minLot;
     }
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
   ArraySetAsSeries(dPlus, true);
   ArraySetAsSeries(dMinus, true);
   CopyBuffer(adxHandle, 1, 0, 3, dPlus);
   CopyBuffer(adxHandle, 2, 0, 3, dMinus);
   double adjustedLot = MathMax(Lot, minLot);
   
   if(isNewBar() && Termination == false)
     {
      if(dPlus[2] < dMinus[2] && dPlus[1] > dMinus[1])
        {
         if(PositionsTotal() < 1)
           {
            d_trade.Buy(adjustedLot, _Symbol, NULL);
           }
         else
            if(PositionsTotal() >= 1)
              {
               if(PositionSelect(_Symbol) == true)
                 {
                  int positionType = PositionGetInteger(POSITION_TYPE);
                  double positionProfit = PositionGetDouble(POSITION_PROFIT);
                  if(positionType == 1)
                    {
                     d_trade.PositionClose(_Symbol);
                     balance = balance + positionProfit;
                     d_trade.Buy(adjustedLot, _Symbol, NULL);
                    }
                 }
              }
        }
     }
   else
      if(dPlus[2] > dMinus[2] && dPlus[1] < dMinus[1])
        {
         if(PositionsTotal() < 1)
           {
            d_trade.Sell(adjustedLot, _Symbol, NULL);
           }
         else
            if(PositionsTotal() >= 1)
              {
               if(PositionSelect(_Symbol) == true)
                 {
                  int positionType = PositionGetInteger(POSITION_TYPE);
                  double positionProfit = PositionGetDouble(POSITION_PROFIT);
                  if(positionType == 0)
                    {
                     d_trade.PositionClose(_Symbol);
                     balance = balance + positionProfit;
                     d_trade.Sell(adjustedLot, _Symbol, NULL);
                    }
                 }
              }
        }
   EquityStepping();

  }
//+------------------------------------------------------------------+
bool isNewBar()
  {
   static int lastBarsCount = 0;
   int currentBarsCount = Bars(_Symbol, _Period);

   if(currentBarsCount > lastBarsCount)
     {
      lastBarsCount = currentBarsCount;
      return true;
     }

   return false;
  }
//+------------------------------------------------------------------+
void EquityStepping()
  {
   double CurrentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(CurrentEquity >= (balance + EquityStepProfit_USD))
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         d_trade.PositionClose(_Symbol);
        }
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         ulong ticket = OrderGetTicket(i);
         if(ticket != 0)
           {
            d_trade.OrderDelete(ticket);
           }
        }
      balance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(balance >= (StartingBalance + Termination_Usd))
        {
         Termination = true;
        }
     }
  }
//+------------------------------------------------------------------+
