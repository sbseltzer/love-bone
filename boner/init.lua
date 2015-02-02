--[[
	BÖNER: Library for keyframe-based skeletal animations in LÖVE.
	By Samuel Seltzer-Johnston
--]]

local SHARED = require("boner.shared");
local newBone = require("boner.bone");
local newSkeleton = require("boner.skeleton");
local newAnimation = require("boner.animation");
local newActor = require("boner.actor");
local newVisual = require("boner.visual");
local newAttachment = require("boner.attachment");
local newTransformer = require("boner.transformer");
local newEventHandler = require("boner.eventhandler");

-- Enable/disable debug rendering.
local function setDebug(b)
	SHARED.DEBUG = b;
end
local function getDebug()
	return SHARED.DEBUG;
end

-- Return the library.
return {
	setDebug = setDebug,
	getDebug = getDebug;
	newBone = newBone,
	newSkeleton = newSkeleton,
	newAnimation = newAnimation, 
	newActor = newActor,
	newVisual = newVisual,
	newAttachment = newAttachment,
	newTransformer = newTransformer,
	newEventHandler = newEventHandler,
	isType = SHARED.isType
};