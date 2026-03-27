return function(Tab, Context)
	local player = Context.Player
	local ESP_Enabled, Tracers_Enabled, Chams_Enabled, Fullbright_Enabled = false, false, false, false
	local customFovEnabled, customTimeEnabled = false, false
	local customFovValue, customTime = 70, 12
	local defaultFov = 70
	local ESP_Objects = {}
	local settingAmbient = false
	local settingClockTime = false

	local origLighting = {
		Ambient = Context.Lighting.Ambient,
		Brightness = Context.Lighting.Brightness,
		GlobalShadows = Context.Lighting.GlobalShadows,
		ClockTime = Context.Lighting.ClockTime,
		FogEnd = Context.Lighting.FogEnd
	}

	-- ===================================
	Tab:CreateSection("👁️ Радар и Обнаружение")
	-- ===================================
	local EspToggle = Tab:CreateToggle({
		Name = "Player ESP (Боксы, Имя, ХП, Дистанция)",
		CurrentValue = false,
		Flag = "ESP",
		Callback = function(Value) ESP_Enabled = Value end,
	})
	Tab:CreateKeybind({
		Name = "⌨️ Бинд: ESP",
		CurrentKeybind = "",
		HoldToInteract = false,
		Flag = "EspBind",
		Callback = function() EspToggle:Set(not ESP_Enabled) end,
	})

	Tab:CreateToggle({
		Name = "Tracers (Линии до игроков)",
		CurrentValue = false,
		Flag = "Tracers",
		Callback = function(Value) Tracers_Enabled = Value end,
	})

	Tab:CreateToggle({
		Name = "Chams (Подсветка сквозь стены)",
		CurrentValue = false,
		Flag = "Chams",
		Callback = function(Value)
			Chams_Enabled = Value
			if not Value then
				for _, esp in pairs(ESP_Objects) do
					if esp.Highlight.Parent then
						esp.Highlight.Parent = nil
					end
				end
			end
		end,
	})

	-- ===================================
	Tab:CreateSection("🌍 Освещение и Окружение")
	-- ===================================
	local FullbrightToggle = Tab:CreateToggle({
		Name = "Fullbright (Ночное видение)",
		CurrentValue = false,
		Flag = "Fullbright",
		Callback = function(Value)
			Fullbright_Enabled = Value
			if not Value then
				Context.Lighting.Ambient = origLighting.Ambient
				Context.Lighting.Brightness = origLighting.Brightness
				Context.Lighting.GlobalShadows = origLighting.GlobalShadows
				Context.Lighting.ClockTime = origLighting.ClockTime
				Context.Lighting.FogEnd = origLighting.FogEnd
			end
		end,
	})
	Tab:CreateKeybind({
		Name = "⌨️ Бинд: Fullbright",
		CurrentKeybind = "L",
		HoldToInteract = false,
		Flag = "FullbrightBind",
		Callback = function() FullbrightToggle:Set(not Fullbright_Enabled) end,
	})

	Tab:CreateToggle({
		Name = "Заморозить время суток",
		CurrentValue = false,
		Flag = "FreezeTime",
		Callback = function(Value)
			customTimeEnabled = Value
			if not Value then Context.Lighting.ClockTime = origLighting.ClockTime end
		end,
	})

	Tab:CreateSlider({
		Name = "Время суток",
		Range = {0, 24},
		Increment = 0.5,
		Suffix = " ч.",
		CurrentValue = 12,
		Flag = "TimeSlider",
		Callback = function(Value)
			customTime = Value
			if customTimeEnabled then Context.Lighting.ClockTime = customTime end
		end,
	})

	-- ===================================
	Tab:CreateSection("🎥 Камера")
	-- ===================================
	Tab:CreateToggle({
		Name = "Принудительный FOV",
		CurrentValue = false,
		Flag = "FOVToggle",
		Callback = function(Value)
			customFovEnabled = Value
			if not Value then Context.Camera.FieldOfView = defaultFov end
		end,
	})

	Tab:CreateSlider({
		Name = "Field Of View (Угол обзора)",
		Range = {30, 120},
		Increment = 1,
		Suffix = "°",
		CurrentValue = 70,
		Flag = "FOVSlider",
		Callback = function(Value) customFovValue = Value end,
	})

	-- ===================================
	-- ЛОГИКА
	-- ===================================
	table.insert(Context.Connections, Context.Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
		if Fullbright_Enabled and not settingAmbient then
			settingAmbient = true
			Context.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
			Context.Lighting.Brightness = 2
			Context.Lighting.GlobalShadows = false
			Context.Lighting.FogEnd = 100000
			settingAmbient = false
		end
	end))
	table.insert(Context.Connections, Context.Lighting:GetPropertyChangedSignal("ClockTime"):Connect(function()
		if customTimeEnabled and not settingClockTime then
			settingClockTime = true
			Context.Lighting.ClockTime = customTime
			settingClockTime = false
		end
	end))

	local function CreateESP(plr)
		local esp = {
			Box = Drawing.new("Square"),
			Name = Drawing.new("Text"),
			HealthBar = Drawing.new("Line"),
			Tracer = Drawing.new("Line"),
			Highlight = Instance.new("Highlight")
		}
		esp.Box.Thickness, esp.Box.Color, esp.Box.Filled = 1, Color3.fromRGB(255, 255, 255), false
		esp.Name.Size, esp.Name.Center, esp.Name.Outline, esp.Name.Color = 16, true, true, Color3.fromRGB(255, 255, 255)
		esp.HealthBar.Thickness = 2
		esp.Tracer.Thickness, esp.Tracer.Color = 1, Color3.fromRGB(255, 255, 255)

		esp.Highlight.Name = "ChamsHighlight"
		esp.Highlight.FillColor = Color3.fromRGB(255, 0, 0)
		esp.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		esp.Highlight.FillTransparency = 0.5
		esp.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		ESP_Objects[plr] = esp
	end

	local function RemoveESP(plr)
		if ESP_Objects[plr] then
			ESP_Objects[plr].Box:Remove()
			ESP_Objects[plr].Name:Remove()
			ESP_Objects[plr].HealthBar:Remove()
			ESP_Objects[plr].Tracer:Remove()
			if ESP_Objects[plr].Highlight.Parent then ESP_Objects[plr].Highlight:Destroy() end
			ESP_Objects[plr] = nil
		end
	end

	for _, plr in pairs(Context.Players:GetPlayers()) do
		if plr ~= player then CreateESP(plr) end
	end
	table.insert(Context.Connections, Context.Players.PlayerAdded:Connect(function(plr) CreateESP(plr) end))
	table.insert(Context.Connections, Context.Players.PlayerRemoving:Connect(function(plr) RemoveESP(plr) end))

	table.insert(Context.Connections, Context.RunService.RenderStepped:Connect(function()
		if customFovEnabled then Context.Camera.FieldOfView = customFovValue end
		if Fullbright_Enabled and not settingAmbient then
			settingAmbient = true
			Context.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
			Context.Lighting.Brightness = 2
			Context.Lighting.GlobalShadows = false
			Context.Lighting.ClockTime = 14
			Context.Lighting.FogEnd = 100000
			settingAmbient = false
		end

		for plr, esp in pairs(ESP_Objects) do
			local char = plr.Character
			local isValid = char
				and char:FindFirstChild("HumanoidRootPart")
				and char:FindFirstChild("Humanoid")
				and char.Humanoid.Health > 0

			if isValid then
				local hrp, hum = char.HumanoidRootPart, char.Humanoid
				local pos, onScreen = Context.Camera:WorldToViewportPoint(hrp.Position)

				if Chams_Enabled then
					esp.Highlight.Parent = Context.CoreGui
					esp.Highlight.Adornee = char
				else
					esp.Highlight.Parent = nil
				end

				if onScreen then
					local distance = math.floor((Context.Camera.CFrame.Position - hrp.Position).Magnitude)
					local size = Vector2.new(2000 / pos.Z, 3000 / pos.Z)
					local boxPos = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)

					if ESP_Enabled then
						esp.Box.Size, esp.Box.Position, esp.Box.Visible = size, boxPos, true
						esp.Name.Text = string.format("%s [%d]", plr.Name, distance)
						esp.Name.Position, esp.Name.Visible = Vector2.new(pos.X, boxPos.Y - 20), true
						local maxHp = hum.MaxHealth
						local healthPercent = (maxHp > 0) and (hum.Health / maxHp) or 0
						esp.HealthBar.From = Vector2.new(boxPos.X - 5, boxPos.Y + size.Y)
						esp.HealthBar.To = Vector2.new(boxPos.X - 5, boxPos.Y + size.Y - (size.Y * healthPercent))
						esp.HealthBar.Color = Color3.fromRGB(255 - (healthPercent * 255), healthPercent * 255, 0)
						esp.HealthBar.Visible = true
					else
						esp.Box.Visible, esp.Name.Visible, esp.HealthBar.Visible = false, false, false
					end

					if Tracers_Enabled then
						esp.Tracer.From = Vector2.new(Context.Camera.ViewportSize.X / 2, Context.Camera.ViewportSize.Y)
						esp.Tracer.To = Vector2.new(pos.X, pos.Y)
						esp.Tracer.Visible = true
					else
						esp.Tracer.Visible = false
					end
				else
					esp.Box.Visible, esp.Name.Visible, esp.HealthBar.Visible, esp.Tracer.Visible = false, false, false, false
				end
			else
				esp.Box.Visible, esp.Name.Visible, esp.HealthBar.Visible, esp.Tracer.Visible = false, false, false, false
				esp.Highlight.Parent = nil
			end
		end
	end))

	table.insert(Context.Cleanups, function()
		Context.Lighting.Ambient = origLighting.Ambient
		Context.Lighting.Brightness = origLighting.Brightness
		Context.Lighting.GlobalShadows = origLighting.GlobalShadows
		Context.Lighting.ClockTime = origLighting.ClockTime
		Context.Lighting.FogEnd = origLighting.FogEnd
		Context.Camera.FieldOfView = defaultFov
		for plr, esp in pairs(ESP_Objects) do
			esp.Box:Remove()
			esp.Name:Remove()
			esp.HealthBar:Remove()
			esp.Tracer:Remove()
			if esp.Highlight.Parent then esp.Highlight:Destroy() end
			ESP_Objects[plr] = nil
		end
	end)
end
