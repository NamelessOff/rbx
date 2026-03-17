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

-- Общий контекст со всеми сервисами, который мы передадим в каждый модуль
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
	Connections = {}, -- Хранилище всех циклов
	Cleanups = {}     -- Хранилище функций для очистки мусора (ESP, Парты и тд) при уничтожении
}

local Tabs = {
	Local = Window:CreateTab("Персонаж", 4483362458),
	Combat = Window:CreateTab("Бой", 4483362458),
	Visuals = Window:CreateTab("Визуал", 4483362458),
	Players = Window:CreateTab("Игроки", 4483362458),
	Server = Window:CreateTab("Сервер", 4483362458),
	Misc = Window:CreateTab("Разное", 4483362458)
}

-- ==========================================
-- ЗАГРУЗКА МОДУЛЕЙ С GITHUB
-- (Замените ссылки на свои RAW-ссылки с GitHub)
-- ==========================================
local repoUrl = "https://raw.githubusercontent.com/ВАШ_ПРОФИЛЬ/ВАШ_РЕПОЗИТОРИЙ/main/"

loadstring(game:HttpGet(repoUrl .. "Local.lua"))()(Tabs.Local, SharedContext)
loadstring(game:HttpGet(repoUrl .. "Combat.lua"))()(Tabs.Combat, SharedContext)
loadstring(game:HttpGet(repoUrl .. "Visuals.lua"))()(Tabs.Visuals, SharedContext)
loadstring(game:HttpGet(repoUrl .. "Players.lua"))()(Tabs.Players, SharedContext)
loadstring(game:HttpGet(repoUrl .. "Server.lua"))()(Tabs.Server, SharedContext)

-- ==========================================
-- РАЗНОЕ И УНИЧТОЖЕНИЕ
-- ==========================================
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

Tabs.Misc:CreateButton({
	Name = "❌ ПОЛНОСТЬЮ УНИЧТОЖИТЬ СКРИПТ",
	Callback = function()
		-- 1. Вызываем все локальные функции очистки из модулей
		for _, cleanupFunc in pairs(SharedContext.Cleanups) do
			pcall(cleanupFunc)
		end
		
		-- 2. Отключаем все события
		for _, conn in pairs(SharedContext.Connections) do
			if conn then conn:Disconnect() end
		end
		SharedContext.Connections = {}
		
		-- 3. Уничтожаем интерфейс
		Rayfield:Destroy()
	end,
})