local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local guiParent = playerGui

if type(gethui) == "function" then
	local ok, hiddenGui = pcall(gethui)

	if ok and hiddenGui then
		guiParent = hiddenGui
	end
end

local RuntimeEnvironment = (getgenv and getgenv()) or _G
local existingRuntime = RuntimeEnvironment.__UI_V5_RUNTIME

if type(existingRuntime) == "table"
	and type(existingRuntime.Unload) == "function" then

	pcall(function()
		existingRuntime:Unload()
	end)
end

RuntimeEnvironment.__UI_V5_RUNTIME = nil

pcall(function()
	UserInputService.MouseIconEnabled = true
end)

local function RemoveStaleGui(parent, name)
	if not parent then
		return
	end

	local old = parent:FindFirstChild(name)

	if old then
		pcall(function()
			old:Destroy()
		end)
	end
end

RemoveStaleGui(guiParent, "UI-v5-Cursor")
RemoveStaleGui(playerGui, "UI-v5-Cursor")

RemoveStaleGui(guiParent, "UI-v5")
RemoveStaleGui(playerGui, "UI-v5")

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

local function SafeCall(callback, ...)
	if type(callback) ~= "function" or unloaded then
		return
	end

	pcall(callback, ...)
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

	Control = Color3.fromRGB(13, 13, 14),
	Control2 = Color3.fromRGB(14, 14, 16),
	ControlHover = Color3.fromRGB(24, 23, 26),
	ToggleOff = Color3.fromRGB(18, 18, 20),
	Popup = Color3.fromRGB(20, 20, 22),
	Selected = Color3.fromRGB(27, 24, 29),
	Track = Color3.fromRGB(31, 31, 34),
	Thumb = Color3.fromRGB(220, 171, 226),

	Border = Color3.fromRGB(50, 50, 55),
	BorderSoft = Color3.fromRGB(38, 38, 42),
	Outline = Color3.fromRGB(72, 72, 78),
	InnerOutline = Color3.fromRGB(35, 35, 39),

	Text = Color3.fromRGB(210, 210, 214),
	TextStrong = Color3.fromRGB(252, 252, 254),
	Muted = Color3.fromRGB(135, 135, 142),
	Dim = Color3.fromRGB(83, 83, 90),

	Accent = Color3.fromRGB(178, 112, 187),
	AccentDark = Color3.fromRGB(100, 60, 108),
	AccentLight = Color3.fromRGB(226, 162, 235),

	Notification = Color3.fromRGB(29, 27, 32),
	NotificationBorder = Color3.fromRGB(104, 72, 112),
	NotificationTitle = Color3.fromRGB(246, 246, 249),
	NotificationText = Color3.fromRGB(205, 205, 211),
	NotificationSeparator = Color3.fromRGB(178, 112, 187),
	NotificationRailGlow = Color3.fromRGB(178, 112, 187),

	NotificationRailA = Color3.fromRGB(82, 48, 92),
	NotificationRailB = Color3.fromRGB(178, 112, 187),
	NotificationRailC = Color3.fromRGB(226, 162, 235),

	ProgressBack = Color3.fromRGB(39, 34, 42),
	NotificationProgressA = Color3.fromRGB(82, 48, 92),
	NotificationProgressB = Color3.fromRGB(178, 112, 187),
	NotificationProgressC = Color3.fromRGB(226, 162, 235),

	Watermark = Color3.fromRGB(17, 17, 19),
	WatermarkBorder = Color3.fromRGB(64, 57, 68),
}

local FONT = Enum.Font.Code

local MOTION = {
	Fast = 0.10,
	Hover = 0.14,
	Control = 0.16,
	Popup = 0.14,
	TabOut = 0.09,
	TabIn = 0.14,
	WindowIn = 0.22,
	WindowOut = 0.18,
}

local themeBindings = setmetatable({}, {__mode = "k"})
local themeGradients = setmetatable({}, {__mode = "k"})
local notificationRailGradients = setmetatable({}, {__mode = "k"})
local notificationProgressGradients = setmetatable({}, {__mode = "k"})

local function BuildNotificationRailSequence()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, C.NotificationRailA),
		ColorSequenceKeypoint.new(0.50, C.NotificationRailB),
		ColorSequenceKeypoint.new(1.00, C.NotificationRailC),
	})
end

local function BuildNotificationProgressSequence()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, C.NotificationProgressA),
		ColorSequenceKeypoint.new(0.50, C.NotificationProgressB),
		ColorSequenceKeypoint.new(1.00, C.NotificationProgressC),
	})
end

local function BindNotificationRailGradient(gradient)
	if not gradient then
		return gradient
	end

	notificationRailGradients[gradient] = true
	gradient.Color = BuildNotificationRailSequence()

	return gradient
end

local function BindNotificationProgressGradient(gradient)
	if not gradient then
		return gradient
	end

	notificationProgressGradients[gradient] = true
	gradient.Color = BuildNotificationProgressSequence()

	return gradient
end

local function SameColor(a, b)
	return typeof(a) == "Color3"
		and typeof(b) == "Color3"
		and math.abs(a.R - b.R) < 0.0001
		and math.abs(a.G - b.G) < 0.0001
		and math.abs(a.B - b.B) < 0.0001
end

local function ThemeKeyForColor(color)
	if typeof(color) ~= "Color3" then
		return nil
	end

	for key, value in pairs(C) do
		if typeof(value) == "Color3" and SameColor(color, value) then
			return key
		end
	end

	return nil
end

local function BindThemeProperty(obj, property, key)
	if not obj or not property or not key then
		return
	end

	local bindings = themeBindings[obj]
	if not bindings then
		bindings = {}
		themeBindings[obj] = bindings
	end

	bindings[property] = key
end

local function BuildAccentSequence()
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, C.AccentDark),
		ColorSequenceKeypoint.new(0.50, C.Accent),
		ColorSequenceKeypoint.new(1.00, C.AccentLight),
	})
end

local function BindAccentGradient(gradient)
	if not gradient then
		return gradient
	end

	themeGradients[gradient] = true
	gradient.Color = BuildAccentSequence()
	return gradient
end

local function RefreshTheme()
	for obj, bindings in pairs(themeBindings) do
		if obj and obj.Parent then
			for property, key in pairs(bindings) do
				local value = C[key]
				if typeof(value) == "Color3" then
					pcall(function()
						obj[property] = value
					end)
				end
			end
		end
	end

	for gradient in pairs(themeGradients) do
		if gradient and gradient.Parent then
			gradient.Color = BuildAccentSequence()
		end
	end

	for gradient in pairs(notificationRailGradients) do
		if gradient and gradient.Parent then
			gradient.Color = BuildNotificationRailSequence()
		end
	end

	for gradient in pairs(notificationProgressGradients) do
		if gradient and gradient.Parent then
			gradient.Color = BuildNotificationProgressSequence()
		end
	end
end

local function New(className, props)
	local obj = Instance.new(className)

	for property, value in pairs(props or {}) do
		obj[property] = value

		if typeof(value) == "Color3" then
			local key = ThemeKeyForColor(value)
			if key then
				BindThemeProperty(obj, property, key)
			end
		end
	end

	return obj
end

local activeTweens = setmetatable({}, {__mode = "k"})

local function Tween(obj, props, duration)
	if unloaded or not obj or not obj.Parent then
		return nil
	end

	local previous = activeTweens[obj]
	if previous then
		pcall(function()
			previous:Cancel()
		end)
	end

	local tween = TweenService:Create(
		obj,
		TweenInfo.new(
			duration or MOTION.Control,
			Enum.EasingStyle.Quart,
			Enum.EasingDirection.Out
		),
		props
	)

	activeTweens[obj] = tween

	tween.Completed:Connect(function()
		if activeTweens[obj] == tween then
			activeTweens[obj] = nil
		end
	end)

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
	Parent = guiParent,
	ResetOnSpawn = false,
	DisplayOrder = 2147483647,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
})

pcall(function()
	gui.OnTopOfCoreBlur = true
end)

