local addon_name, addon = ...
local profile = addon.profile

local fonts = addon.fonts
local util = addon.utility
local minimap = addon.minimap

local SexyCompatDefault = true
local AltIgnoredDefault = true
local VerboseDefault    = false
local DebugOnDefault    = false
local TooltipCharacterSettingDefault = "ALL"
local TooltipServerSettingDefault = "ALL"
local GoldFormatSettingDefault = "NONE"
local MoneyXferSettingDefault = "ASTERISK"
local FactionDisplaySettingDefault = false
local MinimapLockDefault = true -- For locking to the minimap
local MinimapHideDefault = false
local MinimapButtonLockDefault = false -- For locking the button itself
local defaultMinimapX, defaultMinimapY = 100, 100
local defaultStatDialogX, defaultStatDialogY = 500, 500
local defaultStatDialogTab = 1

local DefaultFont = "Friz"
local DefaultFontSize = 12

local realm = GetRealmName()
local _, class = UnitClass("player")
local player = UnitName("player")
local faction = UnitFactionGroup("player")

-- This function shall be used to transfer from the old character specific settings to the new global settings
function profile.TransferFuncToProfile(setting)
   if _G.WOWMMChar[setting] ~= nil then
      _G.WOWMSProfile[realm][player][setting] = _G.WOWMMChar[setting]
      _G.WOWMMChar[setting] = nil
      return
   end

   if _G.WOWMMChar.Minimap ~= nil and _G.WOWMMChar.Minimap[setting] ~= nil then
      _G.WOWMSProfile[realm][player].Minimap[setting] = _G.WOWMMChar.Minimap[setting]
      _G.WOWMMChar.Minimap[setting] = nil
      return
   end
end

local function GetProfileStructure()
   local profileStruct = _G.WOWMSProfile[realm][player]
   local savedProfileName = _G.WOWMSProfile[realm][player].SavedProfile
   if savedProfileName ~= nil then
      if _G.WOWMSProfile.Saved[savedProfileName] ~= nil then
         profileStruct = _G.WOWMSProfile.Saved[savedProfileName]
      else
         profileStruct.SavedProfile = nil
      end
   end
   return profileStruct
end

function profile.GetProfileName()
   return _G.WOWMSProfile[realm][player].SavedProfile
end

function profile.SetProfileName(name)
   _G.WOWMSProfile[realm][player].SavedProfile = name
   ReloadUI()
end

function profile.DeleteProfile(name)
   _G.WOWMSProfile.Saved[name] = nil
   if _G.WOWMSProfile[realm][player].SavedProfile == name then
      _G.WOWMSProfile[realm][player].SavedProfile = nil
      ReloadUI()
   end
end

function profile.DissociateProfile()
   _G.WOWMSProfile[realm][player].SavedProfile = nil
   ReloadUI()
end

function profile.GetFontSetting()
   local font = GetProfileStructure().Font
   if font == nil then
      font = DefaultFont
   elseif fonts[font] == nil then
      font = DefaultFont
   end
   return font
end

function profile.SetFontSetting(font)
   if profile.GetFontSetting() ~= font then
      GetProfileStructure().Font = font
   end
end

function profile.GetFontSizeSetting()
   local fontSize = GetProfileStructure().FontSize
   if fontSize == nil then
      fontSize = DefaultFontSize
   end
   return fontSize
end

function profile.SetFontSizeSetting(fontSize)
   if profile.GetFontSizeSetting() ~= fontSize then
      GetProfileStructure().FontSize = fontSize
   end
end

function profile.GetElvUIFontSetting()
   local elvUIFontSetting = GetProfileStructure().ElvUIFontSetting
   if elvUIFontSetting == nil then
      elvUIFontSetting = false
   end
   return elvUIFontSetting
end

function profile.SetElvUIFontSetting(elvUIFontSetting)
   if profile.GetElvUIFontSetting() ~= elvUIFontSetting then
      GetProfileStructure().ElvUIFontSetting = elvUIFontSetting
   end
end

