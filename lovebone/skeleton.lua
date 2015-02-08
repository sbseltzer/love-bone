--[[
	Skeleton
	A simple containment data structure for bones, animations, and skins.
	Actors hold a reference to a skeleton, which defines what animations and skins it can use.
--]]

local util = RequireLibPart("util");
local newBone = RequireLibPart("bone");
local SKELETON_ROOT_NAME = util.SKELETON_ROOT_NAME;

local MSkeleton = util.Meta.Skeleton;
MSkeleton.__index = MSkeleton;
local function newSkeleton()
	local skeleton = setmetatable({}, MSkeleton);
	skeleton.BoneNames = {};
	skeleton.Bones = {};
	skeleton.Bones[SKELETON_ROOT_NAME] = newBone();
	skeleton.RenderOrder = {};
	skeleton.Valid = true;
	return skeleton;
end

function MSkeleton:IsValid()
	return self.Valid;
end

-- Checks all bones to see if parents are valid, and populates children lists.
function MSkeleton:Validate()
	self.Valid = true;
	for boneName, bone in pairs(self.Bones) do
		local parentName = bone:GetParent();
		if (parentName) then
			if (not self.Bones[parentName]) then
				print("Validation failed: Could not find parent '" .. parentName .. "' for bone '" .. boneName .. "'");
				self.Valid = false;
				break;
			else
				if (parentName == boneName) then
					print("Validation failed: Bone '" .. parentName .. "' cannot be its own parent");
					self.Valid = false;
					break;
				end
				local parent = self.Bones[parentName];
				parent.Children = parent.Children or {};
				print("Adding child",boneName,"to",parentName);
				table.insert(parent.Children, boneName);
			end
		elseif (boneName ~= SKELETON_ROOT_NAME) then
			print("Validation failed: No parent found for bone '" .. boneName .. "'");
			self.Valid = false;
			break;
		end
	end
	if (self.Valid) then
		self:BuildRenderOrder();
	end
	return self.Valid;
end

-- Adds a bone to the skeleton.
function MSkeleton:SetBone(boneName, boneObj)
	if (not boneName or type(boneName) ~= "string") then
		error(util.errorArgs("BadArg", 1, "SetBone", "string", type(boneName)));
	elseif (not boneObj or not util.isType(boneObj, "Bone")) then
		error(util.errorArgs("BadMeta", 2, "SetBone", "Bone", tostring(util.Meta.Bone), tostring(getmetatable(boneObj))));
	end
	if (not boneObj:GetParent() and boneName ~= SKELETON_ROOT_NAME) then
		boneObj:SetParent(SKELETON_ROOT_NAME);
	end
	self.Bones[boneName] = boneObj;
	self.Valid = false;
end

-- Rebuilds the rendering order of bones based on their current layer.
function MSkeleton:BuildRenderOrder()
	if (not self:IsValid()) then
		print("Warning: Could not build render order for invalid skeleton!");
		return;
	end
	self.RenderOrder = {};
	for boneName, bone in pairs(self.Bones) do
		local i = 1;
		for _, v in pairs(self.RenderOrder) do
			if (self.Bones[v]:GetLayer() <= bone:GetLayer()) then
				i = i + 1;
			end
		end
		table.insert(self.RenderOrder, i, boneName);
	end
end

-- Get a bone object.
function MSkeleton:GetBone(boneName)
	return self.Bones[boneName];
end

-- Returns a list of bones that belong to the skeleton, starting from the optional rootName.
function MSkeleton:GetBoneList(rootName, t)
	if (not self:IsValid()) then
		print("Warning: Could not get bone tree for invalid skeleton!");
		return;
	end
	rootName = rootName or SKELETON_ROOT_NAME;
	t = t or {};
	table.insert(t, rootName);
	local children = self:GetBone(rootName).Children;
	if (not children or #children == 0) then
		return t;
	end
	for i = 1, #children do
		self:GetBoneList(children[i], t);
	end
	return t;
end

-- Returns the skeleton bind pose.
function MSkeleton:GetBindPose()
	if (not self:IsValid()) then
		print("Warning: Could not get bind pose for invalid skeleton!");
		return;
	end
	-- TODO: Validate?
	-- TODO: Cache this?
	local pose = {};
	for boneName, bone in pairs(self.Bones) do
		local keyframe = {};
		keyframe.time = 0;
		keyframe.rotation = bone:GetDefaultRotation();
		keyframe.translation = {bone:GetDefaultTranslation()};
		keyframe.scale = {bone:GetDefaultScale()};
		--print("BindPos:".. boneName ..":",keyframe.time, keyframe.rotation, "[" .. keyframe.translation[1] .. "," .. keyframe.translation[2] .. "]");
		pose[boneName] = keyframe;
	end
	return pose;
end

return newSkeleton;