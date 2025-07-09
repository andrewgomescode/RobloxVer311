local BallModules = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Utiliza os remotes existentes
local BallEvent = ReplicatedStorage.RemoteEvents.BallEvent
local RequestKick = ReplicatedStorage.RemoteFunctions.RequestKick

local clientWelds = {}
local physicsEnabled = false

function BallModules.Debounce(cooldown)
	while cooldown ~= 0 do  -- CORRETO: condição direta no while
		cooldown = cooldown - 1
		task.wait(1)
	end
	return false
end

function BallModules.Init()
	print("Configurando BallModules...")
	BallEvent.OnClientEvent:Connect(function(action, dummy, ball)
		print("Evento recebido:", action)
		if action == "Attach" then
			wait(3)
			BallModules.AttachBall(dummy, ball)
		elseif action == "Detach" then
			BallModules.DetachBall(ball)
		end
	end)
end

function BallModules.AttachBall(dummy, ball)
	print("Tentando grudar bola no cliente...")
	if not ball or not dummy then 
		print("Bola ou dummy inválidos")
		return 
	end

	local humanoidRootPart = dummy:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		print("Dummy sem HumanoidRootPart")
		return
	end

	-- Remove weld anterior se existir
	if clientWelds[ball] then
		print("Removendo weld cliente existente...")
		clientWelds[ball]:Destroy()
	end

	-- Cria weld visual no cliente
	local weld = Instance.new("WeldConstraint")
	weld.Name = "ClientWeld"
	weld.Part0 = humanoidRootPart
	weld.Part1 = ball
	weld.Parent = ball

	-- Aplica posição
	ball.CFrame = humanoidRootPart.CFrame * CFrame.new(-0.5, -2, -1)

	clientWelds[ball] = weld
	print("Bola grudada no cliente!")
end

function BallModules.DetachBall(ball)
	if clientWelds[ball] then
		print("Removendo ClientWeld...")
		clientWelds[ball]:Destroy()
		clientWelds[ball] = nil
		print("Bola solta no cliente!")
	end
end

function BallModules.kickBall(ball, target)
	print("Preparando chute...")
	
	if not ball or not ball:IsA("BasePart") then
		print("Bola inválida - chute cancelado")
		return false
	end

	-- Solicita ao servidor para remover o ServerWeld
	print("Solicitando remoção do ServerWeld...")
	local success = RequestKick:InvokeServer(ball)
	print("Resposta do servidor:", success)

	if not success then
		print("Falha ao remover ServerWeld - chute cancelado")
		return false
	end

	-- Remove weld visual do cliente
	BallModules.DetachBall(ball)

	-- Configuração física
	ball.Anchored = false
	ball.CanCollide = true
	ball.Massless = false

	-- Cálculo de força aumentada
	local targetPosition = typeof(target) == "CFrame" and target.Position or target
	local direction = (targetPosition - ball.Position).Unit
	local distance = (targetPosition - ball.Position).Magnitude
	local force = math.clamp(distance * 8, 200, 1500)  -- Força significativamente aumentada

	print(string.format("APLICANDO FORÇA FORTE: %.2f | Direção: %s", force, tostring(direction)))

	-- Aplicação de força agressiva
	ball.AssemblyLinearVelocity = direction * force * 1.5  -- Aumento adicional de 50%

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = direction * force
	bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	bodyVelocity.Parent = ball
	Debris:AddItem(bodyVelocity, 0.5)

	print("Bola chutada com sucesso!")
	return true
end

return BallModules