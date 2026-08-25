local E, L, V, P, G = unpack(ElvUI)
local B = E:GetModule('Bags')
local D = B:NewModule('Deconstruct', 'AceHook-3.0', 'AceEvent-3.0')
local LIS = E.Libs.ItemSearch

local _G = _G
local ipairs, pairs, pcall, select = ipairs, pairs, pcall, select
local setmetatable, tonumber, tostring, type = setmetatable, tonumber, tostring, type
local format, gmatch, strfind, strmatch = format, gmatch, strfind, strmatch
local tinsert, wipe = tinsert, wipe

local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local GameTooltip_Hide = GameTooltip_Hide
local InCombatLockdown = InCombatLockdown
local IsSpellKnown = IsSpellKnown

local GetContainerItemInfo = GetContainerItemInfo
local GetContainerItemLink = GetContainerItemLink
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetItemInfoEx = GetItemInfoEx
local GetItemSetInfo = GetItemSetInfo
local GetSpellInfo = GetSpellInfo
local GetTime = GetTime
local GetTradeTargetItemLink = GetTradeTargetItemLink

local C_Item_GetItemInfo = C_Item.GetItemInfo

local ShowOverlayGlow = ActionButton_ShowOverlayGlow
local HideOverlayGlow = ActionButton_HideOverlayGlow

local ITEM_DISENCHANT_ANY_SKILL = ITEM_DISENCHANT_ANY_SKILL
local ITEM_DISENCHANT_MIN_SKILL = ITEM_DISENCHANT_MIN_SKILL
local ITEM_DISENCHANT_NOT_DISENCHANTABLE = ITEM_DISENCHANT_NOT_DISENCHANTABLE
local ITEM_MILLABLE = ITEM_MILLABLE
local ITEM_PROSPECTABLE = ITEM_PROSPECTABLE
local LOCKED = LOCKED

local DE_TEXTURE = [[Interface\ICONS\INV_Rod_Enchantedcobalt]]
local DE_TEXTURE_ACTIVE = [[Interface\ICONS\INV_Enchant_EssenceCosmicGreater]]

local PROCESS_UNLOCK = 'unlock'
local PROCESS_PROSPECT = 'prospect'
local PROCESS_MILL = 'mill'
local PROCESS_DISENCHANT = 'disenchant'

D.PrimeDEID = 311891
D.DEname = GetSpellInfo(13262)
D.DEPrimeName = GetSpellInfo(311891)
D.MILLname = GetSpellInfo(51005)
D.PROSPECTname = GetSpellInfo(31252)
D.LOCKname = GetSpellInfo(1804)

D.ItemTable = {
	DoNotDE = {
		['49715'] = true,
		['44731'] = true,
		['21524'] = true,
		['51525'] = true,
		['70923'] = true,
		['34486'] = true,
		['11287'] = true,
		['11288'] = true,
		['11289'] = true,
		['11290'] = true,
		['4614'] = true,
		['20406'] = true,
		['20407'] = true,
		['20408'] = true,
		['21766'] = true,
	},
	Cooking = {
		['46349'] = true,
	},
	Fishing = {
		['19022'] = true,
		['19970'] = true,
		['25978'] = true,
		['44050'] = true,
		['45858'] = true,
		['45991'] = true,
		['45992'] = true,
		['33820'] = true,
	}
}

local prospectableOres = {
	[2770] = true,
	[2771] = true,
	[2772] = true,
	[3858] = true,
	[10620] = true,
	[23424] = true,
	[23425] = true,
	[36909] = true,
	[36912] = true,
	[36910] = true,
}

local millableHerbs = {
	[765] = true,
	[785] = true,
	[2447] = true,
	[2449] = true,
	[2450] = true,
	[2452] = true,
	[2453] = true,
	[3355] = true,
	[3356] = true,
	[3357] = true,
	[3358] = true,
	[3369] = true,
	[3818] = true,
	[3819] = true,
	[3820] = true,
	[3821] = true,
	[4625] = true,
	[8831] = true,
	[8836] = true,
	[8838] = true,
	[8839] = true,
	[8845] = true,
	[8846] = true,
	[13463] = true,
	[13464] = true,
	[13465] = true,
	[13466] = true,
	[13467] = true,
	[22785] = true,
	[22786] = true,
	[22787] = true,
	[22789] = true,
	[22790] = true,
	[22791] = true,
	[22792] = true,
	[22793] = true,
	[36901] = true,
	[36903] = true,
	[36904] = true,
	[36905] = true,
	[36906] = true,
	[36907] = true,
	[37921] = true,
	[39970] = true,
}

