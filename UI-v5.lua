local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RuntimeEnvironment = (getgenv and getgenv()) or _G
local existingRuntime = RuntimeEnvironment.__UI_V5_RUNTIME

if existingRuntime then
	if existingRuntime == true then
		return nil
	end

	return existingRuntime
end

if playerGui:FindFirstChild("UI-v5") then
	return nil
end

RuntimeEnvironment.__UI_V5_RUNTIME = true

local unloaded = false
local capturingKeybind = false

local activeColorPickerClose = nil
local activeColorPickerPopup = nil
local activeColorPickerPreview = nil

local activeKeybindClose = nil
local activeKeybindPopup = nil
local activeKeybindButton = nil

local activeDropdownClose = nil
local activeDropdownPopup = nil
local activeDropdownButton = nil

local connections = {}

local function Track(connection)
	table.insert(connections, connection)
	return connection
end

local function DisconnectAll()
	for i = #connections, 1, -1 do
		local connection = connections[i]

		if connection and connection.Connected then
			connection:Disconnect()
		end

		connections[i] = nil
	end
end

local C = {
	Window = Color3.fromRGB(15, 15, 16),
	Top = Color3.fromRGB(12, 12, 13),
	Panel = Color3.fromRGB(18, 18, 19),
	Panel2 = Color3.fromRGB(21, 21, 23),
	PanelHover = Color3.fromRGB(25, 24, 27),

	Border = Color3.fromRGB(50, 50, 55),
	BorderSoft = Color3.fromRGB(38, 38, 42),

	Text = Color3.fromRGB(210, 210, 214),
	Muted = Color3.fromRGB(135, 135, 142),
	Dim = Color3.fromRGB(83, 83, 90),

	Accent = Color3.fromRGB(178, 112, 187),
	AccentDark = Color3.fromRGB(100, 60, 108),
}

local FONT = Enum.Font.Code

local MOTION = {
	Fast = 0.08,
	Hover = 0.11,
	Control = 0.13,
	Popup = 0.12,
	TabOut = 0.10,
	TabIn = 0.16,
	WindowIn = 0.20,
	WindowOut = 0.16,
}

local function New(className, props)
	local obj = Instance.new(className)

	for property, value in pairs(props or {}) do
		obj[property] = value
	end

	return obj
end

