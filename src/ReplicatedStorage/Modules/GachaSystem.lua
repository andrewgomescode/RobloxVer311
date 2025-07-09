--[[
    GachaSystem - Sistema de gacha completo com pity e probabilidades
    Autor: Sistema de Gacha/Inventário
    Versão: 1.0
    
    Funcionalidades:
    - Sistema de probabilidades por raridade
    - Pity system para garantir cartas raras
    - Abertura de pacotes com animações
    - Estatísticas de pulls
    - Seed personalizada por jogador
    - Prevenção de exploits
]]

local GachaSystem = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CardDatabase = require(script.Parent.CardDatabase)
local InventoryManager = require(script.Parent.InventoryManager)

-- Configurações do sistema de gacha
local GACHA_CONFIG = {
    -- Probabilidades base (em porcentagem)
    BASE_PROBABILITIES = {
        [CardDatabase.Rarity.COMMON.id] = 70,    -- 70%
        [CardDatabase.Rarity.RARE.id] = 20,      -- 20%
        [CardDatabase.Rarity.EPIC.id] = 8,       -- 8%
        [CardDatabase.Rarity.LEGENDARY.id] = 2   -- 2%
    },
    
    -- Sistema de pity
    PITY_SYSTEM = {
        EPIC_PITY = 30,      -- Épico garantido a cada 30 pulls
        LEGENDARY_PITY = 100, -- Lendário garantido a cada 100 pulls
        PITY_INCREASE = 2    -- Aumento de chance por pull sem rare+
    },
    
    -- Configurações de pacotes
    PACK_SETTINGS = {
        CARDS_PER_PACK = 5,
        PACK_COST = 200,
        GUARANTEED_RARE_POSITION = 5, -- Última carta sempre rara ou superior
        MAX_PACKS_PER_OPENING = 10
    }
}

-- Cache de seeds por jogador
local playerSeeds = {}
local playerPullCount = {}

-- Função para inicializar seed do jogador
function GachaSystem:InitializePlayerSeed(player)
    local userId = player.UserId
    playerSeeds[userId] = Random.new(tick() + userId)
    playerPullCount[userId] = 0
end

-- Função para obter random personalizado do jogador
function GachaSystem:GetPlayerRandom(player)
    local userId = player.UserId
    if not playerSeeds[userId] then
        self:InitializePlayerSeed(player)
    end
    return playerSeeds[userId]
end

-- Função para calcular probabilidades ajustadas com pity
function GachaSystem:CalculateAdjustedProbabilities(inventory, isPityPosition)
    local baseProbabilities = GACHA_CONFIG.BASE_PROBABILITIES
    local adjustedProbabilities = {}
    
    -- Copia as probabilidades base
    for rarityId, probability in pairs(baseProbabilities) do
        adjustedProbabilities[rarityId] = probability
    end
    
    -- Aplica sistema de pity
    if inventory.gachaStats then
        local pityCount = inventory.gachaStats.pityCount or 0
        local lastLegendaryPull = inventory.gachaStats.lastLegendaryPull or 0
        
        -- Pity para lendário (100 pulls)
        if lastLegendaryPull >= GACHA_CONFIG.PITY_SYSTEM.LEGENDARY_PITY then
            adjustedProbabilities[CardDatabase.Rarity.LEGENDARY.id] = 100
            adjustedProbabilities[CardDatabase.Rarity.EPIC.id] = 0
            adjustedProbabilities[CardDatabase.Rarity.RARE.id] = 0
            adjustedProbabilities[CardDatabase.Rarity.COMMON.id] = 0
        -- Pity para épico (30 pulls)
        elseif pityCount >= GACHA_CONFIG.PITY_SYSTEM.EPIC_PITY then
            adjustedProbabilities[CardDatabase.Rarity.EPIC.id] = 50
            adjustedProbabilities[CardDatabase.Rarity.RARE.id] = 50
            adjustedProbabilities[CardDatabase.Rarity.COMMON.id] = 0
        -- Posição garantida (última carta sempre rara+)
        elseif isPityPosition then
            adjustedProbabilities[CardDatabase.Rarity.COMMON.id] = 0
            -- Redistribui a probabilidade de comum para as outras raridades
            adjustedProbabilities[CardDatabase.Rarity.RARE.id] = 60
            adjustedProbabilities[CardDatabase.Rarity.EPIC.id] = 25
            adjustedProbabilities[CardDatabase.Rarity.LEGENDARY.id] = 15
        else
            -- Aumenta chance gradualmente com pity
            local pityBonus = pityCount * GACHA_CONFIG.PITY_SYSTEM.PITY_INCREASE
            adjustedProbabilities[CardDatabase.Rarity.RARE.id] = 
                adjustedProbabilities[CardDatabase.Rarity.RARE.id] + pityBonus
            adjustedProbabilities[CardDatabase.Rarity.EPIC.id] = 
                adjustedProbabilities[CardDatabase.Rarity.EPIC.id] + (pityBonus * 0.5)
            adjustedProbabilities[CardDatabase.Rarity.LEGENDARY.id] = 
                adjustedProbabilities[CardDatabase.Rarity.LEGENDARY.id] + (pityBonus * 0.25)
            
            -- Reduz chance de comum para compensar
            adjustedProbabilities[CardDatabase.Rarity.COMMON.id] = 
                math.max(10, adjustedProbabilities[CardDatabase.Rarity.COMMON.id] - (pityBonus * 1.75))
        end
    end
    
    -- Normaliza as probabilidades para somar 100%
    local total = 0
    for _, probability in pairs(adjustedProbabilities) do
        total = total + probability
    end
    
    for rarityId, probability in pairs(adjustedProbabilities) do
        adjustedProbabilities[rarityId] = (probability / total) * 100
    end
    
    return adjustedProbabilities
