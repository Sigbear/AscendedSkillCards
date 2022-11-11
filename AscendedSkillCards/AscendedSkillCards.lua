local ASC = LibStub("AceAddon-3.0"):NewAddon("AscendedSkillCards", "AceEvent-3.0", "AceConsole-3.0")

-- forward declaration
local ScanForUnknownSkillCards
local ColorChatString
local HideAllButtonFrames
local AddOrReuseButtonFrames
local ResizeWindowAndShowButtonFrames
local UpdateSkillCardsInInventoryText

local stringHexColors =
{
  White = "ffffff",
  Gold = "e6cc80"
}

-- GUI
topSkillCardFrame = CreateFrame("Frame", "AscendedSkillCardsContainerFrame", UIParent, "GameTooltipTemplate")
topSkillCardFrame:SetFrameStrata("DIALOG")
topSkillCardFrame:SetMovable(true)
-- topSkillCardFrame:SetUserPlaced(true)

local closeSkillCardFrameButton = CreateFrame("Button", "skillCardFrameCloseButton", topSkillCardFrame,
  "UIPanelCloseButton")
local skillCardFrameOptionsButton = CreateFrame("Button", "skillCardFrameOptionsButton", topSkillCardFrame)

local unknownSkillCardsInInvTitleText = nil
local menuTexts = {
  UnknownCardsInInv = "Unknown skill cards",
  NoUnknownCardsInInv = "No unknown cards found",
  NormalCardCounterTextPrefix = "Normal cards: ",
  LuckySkillCardsCounterPrefix = "Lucky cards: "
}

-- Gossip frame interaction buttons Tooltip
local exchangeCardsButtonTooltip = CreateFrame("GameTooltip", "GossipFrameInteractionTooltip", UIParent,
  "GameTooltipTemplate")
local exchangeCardsTooltipData =
{
  {
    header = "Exchange 5 normal skill cards",
    text = "Exchange 5 random normal skill cards for sealed decks.",
    info = "\nFor this to work you have to have the exchange skill card window open"
  },
  {
    header = "Exchange 5 lucky skill cards",
    text = "Exchange 5 random lucky skill cards for sealed decks.",
    info = "\nFor this to work you have to have the exchange skill card window open"
  },
  {
    header = "Exchange 5 golden skill cards",
    text = "Exchange 5 random golden skill cards for golden sealed decks.",
    info = "\nFor this to work you have to have the exchange skill card window open"
  },
  {
    header = "Exchange 5 golden lucky skill cards",
    text = "Exchange 5 random golden lucky skill cards for sealed decks.",
    info = "\nFor this to work you have to have the exchange skill card window open"
  }
}

-- EasyMenu
local skillCardFrameOptionsMenu = CreateFrame("Frame", "skillCardOptionsMenu", skillCardFrameOptionsButton,
  "UIDropDownMenuTemplate")

local firstTimeLoadingMenu = true
local defaultSkillCardFrameHeight = 200
local skillCardButtonsPerRow = 6

-- skill card counter texts
local normalSkillCardCounterText = topSkillCardFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
local luckySkillCardCounterText = topSkillCardFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
local goldenNormalSkillCardCounterText = topSkillCardFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
local goldenluckySkillCardCounterText = topSkillCardFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")

local testCards = { [0] = 1405118, 1412042, 1444425, 1431821, 1431935, 1434074, 1180493 }
local testCardIndex = 0

-- unknown skill card "bag slot"
local unknownSkillCards = {}
local unknownCards = 0
local unknownGoldenskillCards = 0
local totalUnknownCards = 0
local normalSkillCards = 0
local luckySkillCards = 0
local goldenSkillCards = 0
local luckyGoldenSkillCards = 0
local totalCards = 0

-- add local "session based" variables here as they are needed
local function BeginNewSession()

  table.wipe(unknownSkillCards)

  unknownCards = 0
  unknownGoldenskillCards = 0
  totalUnknownCards = 0
  normalSkillCards = 0
  luckySkillCards = 0
  goldenSkillCards = 0
  luckyGoldenSkillCards = 0
  totalCards = 0
end


-- reuse card frames
local buttonFramePool = {}

-- button config
local buttonWidth, buttonHeight = 32, 32

-- make sure vanity tab has been opened to query server
local alreadyOpenedVanityTab = false

