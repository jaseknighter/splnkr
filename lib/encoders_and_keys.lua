-- encoders and keys

local function grid_key(x, y, z)
  if z == 0 then
    if x == 14 and y==8 then
      -- print("filter")
      grid_mode = "filter"
    elseif x == 15 and y==8 then
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
    end
  end

  if pages.index == 1 then
    if saving == false and show_instructions == false and file_selected == true then    
      if n==1 then
        d = util.clamp(d,-1,1) * 0.01
        if nav_active_control == 3 then
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
        elseif nav_active_control == 4 then
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
        elseif nav_active_control == 5 then
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
            local display_mode = nav_active_control == 3 and 1 or 2  
            cutters[new_active_cutter]:set_display_mode(display_mode)
            sample_player.active_cutter = new_active_cutter
            sample_player.cutter_assignments[sample_player.selected_voice] = sample_player.active_cutter 
            sample_player.selected_cutter_group = sample_player.active_cutter
            for i=1,6,1 do sample_player.reset(i) end
          end
        else
          nav_active_control = util.clamp(nav_active_control+d,1,#sample_player_nav_labels)
          if waveform_loaded then 
            if nav_active_control > 2 and sample_player.active_cutter == 0 then
              sample_player.active_cutter = 1
              if sample_player.cutter_assignments[sample_player.active_cutter] < 1 then 
                sample_player.cutter_assignments[sample_player.active_cutter] = 1
                sample_player.update() 
              end
            end
    
            if nav_active_control == 3 then 
              for i=1,#cutters,1
              do
                cutters[i]:set_display_mode(0)
              end 
              cutters[sample_player.active_cutter]:set_display_mode(1)
            elseif nav_active_control == 4 then 
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
        if nav_active_control == 1 then 
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
            sample_player.selected_voice = util.clamp(d+sample_player.selected_voice,1,6)
            sample_player.active_cutter = sample_player.cutter_assignments[sample_player.selected_voice]
            sample_player.selected_cutter_group = sample_player.active_cutter
            sample_player_nav_labels[1] = "select/play/scrub voice: " .. sample_player.selected_voice
            for i=1,#cutters,1
            do
              cutters[i]:set_display_mode(0)
            end 
            if sample_player.active_cutter > 0 then
              local display_mode = nav_active_control == 3 and 1 or 2  
              cutters[sample_player.active_cutter]:set_display_mode(display_mode)
            end
          end
        elseif nav_active_control == 2 then -- set play mode
          local new_play_mode = util.clamp(sample_player.play_modes[sample_player.selected_voice]+d,0,#play_mode_text-1)
          sample_player.set_play_mode(sample_player.selected_voice,new_play_mode)
        elseif nav_active_control == 3 then -- move cutter edge
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
        elseif nav_active_control == 4 then -- move cutter
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
        elseif nav_active_control == 5 then -- set rate
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
        elseif nav_active_control == 6 then
          local new_level = util.clamp(sample_player.level+(d)/100,0,1)
          new_level = fn.round_decimals (new_level, 3, "down")
          sample_player.level = new_level
          softcut.level(sample_player.selected_voice,sample_player.level)
        elseif nav_active_control == 7 then
          autogen = util.clamp(autogen+d,1,MAX_CUTTERS)
          sample_player.autogenerate_cutters(autogen)
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
    if n==1 then
    elseif n==2 then
      -- do something
    elseif n==3 then
      -- do something
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
          if #cutters > 1 and nav_active_control > 1 and nav_active_control < 7 then
            table.remove(cutters, sample_player.active_cutter)
            -- table.remove(sample_player.voice_rates, sample_player.active_cutter)
            for i=1,#cutters,1
            do
              cutters[i]:set_cutter_id(i)
              cutters[i]:set_active_edge(1)
              cutters[i]:set_display_mode(0)
            end
            sample_player.active_cutter = sample_player.active_cutter > 1 and sample_player.active_cutter -1 or 1
            sample_player.cutter_assignments[sample_player.selected_voice] = sample_player.active_cutter > 1 and sample_player.active_cutter - 1 or 1
            local display_mode = nav_active_control == 3 and 1 or 2
            cutters[sample_player.active_cutter]:set_display_mode(display_mode)
            sample_player.selected_cutter_group = sample_player.active_cutter
            sample_player.update()
          elseif nav_active_control == 7 then
            -- do something?
          end
        end
      elseif n==3 and z==1 then
        if nav_active_control == 1 then
          -- playing = playing == 1 and 0 or 1
          softcut.play(sample_player.selected_voice, playing)
        end
        if nav_active_control > 1 and #cutters < MAX_CUTTERS then

          local new_cutter_start_x, new_cutter_finish_x
          if cutters[sample_player.active_cutter]:get_finish_x() < 60 then
            new_cutter_start_x = cutters[sample_player.active_cutter]:get_finish_x() + 5
            new_cutter_finish_x = new_cutter_start_x + 10
          else
            new_cutter_start_x = cutters[sample_player.active_cutter]:get_start_x() - 20
            new_cutter_finish_x = new_cutter_start_x + 10
          end
          table.insert(cutters, sample_player.active_cutter+1, Cutter:new(sample_player.active_cutter+1, new_cutter_start_x, new_cutter_finish_x))
          table.insert(sample_player.voice_rates, sample_player.active_cutter+1,sample_player.voice_rates[sample_player.selected_voice])
          sample_player.cutters_start_finish_update()
        end
        for i=1,#cutters,1
        do
          cutters[i]:set_cutter_id(i)
          cutters[i]:set_display_mode(0)
        end
        local display_mode = nav_active_control == 3 and 1 or 2
        cutters[sample_player.active_cutter]:set_display_mode(display_mode)
        sample_player.update()
      end
    end
    if ((not waveform_loaded or nav_active_control == 1) and alt_key_active == false) and n==2 and z==1 then
      screen.clear()
      selecting = true
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
      
  end
end

return{
  enc=enc,
  key=key,
  grid_key = grid_key
}
