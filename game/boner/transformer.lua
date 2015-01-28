
--[[
	BÖNER uses modular transformation system for calculating bone orientation.
	An arbitrary number of transformations can be applied to arbitrary sets of bone at varying powers.
	
	Transformations also hold a degree of effect, or power. This determines how powerful the transformation is.
	Degree of effect can be used for blending animations. For instance, transitioning from walking to idle.
	To do this transition, the power for the walking animation would go from 1 to 0 over some period of time.
	At the same time, the power for the idle animation would go from 0 to 1 over the same period of time.
	
	However, it is possible for multiple animations to hold a total power greater than 1. 
	This can look awkward, and sometimes is not the desired effect.
	To overcome this, transformations may specify a priority for certain bones. By default priority is 0.
	In these cases we may need to calculate a new power for the transformations to use on the affected bones.
	If and only if a bone has multiple priority layers specified:
		1. Start with the top priority layer.
		2. Let the current priority layer be denoted as L0.
		3. If the sum of L0's DoEs is greater than 1, scale them such that they are equal to 1.
		4. Let A be the (possibly modified) sum of L0's DoEs.
		5. Let the priority layer below L0 be denoted as L1.
		6. Scale down the DoEs of L1 such that the sum of their DoEs is equal to 1-A
		7. Let B be the (possibly modified) sum of L1's DoEs.
		8. Let L0 = L1, and A = B.
		9. Repeat steps 3-8 until L0 is the lowest priority layer.
	A power of 0 for a transformation on a bone means that the transformation has no effect on the bone.
	A power of 1 for a transformation on a bone means that the transformation has full effect on the bone.
	Having a power of 1 DOES NOT mean that the transformation has a mutually exclusive control over the bone.
	To accomplish this, it must have a power of 1, and all other transformations for that bone must have a power of 0.
	By default, all active transformations have a power of 1 for all bones, even if they never actually affect some bones.
	If the intended effect is a strict overlap, this is fine.
	
	If we want to blend between two transformations for some set of bones, their powers must swap over a period of time.
	There is one problem, though. Power is specified per-transformation. If both transformations affect the entire skeleton, this is fine.
	If we want a transformation fading in on some set of bones while the current animation fades out on that same set, we have a problem.
	Swapping their true power values will affect the entire skeleton, so we need a way to alter power for particular bones.
	
	This is where priority comes in.
	Priority is specified per-bone, although, the desired effect is often to apply priority to an entire hierarchy.
	If multiple transformations affect a single bone, we check their priority level.
	If one or more transformations have the same priority on that bone, we say the layer power is the average of their powers.
	
	
	
	So here's the problem:
		For each bone, we need to know how much each transformation should affect it.
		
	
	
	
--]]
local SHARED = require("boner.shared");
local SKELETON_ROOT_NAME = SHARED.SKELETON_ROOT_NAME;
local rotate = SHARED.rotate;
local lerp = SHARED.lerp;

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
	
	t.Objects = {};
	t.Power = {};
	t.Filter = {};
	t.Priority = {};
	
	t.FlipH = false;
	t.FlipV = false;
	return t;
end

local function newTransformation(rotation, translateX, translateY, scaleX, scaleY, layer, visual, vertFlip, horizFlip)
	
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
		self.TransformLocal = skeleton:GetBlankTransformation();
		self.TransformGlobal = skeleton:GetBlankTransformation();
		self:CalculateLocal();
		self:CalculateGlobal();
	end
end

-- Adds a transformation to the list of transformer objects with an optional bone filter.
function MTransformer:RegisterObject(name, obj, boneFilter)
	if (obj == nil) then
		self.Objects[name] = nil;
		self.Power[name] = nil;
		self.Filter[name] = nil;
		for boneName, _ in pairs(self.Actor:GetSkeleton().Bones) do
			if (self.Priority[boneName]) then
				self.Priority[boneName][name] = nil;
			end
		end
		return;
	end
	if (boneFilter) then
		self.Filter[name] = {};
		if (type(boneFilter) == "table") then
			for i = 1, #boneFilter do
				local boneName = boneFilter[i];
				self.Filter[name][boneName] = true;
			end
		end
	else
		self.Filter[name] = nil;
	end
	if (type(obj) == "table") then
		if (not SHARED.isMeta(obj, "Animation") and obj.bone and self.Actor:GetSkeleton():GetBone(obj.bone)) then
			-- Tables must have a valid transformation aspect.
			local hasValidRotation = obj.rotation and tonumber(obj.rotation);
			local hasValidTranslation = obj.translation and type(obj.translation) == "table" and #obj.translation == 2 and tonumber(obj.translation[1]) and tonumber(obj.translation[2]);
			local hasValidScale = obj.scale and type(obj.scale) == "table" and #obj.scale == 2 and tonumber(obj.scale[1]) and tonumber(obj.scale[2]);
			if (not (hasValidRotation or hasValidTranslation or hasValidScale)) then
				obj = nil;
			end
		end
	elseif(not type(obj) == "function" and not type(obj) == "string") then
		obj = nil;
	end
	if (obj) then
		self.Objects[name] = obj;
		self.Power[name] = 0;
		for boneName, _ in pairs(self.Actor:GetSkeleton().Bones) do
			self.Priority[boneName] = self.Priority[boneName] or {};
			self.Priority[boneName][name] = self.Priority[boneName][name] or 0;
		end
	else
		error("Failed to add transformation '" .. name .. "' to actor: Invalid object!", 2);
	end
end

function MTransformer:SetPower(name, power)
	power = math.max(0, math.min(power, 1)); -- clamp to [0,1]
	self.Power[name] = power;
end
function MTransformer:GetPower(name)
	if (self.Power[name] == nil) then
		return -1;
	end
	return self.Power[name];
