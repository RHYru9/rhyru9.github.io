-- ========================================
-- 🍀 ALL-IN-ONE LUCK ANALYZER & DUMPER
-- Fishing Game Exploit Tool
-- ========================================

_G.LuckAnalyzer = _G.LuckAnalyzer or {}
local LA = _G.LuckAnalyzer

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Config
LA.Config = {
    AutoExport = true,
    ShowNotifications = true,
    DebugMode = true
}

-- Storage
LA.Data = {
    Modules = {},
    Remotes = {},
    Analysis = {},
    DumpedCode = {}
}

print([[
╔════════════════════════════════════════╗
║   🍀 LUCK ANALYZER LOADED 🍀          ║
║   Fishing Game Exploit Tool            ║
╚════════════════════════════════════════╝
]])

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

function LA:Log(msg, prefix)
    prefix = prefix or "INFO"
    local colors = {
        INFO = "[ℹ️ INFO]",
        SUCCESS = "[✅ SUCCESS]",
        ERROR = "[❌ ERROR]",
        WARNING = "[⚠️ WARNING]",
        DEBUG = "[🔍 DEBUG]"
    }
    print(string.format("%s %s", colors[prefix] or prefix, msg))
end

function LA:Notify(title, text, duration)
    if not self.Config.ShowNotifications then return end
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 3
    })
end

function LA:SafeRequire(module)
    local success, result = pcall(function()
        return require(module)
    end)
    return success and result or nil
end

function LA:FindInstance(name, recursive)
    return ReplicatedStorage:FindFirstChild(name, recursive or true)
end

-- ========================================
-- MODULE SCANNER
-- ========================================

function LA:ScanLuckModules()
    self:Log("Starting module scan...", "INFO")
    self:Notify("Scanning", "Searching for luck modules...", 2)
    
    local keywords = {
        "Luck", "DoubleLuck", "RollData", "Weight",
        "Enchant", "Potion", "Modifier", "Passive",
        "GamePass", "Product", "Fishing"
    }
    
    local found = 0
    
    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("ModuleScript") then
            local name = child.Name
            
            for _, keyword in ipairs(keywords) do
                if string.find(name, keyword) then
                    local moduleData = {
                        Name = name,
                        Path = child:GetFullName(),
                        Instance = child,
                        Exports = {}
                    }
                    
                    -- Try to get exports
                    local module = self:SafeRequire(child)
                    if module and type(module) == "table" then
                        for k, v in pairs(module) do
                            moduleData.Exports[k] = type(v)
                        end
                    end
                    
                    table.insert(self.Data.Modules, moduleData)
                    found = found + 1
                    self:Log(string.format("Found: %s", name), "SUCCESS")
                    break
                end
            end
        end
    end
    
    self:Notify("Scan Complete", string.format("Found %d modules", found), 3)
    return self.Data.Modules
end

-- ========================================
-- REMOTE SCANNER
-- ========================================

function LA:ScanLuckRemotes()
    self:Log("Starting remote scan...", "INFO")
    self:Notify("Scanning", "Searching for luck remotes...", 2)
    
    local keywords = {
        "Luck", "Potion", "GamePass", "Purchase",
        "Product", "Enchant", "Roll", "Consume"
    }
    
    local found = 0
    
    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
            local name = child.Name
            
            for _, keyword in ipairs(keywords) do
                if string.find(name, keyword) then
                    local remoteData = {
                        Name = name,
                        Type = child.ClassName,
                        Path = child:GetFullName(),
                        Instance = child
                    }
                    
                    if child:IsA("RemoteEvent") then
                        remoteData.Usage = "remote:FireServer(...)"
                    else
                        remoteData.Usage = "remote:InvokeServer(...)"
                    end
                    
                    table.insert(self.Data.Remotes, remoteData)
                    found = found + 1
                    self:Log(string.format("Found: %s (%s)", name, child.ClassName), "SUCCESS")
                    break
                end
            end
        end
    end
    
    self:Notify("Scan Complete", string.format("Found %d remotes", found), 3)
    return self.Data.Remotes
end

-- ========================================
-- MODULE DUMPER
-- ========================================

