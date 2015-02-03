
local boner = require("boner");
local demina = require("examples.util.demina");

-- Actor list
local NUM_ACTORS = 1; -- Increase for stress testing
local bonedActors = {};

-- Animation blending
local toggleTransforms = {
	"anim_main",
	"anim_gest",
	"anim_ctrl",
	"anim_zomg"
}
local increasePower = {};

-- "pews"
local pews = {};

-- Transformation table binding
local zomg = {object = {head = {translation={0,0}}}, direction = -1};

-- Skin cycling
local curSkin = 1;

-- Attachment cycling
local curPart = 0;
local bodyParts = {};

function love.load()

	local skeleton = demina.ImportSkeleton("examples/assets/guy/guy_default.anim");
	skeleton:GetBone("head"):SetLayer(7); -- Corrected head layer.
	skeleton:BuildRenderOrder(); -- must rebuild the render order if we modify layers.
	
	local animWalk = demina.ImportAnimation("examples/assets/guy/guy_walk.anim", skeleton);
	local animPump = demina.ImportAnimation("examples/assets/guy/guy_fistpump.anim", skeleton);
	local skinDefault = demina.ImportSkin("examples/assets/guy/guy_default.anim", skeleton);
	local skinGuy = demina.ImportSkin("examples/assets/guy/guy_skin.anim", skeleton);
	
	local gun = boner.newVisual("examples/assets/guy/gun.png");
	local aw, ah = gun:GetDimensions();
	gun:SetOrigin(aw/10, ah/1.5);
	
	local attachmentThing = boner.newAttachment(gun);
	attachmentThing:SetLayerOffset(1);
	attachmentThing:SetScale(1.5, 1.5);
	attachmentThing:SetRotation(math.pi/2);
	
	--demina.ImportSkin("guy/test.tdict", skeleton, "default");
	local actorX, actorY = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2;
	for i = 1, NUM_ACTORS do
		local bonedActor = boner.newActor(skeleton);
		bonedActor.Skins = {skinDefault, skinGuy};
		bonedActor.SetSkinAttachments = function(self, skinData)
			for boneName, visual in pairs(skinData) do
				if (boner.isType(visual, "Visual")) then
					local attach = boner.newAttachment(visual);
					self:SetAttachment(boneName, "skin", attach);
				end
			end
		end
		bonedActor:SetSkinAttachments(skinDefault);
		local root = bonedActor:GetTransformer():GetRoot();
		root.translation[1] = actorX;
		root.translation[2] = actorY;
		bonedActor:SetAttachment("back_hand", "gun", attachmentThing);
		bodyParts = bonedActor:GetAttachmentList();
		local point = function(actor, boneName, vars)
			if (boneName == "back_upper_arm") then
				local parentName = actor:GetSkeleton():GetBone(boneName):GetParent();
				local parentAngle = actor:GetTransformer():GetAngle(parentName);
				
				-- Get point direction
				local mx, my = love.mouse.getPosition();
				local bx, by = actor:GetTransformer():GetPosition(boneName);
				local Ax, Ay = 1, 0;
				local Bx, By = mx - bx, my - by;
				local length = math.sqrt(math.pow(Bx, 2) + math.pow(By, 2));
				Bx = Bx/length;
				By = By/length;
				
				-- Get point angle
				local dot = Ax * Bx + Ay * By;
				local rot = math.acos(dot);
				if (By < 0) then
					rot = -rot;
				end
				
				-- Account for flipping.
				rot = rot + actor:GetTransformer():GetAngle();
				local sx, sy = actor:GetTransformer():GetScale();
				rot = rot * (sy/math.abs(sy));
				
				return {rotation = rot - math.pi/2};
			end
		end
		local shoot = function(actor, boneName)
			if (boneName == "back_lower_arm") then
				if (actor.clickTime and love.timer.getTime() - actor.clickTime >= 0.1) then
					actor:GetTransformer():SetPower("anim_shot", 0);
				end
				return {rotation = -math.pi/3};
			end
		end
		
		local transformer = bonedActor:GetTransformer();
		
		transformer:Register("anim_main", animWalk);
		--bonedActor:GetTransformer():SetPriority("anim_main", skeleton:GetBoneList("torso"), 0);
		transformer:SetPower("anim_main", 0);
		
		transformer:Register("anim_gest", animPump, skeleton:GetBoneList("front_upper_arm"));
		transformer:SetPriority("anim_gest", skeleton:GetBoneList("front_upper_arm"), 1);
		transformer:SetPower("anim_gest", 0);
		
		transformer:Register("anim_ctrl", point, skeleton:GetBoneList("back_upper_arm"));
		transformer:SetPriority("anim_ctrl", skeleton:GetBoneList("back_upper_arm"), 1);
		transformer:SetPower("anim_ctrl", 0);
		
		transformer:Register("anim_shot", shoot, skeleton:GetBoneList("back_lower_arm"));
		transformer:SetPriority("anim_shot", skeleton:GetBoneList("back_lower_arm"), 2);
		transformer:SetPower("anim_shot", 0);
		
		transformer:Register("anim_zomg", zomg.object, skeleton:GetBoneList("head"));
		transformer:SetPriority("anim_zomg", skeleton:GetBoneList("head"), 1);
		transformer:SetPower("anim_zomg", 0);
		
		local boomCallback = function(actor, animName, eventName)
			if (actor:GetTransformer():GetPower("anim_gest") > 0.8 and actor:GetTransformer():GetPower("anim_zomg") == 1) then
				if (zomg.object.head.translation[2] <= -100 and zomg.direction < 0) then
					zomg.direction = 1;
				elseif (zomg.object.head.translation[2] >= 0 and zomg.direction > 0) then
					zomg.direction = -1;
				end
				zomg.object.head.translation[2] = zomg.object.head.translation[2] + 25 * zomg.direction;
			end
		end
		bonedActor:GetEventHandler():Register(animPump, "boom", boomCallback);
		
		local stepSound = love.audio.newSource( "examples/assets/guy/step.wav" );
		local footDownCallback = function(actor, animName, eventName)
			--print(actor, animName, eventName);
			--if (actor:GetTransformer():GetPower("anim_main") > 0.2) then
				stepSound:setVolume(actor:GetTransformer():GetPower("anim_main"));
				stepSound:seek(0.1);
				stepSound:play();
			--end
		end
		if (i == 1) then
			bonedActor:GetEventHandler():Register(animWalk, "foot_down", footDownCallback);
		end
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
		--love.graphics.translate(actorX, actorY);
		--love.graphics.scale(1, -1)
		bonedActors[i]:Draw();
		love.graphics.pop();
	end
	--love.graphics.circle("fill", 0, 0, 10);