function profile.GetSexyCompatSetting()
   local isSexyCompat = GetProfileStructure().Minimap.IsSexyCompat
   if isSexyCompat == nil then
      isSexyCompat = SexyCompatDefault
   end
   return isSexyCompat
end

function profile.SetSexyCompatSetting(isSexyCompat)
   if profile.GetSexyCompatSetting() ~= isSexyCompat then
      GetProfileStructure().Minimap.IsSexyCompat = isSexyCompat
   end
end

function profile.GetTooltipCharacterSetting()
   local charSetting = GetProfileStructure().TooltipCharacterSetting
   if charSetting == nil then
      charSetting = TooltipCharacterSettingDefault
   end
   return charSetting
end

function profile.SetTooltipCharacterSetting(charSetting)
   if profile.GetTooltipCharacterSetting() ~= charSetting then
      GetProfileStructure().TooltipCharacterSetting = charSetting
   end
end

function profile.GetTooltipServerSetting()
   local serverSetting = GetProfileStructure().TooltipServerSetting
   if serverSetting == nil then
      serverSetting = TooltipServerSettingDefault
   end
   return serverSetting
end

function profile.SetTooltipServerSetting(serverSetting)
   if profile.GetTooltipServerSetting() ~= serverSetting then
      GetProfileStructure().TooltipServerSetting = serverSetting
   end
end

function profile.GetMoneyXferSetting()
   local moneyXferSetting = GetProfileStructure().MoneyXferSetting
   if moneyXferSetting == nil then
      moneyXferSetting = MoneyXferSettingDefault
   end
   return moneyXferSetting
end

function profile.SetMoneyXferSetting(moneyXferSetting)
   if profile.GetMoneyXferSetting() ~= moneyXferSetting then
      GetProfileStructure().MoneyXferSetting = moneyXferSetting
   end
end

function profile.GetFactionDisplaySetting()
   local factionDisplaySetting = GetProfileStructure().FactionDisplaySetting
   if factionDisplaySetting == nil then
      factionDisplaySetting = FactionDisplaySettingDefault
   end
   return factionDisplaySetting
end

function profile.SetFactionDisplaySetting(factionDisplaySetting)
   if profile.GetFactionDisplaySetting() ~= factionDisplaySetting then
      GetProfileStructure().FactionDisplaySetting = factionDisplaySetting
   end
end

function profile.GetGoldFormatSetting()
   local goldFormatSetting = GetProfileStructure().GoldFormatSetting
   if goldFormatSetting == nil then
      goldFormatSetting = GoldFormatSettingDefault
   end
   return goldFormatSetting
end

function profile.SetGoldFormatSetting(goldFormatSetting)
   if profile.GetGoldFormatSetting() ~= goldFormatSetting then
      GetProfileStructure().GoldFormatSetting = goldFormatSetting
   end
end

function profile.GetVerboseSetting()
   local isVerbose = GetProfileStructure().IsVerbose
   if isVerbose == nil then
      isVerbose = VerboseDefault
   end
   return isVerbose
end

function profile.SetVerboseSetting(isVerbose)
   if profile.GetVerboseSetting() ~= isVerbose then
      GetProfileStructure().IsVerbose = isVerbose
   end
end

function profile.GetOptionalSettingShown(key, default)
   local shown = GetProfileStructure()[key.."Shown"]
   if shown == nil and default ~= nil then
      shown = default
   end
   return shown
end

function profile.SetOptionalSetting(key, value)
   local shown = key.."Shown"
   if profile.GetOptionalSettingShown(key) ~= value then
      GetProfileStructure()[shown] = value
   end
end

function profile.GetMinimapHideSetting()
   local isMinimapHidden = GetProfileStructure().Minimap.IsMinimapHidden
   if isMinimapHidden == nil then
      isMinimapHidden = MinimapHideDefault
   end
   return isMinimapHidden
end

function profile.SetMinimapHideSetting(isMinimapHidden)
   if profile.GetMinimapHideSetting() ~= isMinimapHidden then
      GetProfileStructure().Minimap.IsMinimapHidden = isMinimapHidden
   end
end

