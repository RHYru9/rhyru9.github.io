-- ========================================
-- 🎲 DEEP RNG & LUCK SYSTEM ANALYZER
-- Fishing Game RNG System Deep Dive
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print([[
╔════════════════════════════════════════╗
║     🎲 RNG SYSTEM DEEP ANALYZER 🎲     ║
║    Analyzing Fishing Game Mechanics    ║
╚════════════════════════════════════════╝
]])

-- ========================================
-- DATA STORAGE
-- ========================================

local Analysis = {
    RNGModules = {},
    LuckModifiers = {},
    RollFunctions = {},
    WeightSystems = {},
    Multipliers = {},
    ServerChecks = {},
    ClientFunctions = {}
}

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

local function SafeRequire(module)
    local success, result = pcall(function()
        return require(module)
    end)
    if success then
        return result
    end
    return nil
end

local function DeepInspect(tbl, name, depth)
    depth = depth or 0
    if depth > 3 then return end
    
    local indent = string.rep("  ", depth)
    print(indent .. "📦 " .. name .. " = {")
    
    for k, v in pairs(tbl) do
        local keyStr = type(k) == "string" and k or tostring(k)
        
        if type(v) == "function" then
            print(indent .. "  🔧 " .. keyStr .. " = function")
            
            -- Try to get function info
            local info = debug.getinfo(v)
            if info then
                print(indent .. "     └─ Params: " .. (info.nparams or "?"))
                print(indent .. "     └─ Source: " .. (info.short_src or "?"))
            end
            
        elseif type(v) == "table" then
            if depth < 2 then
                DeepInspect(v, keyStr, depth + 1)
            else
                print(indent .. "  📋 " .. keyStr .. " = {...}")
            end
            
        elseif type(v) == "number" then
            print(indent .. "  🔢 " .. keyStr .. " = " .. tostring(v))
            
        elseif type(v) == "string" then
            print(indent .. "  📝 " .. keyStr .. ' = "' .. v .. '"')
            
        else
            print(indent .. "  ❓ " .. keyStr .. " = " .. tostring(v))
        end
    end
    
    print(indent .. "}")
end

-- ========================================
-- MODULE ANALYZERS
-- ========================================

local function AnalyzeRollData()
    print("\n" .. string.rep("=", 60))
    print("📊 ANALYZING: RollData")
    print(string.rep("=", 60))
    
    local RollData = SafeRequire(ReplicatedStorage:FindFirstChild("RollData", true))
    if RollData then
        DeepInspect(RollData, "RollData", 0)
        Analysis.RNGModules.RollData = RollData
        
        -- Check for luck-related keys
        for k, v in pairs(RollData) do
            if string.find(string.lower(tostring(k)), "luck") or 
               string.find(string.lower(tostring(k)), "chance") or
               string.find(string.lower(tostring(k)), "rate") then
                print("🍀 LUCK RELATED: " .. tostring(k) .. " = " .. tostring(v))
                Analysis.LuckModifiers[k] = v
            end
        end
    else
        print("❌ RollData not found")
    end
end

local function AnalyzeWeightRandom()
    print("\n" .. string.rep("=", 60))
    print("⚖️ ANALYZING: WeightRandom")
    print(string.rep("=", 60))
    
    local WeightRandom = SafeRequire(ReplicatedStorage:FindFirstChild("WeightRandom", true))
    if WeightRandom then
        DeepInspect(WeightRandom, "WeightRandom", 0)
        Analysis.RNGModules.WeightRandom = WeightRandom
        
        -- Find roll functions
        for k, v in pairs(WeightRandom) do
            if type(v) == "function" then
                if string.find(string.lower(k), "roll") or 
                   string.find(string.lower(k), "pick") or
                   string.find(string.lower(k), "random") or
                   string.find(string.lower(k), "select") then
                    print("🎲 ROLL FUNCTION: " .. k)
                    Analysis.RollFunctions[k] = v
                end
            end
        end
    else
        print("❌ WeightRandom not found")
    end
end