-- settings
if not AscendedSkillCardsDB then
  AscendedSkillCardsDB = {
    EnableTooltips = true,
    isDebugging = false,
    ForceExchangeCards = false,
    ForceExchangeGoldenCards = false,
    ShowOnOpeningSealedDeck = true,
    ShowOnOpeningExchangeWindow = true,
    HideOnClosingExchangeWindow = true,
    EnableGoldenSkillCards = true,
  }
end

local function DebugPrint(string)
  if (AscendedSkillCardsDB.isDebugging) then print(string) end
end

local function CheckStringForSkillCard(string)
  local itemIsSkillCard = string.find(string, "Skill Card", 1, true) or
      string.find(string, "Lucky Skill Card", 1, true)
  local itemIsGoldenSkillCard = string.find(string, "Golden Skill Card", 1, true) or
      string.find(string, "Lucky Golden Skill Card", 1, true)
  return itemIsSkillCard, itemIsGoldenSkillCard
end

local function CreateDivider(self, xOffset, yOffset)
  local line = self:CreateTexture()
  line:SetTexture("Interface/BUTTONS/WHITE8X8")
  line:SetSize(160, 1)
  line:SetPoint("TOP", xOffset, yOffset)
end

local function CreateText(self, text, xOffset, yOffset, underlined)
  local fontString = self:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  fontString:SetPoint("TOP", xOffset, yOffset)
  fontString:SetText(text)
  if (underlined == true) then
    CreateDivider(self, 0, yOffset - 15)
  end
  return fontString
end

function ASC:DisableAddon(settingGuard)
  if (settingGuard ~= nil) then DebugPrint("DisableAddon passed arg: " .. settingGuard) end
  if (settingGuard ~= nil and AscendedSkillCardsDB[settingGuard] == false) then return end
  topSkillCardFrame:Hide()
end

-- toggle corresponding setting in DB or set it to defaultValue if it doesn't exist.
local function ToggleSetting(nameOfSetting, defaultValue)
  if(nameOfSetting == "" or nil) then DebugPrint("Setting could not be toggled. Bad input") return end
  if (AscendedSkillCardsDB[nameOfSetting] == nil) then
    DebugPrint("Setting: " .. nameOfSetting .. " did not exist in DB. Setting default of " .. tostring(defaultValue))
    AscendedSkillCardsDB[nameOfSetting] = defaultValue
  else
    AscendedSkillCardsDB[nameOfSetting] = not AscendedSkillCardsDB[nameOfSetting]
  end
end

local function CreateAndShowOptionsMenu()
  local menu = {
    {
      text = "Settings",
      isTitle = true
    },
    {
      text = "Show/hide",
      hasArrow = true,
      menuList =
      {
        {
          text = "Show when",
          isTitle = true
        },
        {
          text = "Opening sealed deck",
          keepShownOnClick = true,
          tooltipTitle = "Auto show when opening a sealed deck",
          tooltipOnButton = true,
          checked = AscendedSkillCardsDB.ShowOnOpeningSealedDeck,
          tooltipText = "Show window automatically when opening a sealed deck",
          func = function() ToggleSetting("ShowOnOpeningSealedDeck", true) end
        },
        {
          text = "Opening exchange window",
          keepShownOnClick = true,
          tooltipTitle = "Show on opening exchange gui",
          tooltipOnButton = true,
          checked = AscendedSkillCardsDB.ShowOnOpeningExchangeWindow,
          tooltipText = "Show window when opening exchange card vendor window",
          func = function() ToggleSetting("ShowOnOpeningExchangeWindow", true) end
        },
        {
          text = "Hide when",
          isTitle = true
        },
        {
          text = "Closing exchange window",
          keepShownOnClick = true,
          tooltipTitle = "closing exchange gui",
          tooltipOnButton = true,
          checked = AscendedSkillCardsDB.HideOnClosingExchangeWindow,
          tooltipText = "Hide window when closing the exchange card vendor window",
          func = function() ToggleSetting("HideOnClosingExchangeWindow", true) end
        }
      }
    },
    {
      text = "Show tooltips",
      keepShownOnClick = true,
      tooltipTitle = "Show tooltips",
      tooltipOnButton = true,
      checked = AscendedSkillCardsDB.EnableTooltips,
      tooltipText = "Enable button tooltips",
      func = function() ToggleSetting("EnableTooltips", true) end
    },
    {
      text = "Force exchange",
      hasArrow = true,
      menuList =
      {
        {
          text = "Normal cards",
          keepShownOnClick = true,
          tooltipTitle = "Force normal exchange",
          tooltipOnButton = true,
          checked = AscendedSkillCardsDB.ForceExchangeCards,
          tooltipText = "Exchange cards even if you have unlearned skill cards in inventory",
          func = function() ToggleSetting("ForceExchangeCards", false) end
        },
        {
          text = "Golden cards",
          keepShownOnClick = true,
          tooltipTitle = "Force golden exchange",
          tooltipOnButton = true,
          checked = AscendedSkillCardsDB.ForceExchangeGoldenCards,
          tooltipText = "Exchange golden cards even if you have unlearned golden skill cards in inventory",
          func = function() ToggleSetting("ForceExchangeGoldenCards", false) end
        }
      }
    }
  }
  EasyMenu(menu, skillCardFrameOptionsMenu, skillCardFrameOptionsButton, 0, 119, "MENU")
