
local SHARED = require("boner.shared");

--[[
	
--]]
local MEventHandler = SHARED.Meta.EventHandler;
MEventHandler.__index = MEventHandler;
local function newEventHandler(actor)
	local t = setmetatable({}, MEventHandler);
	t:SetActor(actor);
	t.Callbacks = {};
	t.Checked = {};
	--t.lastCheck = 0,
	--t.lastID = 1
	return t;
end

function MEventHandler:SetActor(actor)
	self.Actor = actor;
end
function MEventHandler:GetActor()
	return self.Actor;
end

function MEventHandler:Fire(animName, eventName)
	if (animName and self.Callbacks[animName] and eventName and self.Callbacks[animName][eventName]) then
		for i = 1, #self.Callbacks[animName][eventName] do
			--print("Fire callback",animName, eventName, i);
			self.Callbacks[animName][eventName][i](self:GetActor(), animName, eventName);
		end
	end
end
function MEventHandler:Register(animName, eventName, funcCallback)
	self.Callbacks[animName] = self.Callbacks[animName] or {};
	self.Callbacks[animName][eventName] = self.Callbacks[animName][eventName] or {};
	table.insert(self.Callbacks[animName][eventName], funcCallback);
end

function MEventHandler:Check(animObj, keyTime)
	-- No events for this anim? Do nothing.
	if (#animObj.Events == 0) then
		return;
	end
	
	-- Did we already checked for events on this animation this frame?
	if (self.Checked[animObj:GetName()] and self.Checked[animObj:GetName()] == keyTime) then
		--print("Attempted duplicate check", animObj:GetName(), keyTime);
		return;
	end
	self.Checked[animObj:GetName()] = self.Checked[animObj:GetName()] or 0;
	--print("Checking events", animObj:GetName(), keyTime);
	
	local events = animObj:GetEventsInRange(self.Checked[animObj:GetName()], keyTime);
	for i = 1, #events do
		--print("Checked for events in range", self.lastCheck, keyTime);
		self:Fire(animObj:GetName(), events[i].name);
	end
	
	--self.lastCheck = keyTime;
	self.Checked[animObj:GetName()] = keyTime;
end


return newEventHandler;