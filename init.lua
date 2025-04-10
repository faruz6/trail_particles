local TRAIL_INTERVAL = 0.2
local trail_timers = {}
local trail_particles = {}

-- Trail definitions
local BASE_TRAILS = {
    sparkle = {
        walk = { texture = "default_mese_particle.png", size = 1.5, color = "#00ffff" },
        sprint = { texture = "default_mese_particle.png", size = 2.2, color = "#ff0000" }
    },
    flame = {
        walk = { texture = "flame.png", size = 5, color = "#ffa500" },
        sprint = { texture = "flame.png", size = 3, color = "#ff4500" }
    },
}

-- Check sprinting based on velocity (more reliable across PC/mobile)
local function is_sprinting(player)
    local vel = player:get_velocity()
    local speed = math.sqrt(vel.x * vel.x + vel.z * vel.z)
    return speed > 4.2 -- Adjust this threshold if needed based on your sprint speed
end

-- Load saved trail
minetest.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    local trail = player:get_attribute("trail_particles:trail")
    if trail then
        trail_particles[name] = trail
    end
end)

-- Save trail on leave
minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    local trail = trail_particles[name]
    if trail then
        player:set_attribute("trail_particles:trail", trail)
    end
end)

-- Show particle trail
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        trail_timers[name] = (trail_timers[name] or 0) + dtime
        if trail_timers[name] < TRAIL_INTERVAL then goto continue end
        trail_timers[name] = 0

        local trail_type = trail_particles[name]
        local def = BASE_TRAILS[trail_type or ""]
        if not def then goto continue end

        local pos = vector.add(player:get_pos(), {x = 0, y = 1, z = 0})
        local trail_def = is_sprinting(player) and def.sprint or def.walk

        local spread = 0.4
        local offset = {
            x = math.random(-spread*150, spread*150) / 100,
            y = math.random(-30, 10) / 100,
            z = math.random(-spread*150, spread*150) / 100,
        }
        pos = vector.add(pos, offset)

        minetest.add_particle({
            pos = pos,
            velocity = {x = 0, y = 0.01, z = 0},
            acceleration = {x = 0, y = 0.5, z = 0},
            expirationtime = 0.6,
            size = trail_def.size,
            texture = trail_def.texture,
            glow = 8,
            collisiondetection = false,
        })

        ::continue::
    end
end)

-- Chat commands
minetest.register_chatcommand("trail", {
    params = "<sparkle|flame|none>",
    description = "Choose your particle trail",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found." end

        if param == "none" then
            trail_particles[name] = nil
            player:set_attribute("trail_particles:trail", "")
            return true, "Trail disabled"
        elseif BASE_TRAILS[param] then
            trail_particles[name] = param
            player:set_attribute("trail_particles:trail", param)
            return true, "Trail set to " .. param
        else
            return false, "Available: sparkle, flame, none"
        end
    end
})

minetest.register_chatcommand("settrail", {
    params = "<trail> <playername>",
    description = "Admin-only: Set a trail for a player",
    privs = {server = true},
    func = function(name, param)
        local args = param:split(" ")
        local trail = args[1]
        local target = args[2]
        if not trail or not target then return false, "Usage: /settrail <trail> <player>" end

        if not BASE_TRAILS[trail] and trail ~= "none" then
            return false, "Invalid trail type"
        end

        local player = minetest.get_player_by_name(target)
        if not player then return false, "Player not found" end

        if trail == "none" then
            trail_particles[target] = nil
            player:set_attribute("trail_particles:trail", "")
            return true, "Trail removed from " .. target
        else
            trail_particles[target] = trail
            player:set_attribute("trail_particles:trail", trail)
            return true, "Trail '" .. trail .. "' set for " .. target
        end
    end
})