function profile.GetMinimapLockSetting()
   local isMinimapLocked = GetProfileStructure().Minimap.IsMinimapLocked
   if isMinimapLocked == nil then
      isMinimapLocked = MinimapLockDefault
   end
   return isMinimapLocked
end

function profile.SetMinimapLockSetting(isMinimapLocked)
   if profile.GetMinimapLockSetting() ~= isMinimapLocked then
      GetProfileStructure().Minimap.IsMinimapLocked = isMinimapLocked
   end
end

function profile.GetLockSetting()
   local isLocked = GetProfileStructure().Minimap.IsLocked
   if isLocked == nil then
      isLocked = LockDefault
   end
   return isLocked
end

function profile.SetLockSetting(isLocked)
   if profile.GetLockSetting() ~= isLocked then
      GetProfileStructure().Minimap.IsLocked = isLocked
   end
end

function profile.GetMinimapButtonXPos()
   local xPos = GetProfileStructure().Minimap.x
   if xPos == nil then
      xPos = defaultMinimapX
   end
   return xPos
end

function profile.GetMinimapButtonYPos()
   local yPos = GetProfileStructure().Minimap.y
   if yPos == nil then
      yPos = defaultMinimapY
   end
   return yPos
end

function profile.SetMinimapButtonPos(x, y)
   if profile.GetMinimapButtonXPos() ~= x then
      GetProfileStructure().Minimap.x = x
   end

   if profile.GetMinimapButtonYPos() ~= y then
      GetProfileStructure().Minimap.y = y
   end
end

-- Non-profile functions
-- Rational: The functions below store items that may not be available on all toons
--             therefore, they cannot be part of a created profile.

function profile.GetMainDialogXPos()
   local xPos = _G.WOWMMChar.StatDialog.x
   if xPos == nil then
      xPos = defaultStatDialogX
   end
   return xPos
end

function profile.GetMainDialogYPos()
   local yPos = _G.WOWMMChar.StatDialog.y
   if yPos == nil then
      yPos = defaultStatDialogY
   end
   return yPos
end

function profile.SetMainDialogPos(x, y)
   if profile.GetMainDialogXPos() ~= x then
      _G.WOWMMChar.StatDialog.x = x
   end

   if profile.GetMainDialogYPos() ~= y then
      _G.WOWMMChar.StatDialog.y = y
   end
end

function profile.GetMainDialogTab()
   local tab = _G.WOWMMChar.StatDialog.CurrentTab
   if tab == nil then
      tab = defaultStatDialogTab
   end
   return tab
end

function profile.SetMainDialogTab(tab)
   if profile.GetMainDialogTab() ~= tab then
      _G.WOWMMChar.StatDialog.CurrentTab = tab
   end
end

function profile.GetMainDialogPieScreen(default)
   local pieScreen = _G.WOWMMChar.StatDialog.PieScreen
   if pieScreen == nil and default ~= nil then
      pieScreen = default
   end
   return pieScreen
end

function profile.SetMainDialogPieScreen(pieScreen)
   if profile.GetMainDialogPieScreen() ~= pieScreen then
      _G.WOWMMChar.StatDialog.PieScreen = pieScreen
   end
end

function profile.GetMainDialogDisplayParent()
   return _G.WOWMMChar.StatDialog.DisplayParent
end

function profile.SetMainDialogDisplayParent(parent)
   _G.WOWMMChar.StatDialog.DisplayParent = parent
end

-- Global settings

function profile.GetDebugSetting()
   local debugOn = _G.WOWMMGlobal.IsDebugOn
   if debugOn == nil then
      debugOn = DebugOnDefault
   end
   return debugOn
end

function profile.SetDebugSetting(debugOn)
   if profile.GetDebugSetting() ~= debugOn then
      _G.WOWMMGlobal.IsDebugOn = debugOn
   end
end

function profile.GetAltSetting()
   local isAltIgnored = _G.WOWMMGlobal.IsAltIgnored
   if isAltIgnored == nil then
      isAltIgnored = AltIgnoredDefault
   end
   return isAltIgnored
end

