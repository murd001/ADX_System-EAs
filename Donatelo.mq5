//+------------------------------------------------------------------+
//|                                                     Donatelo.mq5 |
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
input double Lot = 0.1;
input double GridSize = 1000.0;
input double EquityStepProfit_USD = 100.0;

bool GridCreateOnce;
int adxHandle;
double dPlus[], dMinus[];
double balance;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   GridCreateOnce = false;
   adxHandle = iADX(_Symbol,TimeFrame, 14);
   balance = AccountInfoDouble(ACCOUNT_BALANCE);
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

   if(GridCreateOnce == false)
     {
      CreateNewGrid();
      GridCreateOnce = true;
     }

   if(isNewBar())
     {
      if(dPlus[2] < dMinus[2] && dPlus[1] > dMinus[1])
        {
         //Cross For Buy
         for(int i=PositionsTotal()-1; i>=0; i--)
           {
            if(d_position.SelectByIndex(i))
              {
               if(d_position.PositionType() == POSITION_TYPE_SELL)
                 {
                  double positionProfit = d_position.Profit();
                  if(positionProfit > 0)
                    {
                     double positionOpenPrice = d_position.PriceOpen();
                     ulong positionTicket = d_position.Ticket();
                     if(d_trade.PositionClose(positionTicket))
                       {
                        Print("Closed sell position ", positionTicket, " with profit ", positionProfit);

                        if(d_trade.BuyStop(Lot, positionOpenPrice, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "Replaced sell with buy stop"))
                          {
                           Print("Placed buy stop order at ", positionOpenPrice);
                          }
                        else
                          {
                           Print("Failed to place buy stop order. Error: ", GetLastError());
                          }
                       }
                     else
                       {
                        Print("Failed to close position ", positionTicket, ". Error: ", GetLastError());
                       }
                    }
                 }
              }
           }
        }
      else
         if(dPlus[2] > dMinus[2] && dPlus[1] < dMinus[1])
           {
            //Cross For Sell
            for(int i = PositionsTotal() - 1; i >= 0; i--)
              {
               if(d_position.SelectByIndex(i))
                 {
                  if(d_position.PositionType() == POSITION_TYPE_BUY)
                    {
                     double positionProfit = d_position.Profit();
                     if(positionProfit > 0)
                       {
                        double positionOpenPrice = d_position.PriceOpen();
                        ulong positionTicket = d_position.Ticket();

                        if(d_trade.PositionClose(positionTicket))
                          {
                           Print("Closed buy position ", positionTicket, " with profit ", positionProfit);

                           if(d_trade.SellStop(Lot, positionOpenPrice, _Symbol, 0, 0, ORDER_TIME_GTC, 0, "Replaced buy with sell stop"))
                             {
                              Print("Placed sell stop order at ", positionOpenPrice);
                             }
                           else
                             {
                              Print("Failed to place sell stop order. Error: ", GetLastError());
                             }
                          }
                        else
                          {
                           Print("Failed to close position ", positionTicket, ". Error: ", GetLastError());
                          }
                       }
                    }
                 }
              }
           }

     }
   EquityStepping();
  }
//+------------------------------------------------------------------+
void CreateNewGrid()
  {
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double buyStopPrice = currentPrice + GridSize;
   double sellStopPrice = currentPrice - GridSize;
   d_trade.Buy(Lot, _Symbol, 0, 0, 0, "Initial market buy");
   for(int i = 0; i < 50; i++)
     {
      double price = buyStopPrice + (i * GridSize);
      d_trade.BuyStop(Lot, price, _Symbol, 0, 0, 0, "Grid buy stop");
     }
   for(int i = 0; i < 50; i++)
     {
      double price = sellStopPrice - (i * GridSize);
      d_trade.SellStop(Lot, price, _Symbol, 0, 0, 0, "Grid sell stop");
     }
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
      GridCreateOnce = false;
      balance = AccountInfoDouble(ACCOUNT_BALANCE);
     }
  }
//+------------------------------------------------------------------+
