local _, addon = ...

local mt = addon.mt
local util = addon.utility
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local BAG_UUID = 'BAG_01'                       -- Income from items in your bags such as pet supplies

local BagTracker = CreateFrame("Frame")         -- Hidden Frame used for holding information about the current contents of the players bags

local LootableItems = {}

-- Pet Supplies
util.addToSet(LootableItems, 127751) -- Fel-Touched Pet Supplies
util.addToSet(LootableItems, 143753) -- Damp Pet Supplies
util.addToSet(LootableItems, 146317) -- Mr. Smite's Supplies
util.addToSet(LootableItems, 165839) -- Unopened Gnomeregan Supply Box
util.addToSet(LootableItems, 118697) -- Big Bag of Pet Supplies
util.addToSet(LootableItems, 122535) -- Traveler's Pet Supplies
util.addToSet(LootableItems, 116414) -- Pet Supplies
util.addToSet(LootableItems, 151638) -- Leprous Sack of Pet Supplies
util.addToSet(LootableItems, 142447) -- Torn Sack of Pet Supplies
util.addToSet(LootableItems, 98095)  -- Brawler's Pet Supplies
util.addToSet(LootableItems, 94207)  -- Fabled Pandaren Pet Supplies
util.addToSet(LootableItems, 93146)  -- Pandaren Spirit Pet Supplies (Burning)
util.addToSet(LootableItems, 93147)  -- Pandaren Spirit Pet Supplies (Flowing)
util.addToSet(LootableItems, 93148)  -- Pandaren Spirit Pet Supplies (Whispering)
util.addToSet(LootableItems, 93149)  -- Pandaren Spirit Pet Supplies (Thundering)

util.addToSet(LootableItems, 120321) -- Mystery Bag

util.addToSet(LootableItems, 98134)  -- Heroic Cache of Treasures
util.addToSet(LootableItems, 98546)  -- Bulging Heroic Cache of Treasures

-- Legion emissary
util.addToSet(LootableItems, 152102) -- Farondis Chest
util.addToSet(LootableItems, 152103) -- Dreamweaver Cache
util.addToSet(LootableItems, 152104) -- Highmountain Supplies
util.addToSet(LootableItems, 152105) -- Nightfallen Cache
util.addToSet(LootableItems, 152106) -- Valarjar Strongbox
util.addToSet(LootableItems, 152107) -- Warden's Supply Kit
util.addToSet(LootableItems, 152108) -- Legionfall Chest
util.addToSet(LootableItems, 152922) -- Brittle Krokul Chest
util.addToSet(LootableItems, 152923) -- Gleaming Footlocker
util.addToSet(LootableItems, 157822) -- Dreamweaver Provisions
util.addToSet(LootableItems, 157823) -- Highmountain Tribute
util.addToSet(LootableItems, 157824) -- Valarjar Cache
util.addToSet(LootableItems, 157825) -- Farondis Lockbox
util.addToSet(LootableItems, 157826) -- Nightfallen Hoard
util.addToSet(LootableItems, 157827) -- Warden's Field Kit
util.addToSet(LootableItems, 157828) -- Kirin Tor Chest
util.addToSet(LootableItems, 157829) -- Gilded Trunk
util.addToSet(LootableItems, 157830) -- Legionfall Spoils
util.addToSet(LootableItems, 157831) -- Scuffed Krokul Cache

-- Not sure if I need to add these.
--util.addToSet(LootableItems, 163857) -- Azerite Armor Cache
--util.addToSet(LootableItems, 165863) -- Zandalari Weapons Cache
--util.addToSet(LootableItems, 165864) -- Voldunai Equipment Cache
--util.addToSet(LootableItems, 165866) -- Zandalari Empire Equipment Cache
--util.addToSet(LootableItems, 165869) -- Proudmoore Admiralty Equipment Cache
--util.addToSet(LootableItems, 165870) -- Order of Embers Equipment Cache
--util.addToSet(LootableItems, 165871) -- Honorbound Equipment Cache
--util.addToSet(LootableItems, 165872) -- 7th Legion Equipment Cache

