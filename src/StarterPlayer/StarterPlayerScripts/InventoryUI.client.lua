--[[
    InventoryUI - Sistema de interface do inventário de cartas
    Autor: Sistema de Gacha/Inventário
    Versão: 1.0
    
    Funcionalidades:
    - Grade de cartas com rolagem
    - Filtros por raridade, posição e time
    - Ordenação por diversos critérios
    - Busca por nome
    - Visualização detalhada de cartas
    - Animações e feedback visual
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Modules
local CardDatabase = require(ReplicatedStorage.Modules.CardDatabase)
local InventoryManager = require(ReplicatedStorage.Modules.InventoryManager)
local RemoteEventsModule = require(ReplicatedStorage.RemoteEvents)
local RemoteEvents = RemoteEventsModule.Events
local RemoteFunctions = RemoteEventsModule.Functions

-- GUI Variables
local inventoryGui = nil
local cardFrames = {}
local currentFilter = InventoryManager.FilterType.ALL
local currentSort = InventoryManager.SortType.RARITY
local currentSearch = ""
local cardData = {}
local isInventoryOpen = false

-- UI Configuration
local UI_CONFIG = {
    CARD_SIZE = UDim2.new(0, 120, 0, 160),
    CARD_PADDING = 10,
    CARDS_PER_ROW = 6,
    ANIMATION_DURATION = 0.3,
    CARD_HOVER_SCALE = 1.1,
    COLORS = {
        BACKGROUND = Color3.fromRGB(30, 30, 30),
        CARD_BACKGROUND = Color3.fromRGB(45, 45, 45),
        ACCENT = Color3.fromRGB(0, 162, 255),
        TEXT = Color3.fromRGB(255, 255, 255),
        SUBTEXT = Color3.fromRGB(200, 200, 200)
    }
}

-- Create main inventory GUI
local function createInventoryGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InventoryGui"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    
    -- Main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
    mainFrame.Position = UDim2.new(0.05, 0, 0.075, 0)
    mainFrame.BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = UI_CONFIG.COLORS.ACCENT
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Inventário de Cartas"
    titleLabel.TextColor3 = UI_CONFIG.COLORS.TEXT
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = titleBar
    
    -- Close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -50, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = UI_CONFIG.COLORS.TEXT
    closeButton.TextScaled = true
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Control panel
    local controlPanel = Instance.new("Frame")
    controlPanel.Name = "ControlPanel"
    controlPanel.Size = UDim2.new(1, 0, 0, 80)
    controlPanel.Position = UDim2.new(0, 0, 0, 50)
    controlPanel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    controlPanel.BorderSizePixel = 0
    controlPanel.Parent = mainFrame
    
    -- Search box
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(0.3, 0, 0, 30)
    searchBox.Position = UDim2.new(0, 20, 0, 10)
    searchBox.BackgroundColor3 = UI_CONFIG.COLORS.CARD_BACKGROUND
    searchBox.BorderSizePixel = 1
    searchBox.BorderColor3 = UI_CONFIG.COLORS.ACCENT
    searchBox.PlaceholderText = "Buscar cartas..."
    searchBox.PlaceholderColor3 = UI_CONFIG.COLORS.SUBTEXT
    searchBox.TextColor3 = UI_CONFIG.COLORS.TEXT
    searchBox.TextScaled = true
    searchBox.Font = Enum.Font.Gotham
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = controlPanel
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 6)
    searchCorner.Parent = searchBox
    
    -- Filter dropdown
    local filterFrame = Instance.new("Frame")
    filterFrame.Name = "FilterFrame"
    filterFrame.Size = UDim2.new(0.2, 0, 0, 30)
    filterFrame.Position = UDim2.new(0.35, 0, 0, 10)
    filterFrame.BackgroundColor3 = UI_CONFIG.COLORS.CARD_BACKGROUND
    filterFrame.BorderSizePixel = 1
    filterFrame.BorderColor3 = UI_CONFIG.COLORS.ACCENT
    filterFrame.Parent = controlPanel
    
    local filterCorner = Instance.new("UICorner")
    filterCorner.CornerRadius = UDim.new(0, 6)
    filterCorner.Parent = filterFrame
    
    local filterButton = Instance.new("TextButton")
    filterButton.Name = "FilterButton"
    filterButton.Size = UDim2.new(1, 0, 1, 0)
    filterButton.Position = UDim2.new(0, 0, 0, 0)
    filterButton.BackgroundTransparency = 1
    filterButton.Text = "Todos"
    filterButton.TextColor3 = UI_CONFIG.COLORS.TEXT
    filterButton.TextScaled = true
    filterButton.Font = Enum.Font.Gotham
    filterButton.Parent = filterFrame
    
    -- Sort dropdown
    local sortFrame = Instance.new("Frame")
    sortFrame.Name = "SortFrame"
    sortFrame.Size = UDim2.new(0.2, 0, 0, 30)
    sortFrame.Position = UDim2.new(0.6, 0, 0, 10)
    sortFrame.BackgroundColor3 = UI_CONFIG.COLORS.CARD_BACKGROUND
    sortFrame.BorderSizePixel = 1
    sortFrame.BorderColor3 = UI_CONFIG.COLORS.ACCENT
    sortFrame.Parent = controlPanel
    
    local sortCorner = Instance.new("UICorner")
    sortCorner.CornerRadius = UDim.new(0, 6)
    sortCorner.Parent = sortFrame
    
    local sortButton = Instance.new("TextButton")
    sortButton.Name = "SortButton"
    sortButton.Size = UDim2.new(1, 0, 1, 0)
    sortButton.Position = UDim2.new(0, 0, 0, 0)
    sortButton.BackgroundTransparency = 1
    sortButton.Text = "Raridade"
    sortButton.TextColor3 = UI_CONFIG.COLORS.TEXT
    sortButton.TextScaled = true
    sortButton.Font = Enum.Font.Gotham
    sortButton.Parent = sortFrame
    
    -- Stats display
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Name = "StatsLabel"
    statsLabel.Size = UDim2.new(0.15, 0, 0, 60)
    statsLabel.Position = UDim2.new(0.83, 0, 0, 10)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "0 cartas"
    statsLabel.TextColor3 = UI_CONFIG.COLORS.TEXT
    statsLabel.TextScaled = true
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextWrapped = true
    statsLabel.Parent = controlPanel
    
    -- Cards scroll frame
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Name = "CardsScrollFrame"
    scrollFrame.Size = UDim2.new(1, -20, 1, -140)
    scrollFrame.Position = UDim2.new(0, 10, 0, 130)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.ScrollBarImageColor3 = UI_CONFIG.COLORS.ACCENT
    scrollFrame.Parent = mainFrame
    
    -- Grid layout for cards
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UI_CONFIG.CARD_SIZE
    gridLayout.CellPadding = UDim2.new(0, UI_CONFIG.CARD_PADDING, 0, UI_CONFIG.CARD_PADDING)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = scrollFrame
    
    -- Connect events
    closeButton.MouseButton1Click:Connect(function()
        closeInventory()
    end)
    
    searchBox.FocusLost:Connect(function()
        currentSearch = searchBox.Text
        updateCardDisplay()
    end)
    
    filterButton.MouseButton1Click:Connect(function()
        -- Cycle through filters
        local filterOrder = {
            InventoryManager.FilterType.ALL,
            InventoryManager.FilterType.RARITY,
            InventoryManager.FilterType.POSITION,
            InventoryManager.FilterType.TEAM
        }
        
        local currentIndex = 1
        for i, filter in ipairs(filterOrder) do
            if filter == currentFilter then
                currentIndex = i
                break
            end
        end
        
        currentIndex = currentIndex % #filterOrder + 1
        currentFilter = filterOrder[currentIndex]
        
        local filterNames = {
            [InventoryManager.FilterType.ALL] = "Todos",
            [InventoryManager.FilterType.RARITY] = "Raridade",
            [InventoryManager.FilterType.POSITION] = "Posição",
            [InventoryManager.FilterType.TEAM] = "Time"
        }
        
        filterButton.Text = filterNames[currentFilter]
        updateCardDisplay()
    end)
    
    sortButton.MouseButton1Click:Connect(function()
        -- Cycle through sort options
        local sortOrder = {
            InventoryManager.SortType.RARITY,
            InventoryManager.SortType.OVERALL,
            InventoryManager.SortType.NAME,
            InventoryManager.SortType.POSITION
        }
        
        local currentIndex = 1
        for i, sort in ipairs(sortOrder) do
            if sort == currentSort then
                currentIndex = i
                break
            end
        end
        
        currentIndex = currentIndex % #sortOrder + 1
        currentSort = sortOrder[currentIndex]
        
        local sortNames = {
            [InventoryManager.SortType.RARITY] = "Raridade",
            [InventoryManager.SortType.OVERALL] = "Overall",
            [InventoryManager.SortType.NAME] = "Nome",
            [InventoryManager.SortType.POSITION] = "Posição"
        }
        
        sortButton.Text = sortNames[currentSort]
        updateCardDisplay()
    end)
    
    return screenGui
end

-- Create individual card frame
local function createCardFrame(cardData, quantity)
    local cardFrame = Instance.new("Frame")
    cardFrame.Name = "CardFrame_" .. cardData.id
    cardFrame.Size = UDim2.new(1, 0, 1, 0)
    cardFrame.BackgroundColor3 = UI_CONFIG.COLORS.CARD_BACKGROUND
    cardFrame.BorderSizePixel = 2
    cardFrame.BorderColor3 = cardData.rarity.color
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = cardFrame
    
    -- Card image
    local cardImage = Instance.new("ImageLabel")
    cardImage.Name = "CardImage"
    cardImage.Size = UDim2.new(1, -10, 0.6, -10)
    cardImage.Position = UDim2.new(0, 5, 0, 5)
    cardImage.BackgroundTransparency = 1
    cardImage.Image = cardData.image
    cardImage.ScaleType = Enum.ScaleType.Crop
    cardImage.Parent = cardFrame
    
    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 6)
    imageCorner.Parent = cardImage
    
    -- Card name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0.6, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = cardData.name
    nameLabel.TextColor3 = UI_CONFIG.COLORS.TEXT
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = cardFrame
    
    -- Card overall
    local overallLabel = Instance.new("TextLabel")
    overallLabel.Name = "OverallLabel"
    overallLabel.Size = UDim2.new(0.3, 0, 0, 18)
    overallLabel.Position = UDim2.new(0, 5, 0.6, 25)
    overallLabel.BackgroundColor3 = cardData.rarity.color
    overallLabel.BorderSizePixel = 0
    overallLabel.Text = tostring(cardData.stats.overall)
    overallLabel.TextColor3 = UI_CONFIG.COLORS.TEXT
    overallLabel.TextScaled = true
    overallLabel.Font = Enum.Font.GothamBold
    overallLabel.Parent = cardFrame
    
    local overallCorner = Instance.new("UICorner")
    overallCorner.CornerRadius = UDim.new(0, 4)
    overallCorner.Parent = overallLabel
    
    -- Card position
    local positionLabel = Instance.new("TextLabel")
    positionLabel.Name = "PositionLabel"
    positionLabel.Size = UDim2.new(0.65, 0, 0, 18)
    positionLabel.Position = UDim2.new(0.33, 0, 0.6, 25)
    positionLabel.BackgroundTransparency = 1
    positionLabel.Text = cardData.position
    positionLabel.TextColor3 = UI_CONFIG.COLORS.SUBTEXT
    positionLabel.TextScaled = true
    positionLabel.Font = Enum.Font.Gotham
    positionLabel.Parent = cardFrame
    
    -- Team label
    local teamLabel = Instance.new("TextLabel")
    teamLabel.Name = "TeamLabel"
    teamLabel.Size = UDim2.new(1, -10, 0, 16)
    teamLabel.Position = UDim2.new(0, 5, 0.6, 45)
    teamLabel.BackgroundTransparency = 1
    teamLabel.Text = cardData.team.name
    teamLabel.TextColor3 = UI_CONFIG.COLORS.SUBTEXT
    teamLabel.TextScaled = true
    teamLabel.Font = Enum.Font.Gotham
    teamLabel.Parent = cardFrame
    
    -- Quantity indicator (if > 1)
    if quantity > 1 then
        local quantityLabel = Instance.new("TextLabel")
        quantityLabel.Name = "QuantityLabel"
        quantityLabel.Size = UDim2.new(0, 25, 0, 25)
        quantityLabel.Position = UDim2.new(1, -30, 0, 5)
        quantityLabel.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
        quantityLabel.BorderSizePixel = 0
        quantityLabel.Text = "x" .. quantity
        quantityLabel.TextColor3 = UI_CONFIG.COLORS.TEXT
        quantityLabel.TextScaled = true
        quantityLabel.Font = Enum.Font.GothamBold
        quantityLabel.Parent = cardFrame
        
        local quantityCorner = Instance.new("UICorner")
        quantityCorner.CornerRadius = UDim.new(1, 0)
        quantityCorner.Parent = quantityLabel
    end
    
    -- Hover effects
    local button = Instance.new("TextButton")
    button.Name = "HoverButton"
    button.Size = UDim2.new(1, 0, 1, 0)
    button.Position = UDim2.new(0, 0, 0, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = cardFrame
    
    button.MouseEnter:Connect(function()
        local hoverTween = TweenService:Create(cardFrame, 
            TweenInfo.new(UI_CONFIG.ANIMATION_DURATION, Enum.EasingStyle.Quad), 
            {Size = UDim2.new(UI_CONFIG.CARD_HOVER_SCALE, 0, UI_CONFIG.CARD_HOVER_SCALE, 0)}
        )
        hoverTween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local hoverTween = TweenService:Create(cardFrame, 
            TweenInfo.new(UI_CONFIG.ANIMATION_DURATION, Enum.EasingStyle.Quad), 
            {Size = UDim2.new(1, 0, 1, 0)}
        )
        hoverTween:Play()
    end)
    
    button.MouseButton1Click:Connect(function()
        showCardDetails(cardData)
    end)
    
    return cardFrame
end

-- Update card display based on current filters
local function updateCardDisplay()
    -- Clear existing cards
    for _, frame in pairs(cardFrames) do
        frame:Destroy()
    end
    cardFrames = {}
    
    -- Get inventory data
    local inventory = RemoteFunctions.GetPlayerData:InvokeServer()
    if not inventory then return end
    
    -- Filter cards
    local filteredCards = {}
    if currentSearch ~= "" then
        filteredCards = InventoryManager:SearchCards(inventory, currentSearch)
    else
        filteredCards = InventoryManager:FilterCards(inventory, currentFilter)
    end
    
    -- Sort cards
    local sortedCards = InventoryManager:SortCards(filteredCards, currentSort, false)
    
    -- Create card frames
    local scrollFrame = inventoryGui.MainFrame.CardsScrollFrame
    for i, cardEntry in ipairs(sortedCards) do
        local cardFrame = createCardFrame(cardEntry.card, cardEntry.quantity)
        cardFrame.LayoutOrder = i
        cardFrame.Parent = scrollFrame
        cardFrames[cardEntry.id] = cardFrame
    end
    
    -- Update scroll canvas size
    local gridLayout = scrollFrame:FindFirstChild("UIGridLayout")
    if gridLayout then
        wait() -- Wait for layout to update
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end
    
    -- Update stats
    local statsLabel = inventoryGui.MainFrame.ControlPanel.StatsLabel
    local totalCards = 0
    for _, cardEntry in ipairs(sortedCards) do
        totalCards = totalCards + cardEntry.quantity
    end
    statsLabel.Text = totalCards .. " cartas\n" .. #sortedCards .. " únicas"
end

-- Show card details
function showCardDetails(cardData)
    -- Create detail popup
    local detailGui = Instance.new("Frame")
    detailGui.Name = "CardDetailPopup"
    detailGui.Size = UDim2.new(0, 400, 0, 500)
    detailGui.Position = UDim2.new(0.5, -200, 0.5, -250)
    detailGui.BackgroundColor3 = UI_CONFIG.COLORS.BACKGROUND
    detailGui.BorderSizePixel = 2
    detailGui.BorderColor3 = cardData.rarity.color
    detailGui.Parent = inventoryGui
    
    local detailCorner = Instance.new("UICorner")
    detailCorner.CornerRadius = UDim.new(0, 12)
    detailCorner.Parent = detailGui
    
    -- Content will be implemented later
    -- For now, just show basic info
    
    -- Close after 3 seconds
    game:GetService("Debris"):AddItem(detailGui, 3)
end

-- Open inventory
function openInventory()
    if isInventoryOpen then return end
    
    isInventoryOpen = true
    
    if not inventoryGui then
        inventoryGui = createInventoryGUI()
        inventoryGui.Parent = playerGui
    end
    
    -- Animate in
    local mainFrame = inventoryGui.MainFrame
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    inventoryGui.Enabled = true
    
    local openTween = TweenService:Create(mainFrame, 
        TweenInfo.new(UI_CONFIG.ANIMATION_DURATION, Enum.EasingStyle.Back), 
        {
            Size = UDim2.new(0.9, 0, 0.85, 0),
            Position = UDim2.new(0.05, 0, 0.075, 0)
        }
    )
    openTween:Play()
    
    -- Update display
    updateCardDisplay()
end

-- Close inventory
function closeInventory()
    if not isInventoryOpen then return end
    
    isInventoryOpen = false
    
    if inventoryGui then
        local mainFrame = inventoryGui.MainFrame
        local closeTween = TweenService:Create(mainFrame, 
            TweenInfo.new(UI_CONFIG.ANIMATION_DURATION, Enum.EasingStyle.Back), 
            {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }
        )
        closeTween:Play()
        
        closeTween.Completed:Connect(function()
            inventoryGui.Enabled = false
        end)
    end
end

-- Input handling
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.I then
        if isInventoryOpen then
            closeInventory()
        else
            openInventory()
        end
    elseif input.KeyCode == Enum.KeyCode.Escape and isInventoryOpen then
        closeInventory()
    end
end)

-- Remote event connections
RemoteEvents.OpenInventoryUI.OnClientEvent:Connect(function()
    openInventory()
end)

RemoteEvents.UpdateInventory.OnClientEvent:Connect(function(inventory, message, newCards)
    if isInventoryOpen then
        updateCardDisplay()
    end
    
    -- Show notification if message exists
    if message and message ~= "" then
        -- Create notification popup
        -- Implementation can be added later
        print("Notification: " .. message)
    end
end)

print("InventoryUI loaded successfully") 