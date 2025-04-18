local addon_name, addon = ...
local sd = addon.statDisplay

local core = addon.core
local util = addon.utility
local profile = addon.profile
local global = addon.global
local fonts = addon.fonts
local time = addon.time
local token = addon.token
local mt = addon.mt
local _G = _G

local Graph = LibStub:GetLibrary("LibGraph-2.0")
local PieMinimumPercent = 0

local function OnPositionChange(x, y)
   profile.SetMainDialogPos(x, y)
end

local DIALOG_WIDTH = 600
local MIN_DIALOG_HEIGHT = 275
local MainDialog = Prototype_Dialog:new(
   {
      Title = "WoW Money Statistics",
      BackgroundTexture = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      --"Interface\\Tooltips\\UI-Tooltip-Background-Azerite",
      --"Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
      BorderTexture = "Interface\\Tooltips\\UI-Tooltip-Border",
      OnPositionChange = OnPositionChange,
   })
MainDialog:SetSize(DIALOG_WIDTH, MIN_DIALOG_HEIGHT)
MainDialog:Hide()

local ModeMenu
local StatDisplay
local CharFS
local PieChart
local LineGraph

local TimeDisplay = {}
local WoWTokenFS
local WoWTokenFSMoney
local Currencies = {}

--TODO: Add scroll functionality to the FSs
local MAX_FS = 50
local FontStrings = {}
local Highlight
local HighlightTexture = "Interface\\FriendsFrame\\UI-FriendsFrame-HighlightBar-Blue"

local player = UnitName("player")
local realm = GetRealmName()
local faction = UnitFactionGroup("player")

local RegisteredDisplays = {}
RegisteredDisplays.MenuInfo = {}
RegisteredDisplays.DisplayFunction = {}
RegisteredDisplays.Keys = {}
RegisteredDisplays.Order = {}

local RegisteredMenus = {}
RegisteredMenus.MenuInfo = {}
RegisteredMenus.Keys = {}
RegisteredMenus.Order = {}

-- Tab Defines
local TABS = {}
local tabCount = 0
local SUMMARY_TAB = 1
local PIE_CHART_TAB = 2
local LINE_GRAPH_TAB = 3

local function SetFont(font)
   MainDialog:SetFont(font)
end

local function SetFontSize(fontSize)
   MainDialog:SetFontSize(fontSize)
end

function sd.UpdateFontInfo() -- Disabled for now
   --SetFont(profile.GetFontSetting())
   --SetFontSize(profile.GetFontSizeSetting())
   --RegisteredDisplays.DisplayFunction[profile.GetMainDialogPieScreen(RegisteredDisplays.Order[1])]()
end

-- Customize the lines used for Pie Charts
local pieLineColor = 0x333333FF -- More of a darker grey then a black
local function Pie_DrawLine(self, angle)
   local sx, sy, ex, ey
   local Radian = math.pi * (90 - angle) / 180
   local w, h
   local color = util.Color_HexToTable(pieLineColor, true)

   w = self:GetWidth() / 2
   h = self:GetHeight() / 2

   sx = w
   sy = h

   ex = sx + 0.88 * w * math.cos(Radian)
   ey = sx + 0.88 * h * math.sin(Radian)
   self:DrawLine(self, sx, sy, ex, ey, 30, color, "OVERLAY")
end

local function StatDisplayTypeDropDown_OnLoad(self, level, menuList)
   if ModeMenu then
      local count = 0
      for k, v in pairs(RegisteredDisplays.Order) do
         local rd_text = RegisteredDisplays.MenuInfo[v].Text
         local rd_level = RegisteredDisplays.MenuInfo[v].Level
         local rd_parent = RegisteredDisplays.MenuInfo[v].Parent

         if level == 1 and rd_level == 1 then
            count = count + 1
            ModeMenu:AddOption(
               rd_text,
               rd_level,
               function(self)
                  profile.SetMainDialogPieScreen(v)
                  Highlight:Hide()
                  RegisteredDisplays.DisplayFunction[v](rd_text, rd_level, rd_parent)
                  ModeMenu:SetText(rd_text)
               end)
         elseif menuList == rd_parent then
            count = count + 1
            ModeMenu:AddOption(
               rd_text,
               rd_level,
               function(self)
                  profile.SetMainDialogPieScreen(v)
                  Highlight:Hide()
                  RegisteredDisplays.DisplayFunction[v](rd_text, rd_level, rd_parent)
                  ModeMenu:SetText(rd_text)
                  ModeMenu:CloseMenu()
               end)
         end
      end

      if count > 0 then
         local MenuForLevel = false
         for k, v in pairs(RegisteredMenus.Order) do
            MenuForLevel = (level == RegisteredMenus.MenuInfo[v].Level and RegisteredMenus.MenuInfo[v].Parent == menuList)
            if MenuForLevel then
               ModeMenu:AddDescriptor    (  "-------------------", level )
               break
            end
         end
      end

      for k, v in pairs(RegisteredMenus.Order) do
         local rm_text = RegisteredMenus.MenuInfo[v].Text
         local rm_level = RegisteredMenus.MenuInfo[v].Level
         local rm_list = RegisteredMenus.MenuInfo[v].List
         local rm_parent = RegisteredMenus.MenuInfo[v].Parent

         if level == 1 and rm_level == 1 then
            ModeMenu:AddMenu(rm_text, rm_level, rm_list)
         elseif menuList == rm_parent then
            ModeMenu:AddMenu(rm_text, rm_level, rm_list)
         end
      end
   end
end

local function HideFS()
   CharFS:SetText("")
   for i = 1, MAX_FS do
      FontStrings[i].Left:Hide()
      FontStrings[i].Middle:Hide()
      FontStrings[i].Right:Hide()
   end
end

local function SetSize(fsCount)
   local fsHeight = FontStrings[1].Left:GetHeight()
   local displayHeight = ((2 * 7) + (fsHeight * fsCount) + (5 * (fsCount - 1)))
   
   if (displayHeight + 60) < MIN_DIALOG_HEIGHT then
      displayHeight = MIN_DIALOG_HEIGHT - 60
   end

   StatDisplay:SetSize(StatDisplay:GetWidth(), displayHeight)
   MainDialog:SetSize(MainDialog.frame:GetWidth(), displayHeight + 60)
end

local function ShowFS(index, name, money, percent)
   if index == 1 then
      Highlight:SetHeight(FontStrings[1].Left:GetHeight())
   end

   FontStrings[index].Left:SetText(mt.DisplayNames[name] or name)
   FontStrings[index].Right:SetText(format("%3.2f%%", percent))
   FontStrings[index].Left:Show()
   FontStrings[index].Right:Show()
   
   if money then
      FontStrings[index].Middle:SetText(util.FormatMoney(money))
      if money < 0 then
         FontStrings[index].Middle:SetTextColor(1, 0, 0)
      else
         FontStrings[index].Middle:SetTextColor(1, 1, 1)
      end
      FontStrings[index].Middle:Show()
   end

   SetSize(index)
