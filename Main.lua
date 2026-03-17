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

-- ИСПОЛЬЗУЕМ КРАСИВЫЕ ИКОНКИ ВМЕСТО ЦИФР
local Tabs = {
	Local = Window:CreateTab("Персонаж", "user"),
	Combat = Window:CreateTab("Бой", "swords"),
	Visuals = Window:CreateTab("Визуал", "eye"),
	Players = Window:CreateTab("Игроки", "users"),
	Server = Window:CreateTab("Сервер", "server"),
	Misc = Window:CreateTab("Разное", "settings")
}

local repoUrl = "https://raw.githubusercontent.com/NamelessOff/rbx/refs/heads/main/"

loadstring(game:HttpGet(repoUrl .. "Local.lua"))()(Tabs.Local, SharedContext)
loadstring(game:HttpGet(repoUrl .. "Combat.lua"))()(Tabs.Combat, SharedContext)
loadstring(game:HttpGet(repoUrl .. "Visuals.lua"))()(Tabs.Visuals, SharedContext)
loadstring(game:HttpGet(repoUrl .. "Player.lua"))()(Tabs.Players, SharedContext)
loadstring(game:HttpGet(repoUrl .. "Server.lua"))()(Tabs.Server, SharedContext)

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
