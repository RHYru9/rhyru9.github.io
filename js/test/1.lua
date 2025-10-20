-- ========================================
-- 💾 MAC FILE SAVER (OPTIMIZED)
-- Save analysis to executor workspace
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

print([[
╔════════════════════════════════════════╗
║    💾 MAC FILE SAVER OPTIMIZED 💾     ║
║  Auto-analyzing and saving files...    ║
╚════════════════════════════════════════╝
]])

-- ========================================
-- FILE MANAGER
-- ========================================

local FileManager = {}

function FileManager:Init()
    -- Check executor capabilities
    self.canWrite = writefile ~= nil
    self.canMakeFolder = makefolder ~= nil
    self.canListFiles = listfiles ~= nil
    
    if not self.canWrite then
        warn("⚠️ writefile() not supported - files cannot be saved!")
        return false
    end
    
    print("✅ Executor supports file operations")
    return true
end

function FileManager:CreateFolder(folderName)
    if not self.canMakeFolder then return false end
    
    local success, err = pcall(function()
        makefolder(folderName)
    end)
    
    return success
end

function FileManager:WriteFile(fileName, content)
    if not self.canWrite then return false end
    
    local success, err = pcall(function()
        writefile(fileName, content)
    end)
    
    if success then
        print(string.format("✅ Saved: %s", fileName))
        return true
    else
        warn(string.format("❌ Failed: %s - %s", fileName, tostring(err)))
        return false
    end
end

function FileManager:ListFiles(folderName)
    if not self.canListFiles then return {} end
    
    local success, files = pcall(function()
        return listfiles(folderName)
    end)
    
    return success and files or {}
end

-- ========================================
-- ANALYSIS ENGINE
-- ========================================

local AnalysisEngine = {}

function AnalysisEngine:FindModule(moduleName)
    local found = ReplicatedStorage:FindFirstChild(moduleName, true)
    if found then
        local success, module = pcall(require, found)
        if success then
            return module
        end
    end
    return nil
end

function AnalysisEngine:AnalyzeTable(tbl, depth)
    depth = depth or 0
    if depth > 3 then return {} end
    
    local result = {}
    
    for k, v in pairs(tbl) do
        local vtype = type(v)
        
        if vtype == "table" then
            result[k] = {
                type = "table",
                keys = self:GetTableKeys(v)
            }
        elseif vtype == "function" then
            result[k] = {
                type = "function",
                callable = true
            }
        else
            result[k] = {
                type = vtype,
                value = tostring(v):sub(1, 100)
            }
        end
    end
    
    return result
end

function AnalysisEngine:GetTableKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, tostring(k))
    end
    return keys
end

function AnalysisEngine:RunFullAnalysis()
    local analysis = {
        timestamp = os.date("%Y-%m-%d %H:%M:%S"),
        executor = tostring(identifyexecutor and identifyexecutor() or "Unknown"),
        modules = {}
    }
    
    print("\n📊 Starting analysis...\n")
    
    -- Key modules to analyze
    local targetModules = {
        "RollData",
        "WeightRandom",
        "FishingRodModifiers",
        "Enchants",
        "Potions",
        "DoubleLuckProducts",
        "DoubleLuckController"
    }
    
    for _, moduleName in ipairs(targetModules) do
        local module = self:FindModule(moduleName)
        if module then
            print(string.format("  [✓] %s", moduleName))
            analysis.modules[moduleName] = self:AnalyzeTable(module)
        else
            print(string.format("  [✗] %s (not found)", moduleName))
        end
    end
    
    print("\n✅ Analysis complete!\n")
    
    return analysis
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

function OutputFormatter:ToLua(data, varName)
    varName = varName or "AnalysisData"
    
    local function serialize(tbl, indent)
        indent = indent or 0
        local s = string.rep("  ", indent)
        local lines = {"{"}
        
        for k, v in pairs(tbl) do
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
    
    return string.format([[
-- ========================================
-- RNG Analysis Export
-- Generated: %s
-- ========================================

local %s = %s

return %s
]], os.date("%Y-%m-%d %H:%M:%S"), varName, serialize(data), varName)
end

