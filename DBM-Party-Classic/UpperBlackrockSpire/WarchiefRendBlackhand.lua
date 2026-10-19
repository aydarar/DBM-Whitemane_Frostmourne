local mod	= DBM:NewMod("WarchiefRendBlackhand", "DBM-Party-Classic", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20261018212731")
mod:SetCreatureID(10339, 10429) -- Gyth, Rend
mod:SetMainBossID(10429)
mod:SetEncounterID(278)

mod:RegisterCombat("combat")
