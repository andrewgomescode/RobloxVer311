local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Data stores
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v1")
local LeaderboardStore = DataStoreService:GetOrderedDataStore("Leaderboard_v1")

-- Modules
local CardDatabase = require(ReplicatedStorage.Modules.CardDatabase)
local GachaSystem = require(ReplicatedStorage.Modules.GachaSystem)
local InventoryManager = require(ReplicatedStorage.Modules.InventoryManager)
local VersusSystem = require(ReplicatedStorage.Modules.VersusSystem)
local VersionManager = require(ReplicatedStorage.Modules.VersionManager)

-- Remote Events/Functions
local RemoteEvents = ReplicatedStorage.RemoteEvents
local RemoteFunctions = ReplicatedStorage.RemoteFunctions

-- Player data cache
local playerDataCache = {}

-- Anti-exploit: Request tracking
local requestTracking = {}

local ADMIN_USERS = {"litoliu"} -- Add your username here

local function isAdmin(player)
	for _, adminName in ipairs(ADMIN_USERS) do
		if player.Name == adminName then
			return true
		end
	end
	return false
end


local function trackRequest(player, requestType)
	local userId = player.UserId
	if not requestTracking[userId] then
		requestTracking[userId] = {}
	end

	if not requestTracking[userId][requestType] then
		requestTracking[userId][requestType] = {
			count = 0,
			resetTime = tick() + 60  -- Reset every minute
		}
	end

	local tracker = requestTracking[userId][requestType]

	if tick() > tracker.resetTime then
		tracker.count = 0
		tracker.resetTime = tick() + 60
	end

	tracker.count = tracker.count + 1

	-- Rate limits
	local limits = {
		OpenBoosterPack = 20,
		PurchaseBoosterPack = 30,
		StartMatch = 10
	}

	if tracker.count > (limits[requestType] or 50) then
		return false
	end

	return true
end

-- Load player data with migration support
local function loadPlayerData(player)
	local success, data = pcall(function()
		return PlayerDataStore:GetAsync("Player_" .. player.UserId)
	end)

	if success and data then
		-- Migrate old boosterPacks format to new packs format
		data = InventoryManager:MigrateOldFormat(data)

		-- Migrate data if needed
		local migratedData, error = VersionManager:MigrateData(data)
		if migratedData then
			return migratedData
		else
			warn("Migration failed for player " .. player.Name .. ": " .. error)
		end
	end

	-- Return new inventory if no data or migration failed
	return InventoryManager:CreateNewInventory()
end

-- Save player data
local function savePlayerData(player)
	local data = playerDataCache[player.UserId]
	if not data then return end

	local success, error = pcall(function()
		PlayerDataStore:SetAsync("Player_" .. player.UserId, data)
	end)

	if not success then
		warn("Failed to save data for " .. player.Name .. ": " .. error)
	end
end


Players.PlayerAdded:Connect(function(player)
	-- Initialize systems
	GachaSystem:InitializePlayerSeed(player)

	-- Load player data
	playerDataCache[player.UserId] = loadPlayerData(player)

	-- MIGRATION CHECK - Add this section
	local inventory = playerDataCache[player.UserId]
	if inventory then
		-- Ensure all required fields exist
		if not inventory.cards then
			inventory.cards = {}
		end
		if not inventory.packs then
			inventory.packs = 0
		end
		if not inventory.currency then
			inventory.currency = 1000
		end

		-- Migrate old boosterPacks to new packs format
		if inventory.boosterPacks then
			local totalPacks = 0
			for packType, count in pairs(inventory.boosterPacks) do
				totalPacks = totalPacks + count
			end
			inventory.packs = inventory.packs + totalPacks
			inventory.boosterPacks = nil -- Remove old format
		end
	end

	-- Create leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local currency = Instance.new("IntValue")
	currency.Name = "Currency"
	currency.Value = inventory.currency or 1000
	currency.Parent = leaderstats

	local cardCount = Instance.new("IntValue")
	cardCount.Name = "Cards"
	local count = 0
	if inventory.cards then
		for _, c in pairs(inventory.cards) do
			count = count + c
		end
	end
	cardCount.Value = count
	cardCount.Parent = leaderstats
end)

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if not isAdmin(player) then return end

		local args = string.split(message, " ")
		local command = args[1]:lower()

		if command == "/currency" or command == "/money" then
			local amount = tonumber(args[2])
			if amount then
				local inventory = playerDataCache[player.UserId]
				if inventory then
					inventory.currency = inventory.currency + amount
					player.leaderstats.Currency.Value = inventory.currency

					-- Notify player
					RemoteEvents.UpdateInventory:FireClient(player, inventory, "Added $" .. amount .. " to your account")
					print("Added " .. amount .. " currency to " .. player.Name)
				end
			else
				print("Usage: /currency [amount]")
			end

		elseif command == "/pack" then
			local packType = args[2]
			local amount = tonumber(args[3]) or 1

			local inventory = playerDataCache[player.UserId]
			if inventory and GachaSystem.BoosterPacks[packType] then
				inventory.boosterPacks[packType] = (inventory.boosterPacks[packType] or 0) + amount

				-- Notify player
				RemoteEvents.UpdateInventory:FireClient(player, inventory, "Added " .. amount .. " " .. packType .. " pack(s)")
				print("Added " .. amount .. " " .. packType .. " pack(s) to " .. player.Name)
			else
				print("Usage: /pack [Basic/Premium/Ultimate] [amount]")
			end

		elseif command == "/card" then
			local cardId = args[2]
			local amount = tonumber(args[3]) or 1

			local inventory = playerDataCache[player.UserId]
			if inventory and CardDatabase:GetCardById(cardId) then
				for i = 1, amount do
					InventoryManager:AddCard(inventory, cardId)
				end

				-- Update card count
				local count = 0
				for _, c in pairs(inventory.cards) do
					count = count + c
				end
				player.leaderstats.Cards.Value = count

				-- Notify player
				RemoteEvents.UpdateInventory:FireClient(player, inventory, "Added " .. amount .. " " .. cardId .. " card(s)")
				print("Added " .. amount .. " " .. cardId .. " card(s) to " .. player.Name)
			else
				print("Usage: /card [cardId] [amount]")
				print("Valid IDs: C001-C004, R001-R002, E001-E002, L001-L002")
			end

		elseif command == "/reset" then
			playerDataCache[player.UserId] = InventoryManager:CreateNewInventory()
			player.leaderstats.Currency.Value = 1000
			player.leaderstats.Cards.Value = 0

			RemoteEvents.UpdateInventory:FireClient(player, playerDataCache[player.UserId], "Inventory reset")
			print("Reset inventory for " .. player.Name)

		elseif command == "/help" then
			print("=== ADMIN COMMANDS ===")
			print("/currency [amount] - Add currency")
			print("/pack [Basic/Premium/Ultimate] [amount] - Add packs")
			print("/card [cardId] [amount] - Add specific cards")
			print("/reset - Reset inventory to default")
			print("/help - Show this help")
			print("====================")
		end
	end)
