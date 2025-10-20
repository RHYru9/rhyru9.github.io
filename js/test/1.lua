-- ========================================
-- 🎲 ULTIMATE RNG SYSTEM ANALYZER V2.0
-- Comprehensive deep analysis of ANY Roblox game
-- Universal pattern detection & exploit finder
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

print([[
╔═══════════════════════════════════════════╗
║  🎲 ULTIMATE RNG ANALYZER V2.0 🎲        ║
║  Universal Game Analysis Engine          ║
║  No Limits • No Boundaries               ║
╚═══════════════════════════════════════════╝
]])

-- ========================================
-- CONFIGURATION
-- ========================================

local Config = {
    maxDepth = 10,                    -- Maximum recursion depth
    maxTableSize = 1000,              -- Max items to analyze per table
    scanAllServices = true,           -- Scan ALL game services
    deepFunctionAnalysis = true,      -- Analyze function bytecode
    detectPatterns = true,            -- Auto-detect game patterns
    extractConstants = true,          -- Find all numeric constants
    hookFunctions = true,             -- Hook detected RNG functions
    monitorRemotes = true,            -- Track RemoteEvents/Functions
    analyzeLocalScripts = true,       -- Try to analyze LocalScripts
    extractStrings = true,            -- Extract all string patterns
    findHiddenModules = true,         -- Search for hidden modules
    debugMode = false                 -- Verbose output
}

-- ========================================
-- ADVANCED UTILITIES
-- ========================================

local Utils = {}

function Utils:DeepCopy(orig, seen)
    seen = seen or {}
    if type(orig) ~= 'table' then return orig end
    if seen[orig] then return seen[orig] end
    
    local copy = {}
    seen[orig] = copy
    
    for k, v in next, orig, nil do
        copy[Utils:DeepCopy(k, seen)] = Utils:DeepCopy(v, seen)
    end
    
    return setmetatable(copy, Utils:DeepCopy(getmetatable(orig), seen))
end

function Utils:SafeRequire(module)
    if not module or not module:IsA("ModuleScript") then return nil end
    
    local success, result = pcall(function()
        return require(module)
    end)
    
    if success and result then
        return result
    end
    return nil
end

function Utils:GetFunctionSource(func)
    if not func or type(func) ~= "function" then return nil end
    
    local info = debug.getinfo(func)
    return {
        source = info.source or "Unknown",
        short_src = info.short_src or "Unknown",
        linedefined = info.linedefined or 0,
        lastlinedefined = info.lastlinedefined or 0,
        numparams = info.nparams or 0,
        isvararg = info.isvararg or false,
        what = info.what or "Lua",
        name = info.name or "anonymous"
    }
end

function Utils:ExtractUpvalues(func)
    local upvalues = {}
    local i = 1
    
    while true do
        local name, value = debug.getupvalue(func, i)
        if not name then break end
        
        upvalues[name] = {
            type = type(value),
            value = self:SerializeValue(value, 1)
        }
        i = i + 1
    end
    
    return upvalues
end

function Utils:ExtractConstants(func)
    local constants = {}
    local info = debug.getinfo(func)
    
    if info and info.func then
        local i = 1
        while true do
            local success, constant = pcall(debug.getconstant, func, i)
            if not success then break end
            
            if constant ~= nil then
                table.insert(constants, {
                    index = i,
                    type = type(constant),
                    value = self:SerializeValue(constant, 0)
                })
            end
            i = i + 1
        end
    end
    
    return constants
end

function Utils:AnalyzeFunctionBytecode(func)
    local analysis = {
        source = self:GetFunctionSource(func),
        upvalues = self:ExtractUpvalues(func),
        constants = Config.extractConstants and self:ExtractConstants(func) or {},
        callsRandom = false,
        callsRemote = false,
        modifiesGlobals = false,
        complexity = 0
    }
    
    -- Pattern detection in constants
    for _, constant in ipairs(analysis.constants) do
        if type(constant.value) == "string" then
            local str = constant.value:lower()
            if str:find("random") or str:find("rng") or str:find("roll") then
                analysis.callsRandom = true
            end
            if str:find("remote") or str:find("invoke") or str:find("fire") then
                analysis.callsRemote = true
            end
        end
    end
    
    -- Calculate complexity
    analysis.complexity = #analysis.constants + #analysis.upvalues
    
    return analysis