end

function MTransformer:SetPriority(name, boneList, priority)
	for i = 1, #boneList do
		local boneName = boneList[i];
		self.Priority[boneName] = self.Priority[boneName] or {};
		self.Priority[boneName][name] = priority;
	end
end
function MTransformer:GetPriority(name, boneName, priority)
	if (self.Priority[boneName] == nil) then
		return -1;
	end
	return self.Priority[boneName][name];
end

function MTransformer:GetObjects()
	local transformations = {};
	local overridePriorities = {};
	for name, power in pairs(self.Power) do
		if (power > 0) then
			local obj = self.Objects[name];
			local trans;
			-- If the object is a string, quickly translate it to an animation if one exists.
			if (type(obj) == "string") then
				if (self.Actor:GetSkeleton().Animations[obj]) then
					obj = self.Actor:GetSkeleton().Animations[obj];
				else
					obj = nil;
				end
			end
			if (obj) then
				if (SHARED.isMeta(obj, "Animation")) then
					-- Calculate keyTime
					-- TODO: Speed per transformation.
					local animDuration = obj:GetDuration() / self.Actor.Speed;
					local keyTime = (self.Actor.TimeElapsed % animDuration) * self.Actor.Speed;
					if (keyTime < 0) then
						keyTime = animDuration + keyTime;
					end
					trans = {name = name, object = obj, time = keyTime};
				elseif (type(obj) == "function") then
					trans = {name = name, object = obj, time = self.Actor.TimeElapsed * self.Actor.Speed};
				elseif (type(obj) == "table") then
					trans = {name = name, object = obj};
				end
				if (trans) then
					table.insert(transformations, trans);
				end
			end
		end
	end
	return transformations;
end

-- TODO: Replace the first loop with a priority queue or something.
function MTransformer:GetModifiedPower(boneName, transformations)
	if (not transformations) then
		return {};
	end
	self.Priority[boneName] = self.Priority[boneName] or {};
	if (not self.Priority[boneName]) then
		return {};
	end
	for i = 1, #transformations do
		local transName = transformations[i].name;
		self.Priority[boneName][transName] = self.Priority[boneName][transName] or 0;
	end
	
	local sortedPriority = {};
	local realPowers = {};
	for transName, priority in pairs(self.Priority[boneName]) do
		local i = 1;
		while (sortedPriority[i] and sortedPriority[i] and sortedPriority[i].priority > priority) do
			i = i + 1;
		end
		if (not sortedPriority[i] or sortedPriority[i].priority ~= priority) then
			table.insert(sortedPriority, i, {priority = priority, names = {}, total = 0});
		end
		table.insert(sortedPriority[i].names, transName);
		sortedPriority[i].total = sortedPriority[i].total + self.Power[transName];
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
			realPowers[layerTransNames[j]] = self.Power[layerTransNames[j]] * (1 - layerPowerPrev);
		end
	end
	return realPowers;
end

--
function MTransformer:CalculateLocal(transformList, boneName, parentData)
	boneName = boneName or SKELETON_ROOT_NAME;
	parentData = parentData or {rotation = 0, translation = {0,0}, scale = {1, 1}};
	
	local boneData = self.TransformLocal[boneName];
	boneData.rotation = 0;
	boneData.translation = {0,0};
	boneData.scale = {1, 1};
	
	local powers = self:GetModifiedPower(boneName, transformList);
	
	-- Apply transformation objects to addData - This will usually just be interpolated animation data.
	if (transformList) then
		for i = 1, #transformList do
			local name = transformList[i].name;
			local keyTime = transformList[i].time;
			local obj = transformList[i].object;
			if (not self.Filter[name] or self.Filter[name][boneName]) then
				local data;
				if (SHARED.isMeta(obj, "Animation")) then
					data = obj:Interpolate(boneName, keyTime);
					self:GetActor():GetEventHandler():Check(obj, keyTime);
				elseif (type(obj) == "function") then
					data = obj(boneName, keyTime, self.FlipH, self.FlipV);
				elseif (type(obj) == "table") then
					if (obj.bone and obj.bone == boneName) then
						data = {};
						data.rotation = obj.rotation;
						if (obj.translation) then
							data.translation = {unpack(obj.translation)};
						end
						if (obj.scale) then
							obj.scale = {unpack(obj.scale)};
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
				
				-- TODO: Replace lerp with something that won't be negatively affected by user-input.
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
	end
	
	-- Recursive step: transform children.
	local children = self.Actor:GetSkeleton().Bones[boneName].Children;
	if (children) then
		for i = 1, #children do
			self:CalculateLocal(transformList, children[i], nil);
		end
	end
end

function MTransformer:CalculateGlobal(boneName, parentData)
	boneName = boneName or SKELETON_ROOT_NAME;
	parentData = parentData or {rotation = 0, translation = {0,0}, scale = {1, 1}};
	local addData = self.TransformLocal[boneName];
	local boneData = self.TransformGlobal[boneName];
	local boneObj = self.Actor:GetSkeleton():GetBone(boneName);
	local xOffset, yOffset = boneObj:GetOffset();
	
	if (self.FlipH) then
		xOffset = -xOffset;
		addData.rotation = math.pi - addData.rotation;
		addData.translation[1] = -addData.translation[1];
		addData.scale[2] = -addData.scale[2];
	end
	if (self.FlipV) then
		yOffset = -yOffset;
		addData.rotation = 2 * math.pi - addData.rotation;
		--addData.translation[1] = -addData.translation[1];
		addData.translation[2] = -addData.translation[2];
		--addData.scale[1] = -addData.scale[1];
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
			self:CalculateGlobal(children[i], boneData);
		end
	end
end

return newTransformer;