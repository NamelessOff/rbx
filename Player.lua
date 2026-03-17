return function(Tab, Context)
	local player = Context.Player
	local selectedPlayer = nil

	local function GetPlayerNames()
		local names = {}
		for _, v in pairs(Context.Players:GetPlayers()) do
			if v ~= player then table.insert(names, v.Name) end
		end
		return names
	end

	-- ===================================
	Tab:CreateSection("🎯 Выбор цели")
	-- ===================================
	local PlayerDropdown = Tab:CreateDropdown({
		Name = "Выберите игрока",
		Options = GetPlayerNames(),
		CurrentOption = "",
		MultipleOptions = false,
		Callback = function(Option) selectedPlayer = Option[1] end,
	})

	Tab:CreateButton({
		Name = "🔄 Обновить список игроков",
		Callback = function() PlayerDropdown:Refresh(GetPlayerNames(), true) end,
	})

	-- ===================================
	Tab:CreateSection("🏃 Действия")
	-- ===================================
	Tab:CreateButton({
		Name = "Телепорт к игроку (Ему за спину)",
		Callback = function()
			if selectedPlayer then
				local target = Context.Players:FindFirstChild(selectedPlayer)
				if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and player.Character then
					player.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
				end
			end
		end,
	})

	Tab:CreateButton({
		Name = "Наблюдать (Spectate)",
		Callback = function()
			if selectedPlayer then
				local target = Context.Players:FindFirstChild(selectedPlayer)
				if target and target.Character and target.Character:FindFirstChild("Humanoid") then
					Context.Camera.CameraSubject = target.Character.Humanoid
				end
			end
		end,
	})

	Tab:CreateButton({
		Name = "Остановить наблюдение",
		Callback = function()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				Context.Camera.CameraSubject = player.Character.Humanoid
			end
		end,
	})
	
	table.insert(Context.Cleanups, function()
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			Context.Camera.CameraSubject = player.Character.Humanoid
		end
	end)
end
