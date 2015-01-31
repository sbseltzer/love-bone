
local SHARED = require("boner.shared");
local newVisual = require("boner.visual");
local newAttachment = require("boner.attachment");
local newTransformer = require("boner.transformer");
local newEventHandler = require("boner.eventhandler");

local rotate = SHARED.rotate;
local lerp = SHARED.lerp;
local print_r = SHARED.print_r;

local SKELETON_ROOT_NAME = SHARED.SKELETON_ROOT_NAME;
local SKIN_ATTACHMENT_NAME = SHARED.SKIN_ATTACHMENT_NAME;

--[[
	Actor
	Actors are the top level structure for the systems.
	They contain a skeleton reference and do the actual animation calculations.
	They also have their own Attachment/Event handlers.
--]]
local MActor = SHARED.Meta.Actor;
MActor.__index = MActor;
MActor.Speed = 1;
MActor.TimeElapsed = 0;
MActor.State = "stopped";
local function newActor(skeleton, skinData)
	local t = setmetatable({}, MActor);
	
	-- Attachments (this includes skin)
	t.Attachments = {};
	
	-- Events
	t.EventHandler = newEventHandler(t);
	
	-- Transformer
	t.Transformer = newTransformer(t);
	
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

-- Skeleton reference
function MActor:SetSkeleton(skeleton)
	self.Skeleton = skeleton;
	self:GetTransformer():Initialize(skeleton);
end
function MActor:GetSkeleton()
	return self.Skeleton;
end

function MActor:SetAttachment(boneName, attachName, attachment)
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
	else
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

-- A helper function to setting skins.
function MActor:SetSkin(visuals)
	for boneName, visual in pairs(visuals) do
		if (SHARED.isMeta(visual, "Visual")) then
			print(boneName, visual);
			local attach = newAttachment();
			attach:SetVisual(visual);
			attach:SetRotation(0);
			attach:SetScale(1);
			self:SetAttachment(boneName, SKIN_ATTACHMENT_NAME, attach);
		end
	end
end

-- Drawing bones (used for debugging)
function MActor:DrawBones(transformed, boneColor, boneNameColor)
	boneColor = boneColor or {0, 255, 0, 255}
	local color = {love.graphics.getColor()};
	local renderOrder = self:GetSkeleton().RenderOrder;
	for i = 1, #renderOrder do
		local boneName = renderOrder[i];
		local boneData = transformed[boneName];
		local x0, y0 = unpack(boneData.translation);
		--love.graphics.circle("fill", x0, y0, 3, 4); -- Draw a dot at each bone origin
		-- Render names for bones.
		if (boneNameColor) then
			love.graphics.setColor(unpack(boneNameColor));
			love.graphics.print(boneName, x0, y0, boneData.rotation);
		end
		-- Render lines for bones.
		love.graphics.setColor(unpack(boneColor));
		if (boneData.parent and transformed[boneData.parent]) then
			local parentData = transformed[boneData.parent]
			x0, y0 = unpack(parentData.translation);
			local x1, y1 = unpack(boneData.translation);
			--print("Drawing parent bone:", x0, y0, x1, y1);
			love.graphics.line(x0, y0, x1, y1); -- Draw a line for parent bones
		end
	end
	love.graphics.setColor(unpack(color));
end

function MActor:GetAttachmentRenderOrder()
	local boneOrder = self:GetSkeleton().RenderOrder;
	local realOrder = {};
	--local attachOrders = {};
	for i = 1, #boneOrder do
		local boneName = boneOrder[i];
		local boneLayer = self:GetSkeleton():GetBone(boneName):GetLayer();
		local attachList = self:GetAttachmentList(boneName);
		if (attachList and #attachList > 0) then
			--attachOrders[boneName] = attachList;
			for j = 1, #attachList do
				local attachment = self:GetAttachment(boneName, attachList[j]);
				table.insert(realOrder, {boneName, attachment, boneLayer + attachment:GetLayerOffset()});
			end
		end
	end
	table.sort(realOrder, function(a, b)
		return a[3] < b[3];
	end);
	return realOrder;
end

function MActor:DrawAttachment(transformed, boneName, attachment)
	local boneData = transformed[boneName];
	love.graphics.push();
	-- Bone Transformations
	love.graphics.translate(unpack(boneData.translation));
	love.graphics.rotate(boneData.rotation);
	love.graphics.scale(unpack(boneData.scale));
	-- Attachment Transformations
	love.graphics.translate(attachment:GetTranslation());
	love.graphics.rotate(attachment:GetRotation());
	love.graphics.scale(attachment:GetScale());
	attachment:GetVisual():Draw();
	love.graphics.pop();
end

-- Draw the whole skin.
function MActor:DrawAttachments(transformed)
	local renderOrder = self:GetAttachmentRenderOrder();
	for i = 1, #renderOrder do
		local boneName, attachment = unpack(renderOrder[i]);
		self:DrawAttachment(transformed, boneName, attachment);
	end
end
function MActor:DrawAttachmentsDebug(transformed, boxColor)
	boxColor = boxColor or {0, 0, 255, 255};
	local color = {love.graphics.getColor()};
	love.graphics.setColor(unpack(boxColor));
	local renderOrder = self:GetSkeleton().RenderOrder;
	for i = 1, #renderOrder do
		local boneName = renderOrder[i];
		local boneData = transformed[boneName];
		if (self.Attachments[boneName]) then
			for attachName, attach in pairs(self.Attachments[boneName]) do
				local rBone = boneData.rotation;
				local txBone, tyBone = unpack(boneData.translation);
				local sxBone, syBone = unpack(boneData.scale);
				
				local rAttach = attach:GetRotation();
				local txAttach, tyAttach = attach:GetTranslation();
				local sxAttach, syAttach = attach:GetScale();
				
				local xOrig, yOrig = attach:GetVisual():GetOrigin();--attach:GetOrigin();
				
				-- Draw skin image outline:
				local width, height = attach:GetVisual():GetDimensions();
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
				love.graphics.rectangle("line", -xOrig, -yOrig, width, height);
				love.graphics.pop();
			end
		end
	end
	love.graphics.setColor(unpack(color));
end

function MActor:Draw()
	if (not self:GetSkeleton()) then
		return;
	end
	local transformed = self:GetTransformer().TransformGlobal;
	if (not transformed) then
		return;
	end
	self:DrawAttachments(transformed);
	if (SHARED.DEBUG) then
		self:DrawAttachmentsDebug(transformed);
		self:DrawBones(transformed, nil, {255, 200, 0});
	end
end

-- Update the animation.
function MActor:Update(dt)
	if (not self:GetSkeleton()) then
		return;
	end
	self:GetTransformer():CalculateLocal();
	self:GetTransformer():CalculateGlobal();
end

return newActor;