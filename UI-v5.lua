local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

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

if existingRuntime then
	if existingRuntime == true then
		return nil
	end

	return existingRuntime
end

if guiParent:FindFirstChild("UI-v5")
	or playerGui:FindFirstChild("UI-v5") then

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

	White = Color3.fromRGB(240, 240, 240),
	Black = Color3.fromRGB(3, 3, 3),
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

	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			obj[k] = v
		end
	end

	if props and props.Parent then
		obj.Parent = props.Parent
	end

	return obj
end

local function Tween(obj, props, t)
	if unloaded or not obj or not obj.Parent then
		return nil
	end

	local tw = TweenService:Create(
		obj,
		TweenInfo.new(t or 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		props
	)

	tw:Play()
	return tw
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

local function Pad(obj, l, r, t, b)
	return New("UIPadding", {
		Parent = obj,
		PaddingLeft = UDim.new(0, l or 0),
		PaddingRight = UDim.new(0, r or 0),
		PaddingTop = UDim.new(0, t or 0),
		PaddingBottom = UDim.new(0, b or 0),
	})
end

local function AddList(parent, padding)
	return New("UIListLayout", {
		Parent = parent,
		Padding = UDim.new(0, padding or 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
end

local function Section(parent, title, height)
	local section = New("Frame", {
		Parent = parent,
		Size = UDim2.new(1, -1, 0, height),
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

	local titleLabel = Label(section, title, UDim2.new(1, -10, 0, 20), C.Text)
	titleLabel.Position = UDim2.fromOffset(6, 4)
	titleLabel.TextSize = 13

	local headerDivider = New("Frame", {
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
	})

	return section, body
end


local gui = New("ScreenGui", {
	Name = "UI-v5",
	Parent = guiParent,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
})

local displayOrderSet = false

for _, displayOrder in ipairs({
	2147483647,
	1000000,
	100000,
	10000,
}) do
	if not displayOrderSet then
		local ok = pcall(function()
			gui.DisplayOrder = displayOrder
		end)

		if ok then
			displayOrderSet = true
		end
	end
end

pcall(function()
	gui.OnTopOfCoreBlur = true
end)

local Library = {}
RuntimeEnvironment.__UI_V5_RUNTIME = Library

local notificationOrder = 0

local configRegistry = {}
local configRegistryCounter = 0

local CONFIG_ROOT = "UI-v5"
local CONFIG_FOLDER = CONFIG_ROOT .. "/configs"
local AUTOLOAD_FILE = CONFIG_ROOT .. "/autoload.json"

local runtimeConfigStore = {}
local runtimeAutoloadConfig = nil

local fs_isfolder = isfolder or RuntimeEnvironment.isfolder
local fs_makefolder = makefolder or RuntimeEnvironment.makefolder
local fs_isfile = isfile or RuntimeEnvironment.isfile
local fs_writefile = writefile or RuntimeEnvironment.writefile
local fs_readfile = readfile or RuntimeEnvironment.readfile
local fs_delfile = delfile or RuntimeEnvironment.delfile
local fs_listfiles = listfiles or RuntimeEnvironment.listfiles

local function RegisterConfigControl(kind, control)
	if not control then
		return control
	end

	configRegistryCounter += 1

	local id = string.format(
		"%03d_%s",
		configRegistryCounter,
		tostring(kind or "value")
	)

	configRegistry[id] = {
		Kind = kind,
		Control = control,
	}

	return control
end

local function NormalizeConfigName(name)
	local normalized = tostring(name or "")

	normalized = normalized:gsub("^%s+", "")
	normalized = normalized:gsub("%s+$", "")
	normalized = normalized:gsub("%.json$", "")
	normalized = normalized:gsub("[^%w%-%_ ]", "")
	normalized = normalized:gsub("%s+", "_")

	if #normalized > 40 then
		normalized = normalized:sub(1, 40)
	end

	return normalized
end

local function ConfigPath(name)
	return CONFIG_FOLDER .. "/" .. name .. ".json"
end

local function EnsureConfigFolder()
	if type(fs_makefolder) == "function" then
		pcall(fs_makefolder, CONFIG_ROOT)
		pcall(fs_makefolder, CONFIG_FOLDER)
	end
end

local function EncodeConfigEntry(entry)
	local kind = entry.Kind
	local control = entry.Control

	if kind == "color" then
		local color = control.Get and control.Get()

		if typeof(color) == "Color3" then
			return {
				R = color.R,
				G = color.G,
				B = color.B,
			}
		end

	elseif kind == "keybind" then
		local key = control.GetKey and control.GetKey()
		local mode = control.GetMode and control.GetMode()

		return {
			Key = key and key.Name or nil,
			Mode = mode,
		}

	else
		if control.Get then
			return control.Get()
		end
	end

	return nil
end

local function ApplyConfigEntry(entry, value)
	local kind = entry.Kind
	local control = entry.Control

	if kind == "color" then
		if type(value) == "table"
			and tonumber(value.R)
			and tonumber(value.G)
			and tonumber(value.B)
			and control.Set then

			control.Set(Color3.new(
				math.clamp(tonumber(value.R), 0, 1),
				math.clamp(tonumber(value.G), 0, 1),
				math.clamp(tonumber(value.B), 0, 1)
			))
		end

	elseif kind == "keybind" then
		if type(value) ~= "table" then
			return
		end

		if value.Mode and control.SetMode then
			control.SetMode(tostring(value.Mode))
		end

		if value.Key and Enum.KeyCode[tostring(value.Key)] then
			if control.SetKey then
				control.SetKey(Enum.KeyCode[tostring(value.Key)])
			end
		elseif control.Clear then
			control.Clear()
		end

	else
		if control.Set then
			control.Set(value)
		end
	end
end

function Library:SaveConfig(name)
	if unloaded then
		return false, "runtime unloaded"
	end

	name = NormalizeConfigName(name)

	if name == "" then
		return false, "enter config name"
	end

	local payload = {
		Version = 1,
		SavedAt = os.time(),
		Values = {},
	}

	for id, entry in pairs(configRegistry) do
		local ok, value = pcall(EncodeConfigEntry, entry)

		if ok and value ~= nil then
			payload.Values[id] = value
		end
	end

	local okEncode, encoded = pcall(
		HttpService.JSONEncode,
		HttpService,
		payload
	)

	if not okEncode then
		return false, "encode failed"
	end

	local savedToFile = false

	if type(fs_writefile) == "function" then
		EnsureConfigFolder()

		local okWrite = pcall(
			fs_writefile,
			ConfigPath(name),
			encoded
		)

		savedToFile = okWrite
	end

	if not savedToFile then
		runtimeConfigStore[name] = encoded
	end

	return true, name
end

function Library:LoadConfig(name)
	if unloaded then
		return false, "runtime unloaded"
	end

	name = NormalizeConfigName(name)

	if name == "" then
		return false, "select config"
	end

	local encoded = nil
	local path = ConfigPath(name)

	if type(fs_readfile) == "function" then
		local canRead = true

		if type(fs_isfile) == "function" then
			local okFile, exists = pcall(fs_isfile, path)
			canRead = okFile and exists == true
		end

		if canRead then
			local okRead, result = pcall(fs_readfile, path)

			if okRead and type(result) == "string" then
				encoded = result
			end
		end
	end

	if not encoded then
		encoded = runtimeConfigStore[name]
	end

	if not encoded then
		return false, "config not found"
	end

	local okDecode, payload = pcall(
		HttpService.JSONDecode,
		HttpService,
		encoded
	)

	if not okDecode or type(payload) ~= "table" then
		return false, "invalid config"
	end

	local values = payload.Values

	if type(values) ~= "table" then
		return false, "invalid values"
	end

	for id, value in pairs(values) do
		local entry = configRegistry[id]

		if entry then
			pcall(ApplyConfigEntry, entry, value)
		end
	end

	return true, name
end

function Library:DeleteConfig(name)
	if unloaded then
		return false, "runtime unloaded"
	end

	name = NormalizeConfigName(name)

	if name == "" then
		return false, "select config"
	end

	local removed = false
	local path = ConfigPath(name)

	if type(fs_delfile) == "function" then
		local exists = true

		if type(fs_isfile) == "function" then
			local okFile, result = pcall(fs_isfile, path)
			exists = okFile and result == true
		end

		if exists then
			local okDelete = pcall(fs_delfile, path)

			if okDelete then
				removed = true
			end
		end
	end

	if runtimeConfigStore[name] ~= nil then
		runtimeConfigStore[name] = nil
		removed = true
	end

	if not removed then
		return false, "config not found"
	end

	return true, name
end

function Library:GetConfigs()
	local result = {}
	local seen = {}

	if type(fs_listfiles) == "function" then
		EnsureConfigFolder()

		local okList, files = pcall(fs_listfiles, CONFIG_FOLDER)

		if okList and type(files) == "table" then
			for _, path in ipairs(files) do
				local fileName =
					tostring(path):match("([^/\\]+)%.json$")

				if fileName and fileName ~= "" and not seen[fileName] then
					seen[fileName] = true
					table.insert(result, fileName)
				end
			end
		end
	end

	for name in pairs(runtimeConfigStore) do
		if not seen[name] then
			seen[name] = true
			table.insert(result, name)
		end
	end

	table.sort(result, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	return result
end


function Library:CreateConfig(name)
	name = NormalizeConfigName(name)

	if name == "" then
		return false, "enter config name"
	end

	if table.find(self:GetConfigs(), name) then
		return false, "config already exists"
	end

	return self:SaveConfig(name)
end

function Library:SetAutoload(name)
	if unloaded then
		return false, "runtime unloaded"
	end

	name = NormalizeConfigName(name)

	if name == "" then
		return false, "select config"
	end

	if not table.find(self:GetConfigs(), name) then
		return false, "config not found"
	end

	local payload = {
		Version = 1,
		Config = name,
	}

	local okEncode, encoded = pcall(
		HttpService.JSONEncode,
		HttpService,
		payload
	)

	if not okEncode then
		return false, "autoload encode failed"
	end

	if type(fs_writefile) == "function" then
		EnsureConfigFolder()

		local okWrite = pcall(
			fs_writefile,
			AUTOLOAD_FILE,
			encoded
		)

		if not okWrite then
			runtimeAutoloadConfig = name
			return true, name
		end
	end

	runtimeAutoloadConfig = name
	return true, name
end

function Library:GetAutoload()
	if type(fs_readfile) == "function" then
		local canRead = true

		if type(fs_isfile) == "function" then
			local okFile, exists = pcall(
				fs_isfile,
				AUTOLOAD_FILE
			)

			canRead = okFile and exists == true
		end

		if canRead then
			local okRead, encoded = pcall(
				fs_readfile,
				AUTOLOAD_FILE
			)

			if okRead and type(encoded) == "string" then
				local okDecode, payload = pcall(
					HttpService.JSONDecode,
					HttpService,
					encoded
				)

				if okDecode
					and type(payload) == "table"
					and payload.Config ~= nil then

					local name =
						NormalizeConfigName(payload.Config)

					if name ~= "" then
						runtimeAutoloadConfig = name
						return name
					end
				end
			end
		end
	end

	return runtimeAutoloadConfig
end

function Library:ClearAutoload()
	if unloaded then
		return false, "runtime unloaded"
	end

	if type(fs_delfile) == "function" then
		local shouldDelete = true

		if type(fs_isfile) == "function" then
			local okFile, exists = pcall(
				fs_isfile,
				AUTOLOAD_FILE
			)

			shouldDelete = okFile and exists == true
		end

		if shouldDelete then
			pcall(fs_delfile, AUTOLOAD_FILE)
		end
	end

	runtimeAutoloadConfig = nil

	return true, "autoload cleared"
end


local function MeasureText(text, textSize, maxWidth)
	return TextService:GetTextSize(
		tostring(text or ""),
		textSize,
		FONT,
		Vector2.new(maxWidth or 1000, 1000)
	)
end

local watermarkSide = "Right"
local watermarkTitle = "Developer : (discord) @nelessk"
local watermarkDragging = false
local watermarkDragStart = nil
local watermarkStartPosition = nil

local watermark = New("CanvasGroup", {
	Name = "Watermark",
	Parent = gui,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 0),
	Size = UDim2.fromOffset(270, 34),
	BackgroundColor3 = Color3.fromRGB(14, 14, 17),
	BorderSizePixel = 0,
	GroupTransparency = 0,
	ZIndex = 2000,
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

local gradientTween = TweenService:Create(
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
gradientTween:Play()

local watermarkInner = New("Frame", {
	Parent = watermark,
	Position = UDim2.fromOffset(2, 2),
	Size = UDim2.new(1, -4, 1, -4),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 2001,
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
watermarkText.Font = FONT
watermarkText.ZIndex = 2003

local watermarkDragArea = New("TextButton", {
	Parent = watermark,
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 2010,
})

local function MeasureWatermarkWidth()
	local measured = MeasureText(watermarkTitle, 13, 1000)
	return math.clamp(measured.X + 24, 150, 420)
end

local function ResizeWatermark()
	Tween(watermark, {
		Size = UDim2.fromOffset(MeasureWatermarkWidth(), 34),
	}, 0.14)
end

local function GetWatermarkPosition(side)
	if side == "Left" then
		return UDim2.new(0, 0, 0, 0)
	end

	return UDim2.new(1, 0, 0, 0)
end

local function NormalizeWatermarkSide(side)
	local normalized = string.lower(tostring(side or ""))

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

		Tween(watermark, {
			BackgroundColor3 = Color3.fromRGB(20, 17, 22),
		}, 0.08)

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
	local x = watermarkStartPosition.X.Offset + delta.X
	local y = watermarkStartPosition.Y.Offset + delta.Y

	watermark.Position = UDim2.fromOffset(x, y)
end))

Track(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		if watermarkDragging then
			watermarkDragging = false

			Tween(watermark, {
				BackgroundColor3 = Color3.fromRGB(14, 14, 17),
			}, 0.10)

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

	if type(text) == "table" then
		local data = text

		watermarkTitle = tostring(
			data.Title
			or data.Text
			or data.Name
			or data.title
			or data.text
			or data.name
			or watermarkTitle
		)

		local requestedSide =
			data.Side
			or data.Position
			or data.side
			or data.position

		if requestedSide ~= nil then
			local normalized = NormalizeWatermarkSide(requestedSide)

			if normalized then
				watermarkSide = normalized
			end
		end
	else
		if text ~= nil then
			watermarkTitle = tostring(text)
		end

		if side ~= nil then
			local normalized = NormalizeWatermarkSide(side)

			if normalized then
				watermarkSide = normalized
			end
		end
	end

	watermarkText.Text = watermarkTitle
	ResizeWatermark()

	if watermarkSide == "Left" or watermarkSide == "Right" then
		watermark.AnchorPoint = watermarkSide == "Left"
			and Vector2.new(0, 0)
			or Vector2.new(1, 0)

		Tween(watermark, {
			Position = GetWatermarkPosition(watermarkSide),
		}, 0.14)
	end
end

function Library:SetWatermarkTitle(text)
	if unloaded or not watermarkText.Parent then
		return
	end

	watermarkTitle = tostring(text or "")
	watermarkText.Text = watermarkTitle
	ResizeWatermark()
end

function Library:SetWatermarkPosition(side)
	if unloaded or not watermark.Parent then
		return
	end

	local normalized = NormalizeWatermarkSide(side)

	if not normalized then
		return
	end

	watermarkSide = normalized

	watermark.AnchorPoint = watermarkSide == "Left"
		and Vector2.new(0, 0)
		or Vector2.new(1, 0)

	Tween(watermark, {
		Position = GetWatermarkPosition(watermarkSide),
	}, 0.14)
end

function Library:SetWatermarkVisible(state)
	if unloaded or not watermark.Parent then
		return
	end

	state = state == true

	if state then
		watermark.Visible = true
		watermark.GroupTransparency = 1

		if watermarkSide == "Left" or watermarkSide == "Right" then
			watermark.AnchorPoint = watermarkSide == "Left"
				and Vector2.new(0, 0)
				or Vector2.new(1, 0)

			watermark.Position = GetWatermarkPosition(watermarkSide)
		end

		Tween(watermark, {
			GroupTransparency = 0,
		}, 0.12)
	else
		local tween = Tween(watermark, {
			GroupTransparency = 1,
		}, 0.10)

		if tween then
			tween.Completed:Connect(function()
				if watermark.Parent and watermark.GroupTransparency >= 0.99 then
					watermark.Visible = false
				end
			end)
		end
	end
end

ResizeWatermark()

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

function Library:Notify(data, duration)
	if unloaded or not notificationRoot.Parent then
		return
	end

	local titleText = nil
	local bodyText = nil
	local lifetime = duration or 3

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

		if rawTitle ~= nil and tostring(rawTitle) ~= "" then
			titleText = tostring(rawTitle)
		end

		if rawBody ~= nil and tostring(rawBody) ~= "" then
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
		if data ~= nil and tostring(data) ~= "" then
			bodyText = tostring(data)
		end
	end

	if not titleText and not bodyText then
		return
	end

	lifetime = math.clamp(lifetime, 0.5, 30)
	notificationOrder += 1

	local titleSize = 14
	local bodySize = 13
	local minWidth = 125
	local maxWidth = 285
	local horizontalPadding = 18

	local titleNatural = titleText
		and MeasureText(titleText, titleSize, 1000)
		or Vector2.zero

	local bodyNatural = bodyText
		and MeasureText(bodyText, bodySize, 1000)
		or Vector2.zero

	local wantedWidth = math.max(
		titleNatural.X,
		bodyNatural.X
	) + horizontalPadding

	local cardWidth = math.clamp(
		wantedWidth,
		minWidth,
		maxWidth
	)

	local contentWidth = cardWidth - horizontalPadding

	local titleHeight = 0
	if titleText then
		local measured = MeasureText(
			titleText,
			titleSize,
			contentWidth
		)
		titleHeight = math.max(15, measured.Y)
	end

	local bodyHeight = 0
	if bodyText then
		local measured = MeasureText(
			bodyText,
			bodySize,
			contentWidth
		)
		bodyHeight = math.max(14, measured.Y)
	end

	local topPadding = 4
	local bottomPadding = 5
	local gap = (titleText and bodyText) and 1 or 0

	local cardHeight =
		topPadding
		+ titleHeight
		+ gap
		+ bodyHeight
		+ bottomPadding

	cardHeight = math.max(
		cardHeight,
		(titleText and bodyText) and 35 or 24
	)

	local holder = New("Frame", {
		Parent = notificationRoot,
		Size = UDim2.new(1, 0, 0, cardHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = notificationOrder,
		ZIndex = 1901,
	})

	local card = New("CanvasGroup", {
		Parent = holder,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 20, 0, 0),
		Size = UDim2.fromOffset(cardWidth, cardHeight),
		BackgroundColor3 = Color3.fromRGB(14, 14, 17),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		ClipsDescendants = false,
		GroupTransparency = 1,
		ZIndex = 1902,
	})
	Corner(card, 6)

	local borderStroke = New("UIStroke", {
		Parent = card,
		Color = Color3.fromRGB(61, 47, 66),
		Thickness = 1.2,
		Transparency = 0.30,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	local beam = New("Frame", {
		Parent = card,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(6, 0),
		Size = UDim2.fromOffset(22, 4),
		BackgroundColor3 = Color3.fromRGB(236, 164, 246),
		BorderSizePixel = 0,
		Rotation = 0,
		ZIndex = 1906,
	})
	Corner(beam, 2)

	New("UIGradient", {
		Parent = beam,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(118, 72, 128)),
			ColorSequenceKeypoint.new(0.50, Color3.fromRGB(248, 191, 255)),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(118, 72, 128)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1.00),
			NumberSequenceKeypoint.new(0.24, 0.48),
			NumberSequenceKeypoint.new(0.50, 0.00),
			NumberSequenceKeypoint.new(0.76, 0.48),
			NumberSequenceKeypoint.new(1.00, 1.00),
		}),
	})

	local function SetBeamOnTopPath(distance)
		local w = cardWidth
		local h = cardHeight
		local r = math.min(6, w * 0.12, h * 0.35)

		local sideLength = math.max(0, h - r)
		local topLength = math.max(0, w - (2 * r))
		local arcLength = (math.pi * r) / 2

		local pathLength =
			sideLength
			+ arcLength
			+ topLength
			+ arcLength
			+ sideLength

		if pathLength <= 0 then
			return nil, nil, nil, 1
		end

		local d = math.clamp(distance, 0, pathLength)
		local x, y, rotation

		if d <= sideLength then
			x = 0
			y = h - d
			rotation = 270
			return x, y, rotation, pathLength
		end
		d -= sideLength

		if d <= arcLength then
			local t = d / arcLength
			local theta = math.pi - (t * math.pi / 2)

			x = r + (r * math.cos(theta))
			y = r + (r * math.sin(theta))
			rotation = math.deg(theta + (math.pi / 2))
			return x, y, rotation, pathLength
		end
		d -= arcLength

		if d <= topLength then
			x = r + d
			y = 0
			rotation = 0
			return x, y, rotation, pathLength
		end
		d -= topLength

		if d <= arcLength then
			local t = d / arcLength
			local theta = (-math.pi / 2) + (t * math.pi / 2)

			x = (w - r) + (r * math.cos(theta))
			y = r + (r * math.sin(theta))
			rotation = math.deg(theta + (math.pi / 2))
			return x, y, rotation, pathLength
		end
		d -= arcLength

		x = w
		y = r + d
		rotation = 90

		return x, y, rotation, pathLength
	end

		task.spawn(function()
		local travelTime = 2.6
		local elapsed = 0

		local _, _, _, pathLength = SetBeamOnTopPath(0)

		while not unloaded
			and holder.Parent
			and card.Parent
			and beam.Parent do

			local dt = RunService.RenderStepped:Wait()

			if not holder.Parent
				or not card.Parent
				or not beam.Parent then
				break
			end

			elapsed += dt

			local cycle = (elapsed / travelTime) % 2
			local linearAlpha

			if cycle <= 1 then
				linearAlpha = cycle
			else
				linearAlpha = 2 - cycle
			end

			local alpha =
				0.5
				- (math.cos(linearAlpha * math.pi) * 0.5)

			local distance = pathLength * alpha

			local x, y, rotation, updatedLength =
				SetBeamOnTopPath(distance)

			if updatedLength then
				pathLength = updatedLength
			end

			if x and y and rotation then
				beam.Position = UDim2.fromOffset(x, y)
				beam.Rotation = rotation
			end
		end
	end)

		local inner = New("Frame", {
		Parent = card,
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 1903,
	})
	Corner(inner, 5)

	New("UIStroke", {
		Parent = inner,
		Color = Color3.fromRGB(38, 38, 43),
		Thickness = 1,
		Transparency = 0.28,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})

	local y = topPadding

	if titleText then
		local titleLabel = Label(
			card,
			titleText,
			UDim2.fromOffset(contentWidth, titleHeight),
			Color3.fromRGB(252, 252, 254)
		)

		titleLabel.Position = UDim2.fromOffset(9, y)
		titleLabel.TextSize = titleSize
		titleLabel.Font = FONT
		titleLabel.TextWrapped = true
		titleLabel.TextTruncate = Enum.TextTruncate.None
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleLabel.ZIndex = 1904

		y += titleHeight + gap
	end

	if bodyText then
		local bodyLabel = Label(
			card,
			bodyText,
			UDim2.fromOffset(contentWidth, bodyHeight),
			Color3.fromRGB(230, 230, 236)
		)

		bodyLabel.Position = UDim2.fromOffset(9, y)
		bodyLabel.TextSize = bodySize
		bodyLabel.Font = FONT
		bodyLabel.TextWrapped = true
		bodyLabel.TextTruncate = Enum.TextTruncate.None
		bodyLabel.TextYAlignment = Enum.TextYAlignment.Center
		bodyLabel.ZIndex = 1904
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

	local progressTween = TweenService:Create(
		progress,
		TweenInfo.new(
			lifetime,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
		),
		{
			Size = UDim2.new(0, 0, 0, 2),
		}
	)
	progressTween:Play()

	task.delay(lifetime, function()
		if unloaded or not holder.Parent or not card.Parent then
			return
		end

		local hideTween = Tween(card, {
			GroupTransparency = 1,
			Position = UDim2.new(1, 20, 0, 0),
		}, 0.11)

		if hideTween then
			hideTween.Completed:Connect(function()
				if holder and holder.Parent then
					holder:Destroy()
				end
			end)
		else
			holder:Destroy()
		end
	end)

	return holder
end

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

local innerStroke = New("UIStroke", {
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

local title = Label(top, "Rat.Lua | Aftermath", UDim2.new(1, -16, 1, 0), C.Text)
title.Position = UDim2.fromOffset(8, 0)
title.TextSize = 13


local separator = New("Frame", {
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

local tabs = {"visuals", "combat", "character", "misc", "config"}

local tabDisplayNames = {
	visuals = "Visuals",
	combat = "Combat",
	character = "Movement",
	misc = "World",
	config = "Config",
}

local pages = {}
local tabButtons = {}

for _, name in ipairs(tabs) do
	pages[name] = New("CanvasGroup", {
		Name = name,
		Parent = main,
		Position = UDim2.fromOffset(7, 61),
		Size = UDim2.new(1, -14, 1, -68),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
	})
end

local tabWidth = 130
local tabGap = 3
local currentTab = nil
local tabIndices = {}
local tabPageTweens = {}
local tabIndicatorTween = nil

local tabIndicator = New("Frame", {
	Parent = tabBar,
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.fromOffset(0, 2),
	BackgroundColor3 = C.Accent,
	BackgroundTransparency = 0,
	BorderSizePixel = 0,
	ZIndex = 20,
})
Corner(tabIndicator, 2)

local tabIndicatorGlow = New("Frame", {
	Parent = tabBar,
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.fromOffset(0, 1),
	Size = UDim2.fromOffset(0, 3),
	BackgroundColor3 = C.Accent,
	BackgroundTransparency = 0.76,
	BorderSizePixel = 0,
	ZIndex = 19,
})
Corner(tabIndicatorGlow, 3)

local tabIndicatorGlowTween = nil

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
				0.10,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				GroupTransparency = 1,
				Position = UDim2.fromOffset(4, 61),
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
				oldPage.Position = UDim2.fromOffset(7, 61)
			end
		end)
	end

	local nextPage = pages[name]
	nextPage.Visible = true
	nextPage.GroupTransparency = previousTab and 1 or 0
	nextPage.Position = previousTab
		and UDim2.fromOffset(10, 61)
		or UDim2.fromOffset(7, 61)

	if previousTab then
		if tabPageTweens[name] then
			tabPageTweens[name]:Cancel()
			tabPageTweens[name] = nil
		end

		local fadeIn = TweenService:Create(
			nextPage,
			TweenInfo.new(
				0.16,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.Out
			),
			{
				GroupTransparency = 0,
				Position = UDim2.fromOffset(7, 61),
			}
		)

		tabPageTweens[name] = fadeIn
		fadeIn:Play()

		fadeIn.Completed:Connect(function()
			if tabPageTweens[name] == fadeIn then
				tabPageTweens[name] = nil
			end
		end)
	end
end

for i, name in ipairs(tabs) do
	tabIndices[name] = i

	local button = New("TextButton", {
		Parent = tabBar,
		Position = UDim2.fromOffset((i - 1) * (tabWidth + tabGap), 0),
		Size = UDim2.fromOffset(tabWidth, 25),

		BackgroundColor3 = Color3.fromRGB(17, 17, 18),
		BorderSizePixel = 0,
		AutoButtonColor = false,

		Text = tabDisplayNames[name] or name,
		TextColor3 = C.Muted,
		TextSize = 14,
		Font = FONT,

		ZIndex = 10,
	})

	Stroke(button, C.BorderSoft, 0.56)
	Corner(button, 4)

	Track(button.MouseEnter:Connect(function()
		if currentTab ~= name then
			Tween(button, {
				BackgroundColor3 = Color3.fromRGB(22, 21, 23),
				TextColor3 = Color3.fromRGB(174, 174, 181),
			}, 0.11)
		end
	end))

	Track(button.MouseLeave:Connect(function()
		if currentTab ~= name then
			Tween(button, {
				BackgroundColor3 = Color3.fromRGB(17, 17, 18),
				TextColor3 = C.Muted,
			}, 0.13)
		end
	end))

	Track(button.MouseButton1Click:Connect(function()
		SetTab(name)
	end))

	tabButtons[name] = button
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

	local toggleGradientFill = New("Frame", {
		Parent = button,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = default and 0 or 1,
		BorderSizePixel = 0,
	})
	Corner(toggleGradientFill, 2)

	New("UIGradient", {
		Parent = toggleGradientFill,
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(91, 51, 101)),
			ColorSequenceKeypoint.new(0.50, C.Accent),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(226, 162, 235)),
		}),
	})

	local name = Label(row, text, UDim2.new(1, -20, 1, 0), C.Text)
	name.Position = UDim2.fromOffset(19, 0)

	local state = default == true
	local hovering = false

	local function Visual()
		local offColor = hovering
			and Color3.fromRGB(24, 23, 26)
			or Color3.fromRGB(18, 18, 20)

		Tween(button, {
			BackgroundColor3 = offColor,
		}, 0.11)

		Tween(toggleGradientFill, {
			BackgroundTransparency = state
				and (hovering and 0.04 or 0)
				or 1,
		}, 0.11)

		Tween(name, {
			TextColor3 = state
				and Color3.fromRGB(224, 224, 228)
				or C.Text,
		}, 0.11)
	end

	local function Set(v, fire)
		state = v == true
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

	Track(row.MouseButton1Down:Connect(function()
		Tween(button, {
			BackgroundColor3 = Color3.fromRGB(27, 24, 29),
		}, MOTION.Fast)

		Tween(toggleGradientFill, {
			BackgroundTransparency = state and 0.10 or 1,
		}, MOTION.Fast)
	end))

	Track(row.MouseButton1Up:Connect(function()
		Visual()
	end))

	Track(row.MouseButton1Click:Connect(function()
		Set(not state, true)
	end))

	Visual()

	local control = {
		Set = function(v)
			Set(v, true)
		end,
		Get = function()
			return state
		end,
	}

	RegisterConfigControl("toggle", control)
	return control
end

local function AddSlider(parent, y, text, minVal, maxVal, default, callback)
	local name = Label(parent, text, UDim2.new(0.72, 0, 0, 16), C.Text)
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

	local trackStroke = Stroke(track, C.BorderSoft, 0.62)

	local fill = New("Frame", {
		Parent = track,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	Corner(fill, 3)

	local fillGradient = New("UIGradient", {
		Parent = fill,
		Rotation = 0,
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

	local thumbStroke = Stroke(thumb, Color3.fromRGB(235, 205, 239), 0.42)

	local stripe = New("Frame", {
		Parent = thumb,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 1, 1, -4),
		BackgroundColor3 = Color3.fromRGB(255, 239, 255),
		BackgroundTransparency = 0.22,
		BorderSizePixel = 0,
		ZIndex = 6,
	})
	Corner(stripe, 1)

	local dragging = false
	local hovering = false
	local current = default

	local function FormatValue(value)
		if math.abs(value - math.floor(value)) < 0.001 then
			return tostring(math.floor(value))
		end
		return string.format("%.2f", value)
	end

	local function SetThumbState(active)
		if active then
			Tween(valueLabel, {
				TextColor3 = Color3.fromRGB(218, 186, 223),
			}, 0.09)

			Tween(thumb, {
				Size = UDim2.fromOffset(6, 16),
				BackgroundColor3 = Color3.fromRGB(232, 183, 238),
			}, 0.11)

			Tween(stripe, {
				Size = UDim2.new(0, 1, 1, -5),
				BackgroundTransparency = 0.05,
			}, 0.11)

			Tween(track, {
				BackgroundColor3 = Color3.fromRGB(37, 37, 40),
			}, 0.11)

			Tween(trackStroke, {
				Color = C.AccentDark,
				Transparency = 0.28,
			}, 0.11)

			Tween(fillGradient, {
				Offset = Vector2.new(0.06, 0),
			}, 0.13)

			Tween(thumbStroke, {
				Transparency = 0.18,
			}, 0.11)
		else
			Tween(valueLabel, {
				TextColor3 = C.Muted,
			}, 0.11)

			Tween(thumb, {
				Size = hovering and UDim2.fromOffset(4, 12) or UDim2.fromOffset(3, 10),
				BackgroundColor3 = Color3.fromRGB(220, 171, 226),
			}, 0.13)

			Tween(stripe, {
				Size = UDim2.new(0, 1, 1, -4),
				BackgroundTransparency = 0.22,
			}, 0.13)

			Tween(track, {
				BackgroundColor3 = Color3.fromRGB(31, 31, 34),
			}, 0.13)

			Tween(trackStroke, {
				Color = C.BorderSoft,
				Transparency = 0.62,
			}, 0.13)

			Tween(fillGradient, {
				Offset = Vector2.new(0, 0),
			}, 0.16)

			Tween(thumbStroke, {
				Transparency = 0.42,
			}, 0.13)
		end
	end

	local function UpdateValue(value, fire, instant)
		value = math.clamp(value, minVal, maxVal)
		current = value

		local alpha = 0
		if maxVal ~= minVal then
			alpha = (value - minVal) / (maxVal - minVal)
		end

		if instant then
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			thumb.Position = UDim2.new(alpha, 5 - (alpha * 10), 0.5, 0)
		else
			Tween(fill, {
				Size = UDim2.new(alpha, 0, 1, 0),
			}, 0.09)

			Tween(thumb, {
				Position = UDim2.new(alpha, 5 - (alpha * 10), 0.5, 0),
			}, 0.09)
		end

		valueLabel.Text = FormatValue(value)

		if fire and callback then
			callback(value)
		end
	end

	local function FromMouse(x)
		local left = hitbox.AbsolutePosition.X + 5
		local width = math.max(hitbox.AbsoluteSize.X - 10, 1)
		local alpha = math.clamp((x - left) / width, 0, 1)

		local value = minVal + ((maxVal - minVal) * alpha)
		value = math.floor(value * 100 + 0.5) / 100

		UpdateValue(value, true, true)
	end

	Track(hitbox.MouseEnter:Connect(function()
		hovering = true
		if not dragging then
			SetThumbState(false)
		end
	end))

	Track(hitbox.MouseLeave:Connect(function()
		hovering = false
		if not dragging then
			SetThumbState(false)
		end
	end))

	Track(hitbox.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			SetThumbState(true)
			FromMouse(input.Position.X)
		end
	end))

	Track(UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			FromMouse(input.Position.X)
		end
	end))

	Track(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
			dragging = false
			SetThumbState(false)
		end
	end))

	UpdateValue(default, false, true)

	local control = {
		Set = function(v)
			UpdateValue(v, true, false)
		end,
		Get = function()
			return current
		end,
	}

	RegisterConfigControl("slider", control)
	return control
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

		BackgroundColor3 = Color3.fromRGB(13, 13, 14),
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
			callback(active, currentMode, currentKey)
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
				BackgroundColor3 = Color3.fromRGB(24, 20, 26),
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
				BackgroundColor3 = Color3.fromRGB(13, 13, 14),
			}, MOTION.Hover)

			Tween(bindStroke, {
				Color = C.BorderSoft,
				Transparency = 0.40,
			}, MOTION.Hover)
		else
			button.Text = "none"

			Tween(button, {
				TextColor3 = C.Muted,
				BackgroundColor3 = Color3.fromRGB(13, 13, 14),
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

			Tween(old, {
				GroupTransparency = 1,
				Position = UDim2.new(
					old.Position.X.Scale,
					old.Position.X.Offset,
					old.Position.Y.Scale,
					old.Position.Y.Offset - 3
				),
			}, 0.09)

			task.delay(0.10, function()
				if old and old.Parent then
					old:Destroy()
				end
			end)
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
			Position = UDim2.fromOffset(x, py + 3),
			Size = UDim2.fromOffset(popupWidth, popupHeight),

			BackgroundColor3 = Color3.fromRGB(14, 14, 16),
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
			Position = UDim2.fromOffset(x, py),
		}, 0.10)

		for i, mode in ipairs(modes) do
			local selected = mode == currentMode

			local option = New("TextButton", {
				Parent = popup,
				Position = UDim2.fromOffset(0, (i - 1) * rowHeight),
				Size = UDim2.new(1, 0, 0, rowHeight),

				BackgroundColor3 = selected
					and Color3.fromRGB(29, 22, 31)
					or Color3.fromRGB(14, 14, 16),

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
					BackgroundColor3 = Color3.fromRGB(27, 27, 30),
				}, 0.07)
			end)

			local leave = option.MouseLeave:Connect(function()
				Tween(option, {
					BackgroundColor3 = selected
						and Color3.fromRGB(29, 22, 31)
						or Color3.fromRGB(14, 14, 16),
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
			BackgroundColor3 = Color3.fromRGB(26, 20, 28),
		}, 0.08)

		RefreshButton()
	end

	local function EndListening()
		listening = false
		capturingKeybind = false

		Tween(button, {
			BackgroundColor3 = Color3.fromRGB(13, 13, 14),
		}, 0.08)

		RefreshButton()
	end

	Track(button.MouseEnter:Connect(function()
		if not listening then
			Tween(button, {
				BackgroundColor3 = Color3.fromRGB(20, 20, 22),
			}, 0.08)
		end
	end))

	Track(button.MouseLeave:Connect(function()
		if not listening then
			Tween(button, {
				BackgroundColor3 = Color3.fromRGB(13, 13, 14),
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

		if processed or not currentKey then
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

	RegisterConfigControl("keybind", control)
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
			callback(color)
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

			Tween(old, {
				GroupTransparency = 1,
			}, 0.10)

			task.delay(0.11, function()
				if old and old.Parent then
					old:Destroy()
				end
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

			BackgroundColor3 = Color3.fromRGB(18, 18, 20),
			BorderSizePixel = 0,
			GroupTransparency = 1,

			ZIndex = 300,
		})

		Stroke(popup, C.Border, 0.33)
		Corner(popup, 6)

		activeColorPickerPopup = popup
		activeColorPickerPreview = preview

		Tween(popup, {
			GroupTransparency = 0,
		}, 0.12)


		local dragHeader = New("TextButton", {
			Parent = popup,
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 18),

			BackgroundColor3 = Color3.fromRGB(14, 14, 16),
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
					BackgroundColor3 = Color3.fromRGB(21, 21, 24),
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

			BackgroundColor3 = Color3.fromRGB(12, 12, 14),
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

		local function Refresh(fire)
			currentColor = Color3.fromHSV(h, s, v)

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
				callback(currentColor)
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

			Refresh(true)
		end

		local function UpdateHue(position)
			local ay = hueInput.AbsolutePosition.Y
			local ah = math.max(hueInput.AbsoluteSize.Y, 1)

			h = math.clamp(
				(position.Y - ay) / ah,
				0,
				1
			)

			Refresh(true)
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
						BackgroundColor3 = Color3.fromRGB(14, 14, 16),
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
				Refresh(true)
			else
				hexBox.Text = ToHex(currentColor)
			end
		end))

		Refresh(false)
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

	RegisterConfigControl("color", control)
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
	local current = default or options[1]
	local popup = nil
	local opened = false
	local popupConnections = {}

	local name = Label(parent, text, UDim2.new(1, 0, 0, 17), C.Text)
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
	local dropdownStroke = Stroke(button, C.BorderSoft, 0.50)
	Corner(button, 4)

	local valueText = Label(
		button,
		tostring(current),
		UDim2.new(1, -24, 1, 0),
		C.Text
	)
	valueText.Position = UDim2.fromOffset(6, 0)
	valueText.TextSize = 12
	valueText.ZIndex = 71

	local arrow = Label(
		button,
		"›",
		UDim2.fromOffset(18, 19),
		C.Muted,
		Enum.TextXAlignment.Center
	)
	arrow.Position = UDim2.new(1, -19, 0, 0)
	arrow.TextSize = 14
	arrow.ZIndex = 71

	local function DisconnectPopupConnections()
		for i = #popupConnections, 1, -1 do
			local connection = popupConnections[i]

			if connection and connection.Connected then
				connection:Disconnect()
			end

			popupConnections[i] = nil
		end
	end

	local function Close()
		opened = false
		DisconnectPopupConnections()

		if activeDropdownClose == Close then
			activeDropdownClose = nil
		end

		if activeDropdownPopup == popup then
			activeDropdownPopup = nil
		end

		if activeDropdownButton == button then
			activeDropdownButton = nil
		end

		Tween(arrow, {
			Rotation = 0,
			TextColor3 = C.Muted,
		}, MOTION.Popup)

		Tween(dropdownStroke, {
			Color = C.BorderSoft,
			Transparency = 0.50,
		}, MOTION.Popup)

		if popup and popup.Parent then
			local old = popup
			popup = nil

			Tween(old, {
				GroupTransparency = 1,
				Position = UDim2.new(
					old.Position.X.Scale,
					old.Position.X.Offset,
					old.Position.Y.Scale,
					old.Position.Y.Offset - 3
				),
			}, 0.09)

			task.delay(0.10, function()
				if old and old.Parent then
					old:Destroy()
				end
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

		if activeDropdownClose and activeDropdownClose ~= Close then
			activeDropdownClose()
		end

		if activeColorPickerClose then
			activeColorPickerClose()
		end

		if activeKeybindClose then
			activeKeybindClose()
		end

		opened = true

		local rowHeight = 20
		local popupHeight = rowHeight * #options
		local popupWidth = math.max(button.AbsoluteSize.X, 110)

		local x = button.AbsolutePosition.X - main.AbsolutePosition.X
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
			Position = UDim2.fromOffset(x, py + 3),
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

		Tween(dropdownStroke, {
			Color = C.AccentDark,
			Transparency = 0.20,
		}, MOTION.Popup)

		Tween(popup, {
			GroupTransparency = 0,
			Position = UDim2.fromOffset(x, py),
		}, 0.10)

		for i, option in ipairs(options) do
			local selected = option == current

			local opt = New("TextButton", {
				Parent = popup,
				Position = UDim2.fromOffset(0, (i - 1) * rowHeight),
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

			if i > 1 then
				New("Frame", {
					Parent = opt,
					Position = UDim2.fromOffset(6, 0),
					Size = UDim2.new(1, -12, 0, 1),

					BackgroundColor3 = C.BorderSoft,
					BackgroundTransparency = 0.58,
					BorderSizePixel = 0,

					ZIndex = 462,
				})
			end

			local enter = opt.MouseEnter:Connect(function()
				Tween(opt, {
					BackgroundColor3 = C.PanelHover,
				}, 0.07)
			end)

			local leave = opt.MouseLeave:Connect(function()
				Tween(opt, {
					BackgroundColor3 = selected
						and Color3.fromRGB(29, 22, 31)
						or Color3.fromRGB(14, 14, 16),
				}, 0.07)
			end)

			local click = opt.MouseButton1Click:Connect(function()
				current = option
				valueText.Text = tostring(current)
				Close()

				if callback then
					callback(current)
				end
			end)

			table.insert(popupConnections, enter)
			table.insert(popupConnections, leave)
			table.insert(popupConnections, click)

			Track(enter)
			Track(leave)
			Track(click)
		end
	end

	Track(button.MouseEnter:Connect(function()
		if not opened then
			Tween(button, {
				BackgroundColor3 = C.PanelHover,
			}, MOTION.Fast)
		end
	end))

	Track(button.MouseLeave:Connect(function()
		if not opened then
			Tween(button, {
				BackgroundColor3 = Color3.fromRGB(13, 13, 14),
			}, MOTION.Hover)
		end
	end))

	Track(button.MouseButton1Click:Connect(Open))

	local control = {
		Get = function()
			return current
		end,

		Set = function(value)
			if table.find(options, value) then
				current = value
				valueText.Text = tostring(current)

				if callback then
					callback(current)
				end
			end
		end,

		Close = Close,
	}

	RegisterConfigControl("dropdown", control)
	return control
end


local function AddFeatureRow(parent, y, text, options)
	options = options or {}

	local hasSlider = options.Slider ~= nil
	local hasColor = options.Color ~= nil and options.Color ~= false
	local hasBind = options.Bind ~= nil and options.Bind ~= false

	local rowHeight = hasSlider and 53 or 22

	local row = New("Frame", {
		Parent = parent,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, rowHeight),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	local enabled = options.Default == true

	local toggleBox = New("TextButton", {
		Parent = row,
		Position = UDim2.fromOffset(1, 4),
		Size = UDim2.fromOffset(13, 13),
		BackgroundColor3 = Color3.fromRGB(18, 18, 20),
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	})
	Corner(toggleBox, 2)

	local toggleGradientFill = New("Frame", {
		Parent = toggleBox,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = enabled and 0 or 1,
		BorderSizePixel = 0,
	})
	Corner(toggleGradientFill, 2)

	New("UIGradient", {
		Parent = toggleGradientFill,
		Rotation = 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromRGB(91, 51, 101)),
			ColorSequenceKeypoint.new(0.50, C.Accent),
			ColorSequenceKeypoint.new(1.00, Color3.fromRGB(226, 162, 235)),
		}),
	})

	local rightUsed = 0

	local bindHolder = nil
	local bindControl = nil

	if hasBind then
		bindHolder = New("Frame", {
			Parent = row,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 0, 0, 0),
			Size = UDim2.fromOffset(62, 20),
			BackgroundTransparency = 1,
		})

		local bindOptions = options.Bind
		if type(bindOptions) ~= "table" then
			bindOptions = {}
		end

		bindControl = AddKeybind(
			bindHolder,
			0,
			"",
			bindOptions.Key,
			bindOptions.Mode or "Toggle",
			function(active, mode, key)
				if bindOptions.Callback then
					bindOptions.Callback(active, mode, key)
				end
			end
		)

		rightUsed += 66
	end

	local colorHolder = nil
	local colorControl = nil

	if hasColor then
		colorHolder = New("Frame", {
			Parent = row,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -rightUsed, 0, 1),
			Size = UDim2.fromOffset(26, 18),
			BackgroundTransparency = 1,
		})

		local colorOptions = options.Color
		if type(colorOptions) ~= "table" then
			colorOptions = {}
		end

		colorControl = AddColorPicker(
			colorHolder,
			0,
			"",
			colorOptions.Default or Color3.new(1, 1, 1),
			function(color)
				if colorOptions.Callback then
					colorOptions.Callback(color)
				end
			end
		)

		rightUsed += 31
	end

	local name = Label(
		row,
		text,
		UDim2.new(1, -(20 + rightUsed), 0, 20),
		C.Text
	)
	name.Position = UDim2.fromOffset(19, 0)

	local function SetEnabled(value, fire)
		enabled = value == true

		Tween(toggleBox, {
			BackgroundColor3 = Color3.fromRGB(18, 18, 20),
		}, 0.11)

		Tween(toggleGradientFill, {
			BackgroundTransparency = enabled and 0 or 1,
		}, 0.11)

		if fire and options.Callback then
			options.Callback(enabled)
		end
	end

	Track(toggleBox.MouseEnter:Connect(function()
		Tween(toggleBox, {
			BackgroundColor3 = Color3.fromRGB(24, 23, 26),
		}, MOTION.Fast)

		Tween(toggleGradientFill, {
			BackgroundTransparency = enabled and 0.04 or 1,
		}, MOTION.Fast)
	end))

	Track(toggleBox.MouseLeave:Connect(function()
		Tween(toggleBox, {
			BackgroundColor3 = Color3.fromRGB(18, 18, 20),
		}, MOTION.Hover)

		Tween(toggleGradientFill, {
			BackgroundTransparency = enabled and 0 or 1,
		}, MOTION.Hover)
	end))

	Track(toggleBox.MouseButton1Click:Connect(function()
		SetEnabled(not enabled, true)
	end))

	local sliderControl = nil

	if hasSlider then
		local sliderOptions = options.Slider
		if type(sliderOptions) ~= "table" then
			sliderOptions = {}
		end

		sliderControl = AddSlider(
			row,
			22,
			sliderOptions.Text or "",
			sliderOptions.Min or 0,
			sliderOptions.Max or 100,
			sliderOptions.Default or 0,
			function(value)
				if sliderOptions.Callback then
					sliderOptions.Callback(value)
				end
			end
		)
	end

	local control = {
		Get = function()
			return enabled
		end,

		Set = function(value)
			SetEnabled(value, true)
		end,

		Color = colorControl,
		Slider = sliderControl,
		Bind = bindControl,
	}

	RegisterConfigControl("toggle", control)
	return control
end

local function AddSubTitle(parent, y, text)
	local center = Label(parent, text, UDim2.fromOffset(90, 18), C.Muted, Enum.TextXAlignment.Center)
	center.AnchorPoint = Vector2.new(0.5, 0)
	center.Position = UDim2.new(0.5, 0, 0, y)

	local left = New("Frame", {
		Parent = parent,
		Position = UDim2.new(0, 0, 0, y + 9),
		Size = UDim2.new(0.5, -50, 0, 1),
		BackgroundColor3 = C.BorderSoft,
		BorderSizePixel = 0,
	})

	local right = New("Frame", {
		Parent = parent,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, y + 9),
		Size = UDim2.new(0.5, -50, 0, 1),
		BackgroundColor3 = C.BorderSoft,
		BorderSizePixel = 0,
	})
end


local visuals = pages.visuals

local left = New("ScrollingFrame", {
	Parent = visuals,
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Color3.fromRGB(92, 67, 98),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromOffset(0, 0),
})

local right = New("ScrollingFrame", {
	Parent = visuals,
	Position = UDim2.new(0.5, 4, 0, 0),
	Size = UDim2.new(0.5, -4, 1, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 2,
	ScrollBarImageColor3 = Color3.fromRGB(92, 67, 98),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.fromOffset(0, 0),
})

AddList(left, 6)
AddList(right, 6)

do
	local sec, body = Section(left, "overlays", 205)

	AddToggle(body, 0, "esp enabled", false)
	AddSlider(body, 24, "esp scale multiplier", 0, 10, 0)

	AddToggle(body, 67, "grave icon for corpses", true)

	AddSubTitle(body, 94, "inclusions")

	AddToggle(body, 118, "include ai", false)
	AddToggle(body, 141, "include players", false)
	AddToggle(body, 164, "include corpses", false)
end

do
	local sec, body = Section(left, "bullet tracers", 255)

	AddToggle(body, 0, "tracers enabled", false)

	AddColorPicker(body, 25, "tracers color", Color3.fromRGB(255, 60, 70), function(color)
	end)

	AddSlider(body, 50, "tracers lifetime", 0, 5, 2)
	AddDropdown(body, 93, "tracers type", {"line", "beam", "laser"}, "line")
	AddDropdown(body, 136, "tracer origin", {"camera", "weapon", "character"}, "camera")

	AddSubTitle(body, 181, "enemy tracers")

	AddToggle(body, 205, "enemy tracers", false)
end

do
	local sec, body = Section(left, "viewmodel", 300)

	AddToggle(body, 0, "enabled", false)

	AddColorPicker(body, 25, "color", Color3.fromRGB(230, 230, 230))

	AddDropdown(body, 50, "material", {"plastic", "forcefield", "neon", "glass"}, "plastic")

	AddSlider(body, 93, "x offset", -10, 10, 0)
	AddSlider(body, 136, "y offset", -10, 10, 0)
	AddSlider(body, 179, "z offset", -10, 10, 0)

	AddKeybind(body, 225, "bind", nil, "Toggle", function(active, mode, key)
	end)
end

do
	local sec, body = Section(right, "crosshair", 470)

	AddToggle(body, 0, "enabled", false)

	AddColorPicker(body, 25, "color", Color3.fromRGB(255, 255, 255))

	AddSlider(body, 50, "spokes", 0, 10, 4)
	AddSlider(body, 93, "length", 0, 300, 20)
	AddSlider(body, 136, "gap", 0, 50, 5)
	AddSlider(body, 179, "width", 1, 20, 1)
	AddSlider(body, 222, "outline width", 0, 10, 1)
	AddSlider(body, 265, "spin speed", 0, 15, 0)

	AddDropdown(body, 308, "gap animation", {"none", "pulse", "dynamic"}, "none")

	AddKeybind(body, 352, "bind", nil, "Always On", function(active, mode, key)
	end)
end

do
	local sec, body = Section(right, "lighting", 290)

	AddToggle(body, 0, "brightness", false)
	AddSlider(body, 24, "brightness value", 0, 10, 3)

	AddToggle(body, 67, "time", false)
	AddSlider(body, 91, "time value", 0, 24, 12)

	AddToggle(body, 134, "fog density", false)
	AddSlider(body, 158, "fog density value", 0, 1, 0.35)

	AddColorPicker(body, 204, "ambient", Color3.fromRGB(90, 90, 100))
	AddColorPicker(body, 229, "outdoor ambient", Color3.fromRGB(90, 90, 100))
end

do
	local sec, body = Section(right, "camera", 220)

	AddToggle(body, 0, "zoom", false)
	AddSlider(body, 24, "zoom value", 20, 120, 20)

	AddFeatureRow(body, 67, "Fov", {
		Default = false,

		Callback = function(enabled)
		end,

		Color = {
			Default = Color3.fromRGB(255, 255, 255),
			Callback = function(color)
			end,
		},

		Slider = {
			Min = 30,
			Max = 120,
			Default = 90,
			Callback = function(value)
			end,
		},

		Bind = {
			Key = nil,
			Mode = "Hold",
			Callback = function(active, mode, key)
			end,
		},
	})
end


do
	local page = pages.combat

	local leftColumn = New("ScrollingFrame", {
		Parent = page,
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(92, 67, 98),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})

	local rightColumn = New("ScrollingFrame", {
		Parent = page,
		Position = UDim2.new(0.5, 4, 0, 0),
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(92, 67, 98),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})

	AddList(leftColumn, 6)
	AddList(rightColumn, 6)

	do
		local sec, body = Section(leftColumn, "aim", 315)

		AddToggle(body, 0, "enabled", false)
		AddSlider(body, 24, "fov", 0, 500, 120)
		AddSlider(body, 67, "smoothness", 0, 100, 25)
		AddDropdown(body, 110, "aim part", {"head", "upper torso", "lower torso"}, "head")
		AddDropdown(body, 153, "priority", {"distance", "fov", "health"}, "fov")
		AddColorPicker(body, 196, "fov color", Color3.fromRGB(178, 112, 187))
		AddKeybind(body, 225, "aim bind", Enum.KeyCode.F, "Hold")
	end

	do
		local sec, body = Section(leftColumn, "target", 220)

		AddToggle(body, 0, "visible check", true)
		AddToggle(body, 24, "team check", true)
		AddToggle(body, 48, "distance check", false)
		AddSlider(body, 76, "max distance", 100, 5000, 1500)
		AddDropdown(body, 119, "target mode", {"single", "closest", "cycle"}, "closest")
	end

	do
		local sec, body = Section(rightColumn, "weapon", 270)

		AddToggle(body, 0, "enabled", false)
		AddToggle(body, 24, "no spread", false)
		AddToggle(body, 48, "no recoil", false)
		AddSlider(body, 76, "fire rate", 1, 1000, 600)
		AddSlider(body, 119, "recoil scale", 0, 100, 0)
		AddDropdown(body, 162, "mode", {"default", "fast", "custom"}, "default")
		AddKeybind(body, 205, "weapon bind", Enum.KeyCode.T, "Toggle")
	end

	do
		local sec, body = Section(rightColumn, "hitbox", 220)

		AddToggle(body, 0, "enabled", false)
		AddSlider(body, 24, "size", 1, 20, 5)
		AddDropdown(body, 67, "part", {"head", "torso", "all"}, "head")
		AddColorPicker(body, 110, "color", Color3.fromRGB(255, 90, 110))
		AddKeybind(body, 139, "bind", Enum.KeyCode.H, "Toggle")
	end
end

do
	local page = pages.character

	local leftColumn = New("ScrollingFrame", {
		Parent = page,
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(92, 67, 98),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})

	local rightColumn = New("ScrollingFrame", {
		Parent = page,
		Position = UDim2.new(0.5, 4, 0, 0),
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(92, 67, 98),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})

	AddList(leftColumn, 6)
	AddList(rightColumn, 6)

	do
		local sec, body = Section(leftColumn, "speed", 205)

		AddToggle(body, 0, "enabled", false)
		AddSlider(body, 24, "speed", 1, 200, 25)
		AddDropdown(body, 67, "mode", {"walkspeed", "velocity", "cframe"}, "walkspeed")
		AddKeybind(body, 110, "speed bind", Enum.KeyCode.X, "Toggle")
	end

	do
		local sec, body = Section(leftColumn, "jump", 175)

		AddToggle(body, 0, "enabled", false)
		AddSlider(body, 24, "jump power", 1, 200, 50)
		AddKeybind(body, 67, "jump bind", Enum.KeyCode.Space, "Hold")
	end

	do
		local sec, body = Section(rightColumn, "fly", 220)

		AddToggle(body, 0, "enabled", false)
		AddSlider(body, 24, "fly speed", 1, 300, 50)
		AddDropdown(body, 67, "mode", {"camera", "character", "velocity"}, "camera")
		AddKeybind(body, 110, "fly bind", Enum.KeyCode.H, "Toggle")
	end

	do
		local sec, body = Section(rightColumn, "player", 195)

		AddToggle(body, 0, "noclip", false)
		AddToggle(body, 24, "auto jump", false)
		AddToggle(body, 48, "spin", false)
		AddSlider(body, 76, "spin speed", 0, 100, 20)
	end
end

do
	local page = pages.misc

	local leftColumn = New("ScrollingFrame", {
		Parent = page,
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(92, 67, 98),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})

	local rightColumn = New("ScrollingFrame", {
		Parent = page,
		Position = UDim2.new(0.5, 4, 0, 0),
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(92, 67, 98),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})

	AddList(leftColumn, 6)
	AddList(rightColumn, 6)

	do
		local sec, body = Section(leftColumn, "world", 280)

		AddToggle(body, 0, "fullbright", false)
		AddSlider(body, 24, "brightness", 0, 10, 3)
		AddToggle(body, 67, "clock time", false)
		AddSlider(body, 91, "time", 0, 24, 12)
		AddToggle(body, 134, "fog", false)
		AddSlider(body, 158, "fog density", 0, 1, 0.35)
		AddColorPicker(body, 201, "ambient", Color3.fromRGB(90, 90, 100))
		AddColorPicker(body, 230, "outdoor ambient", Color3.fromRGB(90, 90, 100))
	end

	do
		local sec, body = Section(leftColumn, "camera", 190)

		AddToggle(body, 0, "fov changer", false)
		AddSlider(body, 24, "fov", 30, 120, 70)
		AddToggle(body, 67, "zoom", false)
		AddKeybind(body, 95, "zoom bind", Enum.KeyCode.N, "Hold")
	end

	do
		local sec, body = Section(rightColumn, "crosshair", 300)

		AddToggle(body, 0, "enabled", false)
		AddColorPicker(body, 25, "color", Color3.fromRGB(255, 255, 255))
		AddSlider(body, 50, "gap", 0, 50, 5)
		AddSlider(body, 93, "length", 1, 100, 15)
		AddSlider(body, 136, "width", 1, 10, 2)
		AddSlider(body, 179, "spin speed", 0, 20, 0)
		AddDropdown(body, 222, "animation", {"none", "spin", "pulse"}, "none")
	end

	do
		local sec, body = Section(rightColumn, "misc", 170)

		AddToggle(body, 0, "notifications", true)
		AddDropdown(body, 24, "notification side", {"right", "left"}, "right")
		AddKeybind(body, 67, "menu bind", Enum.KeyCode.RightShift, "Toggle")
	end
end




do
	local page = pages.config

	local leftColumn = New("Frame", {
		Parent = page,
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	local rightColumn = New("Frame", {
		Parent = page,
		Position = UDim2.new(0.5, 4, 0, 0),
		Size = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	local sec, body = Section(leftColumn, "config", 205)

	local info = Label(
		body,
		"UI-v5  •  runtime",
		UDim2.new(1, 0, 0, 18),
		C.Muted
	)
	info.Position = UDim2.fromOffset(0, 0)

	local testNotifyButton = New("TextButton", {
		Parent = body,
		Position = UDim2.fromOffset(0, 31),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Color3.fromRGB(24, 21, 27),
		BorderSizePixel = 0,
		AutoButtonColor = false,

		Text = "Test Notify",
		TextColor3 = Color3.fromRGB(214, 191, 218),
		TextSize = 13,
		Font = FONT,
	})
	Stroke(testNotifyButton, Color3.fromRGB(83, 57, 89), 0.30)
	Corner(testNotifyButton, 4)

	local unloadButton = New("TextButton", {
		Parent = body,
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = Color3.fromRGB(34, 17, 20),
		BorderSizePixel = 0,
		AutoButtonColor = false,

		Text = "Unload",
		TextColor3 = Color3.fromRGB(225, 110, 120),
		TextSize = 13,
		Font = FONT,
	})
	Stroke(unloadButton, Color3.fromRGB(105, 48, 55), 0.35)
	Corner(unloadButton, 4)

	local hint = Label(
		body,
		"RightShift: menu  •  Test Notify: preview",
		UDim2.new(1, 0, 0, 18),
		C.Dim
	)
	hint.Position = UDim2.fromOffset(0, 103)
	hint.TextSize = 11

	local configSec, configBody = Section(rightColumn, "configs", 355)

	local nameLabel = Label(
		configBody,
		"config name",
		UDim2.new(1, 0, 0, 16),
		C.Muted
	)
	nameLabel.Position = UDim2.fromOffset(0, 0)
	nameLabel.TextSize = 12

	local configNameBox = New("TextBox", {
		Parent = configBody,
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 0, 27),

		BackgroundColor3 = Color3.fromRGB(13, 13, 15),
		BorderSizePixel = 0,

		ClearTextOnFocus = false,
		Text = "default",
		PlaceholderText = "config name",
		PlaceholderColor3 = C.Dim,

		TextColor3 = C.Text,
		TextSize = 12,
		Font = FONT,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local nameStroke = Stroke(configNameBox, C.BorderSoft, 0.48)
	Corner(configNameBox, 3)

	New("UIPadding", {
		Parent = configNameBox,
		PaddingLeft = UDim.new(0, 7),
		PaddingRight = UDim.new(0, 7),
	})

	local createButton = New("TextButton", {
		Parent = configBody,
		Position = UDim2.fromOffset(0, 51),
		Size = UDim2.new(1, 0, 0, 24),

		BackgroundColor3 = Color3.fromRGB(27, 22, 30),
		BorderSizePixel = 0,
		AutoButtonColor = false,

		Text = "Create",
		TextColor3 = Color3.fromRGB(218, 190, 223),
		TextSize = 12,
		Font = FONT,
	})
	local createStroke = Stroke(
		createButton,
		Color3.fromRGB(91, 59, 98),
		0.26
	)
	Corner(createButton, 3)

	local selectedLabel = Label(
		configBody,
		"saved configs",
		UDim2.new(1, 0, 0, 16),
		C.Muted
	)
	selectedLabel.Position = UDim2.fromOffset(0, 81)
	selectedLabel.TextSize = 12

	local configList = New("ScrollingFrame", {
		Parent = configBody,
		Position = UDim2.fromOffset(0, 100),
		Size = UDim2.new(1, 0, 0, 66),

		BackgroundColor3 = Color3.fromRGB(13, 13, 15),
		BorderSizePixel = 0,

		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Color3.fromRGB(105, 67, 113),

		ZIndex = 20,
	})
	Stroke(configList, C.BorderSoft, 0.50)
	Corner(configList, 3)

	local listPadding = New("UIPadding", {
		Parent = configList,
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
	})

	local listLayout = New("UIListLayout", {
		Parent = configList,
		FillDirection = Enum.FillDirection.Vertical,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
	})

	local statusLabel = Label(
		configBody,
		"ready",
		UDim2.new(1, 0, 0, 16),
		C.Dim
	)
	statusLabel.Position = UDim2.fromOffset(0, 290)
	statusLabel.TextSize = 11

	local selectedConfig = nil
	local configButtons = {}

	local function SetStatus(text, good)
		statusLabel.Text = tostring(text or "")

		Tween(statusLabel, {
			TextColor3 = good == nil
				and C.Dim
				or (
					good
					and Color3.fromRGB(192, 145, 201)
					or Color3.fromRGB(220, 112, 122)
				),
		}, 0.10)
	end

	local function MakeActionButton(text, xScale, xOffset, y, widthScale, widthOffset, accent)
		local button = New("TextButton", {
			Parent = configBody,
			Position = UDim2.new(xScale, xOffset, 0, y),
			Size = UDim2.new(widthScale, widthOffset, 0, 24),

			BackgroundColor3 = accent
				and Color3.fromRGB(27, 22, 30)
				or Color3.fromRGB(18, 18, 20),

			BorderSizePixel = 0,
			AutoButtonColor = false,

			Text = text,
			TextColor3 = accent
				and Color3.fromRGB(218, 190, 223)
				or C.Text,

			TextSize = 12,
			Font = FONT,
		})

		local stroke = Stroke(
			button,
			accent
				and Color3.fromRGB(91, 59, 98)
				or C.BorderSoft,
			accent and 0.26 or 0.48
		)
		Corner(button, 3)

		Track(button.MouseEnter:Connect(function()
			Tween(button, {
				BackgroundColor3 = accent
					and Color3.fromRGB(35, 27, 38)
					or Color3.fromRGB(24, 24, 27),
			}, MOTION.Fast)

			Tween(stroke, {
				Transparency = accent and 0.12 or 0.30,
			}, MOTION.Fast)
		end))

		Track(button.MouseLeave:Connect(function()
			Tween(button, {
				BackgroundColor3 = accent
					and Color3.fromRGB(27, 22, 30)
					or Color3.fromRGB(18, 18, 20),
			}, MOTION.Hover)

			Tween(stroke, {
				Transparency = accent and 0.26 or 0.48,
			}, MOTION.Hover)
		end))

		return button
	end

	local saveButton = MakeActionButton(
		"Save",
		0,
		0,
		172,
		0.5,
		-3,
		true
	)

	local loadButton = MakeActionButton(
		"Load",
		0.5,
		3,
		172,
		0.5,
		-3,
		false
	)

	local deleteButton = MakeActionButton(
		"Delete",
		0,
		0,
		201,
		0.5,
		-3,
		false
	)

	local refreshButton = MakeActionButton(
		"Refresh",
		0.5,
		3,
		201,
		0.5,
		-3,
		false
	)

	local autoloadButton = MakeActionButton(
		"Set As Autoload",
		0,
		0,
		230,
		1,
		0,
		true
	)

	local clearAutoloadButton = MakeActionButton(
		"Clear Autoload",
		0,
		0,
		259,
		1,
		0,
		false
	)

	local function RefreshSelectionVisuals()
		for name, button in pairs(configButtons) do
			local selected = name == selectedConfig

			Tween(button, {
				BackgroundColor3 = selected
					and Color3.fromRGB(30, 23, 33)
					or Color3.fromRGB(16, 16, 18),

				TextColor3 = selected
					and Color3.fromRGB(220, 181, 227)
					or C.Text,
			}, 0.10)
		end
	end

	local function ClearConfigRows()
		for _, child in ipairs(configList:GetChildren()) do
			if child:IsA("TextButton")
				or child.Name == "EmptyConfigLabel" then

				child:Destroy()
			end
		end

		table.clear(configButtons)
	end

	local function RefreshConfigList()
		ClearConfigRows()

		local configs = Library:GetConfigs()

		if #configs == 0 then
			selectedConfig = nil

			local empty = Label(
				configList,
				"no saved configs",
				UDim2.new(1, -2, 0, 24),
				C.Dim,
				Enum.TextXAlignment.Center
			)
			empty.Name = "EmptyConfigLabel"
			empty.TextSize = 11
			empty.LayoutOrder = 1

			SetStatus("no configs", nil)
			return
		end

		if selectedConfig and not table.find(configs, selectedConfig) then
			selectedConfig = nil
		end

		local autoloadName = Library:GetAutoload()

		for index, name in ipairs(configs) do
			local button = New("TextButton", {
				Name = "Config_" .. name,
				Parent = configList,
				Size = UDim2.new(1, -2, 0, 24),

				BackgroundColor3 = Color3.fromRGB(16, 16, 18),
				BorderSizePixel = 0,
				AutoButtonColor = false,

				Text = "  " .. name,
				TextColor3 = C.Text,
				TextSize = 12,
				Font = FONT,
				TextXAlignment = Enum.TextXAlignment.Left,

				LayoutOrder = index,
				ZIndex = 21,
			})
			Corner(button, 2)

			local indicator = New("Frame", {
				Parent = button,
				Position = UDim2.fromOffset(0, 4),
				Size = UDim2.fromOffset(2, 16),
				BackgroundColor3 = C.Accent,
				BackgroundTransparency = 0.25,
				BorderSizePixel = 0,
				ZIndex = 22,
			})

			if name == autoloadName then
				local autoTag = Label(
					button,
					"AUTO",
					UDim2.fromOffset(40, 24),
					Color3.fromRGB(197, 139, 207),
					Enum.TextXAlignment.Center
				)
				autoTag.AnchorPoint = Vector2.new(1, 0)
				autoTag.Position = UDim2.new(1, -4, 0, 0)
				autoTag.TextSize = 10
				autoTag.ZIndex = 23
			end

			configButtons[name] = button

			Track(button.MouseEnter:Connect(function()
				if selectedConfig ~= name then
					Tween(button, {
						BackgroundColor3 = Color3.fromRGB(22, 21, 24),
					}, MOTION.Fast)
				end
			end))

			Track(button.MouseLeave:Connect(function()
				if selectedConfig ~= name then
					Tween(button, {
						BackgroundColor3 = Color3.fromRGB(16, 16, 18),
					}, MOTION.Hover)
				end
			end))

			Track(button.MouseButton1Click:Connect(function()
				selectedConfig = name
				configNameBox.Text = name
				RefreshSelectionVisuals()
				SetStatus("selected: " .. name, nil)
			end))
		end

		RefreshSelectionVisuals()
		SetStatus(tostring(#configs) .. " config(s)", nil)
	end

	Track(configNameBox.Focused:Connect(function()
		Tween(nameStroke, {
			Color = C.AccentDark,
			Transparency = 0.18,
		}, MOTION.Fast)
	end))

	Track(configNameBox.FocusLost:Connect(function()
		Tween(nameStroke, {
			Color = C.BorderSoft,
			Transparency = 0.48,
		}, MOTION.Hover)
	end))

	Track(createButton.MouseEnter:Connect(function()
		Tween(createButton, {
			BackgroundColor3 = Color3.fromRGB(35, 27, 38),
		}, MOTION.Fast)

		Tween(createStroke, {
			Transparency = 0.12,
		}, MOTION.Fast)
	end))

	Track(createButton.MouseLeave:Connect(function()
		Tween(createButton, {
			BackgroundColor3 = Color3.fromRGB(27, 22, 30),
		}, MOTION.Hover)

		Tween(createStroke, {
			Transparency = 0.26,
		}, MOTION.Hover)
	end))

	Track(createButton.MouseButton1Click:Connect(function()
		local requested = configNameBox.Text
		local ok, result = Library:CreateConfig(requested)

		if ok then
			selectedConfig = result
			configNameBox.Text = result
			RefreshConfigList()
			selectedConfig = result
			RefreshSelectionVisuals()
			SetStatus("created: " .. result, true)

			Library:Notify({
				Title = "Config",
				Text = "created " .. result,
				Duration = 2.2,
			})
		else
			SetStatus(result, false)
		end
	end))

	Track(saveButton.MouseButton1Click:Connect(function()
		local requested = configNameBox.Text
		local ok, result = Library:SaveConfig(requested)

		if ok then
			selectedConfig = result
			configNameBox.Text = result
			RefreshConfigList()
			selectedConfig = result
			RefreshSelectionVisuals()
			SetStatus("saved: " .. result, true)

			Library:Notify({
				Title = "Config",
				Text = "saved " .. result,
				Duration = 2.2,
			})
		else
			SetStatus(result, false)
		end
	end))

	Track(loadButton.MouseButton1Click:Connect(function()
		local requested =
			selectedConfig
			or NormalizeConfigName(configNameBox.Text)

		local ok, result = Library:LoadConfig(requested)

		if ok then
			selectedConfig = result
			configNameBox.Text = result
			RefreshSelectionVisuals()
			SetStatus("loaded: " .. result, true)

			Library:Notify({
				Title = "Config",
				Text = "loaded " .. result,
				Duration = 2.2,
			})
		else
			SetStatus(result, false)
		end
	end))

	Track(deleteButton.MouseButton1Click:Connect(function()
		local requested =
			selectedConfig
			or NormalizeConfigName(configNameBox.Text)

		local ok, result = Library:DeleteConfig(requested)

		if ok then
			if Library:GetAutoload() == result then
				Library:ClearAutoload()
			end

			selectedConfig = nil
			RefreshConfigList()
			SetStatus("deleted: " .. result, true)

			Library:Notify({
				Title = "Config",
				Text = "deleted " .. result,
				Duration = 2.2,
			})
		else
			SetStatus(result, false)
		end
	end))

	Track(refreshButton.MouseButton1Click:Connect(function()
		RefreshConfigList()
	end))

	Track(autoloadButton.MouseButton1Click:Connect(function()
		local requested =
			selectedConfig
			or NormalizeConfigName(configNameBox.Text)

		local ok, result = Library:SetAutoload(requested)

		if ok then
			selectedConfig = result
			configNameBox.Text = result
			RefreshConfigList()
			selectedConfig = result
			RefreshSelectionVisuals()
			SetStatus("autoload: " .. result, true)

			Library:Notify({
				Title = "Autoload",
				Text = "set " .. result,
				Duration = 2.2,
			})
		else
			SetStatus(result, false)
		end
	end))

	Track(clearAutoloadButton.MouseButton1Click:Connect(function()
		local ok, result = Library:ClearAutoload()

		if ok then
			RefreshConfigList()
			SetStatus(result, true)

			Library:Notify({
				Title = "Autoload",
				Text = "cleared",
				Duration = 2.2,
			})
		else
			SetStatus(result, false)
		end
	end))

	Track(testNotifyButton.MouseEnter:Connect(function()
		Tween(testNotifyButton, {
			BackgroundColor3 = Color3.fromRGB(31, 25, 34),
			TextColor3 = Color3.fromRGB(228, 205, 232),
		}, 0.10)
	end))

	Track(testNotifyButton.MouseLeave:Connect(function()
		Tween(testNotifyButton, {
			BackgroundColor3 = Color3.fromRGB(24, 21, 27),
			TextColor3 = Color3.fromRGB(214, 191, 218),
		}, 0.10)
	end))

	Track(testNotifyButton.MouseButton1Click:Connect(function()
		Library:Notify({
			Title = "Test Log",
			Text = "test log test log test log 123 123 123",
			Duration = 4,
		})
	end))

	Track(unloadButton.MouseEnter:Connect(function()
		Tween(unloadButton, {
			BackgroundColor3 = Color3.fromRGB(44, 20, 24),
			TextColor3 = Color3.fromRGB(240, 130, 138),
		}, 0.10)
	end))

	Track(unloadButton.MouseLeave:Connect(function()
		Tween(unloadButton, {
			BackgroundColor3 = Color3.fromRGB(34, 17, 20),
			TextColor3 = Color3.fromRGB(225, 110, 120),
		}, 0.10)
	end))

	Track(unloadButton.MouseButton1Click:Connect(function()
		if unloaded then
			return
		end

		unloaded = true

		if activeColorPickerClose then
			activeColorPickerClose()
		end

		if activeKeybindClose then
			activeKeybindClose()
		end

		if activeDropdownClose then
			activeDropdownClose()
		end

		local fadeTween = TweenService:Create(
			main,
			TweenInfo.new(
				0.16,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.In
			),
			{GroupTransparency = 1}
		)

		local unloadPosition = main.Position

		local moveTween = TweenService:Create(
			main,
			TweenInfo.new(
				0.16,
				Enum.EasingStyle.Quart,
				Enum.EasingDirection.In
			),
			{
				Position = UDim2.new(
					unloadPosition.X.Scale,
					unloadPosition.X.Offset,
					unloadPosition.Y.Scale,
					unloadPosition.Y.Offset + 7
				)
			}
		)

		fadeTween:Play()
		moveTween:Play()

		task.delay(0.17, function()
			DisconnectAll()

			if gui and gui.Parent then
				gui:Destroy()
			end

			if RuntimeEnvironment.__UI_V5_RUNTIME == Library then
				RuntimeEnvironment.__UI_V5_RUNTIME = nil
			end
		end)
	end))

	RefreshConfigList()

	task.defer(function()
		if unloaded then
			return
		end

		local autoloadName = Library:GetAutoload()

		if not autoloadName or autoloadName == "" then
			return
		end

		local ok, result = Library:LoadConfig(autoloadName)

		if ok then
			selectedConfig = result
			configNameBox.Text = result
			RefreshConfigList()
			selectedConfig = result
			RefreshSelectionVisuals()
			SetStatus("autoloaded: " .. result, true)

			Library:Notify({
				Title = "Autoload",
				Text = "loaded " .. result,
				Duration = 2.2,
			})
		else
			SetStatus("autoload failed", false)
		end
	end)
end

local dragging = false
local dragStart
local startPosition

local resizing = false
local resizeStart = nil
local resizeStartSize = nil
local resizeTopLeft = nil

local MIN_MAIN_WIDTH =
	(#tabs * tabWidth)
	+ ((#tabs - 1) * tabGap)
	+ 14

local MIN_MAIN_HEIGHT = 300

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

local resizeGripLines = {}

for i = 0, 2 do
	local line = New("Frame", {
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

	table.insert(resizeGripLines, line)
end

local function SetResizeGripActive(active)
	for _, line in ipairs(resizeGripLines) do
		Tween(line, {
			BackgroundColor3 = active
				and Color3.fromRGB(210, 148, 220)
				or Color3.fromRGB(92, 92, 99),

			BackgroundTransparency = active and 0.02 or 0.22,
		}, MOTION.Fast)
	end
end

Track(resizeHandle.MouseEnter:Connect(function()
	if not resizing then
		SetResizeGripActive(true)
	end
end))

Track(resizeHandle.MouseLeave:Connect(function()
	if not resizing then
		SetResizeGripActive(false)
	end
end))

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

		Tween(top, {
			BackgroundColor3 = Color3.fromRGB(15, 13, 16),
		}, MOTION.Fast)

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

		SetResizeGripActive(true)

		Tween(outerOutline, {
			Color = C.AccentDark,
			Transparency = 0.02,
		}, MOTION.Fast)
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

		local width = math.max(
			MIN_MAIN_WIDTH,
			resizeStartSize.X + delta.X
		)

		local height = math.max(
			MIN_MAIN_HEIGHT,
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

			Tween(top, {
				BackgroundColor3 = C.Top,
			}, MOTION.Hover)

			Tween(outerOutline, {
				Color = Color3.fromRGB(72, 72, 78),
				Transparency = 0.12,
			}, MOTION.Hover)
		end

		if resizing then
			resizing = false

			SetResizeGripActive(false)

			Tween(outerOutline, {
				Color = Color3.fromRGB(72, 72, 78),
				Transparency = 0.12,
			}, MOTION.Hover)
		end
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
				0.20,
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
				0.22,
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
		if activeColorPickerClose then
			activeColorPickerClose()
		end

		if activeKeybindClose then
			activeKeybindClose()
		end

		if activeDropdownClose then
			activeDropdownClose()
		end

		restingPosition = main.Position

		visibilityTween = TweenService:Create(
			main,
			TweenInfo.new(
				0.17,
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
				0.17,
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

restingPosition = main.Position
main.Visible = true
main.GroupTransparency = 1
main.Position = OffsetPosition(restingPosition, 6)

TweenService:Create(
	main,
	TweenInfo.new(
		0.22,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	),
	{
		GroupTransparency = 0,
		Position = restingPosition,
	}
):Play()

SetTab("combat")

return Library
