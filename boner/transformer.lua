local SHARED = require("boner.shared");
local SKELETON_ROOT_NAME = SHARED.SKELETON_ROOT_NAME;
local rotate = SHARED.rotate;
local lerp = SHARED.lerp;

-- Helper methods for transformation tables.
local function newTransformation(rotation, translateX, translateY, scaleX, scaleY, layer, visual, vFlip, hFlip)
	rotation = rotation or 0;
	translateX = translateX or 0;
	translateY = translateY or 0;
	scaleX = scaleX or 1;
	scaleY = scaleY or 1;
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
			valid = valid and SHARED.isMeta(t.visual, "Visual");
		end
	end
	-- We don't need to check vFlip and hFlip as they are booleans.
	return valid;
end
local function isValidTransformationObject(obj)
	if (type(obj) == "table") then
		if (not SHARED.isMeta(obj, "Animation")) then
			for boneName, trans in pairs(obj) do
				--print(boneName, trans);
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


--[[
	The actor bone transformation code took up so much space that it really deserved its own file.
--]]
local MTransformer = SHARED.Meta.Transformer;
MTransformer.__index = MTransformer;

local function newTransformer(actor)
	local t = setmetatable({}, MTransformer);
	
	t:SetActor(actor);
	
	t.TransformLocal = {};
	t.TransformGlobal = {};
	
	t.Transformations = {};
	t.Powers = {};
	t.BoneMasks = {};
	t.Priorities = {};
	t.Variables = {};
	
	t.FlipH = false;
	t.FlipV = false;
	
	t.RootTransformation = newTransformation();
	
	return t;
end

function MTransformer:SetActor(actor)
	self.Actor = actor;
end
function MTransformer:GetActor()
	return self.Actor;
end

-- Called by actor to initialize transformer.
function MTransformer:Initialize(skeleton)
	if (skeleton) then
		self:CalculateLocal();
		self:CalculateGlobal();
	end
end

-- Adds a transformation to the list of transformer objects with an optional bone filter.
function MTransformer:Register(name, obj, boneMask)
	if (not obj) then
		self.Transformations[name] = nil;
		self.Powers[name] = nil;
		self.BoneMasks[name] = nil;
		self.Variables[name] = nil;
		for boneName, _ in pairs(self.Actor:GetSkeleton().Bones) do
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
	if (isValidTransformationObject(obj)) then
		self.Transformations[name] = obj;
		self.Powers[name] = 0;
		local vars = {};
		if (SHARED.isMeta(obj, "Animation")) then
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

function MTransformer:IsType(name, typeName)
	if (typeName == "Animation") then
		return SHARED.isMeta(self.Transformations[name], typeName);
	else
		return type(self.Transformations[name]) == typeName;
	end
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

function MTransformer:SetPriority(name, boneList, priority)
	for i = 1, #boneList do
		local boneName = boneList[i];
		self.Priorities[boneName] = self.Priorities[boneName] or {};
		self.Priorities[boneName][name] = priority;
	end
end
function MTransformer:GetPriority(name, boneName, priority)
	if (self.Priorities[boneName] == nil) then
		return -1;
	end
	return self.Priorities[boneName][name];
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
		if (power > 0) then
			local obj = self.Transformations[name];
			local trans;
			if (obj) then
				--[[if (SHARED.isMeta(obj, "Animation")) then
					-- Calculate keyTime
					-- TODO: Speed per transformation.
					local animDuration = obj:GetDuration() / actor.Speed;
					local keyTime = (actor.TimeElapsed % animDuration) * actor.Speed;
					if (keyTime < 0) then
						keyTime = animDuration + keyTime;
					end
					trans = {name = name, object = obj};
				elseif (type(obj) == "function") then
					trans = {name = name, object = obj};
				elseif (type(obj) == "table") then
					trans = {name = name, object = obj};
				end]]
				table.insert(transformations, {name = name, object = obj});
			end
		end
	end
	return transformations;
end

