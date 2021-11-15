-- sample sequencer
--[[
based on tyler etter's code: https://gist.github.com/tyleretters/a62a27e22dc7021248401f8572287544


  
  register_ui_group properties:
    group_name
    x1,y,1,x2,y2
    off_level

  ui data structures:
    ui_groups 
      active_groups (group_names)
      selected_for editing (uid)
    ui_group 
      group_name
      record_selection_modes
        1 - single selection (e.g. for sequins sets)
        2 - multiple selections
        3 - single flicker selection
      play_selection_modes
        TBD

  
  1 lattice
    each lattice has:
      auto default:true,
      meter default: 4,
      ppqn = 96
  5 patterns per lattice
    each pattern has:
      division = 1,
      enabled = true
      1 sequins set
        each sequins set contains 0-4 sequins sub sets (variations on the main sequins set)
        each sequins set contains up to 9 sequins
          each of the up to 9 sequins can contain 1-7 output typess or nested sequins
            NOTE: IF NESTED SEQUINS ARE SELECTED, THE VALUE SET BUTTON WILL FLICKER
            OUTPUTS:            
              1. sample (softcut voice) with suboptions:
                  play_voice (suboptions 1-6)
                params for each voice
                  sample_cut_num
                  rate
                  rate_direction
                  level
                NOTES: 
                  if the value type is a number, only 1 suboption may be chosen
                  if the value type is an array, multiple suboptions may be chosen
              2. device (synth) outputs: 
                midi: note num), 
                crow: has ___ sub modes 
                  pitch (to voltage)
                  drum
                just friends: has 5 sub modes
                  just friends play_note ([pitch (note num), level]), 
                  just friends play_voice, 
                  just friends pitch (portamento), 
                  postponed -- just friends geode play_voice ([chan, divs, repeats])
                  postponed -- just friends geode play_note ([divs, repeats])
                w_slash: has two sub modes
                  w_syn, 
                  w_delay (karplus), 
                NOTES:
                  ???? if the value type is a number, only 1 suboption may be chosen
                  ???? if the value type is an array, multiple suboptions may be chosen

              3. effects
                  outputs are:
                    amp
                    drywet
                    pitchshift
                    pitchshift offset
                    pitchshift array[1-8 nums per array] (use 2 rows under pattern selectors for array index)
                    phaser
                    delay
              4. enveloper
                default params are for the enveloper:
                  enveloper
                  enveloper trig_rate
                  enveloper overlap

              5. lattice with suboptions:
                set_meter (meter)
                auto_pulse(s)
                pulse
                ppqn
                NOTES:
                  if the value type is a number, only 1 suboption may be chosen
                  if the value type is an array, multiple suboptions may be chosen
              6. pattern  with suboptions:
                division
                stop/start/toggle [1,2,3]
                NOTES:
                  if the value type is a number, only 1 suboption may be chosen
                  if the value type is an array, multiple suboptions may be chosen
              BASED ON THE TARGET SELECTED, 1-6 VALUE SELECTORS WILL LIGHT UP
                  
  each sequence group has up to 5 levels 
  each level has up to 7??? sequins values (steps)
  each sequins value (steps) has 1 main attribute and 1-x subattributes
    1: main attribute (3 options): 
      a. clip to play (screen level 15): 
        data: clip_to_play:x
      b. sub-sequins to play (screen level 7): sub_s[level][step]
        note: the bottom (5th level) can not call another sequence
      c. silence (sreen level 1)
    2: sub attributes:
      clip to play/silence: clip_to_play([value])
        clip_to_play value of 0 equals silence
      duration in time or musical beat (required): duration()
      pattern meter: pattern_meter: [value] 

  step types:
    softcut: 




  UI
    row 1: 
    row 7: select clip
    row 8 (bottom):
      1-3: modes (sequence clips, adjust clips, play (sequenced and free playing))
          Free playing can trigger either a voice (sequence) or a clip

      mode 1 settings: sequence clips
        4: spacer
        5: enable flow modifiers 
        6: spacer
        7-12: voice selector
        7-12: flow modifier selectors (with 6 pressed)
          IMPORTANT: each sequins can have just one modifier, so remember to do a hard reset before changing modifiers
            -- flow-modifiers that might return a value, or might skip
          seq:every(n)   -- produce a value every nth call 
            -- enable with 7: choose n with row 7
          seq:times(n)   -- only produce a value the first n times it's called
            -- enable with 8: choose n with row 7
          seq:cond(math.random(1-16) == 1) -- conditionally produces a value if pred() returns true
            -- enable with 9: choose n with row 7
            -- flow-modifiers that will capture focus
            -- these are 'greedy' modifiers, keeping the spotlight on them
          seq:count(n) -- produce n values in a row without letting other sequins give a value
            -- enable with 10: choose n with row 7
          seq:all()    -- like count(#self), returns all values of seq before returning 
            -- enable with 11 long press: choose n with row 7
            -- modifiers that may return a value, and capture focus
          seq:condr(pred) -- conditionally produces a value if pred() returns true, and captures focus
            -- not implemented
            -- with nested sequins, you can restart the arrangement
          seq:reset() -- resets all flow-modifiers as well as table indices
            -- soft reset: enable with 12
            -- hard reset (remove modifiers): enable with 12 long press
        13: spacer
        15-16: mode switcher (15: filter, 16: sequencer)
          
]]
local grid_sequencer = {}

