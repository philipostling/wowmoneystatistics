--TODO: Add my own event framework?
local addon_name, addon = ...
local util = addon.utility

local core = addon.core
local time = addon.time
local fonts = addon.fonts
local profile = addon.profile
local mt = addon.mt
local sd = addon.statDisplay
local _G = _G

function util.addToSet(set, key, value)
   if value == nil then
      value = true
   end

   set[key] = value
end

function util.removeFromSet(set, key)
   set[key] = nil
end

function util.setContains(set, key)
   return set[key] ~= nil
end

function util.getSetValue(set, key)
   return set[key]
end

local Region

local ClassColors = {}
util.addToSet(ClassColors,"DEATHKNIGHT",0xC41F3B)
util.addToSet(ClassColors,"DEMONHUNTER",0xA330C9)
util.addToSet(ClassColors,"DRUID"      ,0xFF7D0A)
util.addToSet(ClassColors,"HUNTER"     ,0xABD473)
util.addToSet(ClassColors,"MAGE"       ,0x69CCF0)
util.addToSet(ClassColors,"MONK"       ,0x00FF96)
util.addToSet(ClassColors,"PALADIN"    ,0xF58CBA)
util.addToSet(ClassColors,"PRIEST"     ,0xFFFFFF)
util.addToSet(ClassColors,"ROGUE"      ,0xFFF569)
util.addToSet(ClassColors,"SHAMAN"     ,0x0070DE)
util.addToSet(ClassColors,"WARLOCK"    ,0x9482C9)
util.addToSet(ClassColors,"WARRIOR"    ,0xC79C6E)
util.addToSet(ClassColors,"EMPHASIS"   ,0x00C800)
util.addToSet(ClassColors,"HEADER"     ,0xFDC803)

local GoldIcon    = "|TInterface\\MoneyFrame\\UI-GoldIcon:12:12|t"
local SilverIcon  = "|TInterface\\MoneyFrame\\UI-SilverIcon:12:12|t"
local CopperIcon  = "|TInterface\\MoneyFrame\\UI-CopperIcon:12:12|t"

local LDBinteraction = false

local realm = GetRealmName()
local _, class = UnitClass("player")
local player = UnitName("player")
local faction = UnitFactionGroup("player")

local SubjectPatterns = 
{
   AHOutbid       = gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", ".*"),
   AHSuccess      = gsub(AUCTION_SOLD_MAIL_SUBJECT, "%%s", ".*"),
   CODPayment     = gsub(COD_PAYMENT, "%%s", ".*"),
}

util.FactionList = { "Alliance", "Horde", "Neutral" }

function util.GetIncomingMailType(subject)
	if subject then
		for k, v in pairs(SubjectPatterns) do
         if subject:find(v) then return k end
		end
	end
	return "NONE"
end

function util.IsAlt(name)
   for n, _ in pairs(_G.WOWMMGlobal[realm].Chars) do
      if n == name then return true end
   end
   return false
end

function util.LinkToID(link)
   if not link then return 0 end
   local itemID = link:match("item:(%d+):")
   itemID = tonumber(itemID)
   if itemID == nil then return 0 end
   return itemID
end

