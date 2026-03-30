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

    -- Обновленная функция сканирования
    local function ScanForOres()
        print("------------------------------------------")
        print("[Partner Log]: Начало умного сканирования...")
        
        local foundNames = {} 
        local newOptions = {} 
        
        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            if item:IsA("BasePart") then
                local name = item.Name
                local parentName = item.Parent and item.Parent.Name or ""
                
                if string.find(string.lower(name), "ore") or string.find(string.lower(parentName), "ore") then
                    local displayName = name
                    if name == "OreMesh" or name == "Part" or name == "MeshPart" then
                        displayName = parentName
                    end

                    if not foundNames[displayName] and displayName ~= "" then
                        foundNames[displayName] = true
                        table.insert(newOptions, displayName)
                        print("[Partner Log]: Найдена категория: " .. displayName)
                    end
                end
            end
        end

        OreTypes = newOptions
        
        if OreDropdown then
            OreDropdown:Refresh(OreTypes, false)
            print("[Partner Log]: Меню обновлено. Найдено типов: " .. #OreTypes)
        end

        -- СОХРАНЯЕМ РЕЗУЛЬТАТ В ФАЙЛ
        if #OreTypes > 0 then
            SaveOresToFile()
        end
    end

    local function UpdateVisuals()
        ClearESP()
        if not Config.VisualsEnabled then return end

        for _, item in pairs(Config.OresFolder:GetDescendants()) do
            if item:IsA("BasePart") then
                local name = item.Name
                local parentName = item.Parent and item.Parent.Name or ""
                
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
