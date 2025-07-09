-- Services
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Modules
local BallModules = require(ReplicatedStorage.Modules.BallModules)

-- Local Player
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Variáveis de controle
local selectedDummy = nil
local clickCount = 0

-- Função principal de inicialização
local function init()
	-- Configura os click detectors nos dummies
	local function setupDummyInteraction()
		

		for _, dummy in ipairs(workspace:GetChildren()) do
			if dummy.Name == "TestDummy" then
				print("Dummy encontrado:", dummy.Name)
				local clickDetector = dummy:FindFirstChildWhichIsA("ClickDetector")
				if clickDetector then
					--print("ClickDetector encontrado no dummy")

					clickDetector.MouseClick:Connect(function()
						print("Clicou no dummy")
						local ball = workspace:FindFirstChild("Football") 
						print("bola bobola: ", workspace:WaitForChild("Football"))

						if ball and ball:FindFirstChildWhichIsA("WeldConstraint") then
							selectedDummy = dummy
							clickCount = 1
							print("Dummy selecionado para chute")
						end
					end)
				end
			end
		end
	end

	-- Sistema de detecção de clique
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if selectedDummy then
				clickCount = clickCount + 1
				print("Clique registrado. Total:", clickCount)

				if clickCount == 2 then
					print("Segundo clique detectado - preparando chute")
					local ball = workspace:FindFirstChild("Football")

					if ball then
						BallModules.kickBall(ball, mouse.Hit.Position)
						print("Bola chutada!")
						selectedDummy = nil
						clickCount = 0
					end
				end
			end
		end
	end)

	-- Configura inicial
	setupDummyInteraction()
end

-- Inicialização
player.CharacterAdded:Connect(function(character)
	wait(3)
	init()
end)

