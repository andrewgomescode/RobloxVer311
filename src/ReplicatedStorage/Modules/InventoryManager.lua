--[[
    InventoryManager - Sistema de gerenciamento de inventário de cartas
    Autor: Sistema de Gacha/Inventário
    Versão: 1.0
    
    Funcionalidades:
    - Gerenciar coleção de cartas do jogador
    - Adicionar/remover cartas
    - Filtrar e ordenar inventário
    - Calcular estatísticas do inventário
    - Migração de dados antigos
]]

local InventoryManager = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CardDatabase = require(script.Parent.CardDatabase)

-- Configurações do inventário
local INVENTORY_VERSION = "1.2"
local DEFAULT_CURRENCY = 1000
local DEFAULT_PACKS = 3

-- Tipos de ordenação
InventoryManager.SortType = {
    RARITY = "rarity",
    OVERALL = "overall",
    NAME = "name",
    POSITION = "position",
    TEAM = "team",
    RECENT = "recent"
}

-- Tipos de filtro
InventoryManager.FilterType = {
    ALL = "all",
    RARITY = "rarity",
    POSITION = "position",
    TEAM = "team",
    OVERALL_RANGE = "overall_range"
}

-- Função para criar novo inventário
function InventoryManager:CreateNewInventory()
    return {
        version = INVENTORY_VERSION,
        currency = DEFAULT_CURRENCY,
        packs = DEFAULT_PACKS,
        cards = {},
        cardHistory = {}, -- Histórico de cartas obtidas
        gachaStats = {
            totalOpened = 0,
            rarityPulls = {
                [CardDatabase.Rarity.COMMON.id] = 0,
                [CardDatabase.Rarity.RARE.id] = 0,
                [CardDatabase.Rarity.EPIC.id] = 0,
                [CardDatabase.Rarity.LEGENDARY.id] = 0
            },
            pityCount = 0,
            lastLegendaryPull = 0
        },
        timestamps = {
            created = os.time(),
            lastLogin = os.time(),
            lastPull = 0
        }
    }
end

-- Função para adicionar carta ao inventário
function InventoryManager:AddCard(inventory, cardId, quantity)
    quantity = quantity or 1
    
    -- Verifica se a carta é válida
    if not CardDatabase:IsValidCard(cardId) then
        return false, "Carta inválida: " .. tostring(cardId)
    end
    
    -- Inicializa a carta se não existir
    if not inventory.cards[cardId] then
        inventory.cards[cardId] = 0
    end
    
    -- Adiciona a quantidade
    inventory.cards[cardId] = inventory.cards[cardId] + quantity
    
    -- Atualiza histórico
    self:UpdateCardHistory(inventory, cardId, quantity)
    
    return true, "Carta adicionada com sucesso"
end

-- Função para remover carta do inventário
function InventoryManager:RemoveCard(inventory, cardId, quantity)
    quantity = quantity or 1
    
    -- Verifica se a carta existe no inventário
    if not inventory.cards[cardId] or inventory.cards[cardId] < quantity then
        return false, "Quantidade insuficiente da carta: " .. tostring(cardId)
    end
    
    -- Remove a quantidade
    inventory.cards[cardId] = inventory.cards[cardId] - quantity
    
    -- Remove completamente se a quantidade for zero
    if inventory.cards[cardId] <= 0 then
        inventory.cards[cardId] = nil
    end
    
    return true, "Carta removida com sucesso"
end

-- Função para obter quantidade de uma carta
function InventoryManager:GetCardQuantity(inventory, cardId)
    return inventory.cards[cardId] or 0
end

-- Função para obter total de cartas no inventário
function InventoryManager:GetTotalCards(inventory)
    local total = 0
    for cardId, quantity in pairs(inventory.cards) do
        total = total + quantity
    end
    return total
end

-- Função para obter cartas únicas no inventário
function InventoryManager:GetUniqueCardsCount(inventory)
    local count = 0
    for cardId, quantity in pairs(inventory.cards) do
        if quantity > 0 then
            count = count + 1
        end
    end
    return count
end

