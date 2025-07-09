local VersusSystem = {}
local CardDatabase = require(game.ReplicatedStorage.Modules.CardDatabase)

VersusSystem.TeamSize = 11
VersusSystem.Formations = {
	["4-4-2"] = {GK = 1, DEF = 4, MID = 4, ATT = 2},
	["4-3-3"] = {GK = 1, DEF = 4, MID = 3, ATT = 3},
	["3-5-2"] = {GK = 1, DEF = 3, MID = 5, ATT = 2}
}

function VersusSystem:ValidateTeam(team, formation)
	local formationReq = self.Formations[formation]
	if not formationReq then
		return false, "Invalid formation"
	end

	local positionCount = {GK = 0, DEF = 0, MID = 0, ATT = 0}

	for _, cardId in ipairs(team) do
		local card = CardDatabase:GetCardById(cardId)
		if not card then
			return false, "Invalid card in team"
		end
		positionCount[card.position] = positionCount[card.position] + 1
	end

	-- Check if team matches formation requirements
	for position, required in pairs(formationReq) do
		if positionCount[position] ~= required then
			return false, "Team doesn't match formation requirements"
		end
	end

	return true, "Team valid"
end

function VersusSystem:CalculateTeamPower(team)
	local totalPower = 0
	local positionBonus = 1.0

	for _, cardId in ipairs(team) do
		local card = CardDatabase:GetCardById(cardId)
		if card then
			local cardPower = CardDatabase:CalculateCardPower(card)
			totalPower = totalPower + cardPower
		end
	end

	-- Future: Add chemistry bonuses, position bonuses, etc.
	return math.floor(totalPower * positionBonus)
end

function VersusSystem:SimulateMatch(team1Power, team2Power)
	-- Basic simulation with some randomness
	local powerDiff = team1Power - team2Power
	local winChance = 0.5 + (powerDiff / (team1Power + team2Power))

	-- Clamp win chance between 20% and 80%
	winChance = math.max(0.2, math.min(0.8, winChance))

	local result = {
		winner = nil,
		score = {team1 = 0, team2 = 0},
		powerDifference = powerDiff
	}

	-- Simulate match
	if math.random() < winChance then
		result.winner = 1
		result.score.team1 = math.random(1, 3)
		result.score.team2 = math.max(0, result.score.team1 - math.random(1, 2))
	else
		result.winner = 2
		result.score.team2 = math.random(1, 3)
		result.score.team1 = math.max(0, result.score.team2 - math.random(1, 2))
	end

	return result
end

return VersusSystem