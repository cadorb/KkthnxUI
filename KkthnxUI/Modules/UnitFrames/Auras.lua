local K, C, L, _ = select(2, ...):unpack()
if C.Unitframe.Enable ~= true then return end

local _G = _G
local GetName = GetName
local UnitIsFriend = UnitIsFriend
local hooksecurefunc = hooksecurefunc

TargetFrame.maxBuffs = 16
TargetFrame.maxDebuffs = 16
MAX_TARGET_BUFFS = 16
MAX_TARGET_DEBUFFS = 16

-- AURAS
local function TargetAuraColour(self)
	-- BUFFS
	for i = 1, MAX_TARGET_BUFFS do
		local bframe = _G[self:GetName().."Buff"..i]
		local bframecd = _G[self:GetName().."Buff"..i.."Cooldown"]
		local bframecount = _G[self:GetName().."Buff"..i.."Count"]
		if bframe then
			K.CreateBorder(bframe, 8)

			bframecd:ClearAllPoints()
			bframecd:SetPoint("TOPLEFT", bframe, 1.5, -1.5)
			bframecd:SetPoint("BOTTOMRIGHT", bframe, -1.5, 1.5)

			bframecount:ClearAllPoints()
			bframecount:SetPoint("CENTER", bframe, "BOTTOM", 0, 0)
			bframecount:SetJustifyH"CENTER"
			bframecount:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
			bframecount:SetDrawLayer("OVERLAY", 7)
		end
	end

	-- DEBUFFS
	for i = 1, MAX_TARGET_DEBUFFS do
		local dframe = _G[self:GetName().."Debuff"..i]
		local dframecd = _G[self:GetName().."Debuff"..i.."Cooldown"]
		local dframecount = _G[self:GetName().."Debuff"..i.."Count"]
		if dframe then
			K.CreateBorder(dframe, 8)
			-- BORDER COLOUR
			local dname = UnitDebuff(self.unit, i)
			local _, _, _, _, dtype = UnitDebuff(self.unit, i)
			if dname then
				local colour = DebuffTypeColor[dtype] or DebuffTypeColor.none
				local auborder = _G[self:GetName().."Debuff"..i.."Border"]
				auborder:Hide()
				dframe:SetBackdropBorderColor(colour.r, colour.g, colour.b)
			else
				dframe:SetBackdropBorderColor(unpack(C.Media.Border_Color))
			end

			if dframecd then -- PET DOESN'T SHOW CD?
				dframecd:ClearAllPoints()
				dframecd:SetPoint("TOPLEFT", dframe, 1.5, -1.5)
				dframecd:SetPoint("BOTTOMRIGHT", dframe, -1.5, 1.5)
			end
			if dframecount then -- TOT DOESN'T SHOW STACKS
				dframecount:ClearAllPoints()
				dframecount:SetPoint("CENTER", dframe, "BOTTOM")
				dframecount:SetJustifyH("CENTER")
				dframecount:SetFont(C.Media.Font, C.Media.Font_Size, C.Media.Font_Style)
			end
		end
	end
end

-- REPOSITION
local function TargetAuraPosit(self, auraName, numAuras, numOppositeAuras, largeAuraList, updateFunc, maxRowWidth, offsetX, mirrorAurasVertically)
	local AURA_OFFSET_Y = C.Unitframe.AuraOffsetY
	local LARGE_AURA_SIZE = C.Unitframe.LargeAuraSize
	local SMALL_AURA_SIZE = C.Unitframe.SmallAuraSize
	local AURA_ROW_WIDTH = 100
	local NUM_TOT_AURA_ROWS = 2
	local size
	local offsetY = AURA_OFFSET_Y
	local rowWidth = 0
	local firstBuffOnRow = 1

	for i = 1, numAuras do
		if largeAuraList[i] then
			size = LARGE_AURA_SIZE
		else
			size = SMALL_AURA_SIZE
		end

		if i == 1 then
			rowWidth = size
			self.auraRows = self.auraRows + 1
		else
			rowWidth = rowWidth + size + offsetX
		end

		if rowWidth > maxRowWidth then
			-- X & Y
			updateFunc(self, auraName, i, numOppositeAuras, firstBuffOnRow, size, offsetX + 0.5, offsetY + 2, mirrorAurasVertically)

			rowWidth = size
			self.auraRows = self.auraRows + 1
			firstBuffOnRow = i
			offsetY = AURA_OFFSET_Y

			if self.auraRows > NUM_TOT_AURA_ROWS then maxRowWidth = AURA_ROW_WIDTH end
		else
			updateFunc(self, auraName, i, numOppositeAuras, i - 1, size, offsetX + 0.5, offsetY + 2, mirrorAurasVertically)
		end
	end
end

