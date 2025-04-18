local _, addon = ...

local function InitGlobals()
   _G.WOWMMChar = _G.WOWMMChar or {}
   _G.WOWMMChar.StatDialog = _G.WOWMMChar.StatDialog or {}

   _G.WOWMSZoneLoot = _G.WOWMSZoneLoot or {}
   
   _G.WOWMMGlobal = _G.WOWMMGlobal or {}
   _G.WOWMSTracker = _G.WOWMSTracker or {}
   _G.WOWMSZone = _G.WOWMSZone or {}
   _G.WOWMSProfile = _G.WOWMSProfile or {}
   _G.WOWMSProfile.Saved = _G.WOWMSProfile.Saved or {}

   _G.WOWMSDebug = _G.WOWMSDebug or {}
end
InitGlobals()

-- Create file namespaces
addon.global = {}
addon.global.InitGlobals = InitGlobals

addon.token = {}
addon.minimap = {}
addon.slash = {}
addon.utility = {}
addon.profile = {}
addon.time = {}
addon.ldb = {}
addon.tooltip = {}
addon.menu = {}
addon.core = {}
addon.minimap = {}
addon.mt = {}
addon.statDisplay = {}
addon.fonts = {}

addon.debug = {}
addon.test = {}