function OutputFormatter:ToMarkdown(analysis)
    local lines = {
        "# 🎲 RNG System Analysis",
        "",
        string.format("**Generated:** %s", analysis.timestamp),
        string.format("**Executor:** %s", analysis.executor),
        "",
        "---",
        "",
        "## 📊 Modules Analyzed",
        ""
    }
    
    for moduleName, data in pairs(analysis.modules) do
        table.insert(lines, string.format("### %s", moduleName))
        table.insert(lines, "")
        
        local count = 0
        for _ in pairs(data) do count = count + 1 end
        table.insert(lines, string.format("**Items found:** %d", count))
        table.insert(lines, "")
    end
    
    return table.concat(lines, "\n")
end

function OutputFormatter:ToText(analysis)
    local lines = {
        "════════════════════════════════════════",
        "    🎲 RNG SYSTEM ANALYSIS REPORT    ",
        "════════════════════════════════════════",
        "",
        string.format("Generated: %s", analysis.timestamp),
        string.format("Executor: %s", analysis.executor),
        "",
        "════════════════════════════════════════",
        "📊 MODULES ANALYZED",
        "════════════════════════════════════════",
        ""
    }
    
    for moduleName, data in pairs(analysis.modules) do
        local count = 0
        for _ in pairs(data) do count = count + 1 end
        table.insert(lines, string.format("[✓] %s (%d items)", moduleName, count))
    end
    
    table.insert(lines, "")
    table.insert(lines, "════════════════════════════════════════")
    table.insert(lines, "✅ FILES SAVED TO: LuckAnalysis/")
    table.insert(lines, "════════════════════════════════════════")
    table.insert(lines, "")
    table.insert(lines, "📋 Copy these files to your Mac:")
    table.insert(lines, "   /Users/apple/rey/bug/lua/test/")
    
    return table.concat(lines, "\n")
end

-- ========================================
-- MAIN EXECUTION
-- ========================================

local function Main()
    -- Initialize file manager
    if not FileManager:Init() then
        warn("❌ Cannot proceed without file write support")
        return
    end
    
    -- Create output folder
    print("📁 Creating LuckAnalysis folder...")
    FileManager:CreateFolder("LuckAnalysis")
    
    -- Run analysis
    local analysis = AnalysisEngine:RunFullAnalysis()
    
    -- Save in multiple formats
    print("💾 Saving files...\n")
    
    local formats = {
        {name = "analysis.json", content = OutputFormatter:ToJSON(analysis)},
        {name = "analysis.lua", content = OutputFormatter:ToLua(analysis)},
        {name = "analysis.md", content = OutputFormatter:ToMarkdown(analysis)},
        {name = "analysis.txt", content = OutputFormatter:ToText(analysis)}
    }
    
    local savedCount = 0
    for _, format in ipairs(formats) do
        if FileManager:WriteFile("LuckAnalysis/" .. format.name, format.content) then
            savedCount = savedCount + 1
        end
    end
    
    -- Summary
    print("")
    print("════════════════════════════════════════")
    print(string.format("✅ %d files saved successfully!", savedCount))
    print("════════════════════════════════════════")
    print("")
    print("📂 Location: [Executor Workspace]/LuckAnalysis/")
    print("📋 Files: analysis.json, .lua, .md, .txt")
    print("")
    print("💡 Mac sync script should auto-detect")
    print("   these files and copy them!")
    
    -- Copy summary to clipboard
    if setclipboard then
        setclipboard(OutputFormatter:ToText(analysis))
        print("\n✅ Report copied to clipboard!")
    end
    
    return analysis
end

-- Store globally
_G.MacAnalyzer = {
    Run = Main,
    FileManager = FileManager,
    AnalysisEngine = AnalysisEngine,
    OutputFormatter = OutputFormatter
}

-- Auto-run
wait(0.5)
return Main()
