-- DBM-Distance2Boss: a second range radar next to DBM's own one, with an estimated boss marker (second radar only).
--   /d2b x y         changing distance to boss to x, changing unitid to y (etc boss1,target)
--   /d2b            hide it (or show it with 10 yards distance if it is hidden)

-- Boss mods can use it too:  if DBM.Distance2Boss then DBM.Distance2Boss:Show(12) end  /  DBM.Distance2Boss:Hide()

local DBM = DBM
if not DBM then return end

local d2b = {}
DBM.Distance2Boss = d2b

local frame
local activeRange = 10
local activeUnit = "boss1"
local userShown = false -- true when the player opened it with /Distance2Boss (a boss mod's Hide() then leaves it open)
local elapsedSince = 0

local function saveDB()
	DBMDistance2BossDB = DBMDistance2BossDB or {}
	return DBMDistance2BossDB
end

------------------------
--  Create the frame  --
------------------------
local function createFrame()
	local db = saveDB()
	frame = CreateFrame("Frame", "DBMDistance2Boss", UIParent)
	frame:SetFrameStrata("DIALOG")
	frame:SetPoint(db.point or "CENTER", UIParent, db.point or "CENTER", db.x or 0, db.y or 0)
	frame:SetSize(128, 12)
	frame:SetClampedToScreen(true)
	frame:EnableMouse(true)
	frame:SetToplevel(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self)
		self:StartMoving()
	end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, _, x, y = self:GetPoint(1)
		local sv = saveDB()
		sv.point, sv.x, sv.y = point, x, y
	end)

	local inRangeText = frame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
	inRangeText:SetSize(128, 15)
	inRangeText:SetPoint("TOPLEFT", frame, "BOTTOMLEFT")
	inRangeText:SetTextColor(1, 1, 1, 1)
	inRangeText:Hide()
	frame.inRangeText = inRangeText

	frame:Hide()
end
			
local function CheckRange(d,u1)
	local RangeCheckItems  = {
		{r=5,s=37727}, --5
		{r=8,s=34368}, --8
		{r=10,s=32321}, --10
		{r=15,s=33069}, --15
		{r=20,s=10645}, --20
		{r=25,s=24268}, --25
		{r=30,s=835}, --30
		{r=35,s=24269}, --35
		{r=40,s=28767}, --40
		{r=45,s=32698}, --45
		{r=60,s=32825}, --60
		{r=80,s=35278},                        
	}    
	local function CheckIsItemInRange(u)
		local r,prev_r ="","0"
		for k,v in pairs (RangeCheckItems) do
			if IsItemInRange(v.s,u) == 1 then
				r = "["..prev_r.."-"..v.r.."]"
				break
			end
			prev_r=v.r
		end    
		return r
	end
	
	local rangeItem = 10645
	for k,v in pairs (RangeCheckItems) do
		if v.r == d then
			rangeItem=v.s
			break
		end
	end               
	
	local u = "boss1"
	if u1 then u = u1 end
	return IsItemInRange(rangeItem,u),CheckIsItemInRange(u)          
end



local function update()
	if d2b:IsShown() then
		-- Green Text (Regular range frame and not near too many players, or reverse range frame and we ARE near enough)
		local x,y = CheckRange(activeRange,activeUnit)
		if not y then y = "" end
		local msg = ""
		if x and x == 0 then
			frame.inRangeText:SetTextColor(0, 1, 0)
			msg="Safe now "..y      
		else
			frame.inRangeText:SetTextColor(1, 0, 0)
			msg="Run out! "..y
		end
		frame.inRangeText:SetText(msg)
		frame.inRangeText:Show()
		frame:Show()
	end
end

local function onUpdate(self, elapsed)
	elapsedSince = elapsedSince + elapsed
	if elapsedSince < 0.1 then return end
	elapsedSince = 0
	update()
end

-- Show(range, byUser): byUser is set by /Distance2Boss only
function d2b:Show(range, byUser, u)
	range = tonumber(range) or 10
	if not frame then
		createFrame()
	end
	activeRange = range
	activeUnit = u
	if byUser then
		userShown = true
	end
	frame:SetScript("OnUpdate", onUpdate)
	frame:Show()
	update()
end

-- Hide(force): a boss mod's plain Hide() leaves a radar the player opened with /distance2boss alone
function d2b:Hide(force)
	if not frame then return end
	if userShown and not force then return end
	userShown = false
	frame:SetScript("OnUpdate", nil)
	frame:Hide()
end

function d2b:IsShown()
	return frame and frame:IsShown() or false
end

function d2b:GetRange()
	return activeRange
end

SLASH_DISTANCETOBOSS1 = "/d2b"
SLASH_DISTANCETOBOSS2 = "/distance2boss"
SlashCmdList["DISTANCETOBOSS"] = function(msg)
	msg = (msg or ""):lower()
	local args = {}
	if msg ~= "" then
		for i, v in ipairs(string.match(msg, "(%w+)") ) do
			args[i]=v
		end
	end
	if d2b:IsShown() then
		d2b:Hide(true)
	else
		d2b:Show(r, true,args[2])
	end
end
