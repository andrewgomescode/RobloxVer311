local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Função para carregar módulo com tratamento de erro
local function loadModule()
	local success, module = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ArrowManager"))
	end)

	if not success then
		warn("Erro ao carregar ArrowManager:", module)
		return nil
	end
	return module
end

-- Configura o sistema
local function setupSystem()
	local ArrowManager = loadModule()
	if not ArrowManager then return end

	-- Verifica se o template existe
	if not ReplicatedStorage:FindFirstChild("Assets") or not ReplicatedStorage.Assets:FindFirstChild("ArrowIndicator") then
		warn("ArrowIndicator não encontrado em ReplicatedStorage/Assets")
		return
	end

	local player = Players.LocalPlayer
	local mouse = player:GetMouse()

	mouse.Button1Down:Connect(function()
		local target = mouse.Target
		if not target then return end

		-- Verifica se clicou em um TestDummy
		local dummy = target:FindFirstAncestorWhichIsA("Model")
		if dummy and dummy.Name == "TestDummy" then
			ArrowManager.toggleArrowOnDummy(dummy, mouse)
		end
	end)

	--print("Sistema de setas inicializado com sucesso!")
end

-- Inicialização quando o jogador estiver pronto
local player = Players.LocalPlayer
if player.Character then
	task.spawn(setupSystem)
end
player.CharacterAdded:Connect(function()
	task.spawn(setupSystem)
end)