function LA:DumpModule(moduleName)
    self:Log(string.format("Dumping: %s", moduleName), "INFO")
    
    local module = self:FindInstance(moduleName, true)
    if not module then
        self:Log(string.format("Module not found: %s", moduleName), "ERROR")
        return nil
    end
    
    local source = nil
    local method = "Unknown"
    
    -- Method 1: Direct source
    pcall(function()
        if module.Source and module.Source ~= "" then
            source = module.Source
            method = "DirectSource"
        end
    end)
    
    -- Method 2: Decompiler
    if not source and decompile then
        pcall(function()
            source = decompile(module)
            method = "Decompiled"
        end)
    end
    
    -- Method 3: Export structure
    if not source then
        local exports = self:SafeRequire(module)
        if exports and type(exports) == "table" then
            source = "-- Exports from: " .. moduleName .. "\nreturn {\n"
            for k, v in pairs(exports) do
                source = source .. string.format('    ["%s"] = %s,\n', k, type(v))
            end
            source = source .. "}"
            method = "ExportStructure"
        end
    end
    
    if source then
        local data = {
            Name = moduleName,
            Path = module:GetFullName(),
            Method = method,
            Source = source,
            Size = #source
        }
        
        table.insert(self.Data.DumpedCode, data)
        self:Log(string.format("✅ Dumped: %s (%d chars, %s)", moduleName, #source, method), "SUCCESS")
        return data
    else
        self:Log(string.format("❌ Failed to dump: %s", moduleName), "ERROR")
        return nil
    end
end

function LA:DumpAll()
    self:Log("Starting mass dump...", "INFO")
    self:Notify("Dumping", "Extracting all modules...", 2)
    
    local targets = {
        "DoubleLuckProducts", "DoubleLuckController",
        "RollData", "WeightRandom", "FishWeightChances",
        "FishingController", "FishingRodModifiers",
        "Enchants", "Effects", "Potions", "PotionController",
        "GamePass", "GamePassUtility",
        "PassivesRunner", "PassivesUtility", "PassivesTypes",
        "ItemUtility", "PlayerStatsUtility", "Constants"
    }
    
    local dumped = 0
    for _, name in ipairs(targets) do
        if self:DumpModule(name) then
            dumped = dumped + 1
        end
        task.wait(0.1)
    end
    
    self:Notify("Dump Complete", string.format("Dumped %d modules", dumped), 3)
end

-- ========================================
-- REPORT GENERATOR
-- ========================================

function LA:GenerateReport()
    local report = string.format([[
╔════════════════════════════════════════╗
║       LUCK SYSTEM ANALYSIS REPORT       ║
╚════════════════════════════════════════╝

Generated: %s
Game: Fishing Game

════════════════════════════════════════
📦 MODULES FOUND: %d
════════════════════════════════════════
]], os.date("%Y-%m-%d %H:%M:%S"), #self.Data.Modules)
    
    for i, mod in ipairs(self.Data.Modules) do
        report = report .. string.format("\n%d. %s\n   Path: %s\n   Exports: %d\n",
            i, mod.Name, mod.Path, self:CountTable(mod.Exports))
    end
    
    report = report .. string.format([[

════════════════════════════════════════
📡 REMOTES FOUND: %d
════════════════════════════════════════
]], #self.Data.Remotes)
    
    for i, rem in ipairs(self.Data.Remotes) do
        report = report .. string.format("\n%d. %s (%s)\n   Path: %s\n   Usage: %s\n",
            i, rem.Name, rem.Type, rem.Path, rem.Usage)
    end
    
    report = report .. string.format([[

════════════════════════════════════════
💾 DUMPED CODE: %d modules
════════════════════════════════════════
]], #self.Data.DumpedCode)
    
    for i, dump in ipairs(self.Data.DumpedCode) do
        report = report .. string.format("\n%d. %s\n   Method: %s\n   Size: %d chars\n",
            i, dump.Name, dump.Method, dump.Size)
    end
    
    report = report .. "\n" .. string.rep("=", 50) .. "\n"
    
    return report
end

function LA:CountTable(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

-- ========================================
-- EXPORT FUNCTIONS
-- ========================================

function LA:Export()
    self:Log("Generating report...", "INFO")
    
    local report = self:GenerateReport()
    print("\n" .. report)
    
    -- Copy to clipboard
    if setclipboard then
        setclipboard(report)
        self:Notify("Exported", "Report copied to clipboard!", 3)
    end
    
    -- Save to file
    if writefile then
        writefile("LuckAnalysisReport.txt", report)
        self:Log("Report saved to: LuckAnalysisReport.txt", "SUCCESS")
    end
    
    -- Export dumped code
    if #self.Data.DumpedCode > 0 then
        local allCode = "-- DUMPED MODULES\n-- " .. os.date() .. "\n\n"
        for _, dump in ipairs(self.Data.DumpedCode) do
            allCode = allCode .. string.format([[
-- ========================================
-- %s (%s)
-- ========================================
%s

]], dump.Name, dump.Method, dump.Source)
        end
        
        if writefile then
            writefile("DumpedModules.lua", allCode)
            self:Log("Dumped code saved to: DumpedModules.lua", "SUCCESS")
        end
        
        if setclipboard then
            setclipboard(allCode)
            self:Notify("Exported", "Dumped code copied!", 3)
        end
    end
end

-- ========================================
-- QUICK COMMANDS
-- ========================================

function LA:QuickScan()
    self:ScanLuckModules()
    task.wait(0.5)
    self:ScanLuckRemotes()
    task.wait(0.5)
    self:Export()
end

function LA:FullAnalysis()
    self:ScanLuckModules()
    task.wait(0.5)
    self:ScanLuckRemotes()
    task.wait(0.5)
    self:DumpAll()
    task.wait(0.5)
    self:Export()
end

-- ========================================
-- HELPER MENU
-- ========================================

function LA:ShowMenu()
    print([[
╔════════════════════════════════════════╗
║            AVAILABLE COMMANDS           ║
╚════════════════════════════════════════╝

_G.LuckAnalyzer:QuickScan()
  └─ Scan modules & remotes only

_G.LuckAnalyzer:FullAnalysis()
  └─ Full scan + dump all code

_G.LuckAnalyzer:ScanLuckModules()
  └─ Scan modules only

_G.LuckAnalyzer:ScanLuckRemotes()
  └─ Scan remotes only

_G.LuckAnalyzer:DumpAll()
  └─ Dump all target modules

_G.LuckAnalyzer:Export()
  └─ Generate & export report

_G.LuckAnalyzer:ShowMenu()
  └─ Show this menu

════════════════════════════════════════
QUICK START:
_G.LuckAnalyzer:FullAnalysis()

Then paste the output to chat!
════════════════════════════════════════
]])
end

-- ========================================
-- AUTO START
-- ========================================

LA:ShowMenu()
LA:Notify("Luck Analyzer", "Type _G.LuckAnalyzer:ShowMenu() for help", 5)

return LA
