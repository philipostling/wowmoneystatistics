local _, addon = ...

local mt = addon.mt
local util = addon.utility
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local NORMAL_QUEST = 'QUEST_01'     -- Profits or Expenses from Normal Quests
local BONUS_OBJ_QUEST = 'QUEST_02'  -- Profits from Bonus Objective Quests
local WORLD_BOSS_QUEST = 'QUEST_03' -- Profits from World Boss Quests

local QuestFrame = CreateFrame("Frame")

-- [CreatureID] = QuestID
local WorldBosses = {
   -- Battle for Azeroth--
   -- Nazmir
   [132701] = 52181, -- T'zane
   -- Zuldazar
   [132253] = 52169, -- Ji'arak
   [132653] = 52169, -- Ji'arak Broodling (Ji'arak)
   -- Drustvar
   [140252] = 52157, -- Hailstone Construct
   -- Arathi Highlands
   [137374] = 52848, -- The Lion's Roar
   [143600] = 52848, -- Lion's Engineer (The Lion's Roar)
   [143601] = 52848, -- Lion's Shieldbearer (The Lion's Roar)
   [143602] = 52848, -- Lion's Warcaster (The Lion's Roar)
   -- Tiragarde Sound
   [136385] = 52163, -- Azurethos, The Winged Typhoon
   -- Stormsong Valley
   [140163] = 52166, -- Warbringer Yenajz
   -- Vol'dun
   [138794] = 52196, -- Dunegorger Kraulok
   [139614] = 52196, -- Ravenous Ranishu (Dunegorger Kraulok)
   -- Darkshore
   [144946] = 54896, -- Ivus the Forest Lord
   -- Nazjatar
   [152671] = 56056, -- Wekemara
   [155702] = 56056, -- Spawn of Wekemara (Wekemara)
   [152697] = 56057, -- Ulmath, the Soulbinder
   [152736] = 56057, -- Guardian Tannin (Ulmath, the Soulbinder)
   [152729] = 56057, -- Moon Priestess Liara (Ulmath, the Soulbinder)
   -- Vale of Eternal Blossoms
   [154638] = 58705, -- Grand Empress Shek'zara
   [161370] = 58705, -- Zara'thik Swarmguard (Grand Empress Shek'zara)
   [161371] = 58705, -- Zara'thik Ambershaper (Grand Empress Shek'zara)
   -- Uldum
   [160970] = 55466, -- Vuk'laz the Earthbreaker
   [161541] = 55466, -- Aqir Scarab (Vuk'laz the Earthbreaker)
}

local function OnTrigger(uuid, t, m)
   if m > 0 then
      _G.WOWMSTracker[realm].AllChars[t].Earned = _G.WOWMSTracker[realm].AllChars[t].Earned + m
      _G.WOWMSTracker[realm][player][t].Earned = _G.WOWMSTracker[realm][player][t].Earned + m
   else
      local money = math.abs(m)
      _G.WOWMSTracker[realm].AllChars[t].Spent = _G.WOWMSTracker[realm].AllChars[t].Spent + money
      _G.WOWMSTracker[realm][player][t].Spent = _G.WOWMSTracker[realm][player][t].Spent + money
   end
   local pcash = _G.WOWMMGlobal[realm].Chars[player].Cash
   local cash = pcash + m
   util.UpdateEarnedSpent(cash, pcash)
   util.UpdatePlayerCash(cash)
   util.UpdateZoneEarnedSpent(m)
end

local function BonusObjectiveClassifier(uuid, qID, xpR, mR)
   addon.debugPrint("BonusObjectiveClassifier")
   if uuid == BONUS_OBJ_QUEST then
      return uuid, mR
   end
end

local function GetIDFromGUID(guid)
   guid = tostring(guid)
   local i
   local c = 0

   -- Creature GUID Format
   -- [Unit type]-0-[server ID]-[instance ID]-[zone UID]-[ID]-[spawn UID]
   while c ~= 5 do
      i = strfind(guid, '-')
      if not i then
         return nil
      end

      guid = strsub(guid, i + 1)
      c = c + 1
   end

   i = strfind(guid, '-')
   if not i then
      return nil
   end
   return tonumber(strsub(guid, 1, i - 1))
end

local function WorldBossClassifier(uuid, ...)
   local sourceGUID, sourceName, _, _, destinationGUID, destinationName = select(4, CombatLogGetCurrentEventInfo())

   local enemy
   if sourceName == player then
      enemy = GetIDFromGUID(destinationGUID)
   elseif destinationName == player then
      enemy = GetIDFromGUID(sourceGUID)
   end

   if enemy then
      for k, v in pairs(WorldBosses) do
         if enemy and enemy == k and C_QuestLog.IsQuestFlaggedCompleted(v) == false then
            addon.debugPrint("Classify", uuid, enemy)
            return uuid, 0
         end
      end
   end
end

local function HandleLoot(uuid, event, qID, itemLink, quantity)
   if itemLink then
      local itemID = util.LinkToID(itemLink)
      if itemID ~= 0 then
         local sellPrice = select(11, GetItemInfo(itemID))
         if sellPrice > 0 and quantity and quantity > 0 then
            util.StoreItemLocation(itemID, quantity)
         end
      end
   end
end

mt.RegisterInformationEvent(NORMAL_QUEST, 'QUEST_LOOT_RECEIVED', HandleLoot, false)
mt.RegisterTracker(NORMAL_QUEST, 'QUEST', 'QUEST_COMPLETE','QUEST_FINISHED', OnTrigger)

mt.RegisterDeterminant(WORLD_BOSS_QUEST, 'COMBAT_LOG_EVENT_UNFILTERED', WorldBossClassifier)
mt.RegisterTracker(WORLD_BOSS_QUEST, 'QUEST', 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED', OnTrigger)

mt.RegisterDeterminant(BONUS_OBJ_QUEST, 'QUEST_TURNED_IN', BonusObjectiveClassifier)
mt.RegisterTracker(BONUS_OBJ_QUEST, 'QUEST', 'PLAYER_ENTERING_WORLD', nil, OnTrigger)
