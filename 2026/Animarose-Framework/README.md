# 🌹 ANIMAROSE FRAMEWORK v1.0.5
**"Professional-grade infrastructure without the bloat."**

---

## 📌 Author
**Wisterose / Wisterseph**  
GitHub: [wisterose](https://github.com/wisterose)

## 📅 Date
April 19, 2026  

## 📜 License
👉 [MIT License](https://opensource.org/licenses/MIT).

---

# 🧠 Architecture Overview

## 1. 🔒 Invisible Security
Tag modules "Server" or "Client".  
At runtime, Animarose relocates Server logic to ServerStorage, making it physically inaccessible to exploiters.

---

## 2. ⚙️ Zero-Config Lifecycle
No manual requiring.

The framework automatically:
- Loads modules  
- Handles dependency injection  
- Executes `Initialize()` (or the given "InitMethodName")  

---

## 3. 🚀 Native Buffer Networking
Built-in `NetworkService` utilizing [Suphi Kaner's Packet Module](https://youtu.be/WoIElUdj64A?si=3F7xRk0jHhcNcIAu)  for:
- High-speed communication  
- Serialized data transfer  
- Zero RemoteEvent management  

---

## 4. ⏳ Smart Await
Built-in race-condition protection.

If a service isn't ready:
- The framework safely yields  
- Automatically resumes when available  

---

# ⚡ Quick Start Guide

## 🧱 Creating a Service
Create a `ModuleScript`, tag it "Server", and return a table with an `Initialize` method:

```lua
local MyService = {}

function MyService:Initialize()
    print("Animarose Service Active!")
end

return MyService
```

📦 Requiring Services

Require the `ServiceRegistry` and call the `:Require` or  `:Await` methods.

```lua
local ServiceRegistry = require(ReplicatedStorage.ServiceRegistry)
local MyService = ServiceRegistry:Require("MyService")
```

🌐 Using Network

```lua
local Network = ServiceRegistry:Require("NetworkService")
Network:FireServer("MyPacket", {Data = 123})
```

📚 Standard Library (ASL)

🌐 Networking


_Packet

_TypedRemote

NetworkService

🔁 Lifecycle


_Trove

_Future

_Scheduler


🧠 Logic


_Signal

_Observers

_t (Type Checking)

🛠️ RECENT FIXES

[2026-04-20] Internal Dependency & Pathing Resolution
Decoupled Relative Pathing
Fixed a critical issue where moving service scripts within ServerStorage broke require links to sibling modules. The framework no longer relies on rigid file-tree paths.

Implemented ServiceRegistry Getters
Added GetTypes and GetShared methods to the ServiceRegistry. This allows any service to dynamically fetch its internal package dependencies using only a string name, making the entire framework location-agnostic.

NetworkService Refactor
Updated NetworkServiceServer to utilize the new Registry getters. This ensures that even if the network logic is relocated for security purposes, it can still reliably access its type definitions and packet configurations.

Standardized ServicePackage Structure
Formalized the "Package" philosophy: Types, Shared, and Server/Client modules are now strictly grouped together. This ensures clean internal discovery and modularity via the Registry.
