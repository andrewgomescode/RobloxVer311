local GachaSystem = {}
local CardDatabase = require(game.ReplicatedStorage.Modules.CardDatabase)


GachaSystem.StandardPack = {
	cost = 100,
	cardCount = 5,
	guaranteedRare = true -- At least 1 rare or better
}

-- Anti-exploit: Server-side random seed management
local playerSeeds = {}

function GachaSystem:InitializePlayerSeed(player)
	playerSeeds[player.UserId] = {
		seed = tick() * player.UserId,
		lastPull = 0,
		pullCount = 0
	}
end

function GachaSystem:GetWeightedRarity()
	local totalWeight = 0
	local weights = {}

	for rarity, data in pairs(CardDatabase.Rarities) do
		totalWeight = totalWeight + data.dropRate
		table.insert(weights, {rarity = rarity, weight = totalWeight})
	end

	local random = math.random() * totalWeight

	for _, weight in ipairs(weights) do
		if random <= weight.weight then
			return weight.rarity
		end
	end

	return "Common" -- Fallback
end

function GachaSystem:PullCard(player)
	-- Anti-exploit: Rate limiting
	local playerSeed = playerSeeds[player.UserId]
	if not playerSeed then
		self:InitializePlayerSeed(player)
		playerSeed = playerSeeds[player.UserId]
	end

	local currentTime = tick()
	if currentTime - playerSeed.lastPull < 0.1 then -- 0.1 second cooldown between cards
		return nil, "Pull rate limit exceeded"
	end

	playerSeed.lastPull = currentTime
	playerSeed.pullCount = playerSeed.pullCount + 1

	-- Determine rarity
	local rarity = self:GetWeightedRarity()

	-- Select random card from rarity pool
	local possibleCards = CardDatabase:GetCardsByRarity(rarity)
	if #possibleCards == 0 then
		return nil, "No cards available for rarity: " .. rarity
	end

	local selectedCard = possibleCards[math.random(1, #possibleCards)]
	return selectedCard, nil
end

-- MAIN METHOD: OpenPack - This is what the server calls
function GachaSystem:OpenPack(player)
	local pulledCards = {}
	local hasRareOrBetter = false

	for i = 1, self.StandardPack.cardCount do
		local card, error = self:PullCard(player)
		if card then
			table.insert(pulledCards, card)

			if card.rarity ~= "Common" then
				hasRareOrBetter = true
			end
		else
			warn("Failed to pull card:", error)
		end
		task.wait(0.11)
	end

	-- Guaranteed rare logic - if no rare or better was pulled, replace the last card
	if self.StandardPack.guaranteedRare and not hasRareOrBetter and #pulledCards == self.StandardPack.cardCount then
		-- Remove the last card
		table.remove(pulledCards, #pulledCards)

		-- Force pull a rare or better
		local rarities = {"Rare", "Epic", "Legendary"}
		local forcedRarity = rarities[math.random(1, math.min(2, #rarities))] -- Mostly Rare, sometimes Epic
		local rareCards = CardDatabase:GetCardsByRarity(forcedRarity)

		if #rareCards > 0 then
			local guaranteedCard = rareCards[math.random(1, #rareCards)]
			table.insert(pulledCards, guaranteedCard)
		else
			-- Fallback to any rare
			local allRares = CardDatabase:GetCardsByRarity("Rare")
			if #allRares > 0 then
				table.insert(pulledCards, allRares[math.random(1, #allRares)])
			end
		end
	end

	return pulledCards, nil
end

-- Legacy method name support (in case it's called elsewhere)
function GachaSystem:OpenBoosterPack(player, packType)
	-- Redirect to the new method
	return self:OpenPack(player)
end

-- Method to open multiple packs at once
function GachaSystem:OpenMultiplePacks(player, quantity)
	local allCards = {}

	for i = 1, quantity do
		local cards, error = self:OpenPack(player)
		if cards then
			for _, card in ipairs(cards) do
				table.insert(allCards, card)
			end
		else
			warn("Failed to open pack", i, ":", error)
		end

		-- Small delay between packs for anti-exploit
		if i < quantity then
			wait(0.1)
		end
	end

	return allCards
end

-- Get pack information
function GachaSystem:GetPackInfo()
	return self.StandardPack
end

-- Calculate pack price for multiple packs
function GachaSystem:CalculatePackCost(quantity)
	return self.StandardPack.cost * quantity
end

return GachaSystem
