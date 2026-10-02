local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ===================== STATE =====================
local IGNORED_TOOLS = {
	["Ruler Axe"] = true,
	["(Click To Teleport)"] = true,
}

local function isIgnored(toolName)
	return IGNORED_TOOLS[toolName] == true
end

local mode = "none" -- "none" | "remove" | "equip"
local selectedToolName = nil
local activeButtonRef = nil
local toolButtonMap = {} -- toolName -> TextButton

-- ===================== GUI CREATION =====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ToolManager"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Main Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0.1, 0, 0.3, 0)
mainFrame.Position = UDim2.new(0, 0, 0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0.025, 0)
mainCorner.Parent = mainFrame

local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(60, 60, 80)
uiStroke.Thickness = 0.15
uiStroke.Parent = mainFrame

-- Title Bar (drag handle)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0.09, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0.025, 0)
titleCorner.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.TextColor3 = Color3.fromRGB(210, 210, 230)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextScaled = true
titleLabel.Text = "Tool Manager"
titleLabel.Parent = titleBar

-- Current Tool Label
local currentToolLabel = Instance.new("TextLabel")
currentToolLabel.Name = "CurrentToolLabel"
currentToolLabel.Size = UDim2.new(1, 0, 0.09, 0)
currentToolLabel.Position = UDim2.new(0, 0, 0.09, 0)
currentToolLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
currentToolLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
currentToolLabel.Font = Enum.Font.Gotham
currentToolLabel.TextScaled = true
currentToolLabel.Text = "Текущий: Нет"
currentToolLabel.BorderSizePixel = 0
currentToolLabel.Parent = mainFrame

local labelPadding = Instance.new("UIPadding")
labelPadding.PaddingLeft = UDim.new(0.03, 0)
labelPadding.PaddingRight = UDim.new(0.03, 0)
labelPadding.Parent = currentToolLabel

-- Buttons Frame
local buttonsFrame = Instance.new("Frame")
buttonsFrame.Name = "ButtonsFrame"
buttonsFrame.Size = UDim2.new(1, 0, 0.12, 0)
buttonsFrame.Position = UDim2.new(0, 0, 0.18, 0)
buttonsFrame.BackgroundTransparency = 1
buttonsFrame.Parent = mainFrame

local btnPadding = Instance.new("UIPadding")
btnPadding.PaddingLeft = UDim.new(0.02, 0)
btnPadding.PaddingRight = UDim.new(0.02, 0)
btnPadding.PaddingTop = UDim.new(0.05, 0)
btnPadding.PaddingBottom = UDim.new(0.05, 0)
btnPadding.Parent = buttonsFrame

local removeBtn = Instance.new("TextButton")
removeBtn.Name = "RemoveBtn"
removeBtn.Size = UDim2.new(0.48, 0, 1, 0)
removeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
removeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
removeBtn.Font = Enum.Font.GothamBold
removeBtn.TextScaled = true
removeBtn.Text = "Убрать Tool"
removeBtn.BorderSizePixel = 0
removeBtn.AutoButtonColor = true
removeBtn.Parent = buttonsFrame

local removeCorner = Instance.new("UICorner")
removeCorner.CornerRadius = UDim.new(0.06, 0)
removeCorner.Parent = removeBtn

local equipBtn = Instance.new("TextButton")
equipBtn.Name = "EquipBtn"
equipBtn.Size = UDim2.new(0.48, 0, 1, 0)
equipBtn.Position = UDim2.new(0.52, 0, 0, 0)
equipBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
equipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
equipBtn.Font = Enum.Font.GothamBold
equipBtn.TextScaled = true
equipBtn.Text = "Взять Tool"
equipBtn.BorderSizePixel = 0
equipBtn.AutoButtonColor = true
equipBtn.Parent = buttonsFrame

local equipCorner = Instance.new("UICorner")
equipCorner.CornerRadius = UDim.new(0.06, 0)
equipCorner.Parent = equipBtn

-- Tool List (ScrollingFrame)
local toolList = Instance.new("ScrollingFrame")
toolList.Name = "ToolList"
toolList.Size = UDim2.new(1, 0, 0.7, 0)
toolList.Position = UDim2.new(0, 0, 0.3, 0)
toolList.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
toolList.BorderSizePixel = 0
toolList.ScrollBarThickness = 4
toolList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 130)
toolList.AutomaticCanvasSize = Enum.AutomaticSize.Y
toolList.CanvasSize = UDim2.new(0, 0, 0, 0)
toolList.Parent = mainFrame

local listPadding = Instance.new("UIPadding")
listPadding.PaddingLeft = UDim.new(0.02, 0)
listPadding.PaddingRight = UDim.new(0.02, 0)
listPadding.PaddingTop = UDim.new(0.01, 0)
listPadding.PaddingBottom = UDim.new(0.01, 0)
listPadding.Parent = toolList

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0.004, 0)
listLayout.Parent = toolList

-- ===================== DRAG LOGIC =====================
local dragging = false
local dragStart = nil
local frameStart = nil

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		frameStart = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		local vpSize = workspace.CurrentCamera.ViewportSize
		mainFrame.Position = UDim2.new(
			frameStart.X.Scale + delta.X / vpSize.X,
			0,
			frameStart.Y.Scale + delta.Y / vpSize.Y,
			0
		)
	end
end)

-- ===================== HELPER FUNCTIONS =====================
local function getCharacter()
	return player.Character
end

local function getBackpack()
	return player:FindFirstChild("Backpack")
end

local function getEquippedTool()
	local char = getCharacter()
	if not char then return nil end
	for _, child in char:GetChildren() do
		if child:IsA("Tool") then
			return child
		end
	end
	return nil