end

--local function LineGraphTab(show)
   --if show == nil then
      --error("Must provide a value for show")
   --end

   --if show then
      --LineGraph:Show()
   --else
      --LineGraph:Hide()
   --end
--end

local function GetAvg(key)
   local E, S, N, C = 0
   local setting = profile.GetFactionDisplaySetting()

   if setting then
      E = _G.WOWMMGlobal[realm][key][faction].Earned
      S = _G.WOWMMGlobal[realm][key][faction].Spent
      N = _G.WOWMMGlobal[realm][key][faction].Net
      C = _G.WOWMMGlobal[realm][key][faction].Count
   else
      E = _G.WOWMMGlobal[realm][key].Earned
      S = _G.WOWMMGlobal[realm][key].Spent
      N = _G.WOWMMGlobal[realm][key.."Net"]
      C = _G.WOWMMGlobal[realm][key.."Count"]
   end

   if C > 0 then
      local A = floor(N / C)
      return A
   else
      return (E - S)
   end
end

local function SummaryTabShow(show)
   if show == nil then
      error("Must provide a value for show")
   end

   if show then
      local setting = profile.GetFactionDisplaySetting()
      for _, v in pairs(time.TimeList) do
         TimeDisplay[v]:Show()

         local E, S = 0

         if setting then
            E = _G.WOWMMGlobal[realm][v][faction].Earned
            S = _G.WOWMMGlobal[realm][v][faction].Spent
         else
            E = _G.WOWMMGlobal[realm][v].Earned
            S = _G.WOWMMGlobal[realm][v].Spent
         end

         TimeDisplay[v].EarnedMoney:SetText(util.FormatMoney(E))
         TimeDisplay[v].SpentMoney:SetText(util.FormatMoney(S))
         if S ~= 0 then
            TimeDisplay[v].SpentMoney:SetTextColor(1, 0, 0)
         else
            TimeDisplay[v].SpentMoney:SetTextColor(1, 1, 1)
         end
         TimeDisplay[v].NetMoney:SetText(util.FormatMoney(E-S))
         if (E-S) < 0 then
            TimeDisplay[v].NetMoney:SetTextColor(1, 0, 0)
         else
            TimeDisplay[v].NetMoney:SetTextColor(1, 1, 1)
         end
         if util.getSetValue(time.TimeSetAvg, v) then
            local A = GetAvg(v)
            TimeDisplay[v].AvgMoney:SetText(util.FormatMoney(A))
            if A < 0 then
               TimeDisplay[v].AvgMoney:SetTextColor(1, 0, 0)
            else
               TimeDisplay[v].AvgMoney:SetTextColor(1, 1, 1)
            end
         end
      end
      WoWTokenFSMoney:SetText(util.FormatMoney(token.GetTokenPrice()))
      WoWTokenFS:Show()
      WoWTokenFSMoney:Show()

      local currencyCount = C_CurrencyInfo.GetCurrencyListSize()
      local shownCount = 1
      for i = 1, currencyCount do
         local ci = C_CurrencyInfo.GetCurrencyListInfo(i)
         if not ci.isHeader and not ci.isTypeUnused and ci.isShowInBackpack and (ci.name and ci.iconFileID) then
            if not Currencies[shownCount] or not Currencies[shownCount].Icon then break end
            Currencies[shownCount].Icon:SetText(util.FormatCurrency(ci.name..":", ci.iconFileID))
            Currencies[shownCount].Count:SetText(ci.quantity)
            Currencies[shownCount].Icon:Show()
            Currencies[shownCount].Count:Show()

            shownCount = shownCount + 1
         end
      end
   else
      for _, v in pairs(time.TimeList) do
         TimeDisplay[v]:Hide()
      end
      WoWTokenFS:Hide()
      WoWTokenFSMoney:Hide()

      for i = 1, #Currencies do
         Currencies[i].Icon:Hide()
         Currencies[i].Count:Hide()
      end
   end
end

local function PieChartTab(show)
   if show == nil then
      error("Must provide a value for show")
   end

   if show then
      RegisteredDisplays.DisplayFunction[profile.GetMainDialogPieScreen(RegisteredDisplays.Order[1])]()

      StatDisplay:Show()
      ModeMenu.menu:Show()
      CharFS:Show()
      PieChart:Show()
   else
      StatDisplay:Hide()
      ModeMenu.menu:Hide()
      CharFS:Hide()
      PieChart:Hide()
   end
end

local function ShowTab(id)
   if TABS[id] and TABS[id].Frame then
      PanelTemplates_SetTab(TABS[id].Frame, id)
      profile.SetMainDialogTab(id)
      for i = 1, #TABS do
         TABS[i].Show(i == id)
      end
      PlaySound(SOUNDKIT.UI_TOYBOX_TABS)
   end
end

local function ToggleDialog()
   MainDialog:Toggle()

   if MainDialog:IsShown() then
      PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN)
   else
      PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE)
   end

   local tab = profile.GetMainDialogTab()
   if tab > tabCount then
      tab = 1
   end
   ShowTab(tab)
end

local function RegisterTab(tabObj, tabIndex, parentFrame, showFunc)
   tabCount = tabCount + 1
   local idx = tabCount
   tinsert(TABS, tabIndex, { Show = showFunc, Frame = parentFrame })
   tabObj:SetScript("OnClick", function() ShowTab(idx) end)
end