function util.UpdateEarnedSpent(cash, pcash)
   if pcash ~= nil then
      if cash >= pcash then
         local earned = cash - pcash
         _G.WOWMMGlobal[realm].AllTime.Earned = _G.WOWMMGlobal[realm].AllTime.Earned + earned
         _G.WOWMMGlobal[realm].Year.Earned = _G.WOWMMGlobal[realm].Year.Earned + earned
         _G.WOWMMGlobal[realm].Month.Earned = _G.WOWMMGlobal[realm].Month.Earned + earned
         _G.WOWMMGlobal[realm].Week.Earned = _G.WOWMMGlobal[realm].Week.Earned + earned
         _G.WOWMMGlobal[realm].Day.Earned = _G.WOWMMGlobal[realm].Day.Earned + earned
         _G.WOWMMGlobal[realm].Session.Earned = _G.WOWMMGlobal[realm].Session.Earned + earned

         _G.WOWMMGlobal[realm].AllTime[faction].Earned = _G.WOWMMGlobal[realm].AllTime[faction].Earned + earned
         _G.WOWMMGlobal[realm].Year[faction].Earned = _G.WOWMMGlobal[realm].Year[faction].Earned + earned
         _G.WOWMMGlobal[realm].Month[faction].Earned = _G.WOWMMGlobal[realm].Month[faction].Earned + earned
         _G.WOWMMGlobal[realm].Week[faction].Earned = _G.WOWMMGlobal[realm].Week[faction].Earned + earned
         _G.WOWMMGlobal[realm].Day[faction].Earned = _G.WOWMMGlobal[realm].Day[faction].Earned + earned
         _G.WOWMMGlobal[realm].Session[faction].Earned = _G.WOWMMGlobal[realm].Session[faction].Earned + earned
      else
         local spent = pcash - cash
         _G.WOWMMGlobal[realm].AllTime.Spent = _G.WOWMMGlobal[realm].AllTime.Spent + spent
         _G.WOWMMGlobal[realm].Year.Spent = _G.WOWMMGlobal[realm].Year.Spent + spent
         _G.WOWMMGlobal[realm].Month.Spent = _G.WOWMMGlobal[realm].Month.Spent + spent
         _G.WOWMMGlobal[realm].Week.Spent = _G.WOWMMGlobal[realm].Week.Spent + spent
         _G.WOWMMGlobal[realm].Day.Spent = _G.WOWMMGlobal[realm].Day.Spent + spent
         _G.WOWMMGlobal[realm].Session.Spent = _G.WOWMMGlobal[realm].Session.Spent + spent

         _G.WOWMMGlobal[realm].AllTime[faction].Spent = _G.WOWMMGlobal[realm].AllTime[faction].Spent + spent
         _G.WOWMMGlobal[realm].Year[faction].Spent = _G.WOWMMGlobal[realm].Year[faction].Spent + spent
         _G.WOWMMGlobal[realm].Month[faction].Spent = _G.WOWMMGlobal[realm].Month[faction].Spent + spent
         _G.WOWMMGlobal[realm].Week[faction].Spent = _G.WOWMMGlobal[realm].Week[faction].Spent + spent
         _G.WOWMMGlobal[realm].Day[faction].Spent = _G.WOWMMGlobal[realm].Day[faction].Spent + spent
         _G.WOWMMGlobal[realm].Session[faction].Spent = _G.WOWMMGlobal[realm].Session[faction].Spent + spent
      end
   end
end

local function DetermineItemsZones(money, checkZone)
   local SoldItems = {}
   local Zones = {}
   local Items = {}
   if checkZone then
      local numItems = GetNumBuybackItems()

      local idx = 1
      for i = 1, numItems do
         local price, quantity = select(3, GetBuybackItemInfo(i))
         local link = GetBuybackItemLink(i)
         local itemID = util.LinkToID(link)
         
         if _G.WOWMSZoneLoot[itemID] and quantity <= _G.WOWMSZoneLoot[itemID].Quantity then
            util.addToSet(SoldItems, idx, { ID = itemID, P = price, Q = quantity })
            idx = idx + 1
         end
      end

      local totalPrice = 0
      for i = #SoldItems, 1, -1 do
         if SoldItems[i] then
            local k, v = SoldItems[i].ID, SoldItems[i]
            if v.P <= money then
               totalPrice = totalPrice + v.P
               util.addToSet(Items, v.ID, v)

               if totalPrice >= money then
                  break
               end
            end
         end
      end

      if money ~= totalPrice then
         util.addToSet(Zones, GetRealZoneText(), money)
         return Zones
      end

      for ID, values in pairs(Items) do
         local quantity = values.Q
         local price = values.P
         local totalQuantity = quantity
         if ID and _G.WOWMSZoneLoot[ID] then
            for k, v in pairs(_G.WOWMSZoneLoot[ID]) do
               if k ~= "Quantity" then
                  if _G.WOWMSZoneLoot[ID][k] < quantity then
                     local p = (_G.WOWMSZoneLoot[ID][k] / totalQuantity) * price
                     quantity = quantity - _G.WOWMSZoneLoot[ID][k]
                     util.addToSet(Zones, k, p)
                     _G.WOWMSZoneLoot[ID].Quantity = _G.WOWMSZoneLoot[ID].Quantity - _G.WOWMSZoneLoot[ID][k]
                     _G.WOWMSZoneLoot[ID][k] = 0
                     money = money - p
                  else
                     local p = (quantity / totalQuantity) * price
                     _G.WOWMSZoneLoot[ID].Quantity = _G.WOWMSZoneLoot[ID].Quantity - quantity
                     _G.WOWMSZoneLoot[ID][k] = _G.WOWMSZoneLoot[ID][k] - quantity
                     util.addToSet(Zones, k, p)
                     quantity = 0
                     money = money - p
                  end
               end

               if quantity == 0 then
                  break
               end
            end

            if quantity ~= 0 then
               util.addToSet(Zones, GetRealZoneText(), money)
            end
         else
            util.addToSet(Zones, GetRealZoneText(), money)
         end
      end
   else
      util.addToSet(Zones, GetRealZoneText(), money)
   end
   return Zones
