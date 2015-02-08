--[[
	EventHandler
	Registers and listens for animation events on an actor.
--]]

local util = RequireLibPart("util");

local MEventHandler = util.Meta.EventHandler;
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
		error(util.errorArgs("BadArg", 1, "SetActor", "table", type(actor)));
	elseif (not util.isType(actor, "Actor")) then
		error(util.errorArgs("BadMeta", 1, "SetActor", "Actor", tostring(util.Meta.Actor), tostring(getmetatable(actor))));
	end
	self.Actor = actor;
end
function MEventHandler:GetActor()
	return self.Actor;
end

function MEventHandler:Register(animObj, eventName, callback)
	if (not animObj or not util.isType(animObj, "Animation")) then
		error(util.errorArgs("BadMeta", 1, "Register", "Animation", tostring(util.Meta.Animation), tostring(getmetatable(animObj))));
	elseif (not eventName or type(eventName) ~= "string") then
		error(util.errorArgs("BadArg", 2, "Register", "string", type(eventName)));
	elseif (not callback or type(callback) ~= "function") then
		error(util.errorArgs("BadArg", 3, "Register", "function", type(eventName)));
	end
	self.Callbacks[animObj] = self.Callbacks[animObj] or {};
	self.Callbacks[animObj][eventName] = self.Callbacks[animObj][eventName] or {};
	table.insert(self.Callbacks[animObj][eventName], callback);
end

function MEventHandler:Fire(animObj, eventName)
	if (not animObj or not util.isType(animObj, "Animation")) then
		error(util.errorArgs("BadMeta", 1, "Fire", "Animation", tostring(util.Meta.Animation), tostring(getmetatable(animObj))));
	elseif (not eventName or type(eventName) ~= "string") then
		error(util.errorArgs("BadArg", 2, "Fire", "string", type(eventName)));
	end
	if (animObj and self.Callbacks[animObj] and eventName and self.Callbacks[animObj][eventName]) then
		for i = 1, #self.Callbacks[animObj][eventName] do
			self.Callbacks[animObj][eventName][i](self:GetActor(), animObj);
		end
	end
end

-- TODO: Support checks for animations playing backwards.
function MEventHandler:Check(animObj, keyTime)
	if (not animObj or type(animObj) ~= "table") then
		error(util.errorArgs("BadArg", 1, "Check", "table", type(animObj)));
	elseif (not util.isType(animObj, "Animation")) then
		error(util.errorArgs("BadMeta", 1, "Check", "Animation", tostring(util.Meta.Animation), tostring(getmetatable(animObj))));
	elseif (not keyTime or type(keyTime) ~= "number") then
		error(util.errorArgs("BadArg", 2, "Check", "number", type(keyTime)));
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