-- BFA emissary
util.addToSet(LootableItems, 166245) -- Tortollan Seekers Supplies
util.addToSet(LootableItems, 166282) -- Talanji's Expedition Supplies
util.addToSet(LootableItems, 166290) -- Voldunai Supplies
util.addToSet(LootableItems, 166292) -- Zandalari Empire Supplies
util.addToSet(LootableItems, 166294) -- Storm's Wake Supplies
util.addToSet(LootableItems, 166295) -- Proudmoore Admiralty Supplies
util.addToSet(LootableItems, 166297) -- Order of Embers Supplies
util.addToSet(LootableItems, 166298) -- Champions of Azeroth Supplies
util.addToSet(LootableItems, 166299) -- Honorbound Supplies
util.addToSet(LootableItems, 166300) -- 7th Legion Supplies
util.addToSet(LootableItems, 169940) -- Unshackled Supplies
util.addToSet(LootableItems, 169939) -- Ankoan Supplies

local BagLootables = {}
local BagLootableCount = {}

local PreviousLootableCount = 0

local function OnTrigger(uuid, t, m)
   if m > 0 then
      _G.WOWMSTracker[realm].AllChars[t].Earned = _G.WOWMSTracker[realm].AllChars[t].Earned + m
      _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned + m

      local pcash = _G.WOWMMGlobal[realm].Chars[player].Cash
      local cash = pcash + m
      util.UpdateEarnedSpent(cash, pcash)
      util.UpdatePlayerCash(cash)
      util.UpdateZoneEarnedSpent(m)
   else
      addon.debugError("Losing money from looting a container item?!")
   end
end

local function GetBagSlotIdx(bag, slot)
   return (bag * 100) + slot
end

local function ClearBag(bag)
   for i = 1, C_Container.GetContainerNumSlots(bag) do
      local idx = GetBagSlotIdx(bag, i)
      util.removeFromSet(BagLootables, idx)
      util.removeFromSet(BagLootableCount, idx)
   end
end

local function GetLootableCount()
   local count = 0
   for _, v in pairs(BagLootableCount) do
      count = count + v
   end

   return count
end

local function CatalogLootableBagItems()
   PreviousLootableCount = GetLootableCount()

   for bag = 0, NUM_BAG_FRAMES do
      ClearBag(bag)

      for i = 1, C_Container.GetContainerNumSlots(bag) do
         local count = select(2, C_Container.GetContainerItemInfo(bag, i))
         local lootable = select(6, C_Container.GetContainerItemInfo(bag, i))
         local itemID = select(10, C_Container.GetContainerItemInfo(bag, i))
         if lootable or util.setContains(LootableItems, itemID) then
            local idx = GetBagSlotIdx(bag, i)
            util.addToSet(BagLootables, idx, itemID)
            util.addToSet(BagLootableCount, idx, count)
            addon.debugPrint("Lootable", itemID)
         end
      end
   end

   addon.debugPrint("Lootable items count: ", GetLootableCount(), PreviousLootableCount)
end

local function EventHandler(self, event, ...)
   addon.debugPrint("BagTracker Event", event, ...)
   CatalogLootableBagItems(bag)
end

local function Classify(uuid)
   addon.debugPrint("BagTracker", "Classify")
   CatalogLootableBagItems()
   if PreviousLootableCount > GetLootableCount() then
      addon.debugPrint("BagTracker", "Looted a lootable item")
      return uuid, 0
   end
end

-- Order matters here
util.RegisterEvents(BagTracker, EventHandler, 'PLAYER_ENTERING_WORLD')
mt.RegisterDeterminant(BAG_UUID, 'BAG_UPDATE', Classify)

-- The intention is to have this Tracker always on
mt.RegisterTracker(BAG_UUID, 'LOOT', 'PLAYER_ENTERING_WORLD', nil, OnTrigger)