end

function util.UpdateZoneEarnedSpent(money, checkZone)
   for k, v in pairs(DetermineItemsZones(money, checkZone)) do
      _G.WOWMSZone[realm].AllChars[k] = _G.WOWMSZone[realm].AllChars[k] or {}
      _G.WOWMSZone[realm].AllChars[k].Earned = _G.WOWMSZone[realm].AllChars[k].Earned or 0
      _G.WOWMSZone[realm].AllChars[k].Spent = _G.WOWMSZone[realm].AllChars[k].Spent or 0

      _G.WOWMSZone[realm][player][k] = _G.WOWMSZone[realm][player][k] or {}
      _G.WOWMSZone[realm][player][k].Earned = _G.WOWMSZone[realm][player][k].Earned or 0
      _G.WOWMSZone[realm][player][k].Spent = _G.WOWMSZone[realm][player][k].Spent or 0
      if v > 0 then
         _G.WOWMSZone[realm].AllChars[k].Earned = _G.WOWMSZone[realm].AllChars[k].Earned + v
         _G.WOWMSZone[realm][player][k].Earned = _G.WOWMSZone[realm][player][k].Earned + v
      else
         local v = math.abs(v)
         _G.WOWMSZone[realm].AllChars[k].Spent = _G.WOWMSZone[realm].AllChars[k].Spent + v
         _G.WOWMSZone[realm][player][k].Spent = _G.WOWMSZone[realm][player][k].Spent + v
      end
   end
end

function util.StoreItemLocation(itemID, quantity)
   local zoneID = GetRealZoneText()
   if _G.WOWMSZoneLoot[itemID] then
      if _G.WOWMSZoneLoot[itemID][zoneID] then
         _G.WOWMSZoneLoot[itemID][zoneID] = _G.WOWMSZoneLoot[itemID][zoneID] + quantity
      else
         _G.WOWMSZoneLoot[itemID][zoneID] = quantity
      end
      _G.WOWMSZoneLoot[itemID].Quantity = _G.WOWMSZoneLoot[itemID].Quantity + quantity
   else
      _G.WOWMSZoneLoot[itemID] = {}
      _G.WOWMSZoneLoot[itemID][zoneID] = quantity
      _G.WOWMSZoneLoot[itemID].Quantity = quantity
   end
end

function util.ItemLocationCleanup()
   -- Look through bags to find itemIDs
   local IDs = {}
   for i = 0, NUM_BAG_FRAMES do
      for j = 1, C_Container.GetContainerNumSlots(i) do
         local itemID = select(10, C_Container.GetContainerItemInfo(i, j))

         if itemID ~= nil then
            itemID = tonumber(itemID)
            util.addToSet(IDs, itemID, itemID)
         end
      end
   end

   for k, v in pairs(_G.WOWMSZoneLoot) do
      if v.Quantity == 0 or IDs[k] == nil then
         _G.WOWMSZoneLoot[k] = nil
      end
   end
end

