local _, addon = ...

local mt = addon.mt
local util = addon.utility
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local LOOT_UUID = 'LOOT_01'   -- Profits from Looting dead things
local Money = {}
local Loot = {}
local Classified = {}

local Match = 
{
   Copper = "(%d+) Copper",
   Silver = "(%d+) Silver",
   Gold   = "(%d+) Gold"
}

local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 100 * COPPER_PER_SILVER

local LootFrame = CreateFrame("Frame")

local function OnTrigger(uuid, t, m)
   if m >= 0 then
      _G.WOWMSTracker[realm].AllChars[t].Earned = _G.WOWMSTracker[realm].AllChars[t].Earned + m
      _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned + m

      local pcash = _G.WOWMMGlobal[realm].Chars[player].Cash
      local cash = pcash + m
      util.UpdateEarnedSpent(cash, pcash)
      util.UpdatePlayerCash(cash)
      util.UpdateZoneEarnedSpent(m)
   else
      addon.debugError("Losing money while looting?!")
   end
end

local function OnActivation(...)
   local num = GetNumLootItems()
   for i = 1, num do
      local item = select(2, GetLootSlotInfo(i)) or ""
      local link = GetLootSlotLink(i)

      local c = string.match(item, Match.Copper) or 0
      local s = string.match(item, Match.Silver) or 0
      local g = string.match(item, Match.Gold) or 0
      c = (g * COPPER_PER_GOLD) + (s * COPPER_PER_SILVER) + c
      table.insert(Money, c)

      if link then
         local itemID = util.LinkToID(link)
         if itemID ~= 0 then
            local quantity = select(3, GetLootSlotInfo(i))
            local price = select(11, GetItemInfo(itemID))
            if itemID and price > 0 then
               util.addToSet(Loot, i, { ID = itemID, Quantity = quantity })
            end
         end
      end
   end
end

local function Cleanup()
   Money = {}
   Loot = {}
   Classified = {}
end

local function OnDeactivation(...)
   -- Rational: If the user has auto loot on and happens to move while looting,
   -- it is possible that the LOOT_CLOSED event happens before the LOOT_SLOT_CLEARED(s)
   -- Need to still handle the loot
   LootFrame:SetScript('OnUpdate', function(self, elapsed)
                                       self.Elapsed = (self.Elapsed or 0) + elapsed
                                       if self.Elapsed > 1 then
                                          for k, v in pairs(Loot) do
                                             if not util.setContains(Classified, k) then
                                                if v and v.ID and v.Quantity then
                                                   util.StoreItemLocation(v.ID, v.Quantity)
                                                end
                                             end
                                          end
                                          Cleanup()
                                          self:SetScript('OnUpdate', nil)
                                       end
                                   end)
end

local function Classify(uuid, slot)
   addon.debugPrint("Classify", uuid, slot)
   if util.setContains(Classified, slot) then
      return
   end

   if uuid == LOOT_UUID then
      if Money[slot] and Money[slot] > 0 then
         util.addToSet(Classified, slot, slot)
         addon.debugPrint("Classified", uuid, slot)
         return uuid, Money[slot]
      else
         util.addToSet(Classified, slot, slot)
         local item = util.getSetValue(Loot, slot)
         if item and item.ID and item.Quantity then
            util.StoreItemLocation(item.ID, item.Quantity)
         end
      end
   end
end

mt.RegisterDeterminant(LOOT_UUID, 'LOOT_SLOT_CLEARED', Classify)
mt.RegisterTracker(LOOT_UUID, 'LOOT', 'LOOT_OPENED', 'LOOT_CLOSED', OnTrigger)
mt.RegisterOnActivation(LOOT_UUID, OnActivation)
mt.RegisterOnDeactivation(LOOT_UUID, OnDeactivation)