-- Função para filtrar cartas do inventário
function InventoryManager:FilterCards(inventory, filterType, filterValue)
    local filteredCards = {}
    
    for cardId, quantity in pairs(inventory.cards) do
        local card = CardDatabase:GetCardById(cardId)
        if card and quantity > 0 then
            local include = false
            
            if filterType == self.FilterType.ALL then
                include = true
            elseif filterType == self.FilterType.RARITY then
                include = card.rarity == filterValue
            elseif filterType == self.FilterType.POSITION then
                include = card.position == filterValue
            elseif filterType == self.FilterType.TEAM then
                include = card.team == filterValue
            elseif filterType == self.FilterType.OVERALL_RANGE then
                local minOverall, maxOverall = filterValue.min, filterValue.max
                include = card.stats.overall >= minOverall and card.stats.overall <= maxOverall
            end
            
            if include then
                filteredCards[cardId] = {
                    card = card,
                    quantity = quantity
                }
            end
        end
    end
    
    return filteredCards
end

-- Função para ordenar cartas do inventário
function InventoryManager:SortCards(cardData, sortType, ascending)
    ascending = ascending or false
    
    local sortedCards = {}
    for cardId, data in pairs(cardData) do
        table.insert(sortedCards, {
            id = cardId,
            card = data.card,
            quantity = data.quantity
        })
    end
    
    table.sort(sortedCards, function(a, b)
        local valueA, valueB
        
        if sortType == self.SortType.RARITY then
            valueA = a.card.rarity.id
            valueB = b.card.rarity.id
        elseif sortType == self.SortType.OVERALL then
            valueA = a.card.stats.overall
            valueB = b.card.stats.overall
        elseif sortType == self.SortType.NAME then
            valueA = a.card.name
            valueB = b.card.name
        elseif sortType == self.SortType.POSITION then
            valueA = a.card.position
            valueB = b.card.position
        elseif sortType == self.SortType.TEAM then
            valueA = a.card.team.name
            valueB = b.card.team.name
        else
            valueA = a.id
            valueB = b.id
        end
        
        if ascending then
            return valueA < valueB
        else
            return valueA > valueB
        end
    end)
    
    return sortedCards
end

-- Função para atualizar histórico de cartas
function InventoryManager:UpdateCardHistory(inventory, cardId, quantity)
    if not inventory.cardHistory then
        inventory.cardHistory = {}
    end
    
    table.insert(inventory.cardHistory, {
        cardId = cardId,
        quantity = quantity,
        timestamp = os.time()
    })
    
    -- Mantém apenas os últimos 100 registros
    if #inventory.cardHistory > 100 then
        table.remove(inventory.cardHistory, 1)
    end
end

-- Função para obter estatísticas do inventário
function InventoryManager:GetInventoryStats(inventory)
    local stats = {
        totalCards = self:GetTotalCards(inventory),
        uniqueCards = self:GetUniqueCardsCount(inventory),
        averageOverall = 0,
        rarityDistribution = {
            [CardDatabase.Rarity.COMMON.id] = 0,
            [CardDatabase.Rarity.RARE.id] = 0,
            [CardDatabase.Rarity.EPIC.id] = 0,
            [CardDatabase.Rarity.LEGENDARY.id] = 0
        },
        positionDistribution = {
            [CardDatabase.Position.GOALKEEPER] = 0,
            [CardDatabase.Position.DEFENDER] = 0,
            [CardDatabase.Position.MIDFIELDER] = 0,
            [CardDatabase.Position.FORWARD] = 0
        },
        teamDistribution = {},
        highestOverall = 0,
        collectionValue = 0
    }
    
    local totalOverall = 0
    local cardCount = 0
    
    for cardId, quantity in pairs(inventory.cards) do
        local card = CardDatabase:GetCardById(cardId)
        if card and quantity > 0 then
            -- Contagem de raridades
            stats.rarityDistribution[card.rarity.id] = 
                stats.rarityDistribution[card.rarity.id] + quantity
            
            -- Contagem de posições
            stats.positionDistribution[card.position] = 
                stats.positionDistribution[card.position] + quantity
            
            -- Contagem de times
            local teamName = card.team.name
            stats.teamDistribution[teamName] = 
                (stats.teamDistribution[teamName] or 0) + quantity
            
            -- Cálculo de overall
            totalOverall = totalOverall + (card.stats.overall * quantity)
            cardCount = cardCount + quantity
            
            -- Maior overall
            if card.stats.overall > stats.highestOverall then
                stats.highestOverall = card.stats.overall
            end
            
            -- Valor da coleção (baseado na raridade)
            local cardValue = card.rarity.id * 100
            stats.collectionValue = stats.collectionValue + (cardValue * quantity)
        end
    end
    
    -- Calcula overall médio
    if cardCount > 0 then
        stats.averageOverall = math.floor(totalOverall / cardCount)
    end
    
    return stats