function util.UpdatePlayerCash(cash)
   if not cash then
      cash = GetMoney()
      addon.debugPrint("UtilMoney", cash)
   end

   if not _G.WOWMMGlobal[realm].Chars[player] then
      util.setupCurrentPlayer()
   end

   _G.WOWMMGlobal[realm].Chars[player].Cash = cash
   _G.WOWMMGlobal[realm].Classes[player] = class
   _G.WOWMMGlobal[realm].Total = util.GetRealmTotalCash(realm)
end

function util.UpdateAltMoneyXfer(sender, receiver, money)
   local senderAlt = util.IsAlt(sender)
   local receiverAlt = util.IsAlt(receiver)

   if senderAlt and receiverAlt then
      local currentXferd = _G.WOWMMGlobal[realm].MoneyXfer[sender][receiver] or 0
      -- When sending money, the value of the money input is negative and vice versa.
      -- Switch the sign for this storage
      currentXferd = currentXferd - money
      if currentXferd < 0 then
         currentXferd = 0
      end
      _G.WOWMMGlobal[realm].MoneyXfer[sender][receiver] = currentXferd

      util.SetPlayerMailIndicator(receiver, currentXferd > 0, true)
   end
end

function util.ClearAltMoneyXfer(char)
   util.SetPlayerMailIndicator(char, false, true)

   for k, v in pairs(_G.WOWMMGlobal[realm].MoneyXfer) do
      addon.debugPrint(k)
      if k ~= char then
         for kk, vv in pairs(v) do
            addon.debugPrint(kk, vv)
            if kk == char then
               _G.WOWMMGlobal[realm].MoneyXfer[k][kk] = nil
            end
         end
      end
   end
end

function util.SetPlayerMailIndicator(p, v, isAlt)
   isAlt = isAlt or util.IsAlt(p)

   if v == nil then
      v = true
   end

   if isAlt then
      _G.WOWMMGlobal[realm].Chars[p].HasMail = v
   end
end

function util.GetPlayerMailIndicator(p)
   local isAlt = util.IsAlt(p)

   if isAlt then
      return _G.WOWMMGlobal[realm].Chars[p].HasMail
   end

   return false
end

function util.GetCharacterFaction(Realm, Char)
   addon.debugPrint(Realm, Char)
   local faction = nil
   if _G.WOWMMGlobal[Realm].Factions then
      faction = _G.WOWMMGlobal[Realm].Factions[Char]
   end
   return faction
end

function util.SetLDBInteraction(interaction)
   LDBinteraction = interaction
end

function util.IsLDBInteraction()
   return LDBinteraction
end

function util.GetClassRGB(class)
   if not class then
      return
   end
   local color = ClassColors[class]
   
   if not color then
      return
   end
   
   return unpack(util.Color_HexToTable(color, false))
end

function util.GetClassRGBHex(class)
   if not class then
      return
   end

   local color = ClassColors[class]
   if not color then
      return
   end
   
   return color
end

function util.Color_HexToTable(hex, hasAlpha)
   if type(hex) ~= "number" or type(hasAlpha) ~= "boolean" then return end

   local colors = {}

   local numBytes = 3
   if hasAlpha then
      numBytes = 4
   end

   for i=1,numBytes do
      table.insert(colors, 1, bit.band(hex, 0xFF)/0xFF)
      hex = bit.rshift(hex, 8)
   end
   return colors
end

function util.GetSortedCharList(server)
   local chars = {}
   for n, v in pairs(_G.WOWMMGlobal) do
      if n == server and type(v) == "table" then
         for n, _ in pairs(v.Chars) do
            table.insert(chars, n)
         end
         table.sort(chars)
      end
   end
   return chars
end

function util.FormatGold(amount, delimiter)
   local formatted = amount
   while true do
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1'..delimiter..'%2')
      if k == 0 then
         break
      end
   end
   return formatted
end

