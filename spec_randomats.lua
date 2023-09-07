local startChance = CreateConVar("ttt_spec_randomat_start_chance", 0.2, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The percent chance a spec randomat will trigger when the game starts with the min required spectators", 0, 1)
local deathChance = CreateConVar("ttt_spec_randomat_death_chance", 0.1, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The percent chance a spec randomat will trigger when a player dies and there is already the min required spectators", 0, 1)
local startDelay = 10
local minSpectators = CreateConVar("ttt_spec_randomat_min_spectators", 3, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "The minmum number of spectators required for a spec randomat to trigger", 0, 100)
local events = {
    ["apparition"] = 2,
    ["bets"] = 1,
    ["boo"] = 2,
    ["deadchat"] = 1,
    ["explosivespectate"] = 2,
    ["ghosting"] = 1,
    ["gifts"] = 1,
    ["poltergeists"] = 1,
    ["revenge"] = 2,
    ["smoke"] = 2,
    ["specbees"] = 2,
    ["specbuff"] = 1
}
local triggerOnDeath = CreateConVar("ttt_spec_randomat_trigger_on_death", 1, {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Whether a spec randomat should try to tigger when players die", 0, 1)

local function GetRandomWeightedEvent()
    local weighted_events = {}
    for id, weight in pairs(events) do
        if not Randomat:CanEventRun(id) then continue end

        for _ = 1, weight do
            table.insert(weighted_events, id)
        end
    end
    
    if #weighted_events == 0 then return nil end

    -- Randomize the weighted list
    table.Shuffle(weighted_events)

    -- Then get a random index from the random list for more randomness
    local count = table.Count(weighted_events)
    local idx = math.random(count)
    return weighted_events[idx]
end

hook.Add("TTTBeginRound", "SpectatorRandomats_TTTBeginRound", function()
    if math.random() > startChance:GetFloat() then return end

    local specCount = 0
    for _, p in ipairs(player.GetAll()) do
        if p:IsSpec() or not p:Alive() then
            specCount = specCount + 1
        end
    end

    if specCount < minSpectators:GetInt() then return end
    
    local event = GetRandomWeightedEvent()
    if not event then return end

    print("[SpectatorRandomats] There are " .. specCount .. " spectators. Starting '" .. event .. "' after " .. startDelay .. " seconds.")
    timer.Create("SpectatorRandomatsDelay", startDelay, 1, function()
        -- If one of these is running already, don't start a new one
        for id, _ in pairs(events) do
            if Randomat:IsEventActive(id) then return end
        end

        Randomat:TriggerEvent(event)
    end)
end)

hook.Add("PlayerDeath", "SpectatorRandomats_PlayerDeath", function(victim, infl, attacker)
    if not triggerOnDeath:GetBool() then return end
    if timer.Exists("SpectatorRandomatsDelay") then return end
    if math.random() > deathChance:GetFloat() then return end

    local specCount = 0
    for _, p in ipairs(player.GetAll()) do
        if p:IsSpec() or not p:Alive() then
            specCount = specCount + 1
        end
    end

    if specCount < minSpectators:GetInt() then return end
    
    local event = GetRandomWeightedEvent()
    if not event then return end

    print("[SpectatorRandomats] There are " .. specCount .. " spectators. Starting '" .. event .. "' after " .. startDelay .. " seconds.")
    timer.Create("SpectatorRandomatsDelay", startDelay, 1, function()
        -- If one of these is running already, don't start a new one
        for id, _ in pairs(events) do
            if Randomat:IsEventActive(id) then return end
        end

        Randomat:TriggerEvent(event)
    end)
end)

hook.Add("TTTEndRound", "SpectatorRandomats_TTTEndRound", function()
    timer.Remove("SpectatorRandomatsDelay")
end)
