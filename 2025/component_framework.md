# Component Management in Salient Winds

Below is how I handle a LOT of smaller things in my game including characters, trinket spawns, kill parts, spawn locations, NPCs, areas, etc.  
It doesn't have to be small things — it can also be used to manage bigger systems too.

## Overview

All snippets below are from my co-owned game **Salient Winds**.

Credits to [**Sleitnick**](https://sleitnick.github.io/RbxUtil/) for the utility dependencies.

## Dependencies

Make sure you have [RbxUtil](https://sleitnick.github.io/RbxUtil/) installed.  
I rely on some utility modules from there for shared logic and component structure.

## Folder Setup

In `ReplicatedStorage`, I have a shared folder with my `Components` folder inside.  
This folder is imported as a **package link**.

> 📦 **Learn more about Package Links**:  
> [https://create.roblox.com/docs/reference/engine/classes/PackageLink](https://create.roblox.com/docs/reference/engine/classes/PackageLink)

## Example Folder Structure

![image](https://github.com/user-attachments/assets/f6e88b8a-6fff-4bb5-98e4-c9aca4117c88)


Replace the above image with a screenshot of your actual folder structure by uploading it to your GitHub repo or using [Imgur](https://imgur.com/).

## What This System Manages

Here's a non-exhaustive list of what I manage using this setup:

- Characters
- Trinket spawns
- Kill parts
- Spawn locations
- NPCs
- Area triggers
- ...and more

Each of these is a **component** that can be initialized, started, stopped, or managed independently.

## Benefits

- Reusability across many systems
- Centralized logic for spawning, behavior, and interaction
- Components are plug-and-play across the world

---

Now that we have the folder setup, we can look into how the handler for it works.
Note that all components should be run on the SERVER to prevent exploitation.

Here is our services folder
![image](https://github.com/user-attachments/assets/7d68a0d7-17ed-4b50-ad9c-c113e76696d6)

We will now access a module service called ComponentService, which initializes all the components on the SERVER

here is the code (you do not have to read through all of it, there will be snippets below the screenshot)

```local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local LemonSignal = require(ReplicatedStorage.shared.Modules.LemonSignal)

local ComponentService = {}
ComponentService._components = {}
ComponentService.ComponentsLoaded = LemonSignal.new()

local ComponentFolder = ReplicatedStorage.shared.Modules.Components

for _, moduleScript in ipairs(ComponentFolder:GetChildren()) do
	if moduleScript:IsA("ModuleScript") then
		local success, ComponentClass = pcall(require, moduleScript)
		if success and typeof(ComponentClass) == "table" and ComponentClass.Start then
			table.insert(ComponentService._components, ComponentClass)

			if ComponentClass.Start ~= nil then
				ComponentClass:Start()
			end
		else
			warn("[ComponentService] Failed to load component:", moduleScript.Name, ComponentClass)
		end
	end
end

ComponentService.ComponentsLoaded:Fire()

function ComponentService:GetComponent(instance: Instance, ComponentClass)
	if typeof(ComponentClass) ~= "table" or not ComponentClass.GetFromInstance then
		warn("[ComponentService] Invalid component class passed to GetComponent")
		return nil
	end

	local c = ComponentClass:GetFromInstance(instance)
	if c then
		return c
	end
end

return ComponentService
```

At the top, we are using [pcall](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#pcall) to require all the component modules in the folder on the SERVER.
![image](https://github.com/user-attachments/assets/208dfb99-bcae-4eb6-8ac4-456965185889)

We then fire our components loaded event to any other server-side script that is willing to catch it using [LemonSignal](https://github.com/Data-Oriented-House/LemonSignal)
![image](https://github.com/user-attachments/assets/3106f95b-8375-4820-88a4-68c79cceae11)
![image](https://github.com/user-attachments/assets/0b881766-51b1-4312-a3ba-40a905cd0941)

You can get the Sleitnick component module from the dependencies listed at the top.
Next I will show you how to set up the component modules themselves using the module from Sleitnick.


```
--@author: wisterose
--@date: 5/8/25

local RunService = game:GetService("RunService")
if not RunService:IsServer() then
	return warn("Cannot require a component on the client.")
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Util
local LemonSignal = require(ReplicatedStorage.shared.Modules.LemonSignal)
local Trove = require(ReplicatedStorage.shared.Packages.Trove)
local Component = require(ReplicatedStorage.shared.Packages.Component)
local TableUtil = require(ReplicatedStorage.shared.Packages.TableUtil)
local CharacterVerification = require(ServerStorage.ServerChecks.CharacterVerification)
local PlayerVerification = require(ServerStorage.ServerChecks.PlayerVerification)

local function verifyPlayer(player: Player): boolean
	local success, result = pcall(PlayerVerification, player)
	return success and result
end

local function verifyCharacter(character: Model): boolean
	local success, result = pcall(CharacterVerification, character)
	return success and result
end

-- Optional: Replace with your own folders or services
local KillPartFolder = Workspace:FindFirstChild("KillParts")

for _, killPart in pairs(KillPartFolder:GetDescendants()) do
	if killPart:IsA("Instance") then
		killPart:SetAttribute("Valid_KillPart", true)
		killPart:AddTag("Valid_KillPart")
	end
end

-- Logger Extension
local Logger = {}
function Logger.ShouldConstruct(component)
	if component.Instance:IsA("Instance") and component.Instance:IsA("Part") then
		return component.Instance:GetAttribute("Valid_KillPart") == true -- Replace if needed
	end
end

local KillpartComponent = Component.new({
	Tag = "Valid_KillPart",
	Ancestors = {KillPartFolder},
	Extensions = {Logger},
})

local constructedComponents = {}

function KillpartComponent:Construct()
	self.Trove = Trove.new()
	print("KillpartComponent Constructed:", self.Instance)
	table.insert(constructedComponents, self)
end

function KillpartComponent:GetFromInstance(instance: Instance)
	for _, component in pairs(constructedComponents) do
		if component.Instance == instance then
			return component
		end
	end
	print("Instance not found")
	return nil
end

function KillpartComponent:Start()
	for _, component in pairs(constructedComponents) do
		if component and component.Instance :: Part | Instance then
			self.Trove:Connect(component.Instance.Touched, function(touchPart)
				if touchPart then
					for _, charmodel in pairs(workspace.Humanoids:GetChildren()) do
						if charmodel:IsA("Model") then
							if touchPart:IsDescendantOf(charmodel) then
								local Player = Players:GetPlayerFromCharacter(charmodel)
								if verifyPlayer(Player) and verifyCharacter(charmodel) then
									local Humanoid = charmodel:FindFirstChildOfClass("Humanoid")
									if Humanoid then
										Humanoid:TakeDamage(Humanoid.MaxHealth or 9e9)
									end
								end
							end
						end
					end
				end
			end)
		end
	end
end

function KillpartComponent:Stop()
	self.Trove:Destroy()
	print("KillpartComponent Stopped:", self.Instance)
end

return KillpartComponent
```

At the top, we are requiring our component module from Sleitnick.
![image](https://github.com/user-attachments/assets/4b58ad56-e46e-471e-9fe5-8e5364668a9d)

Next, we have our logger and the component creation
![image](https://github.com/user-attachments/assets/1996770c-fbf9-43a2-9fb1-c9ca245fb99c)

Our logger is basically its own table with a function attached to it, the method used is specifically named from the options listed in the documentation of the Sleitnick component module.
For now we will use "ShouldConstruct", which will return a boolean telling the constructor whether to make a new component for this object or not.

In the ShouldConstruct check for instance, since it's a kill part component, we will check if the part(component.Instance) has the attribute "Valid_KillPart", to make sure it's valid.
You can really add anything you want to this function as long as it returns a boolean.

Next, we create our component using ```local KillPartComponent = Component.new({})```

We will pass in 3 Arguments, "Tag", "Ancestors" and "Extensions".
For our tag, it will tag the instance with whatever we give it.
For our ancestors we pass in the folder, model, instance, part or whatever the components' instance is a descendant of.
For our extensions we pass in the logger.

Next, we create a table that will hold our currently constructed components, you do not have to do this but this is how I set it up
![image](https://github.com/user-attachments/assets/c10ad381-fbd3-46c1-82d7-5b7dcadbf380)

As you see, it's nothing much, I just create a new trove using the trove module.
I then insert the newly constructed component into the constructedComponents table.

From there you can have pretty much any function you want, if you want to add checks, getting an instance from components, etc.
Just make sure you have a :Start function and a :Stop function, in the start function you pretty much initialize whatever it is for your component, and the stop function, you cleanup any connections, etc.

Here I am Initializing the kill part, and connecting the touch events, I then destroy the trove in the :Stop function.

![image](https://github.com/user-attachments/assets/f39873d4-cfb1-4c4b-8049-62f78f49eca8)


# Why This Approach Matters

- Server authority — logic executes only on the server, shielding it from exploiters.

- Single responsibility — each object type (trinket, NPC, kill part) lives in its own module, reducing cross‑system bugs.

- Hot‑swapping — adding a new feature is as simple as tagging an instance and writing one module; no master script edits are required.

- Maintainability — the Components folder is versioned through a PackageLink, so updates stay in sync and rollbacks are easy.

- Performance — components construct only when a tagged instance exists, avoiding unnecessary polling or heartbeat loops.

## This structure keeps the codebase organised, secure, and modular while scaling smoothly as the game grows.