function util.FormatMoney(cash, clean)
   if clean == nil then
      clean = false
   end

   cash = cash or 0
	local value = abs(cash)
	local gold = floor(value / 10000)
	local silver = floor(mod(value / 100, 100))
	local copper = floor(mod(value, 100))

   if clean then
      if gold == 0 and silver == 0 then
	      return format("%02d%s", copper, CopperIcon)
      elseif gold == 0 then
	      return format("%02d%s %02d%s", silver, SilverIcon, copper, CopperIcon)
      end
   end

   local goldFormat = profile.GetGoldFormatSetting()
   if goldFormat == "COMMA" then
      gold = util.FormatGold(gold, ',')
	   return format("%s%s %02d%s %02d%s", gold, GoldIcon, silver, SilverIcon, copper, CopperIcon)
   elseif goldFormat == "PERIOD" then
      gold = util.FormatGold(gold, '.')
	   return format("%s%s %02d%s %02d%s", gold, GoldIcon, silver, SilverIcon, copper, CopperIcon)
   else
	   return format("%d%s %02d%s %02d%s", gold, GoldIcon, silver, SilverIcon, copper, CopperIcon)
   end
end

function util.FormatCurrency(currency, icon)
   return format("|T%s:12:12|t %s", icon or "", currency or "")
end

function util.GetRealmTotalCash(Realm)
   local total = 0
   local setting = profile.GetFactionDisplaySetting()
   for name, value in pairs(_G.WOWMMGlobal[Realm].Chars) do
      addon.debugPrint("Faction info: ", name, util.GetCharacterFaction(Realm, name), faction)
      if (setting and util.GetCharacterFaction(Realm, name) == faction) or (not setting) then
         if type(value) == "table" then
   	      total = total + value.Cash

            if profile.GetBankCharacterSetting(Realm, name) then
               total = total + (value.GuildBankMoney or 0)
            end
         end
      end
   end
   return total
end

function util.GetTotalCash()
   local total = 0
   for name, value in pairs(_G.WOWMMGlobal) do
      if type(value) == "table" then
         local realmTotal = util.GetRealmTotalCash(name)
         total = total + realmTotal
      end
   end
   return total
end

function util.GetSourcesList(Realm)
   local Sources = {}
   local setting = profile.GetFactionDisplaySetting()
   if _G.WOWMSTracker[Realm] ~= nil then
      for char, v in pairs(_G.WOWMSTracker[Realm]) do
         if ((setting and util.GetCharacterFaction(Realm, char) == faction) or not setting) and tostring(char) ~= "AllChars" then
            for source, t in pairs(v) do
               if util.setContains(Sources, source) then
                  local prevT = util.getSetValue(Sources, source)
                  prevT.Earned = prevT.Earned + t.Earned
                  prevT.Spent = prevT.Spent + t.Spent
                  util.removeFromSet(Sources, source)
                  util.addToSet(Sources, source, prevT)
               else
                  local tbl = {
                                 Earned = t.Earned,
                                 Spent = t.Spent
                              }
                  util.addToSet(Sources, source, tbl)
               end
            end
         end
      end
   end
   return Sources
end

function util.GetZonesList(Realm)
   local Zones = {}
   local setting = profile.GetFactionDisplaySetting()
   for char, v in pairs(_G.WOWMSZone[Realm]) do
      if ((setting and util.GetCharacterFaction(Realm, char) == faction) or not setting) and tostring(char) ~= "AllChars" then
         for zone, t in pairs(v) do
            if util.setContains(Zones, zone) then
               local prevT = util.getSetValue(Zones, zone)
               prevT.Earned = prevT.Earned + t.Earned
               prevT.Spent = prevT.Spent + t.Spent
               util.removeFromSet(Zones, zone)
               util.addToSet(Zones, zone, prevT)
            else
               local tbl = {
                              Earned = t.Earned,
                              Spent = t.Spent
                           }
               util.addToSet(Zones, zone, tbl)
            end
         end
      end
   end
   return Zones
end

function util.GetRegion()
   if not Region then
      local region = GetCVar("portal")

      if region == "public-test" then
         region = "US"
      end

      if not region or #region ~= 2 then
         local cr = GetCurrentRegion()
         region = cr and ({ "US", "KR", "EU", "TW", "CN" })[cr]
      end

      if not region or #region ~= 2 then
         region = (GetCVar("realmList") or ""):match("^(%a+)%.")
      end

      if not region or #region ~= 2 then
         region = (GetRealmName() or ""):match("%((%a%a)%)")
      end
      region = region and region:upper()
      if region and #region == 2 then
         Region = region
      end
   end
   return Region
