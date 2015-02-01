--[[
	Internal library utilities.
--]]

local SKELETON_ROOT_NAME = "__root__"; -- In conventional animation systems, this would be the root scene node.
local SKIN_ATTACHMENT_NAME = "__skin__"; -- In conventional animation systems, this would be the root scene node.
local DEBUG = false;

-- Metatables
local Meta = {
	Bone = {},
	Skeleton = {},
	Animation = {},
	Actor = {},
	Visual = {},
	Attachment = {},
	Transformer = {},
	EventHandler = {}
};

-- Returns true if the metatable for t matches the metatable associated with mName. 
local function isMeta(obj, mName)
	return type(obj) == "table" and getmetatable(obj) == Meta[mName];
end

-- Error checking utilities
local Error = {
	BadArg = "bad argument #%d to '%s' (%s expected, got %s)",
	BadMeta = "bad argument #%d to '%s' (%s[%s] expected, got [%s])",
};
local function errorArgs(errorType, ...)
	return string.format(Error[errorType], ...), 2;
end

-- Linear Interpolation function.
local function lerp(v0, v1, t)
	return (1-t)*v0 + t*v1;
end

-- Rotation function.
local function rotate(cx, cy, angle, px, py)
	local s = math.sin(angle);
	local c = math.cos(angle);

	-- translate point back to origin:
	px = px - cx;
	py = py - cy;

	-- rotate point
	local xnew = px * c - py * s;
	local ynew = px * s + py * c;

	-- translate point back:
	px = xnew + cx;
	py = ynew + cy;
	
	-- If we don't like rounding error (mostly for debug purposes)
	--[[if (epsilon) then
		local floating = math.abs(px) - math.floor(math.abs(px));
		if (floating <= epsilon) then
			px = math.floor(px);
		elseif (floating >= 1-epsilon) then
			px = math.ceil(px);
		end
		floating = math.abs(py) - math.floor(math.abs(py));
		if (floating <= epsilon) then
			py = math.floor(py);
		elseif (floating >= 1-epsilon) then
			py = math.ceil(py);
		end
	end]]
	return px, py;
end

-- Debug helper.
local function print_r(t, i, found)
	i = i or 1;
	if (i == 1) then
		print("{");
	end
	found = found or {};
	local tabs = string.rep("  ", i);
	found[t] = true;
	for k, v in pairs(t) do
		if (type(v) == "table") then
			if (found[v]) then
				print(tabs .. tostring(k) .. " : <parent>");
			else
				print(tabs .. tostring(k) .. " :");
				print(tabs .. "{");
				print_r(v, i + 1, found);
				print(tabs .. "}");
			end
		else
			print(tabs .. tostring(k) .. " : " .. tostring(v));
		end
	end
	if (i == 1) then
		print("}");
	end
end

return {DEBUG = DEBUG, SKELETON_ROOT_NAME = SKELETON_ROOT_NAME, SKIN_ATTACHMENT_NAME = SKIN_ATTACHMENT_NAME, 
		Meta = Meta, isMeta = isMeta, errorArgs = errorArgs,
		lerp = lerp, rotate = rotate, 
		print_r = print_r};