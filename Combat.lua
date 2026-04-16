return function(Tab, Context)
	local player = Context.Player
	local camlockEnabled, isAiming = false, false
	local camlockTarget = nil
	local autoclickerEnabled = false
	local autoclickerDelay = 10
	local flingEnabled = false
	local autoclickerRunning = true
	local CAMLOCK_MAX_DISTANCE = 150
	local legitModeEnabled = false
	local camlockSmoothness = 5

	-- ===================================
	Tab:CreateSection("🎯 Помощь в стрельбе")
	-- ===================================
	local CamlockToggle = Tab:CreateToggle({
		Name = "Aimbot / Camlock (Зажать ПКМ)",
		CurrentValue = false,
		Flag = "Camlock",
		Callback = function(Value)
			camlockEnabled = Value
			if not Value then
				isAiming = false
				camlockTarget = nil
			end
		end,
	})
	Tab:CreateKeybind({
		Name = "⌨️ Бинд: Aimbot",
		CurrentKeybind = "",
		HoldToInteract = false,
		Flag = "CamlockBind",
		Callback = function() CamlockToggle:Set(not camlockEnabled) end,
	})

	Tab:CreateToggle({
		Name = "Legit Mode (Сглаживание + Без стен)",
		CurrentValue = false,
		Flag = "LegitMode",
		Callback = function(Value) legitModeEnabled = Value end,
	})

	Tab:CreateSlider({
		Name = "Скорость наводки (Legit Mode)",
		Range = {1, 10},
		Increment = 1,
		Suffix = " ед.",
		CurrentValue = 5,
		Flag = "Smoothness",
		Callback = function(Value) camlockSmoothness = Value end,
	})

	-- ===================================
	Tab:CreateSection("⚙️ Автоматизация")
	-- ===================================
	local AutoClickToggle = Tab:CreateToggle({
		Name = "Auto-Clicker",
		CurrentValue = false,
		Flag = "AutoClick",
		Callback = function(Value)
			autoclickerEnabled = Value
			if Value then
				Context.VirtualUser:CaptureController()
			end
		end,
	})
	Tab:CreateSlider({
		Name = "Задержка кликера",
		Range = {1, 1000},
		Increment = 10,
		Suffix = " мс",
		CurrentValue = 10,
		Flag = "ClickDelay",
		Callback = function(Value) autoclickerDelay = Value end,
	})
	Tab:CreateKeybind({
		Name = "⌨️ Бинд: Auto-Clicker",
		CurrentKeybind = "",
		HoldToInteract = false,
		Flag = "AutoClickBind",
		Callback = function() AutoClickToggle:Set(not autoclickerEnabled) end,
	})

	-- ===================================
	Tab:CreateSection("💀 Троллинг")
	-- ===================================
	local function StartFling()
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hrp = char.HumanoidRootPart
			if not hrp:FindFirstChild("FlingBAV") then
				local bav = Instance.new("BodyAngularVelocity")
				bav.Name = "FlingBAV"
				bav.AngularVelocity = Vector3.new(0, 99999, 0)
				bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
				bav.P = 100000
				bav.Parent = hrp
			end
		end
	end

	local function StopFling()
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			for _, v in pairs(char.HumanoidRootPart:GetChildren()) do
				if v.Name == "FlingBAV" then v:Destroy() end
			end
		end
	end

	local FlingToggle = Tab:CreateToggle({
		Name = "Смертельное вращение (Fling)",
		CurrentValue = false,
		Flag = "FlingToggle",
		Callback = function(Value)
			flingEnabled = Value
			if Value then StartFling() else StopFling() end
		end,
	})
	Tab:CreateKeybind({
		Name = "⌨️ Бинд: Fling",
		CurrentKeybind = "",
		HoldToInteract = false,
		Flag = "FlingBind",
		Callback = function() FlingToggle:Set(not flingEnabled) end,
	})
	table.insert(Context.Connections, player.CharacterAdded:Connect(function()
		if flingEnabled then
			task.wait(0.5)
			StartFling()
		end
	end))

	-- ===================================
	-- ЛОГИКА
	-- ===================================
	local function GetClosestPlayerToCursor()
		local mousePos = Context.UserInputService:GetMouseLocation()
		local closestDist = CAMLOCK_MAX_DISTANCE
		local target = nil

		for _, p in pairs(Context.Players:GetPlayers()) do
			if p ~= player
				and p.Character
				and p.Character:FindFirstChild("Head")
				and p.Character:FindFirstChild("Humanoid")
				and p.Character.Humanoid.Health > 0
			then
				local pos, onScreen = Context.Camera:WorldToViewportPoint(p.Character.Head.Position)
				if onScreen then
					local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
					if dist < closestDist then
						local isVisible = true
						if legitModeEnabled then
							local rayInfo = RaycastParams.new()
							rayInfo.FilterDescendantsInstances = {player.Character, p.Character}
							rayInfo.FilterType = Enum.RaycastFilterType.Exclude
							local rayDir = p.Character.Head.Position - Context.Camera.CFrame.Position
							local result = workspace:Raycast(Context.Camera.CFrame.Position, rayDir, rayInfo)
							if result then isVisible = false end
						end

						if isVisible then
							closestDist = dist
							target = p.Character.Head
						end
					end
				end
			end
		end
		return target
	end

	table.insert(Context.Connections, Context.UserInputService.InputBegan:Connect(function(input, gpe)
		if not gpe and input.UserInputType == Enum.UserInputType.MouseButton2 and camlockEnabled then
			isAiming = true
			camlockTarget = GetClosestPlayerToCursor()
		end
	end))

	table.insert(Context.Connections, Context.UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isAiming = false
			camlockTarget = nil
		end
	end))

	table.insert(Context.Connections, Context.RunService.RenderStepped:Connect(function(deltaTime)
		if isAiming and camlockEnabled and camlockTarget and camlockTarget.Parent then
			local currentCFrame = Context.Camera.CFrame
			local targetCFrame = CFrame.new(currentCFrame.Position, camlockTarget.Position)
			if legitModeEnabled then
				local alpha = math.clamp((camlockSmoothness / 10) * deltaTime * 20, 0.01, 1)
				Context.Camera.CFrame = currentCFrame:Lerp(targetCFrame, alpha)
			else
				Context.Camera.CFrame = targetCFrame
			end
		else
			if isAiming and not (camlockTarget and camlockTarget.Parent) then
				camlockTarget = nil
			end
		end
	end))
	task.spawn(function()
		while autoclickerRunning do
			task.wait(autoclickerDelay / 1000)
			if autoclickerEnabled then
				Context.VirtualUser:ClickButton1(Vector2.new())
			end
		end
	end)

	table.insert(Context.Cleanups, function()
		autoclickerRunning = false
		autoclickerEnabled = false
		camlockEnabled = false
		isAiming = false
		camlockTarget = nil
		flingEnabled = false
		StopFling()
	end)
end