end

function Utils:SerializeValue(value, depth, seen)
    depth = depth or 0
    seen = seen or {}
    
    if depth > Config.maxDepth then return "MAX_DEPTH" end
    if seen[value] then return "CIRCULAR_REF" end
    
    local vtype = type(value)
    
    if vtype == "table" then
        seen[value] = true
        local items = {}
        local count = 0
        
        for k, v in pairs(value) do
            count = count + 1
            if count > Config.maxTableSize then
                items["__TRUNCATED__"] = "..."
                break
            end
            
            local key = tostring(k)
            items[key] = self:SerializeValue(v, depth + 1, seen)
        end
        
        return items
    elseif vtype == "function" then
        if Config.deepFunctionAnalysis then
            return self:AnalyzeFunctionBytecode(value)
        else
            return {type = "function", name = tostring(value)}
        end
    elseif vtype == "userdata" then
        local success, str = pcall(tostring, value)
        return {type = "userdata", value = success and str or "Unknown"}
    elseif vtype == "number" or vtype == "boolean" then
        return value
    elseif vtype == "string" then
        return value:sub(1, 200)
    else
        return tostring(value)
    end
end

function Utils:GetInstancePath(instance)
    local path = {}
    local current = instance
    
    while current and current ~= game do
        table.insert(path, 1, current.Name)
        current = current.Parent
    end
    
    return table.concat(path, ".")
end

-- ========================================
-- UNIVERSAL MODULE SCANNER
-- ========================================

local ModuleScanner = {}

function ModuleScanner:ScanAllServices()
    print("\n🌐 Scanning ALL game services...\n")
    
    local services = {
        game.ReplicatedStorage,
        game.ReplicatedFirst,
        game.ServerStorage,
        game.ServerScriptService,
        game.StarterGui,
        game.StarterPack,
        game.StarterPlayer,
        game.Lighting,
        game.Workspace
    }
    
    local modules = {}
    
    for _, service in ipairs(services) do
        local serviceName = service.Name
        local success = pcall(function()
            for _, descendant in ipairs(service:GetDescendants()) do
                if descendant:IsA("ModuleScript") then
                    local module = Utils:SafeRequire(descendant)
                    if module then
                        modules[descendant.Name] = {
                            module = module,
                            instance = descendant,
                            service = serviceName,
                            path = Utils:GetInstancePath(descendant)
                        }
                        print(string.format("  [✓] %s: %s", serviceName, descendant.Name))
                    end
                end
            end
        end)
    end
    
    return modules
end

function ModuleScanner:FindByPattern(pattern)
    print(string.format("\n🔍 Searching for pattern: %s\n", pattern))
    
    local results = {}
    
    for _, service in ipairs(game:GetChildren()) do
        pcall(function()
            for _, descendant in ipairs(service:GetDescendants()) do
                if descendant:IsA("ModuleScript") and descendant.Name:lower():find(pattern:lower()) then
                    local module = Utils:SafeRequire(descendant)
                    if module then
                        results[descendant.Name] = {
                            module = module,
                            instance = descendant,
                            path = Utils:GetInstancePath(descendant)
                        }
                        print(string.format("  [✓] Found: %s", descendant.Name))
                    end
                end
            end
        end)
    end
    
    return results
end

