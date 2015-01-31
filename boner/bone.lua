
local SHARED = require("boner.shared");

--[[
	Bone
	Bones define bone hierarchies, the shape of a skeleton, the skeleton bind-pose, and bone rendering order.
	These are at the very bottom of the data structure chain.
--]]
local MBone = SHARED.Meta.Bone;
MBone.__index = MBone;
local function newBone(name, parent, layer, offset, defaultRotation, defaultTranslation, defaultScale)
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
	bone:SetName(name);
	bone:SetParent(parent);
	bone:SetLayer(layer);
	bone:SetOffset(unpack(offset));
	bone:SetDefaultRotation(defaultRotation);
	bone:SetDefaultTranslation(unpack(defaultTranslation));
	bone:SetDefaultScale(unpack(defaultScale));
	return bone;
end

-- Unique Bone reference name
function MBone:SetName(name)
	self.Name = name;
end
function MBone:GetName()
	return self.Name;
end

-- Represents draw order for bones in the same skeleton
function MBone:SetLayer(i)
	self.Layer = i;
end
function MBone:GetLayer()
	return self.Layer;
end

-- Parent bone name
function MBone:SetParent(boneName)
	self.Parent = boneName;
end
function MBone:GetParent()
	return self.Parent;
end

-- Position of this bone's origin relative to its parents origin.
function MBone:SetOffset(offsetX, offsetY)
	self.Offset = {offsetX, offsetY};
end
function MBone:GetOffset()
	return unpack(self.Offset);
end

-- Default local rotation
function MBone:SetDefaultRotation(angle)
	self.Rotation = angle;
end
function MBone:GetDefaultRotation()
	return self.Rotation;
end

-- Default local translation
function MBone:SetDefaultTranslation(transX, transY)
	self.Translation = {transX, transY};
end
function MBone:GetDefaultTranslation()
	return unpack(self.Translation);
end

-- Default local scaling
function MBone:SetDefaultScale(scaleX, scaleY)
	self.Scale = {scaleX, scaleY};
end
function MBone:GetDefaultScale()
	return unpack(self.Scale);
end

return newBone;