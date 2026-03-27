return function(Tab, Context)
	-- ===================================
	Tab:CreateSection("🌐 Управление сервером")
	-- ===================================
	Tab:CreateButton({
		Name = "🔄 Быстрый перезаход (Rejoin)",
		Callback = function()
			local ok, err = pcall(function()
				Context.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Context.Player)
			end)
			if not ok then
				warn("Rejoin failed: " .. tostring(err))
			end
		end,
	})

	Tab:CreateButton({
		Name = "🌐 Сменить сервер (Server Hopper)",
		Callback = function()
			local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
			local httpOk, raw = pcall(function() return game:HttpGet(url) end)
			if not httpOk then
				warn("Server Hopper: HTTP запрос провалился: " .. tostring(raw))
				return
			end

			local parseOk, result = pcall(function() return Context.HttpService:JSONDecode(raw) end)
			if not parseOk or not result or not result.data then
				warn("Server Hopper: не удалось разобрать ответ сервера")
				return
			end

			local found = false
			for _, server in ipairs(result.data) do
				if type(server) == "table" and server.playing < server.maxPlayers and server.id ~= game.JobId then
					local teleportOk, teleportErr = pcall(function()
						Context.TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Context.Player)
					end)
					if teleportOk then
						found = true
						break
					else
						warn("Server Hopper: телепорт провалился: " .. tostring(teleportErr))
					end
				end
			end

			if not found then
				warn("Server Hopper: свободный сервер не найден")
			end
		end,
	})
end