function profile.SetAltSetting(isAltIgnored)
   if profile.GetAltSetting() ~= isAltIgnored then
      _G.WOWMMGlobal.IsAltIgnored = isAltIgnored
   end
end

function profile.GetBankCharacterSetting(Realm, Character)
   if Realm == nil then
      Realm = realm
   end

   if Character == nil then
      Character = player
   end

   local bankChar = _G.WOWMMGlobal[Realm].Chars[Character].BankCharacter or false
   if bankChar == nil then
      bankChar = false;
   end
   return bankChar
end

function profile.SetBankCharacterSetting(bankChar)
   if profile.GetBankCharacterSetting() ~= bankChar then
      _G.WOWMMGlobal[realm].Chars[player].BankCharacter = bankChar
   end
end

-------------------------------------------------------------------------------------
local args = {}
local DIALOG_WIDTH = 200
local DIALOG_HEIGHT = math.floor(DIALOG_WIDTH / 2.5)
local NewProfileDialog = Prototype_Dialog:new(
   {
      Title = "",
      BackgroundTexture = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      BorderTexture = "Interface\\Tooltips\\UI-Tooltip-Border",
      IsMovable = false,
      FrameStrata = "FULLSCREEN_DIALOG",
   })
NewProfileDialog:SetSize(DIALOG_WIDTH, DIALOG_HEIGHT)

local function CreateNewFunc(self)
   if self:GetNumLetters() > 0 then
      local name = self:GetText()
      _G.WOWMSProfile.Saved[name] = util.DeepCopy(GetProfileStructure())
      _G.WOWMSProfile[realm][player].SavedProfile = name
      NewProfileDialog:Hide()
   end
end

local icon = "Interface\\BUTTONS\\UI-GuildButton-PublicNote-Up"
local NewProfileIcon = NewProfileDialog:AddFontString(addon_name.."NewProfileIcon", format("|T%s:35:35|t", icon), "OVERLAY")
NewProfileIcon:SetPoint("TOPLEFT", NewProfileDialog.frame, "TOPLEFT", 10, -10)

local NewProfileLabel = NewProfileDialog:AddFontString(addon_name.."NewProfileFontString", "Profile Name:", "OVERLAY", DIALOG_WIDTH - 65)
NewProfileLabel:SetJustifyH("LEFT")
NewProfileLabel:SetPoint("TOPLEFT", NewProfileIcon, "TOPRIGHT", 10, 0)
NewProfileLabel:SetTextColor(util.GetClassRGB("HEADER"))

local NewProfileDialogEditBox = NewProfileDialog:AddEditBox(addon_name.."NewProfileEditBox",DIALOG_WIDTH - 65, 20, 18)
NewProfileDialogEditBox:SetPoint("TOPLEFT", NewProfileLabel, "BOTTOMLEFT", 0, -5)

local NewProfileCancel = NewProfileDialog:AddButton(addon_name.."NewProfileCancelButton", "Cancel", 50, 20)
NewProfileCancel:SetPoint("BOTTOMRIGHT", NewProfileDialog.frame, "BOTTOMRIGHT", -5, 5)
NewProfileCancel:SetScript("OnClick", function(...) PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE) NewProfileDialog:Hide() end)

local NewProfileOK = NewProfileDialog:AddButton(addon_name.."NewProfileOKButton", "OK", 50, 20)
NewProfileOK:SetPoint("BOTTOMRIGHT", NewProfileCancel, "BOTTOMLEFT", -5, 0)
NewProfileOK:SetScript("OnClick", function(...) PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE) CreateNewFunc(args) NewProfileDialog:Hide() end)
NewProfileOK:Disable()
NewProfileDialog:Hide()

local function OnTextChanged(self)
   if self:GetNumLetters() > 0 then
      NewProfileOK:Enable()
   else
      NewProfileOK:Disable()
   end
end

NewProfileDialogEditBox:SetScript("OnEnterPressed", CreateNewFunc)
NewProfileDialogEditBox:SetScript("OnTextChanged", OnTextChanged)

function profile.CreateNew()
   args = NewProfileDialogEditBox
   NewProfileDialog:Show()
   NewProfileDialogEditBox:SetFocus()
end
