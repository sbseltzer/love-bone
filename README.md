# BÖNER - WIP

A 2D Skeletal Animation framework for LÖVE.

## Usage

Require the [library](https://github.com/GeekWithALife/boner/tree/master/game/boner):

```lua
local boner = require 'boner'
```

And that's that.

## Table of Contents

* [Introduction](#introduction)
* [Elements](#elements)
  * [Button](#button)
    * [Base attributes](#base-attributes)
    * [Methods](#methods)
    * [Basic button drawing](#basic-button-drawing)
  * [Frame](#frame)
    * [Base attributes](#base-attributes-1)
    * [Close attributes](#close-attributes)
    * [Drag attributes](#drag-attributes)
    * [Resize attributes](#resize-attributes)
    * [Methods](#methods-1)
    * [Basic frame drawing](#basic-frame-drawing)
  * [Textinput](#textinput)
    * [Base attributes](#base-attributes-2)
    * [Text attributes](text-attributes)
    * [Methods](#methods-2)
    * [Basic textinput drawing](#basic-textinput-drawing)
* [Extensions](#extensions)
* [Themes](#themes)

## Introduction

## Objects


### Actor

Actors are what ties everything together.  They must hold a reference to a skeleton definition before they can be used.

```lua
local myActor = boner.newActor(skeleton);
...
myActor:SetAnimation(animName);
```

To use them, you must call their update and draw methods.

```lua
function love.update(dt)
	myActor:Update(dt);
end
function love.draw()
	myActor:Draw();
end
```

### Skeleton

Every actor needs a skeleton.  Skeletons never change state.  They are merely a reference for actors so they know what their bone structure looks like and what skins/animations are available to them.

```lua
local skeleton = boner.newSkeleton();
skeleton:AddBone(bone);
...
skeleton:Validate();
```

### Bone

Bones are objects that are used to create skeletons.

```lua
local bone = boner.newBone(name, parent, layer, offset, defaultRotation, defaultTranslation, defaultScale);
```

### Animation

Animations are a convenient way to apply transformations to your actors.

```lua
local animation = boner.newAnimation(animName, skeleton);
animation:AddKeyFrame(boneName, keyTime, rotation, translation, scale);
...
skeleton:AddAnimation(animation);
```

### Visual

Visuals are an abstraction for visible elements. They could be an image, a canvas, a particle emitter, and much more!

```lua
local visual;
visual = boner.newVisual(texturePath | imageData | image | canvas, quad | x, y, w, h)
visual = boner.newVisual(mesh)
visual = boner.newVisual(particleEmitter)

local vw, vh = visual:GetDimensions();
visual:SetOrigin(vw/2, vh/2);
```

### Attachment

Attachments are used to attach a Visual object to a bone on an Actor. Skins are simply attachments without any special transformations applied to them.

```lua
local attachment = boner.newAttachment(visual);
myActor:SetAttachment(boneName, attachName, attachment);
```

### EventHandler

Every actor has an EventHandler automatically created for them. You can use it to register event callbacks.

```lua
myActor:GetEventHandler():Register(animName, eventName, funcCallback);
```

### Transformer

Every actor has a Transformer automatically created for them. You use it to register bone transformations. This includes animations.

```lua
myActor:GetTransformer():Register(transformName, animName | transformTable | transformFunc, boneMask);
myActor:GetTransformer():SetPriotity(transformName, priority);
myActor:GetTransformer():SetPower(transformName, power);
```