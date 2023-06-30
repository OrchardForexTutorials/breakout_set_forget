/*
   Breakout Set and Forget
   Copyright 2023, Orchard Forex
   https://www.orchardforex.com

   Strategy from TradePro https://youtu.be/t0taDife5R4

   USDJPY
   Find a 24 hour high low range based on 6pm EST
   Entries are at 7 pips above and below the range
   3 entries above and 3 entries below
   Each entry has sl at 25 pips
   Separate tp targets for each entry, 15 pips, 35 pips and 50 pips

   Risk 1% per position - will be based on the 25 pip stop loss
   total 3% risk per day
   Assumed using equity

   Not stated
   When one entry target is hit cancel the opposite
   If entry is not hit on a day then forget it

   Optional
   When one profit is hit move stop loss to break even, trail, something

*/

#property copyright "Copyright 2023, Orchard Forex"
#property link "https://www.orchardforex.com"
#property version "1.00"

//+------------------------------------------------------------------+
//|	Inputs
//+------------------------------------------------------------------+
// Time range
input int    InpRangeStartHour   = 1; // Range start hour
input int    InpRangeStartMinute = 0; // Range start minute
input int    InpRangeEndHour     = 1; // Range end hour
input int    InpRangeEndMinute   = 0; // Range end minute

input double InpRangeGapPips     = 7.0;  // Entry gap from outer range pips
input double InpStopLossPips     = 25.0; // Stop loss pips
input double InpTakeProfit1Pips  = 15.0; // Take profit 1 pips
input double InpTakeProfit2Pips  = 35.0; // Take profit 2 pips
input double InpTakeProfit3Pips  = 50.0; // Take profit 3 pips

// Standard features
input long   InpMagic            = 232323;         // Magic number
input string InpTradeComment     = "SnF Breakout"; // Trade comment
input double InpRiskPercent      = 1.0;            // Risk Percent

;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {

   // Validate start and end are valid times
   if ( InpRangeStartHour < 0 || InpRangeStartHour > 23 ) {
      Alert( "Start hour must be in the range from 0-23" );
      return INIT_PARAMETERS_INCORRECT;
   }

   if ( InpRangeStartMinute < 0 || InpRangeStartMinute > 59 ) {
      Alert( "Start minute must be in the range from 0-59" );
      return INIT_PARAMETERS_INCORRECT;
   }

   if ( InpRangeEndHour < 0 || InpRangeEndHour > 23 ) {
      Alert( "End hour must be in the range from 0-23" );
      return INIT_PARAMETERS_INCORRECT;
   }

   if ( InpRangeEndMinute < 0 || InpRangeEndMinute > 59 ) {
      Alert( "End minute must be in the range from 0-59" );
      return INIT_PARAMETERS_INCORRECT;
   }

   return ( INIT_SUCCEEDED );
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit( const int reason ) {}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {}
