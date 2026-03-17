return function(Tab, Context)
	local player = Context.Player
	local camlockEnabled, isAiming = false, false
	local camlockTarget = nil
	local autoclickerEnabled, flingEnabled = false, false
	local autoclickerDelay = 10 

	-- ===================================
	Tab:CreateSection("🎯 Помощь в стрельбе")
	-- ===================================
	local CamlockToggle = Tab:CreateToggle({
		Name = "Aimbot / Camlock (Зажать ПКМ)",
		CurrentValue = false,
		Flag = "Camlock",
		Callback = function(Value) camlockEnabled = Value end,
	})
	Tab:CreateKeybind({
		Name = "⌨️ Бинд: Aimbot",
		CurrentKeybind = "",
		HoldToInteract = false,
		Flag = "CamlockBind",
		Callback = function() CamlockToggle:Set(not camlockEnabled) end,
	})

	-- ===================================
	Tab:CreateSection("⚙️ Автоматизация")
	-- ===================================
	local AutoClickToggle = Tab:CreateToggle({
		Name = "Auto-Clicker",
		CurrentValue = false,
		Flag = "AutoClick",
		Callback = function(Value) autoclickerEnabled = Value end,
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
	local FlingToggle = Tab:CreateToggle({
		Name = "Смертельное вращение (Fling)",
		CurrentValue = false,
		Flag = "FlingToggle",
		Callback = function(Value) 
			flingEnabled = Value 
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				if Value then
					local bav = Instance.new("BodyAngularVelocity")
					bav.Name = "FlingBAV"
					bav.AngularVelocity = Vector3.new(0, 99999, 0)
					bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
					bav.P = 100000
					bav.Parent = char.HumanoidRootPart
				else
					for _, v in pairs(char.HumanoidRootPart:GetChildren()) do
						if v.Name == "FlingBAV" then v:Destroy() end
					end
				end
			end
		end,
	})
	Tab:CreateKeybind({
		Name = "⌨️ Бинд: Fling",
		CurrentKeybind = "",
		HoldToInteract = false,
		Flag = "FlingBind",
		Callback = function() FlingToggle:Set(not flingEnabled) end,
	})

	-- Логика (остается без изменений)
	local function GetClosestPlayerToCursor()
		local mousePos = Context.UserInputService:GetMouseLocation()
		local closestDist = math.huge
		local target = nil

		for _, p in pairs(Context.Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
				local pos, onScreen = Context.Camera:WorldToViewportPoint(p.Character.Head.Position)
				if onScreen then
					local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
					if dist < closestDist then
						closestDist = dist
						target = p.Character.Head
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

	table.insert(Context.Connections, Context.UserInputService.InputEnded:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			isAiming = false
			camlockTarget = nil
		end
	end))

	table.insert(Context.Connections, Context.RunService.RenderStepped:Connect(function()
		if isAiming and camlockTarget and camlockEnabled then 
			Context.Camera.CFrame = CFrame.new(Context.Camera.CFrame.Position, camlockTarget.Position) 
		end
	end))

	task.spawn(function()
		while true do
			task.wait(autoclickerDelay / 1000)
			if autoclickerEnabled then
				Context.VirtualUser:CaptureController()
				Context.VirtualUser:ClickButton1(Vector2.new())
			end
		end
	end)
	
	table.insert(Context.Cleanups, function()
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			for _, v in pairs(char.HumanoidRootPart:GetChildren()) do
				if v.Name == "FlingBAV" then v:Destroy() end
			end
		end
	end)
end
