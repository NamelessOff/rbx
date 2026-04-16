return function(Tab, Context)
    local HttpService = game:GetService("HttpService")
    local FileName = "SavedOresList.json"

    local Config = {
        AutoMine = false,
        VisualsEnabled = false,
        SelectedOres = {}, 
        OresFolderStr = "workspace",
        NameFilter = "",
        OnlyInteractable = false,
        ToolName = "Pickaxe",
        DistanceToMine = 5
    }

    local OreTypes = {} 
    local ActiveBoxESP = {} 
    local OreDropdown 

    local function SaveOresToFile()
        local success, errorMsg = pcall(function()
            local jsonData = HttpService:JSONEncode(OreTypes)
            writefile(FileName, jsonData)
        end)
        if success then
            print("[Partner Log]: Список руд сохранен: " .. FileName)
        else
            warn("[Partner Log]: Ошибка сохранения: " .. tostring(errorMsg))
        end
    end

    local function LoadOresFromFile()
        if type(isfile) == "function" and isfile(FileName) then
            local success, result = pcall(function()
                return HttpService:JSONDecode(readfile(FileName))
            end)
            if success and type(result) == "table" then
                OreTypes = result
                print("[Partner Log]: Список руд загружен.")
                if OreDropdown then OreDropdown:Refresh(OreTypes, false) end
            end
        end
    end

    local function ClearESP()
        for _, box in pairs(ActiveBoxESP) do
            if box then box:Destroy() end
        end
        table.clear(ActiveBoxESP)
    end

    local Blacklist = {
        "Hitbox", "Centre", "Block", "PlacedOre", "OreIngredientMesh",
        "CasingCentre", "CubicBlockMetal", "ShaleMetalBlock", "GemBlockMesh",
        "OreBlockPolished", "CrystallineMetalOre", "CrystallineOre"
    }

    local function IsBlacklisted(name)
        for _, badName in pairs(Blacklist) do
            if name == badName then return true end
        end
        return false
    end

    local function ResolveFolder(pathStr)
        if pathStr == "" or string.lower(pathStr) == "workspace" then return workspace end
        local parts = string.split(pathStr, ".")
        local current = game
        for _, p in ipairs(parts) do
            if current:FindFirstChild(p) then
                current = current[p]
            else
                return nil
            end
        end
        return current
    end

    local function ScanForOres()
        print("[Partner Log]: Сканирование...")
        local folder = ResolveFolder(Config.OresFolderStr)
        if not folder then
            warn("[Partner Log]: Папка " .. Config.OresFolderStr .. " не найдена!")
            return
        end
        
        local foundNames = {} 
        local newOptions = {} 
        local desc = folder:GetDescendants()
        
        task.spawn(function()
            for i, item in ipairs(desc) do
                if i % 150 == 0 then task.wait() end 

                if item:IsA("Model") or item:IsA("BasePart") then
                    local name = item.Name
                    local lowerName = string.lower(name)
                    
                    if Config.OnlyInteractable then
                        local hasPrompt = item:FindFirstChildWhichIsA("ProximityPrompt") or item:FindFirstChildWhichIsA("ClickDetector")
                        if not hasPrompt then continue end
                    end

                    if Config.NameFilter ~= "" and not string.find(lowerName, string.lower(Config.NameFilter)) then
                        continue
                    end
                    
                    if not IsBlacklisted(name) and not foundNames[name] then
                        foundNames[name] = true
                        table.insert(newOptions, name)
                    end
                end
            end

            OreTypes = newOptions
            if OreDropdown then
                OreDropdown:Refresh(OreTypes, false)
            end
            if #OreTypes > 0 then SaveOresToFile() end
            print("[Partner Log]: Найдено типов: " .. #OreTypes)
        end)
    end

    local function UpdateVisuals()
        ClearESP()
        if not Config.VisualsEnabled then return end

        local folder = ResolveFolder(Config.OresFolderStr)
        if not folder then return end

        task.spawn(function()
            for i, item in ipairs(folder:GetDescendants()) do
                if i % 250 == 0 then task.wait() end 
                if table.find(Config.SelectedOres, item.Name) then
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
        end)
    end

    Tab:CreateSection("Настройки Поиска")

    Tab:CreateInput({
        Name = "Путь к папке объектов",
        PlaceholderText = "например: workspace.Map.Ores",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text) Config.OresFolderStr = Text end,
    })

    Tab:CreateInput({
        Name = "Фильтр текста (опционально)",
        PlaceholderText = "Введите фрагмент имени",
        RemoveTextAfterFocusLost = false,
        Callback = function(Text) Config.NameFilter = Text end,
    })

    Tab:CreateToggle({
        Name = "Искать только интерактивные",
        CurrentValue = false,
        Flag = "OnlyInteractable",
        Callback = function(Value) Config.OnlyInteractable = Value end,
    })

    Tab:CreateButton({
        Name = "🔍 Сканировать и Сохранить",
        Callback = ScanForOres
    })

    Tab:CreateSection("Настройки Авто-Фарма")

    OreDropdown = Tab:CreateDropdown({
        Name = "Выберите объекты",
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

    LoadOresFromFile()
end