function ModuleScanner:ScanRemoteEvents()
    print("\n📡 Scanning RemoteEvents/Functions...\n")
    
    local remotes = {
        events = {},
        functions = {}
    }
    
    for _, service in ipairs({game.ReplicatedStorage, game.Workspace}) do
        pcall(function()
            for _, descendant in ipairs(service:GetDescendants()) do
                if descendant:IsA("RemoteEvent") then
                    remotes.events[descendant.Name] = {
                        path = Utils:GetInstancePath(descendant),
                        instance = descendant
                    }
                    print(string.format("  [📤] RemoteEvent: %s", descendant.Name))
                elseif descendant:IsA("RemoteFunction") then
                    remotes.functions[descendant.Name] = {
                        path = Utils:GetInstancePath(descendant),
                        instance = descendant
                    }
                    print(string.format("  [🔄] RemoteFunction: %s", descendant.Name))
                end
            end
        end)
    end
    
    return remotes
end

-- ========================================
-- ADVANCED RNG ANALYZER
-- ========================================

local RNGAnalyzer = {}

function RNGAnalyzer:DeepAnalyze(module, name, depth)
    depth = depth or 0
    if depth > 3 then return {} end
    
    print(string.format("%s📊 Deep analyzing: %s (depth: %d)", string.rep("  ", depth), name, depth))
    
    local analysis = {
        name = name,
        depth = depth,
        functions = {},
        tables = {},
        numbers = {},
        strings = {},
        patterns = {},
        references = {},
        metadata = {}
    }
    
    for key, value in pairs(module) do
        local vtype = type(value)
        
        if vtype == "function" then
            analysis.functions[key] = Utils:AnalyzeFunctionBytecode(value)
        elseif vtype == "table" then
            -- Detect table patterns
            local tableAnalysis = self:AnalyzeTable(value, key, depth + 1)
            analysis.tables[key] = tableAnalysis
        elseif vtype == "number" then
            analysis.numbers[key] = value
        elseif vtype == "string" then
            analysis.strings[key] = value
            
            -- Pattern detection
            if value:lower():find("weight") then
                analysis.patterns.hasWeights = true
            end
            if value:lower():find("luck") then
                analysis.patterns.hasLuck = true
            end
            if value:lower():find("rare") or value:lower():find("legendary") then
                analysis.patterns.hasRarity = true
            end
        end
    end
    
    return analysis
end

function RNGAnalyzer:AnalyzeTable(tbl, name, depth)
    depth = depth or 0
    if depth > Config.maxDepth then return {truncated = true} end
    
    local analysis = {
        name = name,
        size = 0,
        hasWeights = false,
        hasMultipliers = false,
        hasProbabilities = false,
        isArray = true,
        isWeightTable = false,
        keys = {},
        values = {},
        patterns = {}
    }
    
    local arrayIndex = 1
    
    for k, v in pairs(tbl) do
        analysis.size = analysis.size + 1
        
        if k ~= arrayIndex then
            analysis.isArray = false
        end
        arrayIndex = arrayIndex + 1
        
        -- Detect weight patterns
        local keyLower = tostring(k):lower()
        if keyLower:find("weight") or keyLower == "w" then
            analysis.hasWeights = true
            analysis.isWeightTable = true
        end
        if keyLower:find("chance") or keyLower:find("probability") then
            analysis.hasProbabilities = true
            analysis.isWeightTable = true
        end
        if keyLower:find("multiplier") or keyLower:find("mult") or keyLower:find("modifier") then
            analysis.hasMultipliers = true
        end
        
        table.insert(analysis.keys, tostring(k))
        
        -- Analyze values
        if type(v) == "number" then
            table.insert(analysis.values, {key = k, value = v, type = "number"})
        elseif type(v) == "table" then
            -- Recursive analysis for nested tables
            local nested = self:AnalyzeTable(v, tostring(k), depth + 1)
            if nested.isWeightTable then
                analysis.isWeightTable = true
            end
        end
    end
    
    return analysis
end