end

local function SetButtonTooltipText(btn, tooltipIndex)
  local tooltipData = exchangeCardsTooltipData[tooltipIndex]
  local tooltip = exchangeCardsButtonTooltip
  btn:SetScript("OnEnter", function(self, event, ...)
    if (AscendedSkillCardsDB.EnableTooltips) then
      tooltip:SetOwner(topSkillCardFrame, "ANCHOR_TOPRIGHT")
      tooltip:AddLine(tooltipData["header"], 1, 1, 1)
      tooltip:AddLine(tooltipData["text"], 1, 1, 1, true)
      tooltip:AddLine(tooltipData["info"], 1, 1, 1, true)
      tooltip:Show()
    end
  end)
  btn:SetScript("OnLeave", function(self, event, ...)
    tooltip:ClearLines()
    tooltip:Hide()
  end)
end

local function DisplayErrorMessage(errorMessage)
  if (not errorMessage) then return end
  UIErrorsFrame:AddMessage(errorMessage, 1, 0, 0, 1, 1);
end

--[[
  operationindex:
   1 = exchange normal cards
   2 = exchange normal lucky cards
   3 = exchange golden cards
   4 = exchange golden lucky cards
--]]
local function ExchangeCards(operationIndex)
  if (not operationIndex) then return end
  DebugPrint("ExchangeCards passed arg: " .. tostring(operationIndex))
  ScanForUnknownSkillCards()

  -- if we have less than 5 cards total, skedaddle immediately.
  if (totalCards < 5) then
    DisplayErrorMessage("You don't have enough cards for an exchange")
    return
  end

  DebugPrint("-----------------------------")
  DebugPrint("ForceExchangeCards: " .. tostring(AscendedSkillCardsDB.ForceExchangeCards))
  DebugPrint("ForceExchangeGoldenCards: " .. tostring(AscendedSkillCardsDB.ForceExchangeGoldenCards))
  DebugPrint("ExchangeCards thinks you have:")
  DebugPrint("unknownCards: " .. tostring(unknownCards) .. " and unknownGoldenSkillCards: " .. tostring(unknownGoldenskillCards))
  DebugPrint("-----------------------------")

  -- normal cards check
  if ((operationIndex == 1 or operationIndex == 2) and not AscendedSkillCardsDB.ForceExchangeCards and unknownCards ~= 0) then
    DisplayErrorMessage("You have unlearned skill cards in inventory")
    return
  end
  -- golden cards check
  if ((operationIndex == 3 or operationIndex == 4) and not AscendedSkillCardsDB.ForceExchangeGoldenCards and unknownGoldenskillCards ~= 0) then
    DisplayErrorMessage("You have unlearned golden skill cards in inventory")
    return
  end

  if (operationIndex == 1) then
    if (normalSkillCards < 5) then
      DisplayErrorMessage("You don't have enough normal cards for an exchange")
      return
    end
    SkillCardExchangeUI.content.exchange.buttonNormal:Click()
  elseif(operationIndex == 2) then
    if (luckySkillCards < 5) then
      DisplayErrorMessage("You don't have enough lucky cards for an exchange")
      return
    end
    SkillCardExchangeUI.content.exchange.buttonNormalLucky:Click()
  elseif(operationIndex == 3) then
    if(goldenSkillCards < 5) then
      DisplayErrorMessage("You don't have enough golden skill cards for an exchange")
      return
    end
    SkillCardExchangeUI.content.exchange.buttonGold:Click()
  elseif(operationIndex == 4) then
    if (luckyGoldenSkillCards < 5) then
      DisplayErrorMessage("You don't have enough golden lucky cards for an exchange")
      return
    end
    SkillCardExchangeUI.content.exchange.buttonGoldLucky:Click()
  end
 StaticPopup1Button1:Click()