end

-- Função para buscar cartas no inventário por nome
function InventoryManager:SearchCards(inventory, searchTerm)
    local results = {}
    searchTerm = string.lower(searchTerm)
    
    for cardId, quantity in pairs(inventory.cards) do
        local card = CardDatabase:GetCardById(cardId)
        if card and quantity > 0 then
            local cardName = string.lower(card.name)
            local teamName = string.lower(card.team.name)
            local position = string.lower(card.position)
            
            if string.find(cardName, searchTerm) or 
               string.find(teamName, searchTerm) or 
               string.find(position, searchTerm) then
                results[cardId] = {
                    card = card,
                    quantity = quantity
                }
            end
        end
    end
    
    return results
end

-- Função para obter cartas duplicadas (quantidade > 1)
function InventoryManager:GetDuplicateCards(inventory)
    local duplicates = {}
    
    for cardId, quantity in pairs(inventory.cards) do
        if quantity > 1 then
            local card = CardDatabase:GetCardById(cardId)
            if card then
                duplicates[cardId] = {
                    card = card,
                    quantity = quantity,
                    excess = quantity - 1
                }
            end
        end
    end
    
    return duplicates
end

-- Função para migrar dados antigos do inventário
function InventoryManager:MigrateOldFormat(data)
    if not data then return nil end
    
    -- Migra formato antigo de boosterPacks para packs
    if data.boosterPacks then
        local totalPacks = 0
        for packType, count in pairs(data.boosterPacks) do
            totalPacks = totalPacks + count
        end
        data.packs = (data.packs or 0) + totalPacks
        data.boosterPacks = nil
    end
    
    -- Adiciona campos que podem estar faltando
    if not data.version then
        data.version = INVENTORY_VERSION
    end
    
    if not data.cardHistory then
        data.cardHistory = {}
    end
    
    if not data.gachaStats then
        data.gachaStats = {
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
    
    if not data.timestamps then
        data.timestamps = {
            created = os.time(),
            lastLogin = os.time(),
            lastPull = 0
        }
    end
    
    -- Atualiza timestamp de login
    data.timestamps.lastLogin = os.time()
    
    return data
end

-- Função para validar integridade do inventário
function InventoryManager:ValidateInventory(inventory)
    local issues = {}
    
    -- Verifica se todas as cartas no inventário existem no banco de dados
    for cardId, quantity in pairs(inventory.cards) do
        if not CardDatabase:IsValidCard(cardId) then
            table.insert(issues, "Carta inválida encontrada: " .. cardId)
        end
        
        if quantity < 0 then
            table.insert(issues, "Quantidade negativa para carta: " .. cardId)
        end
    end
    
    -- Verifica campos obrigatórios
    if not inventory.currency or inventory.currency < 0 then
        table.insert(issues, "Moeda inválida ou negativa")
    end
    
    if not inventory.packs or inventory.packs < 0 then
        table.insert(issues, "Pacotes inválidos ou negativos")
    end
    
    return #issues == 0, issues
end

-- Função para limpar inventário (remover cartas inválidas)
function InventoryManager:CleanInventory(inventory)
    local cleaned = {}
    
    for cardId, quantity in pairs(inventory.cards) do
        if CardDatabase:IsValidCard(cardId) and quantity > 0 then
            cleaned[cardId] = quantity
        end
    end
    
    inventory.cards = cleaned
    return inventory
end

-- Função para criar backup do inventário
function InventoryManager:CreateBackup(inventory)
    local backup = {}
    
    -- Copia todos os campos importantes
    for key, value in pairs(inventory) do
        if type(value) == "table" then
            backup[key] = {}
            for k, v in pairs(value) do
                backup[key][k] = v
            end
        else
            backup[key] = value
        end
    end
    
    backup.backupTimestamp = os.time()
    return backup
end

return InventoryManager 