function RNGAnalyzer:FindRNGPatterns(module, name)
    print(string.format("🎲 Finding RNG patterns in: %s", name))
    
    local patterns = {
        name = name,
        usesRandom = false,
        usesRandomNew = false,
        usesMathRandom = false,
        usesWeights = false,
        usesSeeds = false,
        rngFunctions = {},
        weightTables = {},
        seedVariables = {},
        randomCalls = []
    }
    
    for key, value in pairs(module) do
        if type(value) == "function" then
            local analysis = Utils:AnalyzeFunctionBytecode(value)
            
            -- Check for RNG patterns in constants
            for _, constant in ipairs(analysis.constants) do
                if type(constant.value) == "string" then
                    local str = constant.value:lower()
                    
                    if str:find("random%.new") then
                        patterns.usesRandomNew = true
                        table.insert(patterns.rngFunctions, {
                            name = key,
                            type = "Random.new",
                            analysis = analysis
                        })
                    elseif str:find("math%.random") then
                        patterns.usesMathRandom = true
                        table.insert(patterns.rngFunctions, {
                            name = key,
                            type = "math.random",
                            analysis = analysis
                        })
                    end
                    
                    if str:find("seed") then
                        patterns.usesSeeds = true
                        table.insert(patterns.seedVariables, key)
                    end
                end
            end
            
            -- Check upvalues for Random objects
            for upname, upval in pairs(analysis.upvalues) do
                if upname:lower():find("random") or upname:lower():find("rng") then
                    patterns.usesRandom = true
                end
                if upname:lower():find("seed") then
                    patterns.usesSeeds = true
                end
            end
        elseif type(value) == "table" then
            local tableAnalysis = self:AnalyzeTable(value, key)
            if tableAnalysis.isWeightTable then
                patterns.usesWeights = true
                patterns.weightTables[key] = tableAnalysis
            end
        end
    end
    
    return patterns
end

-- ========================================
-- PATTERN DETECTOR
-- ========================================

local PatternDetector = {}

function PatternDetector:DetectGameType(allModules)
    print("\n🎮 Detecting game type...\n")
    
    local patterns = {
        fishing = 0,
        gacha = 0,
        simulator = 0,
        tycoon = 0,
        rpg = 0,
        tower_defense = 0,
        obby = 0
    }
    
    local keywords = {
        fishing = {"fish", "rod", "bait", "catch", "reel", "aqua"},
        gacha = {"summon", "pull", "banner", "rate", "pity", "wish"},
        simulator = {"rebirth", "pet", "egg", "hatch", "upgrade", "auto"},
        tycoon = {"cash", "income", "purchase", "unlock", "dropper"},
        rpg = {"quest", "level", "exp", "skill", "stat", "class"},
        tower_defense = {"tower", "enemy", "wave", "defense", "upgrade"},
        obby = {"checkpoint", "stage", "jump", "obstacle"}
    }
    
    for moduleName, _ in pairs(allModules) do
        local nameLower = moduleName:lower()
        
        for gameType, wordList in pairs(keywords) do
            for _, keyword in ipairs(wordList) do
                if nameLower:find(keyword) then
                    patterns[gameType] = patterns[gameType] + 1
                end
            end
        end
    end
    
    -- Find dominant pattern
    local maxScore = 0
    local gameType = "unknown"
    
    for gtype, score in pairs(patterns) do
        if score > maxScore then
            maxScore = score
            gameType = gtype
        end
    end
    
    print(string.format("  [🎯] Detected: %s (confidence: %d)", gameType, maxScore))
    
    return {
        type = gameType,
        confidence = maxScore,
        allScores = patterns
    }
end