local function Tween(obj, props, duration)
	if unloaded or not obj or not obj.Parent then
		return nil
	end

	local tween = TweenService:Create(
		obj,
		TweenInfo.new(
			duration or 0.16,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		props
	)

	tween:Play()
	return tween
end

local function Stroke(obj, color, transparency)
	return New("UIStroke", {
		Parent = obj,
		Color = color or C.Border,
		Thickness = 0.7,
		Transparency = transparency == nil and 0.42 or transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Corner(obj, radius)
	return New("UICorner", {
		Parent = obj,
		CornerRadius = UDim.new(0, radius or 3),
	})
end

local function Label(parent, text, size, color, align)
	return New("TextLabel", {
		Parent = parent,
		BackgroundTransparency = 1,
		Size = size or UDim2.new(1, 0, 0, 18),
		Text = text or "",
		TextColor3 = color or C.Text,
		TextSize = 14,
		Font = FONT,
		TextXAlignment = align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
end

local gui = New("ScreenGui", {
	Name = "UI-v5",
	Parent = playerGui,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local Library = {}
RuntimeEnvironment.__UI_V5_RUNTIME = Library

local main = New("CanvasGroup", {
	Name = "Main",
	Parent = gui,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(680, 620),

	BackgroundColor3 = C.Window,
	BorderSizePixel = 0,
	ClipsDescendants = false,
	GroupTransparency = 0,
})

local outerOutline = New("UIStroke", {
	Parent = main,
	Color = Color3.fromRGB(72, 72, 78),
	Thickness = 1,
	Transparency = 0.12,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local innerOutline = New("Frame", {
	Parent = main,
	Position = UDim2.fromOffset(2, 2),
	Size = UDim2.new(1, -4, 1, -4),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 999,
})

New("UIStroke", {
	Parent = innerOutline,
	Color = Color3.fromRGB(35, 35, 39),
	Thickness = 1,
	Transparency = 0.22,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local top = New("Frame", {
	Parent = main,
	Size = UDim2.new(1, 0, 0, 24),
	BackgroundColor3 = C.Top,
	BorderSizePixel = 0,
})

local title = Label(
	top,
	"UI-v5 Developer : (discord) @nelessk",
	UDim2.new(1, -16, 1, 0),
	C.Text
)
title.Position = UDim2.fromOffset(8, 0)
title.TextSize = 13

New("Frame", {
	Parent = main,
	Position = UDim2.fromOffset(0, 24),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = C.BorderSoft,
	BorderSizePixel = 0,
})

local tabBar = New("Frame", {
	Parent = main,
	Position = UDim2.fromOffset(7, 29),
	Size = UDim2.new(1, -14, 0, 27),
	BackgroundTransparency = 1,
})

local contentRoot = New("Frame", {
	Parent = main,
	Position = UDim2.fromOffset(7, 61),
	Size = UDim2.new(1, -14, 1, -68),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
})

local tabWidth = 130
local tabGap = 3

local tabs = {}
local pages = {}
local tabButtons = {}
local tabIndices = {}
local tabPageTweens = {}

local currentTab = nil
local tabIndicatorTween = nil
local tabIndicatorGlowTween = nil

local tabIndicator = New("Frame", {
	Parent = tabBar,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(0, 2),
	BackgroundColor3 = C.Accent,
	BorderSizePixel = 0,
	ZIndex = 20,
})
Corner(tabIndicator, 2)

local tabIndicatorGlow = New("Frame", {
	Parent = tabBar,
	Position = UDim2.fromOffset(0, 1),
	Size = UDim2.fromOffset(0, 3),
	BackgroundColor3 = C.Accent,
	BackgroundTransparency = 0.76,
	BorderSizePixel = 0,
	ZIndex = 19,
})
Corner(tabIndicatorGlow, 3)

local function CloseTransientPopups()
	if activeColorPickerClose then
		activeColorPickerClose()
	end

	if activeKeybindClose then
		activeKeybindClose()
	end

	if activeDropdownClose then
		activeDropdownClose()
	end
end

local function RefreshTabLayout()
	for i, name in ipairs(tabs) do
		tabIndices[name] = i

		local button = tabButtons[name]
		if button then
			button.Position = UDim2.fromOffset(
				(i - 1) * (tabWidth + tabGap),
				0
			)
		end
	end
end

local function SetTab(name)
	if not pages[name] then
		return
	end

	if currentTab == name then
		return
	end

	CloseTransientPopups()

	local previousTab = currentTab
	currentTab = name

	local index = tabIndices[name]
	if index then
		local targetX = (index - 1) * (tabWidth + tabGap)

		if tabIndicatorTween then
			tabIndicatorTween:Cancel()
		end

		tabIndicatorTween = TweenService:Create(
			tabIndicator,
			TweenInfo.new(
				0.20,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				Position = UDim2.fromOffset(targetX, 0),
				Size = UDim2.fromOffset(tabWidth, 2),
			}
		)
		tabIndicatorTween:Play()

		if tabIndicatorGlowTween then
			tabIndicatorGlowTween:Cancel()
		end

		tabIndicatorGlowTween = TweenService:Create(
			tabIndicatorGlow,
			TweenInfo.new(
				0.22,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				Position = UDim2.fromOffset(targetX, 1),
				Size = UDim2.fromOffset(tabWidth, 3),
			}
		)
		tabIndicatorGlowTween:Play()
	end

	for tabName, button in pairs(tabButtons) do
		local selected = tabName == name

		Tween(button, {
			BackgroundColor3 = selected
				and Color3.fromRGB(25, 23, 27)
				or Color3.fromRGB(17, 17, 18),

			TextColor3 = selected
				and C.Text
				or C.Muted,
		}, 0.16)
	end

	if previousTab and previousTab ~= name and pages[previousTab] then
		local oldPage = pages[previousTab]

		if tabPageTweens[previousTab] then
			tabPageTweens[previousTab]:Cancel()
			tabPageTweens[previousTab] = nil
		end

		local fadeOut = TweenService:Create(
			oldPage,
			TweenInfo.new(
				MOTION.TabOut,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				GroupTransparency = 1,
				Position = UDim2.fromOffset(-3, 0),
			}
		)

		tabPageTweens[previousTab] = fadeOut
		fadeOut:Play()

		fadeOut.Completed:Connect(function(playbackState)
			if tabPageTweens[previousTab] == fadeOut then
				tabPageTweens[previousTab] = nil
			end

			if playbackState == Enum.PlaybackState.Completed
				and currentTab ~= previousTab
				and oldPage.Parent then

				oldPage.Visible = false
				oldPage.Position = UDim2.fromOffset(0, 0)
			end
		end)
	end

	local nextPage = pages[name]
	nextPage.Visible = true
	nextPage.GroupTransparency = previousTab and 1 or 0
	nextPage.Position = previousTab
		and UDim2.fromOffset(3, 0)
		or UDim2.fromOffset(0, 0)

	if previousTab then
		if tabPageTweens[name] then
			tabPageTweens[name]:Cancel()
			tabPageTweens[name] = nil
		end

		local fadeIn = TweenService:Create(
			nextPage,
			TweenInfo.new(
				MOTION.TabIn,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				GroupTransparency = 0,
				Position = UDim2.fromOffset(0, 0),
			}
		)

		tabPageTweens[name] = fadeIn
		fadeIn:Play()
	end
end

local function Section(parent, titleText, height)
	local section = New("Frame", {
		Parent = parent,
		Size = UDim2.new(1, -1, 0, height or 180),
		BackgroundColor3 = C.Panel,
		BorderSizePixel = 0,
	})
	Stroke(section, C.Border, 0.46)
	Corner(section, 4)

	local accent = New("Frame", {
		Parent = section,
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
	})
	Corner(accent, 2)

	local sectionTitle = Label(
		section,
		titleText or "section",
		UDim2.new(1, -10, 0, 20),
		C.Text
	)
	sectionTitle.Position = UDim2.fromOffset(6, 4)
	sectionTitle.TextSize = 13

	New("Frame", {
		Parent = section,
		Position = UDim2.fromOffset(6, 24),
		Size = UDim2.new(1, -12, 0, 1),
		BackgroundColor3 = C.BorderSoft,
		BackgroundTransparency = 0.38,
		BorderSizePixel = 0,
	})

	local body = New("Frame", {
		Parent = section,
		Position = UDim2.fromOffset(6, 25),
		Size = UDim2.new(1, -12, 1, -31),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	return section, body
end

local function AddToggle(parent, y, text, default, callback)
	local row = New("TextButton", {
		Parent = parent,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	})

	local button = New("Frame", {
		Parent = row,
		Position = UDim2.fromOffset(1, 4),
		Size = UDim2.fromOffset(13, 13),
		BackgroundColor3 = Color3.fromRGB(18, 18, 20),
		BorderSizePixel = 0,
	})
	Corner(button, 2)

	local gradientFill = New("Frame", {
		Parent = button,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = default and 0 or 1,
		BorderSizePixel = 0,
	})
	Corner(gradientFill, 2)

	New("UIGradient", {
		Parent = gradientFill,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(91, 51, 101)),
			ColorSequenceKeypoint.new(0.50, C.Accent),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(226, 162, 235)),
		}),
	})

	local name = Label(
		row,
		text or "",
		UDim2.new(1, -20, 1, 0),
		C.Text
	)
	name.Position = UDim2.fromOffset(19, 0)

	local state = default == true
	local hovering = false

	local function Visual()
		Tween(button, {
			BackgroundColor3 = hovering
				and Color3.fromRGB(24, 23, 26)
				or Color3.fromRGB(18, 18, 20),
		}, 0.11)

		Tween(gradientFill, {
			BackgroundTransparency = state
				and (hovering and 0.04 or 0)
				or 1,
		}, 0.11)
	end

	local function Set(value, fire)
		state = value == true
		Visual()

		if fire and callback then
			callback(state)
		end
	end

	Track(row.MouseEnter:Connect(function()
		hovering = true
		Visual()
	end))

	Track(row.MouseLeave:Connect(function()
		hovering = false
		Visual()
	end))

	Track(row.MouseButton1Click:Connect(function()
		Set(not state, true)
	end))

	Visual()

	return {
		Set = function(value)
			Set(value, true)
		end,

		Get = function()
			return state
		end,
	}
end

local function AddSlider(parent, y, text, minValue, maxValue, default, callback)
	local name = Label(
		parent,
		text or "",
		UDim2.new(0.72, 0, 0, 16),
		C.Text
	)
	name.Position = UDim2.fromOffset(0, y)

	local valueLabel = Label(
		parent,
		"",
		UDim2.new(0.28, 0, 0, 16),
		C.Muted,
		Enum.TextXAlignment.Right
	)
	valueLabel.Position = UDim2.new(0.72, 0, 0, y)
	valueLabel.TextSize = 12

	local hitbox = New("Frame", {
		Parent = parent,
		Position = UDim2.fromOffset(0, y + 15),
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = true,
	})

	local track = New("Frame", {
		Parent = hitbox,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 5, 0.5, 0),
		Size = UDim2.new(1, -10, 0, 3),
		BackgroundColor3 = Color3.fromRGB(31, 31, 34),
		BorderSizePixel = 0,
	})
	Corner(track, 3)

	local fill = New("Frame", {
		Parent = track,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	Corner(fill, 3)

	New("UIGradient", {
		Parent = fill,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(92, 54, 101)),
			ColorSequenceKeypoint.new(0.48, C.Accent),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(226, 162, 235)),
		}),
	})

	local thumb = New("Frame", {
		Parent = hitbox,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 5, 0.5, 0),
		Size = UDim2.fromOffset(3, 10),
		BackgroundColor3 = Color3.fromRGB(220, 171, 226),
		BorderSizePixel = 0,
		ZIndex = 5,
	})
	Corner(thumb, 3)

	local dragging = false
	local current = default or minValue

	local function Format(value)
		if math.abs(value - math.floor(value)) < 0.001 then
			return tostring(math.floor(value))
		end

		return string.format("%.2f", value)
	end

	local function Update(value, fire, instant)
		value = math.clamp(value, minValue, maxValue)
		current = value

		local alpha = 0
		if maxValue ~= minValue then
			alpha = (value - minValue) / (maxValue - minValue)
		end

		if instant then
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			thumb.Position = UDim2.new(
				alpha,
				5 - (alpha * 10),
				0.5,
				0
			)
		else
			Tween(fill, {
				Size = UDim2.new(alpha, 0, 1, 0),
			}, 0.09)

			Tween(thumb, {
				Position = UDim2.new(
					alpha,
					5 - (alpha * 10),
					0.5,
					0
				),
			}, 0.09)
		end

		valueLabel.Text = Format(value)

		if fire and callback then
			callback(value)
		end
	end

	local function FromMouse(x)
		local left = hitbox.AbsolutePosition.X + 5
		local width = math.max(hitbox.AbsoluteSize.X - 10, 1)
		local alpha = math.clamp((x - left) / width, 0, 1)

		local value = minValue + ((maxValue - minValue) * alpha)
		value = math.floor(value * 100 + 0.5) / 100

		Update(value, true, true)
	end

	Track(hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			Tween(thumb, {
				Size = UDim2.fromOffset(6, 16),
			}, 0.10)

			FromMouse(input.Position.X)
		end
	end))

	Track(UserInputService.InputChanged:Connect(function(input)
		if dragging
			and input.UserInputType == Enum.UserInputType.MouseMovement then

			FromMouse(input.Position.X)
		end
	end))

	Track(UserInputService.InputEnded:Connect(function(input)
		if dragging
			and input.UserInputType == Enum.UserInputType.MouseButton1 then

			dragging = false
			Tween(thumb, {
				Size = UDim2.fromOffset(3, 10),
			}, 0.12)
		end
	end))

	Update(current, false, true)

	return {
		Set = function(value)
			Update(value, true, false)
		end,

		Get = function()
			return current
		end,
	}
end

local function AddDropdown(parent, y, text, options, default, callback)
	options = options or {}

	local current = default or options[1]

	local name = Label(
		parent,
		text or "",
		UDim2.new(1, 0, 0, 17),
		C.Text
	)
	name.Position = UDim2.fromOffset(0, y)

	local button = New("TextButton", {
		Parent = parent,
		Position = UDim2.fromOffset(0, y + 20),
		Size = UDim2.new(1, 0, 0, 19),

		BackgroundColor3 = Color3.fromRGB(13, 13, 14),
		BorderSizePixel = 0,
		AutoButtonColor = false,

		Text = "",
		ZIndex = 70,
	})
	Stroke(button, C.BorderSoft, 0.50)
	Corner(button, 4)

	local valueText = Label(
		button,
		tostring(current or ""),
		UDim2.new(1, -24, 1, 0),
		C.Text
	)
	valueText.Position = UDim2.fromOffset(6, 0)
	valueText.TextSize = 12

	local arrow = Label(
		button,
		"›",
		UDim2.fromOffset(18, 19),
		C.Muted,
		Enum.TextXAlignment.Center
	)
	arrow.Position = UDim2.new(1, -19, 0, 0)
	arrow.TextSize = 14

	local popup = nil
	local opened = false
	local popupConnections = {}

	local function DisconnectPopupConnections()
		for i = #popupConnections, 1, -1 do
			local c = popupConnections[i]

			if c and c.Connected then
				c:Disconnect()
			end

			popupConnections[i] = nil
		end
	end

	local function Close()
		opened = false
		DisconnectPopupConnections()

		if activeDropdownClose == Close then
			activeDropdownClose = nil
			activeDropdownPopup = nil
			activeDropdownButton = nil
		end

		Tween(arrow, {
			Rotation = 0,
			TextColor3 = C.Muted,
		}, MOTION.Popup)

		if popup and popup.Parent then
			local old = popup
			popup = nil

			Tween(old, {
				GroupTransparency = 1,
			}, 0.09)

			task.delay(0.10, function()
				if old and old.Parent then
					old:Destroy()
				end
			end)
		end
	end

	local function Open()
		if opened then
			Close()
			return
		end

		CloseTransientPopups()

		opened = true

		local rowHeight = 20
		local popupHeight = math.max(20, #options * rowHeight)
		local popupWidth = math.max(button.AbsoluteSize.X, 110)

		local x =
			button.AbsolutePosition.X
			- main.AbsolutePosition.X

		local yPos =
			button.AbsolutePosition.Y
			- main.AbsolutePosition.Y
			+ button.AbsoluteSize.Y
			+ 3

		popup = New("CanvasGroup", {
			Parent = main,
			Position = UDim2.fromOffset(x, yPos),
			Size = UDim2.fromOffset(popupWidth, popupHeight),

			BackgroundColor3 = Color3.fromRGB(14, 14, 16),
			BorderSizePixel = 0,
			GroupTransparency = 1,

			ZIndex = 460,
		})
		Stroke(popup, C.Border, 0.36)
		Corner(popup, 5)

		activeDropdownClose = Close
		activeDropdownPopup = popup
		activeDropdownButton = button

		Tween(arrow, {
			Rotation = 90,
			TextColor3 = C.Accent,
		}, MOTION.Popup)

		Tween(popup, {
			GroupTransparency = 0,
		}, MOTION.Popup)

		for i, option in ipairs(options) do
			local selected = option == current

			local opt = New("TextButton", {
				Parent = popup,
				Position = UDim2.fromOffset(
					0,
					(i - 1) * rowHeight
				),
				Size = UDim2.new(1, 0, 0, rowHeight),

				BackgroundColor3 = selected
					and Color3.fromRGB(29, 22, 31)
					or Color3.fromRGB(14, 14, 16),

				BorderSizePixel = 0,
				AutoButtonColor = false,

				Text = tostring(option),
				TextColor3 = selected and C.Accent or C.Text,
				TextSize = 12,
				Font = FONT,

				ZIndex = 461,
			})

			local enter = opt.MouseEnter:Connect(function()
				Tween(opt, {
					BackgroundColor3 = C.PanelHover,
				}, 0.07)
			end)

			local click = opt.MouseButton1Click:Connect(function()
				current = option
				valueText.Text = tostring(option)
				Close()

				if callback then
					callback(current)
				end
			end)

			table.insert(popupConnections, enter)
			table.insert(popupConnections, click)

			Track(enter)
			Track(click)
		end
	end

	Track(button.MouseButton1Click:Connect(Open))

	return {
		Get = function()
			return current
		end,

		Set = function(value)
			if table.find(options, value) then
				current = value
				valueText.Text = tostring(value)

				if callback then
					callback(current)
				end
			end
		end,

		Close = Close,
	}
end

function Library:CreateTab(name)
	if unloaded then
		return nil
	end

	name = tostring(name or "")
	if name == "" then
		return nil
	end

	if pages[name] then
		return pages[name]._API
	end

	table.insert(tabs, name)

	local page = New("CanvasGroup", {
		Name = name,
		Parent = contentRoot,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
	})
	pages[name] = page

	local button = New("TextButton", {
		Parent = tabBar,
		Size = UDim2.fromOffset(tabWidth, 25),

		BackgroundColor3 = Color3.fromRGB(17, 17, 18),
		BorderSizePixel = 0,
		AutoButtonColor = false,

		Text = name,
		TextColor3 = C.Muted,
		TextSize = 14,
		Font = FONT,

		ZIndex = 10,
	})
	Stroke(button, C.BorderSoft, 0.56)
	Corner(button, 4)

	tabButtons[name] = button
	RefreshTabLayout()

	Track(button.MouseEnter:Connect(function()
		if currentTab ~= name then
			Tween(button, {
				BackgroundColor3 = Color3.fromRGB(22, 21, 23),
				TextColor3 = Color3.fromRGB(174, 174, 181),
			}, MOTION.Hover)
		end
	end))

	Track(button.MouseLeave:Connect(function()
		if currentTab ~= name then
			Tween(button, {
				BackgroundColor3 = Color3.fromRGB(17, 17, 18),
				TextColor3 = C.Muted,
			}, MOTION.Hover)
		end
	end))

	Track(button.MouseButton1Click:Connect(function()
		SetTab(name)
	end))

	local tabAPI = {}

	function tabAPI:Select()
		SetTab(name)
	end

	function tabAPI:GetPage()
		return page
	end

	function tabAPI:CreateColumn(side)
		local frame = New("ScrollingFrame", {
			Parent = page,

			Position = side == "Right"
				and UDim2.new(0.5, 4, 0, 0)
				or UDim2.fromOffset(0, 0),

			Size = UDim2.new(0.5, -4, 1, 0),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Color3.fromRGB(92, 67, 98),

			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
		})

		New("UIListLayout", {
			Parent = frame,
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		})

		return frame
	end

	function tabAPI:CreateSection(parent, titleText, height)
		local section, body = Section(
			parent or page,
			titleText,
			height
		)

		local sectionAPI = {
			Frame = section,
			Body = body,
		}

		function sectionAPI:AddToggle(y, text, default, callback)
			return AddToggle(
				body,
				y,
				text,
				default,
				callback
			)
		end

		function sectionAPI:AddSlider(y, text, minValue, maxValue, default, callback)
			return AddSlider(
				body,
				y,
				text,
				minValue,
				maxValue,
				default,
				callback
			)
		end

		function sectionAPI:AddDropdown(y, text, options, default, callback)
			return AddDropdown(
				body,
				y,
				text,
				options,
				default,
				callback
			)
		end

		function sectionAPI:AddLabel(y, text, color)
			local label = Label(
				body,
				text or "",
				UDim2.new(1, 0, 0, 18),
				color or C.Text
			)
			label.Position = UDim2.fromOffset(0, y)
			return label
		end

		return sectionAPI
	end

	page._API = tabAPI

	if #tabs == 1 then
		SetTab(name)
	end

	return tabAPI
end

function Library:SetTitle(text)
	title.Text = tostring(text or "")
end

function Library:SetAccent(color)
	if typeof(color) ~= "Color3" then
		return
	end

	C.Accent = color
	tabIndicator.BackgroundColor3 = color
	tabIndicatorGlow.BackgroundColor3 = color
end

function Library:SelectTab(name)
	SetTab(tostring(name or ""))
end

local notificationRoot = New("Frame", {
	Name = "Notifications",
	Parent = gui,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -12, 0, -8),
	Size = UDim2.fromOffset(380, 500),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 1900,
})

New("UIListLayout", {
	Parent = notificationRoot,
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 6),
})

local notificationOrder = 0

function Library:Notify(data, duration)
	if unloaded then
		return
	end

	local titleText = nil
	local bodyText = nil
	local lifetime = duration or 3

	if type(data) == "table" then
		titleText = data.Title or data.Header
		bodyText =
			data.Text
			or data.Message
			or data.Description

		lifetime = tonumber(
			data.Duration
			or data.Time
			or lifetime
		) or lifetime
	else
		bodyText = data
	end

	if titleText ~= nil then
		titleText = tostring(titleText)
	end

	if bodyText ~= nil then
		bodyText = tostring(bodyText)
	end

	if not titleText and not bodyText then
		return
	end

	lifetime = math.clamp(lifetime, 0.5, 30)
	notificationOrder += 1

	local width = 260
	local height = titleText and bodyText and 42 or 29

	local holder = New("Frame", {
		Parent = notificationRoot,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = notificationOrder,
		ZIndex = 1901,
	})

	local card = New("CanvasGroup", {
		Parent = holder,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 20, 0, 0),
		Size = UDim2.fromOffset(width, height),

		BackgroundColor3 = Color3.fromRGB(14, 14, 17),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,

		GroupTransparency = 1,
		ClipsDescendants = false,
		ZIndex = 1902,
	})
	Corner(card, 6)
	Stroke(card, Color3.fromRGB(61, 47, 66), 0.30)

	local y = 4

	if titleText then
		local t = Label(
			card,
			titleText,
			UDim2.new(1, -18, 0, 16),
			Color3.fromRGB(252, 252, 254)
		)
		t.Position = UDim2.fromOffset(9, y)
		t.TextSize = 14
		y += 17
	end

	if bodyText then
		local b = Label(
			card,
			bodyText,
			UDim2.new(1, -18, 0, 15),
			C.Text
		)
		b.Position = UDim2.fromOffset(9, y)
		b.TextSize = 13
	end

	local progressBack = New("Frame", {
		Parent = card,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 7, 1, -2),
		Size = UDim2.new(1, -14, 0, 2),

		BackgroundColor3 = Color3.fromRGB(39, 34, 42),
		BackgroundTransparency = 0.30,
		BorderSizePixel = 0,

		ZIndex = 1904,
	})

	local progress = New("Frame", {
		Parent = progressBack,
		Size = UDim2.new(1, 0, 0, 2),

		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,

		ZIndex = 1905,
	})

	Tween(card, {
		GroupTransparency = 0,
		Position = UDim2.new(1, 0, 0, 0),
	}, 0.16)

	TweenService:Create(
		progress,
		TweenInfo.new(
			lifetime,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
		),
		{
			Size = UDim2.new(0, 0, 0, 2),
		}
	):Play()

	task.delay(lifetime, function()
		if not holder.Parent then
			return
		end

		local hide = Tween(card, {
			GroupTransparency = 1,
			Position = UDim2.new(1, 20, 0, 0),
		}, 0.13)

		if hide then
			hide.Completed:Connect(function()
				if holder.Parent then
					holder:Destroy()
				end
			end)
		else
			holder:Destroy()
		end
	end)
end

local dragging = false
local dragStart = nil
local startPosition = nil

local resizing = false
local resizeStart = nil
local resizeStartSize = nil
local resizeTopLeft = nil

local resizeHandle = New("TextButton", {
	Name = "ResizeHandle",
	Parent = main,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, 0, 1, 0),
	Size = UDim2.fromOffset(18, 18),

	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",

	ZIndex = 1300,
})

