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
	local function GetSelectedTarget()
		if not selectedPlayer then
			warn("Цель не выбрана")
			return nil
		end
		local target = Context.Players:FindFirstChild(selectedPlayer)
		if not target then
			warn("Игрок " .. selectedPlayer .. " не найден на сервере")
			return nil
		end
		return target
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
			local target = GetSelectedTarget()
			if not target then return end

			if not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
				warn("Персонаж игрока " .. selectedPlayer .. " недоступен")
				return
			end

			if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
				warn("Ваш персонаж недоступен")
				return
			end

			local ok, err = pcall(function()
				player.Character.HumanoidRootPart.CFrame =
					target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
			end)
			if not ok then warn("Телепорт провалился: " .. tostring(err)) end
		end,
	})

	Tab:CreateButton({
		Name = "Наблюдать (Spectate)",
		Callback = function()
			local target = GetSelectedTarget()
			if not target then return end

			if not target.Character or not target.Character:FindFirstChild("Humanoid") then
				warn("Персонаж игрока " .. selectedPlayer .. " недоступен")
				return
			end

			Context.Camera.CameraSubject = target.Character.Humanoid
		end,
	})

	Tab:CreateButton({
		Name = "Остановить наблюдение",
		Callback = function()
			if player.Character and player.Character:FindFirstChild("Humanoid") then
				Context.Camera.CameraSubject = player.Character.Humanoid
			else
				warn("Не удалось вернуть камеру: персонаж недоступен")
			end
		end,
	})

	table.insert(Context.Cleanups, function()
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			Context.Camera.CameraSubject = player.Character.Humanoid
		end
	end)
end
