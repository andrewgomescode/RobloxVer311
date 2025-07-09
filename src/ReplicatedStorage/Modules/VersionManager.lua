local VersionManager = {}

VersionManager.CurrentVersion = "1.0.0"
VersionManager.MinimumSupportedVersion = "1.0.0"

-- Version migration functions
VersionManager.Migrations = {
	["1.0.0_to_1.1.0"] = function(data)
		-- Example migration: Add new field
		if not data.achievements then
			data.achievements = {}
		end
		data.version = "1.1.0"
		return data
	end,
	["1.1.0_to_1.2.0"] = function(data)
		-- Example migration: Convert card format
		if data.cards and type(data.cards[1]) == "string" then
			local newCards = {}
			for _, cardId in ipairs(data.cards) do
				newCards[cardId] = 1
			end
			data.cards = newCards
		end
		data.version = "1.2.0"
		return data
	end
}

function VersionManager:CompareVersions(v1, v2)
	local v1Parts = {}
	local v2Parts = {}

	for part in string.gmatch(v1, "%d+") do
		table.insert(v1Parts, tonumber(part))
	end

	for part in string.gmatch(v2, "%d+") do
		table.insert(v2Parts, tonumber(part))
	end

	for i = 1, math.max(#v1Parts, #v2Parts) do
		local p1 = v1Parts[i] or 0
		local p2 = v2Parts[i] or 0

		if p1 < p2 then return -1 end
		if p1 > p2 then return 1 end
	end

	return 0
end

function VersionManager:MigrateData(data)
	local currentDataVersion = data.version or "1.0.0"

	-- Check if version is supported
	if self:CompareVersions(currentDataVersion, self.MinimumSupportedVersion) < 0 then
		return nil, "Version too old, data reset required"
	end

	-- Apply migrations sequentially
	while self:CompareVersions(currentDataVersion, self.CurrentVersion) < 0 do
		local migrationFound = false

		for migrationKey, migrationFunc in pairs(self.Migrations) do
			local fromVersion = string.match(migrationKey, "(.+)_to_")
			local toVersion = string.match(migrationKey, "_to_(.+)")

			if fromVersion == currentDataVersion then
				data = migrationFunc(data)
				currentDataVersion = toVersion
				migrationFound = true
				break
			end
		end

		if not migrationFound then
			return nil, "No migration path found"
		end
	end

	return data, nil
end

return VersionManager