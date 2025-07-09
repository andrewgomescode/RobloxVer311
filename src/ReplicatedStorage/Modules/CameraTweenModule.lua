-- ModuleScript in ReplicatedStorage.Modules.CameraTweenModule
local TweenService = game:GetService("TweenService")

local CameraTweenHandler = {}

-- Tween the camera to a new position
function CameraTweenHandler.TweenCamera(camera, targetPos, targetLookAt, duration)
	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out,
		0,
		false,
		0
	)

	local goal = {}
	goal.CFrame = CFrame.new(targetPos, targetLookAt)

	local tween = TweenService:Create(camera, tweenInfo, goal)
	tween:Play()

	return tween
end

-- Reset camera to default
function CameraTweenHandler.ResetCamera(camera)
	camera.CameraType = Enum.CameraType.Custom
end

return CameraTweenHandler