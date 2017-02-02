
local boner = require(LIBNAME);
local demina = require("examples.util.demina");
local newCharacter = require("examples.advanced.character");

-- Actor list
local NUM_ACTORS = 1; -- Increase for stress testing
local characters = {};
local curSkin = 1;
local toggleAnims = {"walk", "pump", "point"}

-- "pews"
local pews = {};

function love.load()
	local skeleton = demina.ImportSkeleton("examples/assets/guy/guy_default.anim");
	skeleton:GetBone("head"):SetLayer(skeleton:GetBone("head"):GetLayer()-3);
	skeleton:BuildRenderOrder(); -- must rebuild it if we modify layers.

	local animWalk = demina.ImportAnimation("examples/assets/guy/guy_walk.anim", skeleton);
	local animPump = demina.ImportAnimation("examples/assets/guy/guy_fistpump.anim", skeleton);

	local skinDefault = demina.ImportSkin("examples/assets/guy/guy_default.anim", skeleton);
	local skinGuy = demina.ImportSkin("examples/assets/guy/guy_skin.anim", skeleton);

	local point = function(transformer, transName, boneName)
		if (boneName == "back_upper_arm") then
			-- Get point direction
			local mx, my = love.mouse.getPosition();
			local bx, by = transformer:GetPosition(boneName);
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
			rot = transformer:GetFlippedAngle(rot);
			return {rotation = rot - math.pi/2};
		end
	end
	local shoot = function(transformer, transName, boneName)
		if (boneName == "back_lower_arm") then
			local vars = transformer:GetVariables(transName);
			if (vars.clickTime and love.timer.getTime() - vars.clickTime >= 0.1) then
				transformer:SetPower(transName, 0);
			end
			return {rotation = -math.pi/3};
		end
	end
	for i = 1, NUM_ACTORS do
		local c = newCharacter(skeleton);
		c:RegisterAnimation("walk", animWalk);

		c:RegisterAnimation("pump", animPump, skeleton:GetBoneList("front_upper_arm"));
		c:SetAnimationLayer("pump", 1);

		c:RegisterAnimation("point", point, skeleton:GetBoneList("back_upper_arm"));
		c:SetAnimationLayer("point", 1);

		c:RegisterAnimation("shoot", shoot, skeleton:GetBoneList("back_lower_arm"));
		c:SetAnimationLayer("shoot", 2);

		c:RegisterSkin("default", skinDefault);
		c:RegisterSkin("guy", skinGuy);

		c:SetSkin("guy");

		c:SetPosition(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2);

		c.Shoot = function(self)
			local vars = self.Actor:GetTransformer():GetVariables("shoot");
			vars.clickTime = vars.clickTime or 0;
			if (love.timer.getTime() - vars.clickTime > 0.5) then
				self.Actor:GetTransformer():SetPower("shoot", 1);
				vars.clickTime = love.timer.getTime();
			end
		end
		table.insert(characters, c);
	end
end

function love.draw()
	love.graphics.setColor(255, 255, 255, 255);
	for i = 1, #characters do
		characters[i]:Draw();
	end
end
function love.update(dt)
	for i = 1, #characters do
		characters[i]:Update(dt);
	end
end

function love.keypressed(key, isrepeat)
	if (tonumber(key) and toggleAnims[tonumber(key)]) then
		local animName = toggleAnims[tonumber(key)];
		for i = 1, #characters do
			local curState = characters[i]:GetAnimationState(animName);
			if (curState ~= "stopped") then
				characters[i]:EndAnimation(animName, 0.5);
				print("ending", characters[i]:GetAnimationState(animName));
			else
				characters[i]:StartAnimation(animName, 1);
				print("starting", characters[i]:GetAnimationState(animName));
			end
		end
	elseif (key == "space") then
		local animName = toggleAnims[tonumber(key)];
		for i = 1, #characters do
			for animName, _ in pairs(characters[i].Animations) do
				characters[i]:ToggleAnimationPlaying(animName);
			end
		end
	elseif (key == "d") then
		local settings = {};
		settings.boneLineColor = {0, 255, 0, 255};
		settings.boneTextColor = {255, 200, 0, 255};
		settings.attachmentLineColor = {255, 0, 0, 255};
		settings.attachmentTextColor = {0, 200, 255, 255};
		for i = 1, #characters do
			characters[i].Actor:SetDebug(characters[i].Actor:GetSkeleton():GetBoneList(), not characters[i].Actor:GetDebug(), settings);
		end
	elseif (key == "s") then
		for i = 1, #characters do
			local s = characters[i].Skins;
			local skins = {};
			for k, v in pairs(s) do
				table.insert(skins, k);
			end
			characters[i]:SetSkin(skins[(curSkin % #skins) + 1]);
		end
		curSkin = curSkin + 1;
	end
end

function love.mousepressed(x, y, button)
	if (button == 1) then
		for i = 1, #characters do
			characters[i]:Shoot();
		end
	end
end