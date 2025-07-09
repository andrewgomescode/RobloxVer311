local clickDetector = script.Parent:FindFirstChildOfClass("ClickDetector")

clickDetector.MouseHoverEnter:Connect(function(player)
	print(player.Name .. " hovered over my parent!")
end)

clickDetector.MouseHoverLeave:Connect(function(player)
	print(player.Name .. " hovered off my parent!")
end)