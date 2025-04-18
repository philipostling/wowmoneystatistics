local _, addon = ...

local mt = addon.mt
local util = addon.utility
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local MERCH_UUID = 'MERCH_01'    -- Profits or Expenses from a Merchant
local REPAIR_UUID = 'MERCH_02'   -- Expenses from Repairing armor

local money
local repairCost
local bagValue
local bagItemCount
local UsedGB = false

-- Rational: This need to be a MainTracker function for testing
function mt.GetBagsValue()
   local value = 0
   local itemCount = 0
   for i = 0, NUM_BAG_FRAMES do
      for j = 1, C_Container.GetContainerNumSlots(i) do
         local count = select(2, C_Container.GetContainerItemInfo(i, j))
         local hasNoValue, itemID = select(9, C_Container.GetContainerItemInfo(i, j))

         if count then
            itemCount = itemCount + count
            if hasNoValue == false and itemID then
               local sellPrice = select(11, GetItemInfo(itemID))
               value = value + (count * sellPrice)
            end
         end
      end
   end

   return value, itemCount
end

local function OnActivation(...)
   money = GetMoney()
   addon.debugPrint("MerchantTracker", money)
   repairCost = GetRepairAllCost()
   bagValue, bagItemCount = mt.GetBagsValue()
end

local function OnDeactivation(...)
   util.ItemLocationCleanup()
end

local function Classify(uuid)
   local rc, cr = GetRepairAllCost()
   local bv, ic = mt.GetBagsValue()
   local m = GetMoney()
   addon.debugPrint("MerchantTracker", m)
   local cost = m - money

   local TotalRepairCost = rc - repairCost
   local bagValueDelta = bagValue - bv
   local bagItemDelta = bagItemCount - ic
   local repaired = rc ~= repairCost

   addon.debugPrint(cost, bv, bagValueDelta, bagItemDelta, repaired)

   if repaired and (cost == bagValueDelta) then
      -- Rational: If the Guild Bank picked up the tab no need for the addon to track it
      -- In this case the change in GetMoney is the same as what I would expect from
      -- the change in value of items in the users bags
      repaired = false
      repairCost = rc
   end
   
   if uuid == REPAIR_UUID and CanMerchantRepair() then
      if repaired == true and TotalRepairCost ~= 0 then
         repairCost = rc
         repaired = false
         money = money + TotalRepairCost
         addon.debugPrint("Classify: ", uuid, TotalRepairCost)
         return REPAIR_UUID, TotalRepairCost
      end
   end

   if uuid == MERCH_UUID then
      -- Reset bagValue and itemCount
      bagValue = bv
      bagItemCount = ic

      if repaired and cost ~= 0 then
         cost = cost + TotalRepairCost
      end

      if cost ~= 0 then
         if (cost > 0 and bagValueDelta > 0) or -- Made money and bag value decreased
            (cost < 0 and (bagValueDelta < 0 or -- Lost money and bag value increased
            (bagValueDelta == 0 and bagItemDelta < 0))) then -- Bag value remained constant but item count increased
            money = m
            addon.debugPrint("Classify: ", uuid, cost)
            return MERCH_UUID, cost
         elseif (bagValueDelta == 0 and bagItemDelta == 0) then
            -- Rational: Provide an unspecified determinant here due to the likelihood that the BAG_UPDATE event has not happened yet
            --             OR the possiblity the user was buying something from a vendor that did not go to the bags, ie something for a quest.
            addon.debugPrint("Classify: ", uuid, 0)
            return MERCH_UUID, 0
         end
      end
   end
end

local function OnTrigger(uuid, t, m)
   if uuid == REPAIR_UUID then
      if m < 0 then
         local money = math.abs(m)
         _G.WOWMSTracker[realm].AllChars[t].Spent = _G.WOWMSTracker[realm].AllChars[t].Spent + money
         _G.WOWMSTracker[realm][player][t].Spent = _G.WOWMSTracker[realm][player][t].Spent + money
      else
         m = 0
         addon.debugError("ERROR - Repair that we earned money from?!")
      end
   else
      if m > 0 then
         _G.WOWMSTracker[realm].AllChars[t].Earned = _G.WOWMSTracker[realm].AllChars[t].Earned + m
         _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned + m
      else
         local money = math.abs(m)
         _G.WOWMSTracker[realm].AllChars[t].Spent = _G.WOWMSTracker[realm].AllChars[t].Spent + money
         _G.WOWMSTracker[realm][player][t].Spent = _G.WOWMSTracker[realm][player][t].Spent + money
      end
   end
   local pcash = _G.WOWMMGlobal[realm].Chars[player].Cash
   local cash = pcash + m
   util.UpdateEarnedSpent(cash, pcash)
   util.UpdatePlayerCash(cash)
   if m > 0 then
      -- Rational: We only want to check different zones when we are selling to a vendor
      util.UpdateZoneEarnedSpent(m, true)
   else
      util.UpdateZoneEarnedSpent(m)
   end
end

mt.RegisterDeterminant(REPAIR_UUID, 'PLAYER_MONEY', Classify)
mt.RegisterDeterminant(MERCH_UUID, 'PLAYER_MONEY', Classify)
mt.RegisterTracker(MERCH_UUID, 'MERCH', 'MERCHANT_SHOW', 'MERCHANT_CLOSED', OnTrigger)
mt.RegisterTracker(REPAIR_UUID, 'REPAIR', 'MERCHANT_SHOW', 'MERCHANT_CLOSED', OnTrigger)
mt.RegisterOnActivation(MERCH_UUID, OnActivation)
mt.RegisterOnActivation(REPAIR_UUID, OnActivation)
mt.RegisterOnDeactivation(MERCH_UUID, OnDeactivation)
--TODO: Make a Grey / Green / Blue / Purple items catagory?
--TODO: Food / reagents / cooking supplies / ...
