local InventoryManager = {}
local CardDatabase = require(game.ReplicatedStorage.Modules.CardDatabase)

InventoryManager.MaxInventorySize = 500


function InventoryManager:CreateNewInventory()
	return {
		cards = {},
		packs = 5,  -- Start with 5 packs (simplified from boosterPacks)
		currency = 1000,  -- Starting currency
		version = "1.0.0"
	}
end

function InventoryManager:AddCard(inventory, cardId)
	if not inventory.cards[cardId] then
		inventory.cards[cardId] = 0
	end


	local totalCards = 0
	for _, count in pairs(inventory.cards) do
		totalCards = totalCards + count
	end

	if totalCards >= self.MaxInventorySize then
		return false, "Inventory full"
	end

	inventory.cards[cardId] = inventory.cards[cardId] + 1
	return true, "Card added successfully"
end

function InventoryManager:RemoveCard(inventory, cardId, count)
	count = count or 1

	if not inventory.cards[cardId] or inventory.cards[cardId] < count then
		return false, "Insufficient cards"
	end

	inventory.cards[cardId] = inventory.cards[cardId] - count

	if inventory.cards[cardId] == 0 then
		inventory.cards[cardId] = nil
	end

	return true, "Card removed successfully"
end

function InventoryManager:GetSortedCards(inventory, sortBy)
	local cardList = {}

	for cardId, count in pairs(inventory.cards) do
		local card = CardDatabase:GetCardById(cardId)
		if card then
			table.insert(cardList, {
				card = card,
				count = count,
				power = CardDatabase:CalculateCardPower(card)
			})
		end
	end

	-- Sort based on criteria
	if sortBy == "rarity" then
		table.sort(cardList, function(a, b)
			local rarityOrder = {Common = 1, Rare = 2, Epic = 3, Legendary = 4}
			return rarityOrder[a.card.rarity] > rarityOrder[b.card.rarity]
		end)
	elseif sortBy == "power" then
		table.sort(cardList, function(a, b)
			return a.power > b.power
		end)
	elseif sortBy == "position" then
		table.sort(cardList, function(a, b)
			return a.card.position < b.card.position
		end)
	end

	return cardList
end

-- Migration function for old data format
function InventoryManager:MigrateOldFormat(inventory)
	-- Convert old boosterPacks format to new packs format
	if inventory.boosterPacks and not inventory.packs then
		local totalPacks = 0
		for packType, count in pairs(inventory.boosterPacks) do
			totalPacks = totalPacks + count
		end
		inventory.packs = totalPacks
		inventory.boosterPacks = nil
	end

	-- Ensure packs field exists
	if not inventory.packs then
		inventory.packs = 0
	end

	return inventory
end

return InventoryManager