grid_sequencer.flicker_level = 15

function grid_sequencer.dirtygrid(bool)
  if bool == nil then return grid_dirty end
  grid_dirty = bool
  return grid_dirty
end

function grid_sequencer.init()
  grid_sequencer.grid_views = {'sequencer'}
  grid_sequencer.active_view = 1
  long_presses = {}
  grid_sequencer.long_press_counter = {}
  grid_sequencer.flickers = {}
  grid_sequencer.flicker_counter = nil
  grid_sequencer.flicker_scheduling = false -- 1 = not scheduled, 2 = scheduled, 3 = ready to flicker
  grid_sequencer.solids = {}
  grid_sequencer.ui_groups = {}
  grid_sequencer.animator = {0,0,0}
  grid_sequencer.animation_mode = {0,0,0}
  grid_sequencer.filter_param_overlay = false
  grid_sequencer.frame = 0
  grid_sequencer.last_known_width = g.cols
  grid_sequencer.last_known_height = g.rows
  for i=1,#grid_sequencer.grid_views, 1 do
    -- grid_sequencer.flickers[i] = {}
    grid_sequencer.solids[i] = {}
    for x = 1, grid_sequencer.last_known_width do
      grid_sequencer.long_press_counter[x] = {}
      grid_sequencer.solids[i][x] = {}
      for y = 1, grid_sequencer.last_known_height do
        grid_sequencer.long_press_counter[x][y] = nil
        grid_sequencer.solids[i][x][y] = {}
      end
    end
  end
  

  grid_sequencer.dirtygrid(true)
end

function grid_sequencer.activate_grid_key_at(x,y, delay)
  if delay then clock.sleep(delay) end
  grid_sequencer.key(x, y, 1)
  grid_sequencer.key(x, y, 0)
end

function grid_sequencer.key(x, y, z)
  -- graphics:set_message(x, y, z)
  -- fn.break_splash(true)
  -- fn.dirty_screen(true)
  if z == 1 and (y < 8 or (x > 5 and x < 11)) then
    grid_sequencer.long_press_counter[x][y] = clock.run(grid_sequencer.grid_long_press, g, x, y, grid_sequencer.active_view)
  end
  if z == 0 then -- otherwise, if a grid key is released...
    if grid_sequencer.long_press_counter[x][y] then -- and the long press is still waiting...
      clock.cancel(grid_sequencer.long_press_counter[x][y]) -- then cancel the long press clock,
      -- if y<8 or (x<=3 or (x>4 and x<7) or x == 8) then
      if y<8 or (x > 5 and x < 11) then
        grid_sequencer:short_press(x,y) -- and execute a short press instead.
      end
    end
    grid_sequencer:set_long_press(false,x,y)
  end
end

function grid_sequencer:solid_off(x,y, from_view)
  grid_sequencer:set_current_level_at(x, y, from_view, "off")  
  grid_sequencer:unregister_flicker_at(x, y)
end

