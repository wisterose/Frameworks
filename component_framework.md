# Component Management in Salient Winds

Below is how I handle a LOT of smaller things in my game including characters, trinket spawns, killparts, spawn locations, NPCs, areas, etc.  
It doesn't have to be small things — it can also be used to manage bigger systems too.

## Overview

All snippets below are from my co-owned game **Salient Winds**.

Credits to [**SleitNick**](https://sleitnick.github.io/RbxUtil/) for the utility dependencies.

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

Here’s a non-exhaustive list of what I manage using this setup:

- Characters
- Trinket spawns
- Killparts
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
Note that all components should be ran on the SERVER to prevent exploitation.

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


