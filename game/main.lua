
local boner = require("boner");
local demina = require("demina");

local animTime = 0;
local bonedActors = {};
local NUM_ACTORS = 1;
local actorX, actorY;
local toggleTransforms = {
	"anim_main",
	"anim_gest",
	"anim_ctrl",
	"anim_zomg"
}
local pews = {}

local zomg = {bone="head", translation={0,0}, direction = -1};
local headScale = 1;
local curPart = 0;
local bodyParts = {};
function love.load()
	actorX, actorY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2;
	--ParseActor("guy_walk.anim");
	local skeleton = demina.ImportSkeleton("guy/guy_default.anim");
	skeleton:GetBone("head"):SetLayer(skeleton:GetBone("head"):GetLayer()-3);
	skeleton:BuildRenderOrder();
	demina.ImportAnimation("guy/guy_walk.anim", skeleton, "walk");
	demina.ImportAnimation("guy/guy_fistpump.anim", skeleton, "pump");
	demina.ImportSkin("guy/guy_default.anim", skeleton, "default");
	demina.ImportSkin("guy/guy_skin.anim", skeleton, "guy");
	local attachmentThing = boner.newAttachment();
	attachmentThing:SetLayerOffset(1);
	attachmentThing:SetVisual(boner.newVisual("guy/gun.png"));
	attachmentThing:SetScale(1.5, 1.5);
	attachmentThing:SetRotation(math.pi/2);
	local aw, ah = attachmentThing:GetVisual():GetDimensions();
	attachmentThing:GetVisual():SetOrigin(aw/10, ah/1.5);--attachmentThing:SetOrigin(aw/10, ah/1.5);
	
	--demina.ImportSkin("guy/test.tdict", skeleton, "default");
	for i = 1, NUM_ACTORS do
		local bonedActor = boner.newActor();
		bonedActor:SetSkeleton(skeleton);
		bonedActor:SetSkin("default");
		bonedActor:SetAttachment("back_hand", "gun", attachmentThing);
		--bonedActor.Transformer.FlipH = true;
		--bonedActor.Transformer.FlipV = true;
		bodyParts = bonedActor:GetAttachmentList();
		local point = function(b, k, fh)
			if (b == "back_upper_arm") then
				local mx, my = love.mouse.getPosition();
				local bx, by = bonedActor:GetBonePosition(b);
				bx = bx + actorX;
				by = by + actorY;
				local Ax, Ay = 1, 0;
				local Bx, By = mx - bx, my - by;
				local length = math.sqrt(math.pow(Bx, 2) + math.pow(By, 2));
				Bx = Bx/length;
				By = By/length;
				local dot = Ax * Bx + Ay * By;
				local rot = math.acos(dot);
				if (By < 0) then
					rot = -rot;
				end
				if (fh) then
					rot = math.pi - rot;
				end
				return {rotation = rot - math.pi/2};
			end
		end
		local shoot = function(b, k)
			if (b == "back_lower_arm") then
				if (bonedActor.clickTime and bonedActor.TimeElapsed - bonedActor.clickTime >= 0.1) then
					bonedActor:GetTransformer():SetPower("anim_shot", 0);
				end
				return {rotation = -math.pi/3};
			end
		end
		bonedActor:GetTransformer():RegisterObject("anim_main", "walk");
		bonedActor:GetTransformer():SetPriority("anim_main", skeleton:GetBoneTree("torso"), 0);
		bonedActor:GetTransformer():SetPower("anim_main", 0);
		
		bonedActor:GetTransformer():RegisterObject("anim_gest", "pump", skeleton:GetBoneTree("front_upper_arm"));
		bonedActor:GetTransformer():SetPriority("anim_gest", skeleton:GetBoneTree("front_upper_arm"), 1);
		bonedActor:GetTransformer():SetPower("anim_gest", 0);
		
		bonedActor:GetTransformer():RegisterObject("anim_ctrl", point, skeleton:GetBoneTree("back_upper_arm"));
		bonedActor:GetTransformer():SetPriority("anim_ctrl", skeleton:GetBoneTree("back_upper_arm"), 1);
		bonedActor:GetTransformer():SetPower("anim_ctrl", 0);
		
		bonedActor:GetTransformer():RegisterObject("anim_shot", shoot, skeleton:GetBoneTree("back_lower_arm"));
		bonedActor:GetTransformer():SetPriority("anim_shot", skeleton:GetBoneTree("back_lower_arm"), 2);
		bonedActor:GetTransformer():SetPower("anim_shot", 0);
		
		bonedActor:GetTransformer():RegisterObject("anim_zomg", zomg, skeleton:GetBoneTree("head"));
		bonedActor:GetTransformer():SetPriority("anim_zomg", skeleton:GetBoneTree("head"), 1);
		bonedActor:GetTransformer():SetPower("anim_zomg", 0);
		--[[
		bonedActor:GetTransformer():RegisterObject("flip", function(b, k)
			return {scale = {-1, 1}};
		end);
		bonedActor:GetTransformer():SetPower("flip", 1);
		bonedActor:GetTransformer():SetPriority("flip", skeleton:GetBoneTree("torso"), 0);]]
		
		local boomCallback = function(actor, animName, eventName)
			print(actor, animName, eventName);
			if (actor:GetTransformer():GetPower("anim_gest") > 0.8 and actor:GetTransformer():GetPower("anim_zomg") == 1) then
				if (zomg.translation[2] <= -100 and zomg.direction < 0) then
					zomg.direction = 1;
				elseif (zomg.translation[2] >= 0 and zomg.direction > 0) then
					zomg.direction = -1;
				end
				zomg.translation[2] = zomg.translation[2] + 10 * zomg.direction;
				print("BOOM", zomg.translation[2]);
			end
		end
		bonedActor:GetEventHandler():Register("pump", "boom", boomCallback);
		
		local stepSound = love.audio.newSource( "guy/step.wav" );
		local footDownCallback = function(actor, animName, eventName)
			--print(actor, animName, eventName);
			--if (actor:GetTransformer():GetPower("anim_main") > 0.2) then
				stepSound:setVolume(actor:GetTransformer():GetPower("anim_main"));
				stepSound:seek(0.1);
				stepSound:play();
			--end
		end
		bonedActor:GetEventHandler():Register("walk", "foot_down", footDownCallback);
		
		bonedActor:SetSpeed(1);
		bonedActor:Start();
		table.insert(bonedActors, bonedActor);
	end
