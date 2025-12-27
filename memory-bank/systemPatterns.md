# System Patterns

## Arsitektur Sistem

### 1. Security Loader Pattern
```
SecurityLoader.lua
├── Configuration (CONFIG)
├── Encryption/Decryption (decrypt function)
├── Rate Limiting (checkRateLimit)
├── Domain Validation (validateDomain)
├── Module Loading (LoadModule)
└── Anti-Dump Protection (EnableAntiDump)
```

**Pattern**: Centralized module loader dengan security layers

### 2. Module Structure Pattern
Setiap modul mengikuti pattern:
```lua
local ModuleName = {}
ModuleName.Enabled = false
ModuleName.Settings = { ... }

-- Event handlers
-- Core functions
-- Start/Stop functions

return ModuleName
```

**Pattern**: Module-based architecture dengan explicit state management

### 3. Network Event Pattern
```lua
-- Wait for network folder
local netFolder = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("sleitnick_net@0.2.0")
    :WaitForChild("net")

-- Get RemoteFunctions/RemoteEvents
local RF_XXX = netFolder:WaitForChild("RF/XXX")
local RE_XXX = netFolder:WaitForChild("RE/XXX")

-- Connect to events
RE_XXX.OnClientEvent:Connect(function(...)
    -- Handle event
end)
```

**Pattern**: Centralized network event handling dengan WaitForChild

### 4. Auto Fishing Pattern
```
Start() → Cast() → Wait Hook → Complete → Cancel → Repeat
         ↓
    Timeout Handler (fallback)
```

**Pattern**: State machine dengan timeout fallback

### 5. Configuration Pattern
```lua
local CONFIG = {
    VERSION = "...",
    SETTINGS = { ... },
    ENABLE_XXX = true/false
}
```

**Pattern**: Centralized configuration object

### 6. Avatar URL Fetching Pattern
```lua
local function getUserAvatarUrl(userId)
    -- Method 1: GetUserThumbnailAsync (official)
    -- Method 2: Thumbnail API + JSON parse
    -- Method 3: Direct URL fallback
end
```

**Pattern**: Multiple fallback methods untuk reliability, dengan pcall() protection

## Design Patterns yang Digunakan

### 1. Module Pattern
- Setiap fitur sebagai modul terpisah
- Explicit exports dengan return statement
- Namespace isolation

### 2. Observer Pattern
- Event-driven architecture
- OnClientEvent connections
- State change notifications

### 3. State Machine Pattern
- Fishing states: Running, WaitingHook, etc.
- Explicit state transitions
- State validation

### 4. Factory Pattern
- SecurityLoader.LoadModule() sebagai factory
- Dynamic module creation dari encrypted URLs

### 5. Singleton Pattern
- SecurityLoader sebagai singleton
- Global state management (_G.FishingScript)

## Key Technical Decisions

### 1. Encryption Strategy
- Base64 encoding + XOR encryption
- Obfuscated secret key
- URL encryption untuk security

### 2. Error Handling
- pcall() untuk protected calls
- warn() untuk error messages
- Graceful degradation

### 3. Performance Optimization
- task.spawn() untuk non-blocking operations
- task.wait() untuk delays
- Minimal blocking operations

### 4. Memory Management
- Explicit cleanup functions
- Connection disconnection
- State reset on stop

### 5. Rate Limiting
- Per-session tracking
- Time-based reset
- Configurable limits

## Component Relationships

### SecurityLoader → Modules
- SecurityLoader memuat semua modul
- Modules independen setelah loaded
- No direct dependencies

### GUI → Modules
- GUI mengontrol module state
- Modules expose Enabled flag
- Bidirectional communication via _G

### Modules → Network
- Modules berkomunikasi via RemoteFunctions/Events
- Network folder sebagai central hub
- Event-driven communication

## Anti-Patterns yang Dihindari

1. **Global Pollution**: Menggunakan namespaces dan modules
2. **Blocking Operations**: Menggunakan task.spawn() untuk async
3. **Hardcoded Values**: Menggunakan CONFIG objects
4. **No Error Handling**: Menggunakan pcall() everywhere
5. **Memory Leaks**: Explicit cleanup dan connection management

## Extension Points

1. **New Modules**: Tambah ke modulePaths dan encryptedURLs di SecurityLoader
2. **New GUI**: Implement GUI yang mengontrol module state
3. **New Features**: Ikuti module pattern yang sudah ada
4. **New Security**: Extend SecurityLoader dengan layer baru
5. **Avatar Integration**: Reuse getUserAvatarUrl() untuk UI personalization

## Recent Pattern Additions

### Avatar Integration Pattern
- getUserAvatarUrl() function untuk fetching user avatar
- Used in: minimize icon, notification icon, loading notification icon
- Implementation dengan 3-tier fallback untuk maximum compatibility
- Returns URL string untuk Image/ImageLabel properties

