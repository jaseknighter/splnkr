-- todo: update start/stop functions to remember state for each voice

Sequencer = {}

function Sequencer:new(lattice,id)
  local s = setmetatable({}, { __index = Sequencer })
  s.lattice = lattice
  s.id = id

  s.sequin_set = Sequinset.new(9)

  s.sequins = Sequins{table.unpack(s.sequin_set)}

  s.division = 1
  s.enabled = true
  s.pattern = lattice:new_pattern{
    action = function(t) 
      if s.id == sequencer_controller.get_active_sequin_groups() then
        s:pattern_event(t)
      end
    end,
    division = s.division, --1/16,
    enabled = s.enabled
  }

  function s:pattern_event()
    -- print("s.sequins.ix",s.sequins.ix,params:get("num_sequin"))
    
    if s.sequins.ix < params:get("num_sequin") then
      s.next_sequin = s.sequins()
    else
      s.sequins:select(1)
      s.next_sequin = s.sequins()
    end
    -- print("pattern event")
    if sequencer_controller.sequencers and sequencer_controller.sequencers[1] and sequencer_controller.sequencers[1].next_sequin then
      -- print("next_sequin",sequencer_controller.sequencers[1].next_sequin.id)
    end
    local flicker_time = 1/16 
    grid_sequencer:register_flicker_at(5+s.next_sequin.id, 1, flicker_time)
    sequin_processor.process(s.next_sequin)
    -- print("next_sequin",next_sequin)
  end
  
  function s:start()
    sample_player.set_play_mode(1,1)
  end
  
  function s:stop()
    sample_player.set_play_mode(0,1)
  end

  return s
end

return Sequencer