local function AnalyzeFishWeightChances()
    print("\n" .. string.rep("=", 60))
    print("🐟 ANALYZING: FishWeightChances")
    print(string.rep("=", 60))
    
    local FishWeights = SafeRequire(ReplicatedStorage:FindFirstChild("FishWeightChances", true))
    if FishWeights then
        DeepInspect(FishWeights, "FishWeightChances", 0)
        Analysis.WeightSystems.FishWeights = FishWeights
        
        -- Calculate total weights
        if type(FishWeights) == "table" then
            local totalWeight = 0
            for k, v in pairs(FishWeights) do
                if type(v) == "number" then
                    totalWeight = totalWeight + v
                elseif type(v) == "table" and v.Weight then
                    totalWeight = totalWeight + v.Weight
                end
            end
            print("📊 Total Weight: " .. totalWeight)
        end
    else
        print("❌ FishWeightChances not found")
    end
end

local function AnalyzeFishingRodModifiers()
    print("\n" .. string.rep("=", 60))
    print("🎣 ANALYZING: FishingRodModifiers")
    print(string.rep("=", 60))
    
    local Modifiers = SafeRequire(ReplicatedStorage:FindFirstChild("FishingRodModifiers", true))
    if Modifiers then
        DeepInspect(Modifiers, "FishingRodModifiers", 0)
        Analysis.LuckModifiers.RodModifiers = Modifiers
        
        -- Find luck multipliers
        for k, v in pairs(Modifiers) do
            if type(v) == "table" then
                for key, val in pairs(v) do
                    if string.find(string.lower(tostring(key)), "luck") or
                       string.find(string.lower(tostring(key)), "multi") then
                        print("🍀 LUCK MODIFIER: " .. tostring(k) .. "." .. tostring(key) .. " = " .. tostring(val))
                    end
                end
            end
        end
    else
        print("❌ FishingRodModifiers not found")
    end
end

local function AnalyzeEnchants()
    print("\n" .. string.rep("=", 60))
    print("✨ ANALYZING: Enchants")
    print(string.rep("=", 60))
    
    local Enchants = SafeRequire(ReplicatedStorage:FindFirstChild("Enchants", true))
    if Enchants then
        DeepInspect(Enchants, "Enchants", 0)
        Analysis.LuckModifiers.Enchants = Enchants
        
        -- Find luck-related enchants
        for k, v in pairs(Enchants) do
            if type(v) == "table" then
                for key, val in pairs(v) do
                    if string.find(string.lower(tostring(key)), "luck") or
                       string.find(string.lower(tostring(key)), "chance") or
                       string.find(string.lower(tostring(key)), "rate") then
                        print("🍀 LUCK ENCHANT: " .. tostring(k) .. "." .. tostring(key) .. " = " .. tostring(val))
                    end
                end
            end
        end
    else
        print("❌ Enchants not found")
    end
end

local function AnalyzePotions()
    print("\n" .. string.rep("=", 60))
    print("💊 ANALYZING: Potions")
    print(string.rep("=", 60))
    
    local Potions = SafeRequire(ReplicatedStorage:FindFirstChild("Potions", true))
    if Potions then
        DeepInspect(Potions, "Potions", 0)
        Analysis.LuckModifiers.Potions = Potions
        
        -- Find luck potions
        for k, v in pairs(Potions) do
            if string.find(string.lower(tostring(k)), "luck") then
                print("🍀 LUCK POTION: " .. tostring(k))
                if type(v) == "table" then
                    DeepInspect(v, k, 1)
                end
            end
        end
    else
        print("❌ Potions not found")
    end
end

local function AnalyzeDoubleLuck()
    print("\n" .. string.rep("=", 60))
    print("🍀🍀 ANALYZING: DoubleLuck System")
    print(string.rep("=", 60))
    
    -- DoubleLuckController
    local Controller = SafeRequire(ReplicatedStorage:FindFirstChild("DoubleLuckController", true))
    if Controller then
        print("📱 DoubleLuckController:")
        DeepInspect(Controller, "DoubleLuckController", 0)
        Analysis.LuckModifiers.DoubleLuckController = Controller
    end
    
    -- DoubleLuckProducts
    local Products = SafeRequire(ReplicatedStorage:FindFirstChild("DoubleLuckProducts", true))
    if Products then
        print("\n💰 DoubleLuckProducts:")
        DeepInspect(Products, "DoubleLuckProducts", 0)
        Analysis.LuckModifiers.DoubleLuckProducts = Products
    end
