--[[
	Animation
	Animations are basically keyframe data containers.
	They also come with utility methods for finding keyframe ranges and interpolating between them.
--]]

local util = RequireLibPart("util");
local lerp = util.lerp;

local MAnimation = util.Meta.Animation;
MAnimation.__index = MAnimation;
local function newAnimation(skeleton)
	local t = setmetatable({}, MAnimation);
	t.KeyFrames = {};
	t.Events = {};
	t.Duration = 0;
	if (skeleton) then
		t:InitializeKeyFrames(skeleton);
	end
	return t;
end

-- Initialize the first frame (time=0) to have all bones in their bind-pose.
function MAnimation:InitializeKeyFrames(skeleton)
	if (not skeleton or not util.isType(skeleton, "Skeleton")) then
		error(util.errorArgs("BadMeta", 1, "InitializeKeyFrames", "Skeleton", tostring(util.Meta.Skeleton), tostring(getmetatable(skeleton))));
	elseif (not skeleton:IsValid()) then
		error("bad argument #1 to 'InitializeKeyFrames' (skeleton is invalid, has Skeleton:Validate() been called?)");
	end
	self.KeyFrames = self.KeyFrames or {};
	for boneName, keyframe in pairs(skeleton:GetBindPose()) do
		if (not (self.KeyFrames and self.KeyFrames[boneName] and self.KeyFrames[boneName][1] and self.KeyFrames[boneName][1].time == 0)) then
			self:AddKeyFrame(boneName, keyframe.time, keyframe.rotation, keyframe.translation, keyframe.scale);
		end
	end
end

-- Adds a keyframe at keyTime for bone with reference name boneName
function MAnimation:AddKeyFrame(boneName, keyTime, rotation, translation, scale)
	self.KeyFrames = self.KeyFrames or {};
	self.KeyFrames[boneName] = self.KeyFrames[boneName] or {};
	
	-- Can't add a keyframe with no data.
	if (not (rotation or translation or scale)) then
		return;
	end
	
	-- Make sure everything is valid.
	if (rotation) then
		rotation = tonumber(rotation) or 0;
	end
	if (translation) then
		translation[1] = tonumber(translation[1]) or 0;
		translation[2] = tonumber(translation[2]) or 0;
	end
	if (scale) then
		scale[1] = tonumber(scale[1]) or 1;
		scale[2] = tonumber(scale[2]) or 1;
	end
	
	-- Update duration.
	if (keyTime > self.Duration) then
		self.Duration = keyTime;
	end
	
	-- Construct the keyframe.
	local keyframe = {time = keyTime, rotation = rotation, translation = translation, scale = scale};
	
	-- Figure out where this keyframe should reside.
	local i = 1;
	for _, v in pairs(self.KeyFrames[boneName]) do
		if v.time < keyframe.time then
			i = i + 1;
		end
	end
	
	-- If this keyframe doesn't already exist, put it into the frames table.
	if (not self.KeyFrames[boneName][i] or self.KeyFrames[boneName][i].time ~= keyframe.time) then
		table.insert(self.KeyFrames[boneName], i, keyframe);
	end
	-- Add the keyframe data for the bone into the keyframe. (semi-redundant step, should probably refactor this)
	self.KeyFrames[boneName][i] = keyframe;
end

function MAnimation:AddEvent(keyTime, eventName)
	-- Figure out where this event should reside.
	local i = 1;
	for _, v in pairs(self.Events) do
		if v.t < keyTime then
			i = i + 1;
		end
	end
	table.insert(self.Events, i, {t = keyTime, e = eventName});
end
function MAnimation:GetEventNames()
	local found = {};
	local t = {};
	for k, v in pairs(self.Events) do
		if (not found[v.e]) then
			table.insert(t, v.e);
			found[v.e] = true;
		end
	end
	return t;
end

-- Returns the total duration of an animation in keyframe time.
function MAnimation:GetDuration()
	return self.Duration;
end

function MAnimation:GetEventsInRange(lastCheckTime, curTime)
	local t = {};
	for i = 1, #self.Events do
		local eventData = self.Events[i];
		if (eventData.t > lastCheckTime and eventData.t <= curTime) then
			--print("Found eventData", i, lastCheckTime, eventData.t, curTime, eventData.e);
			table.insert(t, {ID = i, name = eventData.e});
		end
	end
	return t;
