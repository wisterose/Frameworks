--[=[
	@class SmartQuest

	SmartQuest is a simple and extensible quest management system for Roblox.

	Supports:
	- Quest names and descriptions
	- Quest creation and expiration
	- Start/complete/fail conditions using signals
	- Objective tracking
	- Read-only external signal connection
	- Automatic cleanup via Trove

	:::info Ownership & Safety
	Quest ownership is set with `SetOwner` and all status transitions are locked behind internal checks. Only valid transitions are permitted.

	:::warning Internal Signals
	The module hides raw signals using weak-keyed `privateData` to prevent external tampering. All external interaction must go through `OnStart`, `OnComplete`, `OnFail`, or `OnObjectiveCompleted`.

	© 2025 Wisterose. All rights reserved.
	
	Date: 7/24/25 1:23 AM
	v0.3.5
]=]

--// Dependencies
local Trove = require(script.Dependencies.Trove)
local LemonSignal = require(script.Dependencies.LemonSignal)
local Settings = require(script.Settings)

--// Types
export type QuestId = string

export type QuestOptions = {
	QuestExpiration: number?, -- Optional expiration in seconds
	AllowIncompleteObjectivesOnComplete: boolean?, -- If true, allows quest to complete with incomplete objectives
	CompleteOnFinishedObjectives: boolean,
	Name: string?, -- Optional quest name
	Description: string?, -- Optional quest description
}

export type Quest = {
	QuestExpiration: number?,
	Name: string?,
	Description: string?,
	OnStart: { Connect: (self: any, callback: (...any) -> ()) -> LemonSignal.Connection },
	OnComplete: { Connect: (self: any, callback: (...any) -> ()) -> LemonSignal.Connection },
	OnFail: { Connect: (self: any, callback: (...any) -> ()) -> LemonSignal.Connection },
	OnObjectiveCompleted: { [string]: LemonSignal }, -- Signals for each objective
	Objectives: { [string]: "Incomplete" | "Complete" },
	QuestId: QuestId,
	QuestOwner: number?, -- UserId of owner
	Options: QuestOptions?,
	Status: "None" | "Started" | "Completed" | "Failed",
	MetaData: { [string]: any },
	_trove: any,
}

--// Module
local SmartQuest = {}
SmartQuest.__index = SmartQuest

local PlayerQuests: { [number]: { ActiveQuests: { [number]: Quest }, InactiveQuests: { [number]: Quest } } } = {}
local privateData = setmetatable({}, { __mode = "k" })

--[=[
	@within SmartQuest
	@function CreateId
	@return QuestId

	Creates a formatted quest ID string using `Settings.Format`.
]=]
function SmartQuest.CreateId(): QuestId
	local success, result = pcall(function()
		local id = ""
		for _, v in ipairs(string.split(Settings.Format, "")) do
			if v == "%" then continue end
			id ..= v
		end
		return id
	end)
	if success then
		return result
	else
		warn("SmartQuest.CreateId failed:", result)
		return "INVALID_ID"
	end
end

--[=[
	@within SmartQuest
	@function new
	@param id QuestId
	@param options QuestOptions?
	@return Quest

	Creates a new quest instance with optional behavior settings.
]=]
function SmartQuest.new(id: QuestId, options: QuestOptions?): Quest
	assert(typeof(id) == "string", "Must provide quest ID using SmartQuest.CreateId")

	local signals = {
		Start = LemonSignal.new(),
		Complete = LemonSignal.new(),
		Fail = LemonSignal.new(),
		OnStatusChanged = LemonSignal.new(),
	}

	local self = setmetatable({}, SmartQuest)
	self.QuestExpiration = options and options.QuestExpiration
	self.Objectives = {}
	self.OnObjectiveCompleted = {}

	self.QuestId = id
	self.QuestOwner = nil
	self.Options = {
		QuestExpiration = options and options.QuestExpiration or nil,
		AllowIncompleteObjectivesOnComplete = options and options.AllowIncompleteObjectivesOnComplete or false,
		CompleteOnFinishedObjectives = options and options.CompleteOnFinishedObjectives or false,
	}
	
	self.Name = options and options.Name or "Unnamed Quest"
	self.Description = options and options.Description or ""
	self.Status = "None"
	self.MetaData = {}
	self._trove = Trove.new()

	-- External-facing readonly signals
	self.OnStatusChanged  = {
		Connect = function(_, ...) return signals.OnStatusChanged:Connect(...) end,
	}

	self.OnStart = {
		Connect = function(_, ...) return signals.Start:Connect(...) end,
	}
	self.OnComplete = {
		Connect = function(_, ...) return signals.Complete:Connect(...) end,
	}
	self.OnFail = {
		Connect = function(_, ...) return signals.Fail:Connect(...) end,
	}

	privateData[self] = { signals = signals }

	return self