end

local function AnalyzePassives()
    print("\n" .. string.rep("=", 60))
    print("⚡ ANALYZING: Passive System")
    print(string.rep("=", 60))
    
    local PassivesRunner = SafeRequire(ReplicatedStorage:FindFirstChild("PassivesRunner", true))
    if PassivesRunner then
        print("🏃 PassivesRunner:")
        DeepInspect(PassivesRunner, "PassivesRunner", 0)
    end
    
    local PassivesUtility = SafeRequire(ReplicatedStorage:FindFirstChild("PassivesUtility", true))
    if PassivesUtility then
        print("\n🔧 PassivesUtility:")
        DeepInspect(PassivesUtility, "PassivesUtility", 0)
    end
    
    local PassivesTypes = SafeRequire(ReplicatedStorage:FindFirstChild("PassivesTypes", true))
    if PassivesTypes then
        print("\n📋 PassivesTypes:")
        DeepInspect(PassivesTypes, "PassivesTypes", 0)
    end
end

local function AnalyzeFishingController()
    print("\n" .. string.rep("=", 60))
    print("🎣 ANALYZING: FishingController")
    print(string.rep("=", 60))
    
    local FishingController = SafeRequire(ReplicatedStorage:FindFirstChild("FishingController", true))
    if FishingController then
        DeepInspect(FishingController, "FishingController", 0)
        Analysis.ClientFunctions.FishingController = FishingController
        
        -- Find key functions
        for k, v in pairs(FishingController) do
            if type(v) == "function" then
                if string.find(string.lower(k), "roll") or
                   string.find(string.lower(k), "catch") or
                   string.find(string.lower(k), "fish") or
                   string.find(string.lower(k), "luck") then
                    print("🎯 KEY FUNCTION: " .. k)
                end
            end
        end
    end
end

-- ========================================
-- RNG SYSTEM RECONSTRUCTION
-- ========================================

local function ReconstructRNGSystem()
    print("\n" .. string.rep("=", 60))
    print("🔬 RECONSTRUCTING RNG SYSTEM")
    print(string.rep("=", 60))
    
    print("\n📊 RNG FLOW ANALYSIS:")
    print("1. Player casts fishing rod")
    print("2. Server calculates base luck")
    print("3. Modifiers applied:")
    print("   ├─ Rod modifiers")
    print("   ├─ Enchantments")
    print("   ├─ Potions (DoubleLuck)")
    print("   ├─ Game Pass bonuses")
    print("   └─ Passive effects")
    print("4. WeightRandom picks item based on total luck")
    print("5. Server validates and returns result")
    
    print("\n🎲 ROLL FORMULA (ESTIMATED):")
    print("FinalLuck = BaseLuck * RodMultiplier * EnchantMultiplier * PotionMultiplier * GamePassMultiplier")
    print("ItemRoll = WeightRandom(ItemWeights, FinalLuck)")
    
    print("\n🍀 LUCK MULTIPLIERS FOUND:")
    local totalMultipliers = 0
    for category, data in pairs(Analysis.LuckModifiers) do
        print("  📁 " .. category)
        totalMultipliers = totalMultipliers + 1
    end
    print("  Total categories: " .. totalMultipliers)
    
    print("\n🔧 ROLL FUNCTIONS FOUND:")
    for name, func in pairs(Analysis.RollFunctions) do
        print("  🎲 " .. name)
    end
end

-- ========================================
-- EXPLOIT OPPORTUNITIES
-- ========================================

