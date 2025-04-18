local addon_name, addon = ...
local slash = addon.slash

local minimap = addon.minimap
local util = addon.utility
local profile = addon.profile
local sd = addon.statDisplay
local test = addon.test
local mt = addon.mt

local CommandList = {}
local CommandListDescription = {}
local CommandListRaw = {}
local CommandEnable = {}

local function ShowHelp()
   local c = _G.DEFAULT_CHAT_FRAME;
   c:AddMessage("|cffff6600".."WoW Money Statistics".."|r")

   local cmds = ""
   for _, v in pairs(CommandListRaw) do
      if CommandEnable[v]() then
         cmds = cmds .. v .. " | "
      end
   end

   c:AddMessage("|cffff6600".."Usage"..":|r  ".."/wms { "..string.lower(cmds).."help }")
   --for i=1, #CommandListRaw do
   for _, v in pairs(CommandListRaw) do
      if CommandEnable[v]() then
         local desc = CommandListDescription[v]
         desc = desc and ":|r "..desc or "|r"
         c:AddMessage("  - |cffffd1b3"..string.lower(v)..desc)
      end
   end
   c:AddMessage("  - |cffffd1b3".."help:|r Show Slash Command Usage")
end

local function ParseSlashCommand(msg)
   if #CommandListRaw == 0 then return end

   msg = (msg ~= "") and msg or "help"
   local cmd, args = string.match(msg, "([^%s]*)%s*(.*)")
   cmd = string.upper(cmd)

   if(CommandList[cmd] and CommandEnable[cmd]()) then
      CommandList[cmd](args)
   else
      ShowHelp()
   end
end

local function RegisterSlashCommand(cmd, func, desc, enable, hidden)
   if not hidden then
      hidden = false
   end

   if(type(cmd) == "string" and not CommandList[string.upper(cmd)] and type(func) == "function" and type(enable) == "function") then
      local cmd = string.upper(cmd)
      CommandList[cmd] = func
      CommandEnable[cmd] = enable
      CommandListDescription[cmd] = desc

      if not hidden then
         table.insert(CommandListRaw, cmd)
         table.sort(CommandListRaw)
      end
   end
end

SLASH_WOWMONEYSTATISTICS1 = '/wms'
SlashCmdList["WOWMONEYSTATISTICS"] = ParseSlashCommand

slash.RegisterSlashCommand = RegisterSlashCommand

RegisterSlashCommand("minimap",
                     function(...)
                        local isHidden = profile.GetMinimapHideSetting()
                        profile.SetMinimapHideSetting(minimap.SetMinimapHidden(not isHidden))
                     end, 
                     "Toggle Minimap Icon",
                     function(...)
                        return (not IsAddOnLoaded("SexyMap") or not profile.GetSexyCompatSetting()) and not IsAddOnLoaded("MBB")
                     end)

RegisterSlashCommand("sexymap",
                     function(...)
                        local isSexyCompat = profile.GetSexyCompatSetting()
                        profile.SetSexyCompatSetting(not isSexyCompat)
                        ReloadUI()
                     end, 
                     "Toggle SexyMap Integration",
                     function(...)
                        return IsAddOnLoaded("SexyMap")
                     end)

RegisterSlashCommand("show",
                     function(...)
                        sd.ToggleDialog()
                     end,
                     "Toggle WMS Window",
                     function(...)
                        return true
                     end)

RegisterSlashCommand("alt",
                     function(...)
                        local isAltIgnored = profile.GetAltSetting()
                        profile.SetAltSetting(not isAltIgnored)

                        local c = _G.DEFAULT_CHAT_FRAME;
                        if isAltIgnored then
                           c:AddMessage("|cffff6600".."! - WMS - Alt Transactions Shown - !".."|r")
                        else
                           c:AddMessage("|cffff6600".."! - WMS - Alt Transactions Ignored - !".."|r")
                        end
                     end,
                     "Toggle Alt Transactions",
                     function(...)
                        return true
                     end)

RegisterSlashCommand("verbose",
                     function(...)
                        local isVerbose = profile.GetVerboseSetting()
                        profile.SetVerboseSetting(not isVerbose)

                        local c = _G.DEFAULT_CHAT_FRAME;
                        if isVerbose then
                           c:AddMessage("|cffff6600".."! - WMS - Transaction Messages Hidden - !".."|r")
                        else
                           c:AddMessage("|cffff6600".."! - WMS - Transaction Messages Shown - !".."|r")
                        end
                     end,
                     "Toggle Transaction Messages",
                     function(...)
                        return true
                     end)

--[===[@test
RegisterSlashCommand("test",
                     function(...)
                        local args = {...}
                        test:RunTests(args[1])
                     end,
                     "Run Unit Testing",
                     function(...)
                        return true
                     end)
--@end-test]===]

RegisterSlashCommand("debug",
                     function(...)
                        local isDebugOn = profile.GetDebugSetting()
                        profile.SetDebugSetting(not isDebugOn)
                     end,
                     "",
                     function(...)
                        return true
                     end,
                     true)

RegisterSlashCommand("trackers",
                     function(...)
                        local isDebugOn = profile.GetDebugSetting()
                        profile.SetDebugSetting(true)
                        mt.debugActiveTrackers()
                        profile.SetDebugSetting(isDebugOn)
                     end,
                     "",
                     function(...)
                        return true
                     end,
                     true)

RegisterSlashCommand("addonTables",
                     function(...)
                        if IsAddOnLoaded("TableExplorer") then
                           texplore(addon_name, addon, 10)
                        end
                     end,
                     "",
                     function(...)
                        return true
                     end,
                     true)