-- DEBUFF REPOSITION
local function TargetDebuffPosit(self, debuffName, index, numBuffs, anchorIndex, size, offsetX, offsetY, mirrorVertically)
	local dbuff = _G[debuffName..index]
	local isFriend = UnitIsFriend("player", self.unit)
	local AURA_START_X = 3
	local AURA_START_Y = 32
	local AURA_OFFSET_Y = C.Unitframe.AuraOffsetY

	-- FOR MIRRORING VERTICALLY
	local point, relativePoint
	local startY, auraOffsetY
	if mirrorVertically then
		point = "BOTTOM"
		relativePoint = "TOP"
		startY = -15
		if self.threatNumericIndicator:IsShown() then
			startY = startY + self.threatNumericIndicator:GetHeight()
		end
		offsetY = - offsetY
		auraOffsetY = -AURA_OFFSET_Y
	else
		point = "TOP"
		relativePoint= "BOTTOM"
		startY = AURA_START_Y
		auraOffsetY = AURA_OFFSET_Y
	end

	if index == 1 then
		if isFriend and numBuffs > 0 then
			-- UNIT IS FRIENDLY AND THERE ARE BUFFS...DEBUFFS START ON BOTTOM
			dbuff:SetPoint(point.."LEFT", self.buffs, relativePoint.."LEFT", 0, -offsetY)
		else
			-- UNIT IS NOT FRIENDLY OR THERE ARE NO BUFFS...DEBUFFS START ON TOP
			dbuff:SetPoint(point.."LEFT", self, relativePoint.."LEFT", AURA_START_X, startY - 3)
		end
		self.debuffs:SetPoint(point.."LEFT", dbuff, point.."LEFT", 0, 0)
		self.debuffs:SetPoint(relativePoint.."LEFT", dbuff, relativePoint.."LEFT", 0, -auraOffsetY)
		if isFriend or (not isFriend and numBuffs == 0) then
			self.spellbarAnchor = dbuff
		end
	elseif anchorIndex ~= (index - 1) then
		-- ANCHOR INDEX IS NOT THE PREVIOUS INDEX...MUST BE A NEW ROW
		dbuff:SetPoint(point.."LEFT", _G[debuffName..anchorIndex], relativePoint.."LEFT", 0, -offsetY)
		self.debuffs:SetPoint(relativePoint.."LEFT", dbuff, relativePoint.."LEFT", 0, -auraOffsetY)
		if isFriend or (not isFriend and numBuffs == 0) then
			self.spellbarAnchor = dbuff
		end
	else
		-- ANCHOR INDEX IS THE PREVIOUS INDEX
		dbuff:SetPoint(point.."LEFT", _G[debuffName..(index - 1)], point.."RIGHT", offsetX - 2, 0)
	end
end

-- TOT AURAS
for i = 1, 4 do
	local tot = _G["TargetFrameToTDebuff"..i]
	local totborder = _G["TargetFrameToTDebuff"..i.."Border"]
	local totparent = tot:GetParent()
	K.CreateBorder(tot, 8)

	totborder:Hide()

	-- REPOSITION
	tot:ClearAllPoints()
	if i == 1 then
		tot:SetPoint("LEFT", totparent, "RIGHT", 6, 9)
	elseif i == 2 then
		tot:SetPoint("LEFT", totparent, "RIGHT", 27, 9)
	elseif i == 3 then
		tot:SetPoint("LEFT", totparent, "RIGHT", 6, -11)
	elseif i == 4 then
		tot:SetPoint("LEFT", totparent, "RIGHT", 27, -11)
	end
end

-- PET AURAS
for i = 1, 4 do
	local petf = _G["PetFrameDebuff"..i]
	local petfborder = _G["PetFrameDebuff"..i.."Border"]
	K.CreateBorder(petf, 8)

	petfborder:Hide()

	-- REPOSITION
	petf:ClearAllPoints()
	if i == 1 then
		petf:SetPoint("TOPLEFT", PetFrame, 48, -45)
	else
		petf:SetPoint("LEFT", _G["PetFrameDebuff"..i - 1], "RIGHT", 9, 0)
	end
end

-- PARTY AURAS
for i = 1, 4 do
	local party = "PartyMemberFrame"..i
	_G[party]:HookScript("OnEvent", function(self, event, unit)
		if event == "UNIT_AURA" then
			if unit ~= "party"..i then return end
			for k = 1, 4 do
				local _, _, _, _, dtype = UnitDebuff(unit, k)
				local debuff = _G[party.."Debuff"..k]
				local border = _G[party.."Debuff"..k.."Border"]
				local colour = DebuffTypeColor[dtype] or DebuffTypeColor.none
				if not debuff.skinned then
					K.CreateBorder(debuff, 8)
					border:Hide()
				end
				debuff:SetBackdropBorderColor(colour.r, colour.g, colour.b)
				debuff:ClearAllPoints()
				if k == 1 then
					debuff:SetPoint("TOPLEFT", _G[party], 48, -34)
				else
					debuff:SetPoint("LEFT", _G[party.."Debuff"..k - 1], "RIGHT", 8, 0)
				end
			end
		end
	end)
end

hooksecurefunc("TargetofTarget_Update", TargetAuraColour)
hooksecurefunc("RefreshDebuffs", TargetAuraColour)
hooksecurefunc("PetFrame_Update", TargetAuraColour)
hooksecurefunc("TargetFrame_UpdateAuras", TargetAuraColour)
hooksecurefunc("TargetFrame_UpdateAuraPositions", TargetAuraPosit)
hooksecurefunc("TargetFrame_UpdateDebuffAnchor", TargetDebuffPosit)