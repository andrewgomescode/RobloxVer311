--[[
    CardDatabase - Sistema de base de dados de cartas para o jogo de futebol
    Autor: Sistema de Gacha/Inventário
    Versão: 1.0
]]

local CardDatabase = {}

-- Enumerações de raridades
CardDatabase.Rarity = {
    COMMON = {
        name = "Comum",
        color = Color3.fromRGB(170, 170, 170),
        weight = 70,
        id = 1
    },
    RARE = {
        name = "Raro",
        color = Color3.fromRGB(0, 112, 221),
        weight = 20,
        id = 2
    },
    EPIC = {
        name = "Épico",
        color = Color3.fromRGB(163, 53, 238),
        weight = 8,
        id = 3
    },
    LEGENDARY = {
        name = "Lendário",
        color = Color3.fromRGB(255, 128, 0),
        weight = 2,
        id = 4
    }
}

-- Posições dos jogadores
CardDatabase.Position = {
    GOALKEEPER = "Goleiro",
    DEFENDER = "Zagueiro",
    MIDFIELDER = "Meio-campo",
    FORWARD = "Atacante"
}

-- Times disponíveis (exemplo com times brasileiros)
CardDatabase.Teams = {
    FLAMENGO = {
        name = "Flamengo",
        color = Color3.fromRGB(255, 0, 0),
        logo = "rbxassetid://123456789" -- ID do logo no Roblox
    },
    PALMEIRAS = {
        name = "Palmeiras",
        color = Color3.fromRGB(0, 128, 0),
        logo = "rbxassetid://123456790"
    },
    SAO_PAULO = {
        name = "São Paulo",
        color = Color3.fromRGB(255, 255, 255),
        logo = "rbxassetid://123456791"
    },
    CORINTHIANS = {
        name = "Corinthians",
        color = Color3.fromRGB(0, 0, 0),
        logo = "rbxassetid://123456792"
    },
    SANTOS = {
        name = "Santos",
        color = Color3.fromRGB(255, 255, 255),
        logo = "rbxassetid://123456793"
    },
    ATLETICO_MG = {
        name = "Atlético-MG",
        color = Color3.fromRGB(0, 0, 0),
        logo = "rbxassetid://123456794"
    }
}

-- Base de dados de cartas
CardDatabase.Cards = {
    -- CARTAS COMUNS
    ["C001"] = {
        id = "C001",
        name = "Gabriel Silva",
        position = CardDatabase.Position.DEFENDER,
        team = CardDatabase.Teams.FLAMENGO,
        rarity = CardDatabase.Rarity.COMMON,
        stats = {
            speed = 65,
            shooting = 45,
            passing = 70,
            defending = 85,
            dribbling = 50,
            physicality = 80,
            overall = 66
        },
        description = "Zagueiro sólido com boa capacidade defensiva.",
        image = "rbxassetid://123456800"
    },
    ["C002"] = {
        id = "C002",
        name = "Carlos Mendes",
        position = CardDatabase.Position.MIDFIELDER,
        team = CardDatabase.Teams.PALMEIRAS,
        rarity = CardDatabase.Rarity.COMMON,
        stats = {
            speed = 70,
            shooting = 60,
            passing = 75,
            defending = 60,
            dribbling = 65,
            physicality = 70,
            overall = 67
        },
        description = "Meio-campista versátil com bom passe.",
        image = "rbxassetid://123456801"
    },
    ["C003"] = {
        id = "C003",
        name = "João Santos",
        position = CardDatabase.Position.FORWARD,
        team = CardDatabase.Teams.SAO_PAULO,
        rarity = CardDatabase.Rarity.COMMON,
        stats = {
            speed = 75,
            shooting = 70,
            passing = 60,
            defending = 40,
            dribbling = 70,
            physicality = 65,
            overall = 63
        },
        description = "Atacante rápido com bom drible.",
        image = "rbxassetid://123456802"
    },
    ["C004"] = {
        id = "C004",
        name = "Pedro Oliveira",
        position = CardDatabase.Position.GOALKEEPER,
        team = CardDatabase.Teams.CORINTHIANS,
        rarity = CardDatabase.Rarity.COMMON,
        stats = {
            speed = 45,
            shooting = 20,
            passing = 50,
            defending = 90,
            dribbling = 30,
            physicality = 85,
            overall = 54
        },
        description = "Goleiro confiável com boas defesas.",
        image = "rbxassetid://123456803"
    },
    ["C005"] = {
        id = "C005",
        name = "Lucas Ferreira",
        position = CardDatabase.Position.MIDFIELDER,
        team = CardDatabase.Teams.SANTOS,
        rarity = CardDatabase.Rarity.COMMON,
        stats = {
            speed = 68,
            shooting = 55,
            passing = 78,
            defending = 65,
            dribbling = 62,
            physicality = 72,
            overall = 67
        },
        description = "Volante equilibrado com boa visão de jogo.",
        image = "rbxassetid://123456804"
    },

    -- CARTAS RARAS
    ["R001"] = {
        id = "R001",
        name = "Bruno Henrique",
        position = CardDatabase.Position.FORWARD,
        team = CardDatabase.Teams.FLAMENGO,
        rarity = CardDatabase.Rarity.RARE,
        stats = {
            speed = 88,
            shooting = 82,
            passing = 75,
            defending = 45,
            dribbling = 85,
            physicality = 78,
            overall = 76
        },
        description = "Atacante veloz com grande capacidade de finalização.",
        image = "rbxassetid://123456805"
    },
    ["R002"] = {
        id = "R002",
        name = "Gustavo Scarpa",
        position = CardDatabase.Position.MIDFIELDER,
        team = CardDatabase.Teams.PALMEIRAS,
        rarity = CardDatabase.Rarity.RARE,
        stats = {
            speed = 72,
            shooting = 80,
            passing = 88,
            defending = 60,
            dribbling = 82,
            physicality = 68,
            overall = 75
        },
        description = "Meia criativo com excelente passe e chute.",
        image = "rbxassetid://123456806"
    },
    ["R003"] = {
        id = "R003",
        name = "Miranda",
        position = CardDatabase.Position.DEFENDER,
        team = CardDatabase.Teams.SAO_PAULO,
        rarity = CardDatabase.Rarity.RARE,
        stats = {
            speed = 65,
            shooting = 35,
            passing = 78,
            defending = 92,
            dribbling = 55,
            physicality = 88,
            overall = 69
        },
        description = "Zagueiro experiente com liderança em campo.",
        image = "rbxassetid://123456807"
    },

    -- CARTAS ÉPICAS
    ["E001"] = {
        id = "E001",
        name = "Gabigol",
        position = CardDatabase.Position.FORWARD,
        team = CardDatabase.Teams.FLAMENGO,
        rarity = CardDatabase.Rarity.EPIC,
        stats = {
            speed = 85,
            shooting = 92,
            passing = 78,
            defending = 40,
            dribbling = 88,
            physicality = 82,
            overall = 78
        },
        description = "Artilheiro nato com instinto de gol excepcional.",
        image = "rbxassetid://123456808"
    },
    ["E002"] = {
        id = "E002",
        name = "Dudu",
        position = CardDatabase.Position.FORWARD,
        team = CardDatabase.Teams.PALMEIRAS,
        rarity = CardDatabase.Rarity.EPIC,
        stats = {
            speed = 88,
            shooting = 85,
            passing = 82,
            defending = 45,
            dribbling = 92,
            physicality = 75,
            overall = 78
        },
        description = "Ponta habilidoso com dribles desconcertantes.",
        image = "rbxassetid://123456809"
    },

    -- CARTAS LENDÁRIAS
    ["L001"] = {
        id = "L001",
        name = "Arrascaeta",
        position = CardDatabase.Position.MIDFIELDER,
        team = CardDatabase.Teams.FLAMENGO,
        rarity = CardDatabase.Rarity.LEGENDARY,
        stats = {
            speed = 80,
            shooting = 88,
            passing = 95,
            defending = 65,
            dribbling = 93,
            physicality = 78,
            overall = 83
        },
        description = "Meia-atacante de classe mundial com visão única.",
        image = "rbxassetid://123456810"
    },
    ["L002"] = {
        id = "L002",
        name = "Weverton",
        position = CardDatabase.Position.GOALKEEPER,
        team = CardDatabase.Teams.PALMEIRAS,
        rarity = CardDatabase.Rarity.LEGENDARY,
        stats = {
            speed = 55,
            shooting = 25,
            passing = 70,
            defending = 98,
            dribbling = 45,
            physicality = 92,
            overall = 64
        },
        description = "Goleiro de seleção com reflexos extraordinários.",
        image = "rbxassetid://123456811"
    }
}

