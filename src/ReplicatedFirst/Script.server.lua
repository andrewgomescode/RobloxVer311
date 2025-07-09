local Card = {}

Card.__index = Card

local cardTemplate = game.ReplicatedStorage.Objects.CardTemplate

function Card:GetCard(id)
	local newCard = {}
	return newCard
end

return Card