function grid_sequencer:solid_on(x,y, from_view, flicker_mode)
  grid_sequencer:set_current_level_at(x, y, from_view, "on")  
  grid_sequencer:register_flicker_at(x, y)
end

function grid_sequencer:key_press(x, y, from_view, press_type, from_norns)
  
  from_view = from_view and from_view or self.active_view
  local ui_group_num = grid_sequencer:find_ui_group_num_by_xy(x, y)
  if ui_group_num then
  -- if y < 8 or x == 5 then -- update filter values
    if from_view == 1 then -- set level
      -- do modething
    elseif from_view == 2 then -- set reciprocal quality
      -- do modething
    elseif from_view == 3 then -- set center frequency
      -- do modething
    end

    local current_level = grid_sequencer:get_current_level_at(x, y, from_view)
    local group = grid_sequencer.ui_groups[ui_group_num]
    if current_level ~= nil then 
      local grid_data = group.grid_data
      if ui_group_num > 0 then
        local group_name = group.group_name
        if current_level ~= "on" then
          -- if ui_group_num <= 5 then 
          if group.selection_mode == 1 or group.selection_mode == 3 or group.selection_mode == 6 then -- single selection
            for i=grid_data.x1,grid_data.x2,1 do
              for j=grid_data.y1,grid_data.y2,1 do
                grid_sequencer:set_current_level_at(i, j, from_view, "off")  
                grid_sequencer:unregister_flicker_at(i, j)
              end
            end
          end
          if group.selection_mode < 3 then 
            grid_sequencer:set_current_level_at(x, y, from_view, "on")
            sequencer_controller:update_group(group_name, x, y, "on", press_type)
          elseif group.selection_mode == 3 then -- flickering
            sequencer_controller:update_group(group_name, x, y, "on", press_type)
            grid_sequencer:set_current_level_at(x, y, from_view, "on")
            grid_sequencer:register_flicker_at(x, y)
          elseif group.selection_mode == 4 then -- momentary
            
            grid_sequencer:register_flicker_at(x, y, 1)
            sequencer_controller:update_group(group_name, x, y, "momentary", press_type)
          elseif group.selection_mode == 5 then -- static (no press)
            -- grid_sequencer:register_flicker_at(x, y, 1)
          elseif group.selection_mode == 6 then -- 1 group item always on
            sequencer_controller:update_group(group_name, x, y, "on", press_type)
            grid_sequencer:set_current_level_at(x, y, from_view, "on")
            grid_sequencer:register_flicker_at(x, y)
          end
        elseif current_level == "on" then
          local solid =  grid_sequencer.solids[from_view][x][y].solid
          if group.selection_mode ~= 6 then
            sequencer_controller:update_group(group_name, x, y, "off", press_type)
            grid_sequencer:set_current_level_at(x, y, from_view, "off")
            grid_sequencer:unregister_flicker_at(x, y)
          end
        end
      end
    end

    -- if grid_sequencer:is_registered_solid_at(x, y, from_view) == false then -- register
    --   grid_sequencer:register_solid_at(x, y, from_view) 
    -- else -- unregister
    --   grid_sequencer:unregister_solid_at(x, y, from_view) 
    -- end



    grid_sequencer.dirtygrid(true)
  else
    if x <= 3 then -- change modes
      -- self.active_view = x
    elseif (x == 5 or x == 6) then  -- set animation view
      -- if (self.animation_mode[grid_sequencer.active_view] == 1 and x == 5) or (self.animation_mode[grid_sequencer.active_view] == 2 and x == 6) then 
      --   self.animation_mode[grid_sequencer.active_view] = 0 
      --   grid_sequencer.animator[grid_sequencer.active_view] = 0
      -- else
      --   self.animation_mode[grid_sequencer.active_view] = x==5 and 1 or 2
      --   grid_sequencer.animator[grid_sequencer.active_view] = self.animation_mode[grid_sequencer.active_view]
      -- end
    elseif x == 8 then 
      -- if self.filter_param_overlay == true then 
      --   self.filter_param_overlay = false
      -- else
      --   self.filter_param_overlay = true
      -- end
    end
    grid_sequencer.dirtygrid(true)
  end
end

function grid_sequencer:short_press(x, y, from_view)
  grid_sequencer:key_press(x, y, from_view, "short")
