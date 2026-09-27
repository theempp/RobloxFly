local Shared = game:GetService("ReplicatedStorage").Shared
local P = require(Shared.Palette)
local TweenService = game:GetService("TweenService")
local Design = { P = P }
function Design.make(class, props, parent)
	local object = Instance.new(class)
	for key, value in props do object[key] = value end
	object.Parent = parent; return object
end
function Design.corner(parent, size) Design.make("UICorner", { CornerRadius = UDim.new(0, size or 12) }, parent) end
function Design.padding(parent, amount)
	Design.make("UIPadding", { PaddingTop = UDim.new(0, amount), PaddingBottom = UDim.new(0, amount), PaddingLeft = UDim.new(0, amount), PaddingRight = UDim.new(0, amount) }, parent)
end
function Design.stack(parent, gap)
	return Design.make("UIListLayout", { Padding = UDim.new(0, gap or 12), SortOrder = Enum.SortOrder.LayoutOrder }, parent)
end
function Design.text(parent, text, size, color, height, font)
	return Design.make("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or size + 8),
		Text = text, TextSize = size, Font = font or Enum.Font.GothamMedium, TextColor3 = color or P.Porcelain,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }, parent)
end
function Design.card(parent)
	local f = Design.make("Frame", { BackgroundColor3 = Color3.fromRGB(31, 46, 54), BorderSizePixel = 0,
		Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, parent)
	Design.corner(f, 12); Design.padding(f, 16); Design.stack(f, 8)
	return f
end
function Design.button(parent, title, callback, primary, enabled)
	local active = enabled ~= false
	local b = Design.make("TextButton", { Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = if primary then P.Champagne else Color3.fromRGB(44, 61, 70),
		Text = title, TextSize = 15, Font = Enum.Font.GothamMedium, TextColor3 = if primary then P.Graphite else P.Porcelain,
		AutoButtonColor = false, BorderSizePixel = 0, Selectable = active, Active = active, TextTransparency = if active then 0 else 0.45 }, parent)
	Design.corner(b, 8)
	if active then
		b.Activated:Connect(callback)
		b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0.15 }):Play() end)
		b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), { BackgroundTransparency = 0 }):Play() end)
	end
	return b
end
function Design.rule(parent)
	return Design.make("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = P.Champagne, BackgroundTransparency = 0.7, BorderSizePixel = 0 }, parent)
end
function Design.clear(parent)
	for _, child in parent:GetChildren() do if child:IsA("GuiObject") then child:Destroy() end end
end
return Design