end)


-- Player leaving
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
	playerDataCache[player.UserId] = nil
	requestTracking[player.UserId] = nil
end)

-- Auto-save
spawn(function()
	while true do
		wait(60) -- Save every minute
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
	end
end)

-- Remote Functions
RemoteFunctions.GetPlayerData.OnServerInvoke = function(player)
	return playerDataCache[player.UserId]
end

RemoteFunctions.GetCardCollection.OnServerInvoke = function(player)
	local inventory = playerDataCache[player.UserId]
	if inventory then
		return InventoryManager:GetSortedCards(inventory, "rarity")
	end
	return {}
end

-- Remote Events (Updated for new pack system)
RemoteEvents.PurchaseBoosterPack.OnServerEvent:Connect(function(player, quantity)
	if not trackRequest(player, "PurchaseBoosterPack") then
		return
	end

	-- Validate quantity
	quantity = tonumber(quantity) or 1
	quantity = math.max(1, math.min(quantity, 10)) -- Limit 1-10 packs per purchase

	local inventory = playerDataCache[player.UserId]
	if not inventory then return end

	local totalCost = GachaSystem.StandardPack.cost * quantity

	if inventory.currency < totalCost then
		RemoteEvents.UpdateInventory:FireClient(player, inventory, "Insufficient currency")
		return
	end

	-- Deduct currency and add packs
	inventory.currency = inventory.currency - totalCost
	inventory.packs = (inventory.packs or 0) + quantity

	-- Update leaderstats
	player.leaderstats.Currency.Value = inventory.currency

	RemoteEvents.UpdateInventory:FireClient(player, inventory, quantity .. " pack(s) purchased!")
end)

RemoteEvents.OpenBoosterPack.OnServerEvent:Connect(function(player, quantity)
	if not trackRequest(player, "OpenBoosterPack") then
		return
	end

	-- Validate quantity
	quantity = tonumber(quantity) or 1
	quantity = math.max(1, math.min(quantity, 5)) -- Limit 1-5 packs per opening

	local inventory = playerDataCache[player.UserId]
	if not inventory then return end

	-- Check if player has enough packs (NEW FORMAT)
	local packsOwned = inventory.packs or 0
	if packsOwned < quantity then
		RemoteEvents.UpdateInventory:FireClient(player, inventory, "Not enough packs")
		return
	end

	-- Open packs using the new simplified gacha system
	local allCards = {}
	for i = 1, quantity do
		local cards, error = GachaSystem:OpenBoosterPack(player)
		if cards then
			for _, card in ipairs(cards) do
				table.insert(allCards, card)
			end
		end
	end

	if #allCards == 0 then
		RemoteEvents.UpdateInventory:FireClient(player, inventory, "Failed to open pack")
		return
	end

	-- Deduct packs
	inventory.packs = inventory.packs - quantity

	-- Add cards to inventory
	local addedCards = {}
	for _, card in ipairs(allCards) do
		local success, msg = InventoryManager:AddCard(inventory, card.id)
		if success then
			table.insert(addedCards, card)
		end
	end

	-- Update card count
	local count = 0
	for _, c in pairs(inventory.cards or {}) do
		count = count + c
	end
	player.leaderstats.Cards.Value = count

	RemoteEvents.UpdateInventory:FireClient(player, inventory, "Pack opened!", addedCards)
end)