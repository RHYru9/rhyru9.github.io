-- ========================================
-- 🎲 FULL RNG SYSTEM ANALYZER
-- Deep analysis of Roblox RNG mechanics
-- For Hydrogen Executor
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

print([[
╔═══════════════════════════════════════════╗
║   🎲 FULL RNG SYSTEM ANALYZER 🎲         ║
║   Deep Dive into RNG Mechanics           ║
╚═══════════════════════════════════════════╝
]])

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

local Utils = {}

function Utils:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Utils:DeepCopy(orig_key)] = Utils:DeepCopy(orig_value)
        end
        setmetatable(copy, Utils:DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

function Utils:SafeRequire(module)
    if not module then return nil end
    local success, result = pcall(require, module)
    return success and result or nil
end

function Utils:GetFunctionInfo(func)
    local info = debug.getinfo(func)
    return {
        source = info.source or "Unknown",
        linedefined = info.linedefined or 0,
        lastlinedefined = info.lastlinedefined or 0,
        numparams = info.nparams or 0,
        isvararg = info.isvararg or false
    }
end

function Utils:AnalyzeFunction(func, name)
    local info = self:GetFunctionInfo(func)
    local upvalues = {}
    
    local i = 1
    while true do
        local n, v = debug.getupvalue(func, i)
        if not n then break end
        upvalues[n] = {
            type = type(v),
            value = type(v) == "number" and v or (type(v) == "string" and v:sub(1, 50)) or tostring(v):sub(1, 50)
        }
        i = i + 1
    end
    
    return {
        name = name,
        info = info,
        upvalues = upvalues,
        paramCount = info.numparams
    }
end

function Utils:SerializeValue(value, depth)
    depth = depth or 0
    if depth > 4 then return "..." end
    
    local vtype = type(value)
    
    if vtype == "table" then
        local items = {}
        local count = 0
        for k, v in pairs(value) do
            count = count + 1
            if count > 20 then
                items["..."] = "truncated"
                break
            end
            items[tostring(k)] = self:SerializeValue(v, depth + 1)
        end
        return items
    elseif vtype == "function" then
        return {
            type = "function",
            analysis = self:AnalyzeFunction(value, "anonymous")
        }
    elseif vtype == "number" or vtype == "boolean" then
        return value
    elseif vtype == "string" then
        return value:sub(1, 100)
    else
        return tostring(value):sub(1, 50)
    end
end

-- ========================================
-- MODULE FINDER
-- ========================================

local ModuleFinder = {}

function ModuleFinder:FindAllModules()
    print("\n🔍 Scanning for modules...\n")
    
    local modules = {}
    local keywords = {
        "RNG", "Random", "Roll", "Luck", "Weight", "Chance", "Probability",
        "Gacha", "Drop", "Loot", "Reward", "Fish", "Catch", "Enchant",
        "Modifier", "Buff", "Potion", "Boost", "Multiplier"
    }
    
    local function scanContainer(container, path)
        for _, child in ipairs(container:GetDescendants()) do
            if child:IsA("ModuleScript") then
                local childName = child.Name
                local shouldAnalyze = false
                
                -- Check if name matches keywords
                for _, keyword in ipairs(keywords) do
                    if childName:lower():find(keyword:lower()) then
                        shouldAnalyze = true
                        break
                    end
                end
                
                if shouldAnalyze then
                    local module = Utils:SafeRequire(child)
                    if module then
                        modules[childName] = {
                            module = module,
                            path = path .. "." .. childName,
                            instance = child
                        }
                        print(string.format("  [✓] Found: %s", childName))
                    end
                end
            end
        end
    end
    
    scanContainer(ReplicatedStorage, "ReplicatedStorage")
    
    print(string.format("\n✅ Found %d relevant modules\n", self:CountTable(modules)))
    
    return modules
end

function ModuleFinder:CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- ========================================
-- RNG ANALYZER
-- ========================================

local RNGAnalyzer = {}

function RNGAnalyzer:AnalyzeWeightSystem(module, name)
    print(string.format("📊 Analyzing: %s", name))
    
    local analysis = {
        name = name,
        functions = {},
        weights = {},
        randomCalls = {},
        constants = {},
        logic = {}
    }
    
    -- Analyze all functions
    for key, value in pairs(module) do
        if type(value) == "function" then
            analysis.functions[key] = Utils:AnalyzeFunction(value, key)
            
            -- Detect RNG patterns
            local funcInfo = analysis.functions[key]
            if key:lower():find("random") or key:lower():find("roll") or key:lower():find("weight") then
                table.insert(analysis.randomCalls, {
                    name = key,
                    upvalues = funcInfo.upvalues,
                    params = funcInfo.paramCount
                })
            end
        elseif type(value) == "table" then
            -- Check if it's a weight table
            local hasWeights = false
            for k, v in pairs(value) do
                if type(v) == "number" or (type(v) == "table" and (v.Weight or v.Chance or v.Probability)) then
                    hasWeights = true
                    break
                end
            end
            
            if hasWeights then
                analysis.weights[key] = Utils:SerializeValue(value, 0)
            end
        elseif type(value) == "number" then
            analysis.constants[key] = value
        end
    end
    
    return analysis
end

function RNGAnalyzer:FindRNGLogic(module, name)
    print(string.format("🔬 Deep diving: %s", name))
    
    local logic = {
        name = name,
        rngMethods = {},
        mathRandomCalls = false,
        customRNG = false,
        seedDetected = false,
        weightAlgorithm = "Unknown"
    }
    
    -- Check for Random.new usage
    for key, value in pairs(module) do
        if type(value) == "function" then
            local success, result = pcall(function()
                local info = debug.getinfo(value)
                if info.source then
                    if info.source:find("Random.new") then
                        logic.customRNG = true
                    end
                    if info.source:find("math.random") then
                        logic.mathRandomCalls = true
                    end
                end
            end)
        end
        
        -- Detect weight algorithms
        if key:lower():find("weight") then
            logic.rngMethods[key] = {
                type = type(value),
                callable = type(value) == "function"
            }
            
            if type(value) == "function" then
                local funcAnalysis = Utils:AnalyzeFunction(value, key)
                if funcAnalysis.upvalues then
                    for upname, upvalue in pairs(funcAnalysis.upvalues) do
                        if upname:lower():find("seed") then
                            logic.seedDetected = true
                        end
                    end
                end
            end
        end
    end
    
    return logic
end

function RNGAnalyzer:AnalyzeLuckModifiers(module, name)
    print(string.format("🍀 Analyzing luck: %s", name))
    
    local modifiers = {
        name = name,
        luckValues = {},
        multipliers = {},
        bonuses = {},
        stackable = false,
        maxLuck = nil
    }
    
    for key, value in pairs(module) do
        local keyLower = tostring(key):lower()
        
        -- Detect luck-related values
        if keyLower:find("luck") or keyLower:find("modifier") or keyLower:find("boost") then
            if type(value) == "number" then
                modifiers.luckValues[key] = value
                if value > (modifiers.maxLuck or 0) then
                    modifiers.maxLuck = value
                end
            elseif type(value) == "table" then
                modifiers.multipliers[key] = Utils:SerializeValue(value, 1)
                
                -- Check if luck stacks
                if value.Stackable ~= nil then
                    modifiers.stackable = value.Stackable
                end
            end
        end
        
        -- Detect multiplier patterns
        if type(value) == "table" and (value.Multiplier or value.Value or value.Modifier) then
            modifiers.bonuses[key] = {
                multiplier = value.Multiplier,
                value = value.Value,
                modifier = value.Modifier,
                duration = value.Duration,
                stackable = value.Stackable
            }
        end
    end
    
    return modifiers
end

-- ========================================
-- EXPLOIT FINDER
-- ========================================

local ExploitFinder = {}

function ExploitFinder:FindVulnerabilities(analysisData)
    print("\n🔓 Searching for exploitable patterns...\n")
    
    local exploits = {
        clientSideRNG = {},
        predictableSeeds = {},
        manipulableWeights = {},
        bypassableLimits = {},
        recommendations = {}
    }
    
    -- Check for client-side RNG
    for moduleName, data in pairs(analysisData) do
        if data.logic then
            if data.logic.mathRandomCalls and not data.logic.customRNG then
                table.insert(exploits.clientSideRNG, {
                    module = moduleName,
                    risk = "HIGH",
                    reason = "Uses math.random without custom seed - predictable"
                })
                print(string.format("  [!] %s: Client-side math.random detected", moduleName))
            end
            
            if data.logic.seedDetected then
                table.insert(exploits.predictableSeeds, {
                    module = moduleName,
                    risk = "MEDIUM",
                    reason = "Custom seed detected - may be predictable"
                })
                print(string.format("  [!] %s: Seed-based RNG detected", moduleName))
            end
        end
        
        -- Check for weight manipulation
        if data.weights then
            for weightName, weightData in pairs(data.weights) do
                table.insert(exploits.manipulableWeights, {
                    module = moduleName,
                    weight = weightName,
                    risk = "MEDIUM",
                    reason = "Weight table accessible - may be modifiable"
                })
            end
        end
    end
    
    -- Generate recommendations
    table.insert(exploits.recommendations, "Use server-side RNG for critical rolls")
    table.insert(exploits.recommendations, "Implement Random.new with secure seeds")
    table.insert(exploits.recommendations, "Validate all luck modifiers server-side")
    table.insert(exploits.recommendations, "Add rate limiting for roll attempts")
    
    return exploits
end

-- ========================================
-- FILE MANAGER
-- ========================================

local FileManager = {}

function FileManager:Init()
    self.canWrite = writefile ~= nil
    self.canMakeFolder = makefolder ~= nil
    
    if not self.canWrite then
        warn("⚠️ writefile() not supported!")
        return false
    end
    
    print("✅ File system ready\n")
    return true
end

function FileManager:CreateFolder(folderName)
    if not self.canMakeFolder then return false end
    pcall(function() makefolder(folderName) end)
    return true
end

function FileManager:WriteFile(fileName, content)
    if not self.canWrite then return false end
    
    local success = pcall(function()
        writefile(fileName, content)
    end)
    
    if success then
        print(string.format("💾 Saved: %s", fileName))
    end
    
    return success
end

-- ========================================
-- OUTPUT FORMATTER
-- ========================================

local OutputFormatter = {}

function OutputFormatter:ToJSON(data)
    local success, json = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    return success and json or "{}"
end

function OutputFormatter:ToDetailedReport(fullAnalysis)
    local lines = {
        "════════════════════════════════════════════════════════",
        "         🎲 FULL RNG SYSTEM ANALYSIS REPORT 🎲         ",
        "════════════════════════════════════════════════════════",
        "",
        string.format("Generated: %s", os.date("%Y-%m-%d %H:%M:%S")),
        string.format("Executor: %s", tostring(identifyexecutor and identifyexecutor() or "Hydrogen")),
        string.format("Total Modules Analyzed: %d", fullAnalysis.totalModules or 0),
        "",
        "════════════════════════════════════════════════════════",
        "📊 RNG SYSTEM BREAKDOWN",
        "════════════════════════════════════════════════════════",
        ""
    }
    
    -- Module summaries
    for moduleName, analysis in pairs(fullAnalysis.modules or {}) do
        table.insert(lines, string.format("## %s", moduleName))
        
        if analysis.functions then
            local funcCount = 0
            for _ in pairs(analysis.functions) do funcCount = funcCount + 1 end
            table.insert(lines, string.format("   Functions: %d", funcCount))
        end
        
        if analysis.weights then
            local weightCount = 0
            for _ in pairs(analysis.weights) do weightCount = weightCount + 1 end
            table.insert(lines, string.format("   Weight Tables: %d", weightCount))
        end
        
        if analysis.randomCalls then
            table.insert(lines, string.format("   RNG Calls: %d", #analysis.randomCalls))
        end
        
        table.insert(lines, "")
    end
    
    -- Exploits section
    if fullAnalysis.exploits then
        table.insert(lines, "════════════════════════════════════════════════════════")
        table.insert(lines, "🔓 POTENTIAL VULNERABILITIES")
        table.insert(lines, "════════════════════════════════════════════════════════")
        table.insert(lines, "")
        
        if fullAnalysis.exploits.clientSideRNG then
            for _, exploit in ipairs(fullAnalysis.exploits.clientSideRNG) do
                table.insert(lines, string.format("[%s] %s: %s", exploit.risk, exploit.module, exploit.reason))
            end
        end
        
        table.insert(lines, "")
    end
    
    table.insert(lines, "════════════════════════════════════════════════════════")
    table.insert(lines, "✅ ANALYSIS COMPLETE")
    table.insert(lines, "════════════════════════════════════════════════════════")
    
    return table.concat(lines, "\n")
end

-- ========================================
-- MAIN EXECUTION
-- ========================================

local function Main()
    print("\n🚀 Starting full analysis...\n")
    
    -- Initialize
    if not FileManager:Init() then
        warn("Cannot save files - continuing anyway...")
    end
    
    FileManager:CreateFolder("RNGAnalysis")
    FileManager:CreateFolder("RNGAnalysis/Modules")
    FileManager:CreateFolder("RNGAnalysis/Exploits")
    
    -- Find all modules
    local allModules = ModuleFinder:FindAllModules()
    
    -- Full analysis
    local fullAnalysis = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        executor = tostring(identifyexecutor and identifyexecutor() or "Hydrogen"),
        totalModules = ModuleFinder:CountTable(allModules),
        modules = {},
        luckSystems = {},
        rngLogic = {},
        exploits = {}
    }
    
    -- Analyze each module
    print("\n" .. string.rep("=", 60))
    print("DEEP ANALYSIS PHASE")
    print(string.rep("=", 60) .. "\n")
    
    for moduleName, moduleData in pairs(allModules) do
        -- Weight system analysis
        fullAnalysis.modules[moduleName] = RNGAnalyzer:AnalyzeWeightSystem(moduleData.module, moduleName)
        
        -- RNG logic analysis
        fullAnalysis.rngLogic[moduleName] = RNGAnalyzer:FindRNGLogic(moduleData.module, moduleName)
        
        -- Luck modifier analysis
        if moduleName:lower():find("luck") or moduleName:lower():find("modifier") or 
           moduleName:lower():find("enchant") or moduleName:lower():find("potion") then
            fullAnalysis.luckSystems[moduleName] = RNGAnalyzer:AnalyzeLuckModifiers(moduleData.module, moduleName)
        end
    end
    
    -- Find exploits
    fullAnalysis.exploits = ExploitFinder:FindVulnerabilities(fullAnalysis)
    
    -- Save everything
    print("\n" .. string.rep("=", 60))
    print("SAVING RESULTS")
    print(string.rep("=", 60) .. "\n")
    
    -- Save full JSON
    FileManager:WriteFile("RNGAnalysis/full_analysis.json", OutputFormatter:ToJSON(fullAnalysis))
    
    -- Save detailed report
    FileManager:WriteFile("RNGAnalysis/detailed_report.txt", OutputFormatter:ToDetailedReport(fullAnalysis))
    
    -- Save individual module analyses
    for moduleName, analysis in pairs(fullAnalysis.modules) do
        local fileName = string.format("RNGAnalysis/Modules/%s.json", moduleName:gsub("%s+", "_"))
        FileManager:WriteFile(fileName, OutputFormatter:ToJSON(analysis))
    end
    
    -- Save exploit report
    FileManager:WriteFile("RNGAnalysis/Exploits/vulnerabilities.json", OutputFormatter:ToJSON(fullAnalysis.exploits))
    
    -- Print summary
    print("\n" .. string.rep("=", 60))
    print("✅ ANALYSIS COMPLETE!")
    print(string.rep("=", 60))
    print(string.format("\n📊 Analyzed: %d modules", fullAnalysis.totalModules))
    print(string.format("🔓 Found: %d potential vulnerabilities", 
        #(fullAnalysis.exploits.clientSideRNG or {}) + 
        #(fullAnalysis.exploits.predictableSeeds or {})))
    print("\n📂 Files saved to: [Workspace]/RNGAnalysis/")
    print("   • full_analysis.json - Complete data")
    print("   • detailed_report.txt - Human-readable report")
    print("   • Modules/*.json - Individual module analyses")
    print("   • Exploits/vulnerabilities.json - Security analysis")
    
    if setclipboard then
        setclipboard(OutputFormatter:ToDetailedReport(fullAnalysis))
        print("\n✅ Report copied to clipboard!")
    end
    
    return fullAnalysis
end

-- Store globally
_G.RNGAnalyzer = {
    Run = Main,
    Utils = Utils,
    ModuleFinder = ModuleFinder,
    RNGAnalyzer = RNGAnalyzer,
    ExploitFinder = ExploitFinder,
    FileManager = FileManager
}

-- Auto-run
print("\n⏳ Starting in 1 second...\n")
wait(1)
return Main()
