return function(Tab, Context)
	-- ===================================
	Tab:CreateSection("🌐 Управление сервером")
	-- ===================================
	Tab:CreateButton({
		Name = "🔄 Быстрый перезаход (Rejoin)",
		Callback = function()
			Context.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Context.Player)
		end,
	})

	Tab:CreateButton({
		Name = "🌐 Сменить сервер (Server Hopper)",
		Callback = function()
			local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
			local success, result = pcall(function() return Context.HttpService:JSONDecode(game:HttpGet(url)) end)
			
			if success and result and result.data then
				for _, server in ipairs(result.data) do
					if type(server) == "table" and server.playing < server.maxPlayers and server.id ~= game.JobId then
						Context.TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Context.Player)
						break
					end
				end
			end
		end,
	})
end
