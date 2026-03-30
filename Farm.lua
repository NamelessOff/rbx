return function(Tab, Context)
    -- Подключаем сервис для работы с форматом JSON (чтобы сохранять таблицы в текст)
    local HttpService = game:GetService("HttpService")
    
    -- Название файла, который появится в папке твоего экзекутора (обычно папка workspace)
    local FileName = "SavedOresList.json"

    -- ==========================================
    -- КОНФИГУРАЦИЯ И ПЕРЕМЕННЫЕ
    -- ==========================================
    local Config = {
        AutoMine = false,
        VisualsEnabled = false,
        SelectedOres = {}, 
        OresFolder = workspace, 
        ToolName = "Pickaxe",
        DistanceToMine = 5
    }

    local OreTypes = {} 
    local ActiveBoxESP = {} 
    local OreDropdown 

    -- ==========================================
    -- ФУНКЦИИ РАБОТЫ С ФАЙЛАМИ
    -- ==========================================

    -- Функция сохранения списка в файл
    local function SaveOresToFile()
        -- Защищаем код от ошибок с помощью pcall
        local success, errorMsg = pcall(function()
            -- Превращаем таблицу Lua в удобный текстовый формат JSON
            local jsonData = HttpService:JSONEncode(OreTypes)
            -- Записываем текст в файл (функция экзекутора)
            writefile(FileName, jsonData)
        end)

        if success then
            print("[Partner Log]: Список руд успешно сохранен в файл: " .. FileName)
        else
            warn("[Partner Log]: Ошибка при сохранении файла: " .. tostring(errorMsg))
        end
    end

    -- Функция загрузки списка из файла
    local function LoadOresFromFile()
        -- Проверяем, существует ли функция isfile и сам файл
        if isfile and isfile(FileName) then
            local success, result = pcall(function()
                -- Читаем текст из файла
                local fileData = readfile(FileName)
                -- Превращаем текст обратно в таблицу Lua
                return HttpService:JSONDecode(fileData)
            end)

            if success and type(result) == "table" then
                OreTypes = result
                print("[Partner Log]: Список руд успешно загружен из файла.")
                
                -- Обновляем меню, если оно уже создано
                if OreDropdown then
                    OreDropdown:Refresh(OreTypes, false)
                end
            else
                warn("[Partner Log]: Файл найден, но прочитать его не удалось.")
            end
        else
            print("[Partner Log]: Файл с рудами не найден. Требуется сканирование.")
        end
    end

    -- ==========================================
    -- ФУНКЦИИ ЛОГИКИ (ESP И СКАНЕР)
    -- ==========================================

    local function ClearESP()
        for _, box in pairs(ActiveBoxESP) do
            if box then box:Destroy() end
        end
        ActiveBoxESP = {}
    end

    -- ==========================================
    -- ЧЕРНЫЙ СПИСОК (Игнорируем технические детали)
    -- ==========================================
    local Blacklist = {
        "Hitbox", "Centre", "Block", "PlacedOre", "OreIngredientMesh",
        "CasingCentre", "CubicBlockMetal", "ShaleMetalBlock", "GemBlockMesh",
        "OreBlockPolished", "CrystallineMetalOre", "CrystallineOre"
    }

    -- Функция для проверки, есть ли имя в черном списке
    local function IsBlacklisted(name)
        for _, badName in pairs(Blacklist) do
            if name == badName then return true end
        end
        return false
    end

    -- ==========================================
    -- ОБНОВЛЕННОЕ УМНОЕ СКАНИРОВАНИЕ
    -- ==========================================
    local function ScanForOres()
        print("------------------------------------------")
        print("[Partner Log]: Начало сканирования с учетом Моделей и Черного списка...")
        
        local foundNames = {} 
        local newOptions = {} 
        
        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            -- ТЕПЕРЬ МЫ ИЩЕМ И МОДЕЛИ (Model), И ДЕТАЛИ (BasePart)
            if item:IsA("Model") or item:IsA("BasePart") then
                local name = item.Name
                local lowerName = string.lower(name)
                
                -- Проверяем, есть ли в названии слова "ore" (руда) или "gemstone" (самоцвет)
                if string.find(lowerName, "ore") or string.find(lowerName, "gemstone") then
                    
                    -- Если имя НЕ в черном списке и мы его еще не записывали
                    if not IsBlacklisted(name) and not foundNames[name] then
                        foundNames[name] = true
                        table.insert(newOptions, name)
                        print("[Partner Log]: Чистая руда добавлена в список: " .. name)
                    end
                end
            end
        end

        OreTypes = newOptions
        
        if OreDropdown then
            OreDropdown:Refresh(OreTypes, false)
            print("[Partner Log]: Меню обновлено. Доступно руд: " .. #OreTypes)
        end

        if #OreTypes > 0 then
            SaveOresToFile()
        end
    end

    -- ==========================================
    -- ОБНОВЛЕННЫЕ ВИЗУАЛЫ (ESP ДЛЯ МОДЕЛЕЙ)
    -- ==========================================
    local function UpdateVisuals()
        ClearESP()
        if not Config.VisualsEnabled then return end

        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            -- Проверяем, есть ли имя объекта в выбранных нами в меню
            if table.find(Config.SelectedOres, item.Name) then
                
                -- Если это Модель или Деталь - вешаем на неё рамку
                if item:IsA("Model") or item:IsA("BasePart") then
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

    -- ==========================================
    -- СОЗДАНИЕ ИНТЕРФЕЙСА
    -- ==========================================

    Tab:CreateSection("Поиск и Сохранение")

    Tab:CreateButton({
        Name = "🔍 Сканировать руды (и сохранить)",
        Callback = ScanForOres
    })

    -- Кнопка для ручной загрузки, если нужно
    Tab:CreateButton({
        Name = "📂 Загрузить список из файла",
        Callback = LoadOresFromFile
    })

    Tab:CreateSection("Настройки Авто-Фарма")

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
        Name = "Подсветка (Box ESP)",
        CurrentValue = false,
        Flag = "EspToggle",
        Callback = function(Value)
            Config.VisualsEnabled = Value
            UpdateVisuals()
        end,
    })

    -- Пытаемся загрузить сохраненный файл при старте
    LoadOresFromFile()
end