end

local function CreateGossipFrameInteractionButtons()
  -- Exchange 5 normal cards for sealed deck
  local btn = CreateFrame("Button", "exchangeNormalCardsButton", topSkillCardFrame,
    "UIPanelButtonTemplate")
  btn:SetPoint("TOPLEFT", 15, -75)
  btn:SetWidth(85)
  btn:SetHeight(30)
  btn:SetText(ColorChatString("Normal", stringHexColors.White))
  btn:SetScript("OnClick", function(self, button) ExchangeCards(1) end)
  SetButtonTooltipText(btn, 1)
  -- Exchange 5 lucky cards for sealed deck
  btn = CreateFrame("Button", "ExchangeLuckyCardsButton", topSkillCardFrame,
    "UIPanelButtonTemplate")
  btn:SetPoint("TOPLEFT", 15, -105)
  btn:SetWidth(85)
  btn:SetHeight(30)
  btn:SetText(ColorChatString("Lucky", stringHexColors.White))
  btn:SetScript("OnClick", function(self, button) ExchangeCards(2) end)
  SetButtonTooltipText(btn, 2)
  local btn = CreateFrame("Button", "exchangeGoldenSkillCardsButton", topSkillCardFrame,
    "UIPanelButtonTemplate")
  btn:SetPoint("TOPRIGHT", -15, -75)
  btn:SetWidth(85)
  btn:SetHeight(30)
  btn:SetText(ColorChatString("Normal", stringHexColors.Gold))
  btn:SetScript("OnClick", function(self, button) ExchangeCards(3) end)
  SetButtonTooltipText(btn, 3)
  local btn = CreateFrame("Button", "exchangeLuckyGoldenSkillCardsButton", topSkillCardFrame,
    "UIPanelButtonTemplate")
  btn:SetPoint("TOPRIGHT", -15, -105)
  btn:SetWidth(85)
  btn:SetHeight(30)
  btn:SetText(ColorChatString("Lucky", stringHexColors.Gold))
  btn:SetScript("OnClick", function(self, button) ExchangeCards(4) end)
  SetButtonTooltipText(btn, 4)
end

local function SetupGUI()

  -- top container
  topSkillCardFrame:EnableMouse(true)
  topSkillCardFrame:SetWidth(200)
  topSkillCardFrame:SetHeight(defaultSkillCardFrameHeight)

  -- close button
  closeSkillCardFrameButton:SetWidth(30)
  closeSkillCardFrameButton:SetHeight(30)
  closeSkillCardFrameButton:SetPoint("TOPRIGHT", 3, 3)
  closeSkillCardFrameButton:SetScript("OnClick", ASC.DisableAddon)

  -- title
  CreateText(topSkillCardFrame, "Normal/" .. ColorChatString("Golden", stringHexColors.Gold) .. " cards", 0, -10, true)

  -- counters
  normalSkillCardCounterText:SetPoint("TOPLEFT", 25, -35)
  luckySkillCardCounterText:SetPoint("TOPLEFT", 25, -50)
  normalSkillCardCounterText:SetText(menuTexts.NormalCardCounterTextPrefix)
  luckySkillCardCounterText:SetText(menuTexts.LuckySkillCardsCounterPrefix)

  -- upgrade btns
  CreateGossipFrameInteractionButtons()

  -- unknown cards
  unknownSkillCardsInInvTitleText = CreateText(topSkillCardFrame, menuTexts.NoUnknownCardsInInv, 0, -140, true)

  -- drag and drop functionality
  topSkillCardFrame:SetScript(
    "OnMouseDown",
    function(self, button)
      if button == "LeftButton" and not self.isMoving then
        self:StartMoving()
        self.isMoving = true
      end
    end
  )
  topSkillCardFrame:SetScript(
    "OnMouseUp",
    function(self, button)
      if button == "LeftButton" and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
      end
    end
  )

  -- menu
  skillCardFrameOptionsButton:SetHeight(30)
  skillCardFrameOptionsButton:SetWidth(30)
  skillCardFrameOptionsButton:SetPoint("TOPLEFT", 0, 3)
  skillCardFrameOptionsButton:SetNormalTexture("Interface\\Minimap\\UI-Minimap-MinimizeButtonUp-Up")
  skillCardFrameOptionsButton:SetPushedTexture("Interface\\Minimap\\UI-Minimap-MinimizeButtonUp-Down")
  skillCardFrameOptionsButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-MinimizeButtonUp-Highlight")

  skillCardFrameOptionsButton:SetScript("OnClick", function(self, button)
    if (button == "LeftButton") then
      CreateAndShowOptionsMenu()
    end
  end)
