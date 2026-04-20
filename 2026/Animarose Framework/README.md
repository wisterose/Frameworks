# 🌹 ANIMAROSE FRAMEWORK v1.0.0
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
