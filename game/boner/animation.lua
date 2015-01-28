
local SHARED = require("boner.shared");
local lerp = SHARED.lerp;

--[[
	Animation
	Animations are basically keyframe data containers.
	They also come with utility methods for finding keyframe ranges and interpolating between them.
--]]
local MAnimation = SHARED.Meta.Animation;
MAnimation.__index = MAnimation;
local function newAnimation()
	local t = {};
	t.KeyFrames = {};
	t.Events = {};
	t.Duration = 0;
	return setmetatable(t, MAnimation);
end

function MAnimation:SetName(name)
	self.Name = name;
end
function MAnimation:GetName()
	return self.Name;
end

function MAnimation:SetSkeleton(skeleton)
	self.Skeleton = skeleton;
	self:InitializeKeyFrames(skeleton);
end
function MAnimation:GetSkeleton()
	return self.Skeleton;
end

-- Initialize the first frame (time=0) to have all bones in their bine-pose.
function MAnimation:InitializeKeyFrames(skeleton)
	skeleton = skeleton or self:GetSkeleton();
	if (not skeleton) then
		error("Please give the animation a skeleton before attempting to initialize keyframes!", 2);
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
	
	if (not rotation and not translation) then
		return;
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

-- Returns the total duration of an animation in keyframe time.
function MAnimation:GetDuration()
	return self.Duration;
end

-- Returns two values: prevKeyframe, nextKeyframe
--	1. The last occurring keyframe before or at keyTime for the bone with name boneName.
--	2. The first occurring keyframe after keyTime for the bone with name boneName.
-- If nextKeyframe doesn't exist, it will return the data from prevKeyframe
-- TODO: Add looping functionality.
function MAnimation:GetKeyFrames(boneName, keyTime)
	local prevIndex, nextIndex = {}, {};
	local keyframes = self.KeyFrames[boneName];
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
		newScale = {unpack(prevScaleData.translation)};
		if (prevScaleData.scale ~= nextScaleData.scale) then
			local lerpAmount = (keyTime - prevScaleData.time) / (nextScaleData.time - prevScaleData.time);
			local prevX, prevY = unpack(prevScaleData.translation);
			local nextX, nextY = unpack(nextScaleData.translation);
			newScale = {
				lerp(prevX, nextX, lerpAmount),
				lerp(prevY, nextY, lerpAmount)
			};
		end
	end
	return {rotation = newRot, translation = newTrans};
end

return newAnimation;