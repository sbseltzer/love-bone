--[[
	Visual
	Used by Attachments as a wrapper/abstraction object for anything that could be used to render as an attachment.
	In most cases, the backing visual element will be some type of Drawable.
	The backing visual element could be an image, a particle emitter, a canvas, etc.
	We could even extend this to objects with a draw method (like our Actor object).
--]]

local util = RequireLibPart("util");

local MVisual = util.Meta.Visual;
MVisual.__index = MVisual;
local function newVisual(vis, ...)
	local t = setmetatable({}, MVisual);
	t:SetData(vis, ...);
	t:SetOrigin(0, 0);
	t:SetRotation(0);
	t:SetScale(1, 1);
	return t;
end

-- TODO: Add more things to this?
function MVisual:SetData(vis, ...)
	local validTypes = "string or userdata";
	if (vis == nil) then
		error(util.errorArgs("BadArg", 1, "SetData", validTypes, "nil"));
	end
	local vType = type(vis);
	-- Strings are assumed to be image paths
	if (vType == "string") then
		vis = love.graphics.newImage(vis);
	elseif (vType == "userdata") then
		-- ImageData will always be used for images
		if (vis:typeOf("ImageData")) then
			vis = love.graphics.newImage(vis);
		-- Any drawables can just be used as they are.
		elseif(not vis:typeOf("Drawable")) then
			error(util.errorArgs("BadArg", 1, "SetData", "Drawable", vis:type()));
		end
	else
		error(util.errorArgs("BadArg", 1, "SetData", validTypes, type(vis)));
	end
	-- Attempt to get a quad for texture types.
	local args = {...};
	if (vis.typeOf and (vis:typeOf("Texture") or vis:typeOf("SpriteBatch"))) then
		-- If there are 4 args after the visual data, we expect quad params.
		if (#args >= 4) then
			for i = 1, #args do
				if (not tonumber(args[i])) then
					error(util.errorArgs("BadArg", 1 + i, "SetData", "number", type(args[i])));
				end
			end
			self.Quad = love.graphics.newQuad(...);
		-- If there is 1 arg after the visual data, we expect a quad object.
		elseif (#args >= 1) then
			local quad = args[1];
			if (not quad or type(quad) ~= "userdata") then
				error(util.errorArgs("BadArg", 2, "SetData", "userdata", type(quad)));
			elseif (not quad:typeOf("Quad")) then
				error(util.errorArgs("BadArg", 2, "SetData", "Quad", quad:type()));
			end
			self.Quad = quad;
		end
	else
		self.Quad = nil;
	end
	self.Visual = vis;
end
function MVisual:GetData()
	return self.Visual, self.Quad;
end

function MVisual:GetDimensions()
	local vis, quad = self:GetData();
	if (quad) then
		local x, y, w, h = quad:getViewport();
		return w, h;
	elseif (type(vis) == "userdata") then
		if (vis:typeOf("Texture")) then
			return vis:getDimensions();
		elseif (vis:typeOf("ParticleSystem")) then
			local distribution, dx, dy = vis:getAreaSpread();
			local w, h = 1, 1;
			if (distribution ~= "none") then
				w = dx;
				h = dy;
			end
			return w*2, h*2;
		elseif (vis:typeOf("Mesh")) then
			local maxX, maxY, minX, minY = -1/0, -1/0, 1/0, 1/0;
			local verts = vis:getVertices();
			for i = 1, #verts, 8 do
				local x = verts[i];
				local y = verts[i+1]
				if x > maxX then
					maxX = x;
				elseif x < minX then
					minX = x;
				end
				if y > maxY then
					maxY = y;
				elseif y < minY then
					minY = y;
				end
			end
			return maxX - minX, maxY - minY;
		end
	end
	return 0, 0;
end

function MVisual:SetOrigin(x, y)
	if (not x or not tonumber(x)) then
		error(util.errorArgs("BadArg", 1, "SetOrigin", "number", type(x)));
	elseif (not y or not tonumber(y)) then
		error(util.errorArgs("BadArg", 2, "SetOrigin", "number", type(y)));
	end
	self.Origin = {x, y};
end
function MVisual:GetOrigin()
	return unpack(self.Origin);
end

function MVisual:SetRotation(angle)
	if (not angle or not tonumber(angle)) then
		error(util.errorArgs("BadArg", 1, "SetRotation", "number", type(angle)));
	end
	self.Rotation = angle;
end
function MVisual:GetRotation()
	return self.Rotation;
end

function MVisual:SetScale(x, y)
	if (not x or not tonumber(x)) then
		error(util.errorArgs("BadArg", 1, "SetScale", "number", type(x)));
	elseif (not y or not tonumber(y)) then
		error(util.errorArgs("BadArg", 2, "SetScale", "number", type(y)));
	end
	self.Scale = {x, y};
end
function MVisual:GetScale()
	return unpack(self.Scale);
end

function MVisual:Draw()
	local vis, quad = self:GetData();
	local x, y = 0, 0;
	local r = self:GetRotation();
	local sx, sy = self:GetScale();
	local ox, oy = self:GetOrigin();
	local params = {x, y, r, sx, sy, ox, oy};
	if (quad) then
		table.insert(params, 1, quad);
	end
	love.graphics.draw(vis, unpack(params));
end

return newVisual;