end


-- TODO: Add separate tracks for each possible transformation?
-- Returns two values: prevKeyframe, nextKeyframe
--	1. The last occurring keyframe before or at keyTime for the bone with name boneName.
--	2. The first occurring keyframe after keyTime for the bone with name boneName.
-- If nextKeyframe doesn't exist, it will return the data from prevKeyframe
-- TODO: Add looping functionality.
function MAnimation:GetKeyFrames(boneName, keyTime)
	local prevIndex, nextIndex = {}, {};
	local keyframes = self.KeyFrames[boneName];
	-- TODO: Check if keyframes is valid.
	-- Find start/end of current rotation for this bone.
	for i = 1, #keyframes do
		local data = keyframes[i];
		if (data.rotation) then
			if (data.time <= keyTime) then
				prevIndex.r = i;
			else
				nextIndex.r = i;
				break;
			end
		end
	end
	if (nextIndex.r == nil) then
		nextIndex.r = prevIndex.r;
	end
	-- Find start/end of current translation for this bone.
	for i = 1, #keyframes do
		local data = keyframes[i];
		if (data.translation) then
			if (data.time <= keyTime) then
				prevIndex.t = i;
			else
				nextIndex.t = i;
				break;
			end
		end
	end
	if (nextIndex.t == nil) then
		nextIndex.t = prevIndex.t;
	end
	-- Find start/end of current scaling for this bone.
	for i = 1, #keyframes do
		local data = keyframes[i];
		if (data.scale) then
			if (data.time <= keyTime) then
				prevIndex.s = i;
			else
				nextIndex.s = i;
				break;
			end
		end
	end
	if (nextIndex.s == nil) then
		nextIndex.s = prevIndex.s;
	end
	return prevIndex, nextIndex;
end

-- Interpolate between keyframes for a specific bone at a specific time.
function MAnimation:Interpolate(boneName, keyTime)
	local prevIndex, nextIndex = self:GetKeyFrames(boneName, keyTime);
	-- Get new local rotation
	local prevRotData = self.KeyFrames[boneName][prevIndex.r];
	local nextRotData = self.KeyFrames[boneName][nextIndex.r];
	local newRot = 0;
	if (prevRotData and nextRotData) then
		newRot = prevRotData.rotation;
		if (prevRotData.rotation ~= nextRotData.rotation) then
			local lerpAmount = (keyTime - prevRotData.time) / (nextRotData.time - prevRotData.time);
			newRot = lerp(prevRotData.rotation, nextRotData.rotation, lerpAmount);
		end
	end
	-- Get new local translation
	local prevTransData = self.KeyFrames[boneName][prevIndex.t];
	local nextTransData = self.KeyFrames[boneName][nextIndex.t];
	local newTrans = {0, 0};
	if (prevTransData and nextTransData) then
		newTrans = {unpack(prevTransData.translation)};
		if (prevTransData.translation ~= nextTransData.translation) then
			local lerpAmount = (keyTime - prevTransData.time) / (nextTransData.time - prevTransData.time);
			local prevX, prevY = unpack(prevTransData.translation);
			local nextX, nextY = unpack(nextTransData.translation);
			newTrans = {
				lerp(prevX, nextX, lerpAmount),
				lerp(prevY, nextY, lerpAmount)
			};
		end
	end
	-- Get new local scaling
	local prevScaleData = self.KeyFrames[boneName][prevIndex.s];
	local nextScaleData = self.KeyFrames[boneName][nextIndex.s];
	local newScale = {1, 1};
	if (prevScaleData and nextScaleData) then
		newScale = {unpack(prevScaleData.scale)};
		if (prevScaleData.scale ~= nextScaleData.scale) then
			local lerpAmount = (keyTime - prevScaleData.time) / (nextScaleData.time - prevScaleData.time);
			local prevX, prevY = unpack(prevScaleData.scale);
			local nextX, nextY = unpack(nextScaleData.scale);
			newScale = {
				lerp(prevX, nextX, lerpAmount),
				lerp(prevY, nextY, lerpAmount)
			};
		end
	end
	return {rotation = newRot, translation = newTrans, scale = newScale};
end

return newAnimation;