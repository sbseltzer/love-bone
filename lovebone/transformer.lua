--[[
	Transformer
	This is what makes the actor move.
	To make the actor do anything, you must register transformations with its transformer.
	The transformer is also used as an interface to the bone orientations of an actor.
--]]

local util = RequireLibPart("util");
local SKELETON_ROOT_NAME = util.SKELETON_ROOT_NAME;
local rotate = util.rotate;
local lerp = util.lerp;

-- Helper methods for transformation tables.
local function newTransformation(rotation, translateX, translateY, scaleX, scaleY, layer, visual, vFlip, hFlip)
	rotation = tonumber(rotation) or 0;
	translateX = tonumber(translateX) or 0;
	translateY = tonumber(translateY) or 0;
	scaleX = tonumber(scaleX) or 1;
	scaleY = tonumber(scaleY) or 1;
	return {rotation = rotation, translation = {translateX, translateY}, scale = {scaleX, scaleY}, layer = layer, visual = visual, vFlip = vFlip, hFlip = hFlip};
end
local function isValidTransformation(t)
	local valid = type(t) == "table";
	if (valid) then
		if (t.rotation) then
			valid = valid and tonumber(t.rotation);
		end
		if (t.translation) then
			valid = valid and type(t.translation) == "table" and tonumber(t.translation[1]) and tonumber(t.translation[2]);
		end
		if (t.scale) then
			valid = valid and type(t.scale) == "table" and tonumber(t.scale[1]) and tonumber(t.scale[2]);
		end
		if (t.layer) then
			valid = valid and tonumber(t.layer);
		end
		if (t.visual) then
			valid = valid and util.isType(t.visual, "Visual");
		end
	end
	-- We don't need to check vFlip and hFlip as they are booleans.
	return valid;
end
local function isValidTransformationObject(obj)
	if (type(obj) == "table") then
		if (not util.isType(obj, "Animation")) then
			for boneName, trans in pairs(obj) do
				if (not isValidTransformation(trans)) then
					return false;
				end
			end
		end
	elseif (not type(obj) == "function") then
		return false;
	end
	return true;
end

-- Transformer Meta
local MTransformer = util.Meta.Transformer;
MTransformer.__index = MTransformer;
-- Constructor
local function newTransformer(actor)
	local t = setmetatable({}, MTransformer);
	
	t.TransformLocal = {};
	t.TransformWorld = {};
	
	t.Transformations = {};
	t.Powers = {};
	t.BoneMasks = {};
	t.Priorities = {};
	t.Variables = {};
	
	t.FlipH = false;
	t.FlipV = false;
	
	t.RootTransformation = newTransformation();
	
	t:SetActor(actor);
	
	return t;
end

-- Actor accessors
function MTransformer:SetActor(actor)
	if (not actor or type(actor) ~= "table") then
		error(util.errorArgs("BadArg", 1, "SetActor", "table", type(actor)));
	elseif (not util.isType(actor, "Actor")) then
		error(util.errorArgs("BadMeta", 1, "SetActor", "Actor", tostring(util.Meta.Actor), tostring(getmetatable(actor))));
	end
	self.Actor = actor;
end
function MTransformer:GetActor()
	return self.Actor;
end

-- TODO: Add dummyproofing
function MTransformer:SetTransform(name, transformation, boneMask)
	if (not transformation) then
		self.Transformations[name] = nil;
		self.Powers[name] = nil;
		self.BoneMasks[name] = nil;
		self.Variables[name] = nil;
		for boneName, _ in ipairs(self.Actor:GetSkeleton().Bones) do
			if (self.Priorities[boneName]) then
				self.Priorities[boneName][name] = nil;
			end
		end
		return;
	end
	if (boneMask) then
		self.BoneMasks[name] = {};
		if (type(boneMask) == "table") then
			for i = 1, #boneMask do
				local boneName = boneMask[i];
				self.BoneMasks[name][boneName] = true;
			end
		end
	else
		self.BoneMasks[name] = nil;
	end
	if (isValidTransformationObject(transformation)) then
		self.Transformations[name] = transformation;
		self.Powers[name] = 0;
		local vars = {};
		if (util.isType(transformation, "Animation")) then
			vars.time = 0;
			vars.speed = 1;
		end
		for boneName, _ in pairs(self.Actor:GetSkeleton().Bones) do
			self.Priorities[boneName] = self.Priorities[boneName] or {};
			self.Priorities[boneName][name] = self.Priorities[boneName][name] or 0;
		end
		self.Variables[name] = vars;
		return vars;
	end