end

function grid_sequencer:is_long_press()
  return self.long_press
end

function grid_sequencer:grid_long_press(x, y, from_view)
  clock.sleep(grid_long_press_length)

  table.insert(long_presses,{x,y})
  grid_sequencer:register_flicker_at(x, y)
  -- grid_sequencer:set_long_press(true)
  -- grid_sequencer:unregister_solid_at(x, y, from_view) 

  --samples:select_x(x)
  --samples:select_y(y)
  grid_sequencer.long_press_counter[x][y] = nil
  grid_sequencer.dirtygrid(true)  
end

function grid_sequencer.grid_redraw_clock()
  while true do
    clock.sleep(1 / 15)
    grid_sequencer.frame = grid_sequencer.frame + 1
    if grid_sequencer.dirtygrid() == true then
      grid_sequencer:grid_redraw()
      grid_sequencer.dirtygrid(false)
    end
    if #grid_sequencer.flickers > 0 or #grid_sequencer.solids > 0 then
      grid_sequencer.dirtygrid(true)
    end
  end
end

function grid_sequencer:draw_live_samples()
  -- for k, sample in pairs(samples:get_all()) do
  --   if sample:is_live() then
  --     g:led(sample:get_x(), sample:get_y(), 1)
  --   end
  -- end
end

function grid_sequencer:draw_playing_samples()
  -- for k, sample in pairs(samples:get_all()) do
  --   if sample:is_playing() then
  --     g:led(sample:get_x(), sample:get_y(), 5)
  --   end
  -- end
end

function grid_sequencer:get_current_level_at(x, y, view)
  -- self.solids[view][x][y].solid.current_level
  if grid_sequencer.solids[1][x][y].solid then
    local current_level = grid_sequencer.solids[1][x][y].solid.current_level
    local on_level = grid_sequencer.solids[1][x][y].solid.on_level
    local off_level = grid_sequencer.solids[1][x][y].solid.off_level
    if current_level == off_level then
      return "off"
    elseif current_level == on_level then
      return "on"
    else
      return "other"
    end
  else 
    return nil
  end
end 

function grid_sequencer:set_current_level_at(x, y, view, level)
  view = view or 1
  local solid = grid_sequencer.solids[view][x][y].solid
  if solid then
    if level == "off" then
      solid.current_level = solid.off_level
    else
      solid.current_level = solid.on_level
    end
  else
    -- print("ERROR grid_sequencer:set_current_level_at: can't find solid at", x,y)
  end
end

function grid_sequencer:is_registered_solid_at(x, y, view)
  return #self.solids[view][x][y].solid > 0
end

function grid_sequencer:unregister_solid_at(x, y, view)
  self.solids[view][x][y] = {}
end

function grid_sequencer:set_off_level_at(x, y, view, solid_level, off_level)

end

function grid_sequencer:register_solid_at(x, y, view, solid_level, off_level)
  local solid = {}
  solid.x = x
  solid.y = y
  solid.origin_frame = self.frame
  solid.current_level = off_level and off_level or solid_level
  solid.on_level = solid_level or 15
  solid.off_level = off_level or 0
  -- if y<8 then 
  --   solid.level = solid_level or 10
  -- end 
  self.solids[view][x][y].solid = solid
end

function grid_sequencer.get_num_ui_groups()
  return #grid_sequencer.ui_groups
end

function grid_sequencer:find_ui_group_num_by_xy(x,y)
  for i=1,grid_sequencer.get_num_ui_groups(),1 do
    local data = grid_sequencer.ui_groups[i].grid_data
    if (x>=data.x1 and x<=data.x2) and (y>=data.y1 and y<=data.y2) then
      return i
    end
  end
end

function grid_sequencer:find_ui_group_num_by_name(name)
  for i=1,grid_sequencer.get_num_ui_groups(),1 do
    local group_name = grid_sequencer.ui_groups[i].group_name
    if (name == group_name) then
      return i
    end
  end
end