function PatternDetector:FindExploitPatterns(analysisData)
    print("\n🔓 Finding exploit patterns...\n")
    
    local exploits = {
        clientSideRNG = {},
        predictableSeeds = {},
        manipulableWeights = {},
        unprotectedRemotes = {},
        exposedConstants = {},
        weakValidation = {},
        timingVulnerabilities = {},
        recommendations = {}
    }
    
    for moduleName, data in pairs(analysisData.modules or {}) do
        -- Check for client-side RNG
        if data.patterns then
            if data.patterns.usesMathRandom then
                table.insert(exploits.clientSideRNG, {
                    module = moduleName,
                    risk = "CRITICAL",
                    reason = "Uses math.random - completely predictable",
                    exploit = "Can be predicted and manipulated"
                })
                print(string.format("  [🔴] CRITICAL: %s uses math.random", moduleName))
            end
            
            if data.patterns.usesSeeds then
                table.insert(exploits.predictableSeeds, {
                    module = moduleName,
                    risk = "HIGH",
                    reason = "Uses seed-based RNG",
                    exploit = "Seed can be predicted if algorithm is known"
                })
                print(string.format("  [🟠] HIGH: %s uses seeds", moduleName))
            end
            
            if data.patterns.usesWeights and #data.patterns.weightTables > 0 then
                table.insert(exploits.manipulableWeights, {
                    module = moduleName,
                    risk = "MEDIUM",
                    reason = "Weight tables accessible from client",
                    tables = data.patterns.weightTables,
                    exploit = "Can modify weights before calculation"
                })
                print(string.format("  [🟡] MEDIUM: %s has exposed weights", moduleName))
            end
        end
        
        -- Check for exposed constants
        if data.numbers then
            for key, value in pairs(data.numbers) do
                if value >= 0.01 and value <= 100 then
                    table.insert(exploits.exposedConstants, {
                        module = moduleName,
                        constant = key,
                        value = value,
                        risk = "LOW",
                        reason = "Numeric constant (potential rate/multiplier)"
                    })
                end
            end
        end
    end
    
    -- Recommendations
    table.insert(exploits.recommendations, "Move ALL RNG calculations to server-side")
    table.insert(exploits.recommendations, "Use cryptographically secure RNG (Random.new)")
    table.insert(exploits.recommendations, "Never expose weight tables to client")
    table.insert(exploits.recommendations, "Validate ALL user inputs server-side")
    table.insert(exploits.recommendations, "Implement rate limiting on critical actions")
    table.insert(exploits.recommendations, "Add server-side sanity checks")
    
    return exploits
end

-- ========================================
-- ADVANCED FILE MANAGER
-- ========================================

local FileManager = {}

function FileManager:Init()
    self.canWrite = writefile ~= nil
    self.canMakeFolder = makefolder ~= nil
    self.canList = listfiles ~= nil
    
    if not self.canWrite then
        warn("⚠️ writefile() not supported!")
        return false
    end
    
    print("✅ Advanced file system ready\n")
    return true
end

function FileManager:CreateStructure()
    local folders = {
        "UltimateAnalysis",
        "UltimateAnalysis/Modules",
        "UltimateAnalysis/Functions",
        "UltimateAnalysis/Tables",
        "UltimateAnalysis/Patterns",
        "UltimateAnalysis/Exploits",
        "UltimateAnalysis/Remotes",
        "UltimateAnalysis/Reports"
    }
    
    for _, folder in ipairs(folders) do
        pcall(function() makefolder(folder) end)
    end
end

function FileManager:WriteJSON(path, data)
    local success, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    
    if success then
        pcall(function()
            writefile(path, json)
            print(string.format("💾 %s", path))
        end)
    end
end

function FileManager:WriteLua(path, data, varName)
    varName = varName or "Data"
    
    local function serialize(tbl, indent)
        indent = indent or 0
        local s = string.rep("  ", indent)
        local lines = {"{"}
        
        local count = 0
        for k, v in pairs(tbl) do
            count = count + 1
            if count > 100 then
                table.insert(lines, s .. '  ["__TRUNCATED__"] = true,')
                break
            end
            
            local key = type(k) == "string" and string.format('["%s"]', k) or string.format("[%s]", k)
            local value
            
            if type(v) == "table" then
                value = serialize(v, indent + 1)
            elseif type(v) == "string" then
                value = string.format('"%s"', v:gsub('"', '\\"'))
            else
                value = tostring(v)
            end
            
            table.insert(lines, string.format("%s  %s = %s,", s, key, value))
        end
        
        table.insert(lines, s .. "}")
        return table.concat(lines, "\n")
    end
    
    local content = string.format("local %s = %s\n\nreturn %s", varName, serialize(data), varName)
    
    pcall(function()
        writefile(path, content)
        print(string.format("💾 %s", path))
    end)
