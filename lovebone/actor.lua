--[[
	Actor
	This is what ties everything together. 
	Each actor has a reference to a skeleton, its own transformer/eventhandler, and a list of attachments.
--]]

local util = RequireLibPart("util");
local newVisual = RequireLibPart("visual");
local newAttachment = RequireLibPart("attachment");
local newTransformer = RequireLibPart("transformer");
local newEventHandler = RequireLibPart("eventhandler");

local rotate = util.rotate;
local lerp = util.lerp;
local print_r = util.print_r;

local SKELETON_ROOT_NAME = util.SKELETON_ROOT_NAME;

local MActor = util.Meta.Actor;
MActor.__index = MActor;
local function newActor(skeleton, skinData)
	local t = setmetatable({}, MActor);
	
	-- Attachments (this includes skin)
	t.Attachments = {};
	
	-- Events
	t.EventHandler = newEventHandler(t);
	
	-- Transformer
	t.Transformer = newTransformer(t);
	
	t.Debug = {};
	
	if (skeleton) then
		t:SetSkeleton(skeleton);
	end
	if (skinData) then
		t:SetSkin(skinData);
	end
	
	return t;
end

function MActor:GetTransformer()
	return self.Transformer;
end
function MActor:GetEventHandler()
	return self.EventHandler;
end

function MActor:SetDebug(bones, enabled, settings)
	bones = bones or SKELETON_ROOT_NAME;
	enabled = enabled or false;
	settings = settings or {};
	if (type(bones) == "string") then
		bones = {bones};
	elseif (type(bones) ~= "table") then
		error(util.errorArgs("BadArg", 1, "SetDebug", "string or table", type(bones)));
	end
	for i = 1, #bones do
		self.Debug[bones[i]] = self.Debug[bones[i]] or {};
		self.Debug[bones[i]].enabled = enabled;
		self.Debug[bones[i]].settings = settings;
	end
end
function MActor:GetDebug(boneName)
	boneName = boneName or SKELETON_ROOT_NAME;
	return self.Debug[boneName].enabled, self.Debug[boneName].settings;
end

-- Skeleton reference
function MActor:SetSkeleton(skeleton)
	if (not skeleton or not util.isType(skeleton, "Skeleton")) then
		error(util.errorArgs("BadMeta", 1, "SetSkeleton", "Skeleton", tostring(util.Meta.Skeleton), tostring(getmetatable(skeleton))));
	end
	if (self.Skeleton ~= skeleton) then
		self.Debug = {};
		self:SetDebug(skeleton:GetBoneList(), false);
	end
	self.Skeleton = skeleton;
end
function MActor:GetSkeleton()
	return self.Skeleton;
end

function MActor:SetAttachment(boneName, attachName, attachment)
	if (not boneName or type(boneName) ~= "string") then
		error(util.errorArgs("BadArg", 1, "SetAttachment", "string", type(boneName)));
	elseif (not attachName or type(attachName) ~= "string") then
		error(util.errorArgs("BadArg", 2, "SetAttachment", "string", type(attachName)));
	elseif (not attachment or not util.isType(attachment, "Attachment")) then
		error(util.errorArgs("BadMeta", 3, "SetAttachment", "Attachment", tostring(util.Meta.Attachment), tostring(getmetatable(attachment))));
	end
	self.Attachments[boneName] = self.Attachments[boneName] or {};
	self.Attachments[boneName][attachName] = attachment;
end
function MActor:GetAttachment(boneName, attachName)
	if (self.Attachments[boneName]) then
		return self.Attachments[boneName][attachName];
	end
end

function MActor:GetAttachmentList(boneName)
	local t = {};
	if (boneName) then
		if (self.Attachments[boneName]) then
			for attachName, _ in pairs(self.Attachments[boneName]) do
				table.insert(t, attachName);
			end
		else
			return {};
		end
	else -- TODO: Drop support for this.
		for boneName, attachList in pairs(self.Attachments) do
			if (attachList) then
				for attachName, attach in pairs(attachList) do
					table.insert(t, {boneName, attachName, attach});
				end
			end
		end
	end
	return t;
end

