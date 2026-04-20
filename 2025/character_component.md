# Character Component & Status System in Salient Winds

This document explains how the character component system manages status effects (like burn, stun, etc.) in a modular and efficient way.

## Overview

All snippets below are from my co-owned game **Salient Winds**.

Credits to [**Sleitnick**](https://sleitnick.github.io/RbxUtil/) for the utility dependencies.

## Dependencies

Make sure you have [RbxUtil](https://sleitnick.github.io/RbxUtil/) installed.  
I rely on some utility modules from there for shared logic and component structure.


The character component system consists of two main parts:
1. The character component handler
2. Individual status effect modules

## Component Structure

Here's how the folders are structured:
[INSERT IMAGE OF YOUR CHARACTER COMPONENT FOLDER STRUCTURE HERE - Like the one you shared]

## Character Component Handler

The character component is responsible for managing all status effects on a character. It uses Sleitnick's component system and includes:

- Status tracking
- Effect application/removal
- Duration management
- Attribute handling

### Component Setup

The component uses a logger extension to verify humanoids:

![image](https://github.com/user-attachments/assets/bfc7f925-b152-447a-8036-0537b6d236db)


### Status Management Functions

The component provides several key functions for status handling:

1. **AddStatus**: Applies a new status effect
   - Validates the status module
   - Creates a new instance
   - Sets up attributes
   - Handles cleanup

2. **RemoveStatus**: Removes an active status
   - Cleans up connections
   - Removes attributes
   - Stops the status effect

3. **Status Duration Control**:
   - ProlongStatus: Extends status duration
   - ShortenStatus: Reduces status duration
   - HasStatus: Checks if a status is active

## Status Effect Module Example (Burn)

Let's look at how a status effect module (Burn) is structured:

### Burn Effect Setup

![image](https://github.com/user-attachments/assets/3afd9fd6-3dab-4eb6-9173-9dd97b0e7b8d)


### Core Features

1. **Configuration**:
   - Duration control
   - Damage values
   - Visual effects
   - Roll cancellation

2. **Effect Management**:
   - Damage ticking
   - Visual effects
   - Attribute updates
   - Player verification

### Effect Lifecycle
![image](https://github.com/user-attachments/assets/89dc926f-1b8c-4995-8810-ec2b7e2f67e0)

![image](https://github.com/user-attachments/assets/2023de75-16df-4c6e-9368-f8802749f130)


The burn effect includes:
- Damage over time
- Visual effects
- Roll cancellation after delay
- Cleanup on removal

### Effect Replication

![image](https://github.com/user-attachments/assets/0d9c690e-2a03-4dbb-a15f-136245f165fe)


The effect is replicated to:
- The affected player
- Nearby players (radius-based)
- With custom visual parameters

## Best Practices

1. **Status Validation**
   - Always verify status modules exist
   - Check for required functions
   - Validate configurations

2. **Cleanup**
   - Properly disconnect all connections
   - Remove attributes
   - Clear visual effects

3. **Duration Management**
   - Use prolong/shorten for duration changes
   - Keep attributes updated
   - Handle edge cases

4. **Effect Replication**
   - Use radius-based replication
   - Include necessary effect parameters
   - Handle network efficiency

## Usage Example

```lua
-- Getting a character component
local character = workspace.Humanoids.SomeCharacter
local component = CharacterComponent:GetFromInstance(character)

-- Applying a burn status
component:AddStatus("Burn", {
    Duration = 5,
    Damage = 2,
    EffectColor = Color3.fromRGB(255, 0, 0),
    Rollable = true
})

-- Removing a status
component:RemoveStatus("Burn")
```

## Security Considerations

1. All status effects run server-side
2. Player verification before damage
3. Attribute-based state tracking
4. Protected cleanup methods

This system provides a robust way to manage character states and effects while maintaining security and performance.



# Status Effect Service System

This document explains how the StatusEffectService manages and coordinates status effects across the game, working in tandem with the ComponentService.

## System Overview

The StatusEffectService acts as a central manager for:
- Character verification
- Status effect requests
- Status checking
- Remote communication

Key dependencies include:
- LemonSignal for event handling
- Component system for character management
- Verification modules for security
- PlayerDataService for data management

### Remote Events Structure

```lua
ReplicatedStorage/
└── Events/
    └── Status/
        ├── StatusRequest (RemoteEvent)
        └── HasStatusRequest (RemoteFunction)
```

## Core Functionality

### Character Initialization
![image](https://github.com/user-attachments/assets/b5423832-76b8-4c05-918b-7642973e130c)


When a player's data loads:
1. Binds to CharacterAdded
2. Verifies the player and character
3. Tags the character as "Verified_Humanoid"
4. Moves character to HumanoidFolder

### Status Effect Request Handling

The service handles two types of requests:

1. **Status Application Request**
   ```lua
   StatusRequest.OnServerEvent:Connect(function(player, requestData)
   ```
   - Validates request data
   - Checks player verification
   - Verifies character state
   - Handles both self and target applications
   - Includes distance checking for target effects

2. **Status Check Request**
   ```lua
   HasStatusRequest.OnServerInvoke = function(player, requestData)
   ```
   - Returns status state and configuration
   - Includes timing information
   - Provides full status configuration

### Status Effect Application

![image](https://github.com/user-attachments/assets/22ecc58c-c44e-404e-bdfb-ed45254c18f1)


The StatusEffect function:
1. Gets the character component
2. Validates component existence
3. Executes the requested method
4. Handles configuration passing

## Component Service Integration

  ![image](https://github.com/user-attachments/assets/255fc0d3-f111-4b0e-8573-abfd467a32b7)

The ComponentService:
1. Loads all components on startup
2. Manages component lifecycle
3. Provides component access
4. Handles error cases

### Component Loading Process

```lua
ComponentFolder = ReplicatedStorage.shared.Modules.Components

for _, moduleScript in ComponentFolder:GetChildren() do
    -- Component loading and initialization
end
```

### Component Access

```lua
function ComponentService:GetComponent(instance: Instance, ComponentClass)
    -- Component retrieval logic
end
```

## Security Measures

1. **Player Verification**
   - Checks player validity
   - Verifies character ownership
   - Validates request authenticity

2. **Distance Checking**
   ```lua
   local distance = (character.PrimaryPart.Position - requestData.Target.PrimaryPart.Position).Magnitude
   if distance <= 10 then
       -- Allow effect application
   end
   ```

3. **Character Validation**
   - Ensures characters are properly tagged
   - Verifies component existence
   - Checks parent hierarchy

## Usage Examples

### Applying a Status Effect
```lua
StatusEffectService:StatusEffect(
    character,
    "Burn",
    "AddStatus",
    {
        Duration = 5,
        Damage = 2
    }
)
```

### Checking Status State
```lua
local statusInfo = HasStatusRequest:InvokeServer({
    Target = targetCharacter,
    StatusName = "Burn"
})
```

## Best Practices

1. **Request Validation**
   - Always validate request data
   - Check player and character states
   - Verify distances for targeted effects

2. **Component Management**
   - Use ComponentService for access
   - Validate component existence
   - Handle missing components gracefully

3. **Error Handling**
   - Proper warning messages
   - Graceful failure handling
   - Clear error states

4. **Security**
   - Distance checking
   - Player verification
   - Character validation

## Common Patterns

### Status Application Flow
1. Client sends StatusRequest
2. Server validates request
3. Component applies status
4. Effects are replicated
5. Status state is maintained

### Status Check Flow
1. Client invokes HasStatusRequest
2. Server validates request
3. Component checks status
4. Returns status information
5. Client receives state

This service provides a secure and efficient way to manage status effects across the game while maintaining proper verification and validation at each step.