function grid_sequencer:unregister_ui_group(x1,y1)
  local ui_group = grid_sequencer:find_ui_group_num_by_xy(x1,y1)
  groups_unregistered = {}
  if ui_group then
    for i=grid_sequencer.get_num_ui_groups(),ui_group,-1 do
      grid_sequencer.flickers[i] = {}    
      local grid_data = grid_sequencer.ui_groups[i].grid_data
      for j=grid_data.x1,grid_data.x1+(grid_data.x2-grid_data.x1),1 do
        local j_incr = 1
        for k=grid_data.y1,grid_data.y1+(grid_data.y2-grid_data.y1),1 do
          grid_sequencer:unregister_solid_at(j, k, self.active_view)
        end
      end
      local group_num = i
      local group_name = grid_sequencer.ui_groups[i].group_name
      table.insert(groups_unregistered,{group_num,group_name})
      table.remove(grid_sequencer.ui_groups,i)
    end
  end
  return groups_unregistered
end 

-- function grid_sequencer:register_ui_group(group_name,x1,y1,x2, y2, off_level, off_level_bottom)
function grid_sequencer:register_ui_group(group_name,x1,y1,x2, y2, off_level, selection_mode, control_spec, default_value)
  local ui_group_exists = false
  local ui_group_num
  for i=x1,x2,1 do
    if grid_sequencer:find_ui_group_num_by_xy(i,y1) then
      if ui_group_num == nil then
        ui_group_exists = true
        ui_group_num = grid_sequencer:find_ui_group_num_by_xy(i,y1)
      end
      local old_x1 = grid_sequencer.ui_groups[ui_group_num].grid_data.x1
      local old_x2 = grid_sequencer.ui_groups[ui_group_num].grid_data.x2
      for j=old_x1,old_x2,y1 do
        grid_sequencer:unregister_solid_at(j,y1, 1)
        grid_sequencer:solid_off(j,y1, 1)
      end
    end
  end

  local grid_data = {}
  grid_data.x1=x1 
  grid_data.y1=y1 
  grid_data.x2=x2 
  grid_data.y2=y2 
  grid_data.active_item = nil
  grid_data.default_value = default_value
  grid_data.group_name = group_name
  
  local ol = off_level
  local increment = 0
  local has_default_value = false
  local default_value_x, default_value_y = nil,nil
  for i=x1,x1+(x2-x1),1 do
    for j=y1,y1+(y2-y1),1 do
      grid_data.off_level=ol
      grid_sequencer:register_solid_at(i, j, self.active_view, nil, ol)
      if default_value and default_value == i then
        has_default_value = true
        default_value_x, default_value_y = i,j
      end
    end
    if has_default_value == true then 
      clock.run(grid_sequencer.activate_grid_key_at,default_value_x, default_value_y,0.1)
    end 
      
  end
  -- table.insert(grid_sequencer.ui_groups,grid_data)
  local group_num
  if ui_group_exists == true then
    group_num = ui_group_num
  else 
    grid_sequencer.ui_groups[grid_sequencer.get_num_ui_groups()+1] = {}
    group_num = grid_sequencer.get_num_ui_groups()
  end 
  grid_sequencer.ui_groups[group_num].grid_data = grid_data
  grid_sequencer.ui_groups[group_num].ix = group_num
  grid_sequencer.ui_groups[group_num].group_name = group_name
  grid_sequencer.ui_groups[group_num].selection_mode = selection_mode
  grid_sequencer.ui_groups[group_num].control_spec = control_spec
  grid_sequencer.ui_groups[group_num].default_value = default_value
  grid_sequencer.flickers[group_num] = {}

  return grid_sequencer.ui_groups[group_num]
end

function grid_sequencer:draw_led_solids()
  for i=1,#grid_sequencer.grid_views,1 do
    for j=1,16,1 do
      -- for k, v in pairs(self.solids[self.active_view][j]) do
      for k, v in pairs(self.solids[i][j]) do
        if v.solid then
          local flickering = grid_sequencer:find_flickering_at(v.solid.x, v.solid.y) 
          if flickering == nil then
            local level = v.solid.current_level or 0
            g:led(v.solid.x, v.solid.y, level)
          end
        end
      end
    end
  end
end

