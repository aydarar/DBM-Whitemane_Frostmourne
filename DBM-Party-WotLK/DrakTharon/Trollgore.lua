local mod	= DBM:NewMod("Trollgore", "DBM-Party-WotLK", 4)
local L		= mod:GetLocalizedStrings()

mod.statTypes = "normal,heroic,mythic"

mod:SetRevision("20261018212731")
mod:SetCreatureID(26630)
mod:SetEncounterID(369)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 49555 59807",
	"SPELL_CAST_SUCCESS 59803",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"CHAT_MSG_MONSTER_YELL"
)

local warnConsume		= mod:NewSpellAnnounce(59803,1)

local timerExplosionCD	= mod:NewCDTimer(16, 49555)
local timerNextConsume	= mod:NewNextTimer(15, 59803)

function mod:OnCombatStart()
	-- heroic: Corpse Explode is 59807 and "Corpse go boom!" is a yell; Frostmourne logs 2026-10-11 and 10-15: first one at 35.0 both times
	timerExplosionCD:Start(self:IsDifficulty("heroic5") and 35 or 3)
	timerNextConsume:Start()
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(49555, 59807) and self:AntiSpam(3, "Explosion") then
		timerExplosionCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 59803 and self:AntiSpam(1) then
		warnConsume:Show()
		timerNextConsume:Start()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if (msg == L.YellExplosion or msg:find(L.YellExplosion)) and self:AntiSpam(3, "Explosion") then
		timerExplosionCD:Start()
	end
end
mod.CHAT_MSG_MONSTER_YELL = mod.CHAT_MSG_RAID_BOSS_EMOTE
