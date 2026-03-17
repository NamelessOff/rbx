return function(Tab, Context)
    local player = Context.Player
    local BASE_SPEED = 16
    local noclipEnabled, infJumpEnabled, waterWalkEnabled = false, false, false
    local flyEnabled, flySpeed = false, 50
    local flyingKeys = {W = false, A = false, S = false, D = false, Space = false, LeftControl = false}
    local flyBodyVelocity, flyBodyGyro

    local waterPart = Instance.new("Part")
    waterPart.Size = Vector3.new(5, 1, 5)
    waterPart.Transparency = 1
    waterPart.Anchored = true
    waterPart.CanCollide = true

    Tab:CreateInput({
        Name = "Множитель скорости",
        PlaceholderText = "Например: 1.5",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text)
            local char = player.Character
            if char and char:FindFirstChildOfClass("Humanoid") then
                local mult = tonumber(Text)
                if mult then char:FindFirstChildOfClass("Humanoid").WalkSpeed = BASE_SPEED * mult end
            end
        end,
    })

    local FlyToggle = Tab:CreateToggle({
        Name = "Полет (Fly)",
        CurrentValue = false,
        Flag = "FlyToggle",
        Callback = function(Value) flyEnabled = Value end,
    })
    Tab:CreateKeybind({
        Name = "⌨️ Бинд: Полет",
        CurrentKeybind = "F",
        HoldToInteract = false,
        Flag = "FlyBind",
        Callback = function() FlyToggle:Set(not flyEnabled) end,
    })

    Tab:CreateSlider({
        Name = "Скорость полета",
        Range = {10, 500},
        Increment = 5,
        Suffix = " ед.",
        CurrentValue = 50,
        Flag = "FlySpeed",
        Callback = function(Value) flySpeed = Value end,
    })

    local NoclipToggle = Tab:CreateToggle({
        Name = "No-Clip (Проход сквозь стены)",
        CurrentValue = false,
        Flag = "Noclip", 
        Callback = function(Value) noclipEnabled = Value end,
    })
    Tab:CreateKeybind({
        Name = "⌨️ Бинд: No-Clip",
        CurrentKeybind = "N",
        HoldToInteract = false,
        Flag = "NoclipBind",
        Callback = function() NoclipToggle:Set(not noclipEnabled) end,
    })

    local InfJumpToggle = Tab:CreateToggle({
        Name = "Бесконечный прыжок",
        CurrentValue = false,
        Flag = "InfJump", 
        Callback = function(Value) infJumpEnabled = Value end,
    })
    Tab:CreateKeybind({
        Name = "⌨️ Бинд: Бесконечный прыжок",
        CurrentKeybind = "",
        HoldToInteract = false,
        Flag = "InfJumpBind",
        Callback = function() InfJumpToggle:Set(not infJumpEnabled) end,
    })

    local WaterWalkToggle = Tab:CreateToggle({
        Name = "Water Walker (Хождение по воде)",
        CurrentValue = false,
        Flag = "WaterWalk",
        Callback = function(Value) 
            waterWalkEnabled = Value 
            if not Value then waterPart.Parent = nil end
        end,
    })

    -- Сохраняем слайдер в переменную
    local GravitySlider = Tab:CreateSlider({
        Name = "Управление гравитацией",
        Range = {0, 500},
        Increment = 1,
        Suffix = " Grav",
        CurrentValue = 196.2,
        Flag = "Gravity",
        Callback = function(Value) workspace.Gravity = Value end,
    })

    -- Добавляем кнопку сброса гравитации
    Tab:CreateButton({
        Name = "Сбросить гравитацию (По умолчанию)",
        Callback = function()
            workspace.Gravity = 196.2
            GravitySlider:Set(196.2) -- Визуально возвращаем ползунок на место
        end,
    })

    table.insert(Context.Connections, Context.UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.W then flyingKeys.W = true
        elseif input.KeyCode == Enum.KeyCode.A then flyingKeys.A = true
        elseif input.KeyCode == Enum.KeyCode.S then flyingKeys.S = true
        elseif input.KeyCode == Enum.KeyCode.D then flyingKeys.D = true
        elseif input.KeyCode == Enum.KeyCode.Space then flyingKeys.Space = true
        elseif input.KeyCode == Enum.KeyCode.LeftControl then flyingKeys.LeftControl = true end
    end))

    table.insert(Context.Connections, Context.UserInputService.InputEnded:Connect(function(input, gpe)
        if input.KeyCode == Enum.KeyCode.W then flyingKeys.W = false
        elseif input.KeyCode == Enum.KeyCode.A then flyingKeys.A = false
        elseif input.KeyCode == Enum.KeyCode.S then flyingKeys.S = false
        elseif input.KeyCode == Enum.KeyCode.D then flyingKeys.D = false
        elseif input.KeyCode == Enum.KeyCode.Space then flyingKeys.Space = false
        elseif input.KeyCode == Enum.KeyCode.LeftControl then flyingKeys.LeftControl = false end
    end))

    local function StartFly(hrp)
        if hrp:FindFirstChild("FlyBV") then hrp.FlyBV:Destroy() end
        if hrp:FindFirstChild("FlyBG") then hrp.FlyBG:Destroy() end
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVelocity.Velocity = Vector3.zero
        flyBodyVelocity.Name = "FlyBV"
        flyBodyVelocity.Parent = hrp
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyGyro.P = 9e4
        flyBodyGyro.CFrame = Context.Camera.CFrame
        flyBodyGyro.Name = "FlyBG"
        flyBodyGyro.Parent = hrp
    end

    local function StopFly()
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            if hrp:FindFirstChild("FlyBV") then hrp.FlyBV:Destroy() end
            if hrp:FindFirstChild("FlyBG") then hrp.FlyBG:Destroy() end
        end
        if char and char:FindFirstChildOfClass("Humanoid") then
            char.Humanoid.PlatformStand = false
        end
        flyBodyVelocity = nil
        flyBodyGyro = nil
    end

    table.insert(Context.Connections, Context.RunService.Stepped:Connect(function()
        local char = player.Character
        if not char then return end

        if flyEnabled and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
            local hrp = char.HumanoidRootPart
            local hum = char:FindFirstChildOfClass("Humanoid")
            hum.PlatformStand = true
            if not flyBodyVelocity or not flyBodyVelocity.Parent then StartFly(hrp) end

            local moveDir = Vector3.zero
            if flyingKeys.W then moveDir = moveDir + Context.Camera.CFrame.LookVector end
            if flyingKeys.S then moveDir = moveDir - Context.Camera.CFrame.LookVector end
            if flyingKeys.A then moveDir = moveDir - Context.Camera.CFrame.RightVector end
            if flyingKeys.D then moveDir = moveDir + Context.Camera.CFrame.RightVector end
            if flyingKeys.Space then moveDir = moveDir + Vector3.new(0, 1, 0) end
            if flyingKeys.LeftControl then moveDir = moveDir + Vector3.new(0, -1, 0) end

            if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end
            flyBodyVelocity.Velocity = moveDir * flySpeed
            flyBodyGyro.CFrame = Context.Camera.CFrame
        elseif not flyEnabled and flyBodyVelocity then
            StopFly()
        end

        if noclipEnabled then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
            end
        end

        if waterWalkEnabled and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local rayInfo = RaycastParams.new()
            rayInfo.FilterDescendantsInstances = {char, waterPart}
            rayInfo.FilterType = Enum.RaycastFilterType.Exclude

            local result = workspace:Raycast(hrp.Position, Vector3.new(0, -5, 0), rayInfo)
            if result and result.Material == Enum.Material.Water then
                waterPart.Parent = workspace
                waterPart.Position = Vector3.new(hrp.Position.X, result.Position.Y - 0.5, hrp.Position.Z)
            else
                waterPart.Parent = nil
            end
        end
    end))

    table.insert(Context.Connections, Context.UserInputService.JumpRequest:Connect(function()
        if infJumpEnabled and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))
    
    -- Добавляем очистку для этого модуля при закрытии
    table.insert(Context.Cleanups, function()
        workspace.Gravity = 196.2
        StopFly()
        waterPart:Destroy()
    end)
end