local skeletonKeys = { 43853, 43854, 15872, 15871, 15870, 15869 }

D.DeconstructMode = false
D.BlacklistDE = {}
D.BlacklistLOCK = {}
D.BlacklistDEPatterns = {}
D.BlacklistLOCKPatterns = {}
D.ItemProcessingCache = {}
D.UnlockableCache = {}
D.PendingItemInfo = {}
D.DeconstructButtons = setmetatable({}, { __mode = 'k' })

local disenchantMinSkillPrefix = ITEM_DISENCHANT_MIN_SKILL and strmatch(ITEM_DISENCHANT_MIN_SKILL, '^(.-)%%s')

local eventFrame = CreateFrame('Frame')
eventFrame:SetScript('OnEvent', function(_, event, ...)
	local func = D[event]
	if func then func(D, event, ...) end
end)

local processTooltip
local function PrepareProcessTooltip(itemLink, bag, slot)
	if not itemLink then return end

	if not processTooltip then
		processTooltip = CreateFrame('GameTooltip', 'ElvUI_DeconstructScanTooltip', E.UIParent, 'GameTooltipTemplate')
	end

	processTooltip:SetOwner(E.UIParent, 'ANCHOR_NONE')
	processTooltip:ClearLines()

	if bag ~= nil and slot then
		processTooltip:SetBagItem(bag, slot)
	else
		processTooltip:SetHyperlink(itemLink)
	end

	return processTooltip:GetName(), processTooltip:NumLines()
end

local function FinishProcessTooltip()
	if not processTooltip then return end

	processTooltip:Hide()
	processTooltip:ClearLines()
end

local function MatchesSearch(link, query)
	if not (LIS and link and query) then return false end

	local success, result = pcall(LIS.Matches, LIS, link, query)
	return success and result
end

local function GetItemClassAndSet(item)
	local _, _, _, _, _, _, _, _, _, _, _, _, classID, _, _, setID = GetItemInfoEx(item)
	return classID, setID
end

local function IsGladiatorName(name)
	if not name then return false end

	return (strfind(name, 'гладиатор', 1, true) or strfind(name, 'Гладиатор', 1, true)
		or strfind(name, 'gladiator', 1, true) or strfind(name, 'Gladiator', 1, true)) and true or false
end

local function IsGladiatorItem(itemName, setID)
	if IsGladiatorName(itemName) then return true end

	if setID and setID ~= 0 and GetItemSetInfo then
		return IsGladiatorName(GetItemSetInfo(setID))
	end

	return false
end

local function GetSlotLocation(button)
	if not button then return end

	local bag, slot = button.BagID, button.SlotID

	if bag == nil then bag = button.bag end
	if slot == nil then slot = button.slot end

	if bag == nil and button.GetParent then
		local parent = button:GetParent()
		if parent and parent.GetID then bag = parent:GetID() end
	end

	if slot == nil and button.GetID then slot = button:GetID() end

	return bag, slot
end

local function IsKnownContainerSlot(button, bag)
	if button.bag ~= nil then return true end
	if B.BagFrame and B.BagFrame.Bags and B.BagFrame.Bags[bag] then return true end
	if B.BankFrame and B.BankFrame.Bags and B.BankFrame.Bags[bag] then return true end

	return false
end

function D:HasRelevantProfession()
	return (D.HasEnchanting or D.HasInscription or D.HasJewelcrafting or D.HasPickLock) and true or false
end