end

function love.draw()
	love.graphics.setColor(0, 255, 0, 255);
	for i = 1, #pews do
		local x, y = unpack(pews[i].pos);
		love.graphics.printf("PEW", x, y, 3, "center", pews[i].rot, 2, 2);
	end
	love.graphics.setColor(255, 255, 255, 255);
	for i = 1, #bonedActors do
		love.graphics.push();
		--love.graphics.translate((love.graphics.getWidth() / #bonedActors) * i, 200 + (i % 2) * 400);
		love.graphics.translate(actorX, actorY);
		--love.graphics.scale(1, -1)
		bonedActors[i]:Draw();
		love.graphics.pop();
	end
	--love.graphics.circle("fill", 0, 0, 10);
end

local increasePower = {};
function love.update(dt)
	for i = 1, #bonedActors do
		bonedActors[i]:Update(dt);
		for transName, direction in pairs(increasePower) do
			bonedActors[i]:GetTransformer():SetPower(transName, bonedActors[i]:GetTransformer():GetPower(transName) + direction * dt);
		end
	end
	for i = 1, #pews do
		local x, y = unpack(pews[i].pos);
		pews[i].pos[1] = x + pews[i].dir[1] * pews[i].speed * dt;
		pews[i].pos[2] = y + pews[i].dir[2] * pews[i].speed * dt;
	end
	if (#pews > 0) then
		--print(pews[#pews].dir[1],pews[#pews].dir[2])
	end
end

local blendThings = 0;
local curSkin = 0;
function love.keypressed(key, isrepeat)
	if (key == " ") then
		for i = 1, #bonedActors do
			if (bonedActors[i].State ~= "playing") then
				bonedActors[i]:Start();
			else
				bonedActors[i]:Pause();
			end
		end
	elseif (key == "v") then
		for i = 1, #bonedActors do
			bonedActors[i]:GetTransformer().FlipV = not bonedActors[i]:GetTransformer().FlipV;
			--[[if (bonedActors[i].State == "playing") then
				bonedActors[i]:Pause();
			else
				bonedActors[i]:Start();
			end]]
		end
	elseif (key == "h") then
		for i = 1, #bonedActors do
			bonedActors[i]:GetTransformer().FlipH = not bonedActors[i]:GetTransformer().FlipH;
			--[[if (bonedActors[i].State == "playing") then
				bonedActors[i]:Pause();
			else
				bonedActors[i]:Start();
			end]]
		end
	elseif (key == "r") then
		for i = 1, #bonedActors do
			if (bonedActors[i].State ~= "stopped") then
				bonedActors[i]:Stop();
			else
				bonedActors[i]:Start();
			end
		end
	elseif (key == "e") then
		for i = 1, #bonedActors do
			--if (bonedActors[i].State ~= "playing") then
				bonedActors[i].TimeElapsed = bonedActors[i].TimeElapsed + 0.1;
			--end
		end
	elseif (key == "q") then
		for i = 1, #bonedActors do
			--if (bonedActors[i].State ~= "playing") then
				bonedActors[i].TimeElapsed = bonedActors[i].TimeElapsed - 0.1;
			--end
		end
	elseif (key == "d") then
		boner.setDebug(not boner.getDebug());
	elseif (key == "y") then
		if (blendThings < 3) then
			blendThings = blendThings + 0.5;
		end
	elseif (key == "t") then
		if (blendThings > 0) then
			blendThings = blendThings - 0.5;
		end
	elseif (tonumber(key) and toggleTransforms[tonumber(key)]) then
		for i = 1, #bonedActors do
			local name = toggleTransforms[tonumber(key)];
			increasePower[name] = increasePower[name] or -1;
			increasePower[name] = increasePower[name] * -1;
		end
	--[[elseif (string.sub(key, 1, 1) == "f" and string.len(key) > 1) then
		local num = tonumber(string.sub(key, 2));
		if (num and toggleTransforms[num]) then
			for i = 1, #bonedActors do
				local name = toggleTransforms[num];
				local enabled = bonedActors[i]:GetTransformer():GetPower(name) ~= 0;
				if (not enabled) then
					bonedActors[i]:GetTransformer():SetPower(name, 1);
				else
					bonedActors[i]:GetTransformer():SetPower(name, 0);
				end
			end
		end]]
	elseif (key == "f") then
		for i = 1, #bonedActors do
			local attach = bonedActors[i]:GetAttachment("back_hand", "gun");
			if (attach:GetScale() > 0) then
				attach:SetScale(0, 0);
			else
				attach:SetScale(1.5, 1.5);
			end
		end
	elseif (key == "x") then
		for i = 1, #bonedActors do
			local attachID = (curPart % #bodyParts) + 1;
			local attachData = bodyParts[attachID];
			print(curPart, #bodyParts, attachID, attachData[1], attachData[2]);
			local attach = attachData[3];
			bonedActors[i]:SetAttachment("head", "__skin__", attach);
			curPart = curPart + 1;
		end
	elseif (key == "z") then
		for i = 1, #bonedActors do
			local attachID = (curPart % #bodyParts) + 1;
			local attachData = bodyParts[attachID];
			print(curPart, #bodyParts, attachID, attachData[1], attachData[2]);
			local attach = attachData[3];
			bonedActors[i]:SetAttachment("head", "__skin__", attach);
			curPart = curPart - 1;
		end
	elseif (key == "s") then
		for i = 1, #bonedActors do
			local skins = bonedActors[i]:GetSkeleton().Skins;
			local skinList = {};
			for k, v in pairs(skins) do
				table.insert(skinList, k);
			end
			bonedActors[i]:SetSkin(skinList[(curSkin % #skinList) + 1]);
			curSkin = curSkin + 1;
		end
	elseif (key == "up") then
		zomg.translation[2] = zomg.translation[2] - 5;
	elseif (key == "down") then
		zomg.translation[2] = zomg.translation[2] + 5;
	elseif (key == "left") then
		zomg.translation[1] = zomg.translation[1] - 5;
	elseif (key == "right") then
		zomg.translation[1] = zomg.translation[1] + 5;
	end
end

function love.keyreleased(key)
	if (key == "escape") then
		love.event.quit();
	end
end

function love.mousepressed(x, y, button)
	if (button == "l") then
		for i = 1, #bonedActors do
			local attach = bonedActors[i]:GetAttachment("back_hand", "gun");
			if (attach:GetScale() > 0 and bonedActors[i]:GetTransformer():GetPower("anim_ctrl") == 1 and (not bonedActors[i].clickTime or bonedActors[i].TimeElapsed - bonedActors[i].clickTime > 0.5)) then
				
				local sx, sy = bonedActors[i]:GetAttachmentScale("back_hand", "gun");
				local oX, oY = attach:GetVisual():GetOrigin();
				local w, h = attach:GetVisual():GetDimensions();
				if (bonedActors[i]:GetTransformer().FlipH) then
					oX = -oX;
					oY = -oY;
					w = -w;
					h = -h;
				end
				local gunX, gunY = bonedActors[i]:GetAttachmentPosition("back_hand", "gun", {-oX*sx + w*sx, -oY*sy + (h/10)*sy})
				gunX = gunX + actorX;
				gunY = gunY + actorY;
				
				local armX, armY = bonedActors[i]:GetBonePosition("back_upper_arm");
				armX = armX + actorX;
				armY = armY + actorY;
				
				local dirX, dirY = x - armX, y - armY;
				local length = math.sqrt(math.pow(dirX,2) + math.pow(dirY,2));
				dirX = dirX / length;
				dirY = dirY / length;
				
				local p = {
					pos = {gunX, gunY},
					rot = bonedActors[i]:GetBoneAngle("back_hand") + math.pi/2,
					dir = {dirX, dirY},
					speed = 100
				}
				table.insert(pews, p);
				
				bonedActors[i].clickTime = bonedActors[i].TimeElapsed;
				bonedActors[i]:GetTransformer():SetPower("anim_shot", 1);
			end
		end
	end
end

function love.mousereleased(x, y, button)
	if (button == "l") then
	
	elseif(button == "r") then
		
	end
end
