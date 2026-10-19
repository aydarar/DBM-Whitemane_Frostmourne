local mod	= DBM:NewMod("Faerlina", "DBM-Naxx", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20261018212731")
mod:SetCreatureID(15953)
mod:SetEncounterID(1110)
mod:SetUsedIcons(8)

mod:RegisterCombat("combat_yell", L.Pull)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 28798 54100 28732 54097 28794 54099 9250586 9250587",
	"SPELL_CAST_SUCCESS 28796 54098 9250584 9250585 28794 54099 9250586 9250587",
	"CHAT_MSG_RAID_BOSS_EMOTE",	
	"UNIT_DIED"
)

local warnEmbraceActive		= mod:NewSpellAnnounce(28732, 1)
local warnEmbraceExpire		= mod:NewAnnounce("WarningEmbraceExpire", 2, 28732, nil, nil, nil, 28732)
local warnEmbraceExpired	= mod:NewFadesAnnounce(28732, 3)
local warnEnrageSoon		= mod:NewSoonAnnounce(28131, 3)
local warnEnrageNow			= mod:NewSpellAnnounce(28131, 4)

local specWarnEnrage		= mod:NewSpecialWarningDefensive(28131, nil, nil, nil, 3, 2)
local specWarnGTFO			= mod:NewSpecialWarningGTFO(28794, nil, nil, nil, 1, 8)

local timerEmbrace			= mod:NewBuffActiveTimer(30, 28732, nil, nil, nil, 6)
local timerEnrage			= mod:NewCDTimer(60, 28131, nil, nil, nil, 6)
local timerPoisonVolleyCD	= mod:NewCDTimer(14, 54098, nil, nil, nil, 5)
local timerRainOfFireCD		= mod:NewNextTimer(12, 54099, nil, nil, nil, 3) -- Frostmourne custom, log 2026-10-06: every 12.0-12.1

mod:AddTimerLine("RisenWorshipper")
mod:AddSetIconOption("RisenWorshipperIcons", 9250687, true, 5, {8})
local specWarnRisenWorshipper	= mod:NewSpecialWarningSwitch(9250687, "Kill Risen Worshipper!", nil, nil, 1, 2)

mod.vb.RisenWorshipperIcons = 8
mod.vb.enraged = false

local VOLLEY_CD = 14.05
local lastVolley
local frenzyAt

local function StartFrenzyTimer(sec)
	frenzyAt = GetTime() + sec
	timerEnrage:Stop()
	timerEnrage:Start(sec)
	warnEnrageSoon:Cancel()
	warnEnrageSoon:Schedule(sec - 5)
end

function mod:OnCombatStart(delay)
	lastVolley = nil
	StartFrenzyTimer(60 - delay)
	timerPoisonVolleyCD:Start(12.6-delay) -- REVIEW! variance? (25man Lordaeron 2022/10/16) - 12.6
	self.vb.RisenWorshipperIcons = 8
	self.vb.enraged = false
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(28798, 54100) then -- Frenzy
		self.vb.enraged = true
		StartFrenzyTimer(60) -- next Frenzy 60-80 later
		--if self:IsTanking("player", nil, nil, true, args.destGUID) then -- Whitemane PTR (boss1 doesn't work currently, changed to GUID-based)
		if self:IsTanking("player", "boss1", nil, true) then -- seems to be fixed now
			specWarnEnrage:Show()
			specWarnEnrage:Play("defensive")
		else
			warnEnrageNow:Show()
		end
	elseif args:IsSpellID(28732, 54097)	and args:GetDestCreatureID() == 15953 and self:AntiSpam(5, 2) then	-- Widow's Embrace
		self:Embrace()
	elseif args:IsSpellID(28794, 54099, 9250587, 9250586) and args:IsPlayer() then
		specWarnGTFO:Show(args.spellName)
		specWarnGTFO:Play("watchfeet")
	end
end

function mod:Embrace()
	local isFrenzied = self.vb.enraged
	warnEmbraceExpire:Cancel()
	warnEmbraceExpired:Cancel()
	warnEnrageSoon:Cancel()
	timerPoisonVolleyCD:Cancel()
	if lastVolley then -- next volley = first tick of her 14.05s rhythm after the 30s silence
		local now = GetTime()
		local n = math.ceil((now + 30 - lastVolley) / VOLLEY_CD)
		timerPoisonVolleyCD:Start(lastVolley + n * VOLLEY_CD - now)
	end
	if isFrenzied then
		StartFrenzyTimer(60)
	else
		local remaining = frenzyAt and (frenzyAt - GetTime()) or 0
		StartFrenzyTimer(math.max(30, remaining))
	end
	timerEmbrace:Start()
	warnEmbraceActive:Show()
	warnEmbraceExpire:Schedule(25)
	warnEmbraceExpired:Schedule(30)
	self.vb.enraged = false
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg and msg:find("Widow's Embrace", 1, true) and self:AntiSpam(5, 2) then
		self:Embrace()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(28796, 54098, 9250584, 9250585) then -- Poison Bolt Volley
		lastVolley = GetTime()
		timerPoisonVolleyCD:Start()
	elseif args:IsSpellID(28794, 54099, 9250587, 9250586) then -- Rain of Fire (Frostmourne custom)
		timerRainOfFireCD:Start()
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 15953 then
		warnEnrageSoon:Cancel()
		warnEmbraceExpire:Cancel()
		warnEmbraceExpired:Cancel()
		timerPoisonVolleyCD:Cancel()
	elseif cid == 16506 then
		DBM:Schedule(3.5,function()
			self:ScanForMobs(900126, 2, self.vb.RisenWorshipperIcons, 1, nil, 5, "RisenWorshipperIcons")				
			specWarnRisenWorshipper:Show()
			specWarnRisenWorshipper:Play("killmob")	
		end
				)	
	end
end