function grid_sequencer:find_flickering_at(x,y)
  local found_x, found_y
  local ui_group_num = grid_sequencer:find_ui_group_num_by_xy(x, y)
  -- if ui_group_num == nil or x == nil or y == nil then print("no ui_group at ",x,y) return end
  if self.flickers[ui_group_num] and #self.flickers[ui_group_num]>0 then
    for i=1,#self.flickers[ui_group_num],1 do
      for k, v in pairs(self.flickers[ui_group_num][i]) do
        if k=="y" and v==y then found_y = 1 end
        if k=="x" and v==x then found_x = 1 end
        -- end
        if found_x and found_y then 
          return {ui_group_num,i}
        end
      end
    end
  else
    return nil
  end
end

function grid_sequencer:unregister_flicker_at(x, y)
  local flickering = grid_sequencer:find_flickering_at(x,y) 
  if flickering and self.flicker_counter then 
    clock.cancel(self.flicker_counter)
    table.remove(self.flickers[flickering[1]],flickering[2])
  end
end

function grid_sequencer.set_momentary_flicker(x, y, view, flicker_time)
  clock.sleep(flicker_time)

  grid_sequencer:unregister_flicker_at(x, y)
end

function grid_sequencer:register_flicker_at(x, y, flicker_time)
  local flicker = {}
  flicker.x = x
  flicker.y = y
  flicker.origin_frame = self.frame
  flicker.origin_level = 15
  flicker.level = 15
  flicker.flicker_time = flicker_time or nil

  local ui_group_num = grid_sequencer:find_ui_group_num_by_xy(x, y)
  
  if ui_group_num == nil or x == nil or y == nil then return end
  -- if ui_group_num == nil or x == nil or y == nil then print("no ui_group at ",x,y) return end
  
  table.insert(self.flickers[ui_group_num], flicker)

  if flicker_time then -- just setup a momentary flicker
    local view = 1 
    -- grid_sequencer:register_solid_at(x, y, view)
    clock.run(grid_sequencer.set_momentary_flicker,x, y, view, flicker_time)
  end
end

function grid_sequencer.schedule_led_flickers()
  if grid_sequencer.flicker_scheduling == false then
    grid_sequencer.flicker_scheduling = true
    clock.sleep(0.01)
    -- grid_sequencer:draw_led_flickers()
    grid_sequencer.flicker_scheduling = false
  end
end

function grid_sequencer:draw_led_flickers()
  grid_sequencer.flicker_level = grid_sequencer.flicker_level > 0 and grid_sequencer.flicker_level - 1 or 15
  for i=1,#self.ui_groups,1 do
    for k, v in pairs(self.flickers[i]) do
      -- if v.level == 0 or v.origin_frame + 2 < self.frame then
      local flicker_offset
      flicker_offset = i < 6 and 1 or i-4
      v.level = grid_sequencer.flicker_level + flicker_offset < 15 and grid_sequencer.flicker_level + flicker_offset or grid_sequencer.flicker_level + flicker_offset - 15
      if v.flicker_time then
        g:led(v.x, v.y, 15)
      elseif v.level == 0 then
        -- v.level = v.origin_level
        v.origin_frame = self.frame
      else
        g:led(v.x, v.y, v.level)
        -- v.level = v.level - 1
      end
    end
  end
end


--[[function grid_sequencer:draw_led_pulses()
  for k, v in pairs(self.flickers[self.active_view]) do
    if v.level == 0 or v.origin_frame + 2 < self.frame then
      table.remove(self.flickers[self.active_view], k)
    else
      g:led(v.x, v.y, v.level)
      v.level = v.level - 1
    end
  end
end
]]


function grid_sequencer:draw_spacers()
  g:led(4, 8, 2)
  g:led(5, 8, 2)
  -- g:led(11, 8, 2)
  -- g:led(12, 8, 2)
  -- g:led(8, 8, 2)
  -- g:led(9, 8, 2)
  -- g:led(10, 8, 2)
  g:led(11, 8, 0)
  g:led(12, 8, 0)
  g:led(13, 8, 0)
  g:led(14, 8, 3)
end

--[[
function grid_sequencer:draw_animation_indicators()
  for i=1,3,1 do
    if self.animation_mode[grid_sequencer.active_view] == 1 then
      g:led(5, 8, 7)
    elseif self.animation_mode[grid_sequencer.active_view] == 2 then
      g:led(6, 8, 7)
    end
  end
end

function grid_sequencer:draw_filter_param_overlay()
  if self.filter_param_overlay == true then
    g:led(8, 8, 10)
  else
    g:led(8, 8, 0)
  end
end
]]