for i = 0, 2 do
	New("Frame", {
		Parent = resizeHandle,
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.new(
			1,
			-(5 + (i * 4)),
			1,
			-(5 + (i * 4))
		),

		Size = UDim2.fromOffset(8 + (i * 2), 1),
		BackgroundColor3 = Color3.fromRGB(92, 92, 99),
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,

		Rotation = -45,
		ZIndex = 1301,
	})
end

top.Active = true

Track(top.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		if resizing then
			return
		end

		CloseTransientPopups()

		dragging = true
		dragStart = input.Position
		startPosition = main.Position

		Tween(outerOutline, {
			Color = C.AccentDark,
			Transparency = 0.04,
		}, MOTION.Fast)
	end
end))

Track(resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		if dragging then
			return
		end

		CloseTransientPopups()

		resizing = true
		resizeStart = input.Position
		resizeStartSize = main.AbsoluteSize
		resizeTopLeft = main.AbsolutePosition
	end
end))

Track(UserInputService.InputChanged:Connect(function(input)
	if dragging
		and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then

		local delta = input.Position - dragStart

		main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)

	elseif resizing
		and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then

		local delta = input.Position - resizeStart

		local tabMinimum =
			math.max(
				360,
				(#tabs * tabWidth)
				+ (math.max(#tabs - 1, 0) * tabGap)
				+ 14
			)

		local width = math.max(
			tabMinimum,
			resizeStartSize.X + delta.X
		)

		local height = math.max(
			300,
			resizeStartSize.Y + delta.Y
		)

		main.Size = UDim2.fromOffset(width, height)

		main.Position = UDim2.fromOffset(
			resizeTopLeft.X + (width * 0.5),
			resizeTopLeft.Y + (height * 0.5)
		)
	end
end))

Track(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		if dragging then
			dragging = false
		end

		if resizing then
			resizing = false
		end

		Tween(outerOutline, {
			Color = Color3.fromRGB(72, 72, 78),
			Transparency = 0.12,
		}, MOTION.Hover)
	end
end))

local opened = true
local visibilityTween = nil
local positionTween = nil
local restingPosition = main.Position

local function OffsetPosition(position, yOffset)
	return UDim2.new(
		position.X.Scale,
		position.X.Offset,
		position.Y.Scale,
		position.Y.Offset + yOffset
	)
end

local function SetVisible(state)
	if opened == state or unloaded then
		return
	end

	opened = state

	if visibilityTween then
		visibilityTween:Cancel()
	end

	if positionTween then
		positionTween:Cancel()
	end

	if state then
		main.Visible = true
		main.GroupTransparency = 1
		main.Position = OffsetPosition(restingPosition, 6)

		visibilityTween = TweenService:Create(
			main,
			TweenInfo.new(
				MOTION.WindowIn,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				GroupTransparency = 0,
			}
		)

		positionTween = TweenService:Create(
			main,
			TweenInfo.new(
				MOTION.WindowIn,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				Position = restingPosition,
			}
		)

		visibilityTween:Play()
		positionTween:Play()
	else
		CloseTransientPopups()

		restingPosition = main.Position

		visibilityTween = TweenService:Create(
			main,
			TweenInfo.new(
				MOTION.WindowOut,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.InOut
			),
			{
				GroupTransparency = 1,
			}
		)

		positionTween = TweenService:Create(
			main,
			TweenInfo.new(
				MOTION.WindowOut,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.InOut
			),
			{
				Position = OffsetPosition(restingPosition, 6),
			}
		)

		visibilityTween:Play()
		positionTween:Play()

		visibilityTween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed
				and not opened
				and not unloaded then

				main.Visible = false
				main.Position = restingPosition
			end
		end)
	end
end

Track(UserInputService.InputBegan:Connect(function(input, processed)
	if processed or unloaded or capturingKeybind then
		return
	end

	if input.KeyCode == Enum.KeyCode.RightShift then
		SetVisible(not opened)
	end
end))

function Library:SetVisible(state)
	SetVisible(state == true)
end

function Library:Toggle()
	SetVisible(not opened)
end

function Library:Unload()
	if unloaded then
		return
	end

	unloaded = true
	CloseTransientPopups()

	DisconnectAll()

	if gui and gui.Parent then
		gui:Destroy()
	end

	if RuntimeEnvironment.__UI_V5_RUNTIME == Library then
		RuntimeEnvironment.__UI_V5_RUNTIME = nil
	end
end

main.Visible = true
main.GroupTransparency = 1
restingPosition = main.Position
main.Position = OffsetPosition(restingPosition, 6)

TweenService:Create(
	main,
	TweenInfo.new(
		MOTION.WindowIn,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	),
	{
		GroupTransparency = 0,
		Position = restingPosition,
	}
):Play()

return Library