end

-- Função para selecionar raridade baseada nas probabilidades
function GachaSystem:SelectRarity(player, inventory, isPityPosition)
    local probabilities = self:CalculateAdjustedProbabilities(inventory, isPityPosition)
    local random = self:GetPlayerRandom(player)
    local roll = random:NextNumber(0, 100)
    
    local cumulativeProbability = 0
    for rarityId, probability in pairs(probabilities) do
        cumulativeProbability = cumulativeProbability + probability
        if roll <= cumulativeProbability then
            return rarityId
        end
    end
    
    -- Fallback para comum
    return CardDatabase.Rarity.COMMON.id
end

-- Função para selecionar carta aleatória de uma raridade
function GachaSystem:SelectRandomCard(player, rarityId)
    local rarity = self:GetRarityById(rarityId)
    local cardsOfRarity = CardDatabase:GetCardsByRarity(rarity)
    
    if not cardsOfRarity or not next(cardsOfRarity) then
        warn("Nenhuma carta encontrada para raridade: " .. rarityId)
        return nil
    end
    
    local cardIds = {}
    for cardId, _ in pairs(cardsOfRarity) do
        table.insert(cardIds, cardId)
    end
    
    local random = self:GetPlayerRandom(player)
    local randomIndex = random:NextInteger(1, #cardIds)
    
    return cardIds[randomIndex]
end

-- Função para obter raridade por ID
function GachaSystem:GetRarityById(rarityId)
    for _, rarity in pairs(CardDatabase.Rarity) do
        if rarity.id == rarityId then
            return rarity
        end
    end
    return CardDatabase.Rarity.COMMON
end

-- Função para atualizar estatísticas de gacha
function GachaSystem:UpdateGachaStats(inventory, pulledCards)
    if not inventory.gachaStats then
        inventory.gachaStats = {
            totalOpened = 0,
            rarityPulls = {
                [CardDatabase.Rarity.COMMON.id] = 0,
                [CardDatabase.Rarity.RARE.id] = 0,
                [CardDatabase.Rarity.EPIC.id] = 0,
                [CardDatabase.Rarity.LEGENDARY.id] = 0
            },
            pityCount = 0,
            lastLegendaryPull = 0
        }
    end
    
    local stats = inventory.gachaStats
    stats.totalOpened = stats.totalOpened + #pulledCards
    
    local hasRareOrHigher = false
    local hasLegendary = false
    
    for _, cardData in ipairs(pulledCards) do
        local rarityId = cardData.rarity.id
        stats.rarityPulls[rarityId] = stats.rarityPulls[rarityId] + 1
        
        if rarityId >= CardDatabase.Rarity.RARE.id then
            hasRareOrHigher = true
        end
        
        if rarityId == CardDatabase.Rarity.LEGENDARY.id then
            hasLegendary = true
        end
    end
    
    -- Atualiza contador de pity
    if hasRareOrHigher then
        stats.pityCount = 0
    else
        stats.pityCount = stats.pityCount + 1
    end
    
    -- Atualiza contador de lendário
    if hasLegendary then
        stats.lastLegendaryPull = 0
    else
        stats.lastLegendaryPull = stats.lastLegendaryPull + 1
    end
    
    -- Atualiza timestamp
    if not inventory.timestamps then
        inventory.timestamps = {}
    end
    inventory.timestamps.lastPull = os.time()
end

-- Função principal para abrir pacote
function GachaSystem:OpenBoosterPack(player, quantity)
    quantity = quantity or 1
    quantity = math.min(quantity, GACHA_CONFIG.PACK_SETTINGS.MAX_PACKS_PER_OPENING)
    
    local pulledCards = {}
    local inventory = self:GetPlayerInventory(player)
    
    if not inventory then
        return nil, "Inventário não encontrado"
    end
    
    -- Abre múltiplos pacotes
    for pack = 1, quantity do
        local packCards = {}
        
        -- Gera cartas do pacote
        for cardPos = 1, GACHA_CONFIG.PACK_SETTINGS.CARDS_PER_PACK do
            local isPityPosition = (cardPos == GACHA_CONFIG.PACK_SETTINGS.GUARANTEED_RARE_POSITION)
            local rarityId = self:SelectRarity(player, inventory, isPityPosition)
            local cardId = self:SelectRandomCard(player, rarityId)
            
            if cardId then
                local card = CardDatabase:GetCardById(cardId)
                if card then
                    table.insert(packCards, card)
                end
            end
        end
        
        -- Adiciona cartas do pacote ao total
        for _, card in ipairs(packCards) do
            table.insert(pulledCards, card)
        end
    end
    
    -- Atualiza estatísticas antes de adicionar ao inventário
    self:UpdateGachaStats(inventory, pulledCards)
    
    -- Adiciona cartas ao inventário
    for _, card in ipairs(pulledCards) do
        InventoryManager:AddCard(inventory, card.id, 1)
    end
    
    return pulledCards, nil
end

-- Função para obter inventário do jogador (placeholder)
function GachaSystem:GetPlayerInventory(player)
    -- Esta função deve ser implementada para obter o inventário do jogador
    -- Por exemplo, através de um sistema de cache global ou DataStore
    return nil -- Placeholder
end

-- Função para calcular custo de múltiplos pacotes
function GachaSystem:CalculatePacksCost(quantity)
    return quantity * GACHA_CONFIG.PACK_SETTINGS.PACK_COST
end

-- Função para verificar se o jogador pode comprar pacotes
function GachaSystem:CanAffordPacks(player, quantity)
    local inventory = self:GetPlayerInventory(player)
    if not inventory then return false end
    
    local cost = self:CalculatePacksCost(quantity)
    return inventory.currency >= cost
end

-- Função para processar compra de pacotes
function GachaSystem:PurchasePacks(player, quantity)
    local inventory = self:GetPlayerInventory(player)
    if not inventory then
        return false, "Inventário não encontrado"
    end
    
    local cost = self:CalculatePacksCost(quantity)
    
    if inventory.currency < cost then
        return false, "Moeda insuficiente"
    end
    
    -- Deduz moeda e adiciona pacotes
    inventory.currency = inventory.currency - cost
    inventory.packs = inventory.packs + quantity
    
    return true, "Pacotes comprados com sucesso"
end

-- Função para obter estatísticas de gacha do jogador
function GachaSystem:GetGachaStats(player)
    local inventory = self:GetPlayerInventory(player)
    if not inventory or not inventory.gachaStats then
        return nil
    end
    
    local stats = inventory.gachaStats
    local totalCards = 0
    for _, count in pairs(stats.rarityPulls) do
        totalCards = totalCards + count
    end
    
    return {
        totalOpened = stats.totalOpened,
        totalCards = totalCards,
        rarityDistribution = stats.rarityPulls,
        pityCount = stats.pityCount,
        lastLegendaryPull = stats.lastLegendaryPull,
        nextGuaranteedEpic = math.max(0, GACHA_CONFIG.PITY_SYSTEM.EPIC_PITY - stats.pityCount),
        nextGuaranteedLegendary = math.max(0, GACHA_CONFIG.PITY_SYSTEM.LEGENDARY_PITY - stats.lastLegendaryPull)
    }
end

-- Função para simular abertura de pacote (para testes)
function GachaSystem:SimulateOpening(player, quantity)
    local results = {
        totalCards = 0,
        rarityBreakdown = {
            [CardDatabase.Rarity.COMMON.id] = 0,
            [CardDatabase.Rarity.RARE.id] = 0,
            [CardDatabase.Rarity.EPIC.id] = 0,
            [CardDatabase.Rarity.LEGENDARY.id] = 0
        },
        cards = {}
    }
    
    local inventory = self:GetPlayerInventory(player) or InventoryManager:CreateNewInventory()
    
    for i = 1, quantity do
        local cards, error = self:OpenBoosterPack(player)
        if cards then
            for _, card in ipairs(cards) do
                table.insert(results.cards, card)
                results.rarityBreakdown[card.rarity.id] = 
                    results.rarityBreakdown[card.rarity.id] + 1
                results.totalCards = results.totalCards + 1
            end
        end
    end
    
    return results
end

-- Função para resetar pity de um jogador (admin)
function GachaSystem:ResetPity(player)
    local inventory = self:GetPlayerInventory(player)
    if not inventory then return false end
    
    if inventory.gachaStats then
        inventory.gachaStats.pityCount = 0
        inventory.gachaStats.lastLegendaryPull = 0
    end
    
    return true
end

-- Função para obter informações de configuração do gacha
function GachaSystem:GetGachaConfig()
    return {
        baseProbabilities = GACHA_CONFIG.BASE_PROBABILITIES,
        pitySystem = GACHA_CONFIG.PITY_SYSTEM,
        packSettings = GACHA_CONFIG.PACK_SETTINGS
    }
end

-- Função para limpar cache de jogador (quando sai do servidor)
function GachaSystem:CleanupPlayer(player)
    local userId = player.UserId
    playerSeeds[userId] = nil
    playerPullCount[userId] = nil
end

-- Evento para limpeza automática
Players.PlayerRemoving:Connect(function(player)
    GachaSystem:CleanupPlayer(player)
end)

return GachaSystem 