function D:UpdateProfessions()
	D.HasEnchanting = false
	D.HasInscription = false
	D.HasJewelcrafting = false
	D.HasPickLock = false

	if not D.DEPrimeName and D.PrimeDEID then
		D.DEPrimeName = GetSpellInfo(D.PrimeDEID)
	end

	if (D.DEname and GetSpellInfo(D.DEname)) or (D.DEPrimeName and GetSpellInfo(D.DEPrimeName)) or (D.PrimeDEID and IsSpellKnown(D.PrimeDEID)) then
		D.HasEnchanting = true
	end

	if D.MILLname and GetSpellInfo(D.MILLname) then D.HasInscription = true end
	if D.PROSPECTname and GetSpellInfo(D.PROSPECTname) then D.HasJewelcrafting = true end
	if D.LOCKname and GetSpellInfo(D.LOCKname) then D.HasPickLock = true end

	wipe(D.ItemProcessingCache)
end

function D:GetAvailableKey()
	local now = GetTime()
	if D._keyCheckTime and now < D._keyCheckTime then
		return D._availableKey
	end

	local availableKey
	for _, keyID in ipairs(skeletonKeys) do
		if GetItemCount(keyID) > 0 then
			availableKey = GetItemInfo(keyID) or ('item:'..keyID)
			break
		end
	end

	D._keyCheckTime = now + 0.5

	if D._availableKey ~= availableKey then
		D._availableKey = availableKey
		wipe(D.ItemProcessingCache)
	end

	return availableKey
end

local function BuildBlacklist(list, patterns, db, global)
	wipe(list)
	wipe(patterns)
	wipe(D.ItemProcessingCache)

	if type(db) == 'string' then
		local parsed = {}
		for item in gmatch(db, '([^,]+)') do
			tinsert(parsed, item)
		end
		db = parsed
	end

	for _, source in ipairs({ db or {}, global or {} }) do
		for _, value in pairs(source) do
			if value and value ~= '' then
				local entry = tostring(value)
				entry = strmatch(entry, '^%s*(.-)%s*$') or entry

				local itemName = GetItemInfo(entry)
				if itemName then
					list[itemName] = true
				else
					tinsert(patterns, entry)
				end
			end
		end
	end
end

function D:BuildBlacklistDE()
	BuildBlacklist(D.BlacklistDE, D.BlacklistDEPatterns, E.db.bags.deconstructBlacklist, E.global.bags.deconstructBlacklist)
end

function D:BuildBlacklistLOCK()
	BuildBlacklist(D.BlacklistLOCK, D.BlacklistLOCKPatterns, E.db.bags.lockBlacklist, E.global.bags.lockBlacklist)
end

function D:Blacklisting(skill)
	if skill == 'DE' then
		D:BuildBlacklistDE()
	elseif skill == 'LOCK' then
		D:BuildBlacklistLOCK()
	end
end

function D:IsBreakable(itemId, itemName, itemLink)
	if not itemId then return false end

	if type(itemId) == 'number' then itemId = tostring(itemId) end

	if D.ItemTable.DoNotDE[itemId] then return false end
	if D.ItemTable.Cooking[itemId] then return false end
	if D.ItemTable.Fishing[itemId] then return false end
	if itemName and D.BlacklistDE[itemName] then return false end

	for _, query in ipairs(D.BlacklistDEPatterns) do
		if query ~= '' and MatchesSearch(itemLink or itemName, query) then
			return false
		end
	end

	return true
end

function D:IsDisenchantableTooltip(itemLink, bag, slot)
	local tooltipName, numLines = PrepareProcessTooltip(itemLink, bag, slot)
	if not tooltipName then return nil end

	local result
	for i = 2, numLines do
		local line = _G[tooltipName..'TextLeft'..i]
		local text = line and line:GetText()

		if text == ITEM_DISENCHANT_NOT_DISENCHANTABLE then
			result = false
			break
		elseif text == ITEM_DISENCHANT_ANY_SKILL or (text and disenchantMinSkillPrefix and strfind(text, disenchantMinSkillPrefix, 1, true) == 1) then
			result = true
			break
		end
	end

	FinishProcessTooltip()

	return result
end

