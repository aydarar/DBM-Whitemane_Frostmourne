local mod	= DBM:NewMod("IngvarThePlunderer", "DBM-Party-WotLK", 10)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20261018212731")
mod:SetCreatureID(23980, 23954)
mod:SetEncounterID(575)
mod:SetUsedIcons(8)

mod:RegisterCombat("combat")
mod:RegisterKill("yell", L.YellCombatEnd)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 42723 42669 59706 59709 42708 42729 59708 59734",
	"SPELL_AURA_APPLIED 42730 59735",
	"SPELL_AURA_REMOVED 42730 59735",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_DIED",
	"UNIT_SPELLCAST_SUCCEEDED"
)

local warningWoeStrike	= mod:NewTargetNoFilterAnnounce(42730, 2, nil, "RemoveCurse", 2)

local specWarnSpelllock	= mod:NewSpecialWarningCast(42729, "SpellCaster", nil, 2, 1, 2)
local specWarnSmash		= mod:NewSpecialWarningDodge(42723, "Tank", nil, nil, 1, 2)

local timerSmash		= mod:NewCastTimer(3, 42723)
local timerSmashCD		= mod:NewCDTimer(13, 42723, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerWoeStrike	= mod:NewTargetTimer(10, 42723, nil, "RemoveCurse", nil, 5, nil, DBM_COMMON_L.CURSE_ICON)
-- Frostmourne logs (4 heroic pulls, 2026-10-07 to 10-15):
--   "My life for the... death god!" -> "I return!" 20.1-20.2s (Annhylde resurrects him)
--   phase 1 Staggering Roar 12.7-15.3 after the pull; phase 2 Dark Smash 5.0-5.1 after he returns, then 18.3-18.7;
--   Dreadful Roar 15.1-15.2 after he returns, then 17.8-19.0
local timerResurrect	= mod:NewTimer(20.1, "Ingvar returns", 42863, nil, nil, 6)
local timerDarkSmashCD	= mod:NewCDTimer(18, 59709, nil, nil, nil, 2)
local timerRoarCD		= mod:NewCDTimer(17.5, 59734, nil, nil, nil, 2)

mod:AddSetIconOption("WoeStrikeIcon", 42730, true, false, {8})

function mod:OnCombatStart()
	self:SetStage(1)
	timerSmashCD:Start(self:IsDifficulty("heroic5") and 2 or 15) -- Frostmourne logs (4 pulls): first Smash 2.1-3.7, then every 9.4-12.1
	if self:IsDifficulty("heroic5") then
		timerRoarCD:Start(12.5) -- Staggering Roar
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 59709 then -- Dark Smash (phase 2, heroic)
		specWarnSmash:Show()
		specWarnSmash:Play("shockwave")
		timerSmash:Start()
		timerDarkSmashCD:Start()
		return
	end
	if args:IsSpellID(59708, 59734) and self:IsDifficulty("heroic5") then -- Staggering / Dreadful Roar
		timerRoarCD:Start()
	end
	if args:IsSpellID(42723, 42669, 59706) then
		specWarnSmash:Show()
		specWarnSmash:Play("shockwave")
		timerSmash:Start()
		timerSmashCD:Start(self:IsDifficulty("heroic5") and 9.4 or nil)
	elseif args:IsSpellID(42708, 42729, 59708, 59734) then
		specWarnSpelllock:Show()
		specWarnSpelllock:Play("stopcast")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(42730, 59735) then
		warningWoeStrike:Show(args.destName)
		timerWoeStrike:Start(args.destName)
		if self.Options.WoeStrikeIcon then
			self:SetIcon(args.destName, 8, 10)
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(42730, 59735) then
		timerWoeStrike:Cancel()
		if self.Options.WoeStrikeIcon then
			self:SetIcon(args.destName, 0)
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 23954 then--Only trigger kill for unit_died if he dies in phase 2 with at least one player alive, otherwise it's an auto wipe.
		if DBM:NumRealAlivePlayers() > 0 and self.vb.phase == 2 then
			DBM:EndCombat(self)
		end
	end
end

local function StartPhase2Timers(self)
	if self.vb.p2Timers then return end
	self.vb.p2Timers = true
	timerResurrect:Stop()
	if self:IsDifficulty("heroic5") then
		timerDarkSmashCD:Start(5)
		timerRoarCD:Start(15)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg:find("death god", 1, true) then -- "My life for the... death god!" - he dies and gets resurrected
		self.vb.p2Timers = false
		timerSmashCD:Stop()
		timerRoarCD:Stop()
		timerResurrect:Start()
	elseif msg == L.YellIngvarPhase2 or msg:find(L.YellIngvarPhase2) then
		self:SetStage(2)
		StartPhase2Timers(self)
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if spellName == GetSpellInfo(42863) then -- Scourge Resurrection
		self:SetStage(2)
	end
end
