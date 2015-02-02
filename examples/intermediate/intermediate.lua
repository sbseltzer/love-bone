
local boner = require("boner");
local demina = require("examples.util.demina");
local newCharacter = require("examples.intermediate.character");

-- Actor list
local NUM_ACTORS = 1; -- Increase for stress testing
local characters = {};
local curSkin = 1;
local toggleAnims = {"walk", "pump"}

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
	
	for i = 1, NUM_ACTORS do
		local c = newCharacter(skeleton);
		c:RegisterAnimation("walk", animWalk);
		
		c:RegisterAnimation("pump", animPump, skeleton:GetBoneList("front_upper_arm"));
		c:SetAnimationLayer("pump", 1);
		
		c:RegisterSkin("default", skinDefault);
		c:RegisterSkin("guy", skinGuy);
		
		c:SetSkin("guy");
		
		c:SetPosition(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2);
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
				characters[i]:EndAnimation(animName, 2);
				print("ending", characters[i]:GetAnimationState(animName));
			else
				characters[i]:StartAnimation(animName, 0.5);
				print("starting", characters[i]:GetAnimationState(animName));
			end
		end
	elseif (key == " ") then
		local animName = toggleAnims[tonumber(key)];
		for i = 1, #characters do
			for animName, _ in pairs(characters[i].Animations) do
				characters[i]:ToggleAnimationPlaying(animName);
			end
		end
	elseif (key == "d") then
		boner.setDebug(not boner.getDebug());
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

function love.keyreleased(key)
	if (key == "escape") then
		love.event.quit();
	end
end