-- TODO: We may want to cache this at some point.
function MActor:GetAttachmentRenderOrder()
	local boneOrder = self:GetSkeleton().RenderOrder;
	local realOrder = {};
	for i = 1, #boneOrder do
		local boneName = boneOrder[i];
		local boneLayer = self:GetSkeleton():GetBone(boneName):GetLayer();
		local attachList = self:GetAttachmentList(boneName);
		if (attachList and #attachList > 0) then
			for j = 1, #attachList do
				local attachment = self:GetAttachment(boneName, attachList[j]);
				table.insert(realOrder, {boneName, attachList[j], boneLayer + attachment:GetLayerOffset()});
			end
		end
	end
	local orderFunc = function(a, b)
		return a[3] < b[3];
	end;
	local flipH, flipV = self:GetTransformer().FlipH, self:GetTransformer().FlipV;
	if (flipH and not flipV or flipV and not flipH) then
		orderFunc = function(a, b)
			return a[3] > b[3];
		end;
	end
	table.sort(realOrder, orderFunc);
	return realOrder;
end

function MActor:DrawAttachment(transformed, boneName, attachName)
	local color = {love.graphics.getColor()};
	local boneData = transformed[boneName];
	local attachment = self:GetAttachment(boneName, attachName);
	local vis = attachment:GetVisual();
	
	if (not vis) then
		print("Invalid attachment:", boneName, attachName);
		return;
	end
	love.graphics.push();
	
	-- Bone Transformations
	love.graphics.translate(unpack(boneData.translation));
	love.graphics.rotate(boneData.rotation);
	love.graphics.scale(unpack(boneData.scale));
	
	-- Attachment Transformations
	love.graphics.translate(attachment:GetTranslation());
	love.graphics.rotate(attachment:GetRotation());
	love.graphics.scale(attachment:GetScale());
	
	love.graphics.setColor(attachment:GetColor());
	vis:Draw();
	
	love.graphics.pop();
	
	love.graphics.setColor(unpack(color));
end
function MActor:DrawAttachmentDebug(transformed, boneName, attachName, lineColor, textColor)
	lineColor = lineColor or {0, 0, 255, 255};
	textColor = textColor or {255, 200, 0};
	local color = {love.graphics.getColor()};
	
	local attachment = self:GetAttachment(boneName, attachName);
	local boneData = transformed[boneName];
	
	local rBone = boneData.rotation;
	local txBone, tyBone = unpack(boneData.translation);
	local sxBone, syBone = unpack(boneData.scale);
	
	local rAttach = attachment:GetRotation();
	local txAttach, tyAttach = attachment:GetTranslation();
	local sxAttach, syAttach = attachment:GetScale();
	
	local xOrig, yOrig = attachment:GetVisual():GetOrigin();
	
	-- Draw skin image outline:
	local width, height = attachment:GetVisual():GetDimensions();
	love.graphics.push();
	
	-- Bone Transformations
	love.graphics.translate(txBone, tyBone);
	love.graphics.rotate(rBone);
	love.graphics.scale(sxBone, syBone);
	
	-- Attachment Transformations
	love.graphics.translate(txAttach, tyAttach);
	love.graphics.rotate(rAttach);
	love.graphics.scale(sxAttach, syAttach);
	
	-- Draw debug box
	love.graphics.setColor(unpack(lineColor));
	love.graphics.rectangle("line", -xOrig, -yOrig, width, height);
	
	-- Draw debug text
	love.graphics.setColor(unpack(textColor));
	if (sxAttach ~= 0) then
		sxAttach = 1/sxAttach;
	end
	if (syAttach ~= 0) then
		syAttach = 1/syAttach;
	end
	love.graphics.scale(sxAttach, syAttach);
	love.graphics.print(boneName .. ":" .. attachName, -xOrig + width/2, -yOrig + height/2);
	
	love.graphics.pop();
	
	love.graphics.setColor(unpack(color));
end
function MActor:DrawBoneDebug(transformed, boneName, lineColor, textColor)
	lineColor = lineColor or {0, 255, 0, 255};
	textColor = textColor or {255, 200, 0};
	
	local color = {love.graphics.getColor()};
	local parentData = transformed[self:GetSkeleton():GetBone(boneName):GetParent()];
	local boneData = transformed[boneName];
	
	local sx, sy = unpack(parentData.scale);
	
	love.graphics.push();
	
	-- Bone Transformations
	love.graphics.translate(unpack(parentData.translation));
	love.graphics.rotate(parentData.rotation);
	love.graphics.scale(sx, sy);
	
	-- Draw debug line
	love.graphics.setColor(unpack(lineColor));
	local x, y = self:GetSkeleton():GetBone(boneName):GetOffset();
	love.graphics.line(0, 0, x, y);
	
	-- Draw debug text
	love.graphics.translate(x, y);
	love.graphics.rotate(-parentData.rotation + boneData.rotation);
	if (sx ~= 0) then
		sx = 1/sx;
	end
	if (sy ~= 0) then
		sy = 1/sy;
	end
	love.graphics.scale(sx, sy);
	
	love.graphics.setColor(unpack(textColor));
	love.graphics.print(boneName, 0, 0);
	
	love.graphics.pop();

	love.graphics.setColor(unpack(color));
end

function MActor:Draw()
	if (not self:GetSkeleton()) then
		return;
	elseif (not self:GetSkeleton():IsValid()) then
		print("Warning: Attempted to draw invalid skeleton!");
		return;
	end
	local transformed = self:GetTransformer().TransformWorld;
	if (not transformed) then
		return;
	end
	local debugBones = {};
	local renderOrder = self:GetAttachmentRenderOrder();
	for i = 1, #renderOrder do
		local boneName, attachName = unpack(renderOrder[i]);
		self:DrawAttachment(transformed, boneName, attachName);
		local enabled, settings = self:GetDebug(boneName);
		if (enabled) then
			table.insert(debugBones, {names=renderOrder[i],settings=settings});
		end
	end
	for i = 1, #debugBones do
		local boneName, attachName = unpack(debugBones[i].names);
		local settings = debugBones[i].settings;
		
		local lineColor, textColor;
		lineColor = settings.boneLineColor or {0, 0, 0, 0};
		textColor = settings.boneTextColor or {0, 0, 0, 0};
		self:DrawBoneDebug(transformed, boneName, lineColor, textColor);
		
		lineColor = settings.attachmentLineColor or {0, 0, 0, 0};
		textColor = settings.attachmentTextColor or {0, 0, 0, 0};
		self:DrawAttachmentDebug(transformed, boneName, attachName, lineColor, textColor);
	end
end

-- Update the animation.
function MActor:Update(dt)
	if (not self:GetSkeleton()) then
		return;
	elseif (not self:GetSkeleton():IsValid()) then
		print("Warning: Attempted to update invalid skeleton!");
		return;
	end
	self:GetTransformer():CalculateLocal();
	self:GetTransformer():CalculateWorld();
end

return newActor;