local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpawnPlayersRF = ReplicatedStorage.RemoteFunctions.SpawnPlayers

-- Modelos
local TEST_DUMMY = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("TestDummy")
local FOOTBALL = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Football") -- Adicione sua bola aqui

-- Função de spawn (com bola de futebol)
local function spawnPlayers(player: Player, formationData)
	-- 1. Limpeza segura (dummies + bola)
	for _, child in ipairs(workspace:GetChildren()) do
		if child.Name == "TestDummy" or child.Name == "Football" then
			child:Destroy()
		end
	end

	-- 2. Spawn dos dummies
	for _, playerData in ipairs(formationData.players) do
		local dummy = TEST_DUMMY:Clone()
		local rootPart = dummy:FindFirstChild("HumanoidRootPart")

		if rootPart then
			rootPart.Position = formationData.fieldCenter + playerData.position
			if playerData.role then
				dummy:SetAttribute("Role", playerData.role)
			end
		end
		dummy.Parent = workspace
	end

	-- 3. Spawn da bola de futebol (no centro do campo)
	local football = FOOTBALL:Clone()
	football.Position = formationData.fieldCenter + Vector3.new(0, 1, 0) -- 1 unidade acima do chão
	football.Parent = workspace

	return true
end

-- Conexão do RemoteFunction
SpawnPlayersRF.OnServerInvoke = function(player, ...)
	return spawnPlayers(player, ...)
end