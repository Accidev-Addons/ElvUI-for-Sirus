local E, L, V, P, G = unpack(ElvUI)
local BL = E:GetModule('Blizzard')
local B = E:GetModule('Bags')
local LSM = E.Libs.LSM

local unpack, setmetatable = unpack, setmetatable

local _G = _G
local C_Item = C_Item
local GetCurrentGuildBankTab = GetCurrentGuildBankTab
local GetGuildBankItemLink = GetGuildBankItemLink
local hooksecurefunc = hooksecurefunc

local NUM_SLOTS_PER_GUILDBANK_GROUP = 14
local NUM_GUILDBANK_COLUMNS = 7

local itemLevelTexts = setmetatable({}, { __mode = 'k' })

function BL:GuildBank_ItemLevel(button)
	local db = E.db.general.guildBank
	if not db then return end

	local itemLevelText = itemLevelTexts[button]
	if not itemLevelText then
		itemLevelText = button:CreateFontString(nil, 'ARTWORK', nil, 1)
		itemLevelTexts[button] = itemLevelText
	end

	itemLevelText:ClearAllPoints()
	itemLevelText:Point(db.itemLevelPosition, db.itemLevelxOffset, db.itemLevelyOffset)
	itemLevelText:FontTemplate(LSM:Fetch('font', db.itemLevelFont), db.itemLevelFontSize, db.itemLevelFontOutline)

	local ilvl, r, g, b
	local tab = (db.itemLevel or db.itemQuality) and GetCurrentGuildBankTab()
	local itemlink = tab and GetGuildBankItemLink(tab, button:GetID())
	if itemlink then
		local name, _, rarity, itemLevel, _, _, _, _, itemEquipLoc, _, _, _, classID, subClassID = C_Item.GetItemInfo(itemlink)
		if not name then rarity, itemLevel, itemEquipLoc, classID, subClassID = nil, nil, nil, nil, nil end
        if rarity and rarity > 1 then
            r, g, b = E:GetItemQualityColor(rarity)
        end

        if rarity and rarity > 1 and db.itemQuality then
            button:SetBackdropBorderColor(r, g, b)
        else
            button:SetBackdropBorderColor(unpack(E.media.bordercolor))
        end

		local canShowItemLevel = B:IsItemEligibleForItemLevelDisplay(classID, subClassID, itemEquipLoc, rarity)
		if canShowItemLevel and db.itemLevel then
			local custom = db.itemLevelCustomColorEnable and db.itemLevelCustomColor
			if custom  then
				r, g, b = custom.r, custom.g, custom.b
            elseif rarity and rarity > 1 then -- we already do this above otherwise
				r, g, b = E:GetItemQualityColor(rarity)
			end

			ilvl = itemLevel
		end
	else
		button:SetBackdropBorderColor(unpack(E.media.bordercolor))
	end

	itemLevelText:SetText(ilvl and ilvl >= db.itemLevelThreshold and ilvl or '')
	itemLevelText:SetTextColor(r or 1, g or 1, b or 1)
end

function BL:GuildBank_CountText(button)
	local db = E.db.general.guildBank
	if not db then return end

	local count = button.Count or _G[button:GetName()..'Count']
	count:ClearAllPoints()
	count:Point(db.countPosition, db.countxOffset, db.countyOffset)
	count:FontTemplate(LSM:Fetch('font', db.countFont), db.countFontSize, db.countFontOutline)
	count:SetTextColor(db.countFontColor.r, db.countFontColor.g, db.countFontColor.b)
end

function BL:GuildBank_Update()
	local frame = _G.GuildBankFrame
	if not frame or not frame:IsShown() then return end

    if frame.inset then
        frame.inset:Point('BOTTOMRIGHT', frame.mode ~= 'bank' and -29 or -8, 62)
    end

    if frame.mode ~= 'bank' then
        return
    else
        _G.GuildBankColumn1:Point('TOPLEFT', 20, -70)
    end

	for i = 1, NUM_GUILDBANK_COLUMNS do
		for x = 1, NUM_SLOTS_PER_GUILDBANK_GROUP do
			local button = _G['GuildBankColumn'..i..'Button'..x]

			BL:GuildBank_ItemLevel(button)
			BL:GuildBank_CountText(button)
		end
	end
end

function BL:ImproveGuildBank()
	hooksecurefunc('GuildBankFrame_Update', BL.GuildBank_Update)
end
