--[[
	BÖNER: Library for keyframe-based skeletal animations in LÖVE.
	By Samuel Seltzer-Johnston
--]]

local path = ...;
function RequireLibPart(part)
	return require(path .. "." .. part);
end

local util = RequireLibPart("util");
local newBone = RequireLibPart("bone");
local newSkeleton = RequireLibPart("skeleton");
local newAnimation = RequireLibPart("animation");
local newActor = RequireLibPart("actor");
local newVisual = RequireLibPart("visual");
local newAttachment = RequireLibPart("attachment");
local newTransformer = RequireLibPart("transformer");
local newEventHandler = RequireLibPart("eventhandler");

RequireLibPart = nil;

-- Return the library.
return {
	newBone = newBone,
	newSkeleton = newSkeleton,
	newAnimation = newAnimation, 
	newActor = newActor,
	newVisual = newVisual,
	newAttachment = newAttachment,
	newTransformer = newTransformer,
	newEventHandler = newEventHandler,
	isType = util.isType
};