end

ColorChatString = function(string, hexColor)
  return "|cff" .. tostring(hexColor) .. tostring(string) .. "|r"
end

ScanForUnknownSkillCards = function()

  BeginNewSession()

  -- TODO: test this later.
  -- C_ContentLoader:Load("SkillCardData")
  if (alreadyOpenedVanityTab == false) then
    Collections:Show()
    StoreCollectionFrame:Show()
    Collections:Hide()
    alreadyOpenedVanityTab = true
  end

  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, GetContainerNumSlots(bag) do
      local link = GetContainerItemLink(bag, slot)
      if link then
        local itemInfo = { GetItemInfo(link) }
        local itemName = itemInfo[1]
        local itemCount = GetItemCount(link, false, false, false)
        local skillCardId = GetContainerItemID(bag, slot)

        -- name can be nil when logging in the first time.
        if (itemName == nil) then break else
          local itemIsSkillCard, itemIsGoldenSkillCard = CheckStringForSkillCard(itemName)
          -- filter on skill cards only
          if (itemIsSkillCard or itemIsGoldenSkillCard) then
            totalCards = totalCards + itemCount

            local isNormalSkillCard = GetSkillCard(skillCardId)
            local isLuckySkillCard = GetLuckyCard(skillCardId)

            if (isNormalSkillCard) then
              if (isNormalSkillCard.isGolden) then
                goldenSkillCards = goldenSkillCards + itemCount
              else
                normalSkillCards = normalSkillCards + itemCount
              end
            end
            if (isLuckySkillCard) then
              if (isLuckySkillCard.isGolden) then
                luckyGoldenSkillCards = luckyGoldenSkillCards + itemCount
              else
                luckySkillCards = luckySkillCards + itemCount
              end
            end

            -- check if skillcard is unknown
            local isSkillCardKnown = IsCollectionItemOwned(skillCardId)
            if (isSkillCardKnown == nil) then
              print("AscendedSkillCards: Could not find info about skill card. Please try opening the VANITY collection tab to refresh the information")
            elseif (isSkillCardKnown == false) then
              unknownSkillCards[skillCardId] = bag .. " " .. slot
              if (isLuckySkillCard and isLuckySkillCard.isGolden or isNormalSkillCard and isNormalSkillCard.isGolden) then
                DebugPrint("Found an unknown golden card")
                unknownGoldenskillCards = unknownGoldenskillCards + 1
              else
                DebugPrint("Found an unknown card")
                unknownCards = unknownCards + 1
              end
            end
          end
        end
      end
    end
  end

  normalSkillCardCounterText:SetText(menuTexts.NormalCardCounterTextPrefix .. normalSkillCards .. " / " .. ColorChatString(goldenSkillCards, stringHexColors.Gold))
  luckySkillCardCounterText:SetText(menuTexts.LuckySkillCardsCounterPrefix .. "  " .. luckySkillCards .. " / " .. ColorChatString(luckyGoldenSkillCards, stringHexColors.Gold))
end