end

-- ========================================
-- MAIN EXECUTION ENGINE
-- ========================================

local function ExecuteAnalysis()
    print("\n🚀 Starting ULTIMATE analysis...\n")
    
    local startTime = tick()
    
    -- Initialize
    if not FileManager:Init() then
        warn("Cannot save files - analysis will continue anyway")
    else
        FileManager:CreateStructure()
    end
    
    -- Scan everything
    print(string.rep("=", 60))
    print("PHASE 1: COMPREHENSIVE SCANNING")
    print(string.rep("=", 60))
    
    local allModules = ModuleScanner:ScanAllServices()
    local remotes = Config.monitorRemotes and ModuleScanner:ScanRemoteEvents() or {}
    
    print(string.format("\n✅ Found %d modules, %d remotes\n", 
        Utils:CountTable(allModules), 
        Utils:CountTable(remotes.events) + Utils:CountTable(remotes.functions)))
    
    -- Detect game type
    local gameType = PatternDetector:DetectGameType(allModules)
    
    -- Deep analysis
    print("\n" .. string.rep("=", 60))
    print("PHASE 2: DEEP ANALYSIS")
    print(string.rep("=", 60) .. "\n")
    
    local fullAnalysis = {
        metadata = {
            timestamp = os.date("%Y-%m-%d %H:%M:%S"),
            executor = tostring(identifyexecutor and identifyexecutor() or "Unknown"),
            gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
            placeId = game.PlaceId,
            gameType = gameType,
            analysisTime = 0
        },
        modules = {},
        patterns = {},
        remotes = remotes,
        exploits = {},
        statistics = {
            totalModules = 0,
            totalFunctions = 0,
            totalTables = 0,
            totalRemotes = 0
        }
    }
    
    -- Analyze each module
    for moduleName, moduleData in pairs(allModules) do
        fullAnalysis.modules[moduleName] = RNGAnalyzer:DeepAnalyze(moduleData.module, moduleName)
        fullAnalysis.patterns[moduleName] = RNGAnalyzer:FindRNGPatterns(moduleData.module, moduleName)
        
        -- Update statistics
        fullAnalysis.statistics.totalModules = fullAnalysis.statistics.totalModules + 1
        
        if fullAnalysis.modules[moduleName].functions then
            for _ in pairs(fullAnalysis.modules[moduleName].functions) do
                fullAnalysis.statistics.totalFunctions = fullAnalysis.statistics.totalFunctions + 1
            end
        end
    end
    
    fullAnalysis.statistics.totalRemotes = Utils:CountTable(remotes.events) + Utils:CountTable(remotes.functions)
    
    -- Find exploits
    print("\n" .. string.rep("=", 60))
    print("PHASE 3: EXPLOIT DETECTION")
    print(string.rep("=", 60))
    
    fullAnalysis.exploits = PatternDetector:FindExploitPatterns(fullAnalysis)
    
    -- Calculate analysis time
    fullAnalysis.metadata.analysisTime = math.floor((tick() - startTime) * 1000) / 1000
    
    -- Save everything
    print("\n" .. string.rep("=", 60))
    print("PHASE 4: SAVING RESULTS")
    print(string.rep("=", 60) .. "\n")
    
    if FileManager.canWrite then
        FileManager:WriteJSON("UltimateAnalysis/complete_analysis.json", fullAnalysis)
        FileManager:WriteLua("UltimateAnalysis/complete_analysis.lua", fullAnalysis, "CompleteAnalysis")
        
        -- Save individual components
        for moduleName, analysis in pairs(fullAnalysis.modules) do
            local safeName = moduleName:gsub("[^%w]", "_")
            FileManager:WriteJSON(string.format("UltimateAnalysis/Modules/%s.json", safeName), analysis)
        end
        
        for moduleName, pattern in pairs(fullAnalysis.patterns) do
            local safeName = moduleName:gsub("[^%w]", "_")
            FileManager:WriteJSON(string.format("UltimateAnalysis/Patterns/%s.json", safeName), pattern)
        end
        
        FileManager:WriteJSON("UltimateAnalysis/Exploits/all_vulnerabilities.json", fullAnalysis.exploits)
        FileManager:WriteJSON("UltimateAnalysis/Remotes/remote_events.json", remotes)
    end
    
    -- Print final summary
    print("\n" .. string.rep("=", 60))
    print("✅ ULTIMATE ANALYSIS COMPLETE!")
    print(string.rep("=", 60))
    print(string.format("\n📊 Statistics:"))
    print(string.format("   • Modules analyzed: %d", fullAnalysis.statistics.totalModules))
    print(string.format("   • Functions found: %d", fullAnalysis.statistics.totalFunctions))
    print(string.format("   • Remotes detected: %d", fullAnalysis.statistics.totalRemotes))
    print(string.format("   • Analysis time: %.2fs", fullAnalysis.metadata.analysisTime))
    print(string.format("\n🎮 Game Type: %s (confidence: %d)", gameType.type, gameType.confidence))
    print(string.format("\n🔓 Vulnerabilities:"))
    print(string.format("   • Critical: %d", #fullAnalysis.exploits.clientSideRNG))
    print(string.format("   • High: %d", #fullAnalysis.exploits.predictableSeeds))
    print(string.format("   • Medium: %d", #fullAnalysis.exploits.manipulableWeights))
    print(string.format("   • Low: %d", #fullAnalysis.exploits.exposedConstants))
    print("\n📂 Files saved to: [Workspace]/UltimateAnalysis/")
    
    if setclipboard then
        local summary = string.format([[
ULTIMATE RNG ANALYSIS SUMMARY
=============================
Game: %s
Type: %s
Modules: %d | Functions: %d | Remotes: %d
Vulnerabilities: %d critical, %d high, %d medium
Analysis Time: %.2fs
        ]], 
            fullAnalysis.metadata.gameName,
            gameType.type,
            fullAnalysis.statistics.totalModules,
            fullAnalysis.statistics.totalFunctions,
            fullAnalysis.statistics.totalRemotes,
            #fullAnalysis.exploits.clientSideRNG,
            #fullAnalysis.exploits.predictableSeeds,
            #fullAnalysis.exploits.manipulableWeights,
            fullAnalysis.metadata.analysisTime
        )
        
        setclipboard(summary)
        print("\n✅ Summary copied to clipboard!")
    end
    
    return fullAnalysis
end

function Utils:CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- ========================================
-- GLOBAL API
-- ========================================

_G.UltimateAnalyzer = {
    -- Core functions
    Run = ExecuteAnalysis,
    
    -- Utils
    Utils = Utils,
    
    -- Scanners
    ModuleScanner = ModuleScanner,
    
    -- Analyzers
    RNGAnalyzer = RNGAnalyzer,
    PatternDetector = PatternDetector,
    
    -- File Manager
    FileManager = FileManager,
    
    -- Advanced features
    ScanPattern = function(pattern)
        return ModuleScanner:FindByPattern(pattern)
    end,
    
    AnalyzeModule = function(moduleName)
        local modules = ModuleScanner:ScanAllServices()
        if modules[moduleName] then
            local analysis = RNGAnalyzer:DeepAnalyze(modules[moduleName].module, moduleName)
            local patterns = RNGAnalyzer:FindRNGPatterns(modules[moduleName].module, moduleName)
            return {analysis = analysis, patterns = patterns}
        end
        return nil
    end,
    
    GetModuleByName = function(name)
        local modules = ModuleScanner:ScanAllServices()
        return modules[name]
    end,
    
    ListAllModules = function()
        local modules = ModuleScanner:ScanAllServices()
        local list = {}
        for name, _ in pairs(modules) do
            table.insert(list, name)
        end
        return list
    end,
    
    FindWeightTables = function()
        local modules = ModuleScanner:ScanAllServices()
        local weightTables = {}
        
        for moduleName, moduleData in pairs(modules) do
            local patterns = RNGAnalyzer:FindRNGPatterns(moduleData.module, moduleName)
            if patterns.usesWeights then
                weightTables[moduleName] = patterns.weightTables
            end
        end
        
        return weightTables
    end,
    
    FindRNGFunctions = function()
        local modules = ModuleScanner:ScanAllServices()
        local rngFunctions = {}
        
        for moduleName, moduleData in pairs(modules) do
            local patterns = RNGAnalyzer:FindRNGPatterns(moduleData.module, moduleName)
            if #patterns.rngFunctions > 0 then
                rngFunctions[moduleName] = patterns.rngFunctions
            end
        end
        
        return rngFunctions
    end,
    
    MonitorRemotes = function()
        return ModuleScanner:ScanRemoteEvents()
    end,
    
    -- Hook functions
    HookFunction = function(moduleName, functionName, callback)
        local modules = ModuleScanner:ScanAllServices()
        if modules[moduleName] then
            local module = modules[moduleName].module
            if module[functionName] and type(module[functionName]) == "function" then
                local original = module[functionName]
                module[functionName] = function(...)
                    local args = {...}
                    local result = callback(original, args)
                    if result ~= nil then
                        return result
                    end
                    return original(...)
                end
                return true
            end
        end
        return false
    end,
    
    -- Export functions
    ExportToFile = function(filename, data)
        if FileManager.canWrite then
            FileManager:WriteJSON("UltimateAnalysis/" .. filename, data)
            return true
        end
        return false
    end,
    
    -- Quick analysis presets
    QuickScan = function()
        print("\n⚡ Quick Scan Mode\n")
        Config.maxDepth = 3
        Config.deepFunctionAnalysis = false
        return ExecuteAnalysis()
    end,
    
    DeepScan = function()
        print("\n🔬 Deep Scan Mode\n")
        Config.maxDepth = 10
        Config.deepFunctionAnalysis = true
        return ExecuteAnalysis()
    end,
    
    ExploitScan = function()
        print("\n🔓 Exploit-Focused Scan\n")
        Config.maxDepth = 5
        Config.hookFunctions = true
        local result = ExecuteAnalysis()
        return result.exploits
    end
}

-- ========================================
-- AUTO-EXECUTION
-- ========================================

print([[

╔═══════════════════════════════════════════╗
║         🎮 COMMANDS AVAILABLE 🎮         ║
╚═══════════════════════════════════════════╝

AUTOMATIC MODE:
  Just wait, analysis will auto-start!

MANUAL COMMANDS:
  _G.UltimateAnalyzer.Run()           -- Full analysis
  _G.UltimateAnalyzer.QuickScan()     -- Fast scan
  _G.UltimateAnalyzer.DeepScan()      -- Deep scan
  _G.UltimateAnalyzer.ExploitScan()   -- Find exploits

UTILITY COMMANDS:
  _G.UltimateAnalyzer.ListAllModules()
  _G.UltimateAnalyzer.ScanPattern("Weight")
  _G.UltimateAnalyzer.AnalyzeModule("WeightRandom")
  _G.UltimateAnalyzer.FindWeightTables()
  _G.UltimateAnalyzer.FindRNGFunctions()
  _G.UltimateAnalyzer.MonitorRemotes()

ADVANCED:
  _G.UltimateAnalyzer.HookFunction("Module", "Function", callback)
  _G.UltimateAnalyzer.ExportToFile("custom.json", data)

════════════════════════════════════════════
]])

-- Auto-run with delay
print("\n⏳ Starting ULTIMATE analysis in 2 seconds...\n")
print("💡 Tip: Press Ctrl+C in console to cancel\n")

wait(2)
return ExecuteAnalysis()