function D:IsDisenchantable(itemId, itemName, itemLink, itemRarity, itemType, itemEquipLoc, bag, slot)
	if not itemId or not itemName or not D.HasEnchanting then return false end

	local tooltipResult = D:IsDisenchantableTooltip(itemLink, bag, slot)
	if tooltipResult ~= nil then return tooltipResult end

	local classID, setID = GetItemClassAndSet(itemLink or itemId)
	if IsGladiatorItem(itemName, setID) then return false end

	if not itemRarity or itemRarity < 2 or itemRarity > 4 then return false end
	if classID ~= 2 and classID ~= 4 then return false end
	if not itemEquipLoc or itemEquipLoc == '' then return false end

	return true
end

function D:IsProspectable(itemId)
	if not itemId or not D.HasJewelcrafting then return false end

	return prospectableOres[tonumber(itemId)] or false
end

function D:IsProspectableTooltip(itemLink, bag, slot)
	if not itemLink or not ITEM_PROSPECTABLE then return false end

	local tooltipName, numLines = PrepareProcessTooltip(itemLink, bag, slot)
	if not tooltipName then return false end

	local result = false
	for i = 2, numLines do
		local line = _G[tooltipName..'TextLeft'..i]
		local text = line and line:GetText()

		if text and strfind(text, ITEM_PROSPECTABLE, 1, true) then
			result = true
			break
		end
	end

	FinishProcessTooltip()

	return result
end

function D:IsMillable(itemId)
	if not itemId or not D.HasInscription then return false end

	return millableHerbs[tonumber(itemId)] or false
end

function D:IsMillableTooltip(itemLink, bag, slot)
	if not itemLink or not ITEM_MILLABLE then return false end

	local tooltipName, numLines = PrepareProcessTooltip(itemLink, bag, slot)
	if not tooltipName then return false end

	local result = false
	for i = 2, numLines do
		local line = _G[tooltipName..'TextLeft'..i]
		local text = line and line:GetText()

		if text and strfind(text, ITEM_MILLABLE, 1, true) then
			result = true
			break
		end
	end

	FinishProcessTooltip()

	return result
end

function D:IsUnlockable(itemLink, bag, slot)
	if not itemLink or not LOCKED then return false end

	local cached = D.UnlockableCache[itemLink]
	if cached ~= nil then return cached end

	local tooltipName, numLines = PrepareProcessTooltip(itemLink, bag, slot)
	if not tooltipName then return false end

	local result = false
	for i = 2, numLines do
		local line = _G[tooltipName..'TextLeft'..i]
		local text = line and line:GetText()

		if text and strfind(text, LOCKED, 1, true) then
			result = true
			break
		end
	end

	FinishProcessTooltip()

	D.UnlockableCache[itemLink] = result

	return result
end

function D:GetProcessAction(itemLink, hasKey, count, bag, slot)
	if not itemLink then return end

	local itemId = tonumber(strmatch(itemLink, 'item:(%d+)'))
	if not itemId then return end

	local itemName, _, itemRarity, _, _, itemType, _, _, itemEquipLoc = GetItemInfo(itemId)
	if not itemName then
		D.PendingItemInfo[itemId] = true
		C_Item_GetItemInfo(itemId, true)
		return
	end

	if (D.HasPickLock or hasKey) and D:IsUnlockable(itemLink, bag, slot) then
		if D.BlacklistLOCK[itemName] then return end

		for _, query in ipairs(D.BlacklistLOCKPatterns) do
			if query ~= '' and MatchesSearch(itemLink, query) then return end
		end

		if D.HasPickLock then
			return PROCESS_UNLOCK, D.LOCKname, 'spell', itemId
		elseif hasKey then
			return PROCESS_UNLOCK, hasKey, 'item', itemId
		end
	end

	local process = D.ItemProcessingCache[itemId]
	if process == nil then
		process = false

		if D.HasJewelcrafting and (D:IsProspectable(itemId) or D:IsProspectableTooltip(itemLink, bag, slot)) then
			process = PROCESS_PROSPECT
		elseif D.HasInscription and (D:IsMillable(itemId) or D:IsMillableTooltip(itemLink, bag, slot)) then
			process = PROCESS_MILL
		elseif D.HasEnchanting and D:IsDisenchantable(itemId, itemName, itemLink, itemRarity, itemType, itemEquipLoc, bag, slot) then
			if D:IsBreakable(itemId, itemName, itemLink) then
				process = PROCESS_DISENCHANT
			end
		end

		D.ItemProcessingCache[itemId] = process
	end

	if process == PROCESS_PROSPECT and (count or 0) >= 5 then
		return process, D.PROSPECTname, 'spell', itemId
	elseif process == PROCESS_MILL and (count or 0) >= 5 then
		return process, D.MILLname, 'spell', itemId
	elseif process == PROCESS_DISENCHANT then
		local spell = D.DEname
		if D.DEPrimeName and IsSpellKnown(D.PrimeDEID) then
			spell = D.DEPrimeName
		end

		return process, spell, 'spell', itemId
	end
