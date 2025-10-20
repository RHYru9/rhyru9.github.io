-- ========================================
-- 💾 MAC FILE SAVER + OUTPUT FORMATTER
-- Save analysis ke file yang bisa copy ke Mac
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Config untuk Mac path (untuk reference)
local MAC_TARGET_PATH = "/Users/apple/rey/bug/lua/test/"

print([[
╔════════════════════════════════════════╗
║      💾 MAC FILE SAVER LOADED 💾       ║
║   Output akan disimpan ke executor     ║
║   workspace, lalu copy manual ke Mac   ║
╚════════════════════════════════════════╝
]])

-- ========================================
-- FILE MANAGER
-- ========================================

local FileManager = {}

function FileManager:GetExecutorWorkspace()
    -- Coba deteksi executor workspace path
    if isfolder then
        -- Synapse X / Script-Ware / etc
        return "workspace/"
    end
    return ""
end

function FileManager:CreateFolder(folderName)
    if makefolder then
        local success = pcall(function()
            makefolder(folderName)
        end)
        return success
    end
    return false
end

function FileManager:WriteFile(fileName, content)
    if writefile then
        local success, err = pcall(function()
            writefile(fileName, content)
        end)
        
        if success then
            print(string.format("✅ File saved: %s", fileName))
            print(string.format("📂 Executor workspace: %s", self:GetExecutorWorkspace()))
            return true
        else
            print(string.format("❌ Failed to save: %s", tostring(err)))
            return false
        end
    else
        print("❌ writefile() not supported by your executor")
        return false
    end
end

function FileManager:SaveToMacInstructions(fileName)
    local instructions = string.format([[
╔════════════════════════════════════════╗
║     📋 HOW TO COPY TO MAC PATH         ║
╚════════════════════════════════════════╝

File saved in executor workspace: %s

TO COPY TO MAC:
1. Open Finder
2. Press Cmd+Shift+G
3. Paste: %s
4. Buka folder executor Anda (biasanya di Documents atau Downloads)
5. Copy file "%s" dari workspace executor
6. Paste ke folder Mac target

TERMINAL METHOD:
1. Buka Terminal
2. Ketik: cd %s
3. Ketik: mkdir -p lua/test (jika folder belum ada)
4. Copy manual file dari executor workspace

FILE LOCATION:
- Executor workspace: [Check executor documentation]
- Target Mac path: %s

]], fileName, MAC_TARGET_PATH, fileName, MAC_TARGET_PATH, MAC_TARGET_PATH)
    
    return instructions
end

-- ========================================
-- OUTPUT FORMATTERS
-- ========================================

local OutputFormatter = {}

function OutputFormatter:FormatJSON(data)
    if HttpService then
        local success, json = pcall(function()
            return HttpService:JSONEncode(data)
        end)
        if success then
            return json
        end
    end
    return "ERROR: Could not encode JSON"
end

function OutputFormatter:FormatLua(data, tableName)
    tableName = tableName or "AnalysisData"
    
    local function serializeTable(tbl, indent)
        indent = indent or 0
        local spacing = string.rep("    ", indent)
        local result = "{\n"
        
        for k, v in pairs(tbl) do
            local key = type(k) == "string" and string.format('["%s"]', k) or string.format("[%s]", k)
            
            if type(v) == "table" then
                result = result .. spacing .. "    " .. key .. " = " .. serializeTable(v, indent + 1) .. ",\n"
            elseif type(v) == "string" then
                result = result .. spacing .. "    " .. key .. ' = "' .. v .. '",\n'
            elseif type(v) == "number" or type(v) == "boolean" then
                result = result .. spacing .. "    " .. key .. " = " .. tostring(v) .. ",\n"
            else
                result = result .. spacing .. "    " .. key .. ' = "' .. tostring(v) .. '",\n'
            end
        end
        
        result = result .. spacing .. "}"
        return result
    end
    
    local luaCode = string.format([[
-- ========================================
-- Analysis Data Export
-- Generated: %s
-- Target: %s
-- ========================================

local %s = %s

return %s
]], os.date("%Y-%m-%d %H:%M:%S"), MAC_TARGET_PATH, tableName, serializeTable(data, 0), tableName)
    
    return luaCode
end

function OutputFormatter:FormatMarkdown(analysis)
    local md = string.format([[
# 🎲 RNG System Analysis Report

**Generated:** %s  
**Target Mac Path:** `%s`

---

## 📊 Analysis Summary

### RNG Modules Found
%s

### Luck Modifiers
%s

### Roll Functions
%s

### Exploit Opportunities
%s

---

## 📝 Detailed Findings

### 1. RNG System Components
]], os.date("%Y-%m-%d %H:%M:%S"), MAC_TARGET_PATH, 
        self:CountItems(analysis.RNGModules or {}),
        self:CountItems(analysis.LuckModifiers or {}),
        self:CountItems(analysis.RollFunctions or {}),
        "See detailed analysis below")
    
    return md
end