end

--[=[
	@within SmartQuest
	@function SetOwner
	@param player Player

	Sets the player that owns this quest. Required before starting.
]=]
function SmartQuest:SetOwner(player: Player)
	assert(player and player:IsA("Player"), "Owner must be a Player")
	assert(not self.QuestOwner, "Quest owner already set")

	self.QuestOwner = player.UserId

	PlayerQuests[player.UserId] = PlayerQuests[player.UserId] or {
		ActiveQuests = {},
		InactiveQuests = {},
	}
	table.insert(PlayerQuests[player.UserId].InactiveQuests, self)
end

--[=[
	@within SmartQuest
	@function BindReward
	@param callback () -> ()

	Invokes the callback when the quest completes.
]=]
function SmartQuest:BindReward(callback: () -> ())
	local priv = privateData[self]
	if priv then
		self._trove:Add(priv.signals.Complete:Connect(callback))
	end
end

--[=[
	@within SmartQuest
	@function StartOnSignal
	@param signal RBXScriptSignal
	@param check (...any) -> boolean

	Begins quest when the signal fires and passes the check.
]=]
function SmartQuest:StartOnSignal(signal, check)
	assert(signal and typeof(signal) == "RBXScriptSignal", "Invalid signal")
	assert(typeof(check) == "function", "Check must be a function")

	self._trove:Add(signal:Connect(function(...)
		if check(...) then
			self:Start()
		end
	end))
end

--[=[
	@within SmartQuest
	@function GetName

	Returns the name of a quest.
]=]
function SmartQuest:GetName(): string
	return self.Name or "Unnamed Quest"
end

--[=[
	@within SmartQuest
	@function GetDescription

	Returns the description of a quest.
]=]
function SmartQuest:GetDescription(): string
	return self.Description or ""
end

--[=[
	@within SmartQuest
	@function GetObjectives

	Returns all objectives within a quest.
]=]
function SmartQuest:GetObjectives(): { [string]: "Incomplete" | "Complete" }
	local copy = {}
	for k, v in pairs(self.Objectives) do
		copy[k] = v
	end
	return copy
end

--[=[
	@within SmartQuest
	@function CompleteOnSignal
	@param signal RBXScriptSignal
	@param check (...any) -> boolean

	Completes the quest when the signal passes the check.
]=]
function SmartQuest:CompleteOnSignal(signal, check)
	assert(signal and typeof(signal) == "RBXScriptSignal", "Invalid signal")
	assert(typeof(check) == "function", "Check must be a function")

	self._trove:Add(signal:Connect(function(...)
		if check(...) then
			self:Complete()
		end
	end))
end

--[=[
	@within SmartQuest
	@function FailOnSignal
	@param signal RBXScriptSignal
	@param check (...any) -> boolean

	Fails the quest if the signal fires and passes the check.
]=]
function SmartQuest:FailOnSignal(signal, check)
	assert(signal and typeof(signal) == "RBXScriptSignal", "Invalid signal")
	assert(typeof(check) == "function", "Check must be a function")

	self._trove:Add(signal:Connect(function(...)
		if check(...) then
			self:Fail()
		end
	end))
end

