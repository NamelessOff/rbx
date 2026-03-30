return function(Tab, Context)
    local Config = {
        AutoMine = false,
        VisualsEnabled = false,
        SelectedOres = {}, 
        OresFolder = workspace, -- Убедись, что папка указана верно
        ToolName = "Pickaxe",
        DistanceToMine = 5
    }

    local OreTypes = {} 
    local ActiveBoxESP = {} 
    local OreDropdown 

    -- Очистка ESP
    local function ClearESP()
        for _, box in pairs(ActiveBoxESP) do
            if box then box:Destroy() end
        end
        ActiveBoxESP = {}
    end

    -- УМНОЕ СКАНЕРОВАНИЕ
    local function ScanForOres()
        print("------------------------------------------")
        print("[Partner Log]: Начало умного сканирования...")
        
        local foundNames = {} 
        local newOptions = {} 
        
        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            if item:IsA("BasePart") then
                local name = item.Name
                local parentName = item.Parent and item.Parent.Name or ""
                
                -- Проверяем, есть ли "Ore" в имени парта или его родителя
                -- if string.find(string.lower(name), "ore") or string.find(string.lower(parentName), "ore") then
                    
                    -- Если сам парт называется безлико (напр. OreMesh), берем имя родителя
                    local displayName = name
                    if name == "OreMesh" or name == "Part" or name == "MeshPart" then
                        displayName = parentName
                    end

                    -- Добавляем в список только уникальные красивые названия
                    if not foundNames[displayName] and displayName ~= "" then
                        foundNames[displayName] = true
                        table.insert(newOptions, displayName)
                        print("[Partner Log]: Найдена категория: " .. displayName)
                    end
                -- end
            end
        end

        OreTypes = newOptions
        if OreDropdown then
            OreDropdown:Refresh(OreTypes, false)
            print("[Partner Log]: Меню обновлено. Найдено типов: " .. #OreTypes)
        end
    end

    -- ФУНКЦИЯ ОБНОВЛЕНИЯ ВИЗУАЛОВ
    local function UpdateVisuals()
        ClearESP()
        if not Config.VisualsEnabled then return end

        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            if item:IsA("BasePart") then
                local name = item.Name
                local parentName = item.Parent and item.Parent.Name or ""
                
                -- Проверяем: совпадает ли имя парта ИЛИ имя родителя с выбранным в списке
                local isSelected = table.find(Config.SelectedOres, name) or table.find(Config.SelectedOres, parentName)

                if isSelected then
                    local box = Instance.new("SelectionBox")
                    box.Name = "Partner_ESP_Box"
                    box.Adornee = item
                    box.Color3 = Color3.fromRGB(0, 255, 255)
                    box.LineThickness = 0.05
                    box.Parent = Context.CoreGui
                    table.insert(ActiveBoxESP, box)
                end
            end
        end
    end

    -- (Далее идет остальной код интерфейса: создание кнопок и Dropdown)
    -- Не забудь использовать OreDropdown:Refresh(OreTypes, false) вместо SetOptions
    
    -- Пример создания Dropdown:
    Tab:CreateSection("Поиск")
    Tab:CreateButton({
        Name = "🔍 Сканировать руды",
        Callback = ScanForOres
    })

    OreDropdown = Tab:CreateDropdown({
        Name = "Выберите руды",
        Options = OreTypes,
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "OreSelector",
        Callback = function(Options)
            Config.SelectedOres = Options
            UpdateVisuals()
        end,
    })

    Tab:CreateToggle({
        Name = "Подсветка (Box)",
        CurrentValue = false,
        Flag = "EspToggle",
        Callback = function(Value)
            Config.VisualsEnabled = Value
            UpdateVisuals()
        end,
    })
    
    task.spawn(ScanForOres)
end
