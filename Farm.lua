return function(Tab, Context)
    -- Настройки
    local Config = {
        AutoMine = false,
        VisualsEnabled = false,
        SelectedOres = {}, -- Теперь здесь таблица для нескольких руд
        OresFolder = workspace, -- Укажи папку, например workspace.Ores
        ToolName = "Pickaxe",
        DistanceToMine = 5
    }

    local OreTypes = {"Tin", "Iron", "Copper", "Gold", "Diamond"}
    local ActiveBoxESP = {} -- Хранилище для созданных рамок

    -- Функция для очистки всей подсветки
    local function ClearESP()
        for _, box in pairs(ActiveBoxESP) do
            box:Destroy()
        end
        ActiveBoxESP = {}
    end

    -- Функция для создания рамки (Box ESP)
    local function CreateBox(object)
        if not object:IsA("BasePart") then return end
        
        local box = Instance.new("SelectionBox")
        box.Name = "OreHighlight"
        box.Adornee = object
        box.Color3 = Color3.fromRGB(255, 255, 255) -- Белый цвет по умолчанию
        box.LineThickness = 0.05
        box.Parent = Context.CoreGui -- Помещаем в CoreGui, чтобы игрок видел сквозь стены
        
        table.insert(ActiveBoxESP, box)
    end

    -- Функция обновления визуалов
    local function UpdateVisuals()
        ClearESP()
        if not Config.VisualsEnabled then return end

        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            -- Проверяем, входит ли название руды в наш список выбранных
            if table.find(Config.SelectedOres, item.Name) and item:IsA("BasePart") then
                CreateBox(item)
            end
        end
    end

    -- Интерфейс
    Tab:CreateSection("Настройки Авто-Фарма")

    Tab:CreateDropdown({
        Name = "Выбор руд (Множественный)",
        Options = OreTypes,
        CurrentOption = {},
        MultipleOptions = true, -- ВКЛЮЧАЕМ МНОЖЕСТВЕННЫЙ ВЫБОР
        Flag = "OreSelector",
        Callback = function(Options)
            Config.SelectedOres = Options
            UpdateVisuals() -- Обновляем рамки при смене выбора
        end,
    })

    Tab:CreateToggle({
        Name = "Подсветка выбранных руд (Box)",
        CurrentValue = false,
        Flag = "EspToggle",
        Callback = function(Value)
            Config.VisualsEnabled = Value
            UpdateVisuals()
        end,
    })

    Tab:CreateToggle({
        Name = "Включить Авто-Фарм",
        CurrentValue = false,
        Flag = "AutoFarmToggle",
        Callback = function(Value)
            Config.AutoMine = Value
            
            if Value then
                task.spawn(function()
                    while Config.AutoMine do
                        local player = Context.Player
                        local character = player.Character or player.CharacterAdded:Wait()
                        local rootPart = character:WaitForChild("HumanoidRootPart")
                        
                        local closestOre = nil
                        local shortestDistance = math.huge

                        -- Поиск ближайшей из ВЫБРАННЫХ руд
                        for _, item in pairs(Config.OresFolder:GetDescendants()) do
                            if table.find(Config.SelectedOres, item.Name) and item:IsA("BasePart") then
                                local distance = (rootPart.Position - item.Position).Magnitude
                                if distance < shortestDistance then
                                    closestOre = item
                                    shortestDistance = distance
                                end
                            end
                        end

                        if closestOre then
                            -- Логика телепортации и копания
                            rootPart.CFrame = closestOre.CFrame * CFrame.new(0, Config.DistanceToMine, 0)
                            
                            local tool = player.Backpack:FindFirstChild(Config.ToolName) or character:FindFirstChild(Config.ToolName)
                            if tool then 
                                character.Humanoid:EquipTool(tool)
                                tool:Activate()
                            end
                        end
                        task.wait(0.3)
                    end
                end)
            end
        end,
    })
end