local function FindExploitOpportunities()
    print("\n" .. string.rep("=", 60))
    print("🎯 EXPLOIT OPPORTUNITIES")
    print(string.rep("=", 60))
    
    print("\n✅ POSSIBLE EXPLOITS:")
    
    -- Check for client-side luck calculation
    print("\n1. CLIENT-SIDE LUCK MANIPULATION:")
    if Analysis.ClientFunctions.FishingController then
        print("   ⚠️ FishingController found on client")
        print("   → May be vulnerable to luck spoofing")
        print("   → Try modifying return values")
    end
    
    -- Check for remote functions
    print("\n2. REMOTE FUNCTION ABUSE:")
    print("   🔍 Check these remotes:")
    print("   • ConsumePotion - Might accept spoofed duration")
    print("   • ChargeFishingRod - Might accept luck multiplier")
    print("   • RequestFishingMinigameStarted - Initial luck value?")
    
    -- Check for local calculations
    print("\n3. LOCAL CALCULATION HOOKS:")
    if Analysis.RNGModules.WeightRandom then
        print("   ⚠️ WeightRandom module accessible")
        print("   → Can hook roll functions")
        print("   → Force specific outcomes")
    end
    
    -- Check for multiplier stacking
    print("\n4. MULTIPLIER STACKING:")
    print("   🔍 Try stacking multiple luck sources:")
    print("   • Potion + GamePass + Enchant + Rod")
    print("   → Server might not validate limits")
    
    -- Check for time manipulation
    print("\n5. TIME-BASED EXPLOITS:")
    print("   🔍 If potions use client time:")
    print("   → Manipulate os.time() or tick()")
    print("   → Extend potion duration infinitely")
end

-- ========================================
-- GENERATE EXPLOIT TEMPLATE
-- ========================================

local function GenerateExploitTemplate()
    print("\n" .. string.rep("=", 60))
    print("📝 EXPLOIT TEMPLATE")
    print(string.rep("=", 60))
    
    local template = [[

-- ========================================
-- LUCK EXPLOIT TEMPLATE
-- Based on analysis results
-- ========================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Method 1: Hook WeightRandom
local WeightRandom = require(ReplicatedStorage:FindFirstChild("WeightRandom", true))
local oldRoll = WeightRandom.Roll or WeightRandom.PickWeighted

WeightRandom.Roll = function(...)
    print("🎲 Roll intercepted!")
    -- Force best outcome
    return "LegendaryFish" -- Replace with actual best item
end

-- Method 2: Hook FishingController
local FishingController = require(ReplicatedStorage:FindFirstChild("FishingController", true))
if FishingController.GetLuckMultiplier then
    local oldGetLuck = FishingController.GetLuckMultiplier
    FishingController.GetLuckMultiplier = function(...)
        return 999999 -- Max luck
    end
end

-- Method 3: Spam Potion Remote
local PotionRemote = ReplicatedStorage:FindFirstChild("ConsumePotion", true)
if PotionRemote then
    while true do
        PotionRemote:InvokeServer("DoubleLuck", {Duration = 999999})
        wait(1)
    end
end

-- Method 4: Hook Passives
local PassivesRunner = require(ReplicatedStorage:FindFirstChild("PassivesRunner", true))
-- Modify passive effects here

print("✅ Luck exploit loaded!")
]]
    
    print(template)
    
    if setclipboard then
        setclipboard(template)
        print("\n✅ Template copied to clipboard!")
    end
end

-- ========================================
-- MAIN EXECUTION
-- ========================================

local function RunFullAnalysis()
    print("\n🚀 Starting Deep RNG Analysis...\n")
    
    wait(0.5)
    
    -- Analyze all modules
    AnalyzeRollData()
    wait(0.3)
    
    AnalyzeWeightRandom()
    wait(0.3)
    
    AnalyzeFishWeightChances()
    wait(0.3)
    
    AnalyzeFishingRodModifiers()
    wait(0.3)
    
    AnalyzeEnchants()
    wait(0.3)
    
    AnalyzePotions()
    wait(0.3)
    
    AnalyzeDoubleLuck()
    wait(0.3)
    
    AnalyzePassives()
    wait(0.3)
    
    AnalyzeFishingController()
    wait(0.5)
    
    -- Reconstruction
    ReconstructRNGSystem()
    wait(0.5)
    
    -- Find exploits
    FindExploitOpportunities()
    wait(0.5)
    
    -- Generate template
    GenerateExploitTemplate()
    
    print("\n" .. string.rep("=", 60))
    print("✅ ANALYSIS COMPLETE!")
    print(string.rep("=", 60))
    print("\n📋 Next steps:")
    print("1. Review the analysis above")
    print("2. Copy the exploit template")
    print("3. Modify for your specific needs")
    print("4. Test in-game carefully")
    print("\n⚠️ Be careful with anti-cheat!")
    
    return Analysis
end

-- Run the analysis
return RunFullAnalysis()
