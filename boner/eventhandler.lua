--[[
	EventHandler
	Registers and listens for animation events on an actor.
--]]

local SHARED = require("boner.shared");

local MEventHandler = SHARED.Meta.EventHandler;
MEventHandler.__index = MEventHandler;
local function newEventHandler(actor)
	local t = setmetatable({}, MEventHandler);
	t:SetActor(actor);
	t.Callbacks = {};
	t.Checked = {};
	return t;
end

function MEventHandler:SetActor(actor)
	if (not actor or type(actor) ~= "table") then
		error(SHARED.errorArgs("BadArg", 1, "SetActor", "table", type(actor)));
	elseif (not SHARED.isType(actor, "Actor")) then
		error(SHARED.errorArgs("BadMeta", 1, "SetActor", "Actor", tostring(SHARED.Meta.Actor), tostring(getmetatable(actor))));
	end
	self.Actor = actor;
end
function MEventHandler:GetActor()
	return self.Actor;
end

function MEventHandler:Register(animObj, eventName, funcCallback)
	if (not animObj or not SHARED.isType(animObj, "Animation")) then
		error(SHARED.errorArgs("BadMeta", 1, "Register", "Animation", tostring(SHARED.Meta.Animation), tostring(getmetatable(animObj))));
	elseif (not eventName or type(eventName) ~= "string") then
		error(SHARED.errorArgs("BadArg", 2, "Register", "string", type(eventName)));
	elseif (not funcCallback or type(funcCallback) ~= "function") then
		error(SHARED.errorArgs("BadArg", 3, "Register", "function", type(eventName)));
	end
	self.Callbacks[animObj] = self.Callbacks[animObj] or {};
	self.Callbacks[animObj][eventName] = self.Callbacks[animObj][eventName] or {};
	table.insert(self.Callbacks[animObj][eventName], funcCallback);
end

function MEventHandler:Fire(animObj, eventName)
	if (not animObj or not SHARED.isType(animObj, "Animation")) then
		error(SHARED.errorArgs("BadMeta", 1, "Fire", "Animation", tostring(SHARED.Meta.Animation), tostring(getmetatable(animObj))));
	elseif (not eventName or type(eventName) ~= "string") then
		error(SHARED.errorArgs("BadArg", 2, "Fire", "string", type(eventName)));
	end
	if (animObj and self.Callbacks[animObj] and eventName and self.Callbacks[animObj][eventName]) then
		for i = 1, #self.Callbacks[animObj][eventName] do
			self.Callbacks[animObj][eventName][i](self:GetActor(), animObj, eventName);
		end
	end
end

-- TODO: Support checks for animations playing backwards.
function MEventHandler:Check(animObj, keyTime)
	if (not animObj or type(animObj) ~= "table") then
		error(SHARED.errorArgs("BadArg", 1, "Check", "table", type(animObj)));
	elseif (not SHARED.isType(animObj, "Animation")) then
		error(SHARED.errorArgs("BadMeta", 1, "Check", "Animation", tostring(SHARED.Meta.Animation), tostring(getmetatable(animObj))));
	elseif (not keyTime or type(keyTime) ~= "number") then
		error(SHARED.errorArgs("BadArg", 2, "Check", "number", type(keyTime)));
	end
	
	-- No events for this anim? Do nothing.
	if (#animObj.Events == 0) then
		return;
	end
	
	-- Did we already checked for events on this animation this frame?
	if (self.Checked[animObj] and self.Checked[animObj] == keyTime) then
		return;
	end
	self.Checked[animObj] = self.Checked[animObj] or 0;
	
	local events = animObj:GetEventsInRange(self.Checked[animObj], keyTime);
	for i = 1, #events do
		self:Fire(animObj, events[i].name);
	end
	
	--self.lastCheck = keyTime;
	self.Checked[animObj] = keyTime;
end

return newEventHandler;