local Library = {}
Library.Version = "5.0.12-clean"
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
	Color = C.Outline,
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
	Color = C.InnerOutline,
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
	"",
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
local tabAPIs = {}
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
	if not pages[name] or currentTab == name then
		return
	end

	CloseTransientPopups()
	currentTab = name

	local index = tabIndices[name]
	if index then
		local targetX = (index - 1) * (tabWidth + tabGap)

		if tabIndicatorTween then
			tabIndicatorTween:Cancel()
		end

		if tabIndicatorGlowTween then
			tabIndicatorGlowTween:Cancel()
		end

		tabIndicatorTween = TweenService:Create(
			tabIndicator,
			TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromOffset(targetX, 0),
				Size = UDim2.fromOffset(tabWidth, 2),
			}
		)

		tabIndicatorGlowTween = TweenService:Create(
			tabIndicatorGlow,
			TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{
				Position = UDim2.fromOffset(targetX, 1),
				Size = UDim2.fromOffset(tabWidth, 3),
			}
		)

		tabIndicatorTween:Play()
		tabIndicatorGlowTween:Play()
	end

	for tabName, button in pairs(tabButtons) do
		local selected = tabName == name

		Tween(button, {
			BackgroundColor3 = selected
				and C.Selected
				or C.Control2,
			TextColor3 = selected and C.Text or C.Muted,
		}, MOTION.Hover)
	end

	for tabName, page in pairs(pages) do
		local oldTween = tabPageTweens[tabName]

		if oldTween then
			pcall(function()
				oldTween:Cancel()
			end)

			tabPageTweens[tabName] = nil
		end

		if tabName ~= name then
			page.Visible = false
			page.GroupTransparency = 1
			page.Position = UDim2.fromOffset(0, 0)
		end
	end

	local nextPage = pages[name]
	nextPage.Visible = true
	nextPage.GroupTransparency = 1
	nextPage.Position = UDim2.fromOffset(5, 0)

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

	fadeIn.Completed:Connect(function()
		if tabPageTweens[name] == fadeIn then
			tabPageTweens[name] = nil
		end
	end)

	fadeIn:Play()
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
		titleText or "",
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
		BackgroundColor3 = C.ToggleOff,
		BorderSizePixel = 0,
	})
	Corner(button, 2)

	local toggleOutline = New("UIStroke", {
		Parent = button,
		Color = C.Outline,
		Thickness = 1,
		Transparency = 0.08,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	BindThemeProperty(
		toggleOutline,
		"Color",
		"Outline"
	)

	local gradientFill = New("Frame", {
		Parent = button,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = default and 0 or 1,
		BorderSizePixel = 0,
	})
	Corner(gradientFill, 2)

	BindAccentGradient(New("UIGradient", {
		Parent = gradientFill,
	}))

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
				and C.ControlHover
				or C.ToggleOff,
		}, 0.11)

		Tween(gradientFill, {
			BackgroundTransparency = state
				and (hovering and 0.04 or 0)
				or 1,
		}, 0.11)

		Tween(toggleOutline, {
			Transparency = state
				and 0
				or (hovering and 0.02 or 0.08),
			Thickness = state
				and 1.15
				or 1,
		}, 0.11)
	end

	local function Set(value, fire)
		state = value == true
		Visual()

		if fire and callback then
			SafeCall(callback, state)
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
		BackgroundColor3 = C.Track,
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

	BindAccentGradient(New("UIGradient", {
		Parent = fill,
	}))

	local thumbGlow = New("Frame", {
		Parent = hitbox,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 5, 0.5, 0),
		Size = UDim2.fromOffset(12, 18),
		BackgroundColor3 = C.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 4,
	})
	Corner(thumbGlow, 8)

	local thumb = New("Frame", {
		Parent = hitbox,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 5, 0.5, 0),
		Size = UDim2.fromOffset(3, 10),
		BackgroundColor3 = C.Thumb,
		BorderSizePixel = 0,
		ZIndex = 5,
	})
	Corner(thumb, 3)

	local dragging = false
	local hovering = false
	local current = default or minValue

	local function Format(value)
		if math.abs(value - math.floor(value)) < 0.001 then
			return tostring(math.floor(value))
		end

		return string.format("%.2f", value)
	end

	local function SetActiveVisual(active)
		Tween(track, {
			Size = UDim2.new(
				1,
				-10,
				0,
				active and 5 or 3
			),
		}, active and 0.09 or 0.13)

		Tween(thumb, {
			Size = active
				and UDim2.fromOffset(6, 14)
				or UDim2.fromOffset(3, 10),
		}, active and 0.09 or 0.13)

		Tween(thumbGlow, {
			BackgroundTransparency = active and 0.80 or 1,
		}, active and 0.09 or 0.13)

		Tween(valueLabel, {
			TextColor3 = active and C.AccentLight or C.Muted,
		}, active and 0.09 or 0.13)
	end

	local function Update(value, fire, instant)
		value = math.clamp(value, minValue, maxValue)
		current = value

		local alpha = 0

		if maxValue ~= minValue then
			alpha = (value - minValue) / (maxValue - minValue)
		end

		local targetFill =
			UDim2.new(alpha, 0, 1, 0)

		local targetThumb =
			UDim2.new(
				alpha,
				5 - (alpha * 10),
				0.5,
				0
			)

		if instant then
			fill.Size = targetFill
			thumb.Position = targetThumb
			thumbGlow.Position = targetThumb
		else
			Tween(fill, {
				Size = targetFill,
			}, dragging and 0.055 or 0.10)

			Tween(thumb, {
				Position = targetThumb,
			}, dragging and 0.055 or 0.10)

			Tween(thumbGlow, {
				Position = targetThumb,
			}, dragging and 0.055 or 0.10)
		end

		valueLabel.Text = Format(value)

		if fire then
			SafeCall(callback, value)
		end
	end

	local function FromPointer(x)
		local left = hitbox.AbsolutePosition.X + 5
		local width = math.max(hitbox.AbsoluteSize.X - 10, 1)
		local alpha = math.clamp((x - left) / width, 0, 1)

		local value =
			minValue
			+ ((maxValue - minValue) * alpha)

		value =
			math.floor(value * 100 + 0.5)
			/ 100

		Update(value, true, false)
	end

	Track(hitbox.MouseEnter:Connect(function()
		hovering = true

		if not dragging then
			SetActiveVisual(true)
		end
	end))

	Track(hitbox.MouseLeave:Connect(function()
		hovering = false

		if not dragging then
			SetActiveVisual(false)
		end
	end))

	Track(hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			SetActiveVisual(true)
			FromPointer(input.Position.X)
		end
	end))

	Track(UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			FromPointer(input.Position.X)
		end
	end))

	Track(UserInputService.InputEnded:Connect(function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = false
			SetActiveVisual(hovering)
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

local function AddKeybind(parent, y, text, defaultKey, defaultMode, callback)
	local modes = {"Hold", "Toggle", "Always On"}

	local currentKey = defaultKey
	local currentMode = defaultMode or "Toggle"

	local listening = false
	local held = false
	local toggled = false

	local popup = nil
	local popupConnections = {}

	local label = Label(
		parent,
		text or "",
		UDim2.new(1, -70, 0, 20),
		C.Text
	)
	label.Position = UDim2.fromOffset(0, y)

	local button = New("TextButton", {
		Parent = parent,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, y),
		Size = UDim2.fromOffset(62, 20),

		BackgroundColor3 = C.Control,
		BorderSizePixel = 0,
		AutoButtonColor = false,

		Text = "none",
		TextColor3 = C.Muted,
		TextSize = 12,
		Font = FONT,

		ZIndex = 80,
	})

	local bindStroke = Stroke(button, C.BorderSoft, 0.48)
	Corner(button, 4)

	local function KeyName(keyCode)
		if not keyCode or keyCode == Enum.KeyCode.Unknown then
			return "none"
		end

		local aliases = {
			LeftShift = "LShift",
			RightShift = "RShift",
			LeftControl = "LCtrl",
			RightControl = "RCtrl",
			LeftAlt = "LAlt",
			RightAlt = "RAlt",
			CapsLock = "Caps",

			Zero = "0",
			One = "1",
			Two = "2",
			Three = "3",
			Four = "4",
			Five = "5",
			Six = "6",
			Seven = "7",
			Eight = "8",
			Nine = "9",

			KeypadZero = "0",
			KeypadOne = "1",
			KeypadTwo = "2",
			KeypadThree = "3",
			KeypadFour = "4",
			KeypadFive = "5",
			KeypadSix = "6",
			KeypadSeven = "7",
			KeypadEight = "8",
			KeypadNine = "9",

			Backquote = "`",
			Minus = "-",
			Equals = "=",
			LeftBracket = "[",
			RightBracket = "]",
			BackSlash = "\\",
			Semicolon = ";",
			Quote = "'",
			Comma = ",",
			Period = ".",
			Slash = "/",
		}

		return aliases[keyCode.Name] or keyCode.Name
	end

	local function Emit(active)
		if callback and not unloaded then
			SafeCall(callback, active, currentMode, currentKey)
		end
	end

	local function GetActiveState()
		if currentMode == "Always On" then
			return true
		elseif currentMode == "Hold" then
			return held
		else
			return toggled
		end
	end

	local function RefreshButton()
		if listening then
			button.Text = "[ ... ]"

			Tween(button, {
				TextColor3 = C.Accent,
				BackgroundColor3 = C.Selected,
			}, MOTION.Fast)

			Tween(bindStroke, {
				Color = C.Accent,
				Transparency = 0.16,
			}, MOTION.Fast)
			return
		end

		if currentKey then
			button.Text = KeyName(currentKey)

			Tween(button, {
				TextColor3 = C.Text,
				BackgroundColor3 = C.Control,
			}, MOTION.Hover)

			Tween(bindStroke, {
				Color = C.BorderSoft,
				Transparency = 0.40,
			}, MOTION.Hover)
		else
			button.Text = "none"

			Tween(button, {
				TextColor3 = C.Muted,
				BackgroundColor3 = C.Control,
			}, MOTION.Hover)

			Tween(bindStroke, {
				Color = C.BorderSoft,
				Transparency = 0.48,
			}, MOTION.Hover)
		end
	end

	local function DisconnectPopupConnections()
		for i = #popupConnections, 1, -1 do
			local c = popupConnections[i]

			if c and c.Connected then
				c:Disconnect()
			end

			popupConnections[i] = nil
		end
	end

	local function ClosePopup()
		DisconnectPopupConnections()

		if activeKeybindClose == ClosePopup then
			activeKeybindClose = nil
		end

		if activeKeybindPopup == popup then
			activeKeybindPopup = nil
		end

		if activeKeybindButton == button then
			activeKeybindButton = nil
		end

		if popup and popup.Parent then
			local old = popup
			popup = nil

			local hide = Tween(old, {
				GroupTransparency = 1,
			}, 0.09)

			local removed = false

			local function RemovePopup()
				if removed then
					return
				end

				removed = true

				if old and old.Parent then
					old:Destroy()
				end
			end

			if hide then
				hide.Completed:Connect(RemovePopup)
			end

			task.delay(0.12, RemovePopup)
		end
	end

	local function SetMode(mode)
		if not table.find(modes, mode) then
			return
		end

		held = false
		toggled = false
		currentMode = mode

		if currentMode == "Always On" then
			Emit(true)
		else
			Emit(false)
		end
	end

	local function OpenPopup()
		if unloaded or listening or not currentKey then
			return
		end

		if popup and popup.Parent then
			ClosePopup()
			return
		end

		if activeKeybindClose and activeKeybindClose ~= ClosePopup then
			activeKeybindClose()
		end

		if activeColorPickerClose then
			activeColorPickerClose()
		end

		if activeDropdownClose then
			activeDropdownClose()
		end

		local popupWidth = 112
		local rowHeight = 22
		local popupHeight = rowHeight * #modes

		local x =
			button.AbsolutePosition.X
			- main.AbsolutePosition.X
			+ button.AbsoluteSize.X
			- popupWidth

		local py =
			button.AbsolutePosition.Y
			- main.AbsolutePosition.Y
			+ button.AbsoluteSize.Y
			+ 3

		if py + popupHeight > main.AbsoluteSize.Y - 4 then
			py =
				button.AbsolutePosition.Y
				- main.AbsolutePosition.Y
				- popupHeight
				- 3
		end

		x = math.clamp(
			x,
			4,
			math.max(4, main.AbsoluteSize.X - popupWidth - 4)
		)

		py = math.clamp(
			py,
			4,
			math.max(4, main.AbsoluteSize.Y - popupHeight - 4)
		)

		popup = New("CanvasGroup", {
			Parent = main,
			Position = UDim2.fromOffset(x, py),
			Size = UDim2.fromOffset(popupWidth, popupHeight),

			BackgroundColor3 = C.Control2,
			BorderSizePixel = 0,
			GroupTransparency = 1,

			ZIndex = 500,
		})

		Stroke(popup, C.Border, 0.34)
		Corner(popup, 5)

		activeKeybindClose = ClosePopup
		activeKeybindPopup = popup
		activeKeybindButton = button

		Tween(popup, {
			GroupTransparency = 0,
		}, 0.10)

		for i, mode in ipairs(modes) do
			local selected = mode == currentMode

			local option = New("TextButton", {
				Parent = popup,
				Position = UDim2.fromOffset(0, (i - 1) * rowHeight),
				Size = UDim2.new(1, 0, 0, rowHeight),

				BackgroundColor3 = selected
					and C.Selected
					or C.Control2,

				BorderSizePixel = 0,
				AutoButtonColor = false,

				Text = "",
				ZIndex = 501,
			})

			if i > 1 then
				New("Frame", {
					Parent = option,
					Position = UDim2.fromOffset(6, 0),
					Size = UDim2.new(1, -12, 0, 1),

					BackgroundColor3 = C.BorderSoft,
					BackgroundTransparency = 0.58,
					BorderSizePixel = 0,

					ZIndex = 502,
				})
			end

			local modeText = Label(
				option,
				mode,
				UDim2.new(1, -16, 1, 0),
				selected and C.Accent or C.Text
			)
			modeText.Position = UDim2.fromOffset(8, 0)
			modeText.TextSize = 12
			modeText.ZIndex = 503


			local enter = option.MouseEnter:Connect(function()
				Tween(option, {
					BackgroundColor3 = C.PanelHover,
				}, 0.07)
			end)

			local leave = option.MouseLeave:Connect(function()
				Tween(option, {
					BackgroundColor3 = selected
						and C.Selected
						or C.Control2,
				}, 0.07)
			end)

			local click = option.MouseButton1Click:Connect(function()
				SetMode(mode)
				ClosePopup()
			end)

			table.insert(popupConnections, enter)
			table.insert(popupConnections, leave)
			table.insert(popupConnections, click)

			Track(enter)
			Track(leave)
			Track(click)
		end
	end

	local function BeginListening()
		if unloaded then
			return
		end

		ClosePopup()

		if activeColorPickerClose then
			activeColorPickerClose()
		end

		listening = true
		capturingKeybind = true

		Tween(button, {
			BackgroundColor3 = C.Selected,
		}, 0.08)

		RefreshButton()
	end

	local function EndListening()
		listening = false
		capturingKeybind = false

		Tween(button, {
			BackgroundColor3 = C.Control,
		}, 0.08)

		RefreshButton()
	end

	Track(button.MouseEnter:Connect(function()
		if not listening then
			Tween(button, {
				BackgroundColor3 = C.Popup,
			}, 0.08)
		end
	end))

	Track(button.MouseLeave:Connect(function()
		if not listening then
			Tween(button, {
				BackgroundColor3 = C.Control,
			}, 0.08)
		end
	end))

	Track(button.MouseButton1Click:Connect(function()
		if not listening then
			BeginListening()
		end
	end))

	Track(button.MouseButton2Click:Connect(function()
		OpenPopup()
	end))

	Track(UserInputService.InputBegan:Connect(function(input, processed)
		if unloaded then
			return
		end

		if listening then
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end

			local key = input.KeyCode

			if key == Enum.KeyCode.Escape then
				EndListening()
				return
			end

			if key == Enum.KeyCode.Backspace
				or key == Enum.KeyCode.Delete then

				currentKey = nil
				held = false
				toggled = false

				EndListening()

				if currentMode == "Always On" then
					Emit(true)
				else
					Emit(false)
				end

				return
			end

			if key ~= Enum.KeyCode.Unknown then
				currentKey = key
				held = false
				toggled = false

				EndListening()

				if currentMode == "Always On" then
					Emit(true)
				else
					Emit(false)
				end
			end

			return
		end

		if not currentKey then
			return
		end

		if UserInputService:GetFocusedTextBox() then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if input.KeyCode ~= currentKey then
			return
		end

		if currentMode == "Hold" then
			if not held then
				held = true
				Emit(true)
			end

		elseif currentMode == "Toggle" then
			toggled = not toggled
			Emit(toggled)

		elseif currentMode == "Always On" then
		end
	end))

	Track(UserInputService.InputEnded:Connect(function(input)
		if unloaded or listening or not currentKey then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		if input.KeyCode ~= currentKey then
			return
		end

		if currentMode == "Hold" and held then
			held = false
			Emit(false)
		end
	end))

	RefreshButton()

	if currentMode == "Always On" then
		task.defer(function()
			if not unloaded then
				Emit(true)
			end
		end)
	end

	local control = {
		GetKey = function()
			return currentKey
		end,

		GetMode = function()
			return currentMode
		end,

		GetState = GetActiveState,

		SetKey = function(keyCode)
			currentKey = keyCode
			held = false
			toggled = false
			RefreshButton()

			if currentMode == "Always On" then
				Emit(true)
			else
				Emit(false)
			end
		end,

		SetMode = SetMode,

		Clear = function()
			currentKey = nil
			held = false
			toggled = false

			RefreshButton()

			if currentMode == "Always On" then
				Emit(true)
			else
				Emit(false)
			end
		end,

		Close = ClosePopup,
	}

	return control
end


local function AddColorPicker(parent, y, text, defaultColor, callback)
	local currentColor = defaultColor or Color3.new(1, 1, 1)
	local h, s, v = currentColor:ToHSV()

	local label = Label(parent, text, UDim2.new(1, -31, 0, 18), C.Text)
	label.Position = UDim2.fromOffset(0, y)

	local preview = New("TextButton", {
		Parent = parent,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, y + 1),
		Size = UDim2.fromOffset(24, 16),
		BackgroundColor3 = currentColor,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	})
	local previewStroke = Stroke(preview, C.Border, 0.46)
	Corner(preview, 4)

	local popup = nil
	local opened = false
	local localConnections = {}

	Track(preview.MouseEnter:Connect(function()
		Tween(previewStroke, {
			Color = C.AccentDark,
			Transparency = 0.22,
		}, MOTION.Fast)
	end))

	Track(preview.MouseLeave:Connect(function()
		if not opened then
			Tween(previewStroke, {
				Color = C.Border,
				Transparency = 0.46,
			}, MOTION.Hover)
		end
	end))

	local function LocalTrack(connection)
		table.insert(localConnections, connection)
		Track(connection)
		return connection
	end

	local function DisconnectLocal()
		for i = #localConnections, 1, -1 do
			local connection = localConnections[i]

			if connection and connection.Connected then
				connection:Disconnect()
			end

			localConnections[i] = nil
		end
	end

	local function ToHex(color)
		return string.format(
			"#%02X%02X%02X",
			math.floor(color.R * 255 + 0.5),
			math.floor(color.G * 255 + 0.5),
			math.floor(color.B * 255 + 0.5)
		)
	end

	local function ParseHex(str)
		local raw = tostring(str):gsub("#", ""):gsub("%s+", ""):upper()

		if #raw ~= 6 or not raw:match("^[0-9A-F]+$") then
			return nil
		end

		local r = tonumber(raw:sub(1, 2), 16)
		local g = tonumber(raw:sub(3, 4), 16)
		local b = tonumber(raw:sub(5, 6), 16)

		if not r or not g or not b then
			return nil
		end

		return Color3.fromRGB(r, g, b)
	end

	local function SetColor(color, fire)
		currentColor = color
		h, s, v = color:ToHSV()
		preview.BackgroundColor3 = color

		if fire and callback and not unloaded then
			SafeCall(callback, color)
		end
	end

	local function Close()
		opened = false

		if activeColorPickerClose == Close then
			activeColorPickerClose = nil
		end

		if activeColorPickerPopup == popup then
			activeColorPickerPopup = nil
		end

		if activeColorPickerPreview == preview then
			activeColorPickerPreview = nil
		end

		DisconnectLocal()

		Tween(previewStroke, {
			Color = C.Border,
			Transparency = 0.46,
		}, MOTION.Popup)

		if popup and popup.Parent then
			local old = popup
			popup = nil

			old.Visible = true

			local removed = false

			local function RemovePopup()
				if removed then
					return
				end

				removed = true

				if old and old.Parent then
					old.Visible = false
					old:Destroy()
				end
			end

			local hide = TweenService:Create(
				old,
				TweenInfo.new(
					0.12,
					Enum.EasingStyle.Quart,
					Enum.EasingDirection.Out
				),
				{
					GroupTransparency = 1,
				}
			)

			hide.Completed:Connect(function()
				RemovePopup()
			end)

			hide:Play()

			task.delay(0.16, function()
				RemovePopup()
			end)
		end
	end

	local function Open()
		if unloaded then
			return
		end

		if opened then
			Close()
			return
		end

		if activeColorPickerClose and activeColorPickerClose ~= Close then
			activeColorPickerClose()
		end

		if activeKeybindClose then
			activeKeybindClose()
		end

		if activeDropdownClose then
			activeDropdownClose()
		end

		opened = true
		activeColorPickerClose = Close

		Tween(previewStroke, {
			Color = C.Accent,
			Transparency = 0.10,
		}, MOTION.Popup)

		local W, H = 176, 170

		local localX =
			preview.AbsolutePosition.X
			- main.AbsolutePosition.X
			- W
			+ preview.AbsoluteSize.X

		local localY =
			preview.AbsolutePosition.Y
			- main.AbsolutePosition.Y
			+ preview.AbsoluteSize.Y
			+ 5

		if localY + H > main.AbsoluteSize.Y - 4 then
			localY =
				preview.AbsolutePosition.Y
				- main.AbsolutePosition.Y
				- H
				- 5
		end

		localX = math.clamp(
			localX,
			4,
			math.max(4, main.AbsoluteSize.X - W - 4)
		)

		localY = math.clamp(
			localY,
			4,
			math.max(4, main.AbsoluteSize.Y - H - 4)
		)

		popup = New("CanvasGroup", {
			Parent = main,
			Position = UDim2.fromOffset(localX, localY),
			Size = UDim2.fromOffset(W, H),

			BackgroundColor3 = C.Popup,
			BorderSizePixel = 0,
			GroupTransparency = 1,

			ZIndex = 300,
		})

		Stroke(popup, C.Border, 0.33)
		Corner(popup, 6)

		activeColorPickerPopup = popup
		activeColorPickerPreview = preview

		local show = TweenService:Create(
			popup,
			TweenInfo.new(
				0.14,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				GroupTransparency = 0,
			}
		)

		show:Play()


		local dragHeader = New("TextButton", {
			Parent = popup,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 18),

			BackgroundColor3 = C.Control2,
			BorderSizePixel = 0,
			AutoButtonColor = false,

			Text = "  color picker",
			TextColor3 = C.Muted,
			TextSize = 11,
			Font = FONT,
			TextXAlignment = Enum.TextXAlignment.Left,

			ZIndex = 320,
		})

		local dragDots = Label(
			dragHeader,
			"•••",
			UDim2.fromOffset(26, 18),
			C.Dim,
			Enum.TextXAlignment.Center
		)
		dragDots.Position = UDim2.new(1, -28, 0, 0)
		dragDots.TextSize = 10
		dragDots.ZIndex = 321

		local headerLine = New("Frame", {
			Parent = popup,
			Position = UDim2.fromOffset(0, 18),
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = C.BorderSoft,
			BorderSizePixel = 0,
			ZIndex = 319,
		})

		local draggingPopup = false
		local popupDragStart = nil
		local popupStartPosition = nil

		LocalTrack(dragHeader.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then

				draggingPopup = true
				popupDragStart = input.Position
				popupStartPosition = popup.Position

				Tween(dragHeader, {
					BackgroundColor3 = C.Panel2,
				}, 0.08)
			end
		end))


		local swatch = New("Frame", {
			Parent = popup,
			Position = UDim2.fromOffset(7, 24),
			Size = UDim2.fromOffset(22, 18),

			BackgroundColor3 = currentColor,
			BorderSizePixel = 0,

			ZIndex = 302,
		})

		Stroke(swatch, C.BorderSoft, 0.45)
		Corner(swatch, 4)

		local hexBox = New("TextBox", {
			Parent = popup,
			Position = UDim2.fromOffset(34, 24),
			Size = UDim2.fromOffset(135, 18),

			BackgroundColor3 = C.Top,
			BorderSizePixel = 0,

			ClearTextOnFocus = false,
			Text = ToHex(currentColor),
			TextColor3 = C.Text,

			PlaceholderText = "#RRGGBB",
			PlaceholderColor3 = C.Dim,

			TextSize = 12,
			Font = FONT,
			TextXAlignment = Enum.TextXAlignment.Center,

			ZIndex = 302,
		})

		Stroke(hexBox, C.BorderSoft, 0.50)
		Corner(hexBox, 4)


		local sv = New("Frame", {
			Parent = popup,
			Position = UDim2.fromOffset(7, 48),
			Size = UDim2.fromOffset(141, 96),

			BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			BorderSizePixel = 0,

			ZIndex = 302,
		})

		Corner(sv, 4)

		local sat = New("Frame", {
			Parent = sv,
			Size = UDim2.fromScale(1, 1),

			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,

			ZIndex = 303,
		})

		Corner(sat, 4)

		New("UIGradient", {
			Parent = sat,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		})

		local val = New("Frame", {
			Parent = sv,
			Size = UDim2.fromScale(1, 1),

			BackgroundColor3 = Color3.new(0, 0, 0),
			BorderSizePixel = 0,

			ZIndex = 304,
		})

		Corner(val, 4)

		New("UIGradient", {
			Parent = val,
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			}),
		})

		local svInput = New("TextButton", {
			Parent = sv,
			Size = UDim2.fromScale(1, 1),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 309,
		})

		local svCursor = New("Frame", {
			Parent = sv,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(s, 0, 1 - v, 0),
			Size = UDim2.fromOffset(8, 8),

			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,

			ZIndex = 310,
		})

		Corner(svCursor, 20)
		Stroke(svCursor, Color3.new(0, 0, 0), 0)


		local hueBar = New("Frame", {
			Parent = popup,
			Position = UDim2.fromOffset(154, 48),
			Size = UDim2.fromOffset(15, 96),

			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,

			ZIndex = 302,
		})

		Corner(hueBar, 4)

		New("UIGradient", {
			Parent = hueBar,
			Rotation = 90,

			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0, 0)),
			}),
		})

		local hueInput = New("TextButton", {
			Parent = hueBar,
			Size = UDim2.fromScale(1, 1),

			BackgroundTransparency = 1,
			BorderSizePixel = 0,

			Text = "",
			AutoButtonColor = false,

			ZIndex = 309,
		})

		local hueCursor = New("Frame", {
			Parent = hueBar,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, h, 0),
			Size = UDim2.new(1, 5, 0, 3),

			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,

			ZIndex = 310,
		})

		Corner(hueCursor, 2)
		Stroke(hueCursor, Color3.new(0, 0, 0), 0)

		local rgbText = Label(
			popup,
			"",
			UDim2.fromOffset(162, 16),
			C.Muted,
			Enum.TextXAlignment.Center
		)

		rgbText.Position = UDim2.fromOffset(7, 149)
		rgbText.TextSize = 11
		rgbText.ZIndex = 302

		local draggingSV = false
		local draggingHue = false

		local function Refresh(fire, rebuildColor)
			if rebuildColor ~= false then
				currentColor = Color3.fromHSV(h, s, v)
			end

			preview.BackgroundColor3 = currentColor
			swatch.BackgroundColor3 = currentColor
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)

			svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
			hueCursor.Position = UDim2.new(0.5, 0, h, 0)

			if not hexBox:IsFocused() then
				hexBox.Text = ToHex(currentColor)
			end

			rgbText.Text = string.format(
				"R %d   G %d   B %d",
				math.floor(currentColor.R * 255 + 0.5),
				math.floor(currentColor.G * 255 + 0.5),
				math.floor(currentColor.B * 255 + 0.5)
			)

			if fire and callback and not unloaded then
				SafeCall(callback, currentColor)
			end
		end

		local function UpdateSV(position)
			local ax = svInput.AbsolutePosition.X
			local ay = svInput.AbsolutePosition.Y

			local aw = math.max(svInput.AbsoluteSize.X, 1)
			local ah = math.max(svInput.AbsoluteSize.Y, 1)

			s = math.clamp(
				(position.X - ax) / aw,
				0,
				1
			)

			v = 1 - math.clamp(
				(position.Y - ay) / ah,
				0,
				1
			)

			Refresh(true, true)
		end

		local function UpdateHue(position)
			local ay = hueInput.AbsolutePosition.Y
			local ah = math.max(hueInput.AbsoluteSize.Y, 1)

			h = math.clamp(
				(position.Y - ay) / ah,
				0,
				1
			)

			Refresh(true, true)
		end

		LocalTrack(svInput.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then

				draggingSV = true
				UpdateSV(input.Position)

				Tween(
					svCursor,
					{Size = UDim2.fromOffset(11, 11)},
					0.08
				)
			end
		end))

		LocalTrack(hueInput.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then

				draggingHue = true
				UpdateHue(input.Position)

				Tween(
					hueCursor,
					{Size = UDim2.new(1, 7, 0, 4)},
					0.08
				)
			end
		end))

		LocalTrack(UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if draggingPopup and popup and popup.Parent then
				local delta = input.Position - popupDragStart

				local targetX = popupStartPosition.X.Offset + delta.X
				local targetY = popupStartPosition.Y.Offset + delta.Y

				targetX = math.clamp(
					targetX,
					2,
					math.max(2, main.AbsoluteSize.X - W - 2)
				)

				targetY = math.clamp(
					targetY,
					2,
					math.max(2, main.AbsoluteSize.Y - H - 2)
				)

				popup.Position = UDim2.fromOffset(targetX, targetY)
				return
			end

			if draggingSV then
				UpdateSV(input.Position)
			elseif draggingHue then
				UpdateHue(input.Position)
			end
		end))

		LocalTrack(UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then

				if draggingPopup then
					draggingPopup = false

					Tween(dragHeader, {
						BackgroundColor3 = C.Control2,
					}, 0.09)
				end

				if draggingSV then
					draggingSV = false

					Tween(
						svCursor,
						{Size = UDim2.fromOffset(8, 8)},
						0.09
					)
				end

				if draggingHue then
					draggingHue = false

					Tween(
						hueCursor,
						{Size = UDim2.new(1, 5, 0, 3)},
						0.09
					)
				end
			end
		end))

		LocalTrack(hexBox.FocusLost:Connect(function()
			local parsed = ParseHex(hexBox.Text)

			if parsed then
				SetColor(parsed, false)
				h, s, v = parsed:ToHSV()
				Refresh(true, false)
			else
				hexBox.Text = ToHex(currentColor)
			end
		end))

		Refresh(false, false)
	end

	Track(preview.MouseButton1Click:Connect(Open))

	local control = {
		Get = function()
			return currentColor
		end,

		Set = function(color)
			SetColor(color, true)
		end,

		Close = Close,
	}

	return control