-- TODO: Replace the first loop with a priority queue or something.
function MTransformer:GetModifiedPower(boneName, transformations)
	if (not transformations or #transformations == 0) then
		return {};
	end
	self.Priorities[boneName] = self.Priorities[boneName] or {};
	if (not self.Priorities[boneName]) then
		return {};
	end
	for i = 1, #transformations do
		local transName = transformations[i].name;
		self.Priorities[boneName][transName] = self.Priorities[boneName][transName] or 0;
	end
	
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

--
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
			if (SHARED.isMeta(obj, "Animation")) then
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
				data = obj(self:GetActor(), boneName, self:GetVariables(name));
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
			
			--local targetRot = math.fmod(data.rotation, 2 * math.pi);
			--local curRot = math.fmod(self.TransformLocal[boneName].rotation, 2 * math.pi);
			
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

function MTransformer:CalculateGlobal(boneName, parentData)
	boneName = boneName or SKELETON_ROOT_NAME;
	parentData = parentData or self:GetRoot() or newTransformation();
	
	-- Make sure parentData is valid.
	parentData.rotation = parentData.rotation or 0;
	parentData.translation[1] = parentData.translation[1] or 0;
	parentData.translation[2] = parentData.translation[2] or 0;
	parentData.scale[1] = parentData.scale[1] or 1;
	parentData.scale[2] = parentData.scale[2] or 1;
	
	self.TransformGlobal[boneName] = self.TransformGlobal[boneName] or {};
	
	local boneData = self.TransformGlobal[boneName];
	boneData.rotation = 0;
	boneData.translation = {0, 0};
	boneData.scale = {1, 1};
	
	local addData = self.TransformLocal[boneName];
	local boneObj = self.Actor:GetSkeleton():GetBone(boneName);
	local xOffset, yOffset = boneObj:GetOffset();
	
	if (self.FlipH) then
		xOffset = -xOffset;
		addData.rotation = math.pi - addData.rotation;
		addData.translation[1] = -addData.translation[1];
		addData.scale[2] = -addData.scale[2];
	end
	
	-- TODO: Fix vertical flip.
	--[[if (self.FlipV) then
		yOffset = -yOffset;
		addData.rotation = 2 * math.pi - addData.rotation;
		--addData.translation[1] = -addData.translation[1];
		addData.translation[2] = -addData.translation[2];
		--addData.scale[1] = -addData.scale[1];
		addData.scale[2] = -addData.scale[2];
	end]]
	
	
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
			self:CalculateGlobal(children[i], boneData);
		end
	end
end

-- Getters for absolute bone orientations
function MTransformer:GetBoneAngle(boneName)
	local boneData = self.TransformGlobal[boneName];
	if (not boneData or not boneData.rotation) then
		return 0;
	end
	return boneData.rotation;
end
function MTransformer:GetBonePosition(boneName, offset)
	local boneData = self.TransformGlobal[boneName];
	local sx, sy = self:GetBoneScale(boneName);
	local x, y = unpack(boneData.translation);
	return x, y;
end
function MTransformer:GetBoneScale(boneName)
	local boneData = self.TransformGlobal[boneName];
	if (not boneData or not boneData.scale) then
		return 1, 1;
	end
	return unpack(boneData.scale);
end

-- Getters for absolute attachment orientations
function MTransformer:GetAttachmentAngle(boneName, attachName)
	local boneRot = self:GetBoneAngle(boneName) or 0;
	local attach = self:GetActor():GetAttachment(boneName, attachName);
	local attachRot;
	if (attach) then
		attachRot = attach:GetRotation();
	else
		attachRot = 0;
	end
	return boneRot + attachRot;
end
function MTransformer:GetAttachmentPosition(boneName, attachName, offset)
	local bonePos = {self:GetBonePosition(boneName)};
	local attach = self:GetActor():GetAttachment(boneName, attachName);
	local attachPos;
	if (attach) then
		attachPos = {attach:GetTranslation()};
	else
		attachPos = {0, 0};
	end
	offset = offset or {0, 0};
	offset = {rotate(0, 0, self:GetAttachmentAngle(boneName, attachName), attachPos[1] + offset[1], attachPos[2] + offset[2])};
	return bonePos[1] + offset[1], bonePos[2] + offset[2];
end
function MTransformer:GetAttachmentScale(boneName, attachName)
	local boneScale = {self:GetBoneScale(boneName)};
	local attach = self:GetActor():GetAttachment(boneName, attachName);
	local attachScale;
	if (attach) then
		attachScale = {attach:GetScale()};
	else
		attachScale = {1, 1};
	end
	return boneScale[1] * attachScale[1], boneScale[2] * attachScale[2];
end


return newTransformer;