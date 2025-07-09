-- Services with explicit types
local Players: Players = game:GetService("Players")
local RunService: RunService = game:GetService("RunService")
local TweenService: TweenService = game:GetService("TweenService")
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Custom types
type CameraSettings = {
	position: Vector3,
	lookAt: Vector3,
	fov: number
}

type GameState = {
	cameraActivated: boolean
}

type FormationData = {
	fieldCenter: Vector3,
	fieldSize: Vector3,
	players: {
		position: Vector3,
		Orientation: CFrame,
		role: string?  -- "Goalkeeper", "Defender", etc
	}
}

-- Configuration
local PLAY_AREA: BasePart = workspace:WaitForChild("PlayPart") or workspace:WaitForChild("PlayArea")
local FIELD_AREA: BasePart = workspace:WaitForChild("Field")
local PROXIMITY_RANGE: number = 18
local TWEEN_DURATION: number = 0.5

-- References with type annotations
local player: Player = Players.LocalPlayer
local camera: Camera = workspace.CurrentCamera
local gui: ScreenGui = player:WaitForChild("PlayerGui"):WaitForChild("StartGameButtonGui") :: ScreenGui
local button: TextButton = gui:WaitForChild("StartButton") :: TextButton
local SpawnPlayersRF: RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunctions"):WaitForChild("SpawnPlayers") :: RemoteFunction

-- UI Positions
local VISIBLE_POS: UDim2 = UDim2.new(0.975, 0, 0.95, 0)
local HIDDEN_POS: UDim2 = UDim2.new(0.975, 0, 0.95, 300)
local BUTTON_SIZE: UDim2 = button.Size

-- Game state
local gameState: GameState = {
	cameraActivated = false
}

-- Initialize UI
gui.Enabled = true
button.Position = HIDDEN_POS
button.Size = BUTTON_SIZE
button.Visible = true

--[[
    Get formation data (4-3-2-1 formation)
    @return FormationData
]]
local function getFormationData(): FormationData
	return {
		fieldCenter = FIELD_AREA.Position,
		fieldSize = FIELD_AREA.Size,
		players = {
			-- Goalkeeper
			--[[
			{ position = Vector3.new(130, 4, 0), role = "Goalkeeper",},

			-- Defenders (4)
			{ position = Vector3.new(70, 4, -60), role = "Defender",},
			{ position = Vector3.new(80, 4, -30), role = "Defender",},
			{ position = Vector3.new(80, 4, 30), role = "Defender",  },
			{ position = Vector3.new(70, 4, 60), role = "Defender",  },

			-- Midfielders (3)
			{ position = Vector3.new(20, 4, 60), role = "Midfielder",  },
			{ position = Vector3.new(30, 4, 0), role = "Midfielder",  },
			{ position = Vector3.new(20, 4, -60), role = "Midfielder",  },

			-- Forwards (2)
			{ position = Vector3.new(-25, 4, -25), role = "Forward",  },
			{ position = Vector3.new(-25, 4, 25), role = "Forward",  },
			]]--
			-- Striker (1)
			{ position = Vector3.new(5, 4, 0), role = "Striker",  }
		}
	}
end

--[[
    Calculates camera view settings
    @return CameraSettings
]]
local function calculateCameraView(): CameraSettings
	local fieldSize: Vector3 = FIELD_AREA.Size
	local diagonalLength: number = math.sqrt(fieldSize.X^1.1 + fieldSize.Z^1.1)
	local distanceMultiplier: number = math.max(fieldSize.X, fieldSize.Z) * 0.225
	local cameraHeight: number = FIELD_AREA.Position.Y + distanceMultiplier
	local cameraDistance: number = diagonalLength

	local cameraOffset: CFrame = CFrame.new(0, cameraHeight, -cameraDistance)
	local cameraPos: Vector3 = (FIELD_AREA.CFrame * cameraOffset).Position

	local lookAtPos: Vector3 = Vector3.new(
		FIELD_AREA.Position.X,
		FIELD_AREA.Position.Y,
		FIELD_AREA.Position.Z
	)

	local minDimension: number = math.min(fieldSize.X, fieldSize.Z)
	local dynamicFOV: number = -50 + (minDimension * 0.4)

	local adjustedCameraPos: Vector3 = Vector3.new(
		cameraPos.X - 35,
		cameraPos.Y + 75,
		cameraPos.Z - 200
	)

	return {
		position = adjustedCameraPos,
		lookAt = lookAtPos,
		fov = dynamicFOV
	}