end


local function PointInsideGuiObject(guiObject, point)
	if not guiObject or not guiObject.Parent or not guiObject.Visible then
		return false
	end

	local pos = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize

	return point.X >= pos.X
		and point.Y >= pos.Y
		and point.X <= pos.X + size.X
		and point.Y <= pos.Y + size.Y
end

Track(UserInputService.InputBegan:Connect(function(input)
	if unloaded then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.MouseButton2 then
		return
	end

	local point = input.Position


	if activeColorPickerClose then
		local insidePicker =
			PointInsideGuiObject(activeColorPickerPopup, point)

		local onPickerPreview =
			PointInsideGuiObject(activeColorPickerPreview, point)

		if not insidePicker
			and not onPickerPreview
			and PointInsideGuiObject(main, point) then

			activeColorPickerClose()
		end
	end


	if activeKeybindClose then
		local insideBindMenu =
			PointInsideGuiObject(activeKeybindPopup, point)

		local onBindButton =
			PointInsideGuiObject(activeKeybindButton, point)

		if not insideBindMenu
			and not onBindButton
			and PointInsideGuiObject(main, point) then

			activeKeybindClose()
		end
	end


	if activeDropdownClose then
		local insideDropdown =
			PointInsideGuiObject(activeDropdownPopup, point)

		local onDropdownButton =
			PointInsideGuiObject(activeDropdownButton, point)

		if not insideDropdown
			and not onDropdownButton
			and PointInsideGuiObject(main, point) then

			activeDropdownClose()
		end
	end
end))

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

		BackgroundColor3 = C.Control,
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
		UDim2.new(1, -30, 1, 0),
		C.TextStrong
	)
	valueText.Position = UDim2.fromOffset(7, 0)
	valueText.TextSize = 12
	valueText.ZIndex = 72

	local arrow = Label(
		button,
		"›",
		UDim2.fromOffset(18, 19),
		C.Muted,
		Enum.TextXAlignment.Center
	)
	arrow.Position = UDim2.new(1, -20, 0, 0)
	arrow.TextSize = 14
	arrow.ZIndex = 72

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

			BackgroundColor3 = C.Control2,
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
					and C.Selected
					or C.Control2,

				BorderSizePixel = 0,
				AutoButtonColor = false,

				Text = "",
				ZIndex = 461,
			})

			local optionText = Label(
				opt,
				tostring(option),
				UDim2.new(1, -28, 1, 0),
				selected and C.AccentLight or C.Text
			)
			optionText.Position = UDim2.fromOffset(7, 0)
			optionText.TextSize = 12
			optionText.ZIndex = 462

			if selected then
				local selectedMark = Label(
					opt,
					"•",
					UDim2.fromOffset(18, rowHeight),
					C.AccentLight,
					Enum.TextXAlignment.Center
				)
				selectedMark.Position = UDim2.new(1, -22, 0, 0)
				selectedMark.TextSize = 16
				selectedMark.ZIndex = 462
			end

			local enter = opt.MouseEnter:Connect(function()
				Tween(opt, {
					BackgroundColor3 = C.PanelHover,
				}, 0.07)
			end)

			local click = opt.MouseButton1Click:Connect(function()
				current = option
				valueText.Text = tostring(option)
				valueText.TextColor3 = C.TextStrong
				Close()

				if callback then
					SafeCall(callback, current)
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
				valueText.TextColor3 = C.TextStrong

				if callback then
					SafeCall(callback, current)
				end
			end
		end,

		Close = Close,
	}