end

function util.RegisterEvents(self, handler, ...)
	for i = 1, select('#', ...) do
      local e = select(i, ...)
      if e then
         self:RegisterEvent(e)
      end
	end
   self:SetScript("OnEvent", handler)
end

local function ResetAvg(args)
   local key = args[1]

   if util.setContains(time.TimeSetTitles, key) then
      local net = key.."Net"
      local count = key.."Count"
      _G.WOWMMGlobal[realm][net] = 0
      _G.WOWMMGlobal[realm][count] = 0

      for i = 1, #util.FactionList do
         local f = util.FactionList[i]
         _G.WOWMMGlobal[realm][key][f].Net = 0
         _G.WOWMMGlobal[realm][key][f].Count = 0
      end
   end
end

local function ResetAllAvg(args)
   for _, v in pairs(time.GetTimeList()) do
      ResetAvg({v})
   end
end

local function RemoveCharacterTracker(args)
   local Realm = args[1]
   local CharName = args[2]
   local Tracker = args[3]

   if not _G.WOWMSTracker[Realm] or not _G.WOWMSTracker[Realm][CharName] then
      return
   end

   if Tracker == "ALL" then
      for k, _ in pairs(_G.WOWMSTracker[Realm][CharName]) do
         _G.WOWMSTracker[Realm].AllChars[k].Earned = _G.WOWMSTracker[Realm].AllChars[k].Earned - _G.WOWMSTracker[Realm][CharName][k].Earned
         _G.WOWMSTracker[Realm].AllChars[k].Spent = _G.WOWMSTracker[Realm].AllChars[k].Spent - _G.WOWMSTracker[Realm][CharName][k].Spent
      end
      _G.WOWMSTracker[Realm][CharName] = nil
   else
      _G.WOWMSTracker[Realm].AllChars[Tracker].Earned = _G.WOWMSTracker[Realm].AllChars[Tracker].Earned - _G.WOWMSTracker[Realm][CharName][Tracker].Earned
      _G.WOWMSTracker[Realm].AllChars[Tracker].Spent = _G.WOWMSTracker[Realm].AllChars[Tracker].Spent - _G.WOWMSTracker[Realm][CharName][Tracker].Spent
      _G.WOWMSTracker[Realm][CharName][Tracker] = nil
   end
   mt.InitPersistance()
   sd.UpdateStatDialog()
end

local function RemoveCharacterZone(args)
   local Realm = args[1]
   local CharName = args[2]
   local Zone = args[3]

   if not _G.WOWMSZone[Realm] or not _G.WOWMSZone[Realm][CharName] then
      return
   end

   if Zone == "ALL" then
      for k, _ in pairs(_G.WOWMSZone[Realm][CharName]) do
         _G.WOWMSZone[Realm].AllChars[k].Earned = _G.WOWMSZone[Realm].AllChars[k].Earned - _G.WOWMSZone[Realm][CharName][k].Earned
         _G.WOWMSZone[Realm].AllChars[k].Spent = _G.WOWMSZone[Realm].AllChars[k].Spent - _G.WOWMSZone[Realm][CharName][k].Spent
      end
      _G.WOWMSZone[Realm][CharName] = nil
   else
      _G.WOWMSZone[Realm].AllChars[Zone].Earned = _G.WOWMSZone[Realm].AllChars[Zone].Earned - _G.WOWMSZone[Realm][CharName][Zone].Earned
      _G.WOWMSZone[Realm].AllChars[Zone].Spent = _G.WOWMSZone[Realm].AllChars[Zone].Spent - _G.WOWMSZone[Realm][CharName][Zone].Spent
      _G.WOWMSZone[Realm][CharName][Zone] = nil
   end
   mt.InitPersistance()
   sd.UpdateStatDialog()
end