local function CreateUI(self)
   if not self or not self.frame then return end

   MainDialog:SetFont("Friz")
   MainDialog:SetFontSize(10)

   local headerSpacing = 40
   local numCols = 3
   local frameWidth = 185
   local frameHeight = 85
   local colSpacing = math.min((DIALOG_WIDTH - (numCols * frameWidth)) / (numCols + 1))
   local rowSpacing = 10
   local colCount = 0
   local rowCount = 0
   local textYSpacing = 6
   for _, v in pairs(time.TimeList) do
      TimeDisplay[v] = CreateFrame("Frame", addon_name.."TimeDisplay"..v, self.frame, "BackdropTemplate")
      TimeDisplay[v]:SetFrameStrata("DIALOG")
      TimeDisplay[v]:SetBackdrop(
         {
            bgFile = nil,
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            tileSize = 32,
            insets = { left= 5, right = 5, top = 5, bottom = 5 }
         })
      TimeDisplay[v]:SetSize(frameWidth, frameHeight)
      TimeDisplay[v]:SetPoint("TOPLEFT", self.frame, "TOPLEFT", colSpacing + (colCount * (frameWidth + colSpacing)), -headerSpacing + (rowCount * (-frameHeight - rowSpacing)))
      cSkinFrame(TimeDisplay[v])

      TimeDisplay[v].Header = TimeDisplay[v]:CreateFontString(addon_name..v.."HeaderFontString", "OVERLAY")
      TimeDisplay[v].Header:SetFont(fonts["Friz"], 10, nil)
      TimeDisplay[v].Header:SetText(time.TimeSetTitles[v])
      TimeDisplay[v].Header:SetPoint("TOPLEFT", TimeDisplay[v], "TOPLEFT", 5, -5)
      TimeDisplay[v].Header:SetTextColor(util.GetClassRGB("HEADER"))

      TimeDisplay[v].Earned = TimeDisplay[v]:CreateFontString(addon_name..v.."EarnedFontString", "OVERLAY")
      TimeDisplay[v].Earned:SetFont(fonts["Friz"], 10, nil)
      TimeDisplay[v].Earned:SetText("Earned:")
      TimeDisplay[v].Earned:SetPoint("TOPLEFT", TimeDisplay[v].Header, "BOTTOMLEFT", 0, -textYSpacing)

      TimeDisplay[v].EarnedMoney = TimeDisplay[v]:CreateFontString(addon_name..v.."EarnedMoneyFontString", "OVERLAY")
      TimeDisplay[v].EarnedMoney:SetFont(fonts["Friz"], 10, nil)
      TimeDisplay[v].EarnedMoney:SetText(util.FormatMoney(99999999999))
      TimeDisplay[v].EarnedMoney:SetPoint("TOPRIGHT", TimeDisplay[v], "TOPRIGHT", -5, -5 - textYSpacing - TimeDisplay[v].Header:GetHeight())

      TimeDisplay[v].Spent = TimeDisplay[v]:CreateFontString(addon_name..v.."SpentFontString", "OVERLAY")
      TimeDisplay[v].Spent:SetFont(fonts["Friz"], 10, nil)
      TimeDisplay[v].Spent:SetText("Spent:")
      TimeDisplay[v].Spent:SetPoint("TOPLEFT", TimeDisplay[v].Earned, "BOTTOMLEFT", 0, -textYSpacing)

      TimeDisplay[v].SpentMoney = TimeDisplay[v]:CreateFontString(addon_name..v.."SpentMoneyFontString", "OVERLAY")
      TimeDisplay[v].SpentMoney:SetFont(fonts["Friz"], 10, nil)
      TimeDisplay[v].SpentMoney:SetText(util.FormatMoney(99999999999))
      TimeDisplay[v].SpentMoney:SetPoint("TOPRIGHT", TimeDisplay[v].EarnedMoney, "BOTTOMRIGHT", 0, -textYSpacing)

      TimeDisplay[v].Net = TimeDisplay[v]:CreateFontString(addon_name..v.."NetFontString", "OVERLAY")
      TimeDisplay[v].Net:SetFont(fonts["Friz"], 10, nil)
      TimeDisplay[v].Net:SetText("Net:")
      TimeDisplay[v].Net:SetPoint("TOPLEFT", TimeDisplay[v].Spent, "BOTTOMLEFT", 0, -textYSpacing)

      TimeDisplay[v].NetMoney = TimeDisplay[v]:CreateFontString(addon_name..v.."NetMoneyFontString", "OVERLAY")
      TimeDisplay[v].NetMoney:SetFont(fonts["Friz"], 10, nil)
      TimeDisplay[v].NetMoney:SetText(util.FormatMoney(99999999999))
      TimeDisplay[v].NetMoney:SetPoint("TOPRIGHT", TimeDisplay[v].SpentMoney, "BOTTOMRIGHT", 0, -textYSpacing)

      if util.getSetValue(time.TimeSetAvg, v) then
         TimeDisplay[v].Avg = TimeDisplay[v]:CreateFontString(addon_name..v.."NetFontString", "OVERLAY")
         TimeDisplay[v].Avg:SetFont(fonts["Friz"], 10, nil)
         TimeDisplay[v].Avg:SetText("Avg:")
         TimeDisplay[v].Avg:SetPoint("TOPLEFT", TimeDisplay[v].Net, "BOTTOMLEFT", 0, -textYSpacing)
         TimeDisplay[v].Avg:SetTextColor(util.GetClassRGB("EMPHASIS"))

         TimeDisplay[v].AvgMoney = TimeDisplay[v]:CreateFontString(addon_name..v.."AvgMoneyFontString", "OVERLAY")
         TimeDisplay[v].AvgMoney:SetFont(fonts["Friz"], 10, nil)
         TimeDisplay[v].AvgMoney:SetText(util.FormatMoney(99999999999))
         TimeDisplay[v].AvgMoney:SetPoint("TOPRIGHT", TimeDisplay[v].NetMoney, "BOTTOMRIGHT", 0, -textYSpacing)
      end

      colCount = colCount + 1
      if colCount == numCols then
         rowCount = rowCount + 1
         colCount = 0
      end
   end

   WoWTokenFS = self.frame:CreateFontString(addon_name.."WoWTokenFontString", "OVERLAY")
   WoWTokenFS:SetFont(fonts["Friz"], 10, nil)
   WoWTokenFS:SetText("WoW Token Price:")
   WoWTokenFS:SetPoint("TOPLEFT", self.frame, "TOPLEFT", colSpacing, -headerSpacing + (rowCount * (-frameHeight - rowSpacing)))
   WoWTokenFS:SetTextColor(util.GetClassRGB("HEADER"))

   WoWTokenFSMoney = self.frame:CreateFontString(addon_name.."WoWTokenMoneyFontString", "OVERLAY")
   WoWTokenFSMoney:SetFont(fonts["Friz"], 10, nil)
   WoWTokenFSMoney:SetText(util.FormatMoney(99999999999))
   WoWTokenFSMoney:SetPoint("TOPLEFT", WoWTokenFS, "TOPRIGHT", colSpacing, 0)

   local currencyCount = 3
   local shownCount = 1
   for i = 1, currencyCount do
      Currencies[shownCount] = {}
      Currencies[shownCount].Icon = self.frame:CreateFontString(addon_name.."CurrencyIconFontString"..shownCount, "OVERLAY")
      Currencies[shownCount].Icon:SetFont(fonts["Friz"], 10, nil)
      Currencies[shownCount].Icon:SetText("")
      if shownCount == 1 then
         Currencies[shownCount].Icon:SetPoint("TOPLEFT", WoWTokenFS, "BOTTOMLEFT", 0, -10)
      else
         Currencies[shownCount].Icon:SetPoint("TOPLEFT", Currencies[shownCount - 1].Count, "TOPRIGHT", 20, 0)
      end
      Currencies[shownCount].Icon:SetTextColor(util.GetClassRGB("HEADER"))

      Currencies[shownCount].Count = self.frame:CreateFontString(addon_name.."CurrencyCountFontString"..shownCount, "OVERLAY")
      Currencies[shownCount].Count:SetFont(fonts["Friz"], 10, nil)
      Currencies[shownCount].Count:SetText("")
      Currencies[shownCount].Count:SetPoint("TOPLEFT", Currencies[shownCount].Icon, "TOPRIGHT", 5, 0)

      shownCount = shownCount + 1
   end

   StatDisplay = CreateFrame("Frame", addon_name.."_StatDisplayStatFrame", self.frame, "BackdropTemplate")
   StatDisplay:SetBackdrop(
      {
         bgFile = nil,
         edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
         edgeSize = 16,
         tileSize = 32,
         insets = { left= 5, right = 5, top = 5, bottom = 5 }
      })
   StatDisplay:SetSize(350, 350)
   StatDisplay:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -headerSpacing)

   cSkinFrame(StatDisplay)

   for i = 1, MAX_FS do
      local lfs = StatDisplay:CreateFontString(addon_name.."LeftFontString"..i, "OVERLAY")
      lfs:SetFont(fonts["Friz"], 10, nil)
      lfs:SetText("Item"..i)
      local rfs = StatDisplay:CreateFontString(addon_name.."RightFontString"..i, "OVERLAY")
      rfs:SetFont(fonts["Friz"], 10, nil)
      rfs:SetText("Percent"..i)
      local mfs = StatDisplay:CreateFontString(addon_name.."MiddleFontString"..i, "OVERLAY")
      mfs:SetFont(fonts["Friz"], 10, nil)
      mfs:SetText(util.FormatMoney(99999999999))

      if i == 1 then
         lfs:SetPoint("TOPLEFT", StatDisplay, "TOPLEFT", 10, -7)
         rfs:SetPoint("TOPRIGHT", StatDisplay, "TOPRIGHT", -10, -7)
         mfs:SetPoint("TOPRIGHT", rfs, "TOPLEFT", -40, 0)
      else
         lfs:SetPoint("TOPLEFT", FontStrings[i - 1].Left, "BOTTOMLEFT", 0, -5)
         rfs:SetPoint("TOPRIGHT", FontStrings[i - 1].Right, "BOTTOMRIGHT", 0, -5)
         mfs:SetPoint("TOPRIGHT", FontStrings[i - 1].Middle, "BOTTOMRIGHT", 0, -5)
      end
      tinsert(FontStrings, { Left = lfs, Middle = mfs, Right = rfs })
   end

   SetSize(0)

   Highlight = StatDisplay:CreateTexture()
   Highlight:SetTexture(HighlightTexture)
   Highlight:SetHeight(FontStrings[1].Left:GetHeight())
   Highlight:SetWidth(StatDisplay:GetWidth() * .9)
   Highlight:SetPoint("TOPLEFT", FontStrings[1].Left, "TOPLEFT")
   Highlight:Hide()

   local closeButton = self:AddCloseButton(addon_name.."_StatDisplayCloseButton", "x", 25, 25)

   closeButton:SetScript("OnClick", function(...) ToggleDialog() end)

   ModeMenu = Prototype_Menu:NewDropDownMenu(
      addon_name.."StatDisplayTypeDropDown",
      self.frame,
      {
         OnLoad = StatDisplayTypeDropDown_OnLoad,
      })

