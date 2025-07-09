--[[
    RemoteEvents - Sistema centralizado de eventos remotos
    Autor: Sistema de Gacha/Inventário
    Versão: 1.0
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Cria pasta RemoteEvents se não existir
local RemoteEventsFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not RemoteEventsFolder then
    RemoteEventsFolder = Instance.new("Folder")
    RemoteEventsFolder.Name = "RemoteEvents"
    RemoteEventsFolder.Parent = ReplicatedStorage
end

-- Cria pasta RemoteFunctions se não existir
local RemoteFunctionsFolder = ReplicatedStorage:FindFirstChild("RemoteFunctions")
if not RemoteFunctionsFolder then
    RemoteFunctionsFolder = Instance.new("Folder")
    RemoteFunctionsFolder.Name = "RemoteFunctions"
    RemoteFunctionsFolder.Parent = ReplicatedStorage
end

-- Função para criar RemoteEvent
local function createRemoteEvent(name, folder)
    local existingEvent = folder:FindFirstChild(name)
    if existingEvent then
        return existingEvent
    end
    
    local event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = folder
    return event
end

-- Função para criar RemoteFunction
local function createRemoteFunction(name, folder)
    local existingFunction = folder:FindFirstChild(name)
    if existingFunction then
        return existingFunction
    end
    
    local func = Instance.new("RemoteFunction")
    func.Name = name
    func.Parent = folder
    return func
end

-- RemoteEvents para sistema de inventário e gacha
local RemoteEvents = {
    -- Inventário
    UpdateInventory = createRemoteEvent("UpdateInventory", RemoteEventsFolder),
    RequestInventory = createRemoteEvent("RequestInventory", RemoteEventsFolder),
    FilterInventory = createRemoteEvent("FilterInventory", RemoteEventsFolder),
    SortInventory = createRemoteEvent("SortInventory", RemoteEventsFolder),
    SearchInventory = createRemoteEvent("SearchInventory", RemoteEventsFolder),
    
    -- Gacha
    OpenBoosterPack = createRemoteEvent("OpenBoosterPack", RemoteEventsFolder),
    PurchaseBoosterPack = createRemoteEvent("PurchaseBoosterPack", RemoteEventsFolder),
    GachaAnimation = createRemoteEvent("GachaAnimation", RemoteEventsFolder),
    ShowCardDetails = createRemoteEvent("ShowCardDetails", RemoteEventsFolder),
    
    -- Sistema de cartas
    CardHover = createRemoteEvent("CardHover", RemoteEventsFolder),
    CardClick = createRemoteEvent("CardClick", RemoteEventsFolder),
    CardDrag = createRemoteEvent("CardDrag", RemoteEventsFolder),
    
    -- Interface
    OpenInventoryUI = createRemoteEvent("OpenInventoryUI", RemoteEventsFolder),
    OpenGachaUI = createRemoteEvent("OpenGachaUI", RemoteEventsFolder),
    CloseAllUIs = createRemoteEvent("CloseAllUIs", RemoteEventsFolder),
    
    -- Notificações
    ShowNotification = createRemoteEvent("ShowNotification", RemoteEventsFolder),
    ShowRareCardNotification = createRemoteEvent("ShowRareCardNotification", RemoteEventsFolder),
    
    -- Outros eventos existentes
    BallEvent = createRemoteEvent("BallEvent", RemoteEventsFolder)
}

-- RemoteFunctions para sistema de inventário e gacha
local RemoteFunctions = {
    -- Inventário
    GetPlayerData = createRemoteFunction("GetPlayerData", RemoteFunctionsFolder),
    GetCardCollection = createRemoteFunction("GetCardCollection", RemoteFunctionsFolder),
    GetInventoryStats = createRemoteFunction("GetInventoryStats", RemoteFunctionsFolder),
    GetCardDetails = createRemoteFunction("GetCardDetails", RemoteFunctionsFolder),
    
    -- Gacha
    GetGachaStats = createRemoteFunction("GetGachaStats", RemoteFunctionsFolder),
    GetGachaConfig = createRemoteFunction("GetGachaConfig", RemoteFunctionsFolder),
    CanAffordPacks = createRemoteFunction("CanAffordPacks", RemoteFunctionsFolder),
    
    -- Sistema de cartas
    ValidateCard = createRemoteFunction("ValidateCard", RemoteFunctionsFolder),
    GetCardDatabase = createRemoteFunction("GetCardDatabase", RemoteFunctionsFolder),
    
    -- Outros RemoteFunctions existentes
    SpawnPlayers = createRemoteFunction("SpawnPlayers", RemoteFunctionsFolder),
    RequestKick = createRemoteFunction("RequestKick", RemoteFunctionsFolder)
}

-- Módulo de export
local RemoteEventsModule = {
    Events = RemoteEvents,
    Functions = RemoteFunctions,
    
    -- Funcionalidades auxiliares
    CreateRemoteEvent = createRemoteEvent,
    CreateRemoteFunction = createRemoteFunction,
    
    -- Referências das pastas
    RemoteEventsFolder = RemoteEventsFolder,
    RemoteFunctionsFolder = RemoteFunctionsFolder
}

-- Permite acesso direto aos eventos
setmetatable(RemoteEventsModule, {
    __index = function(self, key)
        return RemoteEvents[key] or RemoteFunctions[key]
    end
})

return RemoteEventsModule 