--[=[
	@within SmartQuest
	@function ObjectiveCompleteOnSignal
	@param signal RBXScriptSignal
	@param check (...any) -> boolean
	@param objectiveName string

	Marks an objective as complete when a signal passes the check.
	Automatically completes the quest if all objectives are done.
]=]
function SmartQuest:ObjectiveCompleteOnSignal(signal, check, objectiveName: string)
	assert(typeof(objectiveName) == "string", "Objective name must be a string")
	assert(signal and typeof(signal) == "RBXScriptSignal", "Invalid signal")
	assert(typeof(check) == "function", "Check must be a function")

	if not self.Objectives[objectiveName] then
		self.Objectives[objectiveName] = "Incomplete"
		self.OnObjectiveCompleted[objectiveName] = LemonSignal.new()
	end

	self._trove:Add(signal:Connect(function(...)
		if check(...) and self.Objectives[objectiveName] ~= "Complete" then
			self.Objectives[objectiveName] = "Complete"
			self.OnObjectiveCompleted[objectiveName]:Fire()

			-- Check if all objectives are completed
			local allDone = true
			for _, status in pairs(self.Objectives) do
				if status ~= "Complete" then
					allDone = false
					break
				end
			end
			
			if allDone and self.Status == "Started" and self.Options.CompleteOnFinishedObjectives then
				self:Complete()
			end
		end
	end))
end

--[=[
	@within SmartQuest
	@function Start
	Starts the quest. Moves it to the ActiveQuests list.
]=]
function SmartQuest:Start()
	if not self.QuestOwner or self.Status ~= "None" then return end
	
	local prevStatus = self.Status
	self.Status = "Started"
	
	local priv = privateData[self]
	if priv then priv.signals.Start:Fire() end
	if priv then priv.signals.OnStatusChanged:Fire(prevStatus, self.Status) end

	local record = PlayerQuests[self.QuestOwner]
	if record then
		table.remove(record.InactiveQuests, table.find(record.InactiveQuests, self))
		table.insert(record.ActiveQuests, self)
	end

	-- Auto-fail if expiration set
	if self.QuestExpiration then
		local cancel = false
		self._trove:Add(function() cancel = true end)

		task.delay(self.QuestExpiration, function()
			if not cancel and self.Status == "Started" then
				self:Fail()
			end
		end)
	end
end

--[=[
	@within SmartQuest
	@function Complete
	Completes the quest. Will warn if any objectives are still incomplete.
]=]
function SmartQuest:Complete()
	if not self.QuestOwner or self.Status ~= "Started" then return end

	if not (self.Options and self.Options.AllowIncompleteObjectivesOnComplete) then
		for _, status in pairs(self.Objectives) do
			if status ~= "Complete" then
				warn("Quest cannot be completed: incomplete objectives exist.")
				return
			end
		end
	end
	
	local prevStatus = self.Status
	self.Status = "Completed"
	
	local priv = privateData[self]
	if priv then priv.signals.Complete:Fire() end
	if priv then priv.signals.OnStatusChanged:Fire(prevStatus, self.Status) end

	self._trove:Clean()

	local quests = PlayerQuests[self.QuestOwner]
	if quests then
		table.remove(quests.ActiveQuests, table.find(quests.ActiveQuests, self))
	end
end

--[=[
	@within SmartQuest
	@function Fail
	Fails the quest and removes it from active quests.
]=]
function SmartQuest:Fail()
	if not self.QuestOwner or self.Status ~= "Started" then return end
	
	local prevStatus = self.Status
	self.Status = "Failed"
	
	local priv = privateData[self]
	if priv then priv.signals.Fail:Fire() end
	if priv then priv.signals.OnStatusChanged:Fire(prevStatus, self.Status) end

	local quests = PlayerQuests[self.QuestOwner]
	if quests then
		table.remove(quests.ActiveQuests, table.find(quests.ActiveQuests, self))
	end
end

--[=[
	@within SmartQuest
	@function Destroy
	Cleans up all signals and removes quest from memory.
]=]
function SmartQuest:Destroy()
	if self._trove then self._trove:Clean() end

	local quests = PlayerQuests[self.QuestOwner]
	if quests then
		for _, list in {quests.ActiveQuests, quests.InactiveQuests} do
			table.remove(list, table.find(list, self))
		end
	end

	privateData[self] = nil

	table.clear(self)
end

return SmartQuest