end
function MTransformer:GetTransform(name)
	return self.Transformations[name];
end

-- This might be useful for mass-animation updating. Still needs work.
function MTransformer:GetIterator(typeName)
	local t = {};
	for name, trans in pairs(self.Transformations) do
		if (util.isType(trans, typeName) or type(trans) == typeName and not util.isType(trans, "Animation")) then
			t[name] = self.Variables[name];
		end
	end
	return pairs(t);
end

-- Utility function. Takes an angle that assumes an unflipped actor, and converts it to account for flipping.
function MTransformer:GetFlippedAngle(angle)
	angle = angle + self:GetAngle();
	local sx, sy = self:GetScale();
	angle = angle * (sy/math.abs(sy));
	return angle;
end

function MTransformer:SetPriority(name, priority, bones)
	if (type(bones) == "string") then
		bones = {bones};
	end
	bones = bones or self:GetActor():GetSkeleton():GetBoneList();
	for i = 1, #bones do
		local boneName = bones[i];
		self.Priorities[boneName] = self.Priorities[boneName] or {};
		self.Priorities[boneName][name] = priority;
	end
end
function MTransformer:GetPriority(name, boneName)
	if (self.Priorities[boneName] == nil) then
		return -1;
	end
	return self.Priorities[boneName][name];
end

function MTransformer:SetPower(name, power)
	power = math.max(0, math.min(power, 1)); -- clamp to [0,1]
	self.Powers[name] = power;
end
function MTransformer:GetPower(name)
	if (self.Powers[name] == nil) then
		return -1;
	end
	return self.Powers[name];
end

function MTransformer:GetVariables(name)
	if (name and self.Variables[name]) then
		return self.Variables[name];
	end
	return self.Variables;
end

function MTransformer:GetActiveTransformations()
	local actor = self:GetActor();
	local transformations = {};
	for name, power in pairs(self.Powers) do
		local obj = self.Transformations[name];
		if (obj and power > 0) then
			table.insert(transformations, {name = name, object = obj});
		end
	end
	return transformations;
end