end

function D:CanProcessItem(itemLink, hasKey, count, bag, slot)
	return D:GetProcessAction(itemLink, hasKey, count, bag, slot) ~= nil
end

function D:ApplyDeconstruct(itemLink, itemId, spell, spellType, button, bag, slotID)
	if not (button and spell and D.DeconstructionReal) then return end
	if button == D.DeconstructionReal then return end
	if bag == nil or not slotID then return end
	if not IsKnownContainerSlot(button, bag) then return end

	if GetTradeTargetItemLink and GetTradeTargetItemLink(7) == itemLink then return end
	if GetContainerItemLink(bag, slotID) ~= itemLink then return end

	local frame = D.DeconstructionReal
	local targetKey = format('%s:%s:%s:%s:%s:%s', bag, slotID, itemId, spellType, tostring(spell), tostring(button))

	if frame.TargetKey == targetKey and frame:IsShown() then
		if ShowOverlayGlow then ShowOverlayGlow(frame) end
		return
	end

	frame.TargetKey = targetKey
	frame.Bag = bag
	frame.Slot = slotID
	frame.ID = itemId
	frame:SetAttribute('type1', spellType)
	frame:SetAttribute(spellType, spell)
	frame:SetAttribute('target-bag', bag)
	frame:SetAttribute('target-slot', slotID)
	frame:SetAllPoints(button)
	frame:Show()

	E.Libs.CustomGlow.PixelGlow_Start(frame, E.media.customGlowColor, 8, 0.25, nil, 2, 0, 0, false, 'Deconstruct')

	if ShowOverlayGlow then ShowOverlayGlow(frame) end
end

function D:DeconstructParser()
	if not D.DeconstructMode then return end
	if not GameTooltip:IsVisible() then return end

	local owner = GameTooltip:GetOwner()
	if not owner then return end

	local ownerName = owner.GetName and owner:GetName()
	if not ownerName then return end

	local isAdiBagsItem = strfind(ownerName, 'AdiBagsItemButton') or strfind(ownerName, 'AdiBagsBankItemButton')
	if not (strfind(ownerName, 'ElvUI_ContainerFrameBag') or strfind(ownerName, 'ElvUI_BankContainerFrameBag') or isAdiBagsItem) then return end

	local bag, slot = GetSlotLocation(owner)
	if bag == nil or not slot then return end

	local itemLink = GetContainerItemLink(bag, slot)
	if not itemLink then return end

	if InCombatLockdown() then return end

	local count = select(2, GetContainerItemInfo(bag, slot)) or 0
	local process, spell, spellType, itemId = D:GetProcessAction(itemLink, D:GetAvailableKey(), count, bag, slot)

	if process then
		D:ApplyDeconstruct(itemLink, itemId, spell, spellType, owner, bag, slot)
	end
end

function D:GetDeconMode()
	if D.DeconstructMode then
		return '|cff00FF00 '..L["Enabled"]..'|r'
	end

	return '|cffFF0000 '..L["Disabled"]..'|r'
end

