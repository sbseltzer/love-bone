--[[
	Attachment
	An oriented visual representation of a bone on an actor.
--]]

local util = RequireLibPart("util");

local MAttachment = util.Meta.Attachment;
MAttachment.__index = MAttachment;
local function newAttachment(visual)
	local t = setmetatable({}, MAttachment);
	if (visual) then
		t:SetVisual(visual);
	end
	--t.Origin = {0,0};
	t:SetRotation(0);
	t:SetTranslation(0, 0);
	t:SetScale(1, 1);
	t:SetLayerOffset(0);
	t:SetColor(255, 255, 255, 255);
	return t;
end

function MAttachment:SetVisual(vis)
	if (not vis or not util.isType(vis, "Visual")) then
		error(util.errorArgs("BadMeta", 1, "SetVisual", "Visual", tostring(util.Meta.Visual), tostring(getmetatable(vis))));
	end
	self.Visual = vis;
end
function MAttachment:GetVisual()
	return self.Visual;
end

function MAttachment:SetColor(...)
	self.Color = self.Color or {};
	local color = {...};
	color[4] = color[4] or 255;
	for i = 1, 4 do
		if (not tonumber(color[i])) then
			error(util.errorArgs("BadArg", i, "SetColor", "number", type(color[i])));
		end
		self.Color[i] = tonumber(color[i]);
	end
end
function MAttachment:GetColor()
	return unpack(self.Color);
end

function MAttachment:SetLayerOffset(layer)
	if (not layer or not tonumber(layer)) then
		error(util.errorArgs("BadArg", 1, "SetLayerOffset", "number", type(layer)));
	end
	self.LayerOffset = tonumber(layer);
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
	if (not angle or not tonumber(angle)) then
		error(util.errorArgs("BadArg", 1, "SetRotation", "number", type(angle)));
	end
	self.Rotation = tonumber(angle);
end
function MAttachment:GetRotation()
	return self.Rotation;
end

function MAttachment:SetTranslation(x, y)
	if (not x or not tonumber(x)) then
		error(util.errorArgs("BadArg", 1, "SetTranslation", "number", type(x)));
	elseif (not y or not tonumber(y)) then
		error(util.errorArgs("BadArg", 2, "SetTranslation", "number", type(y)));
	end
	self.Translation = {tonumber(x), tonumber(y)};
end
function MAttachment:GetTranslation()
	return unpack(self.Translation);
end

function MAttachment:SetScale(x, y)
	if (not x or not tonumber(x)) then
		error(util.errorArgs("BadArg", 1, "SetScale", "number", type(x)));
	elseif (not y or not tonumber(y)) then
		error(util.errorArgs("BadArg", 2, "SetScale", "number", type(y)));
	end
	self.Scale = {tonumber(x), tonumber(y)};
end
function MAttachment:GetScale()
	return unpack(self.Scale);
end

return newAttachment;