-- Função para obter carta por ID
function CardDatabase:GetCardById(cardId)
    return self.Cards[cardId]
end

-- Função para obter todas as cartas
function CardDatabase:GetAllCards()
    return self.Cards
end

-- Função para obter cartas por raridade
function CardDatabase:GetCardsByRarity(rarity)
    local result = {}
    for id, card in pairs(self.Cards) do
        if card.rarity == rarity then
            result[id] = card
        end
    end
    return result
end

-- Função para obter cartas por posição
function CardDatabase:GetCardsByPosition(position)
    local result = {}
    for id, card in pairs(self.Cards) do
        if card.position == position then
            result[id] = card
        end
    end
    return result
end

-- Função para obter cartas por time
function CardDatabase:GetCardsByTeam(team)
    local result = {}
    for id, card in pairs(self.Cards) do
        if card.team == team then
            result[id] = card
        end
    end
    return result
end

-- Função para obter raridade por peso (para sistema de gacha)
function CardDatabase:GetRarityByWeight()
    local rarities = {}
    for _, rarity in pairs(self.Rarity) do
        table.insert(rarities, rarity)
    end
    
    -- Ordena por peso (menor peso = mais raro)
    table.sort(rarities, function(a, b) return a.weight > b.weight end)
    return rarities
end

-- Função para validar se uma carta existe
function CardDatabase:IsValidCard(cardId)
    return self.Cards[cardId] ~= nil
end

-- Função para obter estatísticas de uma carta
function CardDatabase:GetCardStats(cardId)
    local card = self:GetCardById(cardId)
    return card and card.stats or nil
end

-- Função para calcular overall médio de uma coleção
function CardDatabase:CalculateAverageOverall(cardIds)
    local total = 0
    local count = 0
    
    for _, cardId in ipairs(cardIds) do
        local card = self:GetCardById(cardId)
        if card then
            total = total + card.stats.overall
            count = count + 1
        end
    end
    
    return count > 0 and math.floor(total / count) or 0
end

-- Função para obter cartas por faixa de overall
function CardDatabase:GetCardsByOverallRange(minOverall, maxOverall)
    local result = {}
    for id, card in pairs(self.Cards) do
        if card.stats.overall >= minOverall and card.stats.overall <= maxOverall then
            result[id] = card
        end
    end
    return result
end

-- Função para obter informações resumidas de uma carta
function CardDatabase:GetCardSummary(cardId)
    local card = self:GetCardById(cardId)
    if not card then return nil end
    
    return {
        id = card.id,
        name = card.name,
        position = card.position,
        team = card.team.name,
        rarity = card.rarity.name,
        overall = card.stats.overall,
        image = card.image
    }
end

return CardDatabase 