function D:UpdateDeconstructButton(button)
	if not button then return end

	B:SetButtonTexture(button, D.DeconstructMode and DE_TEXTURE_ACTIVE or DE_TEXTURE)

	if D.DeconstructMode then
		if ShowOverlayGlow then ShowOverlayGlow(button) end
	else
		if HideOverlayGlow then HideOverlayGlow(button) end
	end

	button.ttText2 = format(L["Deconstruct Mode Desc"]..'\n'..L["Current state: %s."], D:GetDeconMode())

	if D:HasRelevantProfession() then
		button:Enable()
		button:SetAlpha(1)
	else
		button:Disable()
		button:SetAlpha(0.5)
	end

	if GameTooltip:IsOwned(button) then B.Tooltip_Show(button) end
end

function D:RegisterDeconstructButton(button)
	if not button then return end

	D.DeconstructButtons[button] = true
	D.DeconstructButton = D.DeconstructButton or button

	D:UpdateDeconstructButton(button)
end

function D:UpdateButtonState()
	for button in pairs(D.DeconstructButtons) do
		D:UpdateDeconstructButton(button)
	end
end

function D:UpdateBagSlots(frame, isActive, onlyBagID)
	if not (frame and frame.Bags and frame.BagIDs) then return end

	local hasKey = D:GetAvailableKey()

	for _, bagID in ipairs(frame.BagIDs) do
		if (not onlyBagID) or (onlyBagID == bagID) then
			local bag = frame.Bags[bagID]

			if bag then
				for slotID = 1, B:GetContainerNumSlots(bagID) do
					local slot = bag[slotID]

					if slot then
						if isActive then
							local itemLink = GetContainerItemLink(bagID, slotID)
							local count = select(2, GetContainerItemInfo(bagID, slotID)) or 0

							if itemLink and D:CanProcessItem(itemLink, hasKey, count, bagID, slotID) then
								slot:SetAlpha(1)
							else
								slot:SetAlpha(0.3)
							end
						else
							slot:SetAlpha(1)
						end
					end
				end
			end
		end
	end
end

function D:SetMode(enabled)
	enabled = not not enabled

	if enabled and not D:HasRelevantProfession() then return false end

	D.DeconstructMode = enabled
	D:UpdateButtonState()

	if B.BagFrame then D:UpdateBagSlots(B.BagFrame, enabled) end
	if B.BankFrame then D:UpdateBagSlots(B.BankFrame, enabled) end

	if not enabled and D.DeconstructionReal then D.DeconstructionReal:OnLeave() end

	D:SendMessage('AdiBags_UpdateAllButtons')

	return true
end

function D:ToggleMode()
	return D:SetMode(not D.DeconstructMode)
end

function D:ConstructRealDecButton()
	local frame = CreateFrame('Button', 'ElvUI_DeconstructOverlay', E.UIParent, 'SecureActionButtonTemplate')
	frame:SetScript('OnEvent', function(obj, event, ...) obj[event](obj, ...) end)
	frame:RegisterForClicks('AnyUp', 'AnyDown')
	frame:SetFrameStrata('TOOLTIP')
	frame:Hide()

	local customGlow = E.Libs.CustomGlow

	frame.OnLeave = function(self)
		if D.DeconstructMode and self:IsMouseOver() then
			if ShowOverlayGlow then ShowOverlayGlow(self) end
			return
		end

		customGlow.PixelGlow_Stop(self, 'Deconstruct')

		if InCombatLockdown() then
			self:SetAlpha(0)
			self:RegisterEvent('PLAYER_REGEN_ENABLED')
		else
			self.TargetKey = nil
			self:ClearAllPoints()
			self:SetAlpha(1)

			if GameTooltip then GameTooltip:Hide() end
			if HideOverlayGlow then HideOverlayGlow(self) end

			self:Hide()
		end
	end

	frame.SetTip = function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_LEFT', 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:SetBagItem(self.Bag, self.Slot)

		if ShowOverlayGlow then ShowOverlayGlow(self) end

		E:Delay(0, function()
			if self:IsShown() and self:IsMouseOver() and ShowOverlayGlow then
				ShowOverlayGlow(self)
			end
		end)
	end

	frame.PLAYER_REGEN_ENABLED = function(self)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED')
		self:OnLeave()
	end

	frame:SetScript('OnEnter', frame.SetTip)
	frame:SetScript('OnLeave', frame.OnLeave)

	D.DeconstructionReal = frame
