local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local BallModules = require(ReplicatedStorage:WaitForChild("Modules").BallModules)

-- Utiliza os remotes existentes
local BallEvent = ReplicatedStorage.RemoteEvents.BallEvent
local RequestKick = ReplicatedStorage.RemoteFunctions.RequestKick

-- Configurações
local BALL_NAME = "Football"
local DUMMY_NAME = "TestDummy"
local MAX_DISTANCE = 10
local WELD_OFFSET = CFrame.new(-0.5, -2, -1)
local activeWelds = {}
local AttachDebounce = false

local function attachBall(dummy, ball)
	if activeWelds[ball] then
		print("Bola já está grudada, ignorando attach")
		return 
	end

	print("Criando ServerWeld...")
	local weld = Instance.new("WeldConstraint")
	weld.Name = "ServerWeld"
	weld.Part0 = dummy.HumanoidRootPart
	weld.Part1 = ball
	weld.Parent = ball

	ball.CFrame = dummy.HumanoidRootPart.CFrame * WELD_OFFSET

	activeWelds[ball] = {
		weld = weld,
		dummy = dummy
	}

	print("Bola grudada no servidor!")
	BallEvent:FireAllClients("Attach", dummy, ball)
end

local function detachBall(ball)
	if activeWelds[ball] then
		print("Removendo ServerWeld...")
		activeWelds[ball].weld:Destroy()
		activeWelds[ball] = nil
		BallEvent:FireAllClients("Detach", nil, ball)
		print("Bola solta no servidor!")
	end
end

-- Handler para solicitação de chute
RequestKick.OnServerInvoke = function(player, ball)
	print("Recebido pedido de chute do jogador:", player.Name)
	if activeWelds[ball] then
		detachBall(ball)
		return true
	end
	return false
end

local function cooldown(dummy, ball) 
	print("Bola próxima - grudando...")
	attachBall(dummy, ball)
	task.wait(3)
end

-- Verificação constante de proximidade
RunService.Heartbeat:Connect(function()
	for _, dummy in ipairs(workspace:GetChildren()) do
		if dummy.Name == DUMMY_NAME and dummy:FindFirstChild("HumanoidRootPart") then
			local ball = workspace:FindFirstChild(BALL_NAME)
			if ball then
				local distance = (dummy.HumanoidRootPart.Position - ball.Position).Magnitude
				if distance <= MAX_DISTANCE and not activeWelds[ball] then
					cooldown(dummy, ball)
				end
			end
		end
	end
end)



-- Limpeza ao fechar
game:BindToClose(function()
	for ball, data in pairs(activeWelds) do
		data.weld:Destroy()
	end
end)