local function RemoveTracker(args)
   local Realm = args[1]
   local Tracker = args[2]

   if Tracker == "ALL" then
      _G.WOWMSTracker[Realm] = nil
   else
      for _, v in pairs(_G.WOWMSTracker[Realm]) do
         v[Tracker].Earned = 0
         v[Tracker].Spent = 0
      end
   end
   mt.InitPersistance()
   sd.UpdateStatDialog()
end

local function RemoveZone(args)
   local Realm = args[1]
   local Zone = args[2]

   if Zone == "ALL" then
      _G.WOWMSZone[Realm] = nil
   else
      for _, v in pairs(_G.WOWMSZone[Realm]) do
         v[Zone].Earned = 0
         v[Zone].Spent = 0
      end
   end
   mt.InitPersistance()
   sd.UpdateStatDialog()
end

local function ResetAll(args)
   for _, v in pairs(time.GetTimeList()) do
      time.ResetTime({v})
      ResetAvg({v})
   end
   RemoveTracker({realm, "ALL"})
   RemoveZone({realm, "ALL"})
end

local function RemoveCharacter(args)
   local Realm = args[1]
   local CharName = args[2]

   _G.WOWMMGlobal[Realm].Chars[CharName] = nil
   _G.WOWMMGlobal[Realm].Classes[CharName] = nil

   local count = 0
   for _ in pairs(_G.WOWMMGlobal[Realm].Chars) do count = count + 1 end
   if count == 0 then
      if Realm ~= realm then
         _G.WOWMMGlobal[Realm] = nil
      else
         core.InitializePersistantVariables(false)
      end
   end

   RemoveCharacterTracker({Realm, CharName, "ALL"})
   RemoveCharacterZone({Realm, CharName, "ALL"})
end

function util.setupCurrentPlayer(override) 
   if override == nil then
      override = false
   end

   local cash = GetMoney()
   addon.debugPrint("UtilMoney", cash)
   _G.WOWMMGlobal[realm].Chars[player] = _G.WOWMMGlobal[realm].Chars[player] or {}
   _G.WOWMMGlobal[realm].MoneyXfer[player] = _G.WOWMMGlobal[realm].MoneyXfer[player] or {}
   if _G.WOWMMGlobal[realm].Chars[player].Cash == nil or override then
      _G.WOWMMGlobal[realm].Chars[player].Cash = cash
   else
      _G.WOWMMGlobal[realm].Chars[player].Cash = _G.WOWMMGlobal[realm].Chars[player].Cash
   end
end

function util.stringSplit(str, sep)
   if sep == nil or str == nil then
      return {}
   end

   local t = {}

   for match in string.gmatch(str, "([^"..sep.."]+)") do
      tinsert(t, match)
   end
   return t
end

function util.DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[util.DeepCopy(orig_key)] = util.DeepCopy(orig_value)
        end
        setmetatable(copy, util.DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local ResetFunction
local args = {}
local DIALOG_WIDTH = 200
local DIALOG_HEIGHT = math.floor(DIALOG_WIDTH / 2)
local CheckDialog = Prototype_Dialog:new(
   {
      Title = "",
      BackgroundTexture = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      BorderTexture = "Interface\\Tooltips\\UI-Tooltip-Border",
      IsMovable = false,
      FrameStrata = "FULLSCREEN_DIALOG",
   })
CheckDialog:SetSize(DIALOG_WIDTH, DIALOG_HEIGHT)
local icon = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"
local CheckDialogWarningIcon = CheckDialog.frame:CreateFontString(addon_name.."WarningIconFontString", "OVERLAY")
CheckDialogWarningIcon:SetFont(fonts["Friz"], 10, nil)
CheckDialogWarningIcon:SetText(format("|T%s:35:35|t", icon))
CheckDialogWarningIcon:SetPoint("TOPLEFT", CheckDialog.frame, "TOPLEFT", 10, -10)
local CheckDialogWarning = CheckDialog.frame:CreateFontString(addon_name.."WarningFontString", "OVERLAY")
CheckDialogWarning:SetFont(fonts["Friz"], 10, nil)
CheckDialogWarning:SetWidth(DIALOG_WIDTH - 65)
CheckDialogWarning:SetJustifyH("LEFT")
CheckDialogWarning:SetText("Are you sure you want to do this?")
CheckDialogWarning:SetPoint("TOPLEFT", CheckDialogWarningIcon, "TOPRIGHT", 10, 0)
CheckDialogWarning:SetTextColor(util.GetClassRGB("HEADER"))

local WarningCancel = CheckDialog:AddButton(addon_name.."WarningCancelButton", "Cancel", 50, 20)
WarningCancel:SetPoint("BOTTOMRIGHT", CheckDialog.frame, "BOTTOMRIGHT", -5, 5)
WarningCancel:SetScript("OnClick", function(...) PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE) CheckDialog:Hide() end)
local WarningOK = CheckDialog:AddButton(addon_name.."WarningOKButton", "OK", 50, 20)
WarningOK:SetPoint("BOTTOMRIGHT", WarningCancel, "BOTTOMLEFT", -5, 0)
WarningOK:SetScript("OnClick", function(...) PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE) ResetFunction(args) CheckDialog:Hide() end)
CheckDialog:Hide()