end

local function DeconstructButton_OnClick()
	D:ToggleMode()
end

local function CreateDeconstructButton(bagFrame)
	if not (bagFrame and bagFrame.holderFrame) then return end
	if bagFrame.deconstructButton then return end

	local button = CreateFrame('Button', nil, bagFrame.holderFrame)
	button:Size(20)
	button:SetTemplate()

	if bagFrame.vendorGraysButton then
		button:Point('RIGHT', bagFrame.vendorGraysButton, 'LEFT', -5, 0)
	elseif bagFrame.sortButton then
		button:Point('RIGHT', bagFrame.sortButton, 'LEFT', -5, 0)
	else
		button:Point('TOPRIGHT', bagFrame, 'TOPRIGHT', -25, -5)
	end

	B:SetButtonTexture(button, DE_TEXTURE)
	button:StyleButton(nil, true)

	button.ttText = L["Deconstruct Mode"]
	button.ttText2 = format(L["Deconstruct Mode Desc"]..'\n'..L["Current state: %s."], D:GetDeconMode())

	button:SetScript('OnEnter', B.Tooltip_Show)
	button:SetScript('OnLeave', GameTooltip_Hide)
	button:SetScript('OnClick', DeconstructButton_OnClick)

	bagFrame.deconstructButton = button

	if bagFrame.editBox then
		bagFrame.editBox:ClearAllPoints()
		bagFrame.editBox:Point('BOTTOMLEFT', bagFrame.holderFrame, 'TOPLEFT', E.Border, 4)
		bagFrame.editBox:Point('RIGHT', button, 'LEFT', -7, 0)
	end

	D:RegisterDeconstructButton(button)
end

local function BagFrame_OnHide()
	D:SetMode(false)
end

local function SetupDeconstructButton()
	if not B.BagFrame then return end
	if B.BagFrame.deconstructButton then return end

	CreateDeconstructButton(B.BagFrame)
	D:InitializeExternal()

	if not B.BagFrame.deconstructHideHooked then
		B.BagFrame:HookScript('OnHide', BagFrame_OnHide)
		B.BagFrame.deconstructHideHooked = true
	end
end

function D:ScheduleModeRefresh()
	if D.ModeRefreshScheduled then return end

	D.ModeRefreshScheduled = true

	E:Delay(0.1, function()
		D.ModeRefreshScheduled = nil

		if not D.DeconstructMode then return end

		if B.BagFrame then D:UpdateBagSlots(B.BagFrame, true) end
		if B.BankFrame then D:UpdateBagSlots(B.BankFrame, true) end

		D:SendMessage('AdiBags_UpdateAllButtons')
	end)
end

function D:SKILL_LINES_CHANGED()
	D:UpdateProfessions()
	D:UpdateButtonState()
end

function D:SPELLS_CHANGED()
	D:UpdateProfessions()
	D:UpdateButtonState()
end

function D:LEARNED_SPELL_IN_TAB()
	D:UpdateProfessions()
	D:UpdateButtonState()
end

function D:CHAT_MSG_ADDON(_, prefix, msg)
	if prefix == 'INVOKE_CLIENT_BUTTON' and msg and strfind(msg, tostring(D.PrimeDEID), 1, true) then
		D:UpdateProfessions()
		D:UpdateButtonState()
	end
end

function D:GET_ITEM_INFO_RECEIVED(_, itemID, success)
	if not D.PendingItemInfo[itemID] then return end

	D.PendingItemInfo[itemID] = nil
	D.ItemProcessingCache[itemID] = nil

	if success ~= false and D.DeconstructMode then
		D:ScheduleModeRefresh()
	end
end

function D:BAG_UPDATE(_, bagID)
	D._keyCheckTime = nil
	wipe(D.UnlockableCache)
	D:GetAvailableKey()

	if D.DeconstructMode then
		if B.BagFrame then D:UpdateBagSlots(B.BagFrame, true, bagID) end
		if B.BankFrame then D:UpdateBagSlots(B.BankFrame, true, bagID) end
	end
end