end

local function AddButton(parent, y, text, callback)
	local button = New("TextButton", {
		Parent = parent,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundColor3 = C.Panel2,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = tostring(text or "Button"),
		TextColor3 = C.Text,
		TextSize = 12,
		Font = FONT,
	})
	Stroke(button, C.BorderSoft, 0.46)
	Corner(button, 3)

	Track(button.MouseEnter:Connect(function()
		Tween(button, {BackgroundColor3 = C.PanelHover}, MOTION.Fast)
	end))

	Track(button.MouseLeave:Connect(function()
		Tween(button, {BackgroundColor3 = C.Panel2}, MOTION.Hover)
	end))

	Track(button.MouseButton1Click:Connect(function()
		if callback then
			SafeCall(callback)
		end
	end))

	return button
end

local function AddInput(parent, y, text, default, callback)
	local label = Label(parent, text or "", UDim2.new(1, 0, 0, 16), C.Text)
	label.Position = UDim2.fromOffset(0, y)

	local box = New("TextBox", {
		Parent = parent,
		Position = UDim2.fromOffset(0, y + 19),
		Size = UDim2.new(1, 0, 0, 21),
		BackgroundColor3 = C.Control,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		Text = tostring(default or ""),
		TextColor3 = C.Text,
		PlaceholderColor3 = C.Dim,
		TextSize = 12,
		Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	Stroke(box, C.BorderSoft, 0.50)
	Corner(box, 3)

	New("UIPadding", {
		Parent = box,
		PaddingLeft = UDim.new(0, 6),
		PaddingRight = UDim.new(0, 6),
	})

	local current = tostring(default or "")

	Track(box.FocusLost:Connect(function()
		current = box.Text
		if callback then
			SafeCall(callback, current)
		end
	end))

	return {
		Get = function()
			return current
		end,
		Set = function(value)
			current = tostring(value or "")
			box.Text = current
			if callback then
				SafeCall(callback, current)
			end
		end,
		Box = box,
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
		return tabAPIs[name]
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

		BackgroundColor3 = C.Control2,
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
				BackgroundColor3 = C.Panel2,
				TextColor3 = C.Text,
			}, MOTION.Hover)
		end
	end))

	Track(button.MouseLeave:Connect(function()
		if currentTab ~= name then
			Tween(button, {
				BackgroundColor3 = C.Control2,
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
			ScrollBarImageColor3 = C.AccentDark,

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

		function sectionAPI:AddColorPicker(y, text, default, callback)
			return AddColorPicker(body, y, text, default, callback)
		end

		function sectionAPI:AddKeybind(y, text, defaultKey, defaultMode, callback)
			return AddKeybind(body, y, text, defaultKey, defaultMode, callback)
		end

		function sectionAPI:AddButton(y, text, callback)
			return AddButton(body, y, text, callback)
		end

		function sectionAPI:AddInput(y, text, default, callback)
			return AddInput(body, y, text, default, callback)
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

	tabAPIs[name] = tabAPI

	if #tabs == 1 then
		SetTab(name)
	end

	return tabAPI
end

function Library:SetTitle(text)
	title.Text = tostring(text or "")
end

function Library:SetTheme(theme)
	if type(theme) ~= "table" then
		return false
	end

	local accentChanged = false
	local accentDarkProvided = false
	local accentLightProvided = false

	for key, value in pairs(theme) do
		if C[key] ~= nil and typeof(value) == "Color3" then
			C[key] = value

			if key == "Accent" then
				accentChanged = true
			elseif key == "AccentDark" then
				accentDarkProvided = true
			elseif key == "AccentLight" then
				accentLightProvided = true
			end
		end
	end

	if accentChanged then
		if not accentDarkProvided then
			C.AccentDark = C.Accent:Lerp(Color3.new(0, 0, 0), 0.46)
		end

		if not accentLightProvided then
			C.AccentLight = C.Accent:Lerp(Color3.new(1, 1, 1), 0.34)
		end
	end

	RefreshTheme()

	tabIndicator.BackgroundColor3 = C.Accent
	tabIndicatorGlow.BackgroundColor3 = C.Accent

	return true
end

function Library:SetThemeColor(name, color)
	if type(name) ~= "string" or typeof(color) ~= "Color3" or C[name] == nil then
		return false
	end

	return self:SetTheme({
		[name] = color,
	})
end

function Library:GetTheme()
	local result = {}

	for key, value in pairs(C) do
		if typeof(value) == "Color3" then
			result[key] = value
		end
	end

	return result
end

function Library:SetAccent(color)
	if typeof(color) ~= "Color3" then
		return false
	end

	return self:SetTheme({
		Accent = color,
	})
end

local LOG_THEME_MAP = {
	Background = "Notification",
	Log = "Notification",
	Border = "NotificationBorder",

	Title = "NotificationTitle",
	TitleText = "NotificationTitle",

	Text = "NotificationText",
	Body = "NotificationText",
	BodyText = "NotificationText",

	Separator = "NotificationSeparator",

	RailGlow = "NotificationRailGlow",
	StripGlow = "NotificationRailGlow",

	RailA = "NotificationRailA",
	RailB = "NotificationRailB",
	RailC = "NotificationRailC",

	StripA = "NotificationRailA",
	StripB = "NotificationRailB",
	StripC = "NotificationRailC",

	ProgressBack = "ProgressBack",

	ProgressA = "NotificationProgressA",
	ProgressB = "NotificationProgressB",
	ProgressC = "NotificationProgressC",
}

function Library:SetLogTheme(theme)
	if type(theme) ~= "table" then
		return false
	end

	local update = {}

	for key, value in pairs(theme) do
		local themeKey =
			LOG_THEME_MAP[key]
			or (
				C[key] ~= nil
				and key
				or nil
			)

		if themeKey
			and C[themeKey] ~= nil
			and typeof(value) == "Color3" then

			update[themeKey] = value
		end
	end

	if next(update) == nil then
		return false
	end

	return self:SetTheme(update)
end

function Library:SetLogColor(name, color)
	if type(name) ~= "string"
		or typeof(color) ~= "Color3" then

		return false
	end

	local themeKey =
		LOG_THEME_MAP[name]
		or (
			C[name] ~= nil
				and name
				or nil
		)

	if not themeKey or C[themeKey] == nil then
		return false
	end

	return self:SetTheme({
		[themeKey] = color,
	})
end

function Library:GetLogTheme()
	return {
		Background = C.Notification,
		Border = C.NotificationBorder,

		TitleText = C.NotificationTitle,
		BodyText = C.NotificationText,
		Separator = C.NotificationSeparator,

		StripGlow = C.NotificationRailGlow,
		StripA = C.NotificationRailA,
		StripB = C.NotificationRailB,
		StripC = C.NotificationRailC,

		ProgressBack = C.ProgressBack,
		ProgressA = C.NotificationProgressA,
		ProgressB = C.NotificationProgressB,
		ProgressC = C.NotificationProgressC,
	}
end

function Library:SelectTab(name)
	SetTab(tostring(name or ""))
end

local watermarkSide = "Right"
local watermarkTitle = "Rat.Lua | Aftermath"
local watermarkVisible = false
local watermarkDragging = false
local watermarkDragStart = nil
local watermarkStartPosition = nil
local watermarkTween = nil

local watermark = New("CanvasGroup", {
	Name = "Watermark",
	Parent = gui,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 0, 10),
	Size = UDim2.fromOffset(220, 34),
	BackgroundColor3 = Color3.fromRGB(14, 14, 17),
	BorderSizePixel = 0,
	GroupTransparency = 1,
	Visible = false,
	ZIndex = 90000,
})
Corner(watermark, 8)

local watermarkGradientStroke = New("UIStroke", {
	Parent = watermark,
	Color = Color3.fromRGB(255, 255, 255),
	Thickness = 1.6,
	Transparency = 0.02,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local watermarkGradient = New("UIGradient", {
	Parent = watermarkGradientStroke,
	Rotation = 0,
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(70, 44, 76)),
		ColorSequenceKeypoint.new(0.18, C.Accent),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(222, 150, 232)),
		ColorSequenceKeypoint.new(0.52, Color3.fromRGB(92, 53, 102)),
		ColorSequenceKeypoint.new(0.70, C.Accent),
		ColorSequenceKeypoint.new(0.86, Color3.fromRGB(225, 155, 235)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(70, 44, 76)),
	}),
})

local watermarkGradientTween = TweenService:Create(
	watermarkGradient,
	TweenInfo.new(
		3.2,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.Out,
		-1,
		false,
		0
	),
	{
		Rotation = 360,
	}
)
watermarkGradientTween:Play()

local watermarkInner = New("Frame", {
	Parent = watermark,
	Position = UDim2.fromOffset(2, 2),
	Size = UDim2.new(1, -4, 1, -4),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 90001,
})
Corner(watermarkInner, 7)

New("UIStroke", {
	Parent = watermarkInner,
	Color = Color3.fromRGB(38, 38, 43),
	Thickness = 1,
	Transparency = 0.18,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

local watermarkText = Label(
	watermark,
	watermarkTitle,
	UDim2.new(1, -24, 1, 0),
	C.Text,
	Enum.TextXAlignment.Left
)
watermarkText.Position = UDim2.fromOffset(12, 0)
watermarkText.TextSize = 13
watermarkText.ZIndex = 90003

local watermarkDragArea = New("TextButton", {
	Parent = watermark,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Active = true,
	Text = "",
	ZIndex = 90010,
})

local function MeasureWatermarkWidth()
	local measured = TextService:GetTextSize(
		tostring(watermarkTitle or ""),
		13,
		FONT,
		Vector2.new(2000, 100)
	)

	return math.clamp(
		math.ceil(measured.X) + 30,
		110,
		650
	)
end

local function ResizeWatermark(animated)
	local target =
		UDim2.fromOffset(
			MeasureWatermarkWidth(),
			34
		)

	if animated then
		Tween(watermark, {
			Size = target,
		}, 0.14)
	else
		watermark.Size = target
	end
end

local function GetWatermarkPosition(side)
	if side == "Left" then
		return UDim2.new(0, 10, 0, 10)
	end

	return UDim2.new(1, -10, 0, 10)
end

local function NormalizeWatermarkSide(side)
	local normalized = string.lower(
		tostring(side or "")
	)

	if normalized == "left"
		or normalized == "topleft"
		or normalized == "lefttop"
		or normalized == "top-left"
		or normalized == "top_left" then

		return "Left"
	end

	if normalized == "right"
		or normalized == "topright"
		or normalized == "righttop"
		or normalized == "top-right"
		or normalized == "top_right" then

		return "Right"
	end

	return nil
end

Track(watermarkDragArea.MouseEnter:Connect(function()
	if not watermarkDragging then
		Tween(watermark, {
			BackgroundColor3 = Color3.fromRGB(18, 16, 20),
		}, 0.10)

		Tween(watermarkGradientStroke, {
			Thickness = 2,
		}, 0.10)
	end
end))

Track(watermarkDragArea.MouseLeave:Connect(function()
	if not watermarkDragging then
		Tween(watermark, {
			BackgroundColor3 = Color3.fromRGB(14, 14, 17),
		}, 0.10)

		Tween(watermarkGradientStroke, {
			Thickness = 1.6,
		}, 0.10)
	end
end))

Track(watermarkDragArea.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		watermarkDragging = true
		watermarkDragStart = input.Position

		local abs = watermark.AbsolutePosition

		watermark.AnchorPoint = Vector2.new(0, 0)
		watermark.Position = UDim2.fromOffset(abs.X, abs.Y)
		watermarkStartPosition = watermark.Position
		watermarkSide = "Custom"

		Tween(watermarkGradientStroke, {
			Thickness = 2.2,
		}, 0.08)
	end
end))

Track(UserInputService.InputChanged:Connect(function(input)
	if not watermarkDragging then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then

		return
	end

	local delta = input.Position - watermarkDragStart

	watermark.Position = UDim2.fromOffset(
		watermarkStartPosition.X.Offset + delta.X,
		watermarkStartPosition.Y.Offset + delta.Y
	)
end))

Track(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		if watermarkDragging then
			watermarkDragging = false

			Tween(watermarkGradientStroke, {
				Thickness = 1.6,
			}, 0.10)
		end
	end
end))

function Library:SetWatermark(text, side)
	if unloaded or not watermarkText.Parent then
		return
	end

	if text ~= nil then
		watermarkTitle = tostring(text)
	end

	if side ~= nil then
		local normalized = NormalizeWatermarkSide(side)

		if normalized then
			watermarkSide = normalized
		end
	end

	watermarkText.Text = watermarkTitle
	ResizeWatermark(true)

	if watermarkSide == "Left"
		or watermarkSide == "Right" then

		watermark.AnchorPoint =
			watermarkSide == "Left"
			and Vector2.new(0, 0)
			or Vector2.new(1, 0)

		watermark.Position =
			GetWatermarkPosition(watermarkSide)
	end
end

function Library:SetWatermarkPosition(side)
	local normalized = NormalizeWatermarkSide(side)

	if not normalized then
		return
	end

	watermarkSide = normalized

	watermark.AnchorPoint =
		watermarkSide == "Left"
		and Vector2.new(0, 0)
		or Vector2.new(1, 0)

	watermark.Position =
		GetWatermarkPosition(watermarkSide)
end

function Library:SetWatermarkVisible(state)
	if unloaded or not watermark.Parent then
		return
	end

	state = state == true

	if watermarkVisible == state then
		return
	end

	watermarkVisible = state

	if watermarkTween then
		pcall(function()
			watermarkTween:Cancel()
		end)
	end

	if state then
		watermark.Visible = true
		watermark.GroupTransparency = 1

		if watermarkSide == "Left"
			or watermarkSide == "Right" then

			watermark.AnchorPoint =
				watermarkSide == "Left"
				and Vector2.new(0, 0)
				or Vector2.new(1, 0)

			watermark.Position =
				GetWatermarkPosition(watermarkSide)
		end

		watermarkTween = TweenService:Create(
			watermark,
			TweenInfo.new(
				0.14,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				GroupTransparency = 0,
			}
		)

		watermarkTween:Play()
	else
		watermarkTween = TweenService:Create(
			watermark,
			TweenInfo.new(
				0.11,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				GroupTransparency = 1,
			}
		)

		local thisTween = watermarkTween

		thisTween.Completed:Connect(function()
			if watermarkTween == thisTween
				and not watermarkVisible
				and watermark.Parent then

				watermark.Visible = false
			end
		end)

		thisTween:Play()
	end
end

ResizeWatermark(false)

local notificationRoot = New("Frame", {
	Name = "Notifications",
	Parent = gui,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -14, 0, 14),
	Size = UDim2.fromOffset(650, 500),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 100000,
})