function ASC:EnableAddon(settingGuard)
  if (firstTimeLoadingMenu) then
    DebugPrint("First call, setting up GUI")
    -- make frame closable with esc // this makes the frame close when learning a card :(
    -- _G["skillCardButtonFrame"] = topSkillCardFrame
    -- tinsert(UISpecialFrames, "skillCardButtonFrame");
    SetupGUI()
    -- snap frame to middle first time.
    topSkillCardFrame:SetPoint("CENTER", 0, 0)
    ScanForUnknownSkillCards()
    HideAllButtonFrames()
    AddOrReuseButtonFrames()
    ResizeWindowAndShowButtonFrames()
    UpdateSkillCardsInInventoryText()
    firstTimeLoadingMenu = false
  end
  -- check optional settings flag.
  if (settingGuard ~= nil) then DebugPrint("EnableAddon passed arg: " .. settingGuard) end
  if (settingGuard ~= nil and AscendedSkillCardsDB[settingGuard] == false) then return end
  topSkillCardFrame:Show()
end

local function AddOrReuseSkillCardButtonFrame(skillCardId, skillCardBagSlot, iterator)

  local skillCardItemInfo = { GetItemInfo(skillCardId) }
  local texture = skillCardItemInfo[10]

  if buttonFramePool[iterator] == nil then
    DebugPrint("Creating new frame for skillcard")
    local btn = CreateFrame("Button", "skillCardButtonFrame", topSkillCardFrame,
      "SecureActionButtonTemplate, ActionButtonTemplate")

    btn:SetScript(
      "OnEnter",
      function(self, event, ...)
        GameTooltip_SetDefaultAnchor(GameTooltip, topSkillCardFrame)
        GameTooltip:SetHyperlink(skillCardItemInfo[2])
        GameTooltip:Show()
      end
    )
    btn:SetScript(
      "OnLeave",
      function(self, event, ...)
        GameTooltip:Hide()
      end
    )

    btn.skillCardId = skillCardId
    btn:SetAttribute("type", "item")
    btn:SetAttribute("item", skillCardBagSlot)
    btn:SetWidth(buttonWidth)
    btn:SetHeight(buttonHeight)
    btn:SetNormalTexture(texture)
    btn:GetNormalTexture():SetAllPoints(btn)
    buttonFramePool[iterator] = btn

  else
    DebugPrint("Reusing skillcard button frame")
    local recycledButton = buttonFramePool[iterator]
    recycledButton.skillCardId = skillCardId
    recycledButton:SetAttribute("item", skillCardBagSlot)
    recycledButton:SetNormalTexture(texture)
    recycledButton:GetNormalTexture():SetAllPoints(recycledButton)
    recycledButton:SetScript(
      "OnEnter",
      function(self, event, ...)
        GameTooltip_SetDefaultAnchor(GameTooltip, topSkillCardFrame)
        GameTooltip:SetHyperlink(skillCardItemInfo[2])
        GameTooltip:Show()
      end
    )
  end
end

HideAllButtonFrames = function()
  for _, buttonFrame in pairs(buttonFramePool) do
    buttonFrame.skillCardId = nil
    buttonFrame:Hide()
  end
end

AddOrReuseButtonFrames = function()
  local iterator = 0
  for skillCardId, bagSlot in pairs(unknownSkillCards) do
    if (iterator < 30) then
      AddOrReuseSkillCardButtonFrame(skillCardId, bagSlot, iterator)
      iterator = iterator + 1
    end
  end
end

ResizeWindowAndShowButtonFrames = function()
  topSkillCardFrame:SetHeight(defaultSkillCardFrameHeight)
  for _, _ in pairs(unknownSkillCards) do
    local row, column = 0, 0
    for _, buttonFrame in pairs(buttonFramePool) do
      if (unknownSkillCards[buttonFrame.skillCardId] ~= nil) then
        local xOffset = 4 + column * buttonWidth
        local yOffset = (165 + row * buttonHeight) * -1
        buttonFrame:SetPoint("TOPLEFT", xOffset, yOffset)
        column = column + 1
        if (column > 5) then
          column = 0
          row = row + 1
        end
        if (row < 5) then
          buttonFrame:Show()
        end
      end
    end
  end
  DebugPrint("unknownCards before setHeight: " .. tostring(unknownCards))
  DebugPrint("Unknown golden cards: " .. tostring(unknownGoldenskillCards))
  totalUnknownCards = unknownCards + unknownGoldenskillCards
  DebugPrint("Total unknown cards: " .. tostring(totalUnknownCards))
  topSkillCardFrame:SetHeight(defaultSkillCardFrameHeight +
    math.max(0, (math.ceil(totalUnknownCards / skillCardButtonsPerRow) - 1) * buttonHeight))