end

local function getUniqueToolNames()
	local backpack = getBackpack()
	local char = getCharacter()
	local names = {}
	local seen = {}

	local function addFromContainer(container)
		if not container then return end
		for _, item in container:GetChildren() do
			if item:IsA("Tool") and not seen[item.Name] and not isIgnored(item.Name) then
				seen[item.Name] = true
				table.insert(names, item.Name)
			end
		end
	end

	addFromContainer(backpack)
	addFromContainer(char)

	table.sort(names)
	return names
end

local function findToolInBackpack(name)
	if isIgnored(name) then return nil end
	local backpack = getBackpack()
	if not backpack then return nil end
	for _, item in backpack:GetChildren() do
		if item:IsA("Tool") and item.Name == name then
			return item
		end
	end
	return nil
end

local function getFirstAvailableToolName()
	local backpack = getBackpack()
	if not backpack then return nil end
	for _, item in backpack:GetChildren() do
		if item:IsA("Tool") and not isIgnored(item.Name) then
			return item.Name
		end
	end
	return nil
end

-- ===================== TOOL LIST UI =====================
local function updateToolList()
	-- Remove old buttons
	for name, btn in toolButtonMap do
		btn:Destroy()
	end
	toolButtonMap = {}
	activeButtonRef = nil

	local names = getUniqueToolNames()

	for i, name in names do
		local btn = Instance.new("TextButton")
		btn.Name = "ToolBtn_" .. name
		btn.Size = UDim2.new(1, 0, 0.2, 0)
		btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
		btn.TextColor3 = Color3.fromRGB(200, 200, 220)
		btn.Font = Enum.Font.Gotham
		btn.TextScaled = true
		btn.Text = name
		btn.BorderSizePixel = 0
		btn.TextXAlignment = Enum.TextXAlignment.Center
		btn.Parent = toolList

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0.03, 0)
		btnCorner.Parent = btn

		local btnPadding = Instance.new("UIPadding")
		btnPadding.PaddingLeft = UDim.new(0.02, 0)
		btnPadding.Parent = btn

		-- Highlight if this is the selected tool
		if name == selectedToolName then
			btn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			activeButtonRef = btn
		end

		btn.MouseButton1Click:Connect(function()
			-- Deactivate old
			if activeButtonRef then
				activeButtonRef.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
				activeButtonRef.TextColor3 = Color3.fromRGB(200, 200, 220)
			end

			-- Activate new
			btn.BackgroundColor3 = Color3.fromRGB(70, 130, 70)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			activeButtonRef = btn
			selectedToolName = name
			currentToolLabel.Text = "Текущий: " .. name
		end)

		toolButtonMap[name] = btn
	end
end

-- ===================== BUTTON HANDLERS =====================
removeBtn.MouseButton1Click:Connect(function()
	if mode == "remove" then
		mode = "none"
		removeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	else
		mode = "remove"
		removeBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
		equipBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
	end
end)

equipBtn.MouseButton1Click:Connect(function()
	if mode == "equip" then
		mode = "none"
		equipBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
	else
		mode = "equip"
		equipBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 90)
		removeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	end
end)

-- ===================== REMOVE LOOP =====================
task.spawn(function()
	while true do
		task.wait(0.1)
		if mode ~= "remove" then continue end

		local char = getCharacter()
		if not char then continue end

		for _, child in char:GetChildren() do
			if child:IsA("Tool") and not isIgnored(child.Name) then
				child.Parent = player:FindFirstChild("Backpack")
			end
		end
	end
end)

-- ===================== EQUIP LOOP =====================
task.spawn(function()
	while true do
		task.wait(0.1)
		if mode ~= "equip" then continue end

		local char = getCharacter()
		local backpack = getBackpack()
		if not char or not backpack then continue end

		local equipped = getEquippedTool()

		if equipped then
			-- Tool is equipped, check if it matches selected name
			if equipped.Name == selectedToolName or isIgnored(equipped.Name) then
				-- All good, keep it equipped (ignored tools are never touched)
				continue
			else
				-- Wrong tool equipped, unequip it
				equipped.Parent = backpack
			end
		end

		-- No tool equipped, try to equip selected
		if selectedToolName then
			local tool = findToolInBackpack(selectedToolName)
			if tool then
				tool.Parent = char
				continue
			end

			-- Selected tool name not found in backpack, pick next available
			local nextName = getFirstAvailableToolName()
			if nextName then
				selectedToolName = nextName
				currentToolLabel.Text = "Текущий: " .. nextName
				updateToolList()

				local nextTool = findToolInBackpack(nextName)
				if nextTool then
					nextTool.Parent = char
				end
			else
				-- No tools at all
				currentToolLabel.Text = "Текущий: Нет"
			end
		else
			-- No tool selected yet, pick first available
			local nextName = getFirstAvailableToolName()
			if nextName then
				selectedToolName = nextName
				currentToolLabel.Text = "Текущий: " .. nextName
				updateToolList()

				local nextTool = findToolInBackpack(nextName)
				if nextTool then
					nextTool.Parent = char
				end
			end
		end
	end
end)

-- ===================== REFRESH TOOL LIST ON CHANGES =====================
local lastToolNames = {}

task.spawn(function()
	while true do
		task.wait(0.3)
		local currentNames = getUniqueToolNames()

		-- Check if list changed
		local changed = #currentNames ~= #lastToolNames
		if not changed then
			for i, name in currentNames do
				if name ~= lastToolNames[i] then
					changed = true
					break
				end
			end
		end

		if changed then
			lastToolNames = currentNames
			updateToolList()
		end
	end
end)

-- Initial build
updateToolList()
