return function(Tab, Context)
    -- Настройки
    local Config = {
        AutoMine = false,
        VisualsEnabled = false,
        SelectedOres = {}, 
        OresFolder = workspace, -- Убедись, что тут указана верная папка
        ToolName = "Pickaxe",
        DistanceToMine = 5
    }

    local OreTypes = {} -- Список будет заполнен динамически
    local ActiveBoxESP = {} 
    local OreDropdown -- Переменная для хранения ссылки на объект выпадающего меню

    -- Функция очистки ESP
    local function ClearESP()
        for _, box in pairs(ActiveBoxESP) do
            if box then box:Destroy() end
        end
        ActiveBoxESP = {}
    end

    -- Функция сканирования карты на наличие руд
    local function ScanOres()
        print("[Partner Log]: Начинаю сканирование руд...")
        local foundOres = {}
        local count = 0

        -- Проходим по всем объектам в папке руд
        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            -- Условие: объект должен быть Part и его еще нет в списке
            if item:IsA("BasePart") and not table.find(foundOres, item.Name) then
                table.insert(foundOres, item.Name)
                count = count + 1
                print("[Partner Log]: Найдена новая руда: " .. item.Name)
            end
        end

        OreTypes = foundOres
        
        -- Обновляем Dropdown в интерфейсе, если он уже создан
        if OreDropdown then
            OreDropdown:SetOptions(OreTypes)
            print("[Partner Log]: Список в меню обновлен. Всего видов: " .. count)
        end
        
        return foundOres
    end

    -- Функция создания Box ESP
    local function CreateBox(object)
        if not object:IsA("BasePart") then return end
        local box = Instance.new("SelectionBox")
        box.Name = "OreHighlight"
        box.Adornee = object
        box.Color3 = Color3.fromRGB(0, 255, 255) -- Бирюзовый цвет для видимости
        box.LineThickness = 0.05
        box.Parent = Context.CoreGui 
        table.insert(ActiveBoxESP, box)
    end

    -- Функция обновления визуалов
    local function UpdateVisuals()
        ClearESP()
        if not Config.VisualsEnabled then return end

        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            if table.find(Config.SelectedOres, item.Name) and item:IsA("BasePart") then
                CreateBox(item)
            end
        end
    end

    -- ИНТЕРФЕЙС
    Tab:CreateSection("Сканирование")

    Tab:CreateButton({
        Name = "Сканировать карту на руды",
        Callback = function()
            ScanOres()
        end,
    })

    Tab:CreateSection("Настройки Авто-Фарма")

    -- Сохраняем Dropdown в переменную, чтобы менять его опции позже
    OreDropdown = Tab:CreateDropdown({
        Name = "Выбор руд",
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
        Name = "Подсветка (Box ESP)",
        CurrentValue = false,
        Flag = "EspToggle",
        Callback = function(Value)
            Config.VisualsEnabled = Value
            UpdateVisuals()
        end,
    })

    Tab:CreateToggle({
        Name = "Авто-Фарм выбранного",
        CurrentValue = false,
        Flag = "AutoFarmToggle",
        Callback = function(Value)
            Config.AutoMine = Value
            if Value then
                task.spawn(function()
                    while Config.AutoMine do
                        -- Логика поиска и копания (как в прошлом примере)
                        task.wait(0.5)
                    end
                end)
            end
        end,
    })

    -- Опционально: запускаем сканирование один раз при загрузке
    task.spawn(ScanOres)
end