end

--[[
    Updates camera view in real-time
    @return nil
]]
local function updateCameraView(): ()
	if not gameState.cameraActivated then return end

	local cameraData: CameraSettings = calculateCameraView()
	camera.CFrame = CFrame.lookAt(cameraData.position, cameraData.lookAt)
	camera.FieldOfView = cameraData.fov
end

--[[
    Toggles button visibility with animation
    @param show: boolean - Whether to show the button
    @return nil
]]
local function toggleButton(show: boolean): ()
	local tweenInfo: TweenInfo = TweenInfo.new(
		TWEEN_DURATION,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	TweenService:Create(button, tweenInfo, {
		Position = show and VISIBLE_POS or HIDDEN_POS
	}):Play()
end

--[[
    Activates field camera with animation
    @return nil
]]
local function activateFieldCamera(): ()
	camera.CameraType = Enum.CameraType.Scriptable
	local cameraData: CameraSettings = calculateCameraView()
	camera.FieldOfView = cameraData.fov

	local tweenInfo: TweenInfo = TweenInfo.new(3, Enum.EasingStyle.Quad)
	TweenService:Create(camera, tweenInfo, {
		CFrame = CFrame.lookAt(cameraData.position, cameraData.lookAt),
		FieldOfView = cameraData.fov
	}):Play()
end

--[[
    Checks player proximity to play area
    @return nil
]]
local function checkProximity(): ()
	local character: Model? = player.Character
	local rootPart: BasePart? = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then return end

	local distance: number = (rootPart.Position - PLAY_AREA.Position).Magnitude
	local inArea: boolean = distance <= PROXIMITY_RANGE
	local isButtonVisible: boolean = button.Position.Y.Offset < 150

	if inArea and not isButtonVisible and not gameState.cameraActivated then
		toggleButton(true)
	elseif not inArea and isButtonVisible then
		toggleButton(false)
	end
end

--[[
    Resets camera to default state
    @return nil
]]
local function resetCamera(): ()
	if camera.CameraType == Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = 70
		gameState.cameraActivated = false
	end
end

--[[
    Handles button click event
    @return nil
]]
local function onButtonClick(): ()
	if gameState.cameraActivated then return end

	gameState.cameraActivated = true
	toggleButton(false)
	activateFieldCamera()
	
	local success, err = pcall(function()
		return SpawnPlayersRF:InvokeServer(getFormationData())
	end)
	if success then
		--print("INVOKE LOCAL FUNCIONANDO")
	end
end

-- Event connections
button.MouseButton1Click:Connect(onButtonClick)

RunService.Heartbeat:Connect(function()
	checkProximity()

	-- Check if player left the area
	if camera.CameraType == Enum.CameraType.Scriptable then
		local character: Model? = player.Character
		local rootPart: BasePart? = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if rootPart and (rootPart.Position - PLAY_AREA.Position).Magnitude > PROXIMITY_RANGE then
			resetCamera()
		end
	end
end)

player.CharacterAdded:Connect(function(character: Model)
    -- Método mais seguro com verificação explícita
    local humanoidRootPart: Instance? = character:WaitForChild("HumanoidRootPart")
    if not humanoidRootPart or not humanoidRootPart:IsA("BasePart") then
        warn("HumanoidRootPart não encontrado ou tipo inválido")
        return
    end
    
    -- Agora temos certeza do tipo
    local rootPart: BasePart = humanoidRootPart
    -- ... resto do código
end)