local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded;
   if IsAddOnLoaded("ElvUI") then
      cSkinDropDownBox(ModeMenu.menu)
   end

   local screen = profile.GetMainDialogPieScreen(RegisteredDisplays.Order[1])

   if RegisteredDisplays.MenuInfo[screen] == nil then
      screen = RegisteredDisplays.Order[1]
   end

   ModeMenu:SetText(RegisteredDisplays.MenuInfo[screen].Text)
   ModeMenu:SetPoint("TOPRIGHT",self.frame, "TOPRIGHT", 0, -40)
   ModeMenu:SetWidth(200)

   CharFS = self.frame:CreateFontString(addon_name.."CharFontString", "OVERLAY")
   CharFS:SetFont(fonts["Friz"], 10, nil)
   CharFS:SetText("Character: ")
   CharFS:SetPoint("BOTTOMLEFT", ModeMenu.menu, "TOPLEFT", 20, 5)
   CharFS:SetTextColor(util.GetClassRGB("HEADER"))
   CharFS:Hide()

   PieChart = Graph:CreateGraphPieChart(addon_name.."_StatDisplayPieChart", ModeMenu.menu, "TOPRIGHT", "BOTTOMRIGHT", -20, 0, 200, 200)
   PieChart.DrawLinePie = Pie_DrawLine -- Replace DrawLine function with my modified one
   RegisteredDisplays.DisplayFunction[screen]()
   PieChart:SetSelectionFunc(function(self, k)
      if not k then
         Highlight:Hide()
      else
         if FontStrings[k].Left:IsVisible() then
            Highlight:SetPoint("TOPLEFT", FontStrings[k].Left, "TOPLEFT")
            Highlight:Show()
         end
      end
   end)

   --LineGraph = Graph:CreateGraphLine(addon_name.."_StatDisplayLineGraph", ModeMenu.menu, "TOPRIGHT", "BOTTOMRIGHT", -20, 0, 500, 200)
   --LineGraph:SetXAxis(-5, 30)
   --LineGraph:LockXMin(true)
   --LineGraph:LockXMax(true)
   --LineGraph:SetGridSpacing(1, 500000)
   --LineGraph:SetAutoScale(true)
   --LineGraph:SetYLabels(true, false)
	--local Data1 = {{1, 10000}, {2, 125}, {3, 400}, {4, 1200}, {5, 1000}}
	--local Data2 = {{1, 1000}, {2, 1205}, {3, 40}, {4, 10200}, {5, 5300000}}
   --local r, g, b = util.GetClassRGB("MAGE")
	--LineGraph:AddDataSeries(Data1,{1.0, 0.0, 0.0, 0.8})
	--LineGraph:AddDataSeries(Data2,{r, g, b, 0.8})

   local SummaryTab = self:AddButton("Prototype_Dialog__FrameTab"..SUMMARY_TAB, "Summary", 50, 30, "CharacterFrameTabTemplate")
   SummaryTab:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 10, 2)
   local pieChartTab = self:AddButton("Prototype_Dialog__FrameTab"..PIE_CHART_TAB, "Pie Chart", 50, 30, "CharacterFrameTabTemplate")
   pieChartTab:SetPoint("TOPLEFT", SummaryTab, "TOPRIGHT", -21, 0)
   --local lineGraphTab = self:AddButton("Prototype_Dialog__FrameTab"..LINE_GRAPH_TAB, "Line Graph", 50, 30, "CharacterFrameTabButtonTemplate")
   --lineGraphTab:SetPoint("TOPLEFT", pieChartTab, "TOPRIGHT", -21, 0)

   if IsAddOnLoaded("ElvUI") then
      cSkinTab(SummaryTab)
      cSkinTab(pieChartTab)
      cSkinTab(lineGraphTab)
   end

   RegisterTab(SummaryTab, SUMMARY_TAB, self.frame, SummaryTabShow)
   RegisterTab(pieChartTab, PIE_CHART_TAB, self.frame, PieChartTab)
   --RegisterTab(lineGraphTab, LINE_GRAPH_TAB, self.frame, LineGraphTab)

   local tab = profile.GetMainDialogTab()
   if tab > tabCount then
      tab = 1
   end
   addon.debugPrint("TAB: ", tab)
   PanelTemplates_SetNumTabs(self.frame, tabCount)
   PanelTemplates_SetTab(self.frame, tab)