end
function love.update(dt)
	for i = 1, #bonedActors do
		local transformer = bonedActors[i]:GetTransformer();
		for transformName, vars in pairs(transformer:GetVariables()) do
			if (not boner.isType(transformer:GetTransform(transformName), "Animation") or not vars.paused) then
				local direction = increasePower[transformName] or 0;
				transformer:SetPower(transformName, transformer:GetPower(transformName) + direction * dt);
			end
			if (boner.isType(transformer:GetTransform(transformName), "Animation") and transformer:GetPower(transformName) > 0 and not vars.paused) then
				vars.time = vars.time + dt;
			end
		end
		bonedActors[i]:Update(dt);
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

function love.keypressed(key, isrepeat)
	print("pressed", key);
	if (tonumber(key) and toggleTransforms[tonumber(key)]) then
		local name = toggleTransforms[tonumber(key)];
		increasePower[name] = increasePower[name] or -1;
		increasePower[name] = increasePower[name] * -1;
	elseif (key == " ") then
		for i = 1, #bonedActors do
			local transformer = bonedActors[i]:GetTransformer();
			for transformName, vars in pairs(transformer:GetVariables()) do
				if (boner.isType(transformer:GetTransform(transformName), "Animation")) then
					vars.paused = not vars.paused;
				end
			end
		end
	elseif (key == "v") then
		for i = 1, #bonedActors do
			bonedActors[i]:GetTransformer().FlipV = not bonedActors[i]:GetTransformer().FlipV;
		end
	elseif (key == "h") then
		for i = 1, #bonedActors do
			bonedActors[i]:GetTransformer().FlipH = not bonedActors[i]:GetTransformer().FlipH;
		end
	elseif (key == "w") then
		for i = 1, #bonedActors do
			--if (bonedActors[i].State ~= "playing") then
			local vars;
			vars = bonedActors[i]:GetTransformer():GetVariables("anim_main");
			vars.time = vars.time + 0.1;
			vars = bonedActors[i]:GetTransformer():GetVariables("anim_gest");
			vars.time = vars.time + 0.1;
			print(vars.time);
			--end
		end
	elseif (key == "q") then
		for i = 1, #bonedActors do
			--if (bonedActors[i].State ~= "playing") then
			local vars;
			vars = bonedActors[i]:GetTransformer():GetVariables("anim_main");
			vars.time = vars.time - 0.1;
			vars = bonedActors[i]:GetTransformer():GetVariables("anim_gest");
			vars.time = vars.time - 0.1;
			print(vars.time);
			--end
		end
	elseif (key == "r") then
		for i = 1, #bonedActors do
			--if (bonedActors[i].State ~= "playing") then
			local vars;
			vars = bonedActors[i]:GetTransformer():GetVariables("anim_main");
			vars.speed = vars.speed + 0.1;
			vars = bonedActors[i]:GetTransformer():GetVariables("anim_gest");
			vars.speed = vars.speed + 0.1;
			print(vars.speed);
			--end
		end
	elseif (key == "e") then
		for i = 1, #bonedActors do
			--if (bonedActors[i].State ~= "playing") then
			local vars;
			vars = bonedActors[i]:GetTransformer():GetVariables("anim_main");
			vars.speed = vars.speed - 0.1;
			vars = bonedActors[i]:GetTransformer():GetVariables("anim_gest");
			vars.speed = vars.speed - 0.1;
			print(vars.speed);
			--end
		end
	elseif (key == "d") then
		local settings = {};
		settings.boneLineColor = {0, 255, 0, 255};
		settings.boneTextColor = {255, 200, 0, 255};
		settings.attachmentLineColor = {255, 0, 0, 255};
		settings.attachmentTextColor = {0, 200, 255, 255};
		for i = 1, #bonedActors do
			bonedActors[i]:SetDebug(bonedActors[i]:GetSkeleton():GetBoneList(), not bonedActors[i]:GetDebug(), settings);
		end
		--boner.setDebug(not boner.getDebug());
	elseif (key == "f") then
		for i = 1, #bonedActors do
			local attach = bonedActors[i]:GetAttachment("back_hand", "gun");
			attach:SetRotation(attach:GetRotation() + math.rad(15));
			if (attach:GetScale() > 0) then
				attach:SetScale(0, 0);
			else
				attach:SetScale(1.5, 1.5);
			end
		end
	elseif (key == "a") then
		for i = 1, #bonedActors do
			local attachID = (curPart % #bodyParts) + 1;
			local attachData = bodyParts[attachID];
			print(curPart, #bodyParts, attachID, attachData[1], attachData[2]);
			local attach = attachData[3];
			bonedActors[i]:SetAttachment("head", "skin", attach);
		end
		curPart = curPart + 1;
	elseif (key == "z") then
		for i = 1, #bonedActors do
			local attachID = (curPart % #bodyParts) + 1;
			local attachData = bodyParts[attachID];
			print(curPart, #bodyParts, attachID, attachData[1], attachData[2]);
			local attach = attachData[3];
			bonedActors[i]:SetAttachment("head", "skin", attach);
			curPart = curPart - 1;
		end
	elseif (key == "s") then
		for i = 1, #bonedActors do
			local skins = bonedActors[i].Skins;
			bonedActors[i]:SetSkinAttachments(skins[(curSkin % #skins) + 1]);
		end
		curSkin = curSkin + 1;
	elseif (key == "up") then
		zomg.object.head.translation[2] = zomg.object.head.translation[2] - 5;
	elseif (key == "down") then
		zomg.object.head.translation[2] = zomg.object.head.translation[2] + 5;
	elseif (key == "left") then
		zomg.object.head.translation[1] = zomg.object.head.translation[1] - 5;
	elseif (key == "right") then
		zomg.object.head.translation[1] = zomg.object.head.translation[1] + 5;
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
			if (attach:GetScale() > 0 and bonedActors[i]:GetTransformer():GetPower("anim_ctrl") == 1 and (not bonedActors[i].clickTime or love.timer.getTime() - bonedActors[i].clickTime > 0.5)) then
				
				local sx, sy = bonedActors[i]:GetTransformer():GetScale("back_hand", "gun");
				local w, h = attach:GetVisual():GetDimensions();
				local fx, fy = bonedActors[i]:GetTransformer():GetForward("back_hand", "gun");
				local ux, uy = bonedActors[i]:GetTransformer():GetUp("back_hand", "gun");
				h = h * 0.6;
				local offset = {sx * ((fx * w) + (ux * h)), sy * ((fy * w) + (uy * h))};
				--print(fx, fy);
				local gunX, gunY = bonedActors[i]:GetTransformer():GetPosition("back_hand", "gun")
				gunX = gunX + offset[1]
				gunY = gunY + offset[2]
				
				local armX, armY = bonedActors[i]:GetTransformer():GetPosition("back_upper_arm");
				
				-- TODO: Figure out why using fx and fy doesn't work right.
				local dirX, dirY = x - armX, y - armY;
				local length = math.sqrt(math.pow(dirX,2) + math.pow(dirY,2));
				dirX = dirX / length;
				dirY = dirY / length;--[[]]
				
				local pewspeed = 100;
				local p = {
					pos = {gunX, gunY},
					rot = bonedActors[i]:GetTransformer():GetAngle("back_hand", "gun"),
					dir = {dirX, dirY},
					speed = pewspeed
				}
				local maxpews = 10 * NUM_ACTORS;
				if (#pews < maxpews) then
					table.insert(pews, p);
				else
					pews.index = pews.index or 0;
					pews.index = (pews.index % maxpews);
					pews.index = pews.index + 1;
					pews[pews.index] = p;
				end
				bonedActors[i].clickTime = love.timer.getTime();
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