function OutputFormatter:CountItems(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return string.format("**Total:** %d items", count)
end

-- ========================================
-- MAIN ANALYSIS WITH AUTO-SAVE
-- ========================================

local function RunAnalysisWithAutoSave()
    print("\n🚀 Starting Analysis with Auto-Save...\n")
    
    -- Create output folder
    FileManager:CreateFolder("LuckAnalysis")
    
    -- Run analysis (simplified version)
    local Analysis = {
        RNGModules = {},
        LuckModifiers = {},
        RollFunctions = {},
        Timestamp = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    print("📊 Analyzing modules...")
    
    -- Analyze RollData
    local RollData = require(ReplicatedStorage:FindFirstChild("RollData", true))
    if RollData then
        Analysis.RNGModules.RollData = {}
        for k, v in pairs(RollData) do
            Analysis.RNGModules.RollData[k] = type(v)
            print(string.format("  [RollData] %s: %s", k, type(v)))
        end
    end
    
    -- Analyze WeightRandom
    local WeightRandom = require(ReplicatedStorage:FindFirstChild("WeightRandom", true))
    if WeightRandom then
        Analysis.RNGModules.WeightRandom = {}
        for k, v in pairs(WeightRandom) do
            Analysis.RNGModules.WeightRandom[k] = type(v)
            if type(v) == "function" then
                Analysis.RollFunctions[k] = "function"
                print(string.format("  [WeightRandom] 🎲 %s", k))
            end
        end
    end
    
    -- Analyze Luck Modifiers
    local modules = {
        "FishingRodModifiers",
        "Enchants",
        "Potions",
        "DoubleLuckProducts",
        "DoubleLuckController"
    }
    
    for _, moduleName in ipairs(modules) do
        local module = ReplicatedStorage:FindFirstChild(moduleName, true)
        if module then
            local required = require(module)
            if required then
                Analysis.LuckModifiers[moduleName] = {}
                for k, v in pairs(required) do
                    Analysis.LuckModifiers[moduleName][k] = type(v)
                    print(string.format("  [%s] %s: %s", moduleName, k, type(v)))
                end
            end
        end
    end
    
    print("\n💾 Saving files...\n")
    
    -- Save as JSON
    local jsonData = OutputFormatter:FormatJSON(Analysis)
    FileManager:WriteFile("LuckAnalysis/analysis.json", jsonData)
    
    -- Save as Lua
    local luaData = OutputFormatter:FormatLua(Analysis, "LuckAnalysisData")
    FileManager:WriteFile("LuckAnalysis/analysis.lua", luaData)
    
    -- Save as Markdown
    local mdData = OutputFormatter:FormatMarkdown(Analysis)
    FileManager:WriteFile("LuckAnalysis/analysis.md", mdData)
    
    -- Save detailed text report
    local textReport = string.format([[
╔════════════════════════════════════════╗
║     🎲 RNG SYSTEM ANALYSIS REPORT     ║
╚════════════════════════════════════════╝

Generated: %s
Target Mac Path: %s

════════════════════════════════════════
📊 SUMMARY
════════════════════════════════════════

RNG Modules Found: %d
Luck Modifiers: %d
Roll Functions: %d

════════════════════════════════════════
📁 FILES SAVED
════════════════════════════════════════

1. analysis.json - JSON format
2. analysis.lua - Lua table format
3. analysis.md - Markdown format
4. analysis.txt - This text report

════════════════════════════════════════
📋 COPY TO MAC INSTRUCTIONS
════════════════════════════════════════

%s

════════════════════════════════════════
✅ ANALYSIS COMPLETE
════════════════════════════════════════
]], 
        os.date("%Y-%m-%d %H:%M:%S"),
        MAC_TARGET_PATH,
        FileManager:CountTable(Analysis.RNGModules),
        FileManager:CountTable(Analysis.LuckModifiers),
        FileManager:CountTable(Analysis.RollFunctions),
        FileManager:SaveToMacInstructions("LuckAnalysis/*.*")
    )
    
    FileManager:WriteFile("LuckAnalysis/analysis.txt", textReport)
    
    print(textReport)
    
    -- Copy summary to clipboard
    if setclipboard then
        setclipboard(textReport)
        print("\n✅ Report copied to clipboard!")
    end
    
    print("\n" .. string.rep("=", 60))
    print("✅ ALL FILES SAVED!")
    print(string.rep("=", 60))
    print("\n📂 Files location: [Executor Workspace]/LuckAnalysis/")
    print("📋 Check console for Mac copy instructions")
    print("\n💡 TIP: Check your executor documentation for workspace location")
    
    return Analysis
end

function FileManager:CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- ========================================
-- QUICK COMMANDS
-- ========================================

print([[
╔════════════════════════════════════════╗
║         💡 QUICK COMMANDS 💡           ║
╚════════════════════════════════════════╝

AUTOMATIC (Recommended):
Just wait, script will auto-analyze and save!

MANUAL COMMANDS:
_G.SaveToMac = {
    Analyze = function() -- Run full analysis
    ShowPath = function() -- Show Mac path info
    GetFiles = function() -- List saved files
}

════════════════════════════════════════
]])

-- Store globally for later use
_G.SaveToMac = {
    FileManager = FileManager,
    OutputFormatter = OutputFormatter,
    Analysis = nil,
    
    Analyze = function()
        _G.SaveToMac.Analysis = RunAnalysisWithAutoSave()
        return _G.SaveToMac.Analysis
    end,
    
    ShowPath = function()
        print(FileManager:SaveToMacInstructions("LuckAnalysis/*.*"))
    end,
    
    GetFiles = function()
        if listfiles then
            local files = listfiles("LuckAnalysis")
            print("\n📁 Saved files:")
            for _, file in ipairs(files) do
                print("  • " .. file)
            end
        else
            print("❌ listfiles() not supported")
        end
    end
}

-- Auto-run analysis
wait(1)
return RunAnalysisWithAutoSave()