end

local function RegisterMenu(k, menuText, menuLevel, parentMenu, menuList)
   if not k
      or not menuText
      or not menuLevel
      or not menuList then
      error("RegisterMenu failed - Not enough arguments")
   end

   -- Create Key
   if not util.setContains(RegisteredMenus.Keys, k) then
      util.addToSet(RegisteredMenus.Keys, k, k)
      tinsert(RegisteredMenus.Order, k)
   end

   -- MenuInfo
   if not RegisteredMenus.MenuInfo[k] then
      RegisteredMenus.MenuInfo[k] = 
      {
         Text = menuText,
         Level = menuLevel,
         List = menuList,
         Parent = parentMenu
      }
   end
end

local function RegisterDisplay(k, menuText, menuLevel, parentMenu, displayFunc)
   if not k
      or not menuText
      or not menuLevel
      or not displayFunc then
      error("RegisterDisplay failed - Not enough arguments")
   end

   -- Create Key
   if not util.setContains(RegisteredDisplays.Keys, k) then
      util.addToSet(RegisteredDisplays.Keys, k, k)
      tinsert(RegisteredDisplays.Order, k)
   end

   -- MenuInfo
   if not RegisteredDisplays.MenuInfo[k] then
      RegisteredDisplays.MenuInfo[k] = 
      {
         Text = menuText,
         Level = menuLevel,
         Parent = parentMenu
      }
   end

   -- DisplayFunction
   if not RegisteredDisplays.DisplayFunction[k] then
      RegisteredDisplays.DisplayFunction[k] = displayFunc
   end
end

local function SetParent(parent)
   if not parent then
      parent = profile.GetMainDialogDisplayParent()
   else
      profile.SetMainDialogDisplayParent(parent)
   end
   return parent
end

local function ValueCompare(a, b)
   return a[2] > b[2]
end

