local _, addon = ...

local mt = addon.mt
local util = addon.utility
local _G = _G

local player = UnitName("player")
local realm = GetRealmName()

local TAXI_UUID = 'TAXI_01'                        -- Expenses from taking a Flight Path
local TRADE_UUID = 'TRADE_01'                      -- Profits and Expenses through Trade
local TRAINER_UUID = 'TRAINER_01'                  -- Expenses from Profession Trainers
local AUCTION_UUID = 'AUCTION_01'                  -- Expenses from the Auction House
local BMAH_UUID = 'BMAH_01'                        -- Expenses from the Black Market Auction House
local GARRISION_ARCHITECT_UUID = 'G_ARCHITECT_01'  -- Expenses at the Garrision Architect
local MISSION_TABLE_UUID = 'G_MISSION_01'          -- Profits from the Mission Table
local SHIPYARD_UUID = 'G_SHIPYARD_01'              -- Expenses at the Garrision Shipyard
local TRANSMOG_UUID = 'TRANSMOG_01'                -- Expenses from Transmogrification
local VOID_STORAGE_UUID = 'VOID_01'                -- Expenses from the Void Storage
local AZERITE_REFORGE_UUID = 'AZERITEREFORGE_01'   -- Expenses from the Azerite Reforger
local BARBER_UUID = 'BARBER_01'                    -- Expenses from the Barber

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

mt.RegisterTracker(TAXI_UUID, 'TAXI', 'TAXIMAP_OPENED', 'TAXIMAP_CLOSED', OnTrigger)
mt.RegisterTracker(TRADE_UUID, 'TRADE', 'TRADE_SHOW', 'TRADE_CLOSED', OnTrigger)
mt.RegisterTracker(TRAINER_UUID, 'TRAINER', 'TRAINER_SHOW', 'TRAINER_CLOSED', OnTrigger)
mt.RegisterTracker(AUCTION_UUID, 'AUCTION', 'AUCTION_HOUSE_SHOW', 'AUCTION_HOUSE_CLOSED', OnTrigger)
mt.RegisterTracker(BMAH_UUID, 'BMAH', 'BLACK_MARKET_OPEN', 'BLACK_MARKET_CLOSE', OnTrigger)
mt.RegisterTracker(GARRISION_ARCHITECT_UUID, 'ARCHITECT', 'GARRISON_ARCHITECT_OPENED', 'GARRISON_ARCHITECT_CLOSED', OnTrigger)
mt.RegisterTracker(MISSION_TABLE_UUID, 'MISSION', 'GARRISON_MISSION_NPC_OPENED', 'GARRISON_MISSION_NPC_CLOSED', OnTrigger)
mt.RegisterTracker(SHIPYARD_UUID, 'SHIPYARD', 'GARRISON_SHIPYARD_NPC_OPENED', 'GARRISON_SHIPYARD_NPC_CLOSED', OnTrigger)
mt.RegisterTracker(TRANSMOG_UUID, 'TRANSMOG', 'TRANSMOGRIFY_OPEN', 'TRANSMOGRIFY_CLOSE', OnTrigger)
mt.RegisterTracker(VOID_STORAGE_UUID, 'VOID', 'VOID_STORAGE_UPDATE', 'VOID_TRANSFER_DONE', OnTrigger)
mt.RegisterTracker(AZERITE_REFORGE_UUID, 'AZERITEREFORGE', 'AZERITE_ESSENCE_FORGE_OPEN', 'AZERITE_ESSENCE_FORGE_CLOSE', OnTrigger)
mt.RegisterTracker(BARBER_UUID, 'BARBER', 'BARBER_SHOP_OPEN', 'BARBER_SHOP_CLOSE', OnTrigger)