New("UIListLayout", {
	Parent = notificationRoot,
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Top,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 4),
})

local notificationOrder = 0

function Library:Notify(data, duration)
	if unloaded or not notificationRoot.Parent then
		return
	end

	local titleText = nil
	local bodyText = nil
	local lifetime = tonumber(duration) or 3

	if type(data) == "table" then
		local rawTitle =
			data.Title
			or data.Header
			or data.title
			or data.header

		local rawBody =
			data.Text
			or data.Message
			or data.Description
			or data.Value
			or data.text
			or data.message
			or data.description
			or data.value

		if rawTitle ~= nil
			and tostring(rawTitle) ~= "" then

			titleText = tostring(rawTitle)
		end

		if rawBody ~= nil
			and tostring(rawBody) ~= "" then

			bodyText = tostring(rawBody)
		end

		lifetime = tonumber(
			data.Duration
			or data.Time
			or data.duration
			or data.time
			or lifetime
		) or lifetime
	else
		if data ~= nil
			and tostring(data) ~= "" then

			bodyText = tostring(data)
		end
	end

	if not titleText and not bodyText then
		return
	end

	lifetime = math.clamp(lifetime, 0.5, 30)
	notificationOrder += 1

	local titleSize = 13
	local bodySize = 13

	local titleBounds =
		titleText
		and TextService:GetTextSize(
			titleText,
			titleSize,
			FONT,
			Vector2.new(2000, 100)
		)
		or Vector2.zero

	local bodyBounds =
		bodyText
		and TextService:GetTextSize(
			bodyText,
			bodySize,
			FONT,
			Vector2.new(2000, 100)
		)
		or Vector2.zero

	local separatorWidth =
		(titleText and bodyText)
		and 16
		or 0

	local wantedWidth =
		math.ceil(titleBounds.X)
		+ math.ceil(bodyBounds.X)
		+ separatorWidth
		+ 34

	local cardWidth = math.clamp(
		wantedWidth,
		150,
		620
	)

	local cardHeight = 24

	local holder = New("Frame", {
		Parent = notificationRoot,
		Size = UDim2.new(1, 0, 0, cardHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = notificationOrder,
		ZIndex = 100001,
	})

	local card = New("CanvasGroup", {
		Parent = holder,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 20, 0, 0),
		Size = UDim2.fromOffset(
			cardWidth,
			cardHeight
		),
		BackgroundColor3 = C.Notification,
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		GroupTransparency = 1,
		ZIndex = 100002,
	})
	Corner(card, 4)

	local cardStroke = New("UIStroke", {
		Parent = card,
		Color = C.NotificationBorder,
		Thickness = 1,
		Transparency = 0.16,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	local sideGlow = New("Frame", {
		Parent = card,
		Position = UDim2.fromOffset(-2, 1),
		Size = UDim2.new(0, 8, 1, -2),
		BackgroundColor3 = C.NotificationRailGlow,
		BackgroundTransparency = 0.80,
		BorderSizePixel = 0,
		ZIndex = 100006,
	})
	Corner(sideGlow, 5)

	local sideRail = New("Frame", {
		Parent = card,
		Position = UDim2.fromOffset(0, 1),
		Size = UDim2.new(0, 3, 1, -2),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 100008,
	})
	Corner(sideRail, 4)

	local sideGradient = BindNotificationRailGradient(New("UIGradient", {
		Parent = sideRail,
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 0.55),
			NumberSequenceKeypoint.new(0.30, 0.08),
			NumberSequenceKeypoint.new(0.50, 0.00),
			NumberSequenceKeypoint.new(0.70, 0.08),
			NumberSequenceKeypoint.new(1.00, 0.55),
		}),
		Offset = Vector2.new(0, -0.55),
	}))

	local sideTween = TweenService:Create(
		sideGradient,
		TweenInfo.new(
			1.7,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut,
			-1,
			true
		),
		{
			Offset = Vector2.new(0, 0.55),
		}
	)
	sideTween:Play()

	local x = 12

	if titleText then
		local titleWidth = math.min(
			math.ceil(titleBounds.X) + 2,
			cardWidth - 24
		)

		local titleLabel = Label(
			card,
			titleText,
			UDim2.fromOffset(
				titleWidth,
				cardHeight
			),
			C.NotificationTitle
		)

		titleLabel.Position =
			UDim2.fromOffset(x, 0)

		titleLabel.TextSize = titleSize
		titleLabel.TextTruncate =
			Enum.TextTruncate.AtEnd

		titleLabel.ZIndex = 100010

		x += titleWidth
	end

	if titleText and bodyText then
		local separator = Label(
			card,
			"•",
			UDim2.fromOffset(14, cardHeight),
			C.NotificationSeparator
		)

		separator.Position =
			UDim2.fromOffset(x, 0)

		separator.TextXAlignment =
			Enum.TextXAlignment.Center

		separator.TextSize = 12
		separator.ZIndex = 100010

		x += 14
	end

	if bodyText then
		local bodyLabel = Label(
			card,
			bodyText,
			UDim2.fromOffset(
				cardWidth - x - 10,
				cardHeight
			),
			C.NotificationText
		)

		bodyLabel.Position =
			UDim2.fromOffset(x, 0)

		bodyLabel.TextSize = bodySize
		bodyLabel.TextTruncate =
			Enum.TextTruncate.AtEnd

		bodyLabel.ZIndex = 100010
	end

	local progressBack = New("Frame", {
		Parent = card,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 8, 1, -1),
		Size = UDim2.new(1, -16, 0, 1),
		BackgroundColor3 = C.ProgressBack,
		BorderSizePixel = 0,
		ZIndex = 100005,
	})

	local progress = New("Frame", {
		Parent = progressBack,
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 100006,
	})

	BindNotificationProgressGradient(New("UIGradient", {
		Parent = progress,
		Rotation = 0,
	}))

	Tween(card, {
		GroupTransparency = 0,
		Position = UDim2.new(1, 0, 0, 0),
	}, 0.15)

	local progressTween =
		TweenService:Create(
			progress,
			TweenInfo.new(
				lifetime,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			),
			{
				Size =
					UDim2.new(
						0,
						0,
						0,
						1
					),
			}
		)

	progressTween:Play()

	task.delay(lifetime, function()
		if unloaded
			or not holder.Parent
			or not card.Parent then

			return
		end

		local removed = false

		local function Remove()
			if removed then
				return
			end

			removed = true

			pcall(function()
				sideTween:Cancel()
			end)

			pcall(function()
				progressTween:Cancel()
			end)

			if holder and holder.Parent then
				holder.Visible = false
				holder:Destroy()
			end
		end

		local hideTween = Tween(card, {
			GroupTransparency = 1,
			Position = UDim2.new(1, 20, 0, 0),
		}, 0.12)

		if hideTween then
			hideTween.Completed:Connect(Remove)
			task.delay(0.17, Remove)
		else
			Remove()
		end
	end)

	return holder
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
		BackgroundColor3 = C.Dim,
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
			Color = C.Outline,
			Transparency = 0.12,
		}, MOTION.Hover)
	end
