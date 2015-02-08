--[[
	Bone
	Defines bone hierarchies, the shape of a skeleton, the skeleton bind-pose, and bone rendering order.
	These are at the very bottom of the data structure chain.
--]]

local util = RequireLibPart("util");

local MBone = util.Meta.Bone;
MBone.__index = MBone;
local function newBone(parent, layer, offset, defaultRotation, defaultTranslation, defaultScale)
	layer = layer or 0;
	
	offset = offset or {0, 0};
	offset[1] = tonumber(offset[1]) or 0;
	offset[2] = tonumber(offset[2]) or 0;
	
	defaultRotation = defaultRotation or 0;
	
	defaultTranslation = defaultTranslation or {0, 0};
	defaultTranslation[1] = tonumber(defaultTranslation[1]) or 0;
	defaultTranslation[2] = tonumber(defaultTranslation[2]) or 0;
	
	defaultScale = defaultScale or {1, 1};
	defaultScale[1] = tonumber(defaultScale[1]) or 1;
	defaultScale[2] = tonumber(defaultScale[2]) or 1;
	
	local bone = setmetatable({}, MBone);
	bone:SetParent(parent);
	bone:SetLayer(layer);
	bone:SetOffset(unpack(offset));
	bone:SetDefaultRotation(defaultRotation);
	bone:SetDefaultTranslation(unpack(defaultTranslation));
	bone:SetDefaultScale(unpack(defaultScale));
	return bone;
end

-- Represents draw order for bones in the same skeleton
function MBone:SetLayer(layer)
	if (not layer or not tonumber(layer)) then
		error(util.errorArgs("BadArg", 1, "SetLayer", "number", type(layer)));
	end
	self.Layer = tonumber(layer);
end
function MBone:GetLayer()
	return self.Layer;
end

-- Parent bone name
function MBone:SetParent(boneName)
	if (boneName and type(boneName) ~= "string") then
		error(util.errorArgs("BadArg", 1, "SetParent", "string", type(boneName)));
	end
	self.Parent = boneName;
end
function MBone:GetParent()
	return self.Parent;
end

-- Position of this bone's origin relative to its parents origin.
function MBone:SetOffset(x, y)
	if (not x or not tonumber(x)) then
		error(util.errorArgs("BadArg", 1, "SetOffset", "number", type(x)));
	elseif (not y or not tonumber(y)) then
		error(util.errorArgs("BadArg", 2, "SetOffset", "number", type(y)));
	end
	self.Offset = {tonumber(x), tonumber(y)};
end
function MBone:GetOffset()
	return unpack(self.Offset);
end

-- Default local rotation
function MBone:SetDefaultRotation(angle)
	if (not angle or not tonumber(angle)) then
		error(util.errorArgs("BadArg", 1, "SetDefaultRotation", "number", type(angle)));
	end
	self.Rotation = angle;
end
function MBone:GetDefaultRotation()
	return self.Rotation;
end

-- Default local translation
function MBone:SetDefaultTranslation(x, y)
	if (not x or not tonumber(x)) then
		error(util.errorArgs("BadArg", 1, "SetDefaultTranslation", "number", type(x)));
	elseif (not y or not tonumber(y)) then
		error(util.errorArgs("BadArg", 2, "SetDefaultTranslation", "number", type(y)));
	end
	self.Translation = {tonumber(x), tonumber(y)};
end
function MBone:GetDefaultTranslation()
	return unpack(self.Translation);
end

-- Default local scaling
function MBone:SetDefaultScale(x, y)
	if (not x or not tonumber(x)) then
		error(util.errorArgs("BadArg", 1, "SetDefaultScale", "number", type(x)));
	elseif (not y or not tonumber(y)) then
		error(util.errorArgs("BadArg", 2, "SetDefaultScale", "number", type(y)));
	end
	self.Scale = {tonumber(x), tonumber(y)};
end
function MBone:GetDefaultScale()
	return unpack(self.Scale);
end

return newBone;