function util.ResetAllAvg()
   ResetFunction = ResetAllAvg
   args = {}

   CheckDialogWarning:SetText("Are you sure you want to reset all averages?")
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

function util.ResetAvg(key)
   ResetFunction = ResetAvg
   args = {key}

   CheckDialogWarning:SetText(format("Are you sure you want to reset the %s average?", key))
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

function util.ResetAll()
   ResetFunction = ResetAll
   args = {}

   CheckDialogWarning:SetText("Are you sure you want to reset all earning, spending, averages, catagories, and zones for all characters on this realm?")
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

function util.RemoveCharacter(Realm, CharName)
   ResetFunction = RemoveCharacter
   args = {Realm, CharName}

   CheckDialogWarning:SetText(format("Are you sure you want to remove |cff%06x%s|r?", util.getSetValue(ClassColors, _G.WOWMMGlobal[Realm].Classes[CharName]), CharName))
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

function util.RemoveCharacterTracker(Realm, CharName, Tracker)
   ResetFunction = RemoveCharacterTracker
   args = {Realm, CharName, Tracker}

   CheckDialogWarning:SetText(format("Are you sure you want to remove the %s catagory from |cff%06x%s|r?", mt.DisplayNames[Tracker], util.getSetValue(ClassColors, _G.WOWMMGlobal[Realm].Classes[CharName]), CharName))
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

function util.RemoveCharacterZone(Realm, CharName, Zone)
   ResetFunction = RemoveCharacterZone
   args = {Realm, CharName, Zone}

   CheckDialogWarning:SetText(format("Are you sure you want to remove the %s zone from |cff%06x%s|r?", Zone, util.getSetValue(ClassColors, _G.WOWMMGlobal[Realm].Classes[CharName]), CharName))
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

function util.RemoveTracker(Realm, Tracker)
   ResetFunction = RemoveTracker
   args = {Realm, Tracker}

   if Tracker == "ALL" then
      CheckDialogWarning:SetText("Are you sure you want to remove all catagories from all characters on the realm?")
   else
      CheckDialogWarning:SetText(format("Are you sure you want to remove the %s catagory from all characters on the realm?", mt.DisplayNames[Tracker]))
   end
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

function util.RemoveZone(Realm, Zone)
   ResetFunction = RemoveZone
   args = {Realm, Zone}

   if Zone == "ALL" then
      CheckDialogWarning:SetText("Are you sure you want to remove all zones from all characters on the realm?")
   else
      CheckDialogWarning:SetText(format("Are you sure you want to remove the %s zone from all characters on the realm?", Zone))
   end
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

function util.ResetAllTime()
   ResetFunction = time.ResetAllTime
   args = {}

   CheckDialogWarning:SetText("Are you sure you want to reset earning and spending?")
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

function util.ResetTime(key)
   ResetFunction = time.ResetTime
   args = {key}

   CheckDialogWarning:SetText(format("Are you sure you want to reset the %s earning and spending?", key))
   PlaySound(SOUNDKIT.MONEY_FRAME_OPEN)
   CheckDialog:Show()
end