end))

local opened = true
local visibilityTween = nil
local visibilityToken = 0
local toggleKey = Enum.KeyCode.RightShift

local function NormalizePagesForWindowTween()
	for tabName, page in pairs(pages) do
		local pageTween = tabPageTweens[tabName]

		if pageTween then
			pcall(function()
				pageTween:Cancel()
			end)

			tabPageTweens[tabName] = nil
		end

		if tabName == currentTab then
			page.Visible = true
			page.GroupTransparency = 0
			page.Position = UDim2.fromOffset(0, 0)
		else
			page.Visible = false
			page.GroupTransparency = 1
			page.Position = UDim2.fromOffset(0, 0)
		end
	end
end

local function SetVisible(state)
	state = state == true

	if opened == state or unloaded then
		return
	end

	opened = state
	visibilityToken += 1

	local token = visibilityToken

	NormalizePagesForWindowTween()
	CloseTransientPopups()

	if visibilityTween then
		pcall(function()
			visibilityTween:Cancel()
		end)
	end

	main.Visible = true

	visibilityTween = TweenService:Create(
		main,
		TweenInfo.new(
			state
				and MOTION.WindowIn
				or MOTION.WindowOut,
			Enum.EasingStyle.Quart,
			state
				and Enum.EasingDirection.Out
				or Enum.EasingDirection.InOut
		),
		{
			GroupTransparency =
				state and 0 or 1,
		}
	)

	local thisTween = visibilityTween

	thisTween.Completed:Connect(function(playbackState)
		if token ~= visibilityToken
			or visibilityTween ~= thisTween then

			return
		end

		if playbackState
				== Enum.PlaybackState.Completed
			and not opened
			and not unloaded then

			main.Visible = false
		end
	end)

	thisTween:Play()