end

UpdateSkillCardsInInventoryText = function()
  if (unknownSkillCardsInInvTitleText ~= nil) then
    if (unknownCards > 0 or unknownGoldenskillCards > 0) then
      unknownSkillCardsInInvTitleText:SetText(menuTexts.UnknownCardsInInv)
    else
      unknownSkillCardsInInvTitleText:SetText(menuTexts.NoUnknownCardsInInv)
    end
  end
end

function ASC:BAG_UPDATE(_, bagID)
  local oldUknownCards = unknownCards
  local oldGoldenUknownCards = unknownGoldenskillCards
  ScanForUnknownSkillCards()
  if (bagID >= 0 and (oldUknownCards ~= unknownCards or oldGoldenUknownCards ~= unknownGoldenskillCards)) then
    HideAllButtonFrames()
    AddOrReuseButtonFrames()
    ResizeWindowAndShowButtonFrames()
    UpdateSkillCardsInInventoryText()
  end
end

function ASC:CHAT_MSG_LOOT(_, ...)
  if (AscendedSkillCardsDB.ShowOnOpeningSealedDeck) then
    local lootText = select(1, ...)
    local isSkillCard, isGoldenSkillCard = CheckStringForSkillCard(lootText)
    if (isSkillCard and not isGoldenSkillCard) then
      DebugPrint("Parsed item to be skill card, auto showing window")
      ASC:EnableAddon()
    end
  end
end

-- tmp test variables
local testUnknownCards = 0
local tmpIndex = 0

function ASC:SlashCommand(msg)
  if not msg or msg:trim() == "" then
    if (topSkillCardFrame:IsVisible()) then
      ASC:DisableAddon()
    else
      ASC:EnableAddon()
    end
  elseif (msg == "reset") then
    topSkillCardFrame:SetPoint("CENTER", 0, 0)
    print("AscendedSkillCards: Skillcard frame postion reset.")
  elseif (msg == "debug") then
    AscendedSkillCardsDB.isDebugging = not AscendedSkillCardsDB.isDebugging
    print("AscendedSkillCards: Debug is: " .. tostring(AscendedSkillCardsDB.isDebugging))
  elseif (AscendedSkillCardsDB.isDebugging) then
    if (msg == "scan") then
      ScanForUnknownSkillCards()
    elseif (msg == "menu") then
      CreateAndShowOptionsMenu()
    elseif (msg == "add") then
      if (tmpIndex < 99) then
        DebugPrint("Adding card " .. tmpIndex + 1)
        testUnknownCards = testUnknownCards + 1
        AddOrReuseSkillCardButtonFrame(testCards[testCardIndex % 7], "0 1", tmpIndex)
        testCardIndex = testCardIndex + 1
        tmpIndex = tmpIndex + 1
      end

      local row, column = 0, 0
      for _, buttonFrame in pairs(buttonFramePool) do
        local xOffset = 4 + column * buttonWidth
        local yOffset = (135 + row * buttonHeight) * -1
        buttonFrame:SetPoint("TOPLEFT", xOffset, yOffset)
        column = column + 1
        if (column > (skillCardButtonsPerRow - 1)) then
          column = 0
          row = row + 1
        end
        buttonFrame:Show()
      end
      DebugPrint("cards/max:" .. tostring(math.ceil(testUnknownCards / skillCardButtonsPerRow)))
      topSkillCardFrame:SetHeight(defaultSkillCardFrameHeight +
        math.max(0, (math.ceil(testUnknownCards / skillCardButtonsPerRow) - 1) * buttonHeight))
    end
  end
end

function ASC:OnInitialize()
  self:RegisterChatCommand("asc", "SlashCommand")

  self:RegisterEvent("BAG_UPDATE")
  self:RegisterEvent("CHAT_MSG_LOOT")

  -- Hook skill card exchange frame to show and hide automaticaly on interaction. (Thanks for the tip Anch)
  SkillCardExchangeUI:HookScript("OnShow", function() ASC:EnableAddon("ShowOnOpeningExchangeWindow") end)
  SkillCardExchangeUI:HookScript("OnHide", function() ASC:DisableAddon("HideOnClosingExchangeWindow") end)
end
