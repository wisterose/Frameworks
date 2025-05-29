# Below is how i framework gui handling in most of my roblox games.
## All snippets below are from my co-owned game Salient Winds.

![image](https://github.com/user-attachments/assets/ec52d824-1ff3-4a0b-a184-074668c2d5e1)

First, I start with the good ol' client script in StarterPlayerScripts, and put a folder in it called "React"
Inside this folder is how I handle gui in most games. Any other folder can be for character joint editing, realism, etc etc.

Before I show how to handle the gui, I want to show you whats in the client script.

below is a some code that runs in the client script. This script loads modules using the Loader Module
I use the loader to load some folders in ReplicaatedFirst, ReplicatedStorage and StarterPlayerScrripts (even though I havent really used controllers in StarterPlayerScrripts).
The sharerd client folder at ReplicatedStorage.shared.Modules.SharedClient is where i store all my client side scripts. I initialize all the modules in here on the client so that they aare client only aand the server cant requrie them.

```
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Utility--
local Loader = require(ReplicatedStorage:WaitForChild("shared").Packages.Loader)
local TableUtil = require(ReplicatedStorage:WaitForChild("shared").Packages.TableUtil)

local ControllersFolder = script.Parent:WaitForChild("Controllers")
local ControllersFolder2 = ReplicatedStorage:WaitForChild("shared").Modules.SharedClient

--Remotes--
local RemoteFolder = ReplicatedStorage:WaitForChild("Events")
local DataFolder = RemoteFolder.Data

local PreloadFolder = RemoteFolder.Preloader
local PreloadComplete = PreloadFolder.PreloadComplete

local PreloadCompleteB = false

local function Load()
	print("Loading controllers...")
	Loader.SpawnAll(
		Loader.LoadDescendants(ControllersFolder, Loader.MatchesName("Controller$")),
		"OnStart"
	)

	Loader.SpawnAll(
		Loader.LoadDescendants(ControllersFolder2, Loader.MatchesName("Controller$")),
		"OnStart"
	)
	print("Controllers loaded successfully!")
end

if ControllersFolder and ControllersFolder2 then
	Load()
	
	local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
	Cmdr:SetActivationKeys({Enum.KeyCode.F2})
end
```

# Now, lets talk about whats under the client script.

![image](https://github.com/user-attachments/assets/61b766f7-8681-4944-a2ad-a165f55cecb0)

As you can see, I have loads of folders called components, and an initialize script that initializes the React Tree module.

Under the ReactInit localscript, I have the main gui root ill be using to store all of my games gui.

![image](https://github.com/user-attachments/assets/8ab2f0e6-397a-4462-83aa-c07183b6a7da)

nothing complex here, just using the React-Roblox module to initialize my gui root.

```
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage:WaitForChild("shared").Packages.React)
local ReactRoblox = require(ReplicatedStorage:WaitForChild("shared").Packages.ReactRoblox)

local ReactTree = require(script.Parent.Components._ReactTree)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local rootgui = script.ReactRoot:Clone()
rootgui.Parent = PlayerGui

local root = ReactRoblox.createRoot(rootgui)
root:render(React.createElement(ReactTree))

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

```

This localscript also initializes the react tree module.
I know the script below may feel overwhelming, and youre code does NOT have to be like this at all, just the setup. 

```
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

local React = require(ReplicatedStorage.shared.Packages.React)
local ClientLevelController = require(ReplicatedStorage.shared.Modules.SharedClient.ClientLevelController)

local LevelUI = require(script.Parent.LevelUI.LevelUI)
local LoadingScreen = require(script.Parent.LoadingScreen.LoadingScreen)
local AreaText = require(script.Parent.AreaText.AreaText)
local HealthOverlay = require(script.Parent.HealthOverlay.HealthOverlay)
local Navigation = require(script.Parent.Navigation.Navigation)
local SettingsPanel = require(script.Parent.SettingsPanel.SettingsPanel)
local Map = require(script.Parent.Map.Map)
local Hotbar = require(script.Parent.Hotbar.Hotbar)
local Dialogue = require(script.Parent.Dialogue.Dialogue)
local InventoryPanel = require(script.Parent.Inventory.Inventory)

local ClientSettingsController = require(ReplicatedStorage.shared.Modules.SharedClient.ClientSettingsController)
local ClientHudController = require(ReplicatedStorage.shared.Modules.SharedClient.ClientHudController)
local MenuController = require(ReplicatedStorage.shared.Modules.SharedClient.MenuController)
local CharacterController = require(ReplicatedStorage.shared.Modules.SharedClient.CharacterController)
local ClientInputController = require(ReplicatedStorage.shared.Modules.SharedClient.ClientInputController)
local InventoryController = require(ReplicatedStorage.shared.Modules.SharedClient.ClientInventoryController)

local LemonSignal = require(ReplicatedStorage.shared.Modules.LemonSignal)

local EventsF = ReplicatedStorage:WaitForChild("Events")
local DataFolder = EventsF:WaitForChild("Data")
local DataLoaded = LemonSignal.wrap(DataFolder.DataLoaded.OnClientEvent)

local RemoteFolder = ReplicatedStorage:WaitForChild("Events")
local PreloaderFolder = RemoteFolder:WaitForChild("Preloader")
local PreloadComplete = PreloaderFolder:WaitForChild("PreloadComplete")
local TeleportFolder = RemoteFolder:WaitForChild("Teleport", 5)
local TeleportingEvent = TeleportFolder:WaitForChild("Teleporting", 5)
local teleportCompleteEvent = TeleportFolder:FindFirstChild("TeleportComplete")

local LOADING_TIMEOUT = 15

return function()
	local Settings, setSettings = React.useState(nil)
	local settingsOpen, setSettingsOpen = React.useState(false)
	local preloadComplete, setPreloadComplete = React.useState(false)
	local dataComplete, setDataComplete = React.useState(false)
	local InventoryOpen, setInventoryOpen = React.useState(false)  -- Keep this for UI control
	local hasPlayedOnce, setHasPlayedOnce = React.useState(false)
	local forceTransition, setForceTransition = React.useState(false)
	local isTeleporting, setIsTeleporting = React.useState(false)

	local level, setLevel = React.useState(1)
	local currentExp, setCurrentExp = React.useState(0)
	local maxExp, setMaxExp = React.useState(100)
	local isLevelAnimating, setIsLevelAnimating = React.useState(false)
	local overlayTransparency, setOverlayTransparency = React.useState(1)
	local areaName, setAreaName = React.useState("")
	local mapOpen, setMapOpen = React.useState(false)
	local transitionComplete = React.useRef(false)
	local levelScrollFrameRef = React.createRef()

	React.useEffect(function()
		local levelUpConn = ClientLevelController.LeveledUp:Connect(function(newLevel)
			setLevel(newLevel)
		end)

		local expGainConn = ClientLevelController.ExperienceGain:Connect(function(remainingExp, expToNext)
			setCurrentExp(remainingExp)
			setMaxExp(expToNext)
		end)

		return function()
			levelUpConn:Disconnect()
			expGainConn:Disconnect()
		end
	end, {})

	React.useEffect(function()
		local spawnConn = CharacterController.OnCharacterSpawn:Connect(function()
			if hasPlayedOnce then
				ClientHudController:EnableStatBar()
			end
		end)

		return function()
			spawnConn:Disconnect()
		end
	end, {hasPlayedOnce})

	React.useEffect(function()
		local function onPreloadComplete()
			setPreloadComplete(true)
		end

		local conn = PreloadComplete.Event:Once(onPreloadComplete)

		task.spawn(function()
			if not preloadComplete then
				if PreloadComplete:GetAttribute("Completed") then
					setPreloadComplete(true)
				end
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, {})

	React.useEffect(function()
		if not TeleportingEvent then return end

		local teleportConn = TeleportingEvent.OnClientEvent:Connect(function(destination)
			setIsTeleporting(true)

			setMapOpen(false)

			task.delay(3, function()
				setIsTeleporting(false)
				teleportCompleteEvent:Fire()
			end)
		end)

		return function()
			teleportConn:Disconnect()
		end
	end, {})

	React.useEffect(function()
		local function onDataLoaded()
			local loadedSettings = ClientSettingsController:GetCurrentSettings()
			if loadedSettings then
				setSettings(loadedSettings)
			end
			setDataComplete(true)
		end

		local conn = DataLoaded:Once(onDataLoaded)

		task.spawn(function()
			local retryInterval = 0.5
			local maxRetries = 20
			local retryCount = 0

			while retryCount < maxRetries do
				local loadedSettings = ClientSettingsController:GetCurrentSettings()
				if loadedSettings then
					setSettings(loadedSettings)
					setDataComplete(true)
					break
				end
				task.wait(retryInterval)
				retryCount = retryCount + 1
			end

			if retryCount >= maxRetries then
				setDataComplete(true)
			end
		end)

		return function()
			conn:Disconnect()
		end
	end, {})

	React.useEffect(function()
		local mapConn = ClientInputController.MapActivatedSignal:Connect(function()
			setMapOpen(not mapOpen)
		end)

		local inventoryConn = ClientInputController.InventoryOpenActivatedSignal:Connect(function()
			local newState = not InventoryOpen
			setInventoryOpen(newState)
			print(InventoryOpen)
			InventoryController:ToggleInventory()
			print("inventoryopen caught")
		end)

		return function()
			mapConn:Disconnect()
			inventoryConn:Disconnect()
		end
	end, {mapOpen, InventoryOpen})

	React.useEffect(function()
		local inventorySignalConn = InventoryController.InventorySignal:Connect(function(isInventoryOpen)
			setInventoryOpen(isInventoryOpen)
		end)

		setInventoryOpen(InventoryController.IsInventoryOpen)

		return function()
			inventorySignalConn:Disconnect()
		end
	end, {})

	React.useEffect(function()
		local timeoutThread = task.delay(LOADING_TIMEOUT, function()
			setForceTransition(true)
		end)

		return function()
			task.cancel(timeoutThread)
		end
	end, {Settings, preloadComplete, dataComplete, forceTransition})

	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

	if not Settings then
		return React.createElement("ScreenGui", {
			Name = "MainUI",
			ResetOnSpawn = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			IgnoreGuiInset = true,
		})
	end

	return React.createElement("ScreenGui", {
		Name = "MainUI",
		ResetOnSpawn = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	}, {
		HealthOverlay = React.createElement(HealthOverlay, {
			hasPlayedOnce = hasPlayedOnce,
			characterController = CharacterController,
			overlayTransparency = overlayTransparency,
			refs = {overlayRef = React.createRef()}
		}),
		Navigation = React.createElement(Navigation, {
			settingsOpen = settingsOpen,
			setSettingsOpen = setSettingsOpen,
			setHasPlayedOnce = setHasPlayedOnce,
			hasPlayedOnce = hasPlayedOnce,
			clientHudController = ClientHudController,
			menuController = MenuController,
		}),
		SettingsPanel = React.createElement(SettingsPanel, {
			isOpen = settingsOpen,
			settings = Settings,
			setSettings = setSettings,
			clientSettingsController = ClientSettingsController,
		}),
		LevelUI = React.createElement(LevelUI, {
			hasPlayedOnce = hasPlayedOnce,
			currentExp = currentExp,
			maxExp = maxExp,
			level = level,
			setLevel = setLevel,
			setCurrentExp = setCurrentExp,
			setMaxExp = setMaxExp,
			isLevelAnimating = isLevelAnimating,
			setIsLevelAnimating = setIsLevelAnimating,
			levelScrollFrameRef = levelScrollFrameRef,
			clientLevelController = ClientLevelController,
		}),
		AreaText = React.createElement(AreaText, {
			areaName = areaName,
			setAreaName = setAreaName,
		}),
		LoadingScreen = React.createElement(LoadingScreen, {
			isLoading = not ((Settings and dataComplete and preloadComplete) or forceTransition) or isTeleporting,
			transitionComplete = transitionComplete,
			teleportingText = isTeleporting and "Teleporting..." or nil
		}),
		Map = React.createElement(Map, {
			mapOpen = mapOpen,
		}),
		Hotbar = React.createElement(Hotbar, {
			hasPlayedOnce = hasPlayedOnce,
		}),
		Inventory = InventoryOpen and React.createElement(InventoryPanel) or nil,
		DialogueUI = React.createElement(Dialogue)
	})
end

```

At the top here, we are requiring all of our components, each component module is independent and is very customizable and unique based on how it works.

![image](https://github.com/user-attachments/assets/255d2f26-ad8b-4e6f-9c16-246d08e8a1fb)

Make sure when you are doing this, make suer you return one function to the module.

![image](https://github.com/user-attachments/assets/def94aa4-8a76-41e1-a0d7-46a16729267b)

Im not gonna explain how to use react-roblox, but im sure you can figure it out reading the docs.
Here you can do pretty much anything based on how your games works, but using variables and useEffects are very useful when working with gui.

![image](https://github.com/user-attachments/assets/26e35396-eaab-4af5-8d36-78f2d76cca1b)


As you can see below, we are creating ONE main screen gui, and adding all of our ui component modules.
![image](https://github.com/user-attachments/assets/836ffbe8-cd2f-4881-80c4-04b44325292f)


We can pass in variables hich wll be caught in the return function of each component.

below is an example of one of my components. it returrns a functon with props as the firrst argument, whiich we are passing in from the ReactTree module.

![image](https://github.com/user-attachments/assets/2f2160f0-c495-4349-ab9a-f2a848a57c4d)

you can do whatever u want with theses prop variables, and it is very optimal to use eract like this.

That will be all for handling guis, if you have any questions please leave a comment. I will be postinig new files of NEW frameworks / Plugins i create for games.

[Get roblox util dependencies here](https://sleitnick.github.io/RbxUtil/)


credits to SleitNick for the dependencies !!!