end

Track(UserInputService.InputBegan:Connect(function(input)
	if unloaded or capturingKeybind then
		return
	end

	if UserInputService:GetFocusedTextBox() then
		return
	end

	if input.UserInputType
			== Enum.UserInputType.Keyboard
		and input.KeyCode == toggleKey then

		SetVisible(not opened)
	end
end))

function Library:SetVisible(state)
	SetVisible(state == true)
end

function Library:Toggle()
	SetVisible(not opened)
end

function Library:SetToggleKey(key)
	if typeof(key) == "EnumItem"
		and key.EnumType == Enum.KeyCode
		and key ~= Enum.KeyCode.Unknown then

		toggleKey = key
		return true
	end

	return false
end

function Library:GetToggleKey()
	return toggleKey
end

function Library:Unload()
	if unloaded then
		return
	end

	unloaded = true
	CloseTransientPopups()

	pcall(function()
		UserInputService.MouseIconEnabled = true
	end)

	RemoveStaleGui(guiParent, "UI-v5-Cursor")
	RemoveStaleGui(playerGui, "UI-v5-Cursor")

	pcall(function()
		watermarkGradientTween:Cancel()
	end)

	DisconnectAll()

	if gui and gui.Parent then
		gui:Destroy()
	end

	if RuntimeEnvironment.__UI_V5_RUNTIME == Library then
		RuntimeEnvironment.__UI_V5_RUNTIME = nil
	end
end

NormalizePagesForWindowTween()

main.Visible = true
main.GroupTransparency = 1

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

visibilityTween:Play()

return Library
