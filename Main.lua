local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
	Name = "Ultimate Game Hub v5.0 MODULAR",
	LoadingTitle = "Загрузка ядра...",
	LoadingSubtitle = "by You",
	ConfigurationSaving = { Enabled = false },
	Discord = { Enabled = false },
	KeySystem = false,
	Theme = "Ocean",
})

local SharedContext = {
	Player = game:GetService("Players").LocalPlayer,
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	UserInputService = game:GetService("UserInputService"),
	Lighting = game:GetService("Lighting"),
	VirtualUser = game:GetService("VirtualUser"),
	TeleportService = game:GetService("TeleportService"),
	HttpService = game:GetService("HttpService"),
	CoreGui = game:GetService("CoreGui"),
	Camera = workspace.CurrentCamera,
	Connections = {},
	Cleanups = {}
}

local Tabs = {
	Local = Window:CreateTab("Персонаж", "user"),
	Combat = Window:CreateTab("Бой", "swords"),
	Visuals = Window:CreateTab("Визуал", "eye"),
	Players = Window:CreateTab("Игроки", "users"),
	Server = Window:CreateTab("Сервер", "server"),
	Misc = Window:CreateTab("Разное", "settings")
}

local repoUrl = "https://raw.githubusercontent.com/NamelessOff/rbx/refs/heads/main/"

-- Безопасная функция для загрузки модулей
local function LoadModule(fileName, tab)
    local url = repoUrl .. fileName
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("❌ Не удалось сделать запрос к " .. fileName .. ": " .. tostring(result))
        return
    end

    -- Проверка на 404 ошибку от GitHub
    if result:match("404: Not Found") then
        warn("❌ Файл не найден (404). Проверьте правильность названия и регистра: " .. fileName)
        return
    end

    local func, compileErr = loadstring(result)
    if not func then
        warn("❌ Ошибка синтаксиса в " .. fileName .. ":\n" .. tostring(compileErr))
        return
    end

    local runSuccess, runErr = pcall(function()
        func()(tab, SharedContext)
    end)

    if not runSuccess then
        warn("❌ Ошибка выполнения в " .. fileName .. ":\n" .. tostring(runErr))
    end
end

LoadModule("Local.lua", Tabs.Local)
LoadModule("Combat.lua", Tabs.Combat)
LoadModule("Visuals.lua", Tabs.Visuals)
LoadModule("Player.lua", Tabs.Players) 
LoadModule("Server.lua", Tabs.Server)

Tabs.Misc:CreateSection("Автоматизация")
Tabs.Misc:CreateButton({
	Name = "Активировать Anti-AFK",
	Callback = function()
		table.insert(SharedContext.Connections, SharedContext.Player.Idled:Connect(function()
			SharedContext.VirtualUser:CaptureController()
			SharedContext.VirtualUser:ClickButton2(Vector2.new())
		end))
		Rayfield:Notify({Title = "Anti-AFK", Content = "Активирован.", Duration = 3})
	end,
})

Tabs.Misc:CreateSection("Управление скриптом")
Tabs.Misc:CreateButton({
	Name = "❌ ПОЛНОСТЬЮ УНИЧТОЖИТЬ СКРИПТ",
	Callback = function()
		for _, cleanupFunc in pairs(SharedContext.Cleanups) do
			pcall(cleanupFunc)
		end
		for _, conn in pairs(SharedContext.Connections) do
			if conn then conn:Disconnect() end
		end
		SharedContext.Connections = {}
		Rayfield:Destroy()
	end,
})
