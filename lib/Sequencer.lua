-- todo: update start/stop functions to remember state for each voice

Sequencer = {}

function Sequencer:new(lattice,id)
  local s = setmetatable({}, { __index = Sequencer })
  s.lattice = lattice
  s.id = id

  s.sequin_set = Sequinset.new(9)

  s.seq = Sequins{table.unpack(s.sequin_set)}
  s.sub_seq_leader = Sequins{table.unpack(DEFAULT_SUB_SEQUINS_TAB)}

  s.division = 1
  s.enabled = true
  s.pattern = lattice:new_pattern{
    action = function(t) 
      if s.id == sequencer_controller.get_active_sequinset() then
        s:pattern_event(t)
      end
    end,
    division = s.division, --1/16,
    enabled = s.enabled
  }

  function s:pattern_event()
    local starting_sequin = params:get("starting_sequin")
    if s.seq.ix < starting_sequin then
      s.next_sequin = starting_sequin
    -- else
    --   s.seq:select(1)
    --   s.next_sequin = s.seq()
    end

    local last_sequin = params:get("num_sequin") + params:get("starting_sequin") - 1
    if s.seq.ix < last_sequin  then
      s.next_sequin = s.seq()
    else
      s.seq:select(starting_sequin)
      s.next_sequin = s.seq()
      s.sub_seq_leader()
    end
    s.sub_seq_leader_ix = fn.deep_copy(s.sub_seq_leader.ix)
    -- print("s.sub_seq_leader_ix",s.sub_seq_leader_ix)
    
    -- if sequencer_controller.sequencers and sequencer_controller.sequencers[1] and sequencer_controller.sequencers[1].next_sequin then
    -- end
    local flicker_time = 1/16 
    grid_sequencer:register_flicker_at(5+s.next_sequin.id, 1, flicker_time)
    if sns == nil then 
      sns = s.next_sequin
    end
    sequin_processor.process(s.next_sequin,s.sub_seq_leader_ix)
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