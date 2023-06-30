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

#property strict

#include "Breakout Set and Forget 5a.mqh"

#property copyright app_copyright
#property link      app_link
#property version   app_version
