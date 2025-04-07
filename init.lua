local player_trails = {}

-- List of available trails and their settings
local trail_types = {
    sparkle = {
        texture = "default_item_smoke.png",
        glow = 10,
        color = "#ffffff",
    },
    flame = {
        texture = "fire_basic_flame.png",
        glow = 15,
        color = "#ff6600",
    },
    bubble = {
        texture = "bubble.png", -- Make sure you have a bubble.png or change this
        glow = 5,
        color = "#66ccff",
    }
}

-- Chat command to set trail
minetest.register_chatcommand("trail", {
    params = "<none|sparkle|flame|bubble>",
    description = "Set your trail particle effect.",
    func = function(name, param)
        if param == "none" then
            player_trails[name] = nil
            return true, "Trail disabled."
        elseif trail_types[param] then
            player_trails[name] = param
            return true, "Trail set to: " .. param
        else
            return false, "Invalid trail type. Options: none, sparkle, flame, bubble"
        end
    end
})

-- Update particle trails when players move
local last_positions = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local name = player:get_player_name()
        local pos = player:get_pos()
        local last = last_positions[name]

        if last and vector.distance(pos, last) > 0.1 then
            last_positions[name] = vector.new(pos)

            local trail = player_trails[name]
            if trail and trail_types[trail] then
                local effect = trail_types[trail]
                minetest.add_particle({
                    pos = {
                        x = pos.x + math.random(-2, 2) * 0.05,
                        y = pos.y + 0.5,
                        z = pos.z + math.random(-2, 2) * 0.05
                    },
                    velocity = {x = 0, y = 0.2, z = 0},
                    expirationtime = 0.5,
                    size = 1.5,
                    texture = effect.texture,
                    glow = effect.glow,
                })
            end
        else
            last_positions[name] = vector.new(pos)
        end
    end
end)