--TODO: 30 day moving average?
--TODO: Add chart for 30 days of WoW Token Price?
--TODO: Add chart for 30 days of earnings and spendings
--TODO: Character specific spent and earned charts
--TODO: Catagory by Character charts
--TODO: Pie Charts are inconsistant with what is and isn't shown.  Figure this out
local function Display_EGBS(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName = unpack(t)
   
   if not realmName then
      realmName = GetRealmName()
   end

   CharFS:SetText("Realm: "..realmName)
   CharFS:Show()

   local SourcesList = util.GetSourcesList(realmName)

   local total = 0
   local sorted = {}
   if SourcesList ~= nil then
      for k, v in pairs(SourcesList) do
         total = total + v.Earned
         table.insert(sorted, {k, v.Earned})
      end
      table.sort(sorted, ValueCompare)
   end

   if #sorted == 0 then
      local r, g, b = util.GetClassRGB("EMPHASIS")
      PieChart:CompletePie({ r, g, b })
   else
      local idx = 1
      for _, value in pairs(sorted) do
         local k = value[1]
         local v = value[2]
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         else
            percent = (v/total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         if percent > PieMinimumPercent then
            ShowFS(idx, k, v, percent)
            idx = idx + 1
         end
      end
   end
end

local function Display_CEGBS(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName, charName = unpack(t)

   CharFS:SetText("Character: "..charName.."-"..realmName)
   CharFS:Show()

   local total = 0
   local sorted = {}
   local tbl = _G.WOWMSTracker[realmName][charName]
   if tbl ~= nil then
      for k, v in pairs(tbl) do
         total = total + v.Earned
         table.insert(sorted, {k, v.Earned})
      end
      table.sort(sorted, ValueCompare)
   end

   if #sorted == 0 then
      local r, g, b = util.GetClassRGB("EMPHASIS")
      PieChart:CompletePie({ r, g, b })
   else
      local idx = 1
      for _, value in pairs(sorted) do
         local k = value[1]
         local v = value[2]
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         else
            percent = (v/total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         if percent > PieMinimumPercent then
            ShowFS(idx, k, v, percent)
            idx = idx + 1
         end
      end
   end
end

local function Display_SGBD(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName = unpack(t)
   
   if not realmName then
      realmName = GetRealmName()
   end

   CharFS:SetText("Realm: "..realmName)
   CharFS:Show()

   local SourcesList = util.GetSourcesList(realmName)

   local total = 0
   local sorted = {}
   if SourcesList ~= nil then
      for k, v in pairs(SourcesList) do
         total = total + v.Spent
         table.insert(sorted, {k, v.Spent})
      end
      table.sort(sorted, ValueCompare)
   end

   if #sorted == 0 then
      local r, g, b = util.GetClassRGB("EMPHASIS")
      PieChart:CompletePie({ r, g, b })
   else
      local idx = 1
      for _, value in pairs(sorted) do
         local k = value[1]
         local v = value[2]
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         else
            percent = (v/total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         if percent > PieMinimumPercent then
            ShowFS(idx, k, v, percent)
            idx = idx + 1
         end
      end
   end
end

local function Display_CSGBD(_, _, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName, charName = unpack(t)

   CharFS:SetText("Character: "..charName.."-"..realmName)
   CharFS:Show()

   local total = 0
   local sorted = {}
   local tbl = _G.WOWMSTracker[realmName][charName]
   if tbl ~= nil then
      for k, v in pairs(tbl) do
         total = total + v.Spent
         table.insert(sorted, {k, v.Spent})
      end
      table.sort(sorted, ValueCompare)
   end

   if #sorted == 0 then
      local r, g, b = util.GetClassRGB("EMPHASIS")
      PieChart:CompletePie({ r, g, b })
   else
      local idx = 1
      for _, value in pairs(sorted) do
         local k = value[1]
         local v = value[2]
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         else
            percent = (v/total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         if percent > PieMinimumPercent then
            ShowFS(idx, k, v, percent)
            idx = idx + 1
         end
      end
   end
end

local function Display_NGBS(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName = unpack(t)
   
   if not realmName then
      realmName = GetRealmName()
   end

   CharFS:SetText("Realm: "..realmName)
   CharFS:Show()

   local SourcesList = util.GetSourcesList(realmName)

   local total = 0
   local sorted = {}
   if SourcesList ~= nil then
      for k, v in pairs(SourcesList) do
         local net = v.Earned - v.Spent
         if net >= 0 then
            total = total + net
         end
         table.insert(sorted, {k, net})
      end
      table.sort(sorted, ValueCompare)
   end

   if #sorted == 0 then
      local r, g, b = util.GetClassRGB("EMPHASIS")
      PieChart:CompletePie({ r, g, b })
   else
      local idx = 1
      for _, value in pairs(sorted) do
         local k = value[1]
         local v = value[2]
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         elseif v < 0 then
            percent = 0
         else
            percent = (v/total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         if v ~= 0 then
            ShowFS(idx, k, v, percent)
            idx = idx + 1
         end
      end
   end
end

local function Display_CNGBS(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName, charName = unpack(t)

   CharFS:SetText("Character: "..charName.."-"..realmName)
   CharFS:Show()

   local total = 0
   local sorted = {}
   local tbl = _G.WOWMSTracker[realmName][charName]
   if tbl ~= nil then
      for k, v in pairs(tbl) do
         local net = v.Earned - v.Spent
         if net >= 0 then
            total = total + net
         end
         table.insert(sorted, {k, net})
      end
      table.sort(sorted, ValueCompare)
   end

   if #sorted == 0 then
      local r, g, b = util.GetClassRGB("EMPHASIS")
      PieChart:CompletePie({ r, g, b })
   else
      local idx = 1
      for _, value in pairs(sorted) do
         local k = value[1]
         local v = value[2]
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         elseif v < 0 then
            percent = 0
         else
            percent = (v/total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         if v ~= 0 then
            ShowFS(idx, k, v, percent)
            idx = idx + 1
         end
      end
   end
end

local function Display_GBC(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName = unpack(t)
   
   if not realmName then
      realmName = GetRealmName()
   end

   CharFS:SetText("Realm: "..realmName)
   CharFS:Show()

   local realmTotal = util.GetRealmTotalCash(realmName)

   local sorted = {}
   local tbl = _G.WOWMMGlobal
   if tbl ~= nil then
      for n, v in pairs(tbl) do
         if n == realmName and type(v) == "table" then
            for k, c in pairs(v.Chars) do
               local setting = profile.GetFactionDisplaySetting()

               if (setting and util.GetCharacterFaction(n, k) == faction) or not setting then
                  table.insert(sorted, {k, c.Cash})
               end
            end
         end
      end
      table.sort(sorted, ValueCompare)
   end

   if #sorted == 0 then
      local r, g, b = util.GetClassRGB("EMPHASIS")
      PieChart:CompletePie({ r, g, b })
   else
      local idx = 1
      for _, value in pairs(sorted) do
         local k = value[1]
         local v = value[2]
         local percent = 0
         local r, g, b = util.GetClassRGB(_G.WOWMMGlobal[realmName].Classes[k])
         if not realmTotal or realmTotal == 0 then
            PieChart:CompletePie({ r, g, b })
         else
            percent = (v / realmTotal) * 100
            if percent == 100 then
               PieChart:CompletePie({ r, g, b })
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent, { r, g, b })
            end
         end

         if percent > PieMinimumPercent then
            ShowFS(idx, k, v, percent)
            idx = idx + 1
         end
      end
   end
end

local function Display_GBR(...)
   PieChart:ResetPie()
   HideFS()

   local total = 0
   local sorted = {}
   local tbl = _G.WOWMMGlobal
   if tbl ~= nil then
      for k, v in pairs(tbl) do
         if type(v) == "table" then
            local realmTotal = util.GetRealmTotalCash(k)
            total = total + realmTotal
            table.insert(sorted, {k, realmTotal})
         end
      end
      table.sort(sorted, ValueCompare)
   end

   if #sorted == 0 then
      local r, g, b = util.GetClassRGB("EMPHASIS")
      PieChart:CompletePie({ r, g, b })
   else
      local idx = 1
      for _, value in pairs(sorted) do
         local k = value[1]
         local v = value[2]
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         else
            percent = (v / total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         if percent > PieMinimumPercent then
            ShowFS(idx, k, v, percent)
            idx = idx + 1
         end
      end
   end
end

local function Display_EGBZ(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName = unpack(t)
   
   if not realmName then
      realmName = GetRealmName()
   end

   CharFS:SetText("Realm: "..realmName)
   CharFS:Show()

   local ZonesList = util.GetZonesList(realmName)

   local total = 0
   local sortedZones = {}
   if ZonesList ~= nil then
      for k, v in pairs(ZonesList) do
         if v.Earned > 0 then
            total = total + v.Earned
            table.insert(sortedZones, {k, v.Earned})
         end
      end
      table.sort(sortedZones, ValueCompare)
   end

   if #sortedZones == 0 then
      PieChart:CompletePie()
   end

   local idx = 1
   local other = 0
   for _, value in pairs(sortedZones) do
      local k = value[1]
      local v = value[2]
      if idx <= 13 then
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         elseif v < 0 then
            percent = 0
         else
            percent = (v / total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         ShowFS(idx, k, v, percent)
         idx = idx + 1
      else
         if v > 0 then
            other = other + v
         end
      end
   end

   if other ~= 0 then
      local percent = (other / total) * 100
      PieChart:AddPie(percent)
      ShowFS(idx, "Other", other, percent)
   end
end

local function Display_CEGBZ(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName, charName = unpack(t)

   CharFS:SetText("Character: "..charName.."-"..realmName)
   CharFS:Show()

   local total = 0
   local sortedZones = {}
   local tbl = _G.WOWMSZone[realmName][charName]
   if tbl ~= nil then
      for k, v in pairs(tbl) do
         if v.Earned > 0 then
            total = total + v.Earned
            table.insert(sortedZones, {k, v.Earned})
         end
      end
      table.sort(sortedZones, ValueCompare)
   end

   if #sortedZones == 0 then
      PieChart:CompletePie()
   end

   local idx = 1
   local other = 0
   for _, value in pairs(sortedZones) do
      local k = value[1]
      local v = value[2]
      if idx <= 13 then
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         elseif v < 0 then
            percent = 0
         else
            percent = (v / total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         ShowFS(idx, k, v, percent)
         idx = idx + 1
      else
         if v > 0 then
            other = other + v
         end
      end
   end

   if other ~= 0 then
      local percent = (other / total) * 100
      PieChart:AddPie(percent)
      ShowFS(idx, "Other", other, percent)
   end
end

local function Display_SGBZ(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName = unpack(t)
   
   if not realmName then
      realmName = GetRealmName()
   end

   CharFS:SetText("Realm: "..realmName)
   CharFS:Show()

   local ZonesList = util.GetZonesList(realmName)

   local total = 0
   local sortedZones = {}
   if ZonesList ~= nil then
      for k, v in pairs(ZonesList) do
         if v.Spent > 0 then
            total = total + v.Spent
            table.insert(sortedZones, {k, v.Spent})
         end
      end
      table.sort(sortedZones, ValueCompare)
   end

   if #sortedZones == 0 then
      PieChart:CompletePie()
   end

   local idx = 1
   local other = 0
   for _, value in pairs(sortedZones) do
      local k = value[1]
      local v = value[2]
      if idx <= 13 then
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         elseif v < 0 then
            percent = 0
         else
            percent = (v / total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         ShowFS(idx, k, v, percent)
         idx = idx + 1
      else
         if v > 0 then
            other = other + v
         end
      end
   end

   if other ~= 0 then
      local percent = (other / total) * 100
      PieChart:AddPie(percent)
      ShowFS(idx, "Other", other, percent)
   end
end

local function Display_CSGBZ(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName, charName = unpack(t)

   CharFS:SetText("Character: "..charName.."-"..realmName)
   CharFS:Show()

   local total = 0
   local sortedZones = {}
   local tbl = _G.WOWMSZone[realmName][charName]
   if tbl ~= nil then
      for k, v in pairs(tbl) do
         if v.Spent > 0 then
            total = total + v.Spent
            table.insert(sortedZones, {k, v.Spent})
         end
      end
      table.sort(sortedZones, ValueCompare)
   end

   if #sortedZones == 0 then
      PieChart:CompletePie()
   end

   local idx = 1
   local other = 0
   for _, value in pairs(sortedZones) do
      local k = value[1]
      local v = value[2]
      if idx <= 13 then
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         elseif v < 0 then
            percent = 0
         else
            percent = (v / total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         ShowFS(idx, k, v, percent)
         idx = idx + 1
      else
         if v > 0 then
            other = other + v
         end
      end
   end

   if other ~= 0 then
      local percent = (other / total) * 100
      PieChart:AddPie(percent)
      ShowFS(idx, "Other", other, percent)
   end
end

local function Display_NGBZ(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName = unpack(t)
   
   if not realmName then
      realmName = GetRealmName()
   end

   CharFS:SetText("Realm: "..realmName)
   CharFS:Show()

   local ZonesList = util.GetZonesList(realmName)

   local total = 0
   local sortedZones = {}
   if ZonesList ~= nil then
      for k, v in pairs(ZonesList) do
         local net = v.Earned - v.Spent
         if net > 0 then
            total = total + net
         end
         table.insert(sortedZones, {k, net})
      end
      table.sort(sortedZones, ValueCompare)
   end

   if #sortedZones == 0 then
      PieChart:CompletePie()
   end

   local idx = 1
   local other = 0
   for _, value in pairs(sortedZones) do
      local k = value[1]
      local v = value[2]
      if idx <= 13 then
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         elseif v < 0 then
            percent = 0
         else
            percent = (v / total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         ShowFS(idx, k, v, percent)
         idx = idx + 1
      else
         if v > 0 then
            other = other + v
         end
      end
   end

   if other ~= 0 then
      local percent = (other / total) * 100
      PieChart:AddPie(percent)
      ShowFS(idx, "Other", other, percent)
   end
end

local function Display_CNGBZ(text, level, parent)
   PieChart:ResetPie()
   HideFS()

   parent = SetParent(parent)

   local t = util.stringSplit(parent, "_")
   local _, realmName, charName = unpack(t)

   CharFS:SetText("Character: "..charName.."-"..realmName)
   CharFS:Show()

   local total = 0
   local sortedZones = {}
   local tbl = _G.WOWMSZone[realmName][charName]
   if tbl ~= nil then
      for k, v in pairs(tbl) do
         local net = v.Earned - v.Spent
         if net > 0 then
            total = total + net
         end
         table.insert(sortedZones, {k, net})
      end
      table.sort(sortedZones, ValueCompare)
   end

   if #sortedZones == 0 then
      PieChart:CompletePie()
   end

   local idx = 1
   local other = 0
   for _, value in pairs(sortedZones) do
      local k = value[1]
      local v = value[2]
      if idx <= 13 then
         local percent = 0
         if total == 0 then
            PieChart:CompletePie()
         elseif v < 0 then
            percent = 0
         else
            percent = (v / total) * 100
            if percent == 100 then
               PieChart:CompletePie()
            elseif percent > PieMinimumPercent then
               PieChart:AddPie(percent)
            end
         end

         ShowFS(idx, k, v, percent)
         idx = idx + 1
      else
         if v > 0 then
            other = other + v
         end
      end
   end

   if other ~= 0 then
      local percent = (other / total) * 100
      PieChart:AddPie(percent)
      ShowFS(idx, "Other", other, percent)
   end
end

local function RegisterDisplays()
   RegisterMenu("CATAGORY", "Catagory", 1, nil, "CATAGORY".."_"..realm)
   RegisterDisplay("EGBS", "Earned Gold (Catagory)", 2, "CATAGORY".."_"..realm, Display_EGBS)
   RegisterDisplay("SGBD", "Spent Gold (Catagory)", 2, "CATAGORY".."_"..realm, Display_SGBD)
   RegisterDisplay("NGBS", "Net Gold (Catagory)", 2, "CATAGORY".."_"..realm, Display_NGBS)

   RegisterMenu("ZONE", "Zone", 1, nil, "ZONE".."_"..realm)
   RegisterDisplay("EGBZ", "Earned Gold (Zone)", 2, "ZONE".."_"..realm, Display_EGBZ)
   RegisterDisplay("SGBZ", "Spent Gold (Zone)", 2, "ZONE".."_"..realm, Display_SGBZ)
   RegisterDisplay("NGBZ", "Net Gold (Zone)", 2, "ZONE".."_"..realm, Display_NGBZ)

   RegisterMenu("CHARS", "Character", 1, nil, "CHARS".."_"..realm)
   RegisterDisplay("GBC", "Gold By Character", 2, "CHARS".."_"..realm, Display_GBC)
   local chars = util.GetSortedCharList(realm)
   for _, cn in pairs(chars) do
      local setting = profile.GetFactionDisplaySetting()

      if (setting and util.GetCharacterFaction(realm, cn) == faction) or not setting then
         RegisterMenu("CHARS".."_"..realm.."_"..cn, cn, 2, "CHARS".."_"..realm, "CHARS".."_"..realm.."_"..cn)

         RegisterMenu("CATAGORY".."_"..realm.."_"..cn, "Catagory", 3, "CHARS".."_"..realm.."_"..cn, "CATAGORY".."_"..realm.."_"..cn)
         RegisterDisplay("CEGBS".."_"..realm.."_"..cn, "Earned Gold (Catagory)", 4, "CATAGORY".."_"..realm.."_"..cn, Display_CEGBS)
         RegisterDisplay("CSGBD".."_"..realm.."_"..cn, "Spent Gold (Catagory)", 4, "CATAGORY".."_"..realm.."_"..cn, Display_CSGBD)
         RegisterDisplay("CNGBS".."_"..realm.."_"..cn, "Net Gold (Catagory)", 4, "CATAGORY".."_"..realm.."_"..cn, Display_CNGBS)

         RegisterMenu("ZONE".."_"..realm.."_"..cn, "Zone", 3, "CHARS".."_"..realm.."_"..cn, "ZONE".."_"..realm.."_"..cn)
         RegisterDisplay("CEGBZ".."_"..realm.."_"..cn, "Earned Gold (Zone)", 4, "ZONE".."_"..realm.."_"..cn, Display_CEGBZ)
         RegisterDisplay("CSGBZ".."_"..realm.."_"..cn, "Spent Gold (Zone)", 4, "ZONE".."_"..realm.."_"..cn, Display_CSGBZ)
         RegisterDisplay("CNGBZ".."_"..realm.."_"..cn, "Net Gold (Zone)", 4, "ZONE".."_"..realm.."_"..cn, Display_CNGBZ)
      end
   end
   RegisterMenu("REALMS", "Realm", 1, nil, "REALMS")
   
   local count = 0
   for n, v in pairs(_G.WOWMMGlobal) do
      if type(v) == "table" then
         count = count + 1
      end
   end

   if count > 1 then
      for n, v in pairs(_G.WOWMMGlobal) do
         if type(v) == "table" and n ~= realm then
            RegisterMenu("SERVER"..n, n, 2, "REALMS", "SERVER".."_"..n)
            local chars = util.GetSortedCharList(n)
            for _, cn in pairs(chars) do
               if _G.WOWMSTracker[n] ~= nil and _G.WOWMSTracker[n][cn] ~= nil and type(_G.WOWMSTracker[n][cn]) == "table" then
                  RegisterMenu("CATAGORY".."_"..n, "Catagory", 3, "SERVER".."_"..n, "CATAGORY".."_"..n)
                  RegisterDisplay("EGBS".."_"..n, "Earned Gold (Catagory)", 4, "CATAGORY".."_"..n, Display_EGBS)
                  RegisterDisplay("SGBD".."_"..n, "Spent Gold (Catagory)", 4, "CATAGORY".."_"..n, Display_SGBD)
                  RegisterDisplay("NGBS".."_"..n, "Net Gold (Catagory)", 4, "CATAGORY".."_"..n, Display_NGBS)

                  RegisterMenu("ZONE".."_"..n, "Zone", 3, "SERVER".."_"..n, "ZONE".."_"..n)
                  RegisterDisplay("EGBZ".."_"..n, "Earned Gold (Zone)", 4, "ZONE".."_"..n, Display_EGBZ)
                  RegisterDisplay("SGBZ".."_"..n, "Spent Gold (Zone)", 4, "ZONE".."_"..n, Display_SGBZ)
                  RegisterDisplay("NGBZ".."_"..n, "Net Gold (Zone)", 4, "ZONE".."_"..n, Display_NGBZ)

                  RegisterMenu("CHARS".."_"..n, "Character", 3, "SERVER".."_"..n, "CHARS".."_"..n)
                  RegisterDisplay("GBC".."_"..n, "Gold By Character", 4, "CHARS".."_"..n, Display_GBC)
                  local chars = util.GetSortedCharList(n)
                  for _, cn in pairs(chars) do
                     local setting = profile.GetFactionDisplaySetting()

                     if (setting and util.GetCharacterFaction(n, cn) == faction) or not setting then
                        RegisterMenu("CHARS".."_"..n.."_"..cn, cn, 4, "CHARS".."_"..n, "CHARS".."_"..n.."_"..cn)

                        RegisterMenu("CATAGORY".."_"..n.."_"..cn, "Catagory", 5, "CHARS".."_"..n.."_"..cn, "CATAGORY".."_"..n.."_"..cn)
                        RegisterDisplay("CEGBS".."_"..n.."_"..cn, "Earned Gold (Catagory)", 6, "CATAGORY".."_"..n.."_"..cn, Display_CEGBS)
                        RegisterDisplay("CSGBD".."_"..n.."_"..cn, "Spent Gold (Catagory)", 6, "CATAGORY".."_"..n.."_"..cn, Display_CSGBD)
                        RegisterDisplay("CNGBS".."_"..n.."_"..cn, "Net Gold (Catagory)", 6, "CATAGORY".."_"..n.."_"..cn, Display_CNGBS)

                        RegisterMenu("ZONE".."_"..n.."_"..cn, "Zone", 5, "CHARS".."_"..n.."_"..cn, "ZONE".."_"..n.."_"..cn)
                        RegisterDisplay("CEGBZ".."_"..n.."_"..cn, "Earned Gold (Zone)", 6, "ZONE".."_"..n.."_"..cn, Display_CEGBZ)
                        RegisterDisplay("CSGBZ".."_"..n.."_"..cn, "Spent Gold (Zone)", 6, "ZONE".."_"..n.."_"..cn, Display_CSGBZ)
                        RegisterDisplay("CNGBZ".."_"..n.."_"..cn, "Net Gold (Zone)", 6, "ZONE".."_"..n.."_"..cn, Display_CNGBZ)
                     end
                  end
               end
            end
            RegisterDisplay("GBR", "Gold By Realm", 2, "REALMS", Display_GBR)
         end
      end
   end
end

local frame = CreateFrame("Frame")
local loaded = false

local function EventHandler(self, event, ...)
   local args = {...}
   if event == "ADDON_LOADED" and args[1] ~= addon_name then
      return
   end

   addon.debugPrint("StatDialog Event", event, ...)
   if event == "ADDON_LOADED" and args[1] == addon_name then
      global.InitGlobals()
      mt.InitPersistance()
   end

   if (event == "ADDON_LOADED" or event == "MENU_RELOAD") and args[1] == addon_name then
      self:SetScript("OnUpdate", 
         function(self, elapsed)
            if core.VersionChangesApplied then
               RegisterDisplays()

               -- Rational: When a menu reload is occurring we do not want to recreate the UI
               --          If we did there will be errors
               if not loaded then
                  MainDialog:SetPosition(profile.GetMainDialogXPos(), profile.GetMainDialogYPos())
                  CreateUI(MainDialog)
                  sd.UpdateFontInfo()
               end
               self:SetScript("OnUpdate", nil)
               loaded = true
            end
         end
      )
   end

   if event == "ADDON_LOADED" and args[1] == addon_name then
   end
end

local function UpdateStatDialog()
   local tab = profile.GetMainDialogTab()
   if tab > tabCount then
      tab = 1
   end

   RegisteredMenus = {}
   RegisteredMenus.MenuInfo = {}
   RegisteredMenus.Keys = {}
   RegisteredMenus.Order = {}
   EventHandler(frame, "MENU_RELOAD", addon_name)

   ShowTab(tab)
end

util.RegisterEvents(frame, EventHandler, 'ADDON_LOADED')
sd.ToggleDialog = ToggleDialog
sd.UpdateStatDialog = UpdateStatDialog