function grid_sequencer:draw_active_view()
  g:led(self.active_view, 8, 7)
end

function grid_sequencer:grid_redraw()
  if grid_mode == "sequencer" then
    g:all(0)
    -- self:draw_live_samples()
    -- self:draw_playing_samples()
    -- self:draw_animation_indicators()
    -- self:draw_filter_param_overlay()
    self:draw_led_solids()
    self:draw_led_flickers()
    self.flicker_counter = clock.run(grid_sequencer.schedule_led_flickers)
    
    -- draw active_view
    -- set leds to show active view and  (if selected) animation mode
    self:draw_active_view()
    
    --set mode indicator
    g:led(16, 8, 7)
    self:draw_spacers()  
    g:refresh()
  end
end

function grid_sequencer:get_width()
  return  grid_sequencer.last_known_width
end

function grid_sequencer:get_height()
  return  grid_sequencer.last_known_height
end

-- local long_presses = {}

function grid_sequencer:process_long_press(first_press,second_press)
  if (first_press[1] < 6 and second_press == nil) and (first_press[2] == 1) then
    -- copy/paste sequinsets to selected set from active set
    sequencer_controller.copy_paste_sequinsets(first_press[1], sequencer_controller.selected_sequin_group)
  elseif (first_press[1] < 15 and second_press == nil ) and (first_press[2] == 1) then
    -- copy/paste indivdual sequins to first pressed sequin from active sequin
    local sgp = sequencer_controller.selected_sequin_group
    local ssg = 1  
    local data_path = {sgp,ssg}
    local target_id = first_press[1]-5
    local source_id = sequencer_controller.selected_sequin
    local end_node = "sqn"
    if target_id ~= source_id then
      sequencer_controller.copy_paste_sequence_data(source_id, target_id, data_path, end_node)
    else
      sequencer_controller.clear_sequence_data(source_id, data_path, end_node)
    end
  elseif (first_press[1] >5 and first_press[1] < 11 and first_press[2] == 8  and second_press == nil ) then
    -- print("clear")
  elseif (first_press[1] < 6 and second_press[1] < 6 ) and (first_press[2] == 1 and second_press[2] == 1 ) then
    -- copy/paste sequinsets to first pressed set from second pressed set
    sequencer_controller.copy_paste_sequinsets(first_press[1], second_press[1])
  elseif second_press and (first_press[1] < 15 and second_press[1] < 15 ) and (first_press[2] == 1 and second_press[2] == 1 ) then
    -- copy/paste indivdual sequins to first pressed sequin from second pressed sequin
    local sgp = sequencer_controller.selected_sequin_group
    local ssg = 1  
    local data_path = {sgp,ssg}
    local target_id = first_press[1]-5
    local source_id = second_press[1]-5
    local end_node = "sqn"
    sequencer_controller.copy_paste_sequence_data(source_id, target_id, data_path, end_node)
  end
end

function grid_sequencer:set_long_press(bool,x,y)
  -- self.long_press = bool
  
  if bool == false and #long_presses > 0 then
    for i=#long_presses,1,-1 do
      local long_x = long_presses[i][1]
      local long_y = long_presses[i][2]
      if x==long_x and y==long_y then
        local ui_group_num = grid_sequencer:find_ui_group_num_by_xy(x, y)
        if ui_group_num == nil or x == nil or y == nil then print("no ui_group at ",x,y) return end
        grid_sequencer:unregister_flicker_at(x,y)
        table.insert(long_presses,{x,y})
        -- table.remove(long_presses,i)
      end
    end
    if #long_presses > 3 then
      long_presses = {}
    elseif #long_presses == 3 then
      table.remove(long_presses)
      local first_press = long_presses[1]
      local second_press = long_presses[2]
      long_presses = {}
      grid_sequencer:process_long_press(first_press,second_press)
    else 
      local first_press = long_presses[1]
      grid_sequencer:process_long_press(first_press)
      grid_sequencer:key_press(x, y, 1, "long")
      long_presses = {}
    end
  end
end

return  grid_sequencer