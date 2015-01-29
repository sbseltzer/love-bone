
local SHARED = require("boner.shared");

--[[
	
--]]
local MAttachment = SHARED.Meta.Attachment;
MAttachment.__index = MAttachment;
local function newAttachment(visual)
	local t = setmetatable({}, MAttachment);
	t:SetVisual(visual);
	--t.Origin = {0,0};
	t.Rotation = 0;
	t.Translation = {0,0};
	t.Scale = {1,1};
	t.LayerOffset = 0;
	t.Color = {255, 255, 255, 255};
	return t;
end

function MAttachment:SetVisual(vis)
	self.Visual = vis;
end
function MAttachment:GetVisual()
	return self.Visual;
end

function MAttachment:SetColor(...)
	self.Color = {...};
	for i = 1, 4 do
		self.Color[i] = tonumber(self.Color[i]) or 255;
	end
end
function MAttachment:GetColor()
	return unpack(self.Color);
end

function MAttachment:SetLayerOffset(layer)
	self.LayerOffset = layer;
end
function MAttachment:GetLayerOffset()
	return self.LayerOffset;
end
--[[
function MAttachment:SetOrigin(x, y)
	self.Origin = {x, y};
end
function MAttachment:GetOrigin()
	return unpack(self.Origin);
end
]]
function MAttachment:SetRotation(angle)
	self.Rotation = angle;
end
function MAttachment:GetRotation()
	return self.Rotation;
end

function MAttachment:SetTranslation(x, y)
	self.Translation = {x, y};
end
function MAttachment:GetTranslation()
	return unpack(self.Translation);
end

function MAttachment:SetScale(x, y)
	self.Scale = {x, y};
end
function MAttachment:GetScale()
	return unpack(self.Scale);
end

return newAttachment;