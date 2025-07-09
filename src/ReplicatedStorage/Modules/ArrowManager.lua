local ArrowManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-- Configurações de escala
local MIN_SCALE = 5    -- Tamanho mínimo da seta (eixo Z)
local MAX_SCALE = 25    -- Tamanho máximo da seta (eixo Z)
local SCALE_DISTANCE = 20 -- Distância máxima para atingir MAX_SCALE

-- Tabela de controle
local activeArrows = {}
local updateConnection = nil

-- Função de atualização com alongamento no eixo Z
local function updateArrows()
	for dummy, arrowData in pairs(activeArrows) do
		if not arrowData.arrow or not arrowData.arrow.Parent then
			activeArrows[dummy] = nil
			continue
		end

		local dummyPos = dummy:GetPivot().Position
		local arrowPos = dummyPos + Vector3.new(0, -3, 0) -- Ajuste na altura

		local mousePos = arrowData.mouse.Hit.Position
		local direction = mousePos - arrowPos
		local distance = direction.Magnitude

		-- Suavização e tratamento para distâncias curtas
		if distance < 0.1 then
			direction = arrowData.lastDirection or Vector3.new(1, 0, 0)
		else
			direction = direction.Unit
			arrowData.lastDirection = direction
		end

		-- Ângulo atual e ângulo alvo
		local targetAngle = math.atan2(direction.Z, direction.X)
		local currentAngle = arrowData.currentAngle or targetAngle

		-- Interpolação suave
		arrowData.currentAngle = currentAngle + (targetAngle - currentAngle) * 0.2

		-- Calcula a escala proporcional à distância (eixo Z)
		local scaleFactor = math.clamp(distance / SCALE_DISTANCE, 0, 1)
		local targetScale = MIN_SCALE + (MAX_SCALE - MIN_SCALE) * scaleFactor

		-- Aplica rotação e escala
		arrowData.arrow:PivotTo(
			CFrame.new(arrowPos) * 
				CFrame.Angles(0, -currentAngle + math.pi/2, 0)
		)

		-- Atualiza a escala (apenas no eixo Z)
		arrowData.arrow.Size = Vector3.new(
			arrowData.arrow.Size.X,  -- Mantém o tamanho original em X
			arrowData.arrow.Size.Y,  -- Mantém o tamanho original em Y
			targetScale             -- Ajusta o comprimento em Z
		)
	end
end

-- Restante do código permanece igual (toggleArrowOnDummy e cleanup)
function ArrowManager.toggleArrowOnDummy(dummy, mouse)
	-- Verificação do dummy
	if not dummy or dummy.Name ~= "TestDummy" or not dummy:FindFirstChild("HumanoidRootPart") then
		return nil
	end

	-- Remove seta existente
	if activeArrows[dummy] then
		Debris:AddItem(activeArrows[dummy].arrow, 0.1)
		activeArrows[dummy] = nil

		-- Desconecta se não houver mais setas
		if not next(activeArrows) and updateConnection then
			updateConnection:Disconnect()
			updateConnection = nil
		end
		return nil
	end

	-- Cria nova seta
	local template = ReplicatedStorage.Assets:FindFirstChild("ArrowIndicator")
	if not template then
		warn("Template ArrowIndicator não encontrado")
		return nil
	end

	local newArrow = template:Clone()
	newArrow.Name = "DynamicArrow_"..dummy.Name
	newArrow.Parent = workspace

	-- Posiciona inicialmente 10 unidades acima do dummy
	local dummyPos = dummy:GetPivot().Position
	newArrow:PivotTo(CFrame.new(dummyPos + Vector3.new(0, 10, 0)))

	-- Armazena referências
	activeArrows[dummy] = {
		arrow = newArrow,
		mouse = mouse,
		currentAngle = 0  -- Inicializa o ângulo
	}

	-- Inicia loop de atualização
	if not updateConnection then
		updateConnection = RunService.Heartbeat:Connect(updateArrows)
	end

	return newArrow
end

function ArrowManager.cleanup()
	for dummy, data in pairs(activeArrows) do
		if data.arrow then
			Debris:AddItem(data.arrow, 0.1)
		end
	end
	activeArrows = {}

	if updateConnection then
		updateConnection:Disconnect()
		updateConnection = nil
	end
end

return ArrowManager