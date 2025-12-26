# Tech Context

## Technologies Used

### Core Technologies
- **Lua 5.1**: Bahasa pemrograman utama (Roblox Lua variant)
- **Roblox API**: Platform APIs untuk game interaction
- **sleitnick_net**: Network library untuk RemoteFunctions/Events

### Libraries & Dependencies
- **ReplicatedStorage**: Service untuk network communication
- **Players**: Service untuk player management
- **HttpService**: Service untuk HTTP requests (dalam SecurityLoader)
- **RbxAnalyticsService**: Service untuk client identification

## Development Setup

### Environment
- **Platform**: Roblox
- **Executor**: Jazzy (dari konteks SecurityLoader)
- **OS**: Windows (dari user info)

### File Structure
```
Tugas_Kuliah-main/
├── SecurityLoader.lua          # Entry point dengan security
├── Project_code/
│   ├── BlatantV2.lua
│   ├── Utama/                  # Core modules
│   ├── Quest/                  # Quest automation
│   ├── ShopFeatures/           # Shop automation
│   ├── TeleportSystem/         # Teleport features
│   ├── Camera View/            # Camera modules
│   └── Misc/                   # Utilities
└── [GUI files]                 # Various GUI implementations
```

## Technical Constraints

### Roblox Limitations
- **Sandboxed Environment**: Limited access to system resources
- **Network Restrictions**: HTTP requests terbatas
- **Memory Limits**: Perlu optimasi memory usage
- **Execution Limits**: Rate limiting diperlukan

### Executor Limitations
- **Metatable Access**: Terbatas untuk anti-dump
- **newcclosure**: Mungkin tidak tersedia di semua executor
- **Script Protection**: Perlu encryption untuk security

## Dependencies

### Internal Dependencies
- SecurityLoader → All modules (via encrypted URLs)
- GUI files → Modules (via _G atau direct calls)
- Modules → Network events (via ReplicatedStorage)

### External Dependencies
- **GitHub Raw URLs**: Untuk hosting encrypted modules
- **Roblox Game**: Target game dengan network structure
- **sleitnick_net**: Network library di ReplicatedStorage

## Development Tools

### Code Organization
- Modular structure
- Separation of concerns
- Clear naming conventions

### Version Control
- Git repository
- MIT License
- Copyright notice

## Performance Considerations

### Optimization Techniques
1. **Non-blocking Operations**: task.spawn() untuk async
2. **Memory Management**: Explicit cleanup
3. **Rate Limiting**: Prevent excessive requests
4. **Efficient Delays**: task.wait() instead of wait()

### Known Performance Issues
- Memory leaks (ada fix files: MemLeakFix.lua, NewFixMem.lua)
- FPS issues (ada FpsBooster.lua, UnlockFPS.lua)
- Rendering issues (ada DisableRendering.lua)

## Security Measures

### Encryption
- Base64 + XOR encryption
- Obfuscated secret keys
- Encrypted module URLs

### Protection
- Anti-dump protection
- Domain validation
- Rate limiting
- Session tracking

## Configuration

### Configurable Settings
- Module delays (FishingDelay, CancelDelay, etc.)
- Timeout values
- Rate limits
- Security flags

### Default Values
- Fishing delays: 0.01-1.30 seconds
- Timeout delays: 0.5-1.1 seconds
- Rate limit: 100 loads per session

## Testing Approach

### Test Files
- GUI2test.lua
- JazzyGUITest.lua
- Various "test" and "fix" files

### Iteration Pattern
- Multiple versions (V1, V2, Fixed, etc.)
- Test files untuk validation
- Fix files untuk issues

## Deployment

### Distribution Method
- GitHub repository
- Encrypted URLs via SecurityLoader
- Direct file execution

### Update Mechanism
- Version tracking (CONFIG.VERSION)
- Module count tracking
- Session info display

