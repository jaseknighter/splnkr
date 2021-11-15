-- encoders and keys
-- todo: split out grid controls (and variables) into a separate lua file

local function grid_key(x, y, z)
  if z == 0 then
    if x == 15 and y==8 then
      grid_mode = "filter"
    elseif x == 16 and y==8 then
      grid_mode = "sequencer"
    end
  end
  if grid_mode == "filter" then
    grid_filter.key(x,y,z)
  else
    grid_sequencer.key(x,y,z)
  end
end

p1_index = 1
p3_index = 1

local enc = function (n, d)
  -- set variables needed by each page/example
  d = util.clamp(d, -1, 1)
  if n == 1 and alt_key_active == false then
    -- scroll pages
    local page_increment = d
    local next_page = pages.index + page_increment
    if (next_page <= NUM_PAGES and next_page > 0) then
      page_scroll(page_increment)
      if pages.index == 3 then
        g.key(16,8,0)
      end
    end
  elseif n == 1 then
    if pages.index == 2 then
      active_envelope = active_envelope == 1 and 2 or 1
      inactive_envelope = active_envelope == 1 and 2 or 1
      envelopes[active_envelope].set_active(true)
      envelopes[inactive_envelope].set_active(false)
    end
  end

  if pages.index == 1 then
    if saving == false and show_instructions == false and sample_player.file_selected == true then    
      if n==1 then
        d = util.clamp(d,-1,1) * 0.01
        if sample_player.nav_active_control == 3 then
          if alt_key_active == true then
            local active_edge = cutters[sample_player.active_cutter]:get_active_edge()
            local cutter = cutters[sample_player.active_cutter]
            if active_edge == 1 then -- adjust start cuttter
              cutter:set_start_x(util.clamp(cutters[sample_player.active_cutter]:get_start_x()+(d*1),0,cutters[sample_player.active_cutter]:get_finish_x()))
            else
              cutter:set_finish_x(util.clamp(cutters[sample_player.active_cutter]:get_finish_x()+(d*1),cutters[sample_player.active_cutter]:get_start_x(), 128))
            end
            sample_player.cutters_start_finish_update()
            if sample_player.play_modes[sample_player.selected_voice] > 1 and sample_player.cutter_assignments[sample_player.selected_voice] == sample_player.active_cutter then sample_player.reset() end 
          else
            cutters[sample_player.active_cutter]:rotate_cutter_edge(d)
          end
        elseif sample_player.nav_active_control == 4 then
          if alt_key_active == true then
            for i=1,#cutters,1
            do  
              if i == sample_player.selected_cutter_group and (d<0 and cutters[i]:get_start_x() == 0) or (d>0 and cutters[i]:get_finish_x() == 128) then
                break
              elseif i == sample_player.selected_cutter_group then
                cutters[i]:set_start_x(util.clamp(cutters[i]:get_start_x()+(d*1),0,cutters[i]:get_finish_x()))
                cutters[i]:set_finish_x(util.clamp(cutters[i]:get_finish_x()+(d*1),cutters[i]:get_start_x(), 128))
                sample_player.cutters_start_finish_update()
                if sample_player.play_modes[sample_player.selected_voice] > 1 and sample_player.cutter_assignments[sample_player.selected_voice] == sample_player.active_cutter then 
                  sample_player.reset(sample_player.selected_voice) 
                end 
              end
            end
          end
        elseif sample_player.nav_active_control == 5 then
          if alt_key_active == true then
            local rate = sample_player.voice_rates[sample_player.selected_voice]
            rate = rate + d
            rate = rate ~= 0 and rate or rate + d
            rate = util.clamp(rate,-20,20)
            sample_player.voice_rates[sample_player.selected_voice] = rate 
            sample_player.reset(sample_player.selected_voice)
            -- for i=1,6,1 do sample_player.reset(i) end
          end
        end
      elseif n==2 then 
        d = util.clamp(d,-1,1)
        if alt_key_active == true then
          -- select prev/next cutter
          local new_active_cutter = util.clamp(sample_player.active_cutter+d,1,#cutters)
          if new_active_cutter ~= sample_player.active_cutter then
            for i=1,#cutters,1
            do
              cutters[i]:set_display_mode(0)
            end 
            local display_mode = sample_player.nav_active_control == 3 and 1 or 2  
            cutters[new_active_cutter]:set_display_mode(display_mode)
            sample_player.active_cutter = new_active_cutter
            sample_player.cutter_assignments[sample_player.selected_voice] = sample_player.active_cutter 
            sample_player.selected_cutter_group = sample_player.active_cutter
            for i=1,6,1 do sample_player.reset(i) end
          end
        else
          sample_player.nav_active_control = util.clamp(sample_player.nav_active_control+d,1,#sample_player_nav_labels)
          if waveform_loaded then 
            if sample_player.nav_active_control > 2 and sample_player.active_cutter == 0 then
              sample_player.active_cutter = 1
              if sample_player.cutter_assignments[sample_player.active_cutter] < 1 then 
                sample_player.cutter_assignments[sample_player.active_cutter] = 1
                sample_player.update() 
              end
            end
    
            if sample_player.nav_active_control == 3 then 
              for i=1,#cutters,1
              do
                cutters[i]:set_display_mode(0)
              end 
              cutters[sample_player.active_cutter]:set_display_mode(1)
            elseif sample_player.nav_active_control == 4 then 
              for i=1,#cutters,1
              do
                cutters[i]:set_display_mode(0)
              end 
              cutters[sample_player.active_cutter]:set_display_mode(2)
            end
          end
        end 
      elseif n==3 then
        d = util.clamp(d,-1,1)
        if sample_player.nav_active_control == 1 then 
          if alt_key_active == true then -- scrub
            local r = sample_player.voice_rates[sample_player.selected_voice]
            -- local adj_amt = (d>0) and (r>0 and (1/(r*100)) or 0.001) or (r>0 and 0.001 or (1/(r*100)))
            -- local adj_amt = (d>0) and 0.001 + (r*0.005) or (r>0 and (-0.01 - (-r*0.05)) or (-0.001 - (-r*0.005)))
            local adj_amt = (d>0) and 
            (r>0 and (0.001 + (r*0.005)) or (-0.001 - (-r*0.005))) or
            (r>0 and (-0.001 - (-r*0.005)) or (-0.001 - (-r*0.005)))
            sample_player.sample_positions[sample_player.selected_voice] = util.clamp(sample_player.sample_positions[sample_player.selected_voice] + (d*adj_amt),0, 1)
            softcut.position(sample_player.selected_voice,sample_player.sample_positions[sample_player.selected_voice]*length)
            
          else -- select active voice
            sample_player.select_next_voice(d)
          end
        elseif sample_player.nav_active_control == 2 then -- set play mode
          local new_play_mode = util.clamp(sample_player.play_modes[sample_player.selected_voice]+d,0,#play_mode_text-1)
          if alt_key_active == true then -- update play mode for all voices
            for i=1,6,1 do
              sample_player.set_play_mode(i,new_play_mode)
            end
          else -- update play mode for the selected voice
            sample_player.set_play_mode(sample_player.selected_voice,new_play_mode)
          end
        elseif sample_player.nav_active_control == 3 then -- move cutter edge
          if alt_key_active == true then
            local active_edge = cutters[sample_player.active_cutter]:get_active_edge()
            local cutter = cutters[sample_player.active_cutter]
            if active_edge == 1 then -- adjust start cuttter
              cutter:set_start_x(util.clamp(cutters[sample_player.active_cutter]:get_start_x()+(d*1),0,cutters[sample_player.active_cutter]:get_finish_x()))
            else
              cutter:set_finish_x(util.clamp(cutters[sample_player.active_cutter]:get_finish_x()+(d*1),cutters[sample_player.active_cutter]:get_start_x(), 128))
            end
            sample_player.cutters_start_finish_update()
            if sample_player.play_modes[sample_player.selected_voice] > 1 and 
              sample_player.cutter_assignments[sample_player.selected_voice] == sample_player.active_cutter then 
                for i=1,6,1 do sample_player.reset(i) end
              end 
          else
            cutters[sample_player.active_cutter]:rotate_cutter_edge(d)
          end
        elseif sample_player.nav_active_control == 4 then -- move cutter
          if alt_key_active == true then
            for i=1,#cutters,1
            do  
              if i == sample_player.selected_cutter_group  and (d<0 and cutters[i]:get_start_x() == 0) or (d>0 and cutters[i]:get_finish_x() == 128) then
                break
              elseif i == sample_player.selected_cutter_group then
                cutters[i]:set_start_x(util.clamp(cutters[i]:get_start_x()+(d*1),0,cutters[i]:get_finish_x()))
                cutters[i]:set_finish_x(util.clamp(cutters[i]:get_finish_x()+(d*1),cutters[i]:get_start_x(), 128))
                sample_player.cutters_start_finish_update()
                if sample_player.play_modes[sample_player.selected_voice] > 1 and sample_player.cutter_assignments[sample_player.selected_voice] == sample_player.active_cutter then 
                  for i=1,6,1 do sample_player.reset(i) end
                end 
              end
            end
          end
        elseif sample_player.nav_active_control == 5 then -- set rate
          local rate = sample_player.voice_rates[sample_player.selected_voice]
          rate = rate + d
          rate = rate ~= 0 and rate or rate + d
          rate = util.clamp(rate,-20,20)
          -- if sample_player.play_modes[sample_player.selected_voice] < 2 then sample_player.voice_rates[1] = rate else sample_player.voice_rates[sample_player.selected_voice] = rate end
          if alt_key_active == false then
            sample_player.voice_rates[sample_player.selected_voice] = rate 
          else
            for i=1,#sample_player.voice_rates,1
            do
              sample_player.voice_rates[i] = rate
            end
          end
          
          for i=1,6,1 do sample_player.reset(i) end
        elseif sample_player.nav_active_control == 6 then -- set level
          if alt_key_active == true then -- update play mode for all voices
          for i=1,6,1 do
            local new_level = util.clamp(sample_player.levels[i]+(d)/100,0,1)
            new_level = fn.round_decimals (new_level, 3, "down")
            sample_player.levels[i] = new_level
            softcut.level(i,sample_player.level)
            
            end
          else
            local new_level = util.clamp(sample_player.levels[sample_player.selected_voice]+(d)/100,0,1)
            new_level = fn.round_decimals (new_level, 3, "down")
            sample_player.levels[sample_player.selected_voice] = new_level
          softcut.level(sample_player.selected_voice,sample_player.levels[sample_player.selected_voice])
          end
        elseif sample_player.nav_active_control == 7 then -- autogenerate cutters
          if alt_key_active == true then
            sample_player.num_cutters = util.clamp(sample_player.num_cutters+d,1,MAX_CUTTERS)
            sample_player.autogenerate_cutters(sample_player.num_cutters)
          else
            local sorted_cut_indices = cut_detector.get_sorted_cut_indices()
            local num_cutters = util.clamp(sample_player.num_cutters+d,1,MAX_CUTTERS)
            num_cutters = num_cutters <= #sorted_cut_indices and num_cutters or #sorted_cut_indices
            sample_player.num_cutters = num_cutters
            sample_player.autogenerate_cutters(sample_player.num_cutters)
          end
        end
      end
    end
    sample_player.update()

    
    
  
  elseif pages.index == 2 then
    screen.clear()
    screen_dirty = true

    if n==1 then
      envelopes[active_envelope].enc(n, d)     
    elseif n==2 then
      envelopes[active_envelope].enc(n, d)     
    elseif n==3 then
      envelopes[active_envelope].enc(n, d)     
    end
  elseif pages.index == 3 then
    local startup = sc.selected_sequin_group == nil and true or false

    if n==1 then
    elseif n==2 then
      local ssg = sc.selected_sequin_group and sc.selected_sequin_group or d<0 and 6 or 0
      encoders_and_keys.next_sequins_group = encoders_and_keys.next_sequins_group and encoders_and_keys.next_sequins_group or ssg
      encoders_and_keys.next_sequins_group = util.wrap(encoders_and_keys.next_sequins_group + d,1,5)
      for i=1,5,1 do
        grid_sequencer.solids[1][i][1].solid.current_level = 7
      end
      grid_sequencer.solids[1][encoders_and_keys.next_sequins_group][1].solid.current_level = 14
    elseif n==3 then
      if encoders_and_keys.active_ui_group and encoders_and_keys.active_ui_group.ix < 6 then
        grid_sequencer.activate_grid_key_at(6, 1)
        local next_y = sc:get_active_ui_group().grid_data.y1
        if next_y<=5 then
          encoders_and_keys.active_ui_group = sc:get_active_ui_group()
        end
      elseif sc:get_active_ui_group().ix > 5 then
        local next_y = sc:get_active_ui_group().grid_data.y1
        if next_y<=5 then
          encoders_and_keys.active_ui_group = sc:get_active_ui_group()
        end
        local x_min = encoders_and_keys.active_ui_group.grid_data.x1
        local x_max = encoders_and_keys.active_ui_group.grid_data.x2
        y = encoders_and_keys.active_ui_group.grid_data.y1
        encoders_and_keys.x_selected = encoders_and_keys.x_selected and encoders_and_keys.x_selected or encoders_and_keys.active_ui_group.grid_data.x1
        local x = util.wrap(encoders_and_keys.x_selected+d,x_min,x_max)
        -- if y < 8 and encoders_and_keys.x_selected ~= x then
        
        encoders_and_keys.x_selected = x
        local off_level = encoders_and_keys.active_ui_group.grid_data.off_level
        for i=x_min,x_max,1 do
          grid_sequencer.solids[1][i][y].solid.current_level = off_level
        end
        grid_sequencer.solids[1][encoders_and_keys.x_selected][y].solid.current_level = 14
      end
    end
  elseif pages.index == 4 then

  elseif pages.index == 5 then

  end
end

local key = function (n,z)
  if n == 1 and z == 1 then
    alt_key_active = true
  elseif n == 1 and z == 0 then
    alt_key_active = false
  end

  if pages.index == 1 then
    if saving == false and n == 3 and show_instructions == true then
      show_instructions = false
      screen.clear() 
    elseif saving == false and n == 3 and z== 1 and alt_key_active then
      show_instructions = true
    end

    if saving == false and show_instructions == false and waveform_loaded then
      if n==1 and z==1 then
        -- do something 
      elseif n==2 and z==1 then
        if alt_key_active == true then
          local play_mode = sample_player.get_play_mode(sample_player.selected_voice)
          if play_mode ~= 0 then
            sample_player.set_last_play_mode(sample_player.selected_voice, play_mode)
            sample_player.set_play_mode(sample_player.selected_voice,0)
          else
            local last_play_mode = sample_player.get_last_play_mode(sample_player.selected_voice)
            sample_player.set_last_play_mode(sample_player.selected_voice, nil)
            sample_player.set_play_mode(sample_player.selected_voice,last_play_mode)
          end
        else
          if #cutters > 1 and sample_player.nav_active_control > 1 then
            sample_player.num_cutters = util.clamp(sample_player.num_cutters-1,1,MAX_CUTTERS)
            sample_player.autogenerate_cutters(sample_player.num_cutters)          
          end
        end
      elseif n==3 and z==1 then
        if sample_player.nav_active_control == 1 then
          sample_player.playing = sample_player.playing == 1 and 0 or 1
          softcut.play(sample_player.selected_voice, sample_player.playing)
        elseif sample_player.nav_active_control > 1 and #cutters < MAX_CUTTERS then
          local sorted_cut_indices = cut_detector.get_sorted_cut_indices()
          local num_cutters = util.clamp(sample_player.num_cutters+1,1,MAX_CUTTERS)
          num_cutters = num_cutters <= #sorted_cut_indices and num_cutters or #sorted_cut_indices

          sample_player.num_cutters = num_cutters
          sample_player.autogenerate_cutters(sample_player.num_cutters)
        end
        -- for i=1,#cutters,1
        -- do
        --   cutters[i]:set_cutter_id(i)
        --   cutters[i]:set_display_mode(0)
        -- end
        -- local display_mode = sample_player.nav_active_control == 3 and 1 or 2
        -- cutters[sample_player.active_cutter]:set_display_mode(display_mode)
        -- sample_player.update()
      end
    end
    if ((not waveform_loaded or sample_player.nav_active_control == 1) and alt_key_active == false) and n==2 and z==1 then
      screen.clear()
      sample_player.selecting = true
      fileselect.enter(_path.dust,sample_player.load_file)
    end


  elseif pages.index == 2 then
    if z==1 then
      screen.clear()
      screen_dirty = true
      envelopes[active_envelope].key(n, z)     
    end
    -- if n==1 and z==1 then
    -- elseif n==2 and z==1 then

    -- elseif n==3 and z==1 then
      
    -- end
  elseif pages.index == 3 then
    screen_dirty = true
    local startup = encoders_and_keys.active_ui_group == nil and true or false
      
    if (n==2 or n==3) and z==1 and 
      (encoders_and_keys.next_sequins_group or startup or encoders_and_keys.active_ui_group.ix < 6) then 

      local x
      
      if encoders_and_keys.next_sequins_group then
        x = encoders_and_keys.next_sequins_group 
        grid_sequencer.activate_grid_key_at(x, 1)
        -- if encoders_and_keys.active_ui_group and encoders_and_keys.active_ui_group.ix ~= x then
        --   print("redo")
        -- end
      elseif startup == true then
        x = 1
        grid_sequencer.activate_grid_key_at(x, 1)
      else
        if n==2 then
          x = encoders_and_keys.active_ui_group.grid_data.x1 - 1
        elseif n==3 then
          x = encoders_and_keys.active_ui_group.grid_data.x1 + 1
        end
        print(x,n,encoders_and_keys.active_ui_group.grid_data.x1)
        x = util.wrap(x,1,5)
        grid_sequencer.activate_grid_key_at(x, 1)
      end
      encoders_and_keys.next_sequins_group = nil
      local next_y = sc:get_active_ui_group().grid_data.y1
      if next_y<=5 then
        encoders_and_keys.active_ui_group = sc:get_active_ui_group()
      end
    
    elseif n==2 and z==1 then
      local active_group_index = encoders_and_keys.active_ui_group.ix
      local prev_active_group = grid_sequencer.ui_groups[active_group_index-1]
      -- print("prev_active_group.ix",prev_active_group.ix)
      if prev_active_group.ix >= 6 then
        local prev_x_selected 
        local prev_x1 = prev_active_group.grid_data.x1
        local prev_x2 = prev_active_group.grid_data.x2
        local prev_y = prev_active_group.grid_data.y1
        for i=prev_x1,prev_x2,1 do
          local current_level = grid_sequencer.solids[1][i][prev_y].solid.current_level
          local on_level = grid_sequencer.solids[1][i][prev_y].solid.on_level
          if current_level == on_level then
            prev_x_selected = i
            break
          end
        end
        -- print("prev_x_selected",prev_x_selected)
        if prev_x_selected then
          encoders_and_keys.x_selected = prev_x_selected
          grid_sequencer.activate_grid_key_at(encoders_and_keys.x_selected, prev_y)
          grid_sequencer:register_flicker_at(encoders_and_keys.x_selected, prev_y)
          encoders_and_keys.active_ui_group = sc:get_active_ui_group()
        else
          local current_y = grid_sequencer.ui_groups[active_group_index].y1
          grid_sequencer.activate_grid_key_at(encoders_and_keys.x_selected, current_y)
        end
      end      
    elseif n==3 and z==1 then
      if startup == true or encoders_and_keys.x_selected < 6 then
        elseif encoders_and_keys.active_ui_group and encoders_and_keys.x_selected then
        local y = encoders_and_keys.active_ui_group.grid_data.y1    
        -- local current_level = grid_sequencer.solids[1][encoders_and_keys.x_selected][y].solid.current_level
        -- local off_level = grid_sequencer.solids[1][encoders_and_keys.x_selected][y].solid.off_level
        -- grid_sequencer.activate_grid_key_at(encoders_and_keys.x_selected, y)
        grid_sequencer:key_press(encoders_and_keys.x_selected, y,1,"short",1)
      end
    end  
  end
end

return{
  enc=enc,
  key=key,
  grid_key = grid_key
}
