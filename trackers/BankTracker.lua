local _, addon = ...

local mt = addon.mt
local util = addon.utility
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local BANK_UUID = 'BANK_01'         -- Expenses from purchasing bank slots
local REAGENTBANK_UUID = 'BANK_02'  -- Expenses from purchasing reagent bank

local ALL_SLOTS_PURCHASED_VALUE = 999999999 

local BankSlotCost = 0
local ReagentBankCost = 0

local function GetNextBankSlotCost()
   BankSlotCost = GetBankSlotCost()
   if BankSlotCost == ALL_SLOTS_PURCHASED_VALUE then
      BankSlotCost = 0
   end
end

local function OnTrigger(uuid, t, m)
   if m <= 0 then
      local money = math.abs(m)
      _G.WOWMSTracker[realm].AllChars[t].Spent = _G.WOWMSTracker[realm].AllChars[t].Spent + money
      _G.WOWMSTracker[realm][player][t].Spent = _G.WOWMSTracker[realm][player][t].Spent + money

      local pcash = _G.WOWMMGlobal[realm].Chars[player].Cash
      local cash = pcash - money
      util.UpdateEarnedSpent(cash, pcash)
      util.UpdatePlayerCash(cash)
      util.UpdateZoneEarnedSpent(m)
   else
      addon.debugError("gaining money while purchasing bank slots?!")
   end
end

local function OnActivation(...)
   GetNextBankSlotCost()
   addon.debugPrint("Activation", BankSlotCost)

   if not IsReagentBankUnlocked() then
      ReagentBankCost = GetReagentBankCost()
   else
      ReagentBankCost = 0
   end
end

local function Classify(uuid)
   addon.debugPrint("Classify", uuid, BankSlotCost, ReagentBankCost)
   local cost
   if uuid == BANK_UUID then
      cost = -BankSlotCost
      GetNextBankSlotCost()
      return uuid, cost
   end

   if uuid == REAGENTBANK_UUID then
      cost = -ReagentBankCost
      ReagentBankCost = 0
      return uuid, cost
   end
end

mt.RegisterDeterminant(BANK_UUID, 'PLAYERBANKBAGSLOTS_CHANGED', Classify)
mt.RegisterDeterminant(REAGENTBANK_UUID, 'REAGENTBANK_PURCHASED', Classify)
mt.RegisterTracker(BANK_UUID, 'STORAGEUPGRADE', 'BANKFRAME_OPENED', 'BANKFRAME_CLOSED', OnTrigger)
mt.RegisterTracker(REAGENTBANK_UUID, 'STORAGEUPGRADE', 'BANKFRAME_OPENED', 'BANKFRAME_CLOSED', OnTrigger)
mt.RegisterOnActivation(BANK_UUID, OnActivation)
