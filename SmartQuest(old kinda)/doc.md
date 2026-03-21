# SmartQuest
**Version 0.3.5** **Author:** Wisterose  

SmartQuest is a hardened, signal based quest management system designed for highperformance roblox environments. It prioritizes data integrity and memory safety through the use of weakkeyed private storage and automatic lifecycle cleanup via Trove.

---

## Core Architecture

SmartQuest utilizes a **Private Data Pattern**. Internal signals for status transitions (Start, Complete, Fail) are stored in a scoped table indexed by the quest instance itself. This ensures that external scripts can listen to quest events but cannot spoof or fire them, maintaining a server-authoritative flow.

### Key Features
* **Status Locking:** Prevents invalid state transitions (e.g., completing a quest that hasn't started).
* **Signal Abstraction:** Wraps raw signals in a read-only interface to protect internal states.
* **Trove Integration:** Built-in garbage collection for all connections, tasks, and instances.
* **Objective Chaining:** Automatically evaluates quest completion based on specific objective states.

---

## API Reference

### Constructor
`SmartQuest.new(id: string, options: QuestOptions)`  
Initializes a new quest instance. Requires a unique ID string.

### State Management
* `SetOwner(player: Player)`: Registers the quest to a specific UserId. This is required before calling `Start()`.
* `Start()`: Activates the quest and begins the expiration timer if defined in options.
* `Complete()`: Finalizes the quest. Validates that all mandatory objectives are met unless `AllowIncompleteObjectivesOnComplete` is enabled.
* `Fail()`: Terminates the quest immediately and triggers cleanup logic.

### Objective Tracking
`ObjectiveCompleteOnSignal(signal: RBXScriptSignal, check: function, objectiveName: string)`  
Binds a specific quest objective to an engine or custom signal. The `check` function acts as a filter; the objective only marks as "Complete" if the check returns true.

---

## Implementation Example

```lua
local SmartQuest = require(ReplicatedStorage.Systems.SmartQuest)

-- Configuration
local quest = SmartQuest.new(SmartQuest.CreateId(), {
    Name = "Wrench Retrieval",
    Description = "Find the missing tools to fix the bike.",
    CompleteOnFinishedObjectives = true,
    QuestExpiration = 300 -- 5 minutes
})

quest:SetOwner(Player)

-- Connect to an item pickup event
quest:ObjectiveCompleteOnSignal(ItemEvents.OnPickup, function(itemName)
    return itemName == "AdjustableWrench"
end, "FindWrench")

-- Bind reward logic
quest:BindReward(function()
    print("Awarding currency and unlocking the next mission.")
end)

quest:Start()
