return function(Tab, Context)
	-- Настройки, которые нужно адаптировать под конкретный режим
	local Config = {
		AutoMine = false,
		SelectedOre = "Tin",
		OresFolder = workspace, -- УКАЖИ ПАПКУ С РУДАМИ: например, workspace.Ores
		ToolName = "Pickaxe",   -- УКАЖИ НАЗВАНИЕ ИНСТРУМЕНТА (или оставь пустым для авто-выбора)
		DistanceToMine = 5      -- Дистанция, с которой игра разрешает добывать
	}

	-- Список доступных руд (названия партов/моделей в игре)
	local OreTypes = {"Tin", "Iron", "Copper", "Gold", "Diamond"} 

	Tab:CreateSection("Настройки Авто-Фарма")

	Tab:CreateDropdown({
		Name = "Выбор руды",
		Options = OreTypes,
		CurrentOption = {"Tin"},
		MultipleOptions = false,
		Flag = "OreSelector",
		Callback = function(Option)
			Config.SelectedOre = Option[1]
		end,
	})

	Tab:CreateToggle({
		Name = "Включить Авто-Фарм",
		CurrentValue = false,
		Flag = "AutoFarmToggle",
		Callback = function(Value)
			Config.AutoMine = Value
			
			if Value then
				-- Запускаем цикл фарма в отдельном потоке
				task.spawn(function()
					while Config.AutoMine do
						local player = Context.Player
						local character = player.Character or player.CharacterAdded:Wait()
						local rootPart = character:WaitForChild("HumanoidRootPart")
						local humanoid = character:WaitForChild("Humanoid")

						-- 1. Ищем ближайшую руду
						local closestOre = nil
						local shortestDistance = math.huge

						-- Перебираем объекты в папке с рудами
						for _, item in pairs(Config.OresFolder:GetDescendants()) do
							if item.Name == Config.SelectedOre and item:IsA("BasePart") then
								local distance = (rootPart.Position - item.Position).Magnitude
								if distance < shortestDistance then
									closestOre = item
									shortestDistance = distance
								end
							end
						end

						-- 2. Если руда найдена, действуем
						if closestOre then
							-- Телепортация к руде (чуть выше и сбоку, чтобы не застрять)
							rootPart.CFrame = closestOre.CFrame * CFrame.new(0, Config.DistanceToMine, Config.DistanceToMine)

							-- 3. Экипировка инструмента
							local tool = player.Backpack:FindFirstChild(Config.ToolName)
							if tool then
								humanoid:EquipTool(tool)
							end
							
							-- Берем экипированный инструмент
							local equippedTool = character:FindFirstChildOfClass("Tool")

							-- 4. Имитация добычи
							if equippedTool then
								equippedTool:Activate() -- Имитация клика мышкой
							end

							-- Если в игре используются ProximityPrompt (E для взаимодействия)
							local prompt = closestOre:FindFirstChildOfClass("ProximityPrompt")
							if prompt then
								fireproximityprompt(prompt, 1, true)
							end
						end

						-- Пауза, чтобы не повесить игру (настрой под скорость добычи в игре)
						task.wait(0.2)
					end
				end)
			end
		end,
	})
end
