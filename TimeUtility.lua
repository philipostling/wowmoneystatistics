local _, addon = ...
local t = addon.time

local util = addon.utility
local profile = addon.profile
local _G = _G

local DaysToAdvance = 0

local RegionalResetTimes = { -- All Times should be in UTC
   ["US"] = { -- US, Latin, and Oceanic - Tuesday 15:00 UTC
      ["Day"] = 3,
      ["Hour"] = 15,
      ["Min"] = 0
   },
   ["KR"] = { -- KR - ??? Unsure about reset times for Korea - Setting to Tuesday 00:00 UTC
      ["Day"] = 3,
      ["Hour"] = 0,
      ["Min"] = 0
   },
   ["EU"] = { -- EU - Wednesday 7:00 UTC
      ["Day"] = 4,
      ["Hour"] = 7,
      ["Min"] = 0
   },
   ["TW"] = { -- TW - ??? Unsure about reset times for Taiwan - Setting to Tuesday 00:00 UTC
      ["Day"] = 3,
      ["Hour"] = 0,
      ["Min"] = 0
   },
   ["CN"] = { -- CN - ??? Unsure about reset times for China - Setting to Tuesday 00:00 UTC
      ["Day"] = 3,
      ["Hour"] = 0,
      ["Min"] = 0
   }
}

local realm = GetRealmName()

local SECOND = 1
local MINUTE = 60 * SECOND
local HOUR = 60 * MINUTE
local DAY = 24 * HOUR
local WEEK = 7 * DAY

t.TimeList = { "AllTime", "Year", "Month", "Week", "Day", "Session" }

t.TimeSetAvg = {}
t.TimeSetTitles = {}
for i = 1, #t.TimeList do
   local isNotAllTime = t.TimeList[i] ~= "AllTime"
   util.addToSet(t.TimeSetAvg, t.TimeList[i], isNotAllTime)
   if isNotAllTime then
      util.addToSet(t.TimeSetTitles, t.TimeList[i], t.TimeList[i])
   else
      util.addToSet(t.TimeSetTitles, t.TimeList[i], "All Time")
   end
end

local function GetDate()
   local d = C_DateAndTime.GetCurrentCalendarTime()
   return d.weekday, d.month, d.monthDay, d.year
end

local function GetCalendarMonthInfo(o)
   local monthInfo = C_Calendar.GetMonthInfo(o)
   return monthInfo.month, monthInfo.year, monthInfo.numDays, monthInfo.firstWeekday
end

local function GetCalendarMonthOffset()
   local _, currentMonth, _, currentYear = GetDate()
   local calMonth, calYear = GetCalendarMonthInfo(0)
   local offset = 0

   if calYear ~= currentYear then
      local fullYearCount = (currentYear - calYear) - 1
      local monthOff = currentMonth + (12 - calMonth)
      offset = (fullYearCount * 12) + monthOff
   elseif calMonth ~= currentMonth then
      offset = currentMonth - calMonth
   end

   return offset
end

local function DateToTime(date)
   if type(date) ~= "table" then error("date should be a table") return end

   local time = 
   {
      year = date.year,
      month = date.month,
      day = date.day,
      hour = date.hour,
      min = date.min,
      sec = date.sec 
   }
   return time
end

function t.GetTimeList()
   if profile.GetOptionalSettingShown("Invert", false) then
      return { "Session", "Day", "Week", "Month", "Year", "AllTime" }
   else
      return { "AllTime", "Year", "Month", "Week", "Day", "Session" }
   end
end

function t.ValidateDateAndTime()
   local dateInfo = date('*t')
   local calDateInfo = C_DateAndTime.GetCurrentCalendarTime()
   return (dateInfo.day == calDateInfo.monthDay) and (dateInfo.month == calDateInfo.month) and (dateInfo.year == calDateInfo.year)
end

function t.AdvanceDays(days)
   DaysToAdvance = DaysToAdvance + days
end

function t.GetDaysToAdvance()
   return DaysToAdvance
end

function t.ResetDays()
   DaysToAdvance = 0
end

function t.GetCalendarDate(daysToAdvance)
   local weekday, month, day, year = GetDate()

   local monthOffset = GetCalendarMonthOffset()
   local _, _, monthDays = GetCalendarMonthInfo(monthOffset)

   while (day + daysToAdvance) > monthDays do
      local daysToNextMonth = (monthDays - day) + 1
      daysToAdvance = daysToAdvance - daysToNextMonth
      monthOffset = monthOffset + 1
      month, year, monthDays, weekday = GetCalendarMonthInfo(monthOffset)
      day = 1
   end
   day = day + daysToAdvance
   weekday = (((weekday - 1) + (daysToAdvance%7))%7) + 1

   return weekday, month, day, year, monthDays
end

function t.GetTimeSinceEpoch(daysToAdvance)
   if daysToAdvance == nil then return nil end
   return (time() + (daysToAdvance * DAY))
end

function t.GetTimeOfLastReset(daysToAdvance)
   local region = RegionalResetTimes[util.GetRegion()]

   local curDate = date('*t')
   local _, month, day, year = t.GetCalendarDate(daysToAdvance)
   curDate.year = year
   curDate.month = month
   curDate.day = day
   
   local utc = date('!*t', time(DateToTime(curDate)))
   local locale = date('*t', time(DateToTime(curDate)))
   
   local utcTime = time(DateToTime(utc))
   local localeTime = time(DateToTime(locale))
   local timeDiff = difftime(utcTime, localeTime)

   local dsr = ((utc.wday + region.Day) % 7) + 1
   if utc.hour >= region.Hour and utc.min > region.Min then
      dsr = dsr % 7
   end

   utc.hour = region.Hour
   utc.min = region.Min
   utc.sec = 0
   local lastResetTime = time(DateToTime(utc)) - timeDiff - (dsr * DAY)

   return lastResetTime
end

function t.ResetAllTime(args)
   for _, v in pairs(t.TimeList) do
      t.ResetTime({v})
   end
end

function t.ResetTime(args)
   local key = args[1]

   if util.setContains(t.TimeSetTitles, key) then
      if _G.WOWMMGlobal[realm] and _G.WOWMMGlobal[realm][key] then
         _G.WOWMMGlobal[realm][key].Earned = 0
         _G.WOWMMGlobal[realm][key].Spent = 0

         for i = 1, #util.FactionList do
            local f = util.FactionList[i]
            _G.WOWMMGlobal[realm][key][f].Earned = 0
            _G.WOWMMGlobal[realm][key][f].Spent = 0
         end
      end
   end
end

function t.GetIDSet()
   local wd, m, d, y = t.GetCalendarDate(t.GetDaysToAdvance())
   local timeOfLastReset = t.GetTimeOfLastReset(t.GetDaysToAdvance())

   local IDSet = {}
   util.addToSet(IDSet, "AllTime", "none")
   util.addToSet(IDSet, "Year", y)
   util.addToSet(IDSet, "Month", m.."/"..y)
   util.addToSet(IDSet, "Week", timeOfLastReset)
   util.addToSet(IDSet, "Day", format("%02d/%02d/%d", m, d, strsub(y, 3)))
   util.addToSet(IDSet, "Session", "none")

   return IDSet
end

