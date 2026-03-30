return function(Tab, Context)
    -- ==========================================
    -- КОНФИГУРАЦИЯ И ПЕРЕМЕННЫЕ
    -- ==========================================
    local Config = {
        AutoMine = false,
        VisualsEnabled = false,
        SelectedOres = {},      -- Список выбранных пользователем руд
        OresFolder = workspace,  -- ПАПКА ДЛЯ ПОИСКА (измени на workspace.Ores если нужно)
        ToolName = "Pickaxe",    -- Название кирки
        DistanceToMine = 5       -- Дистанция взаимодействия
    }

    local OreTypes = {}       -- Сюда попадут найденные названия (напр. "Gold Ore")
    local ActiveBoxESP = {}   -- Хранилище для объектов подсветки
    local OreDropdown         -- Ссылка на элемент интерфейса

    -- ==========================================
    -- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ (ЛОГИКА)
    -- ==========================================

    -- Очистка всех созданных рамок подсветки
    local function ClearESP()
        for _, box in pairs(ActiveBoxESP) do
            if box then box:Destroy() end
        end
        ActiveBoxESP = {}
    end

    -- Функция сканирования карты
    local function ScanForOres()
        print("------------------------------------------")
        print("[Partner Log]: Начало сканирования объектов...")
        
        local foundNames = {} -- Временная таблица для проверки уникальности
        local newOptions = {} -- Таблица для передачи в Dropdown
        
        -- Перебираем всё содержимое папки OresFolder
        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            -- УСЛОВИЕ: Имя содержит "Ore", объект является Part и мы его еще не записывали
            if item:IsA("BasePart") and string.find(item.Name, "Ore") then
                if not foundNames[item.Name] then
                    foundNames[item.Name] = true
                    table.insert(newOptions, item.Name)
                    print("[Partner Log]: ОБНАРУЖЕНО: " .. item.Name)
                end
            end
        end

        OreTypes = newOptions
        
        -- Обновляем выпадающий список в меню
        if OreDropdown then
            OreDropdown:SetOptions(OreTypes)
            print("[Partner Log]: Сканирование завершено. Найдено типов: " .. #OreTypes)
        end
    end

    -- Создание рамки вокруг конкретного парта
    local function CreateBox(object)
        local box = Instance.new("SelectionBox")
        box.Name = "Partner_ESP_Box"
        box.Adornee = object
        box.Color3 = Color3.fromRGB(0, 255, 255) -- Бирюзовый цвет
        box.LineThickness = 0.05
        box.Parent = Context.CoreGui -- Рисуем поверх всего интерфейса
        table.insert(ActiveBoxESP, box)
    end

    -- Обновление всей подсветки на экране
    local function UpdateVisuals()
        ClearESP()
        if not Config.VisualsEnabled then return end

        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            -- Если имя объекта есть в списке выбранных в меню
            if table.find(Config.SelectedOres, item.Name) and item:IsA("BasePart") then
                CreateBox(item)
            end
        end
    end

    -- ==========================================
    -- СОЗДАНИЕ ИНТЕРФЕЙСА (RAYFIELD)
    -- ==========================================

    Tab:CreateSection("Поиск ресурсов")

    Tab:CreateButton({
        Name = "🔍 Найти все руды на карте",
        Callback = function()
            ScanForOres()
        end,
    })

    Tab:CreateSection("Настройки Авто-Фарма")

    -- Выпадающее меню с множественным выбором
    OreDropdown = Tab:CreateDropdown({
        Name = "Выберите руды для работы",
        Options = OreTypes,
        CurrentOption = {},
        MultipleOptions = true, -- Разрешаем выбирать несколько
        Flag = "OreSelector",
        Callback = function(Options)
            Config.SelectedOres = Options
            UpdateVisuals() -- Перерисовываем рамки при каждом изменении выбора
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
        Name = "Включить Авто-Фарм",
        CurrentValue = false,
        Flag = "AutoFarmToggle",
        Callback = function(Value)
            Config.AutoMine = Value
            if Value then
                task.spawn(function()
                    while Config.AutoMine do
                        -- Тут твоя логика перемещения к ближайшей руде из Config.SelectedOres
                        task.wait(0.5)
                    end
                end)
            end
        end,
    })

    -- Автоматический запуск поиска при загрузке скрипта
    task.spawn(ScanForOres)
end