function D:BAG_UPDATE_DELAYED()
	D._keyCheckTime = nil
	wipe(D.UnlockableCache)
	D:GetAvailableKey()

	if D.DeconstructMode then
		D:ScheduleModeRefresh()
	end
end

function D:PLAYER_REGEN_ENABLED()
	if not D.PendingExternalInit then return end

	D:UnregisterEvent('PLAYER_REGEN_ENABLED')
	D:InitializeExternal()
end

local function MigrateDeconstructBlacklist()
	if type(E.db.bags.deconstructBlacklist) ~= 'string' then return end

	local newTable = {}
	for item in gmatch(E.db.bags.deconstructBlacklist, '([^,]+)') do
		item = strmatch(item, '^%s*(.-)%s*$')

		if item and item ~= '' then
			local itemID = strmatch(item, 'item:(%d+)')
			newTable[(itemID or item)] = item
		end
	end

	E.db.bags.deconstructBlacklist = newTable
end

local function GameTooltip_Parse()
	D:DeconstructParser()
end

function D:InitializeExternal()
	if not E.db.bags.deconstruct then return false end

	if not D.RuntimeInitialized then
		MigrateDeconstructBlacklist()
		D:UpdateProfessions()
		D:Blacklisting('DE')
		D:Blacklisting('LOCK')

		D:RegisterEvent('BAG_UPDATE')
		D:RegisterEvent('SKILL_LINES_CHANGED')
		D:RegisterEvent('CHAT_MSG_ADDON')
		D:RegisterEvent('SPELLS_CHANGED')
		D:RegisterEvent('LEARNED_SPELL_IN_TAB')

		if eventFrame.RegisterCustomEvent then
			pcall(eventFrame.RegisterCustomEvent, eventFrame, 'BAG_UPDATE_DELAYED')
			pcall(eventFrame.RegisterCustomEvent, eventFrame, 'GET_ITEM_INFO_RECEIVED')
		end

		D.RuntimeInitialized = true
	end

	if not D.DeconstructionReal then
		if InCombatLockdown() then
			D.PendingExternalInit = true
			D:RegisterEvent('PLAYER_REGEN_ENABLED')
			return false
		end

		D:ConstructRealDecButton()
	end

	if not D.TooltipHooksInstalled then
		GameTooltip:HookScript('OnShow', GameTooltip_Parse)
		GameTooltip:HookScript('OnUpdate', GameTooltip_Parse)
		D.TooltipHooksInstalled = true
	end

	D.PendingExternalInit = nil
	D:UpdateButtonState()

	return true
end

local function Container_OnDragStop(frame)
	if not D.DeconstructMode then return end

	D:UpdateBagSlots(frame, true)

	if frame ~= B.BagFrame and B.BagFrame then D:UpdateBagSlots(B.BagFrame, true) end
	if frame ~= B.BankFrame and B.BankFrame then D:UpdateBagSlots(B.BankFrame, true) end
end

function D:Initialize()
	if not E.private.bags.enable then return end
	if not E.db.bags.deconstruct then return end

	D:InitializeExternal()

	hooksecurefunc(B, 'Layout', function(_, isBank)
		if not isBank and B.BagFrame and not B.BagFrame.deconstructButton then
			E:Delay(0.1, SetupDeconstructButton)
		end

		if D.DeconstructMode then
			E:Delay(0.05, function()
				if B.BagFrame then D:UpdateBagSlots(B.BagFrame, true) end
				if B.BankFrame then D:UpdateBagSlots(B.BankFrame, true) end
			end)
		end

		if B.BagFrame and not B.BagFrame.deconstructDragHooked then
			B.BagFrame:HookScript('OnDragStop', Container_OnDragStop)
			B.BagFrame.deconstructDragHooked = true
		end

		if B.BankFrame and not B.BankFrame.deconstructDragHooked then
			B.BankFrame:HookScript('OnDragStop', Container_OnDragStop)
			B.BankFrame.deconstructDragHooked = true
		end
	end)

	if B.BagFrame and not B.BagFrame.deconstructButton then
		E:Delay(0.1, SetupDeconstructButton)
	end
end

hooksecurefunc(B, 'Initialize', function() D:Initialize() end)