-- TODO: This could probably be optimized/refactored.
function MTransformer:GetModifiedPower(boneName, transformations)
	-- No transformations? No power.
	if (not transformations or #transformations == 0) then
		return {};
	end
	
	-- Make sure priorities on each transformation for this bone default to zero.
	self.Priorities[boneName] = self.Priorities[boneName] or {};
	for i = 1, #transformations do
		local transName = transformations[i].name;
		self.Priorities[boneName][transName] = self.Priorities[boneName][transName] or 0;
	end
	
	-- Sort priorities for this bone into priority layers.
	local sortedPriority = {};
	local realPowers = {};
	for transName, priority in pairs(self.Priorities[boneName]) do
		local i = 1;
		while (sortedPriority[i] and sortedPriority[i] and sortedPriority[i].priority > priority) do
			i = i + 1;
		end
		if (not sortedPriority[i] or sortedPriority[i].priority ~= priority) then
			table.insert(sortedPriority, i, {priority = priority, names = {}, total = 0});
		end
		table.insert(sortedPriority[i].names, transName);
		sortedPriority[i].total = sortedPriority[i].total + self.Powers[transName];
		realPowers[transName] = 1;
	end
	
	-- Next, we calculate new transformation powers for this bone.
	for i = 1, #sortedPriority do
		local layerTransNames = sortedPriority[i].names;
		local layerPowerPrev = 0;
		if (i > 1) then
			layerPowerPrev = sortedPriority[i-1].total / #sortedPriority[i-1].names;
		end
		for j = 1, #layerTransNames do
			realPowers[layerTransNames[j]] = self.Powers[layerTransNames[j]] * (1 - layerPowerPrev);
		end
	end
	
	return realPowers;
end

function MTransformer:GetRoot()
	return self.RootTransformation;
end

function MTransformer:CalculateLocal(transformList, boneName)
	transformList = transformList or self:GetActiveTransformations();
	boneName = boneName or SKELETON_ROOT_NAME;
	
	self.TransformLocal[boneName] = self.TransformLocal[boneName] or {};
	
	local boneData = self.TransformLocal[boneName];
	boneData.rotation = 0;
	boneData.translation = {0, 0};
	boneData.scale = {1, 1};
	
	-- Apply transformation objects to addData - This will usually just be interpolated animation data.
	local powers = self:GetModifiedPower(boneName, transformList);
	for i = 1, #transformList do
		local name = transformList[i].name;
		local obj = transformList[i].object;
		if (not self.BoneMasks[name] or self.BoneMasks[name][boneName]) then
			local data;
			if (util.isType(obj, "Animation")) then
				local animDuration = obj:GetDuration();
				local keyTime = tonumber(self:GetVariables(name).time) or 0;
				local animSpeed = tonumber(self:GetVariables(name).speed) or 1;
				keyTime = keyTime * animSpeed;
				keyTime = (keyTime % animDuration);
				if (keyTime < 0) then
					keyTime = animDuration + keyTime;
				end
				data = obj:Interpolate(boneName, keyTime);
				self:GetActor():GetEventHandler():Check(obj, keyTime);
			elseif (type(obj) == "function") then
				data = obj(self, name, boneName);
			elseif (type(obj) == "table") then
				if (obj[boneName]) then
					data = {};
					data.rotation = obj[boneName].rotation;
					if (obj[boneName].translation) then
						data.translation = {unpack(obj[boneName].translation)};
					end
					if (obj[boneName].scale) then
						data.scale = {unpack(obj[boneName].scale)};
					end
				end
			end
			
			-- Make sure we end up with valid data.
			data = data or {};
			data.rotation = data.rotation or 0;
			data.translation = data.translation or {0, 0};
			data.scale = data.scale or {1, 1};
			
			local power = powers[name] or 0;
			
			-- TODO: Replace lerp with something that won't be negatively affected by user-input? Perhaps that responsibility should rest on the user.
			data.rotation = lerp(0, data.rotation, power);
			data.translation[1] = lerp(0, data.translation[1], power);
			data.translation[2] = lerp(0, data.translation[2], power);
			data.scale[1] = lerp(1, data.scale[1], power);
			data.scale[2] = lerp(1, data.scale[2], power);
			
			-- Do the math.
			boneData.rotation = boneData.rotation + data.rotation;
			boneData.translation[1] = boneData.translation[1] + data.translation[1];
			boneData.translation[2] = boneData.translation[2] + data.translation[2];
			boneData.scale[1] = boneData.scale[1] * data.scale[1];
			boneData.scale[2] = boneData.scale[2] * data.scale[2];
		end
	end
	
	-- Recursive step: transform children.
	local children = self:GetActor():GetSkeleton().Bones[boneName].Children;
	if (children) then
		for i = 1, #children do
			self:CalculateLocal(transformList, children[i]);
		end
	end
end

function MTransformer:CalculateWorld(boneName, parentData)
	boneName = boneName or SKELETON_ROOT_NAME;
	parentData = parentData or self:GetRoot() or newTransformation();
	
	-- Make sure parentData is valid.
	parentData.rotation = parentData.rotation or 0;
	parentData.translation[1] = parentData.translation[1] or 0;
	parentData.translation[2] = parentData.translation[2] or 0;
	parentData.scale[1] = parentData.scale[1] or 1;
	parentData.scale[2] = parentData.scale[2] or 1;
	
	self.TransformWorld[boneName] = self.TransformWorld[boneName] or {};
	
	local boneData = self.TransformWorld[boneName];
	boneData.rotation = 0;
	boneData.translation = {0, 0};
	boneData.scale = {1, 1};
	
	local addData = self.TransformLocal[boneName];
	local boneObj = self.Actor:GetSkeleton():GetBone(boneName);
	local xOffset, yOffset = boneObj:GetOffset();
	
	-- Do flipping
	local shouldFlipH = self.FlipH;
	if (self.FlipV) then
		if (boneName == SKELETON_ROOT_NAME) then
			addData.rotation = math.pi;
		end
		shouldFlipH = not shouldFlipH;
	end
	if (shouldFlipH) then
		xOffset = -xOffset;
		addData.rotation = math.pi - addData.rotation;
		addData.translation[1] = -addData.translation[1];
		addData.scale[2] = -addData.scale[2];
	end
	
	-- The rotation will be the key data rotation plus its parents rotation
	boneData.rotation = parentData.rotation + addData.rotation;
	
	-- Scaling just gets multiplied.
	boneData.scale[1] = parentData.scale[1] * addData.scale[1];
	boneData.scale[2] = parentData.scale[2] * addData.scale[2];
	
	-- The rotatedOffset is the bone offset rotated by the parents rotation.
	local rotatedOffset = {rotate(0, 0, parentData.rotation, xOffset * parentData.scale[1], yOffset * parentData.scale[2])};
	local rotatedTranslation = {rotate(0, 0, boneData.rotation, addData.translation[1], addData.translation[2])};
	
	-- The translation will be the bone offset rotated about the parents position plus key data translation plus the parents translation
	boneData.translation[1] = parentData.translation[1] + rotatedOffset[1] + rotatedTranslation[1];
	boneData.translation[2] = parentData.translation[2] + rotatedOffset[2] + rotatedTranslation[2];
	
	-- Recursive step: transform children.
	local children = self.Actor:GetSkeleton().Bones[boneName].Children;
	if (children) then
		for i = 1, #children do
			self:CalculateWorld(children[i], boneData);
		end
	end
end

-- Getters for absolute orientations (attachName is optional in all cases)
function MTransformer:GetAngle(boneName, attachName)
	boneName = boneName or SKELETON_ROOT_NAME;
	local boneData = self.TransformWorld[boneName];
	local attach = self:GetActor():GetAttachment(boneName, attachName);
	local rotation = 0;
	if (boneData and boneData.rotation) then
		rotation = rotation + boneData.rotation;
	end
	if (attach) then
		rotation = rotation + attach:GetRotation();
	end
	return rotation;
end
function MTransformer:GetPosition(boneName, attachName)
	boneName = boneName or SKELETON_ROOT_NAME;
	local boneData = self.TransformWorld[boneName];
	local attach = self:GetActor():GetAttachment(boneName, attachName);
	local x, y = 0, 0;
	if (boneData and boneData.translation) then
		x = x + boneData.translation[1];
		y = y + boneData.translation[2];
	end
	if (attach) then
		local ax, ay = attach:GetTranslation();
		x = x + ax;
		y = y + ay;
	end
	return x, y;
end
function MTransformer:GetScale(boneName, attachName)
	boneName = boneName or SKELETON_ROOT_NAME;
	local boneData = self.TransformWorld[boneName];
	local attach = self:GetActor():GetAttachment(boneName, attachName);
	local x, y = 1, 1;
	if (boneData and boneData.scale) then
		x = x * boneData.scale[1];
		y = y * boneData.scale[2];
	end
	if (attach) then
		local ax, ay = attach:GetScale();
		x = x * ax;
		y = y * ay;
	end
	return x, y;
end
function MTransformer:GetForward(boneName, attachName)
	boneName = boneName or SKELETON_ROOT_NAME;
	local ang = self:GetAngle(boneName, attachName);
	local fx, fy = rotate(0, 0, ang, 1, 0);
	if (self.FlipH and not self.FlipV or self.FlipV and not self.FlipH) then
		fx = -fx;
	end
	return fx, fy;
end
function MTransformer:GetUp(boneName, attachName)
	boneName = boneName or SKELETON_ROOT_NAME;
	local uy, ux = self:GetForward(boneName, attachName);
	return ux, -uy;
end

return newTransformer;