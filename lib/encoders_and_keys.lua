-- encoders and keys
p1_index = 1
p3_index = 1

local enc = function (n, d)
  -- set variables needed by each page/example
  d = util.clamp(d, -1, 1)
  if n == 1 and alt_pressed == false then
    -- scroll pages
    local page_increment = d

    local next_page = pages.index + page_increment
    if (next_page <= num_pages and next_page > 0) then
      page_scroll(page_increment)
    end
  end

  if pages.index == 1 then
    if saving == false and show_instructions == false and file_selected == true then    
      if n==1 then
        d = util.clamp(d,-1,1) * 0.01
        if nav_active_control == 3 then
          if alt_key_active == true then
            local active_cutter_edge = cutters[active_cutter]:get_active_edge()
            local cutter = cutters[active_cutter]
            if active_cutter_edge == 1 then -- adjust start cuttter
              cutter:set_start_x(util.clamp(cutters[active_cutter]:get_start_x()+(d*1),0,cutters[active_cutter]:get_finish_x()))
            else
              cutter:set_finish_x(util.clamp(cutters[active_cutter]:get_finish_x()+(d*1),cutters[active_cutter]:get_start_x(), 128))
            end
            sample_player.cutters_start_finish_update()
            if play_mode > 1 and cutter_to_play == active_cutter then sample_player.reset() end 
          else
            cutters[active_cutter]:rotate_cutter_edge(d)
          end
        elseif nav_active_control == 4 then
          if alt_key_active == true then
            for i=1,#cutters,1
            do  
              if i == selected_cutter_group and (d<0 and cutters[i]:get_start_x() == 0) or (d>0 and cutters[i]:get_finish_x() == 128) then
                break
              elseif i == selected_cutter_group then
                cutters[i]:set_start_x(util.clamp(cutters[i]:get_start_x()+(d*1),0,cutters[i]:get_finish_x()))
                cutters[i]:set_finish_x(util.clamp(cutters[i]:get_finish_x()+(d*1),cutters[i]:get_start_x(), 128))
                sample_player.cutters_start_finish_update()
                if play_mode > 1 and cutter_to_play == active_cutter then 
                  sample_player.reset() 
                end 
              end
            end
          end
        elseif nav_active_control == 5 then
          if alt_key_active == true then
            local rate = cutter_rates[active_cutter]
            rate = rate + d
            rate = rate ~= 0 and rate or rate + d
            rate = util.clamp(rate,-20,20)
            cutter_rates[active_cutter] = rate 
            sample_player.reset() 
          end
        end
      elseif n==2 then 
        d = util.clamp(d,-1,1)
        if alt_key_active == true then
          -- select prev/next cutter
          local new_active_cutter = util.clamp(active_cutter+d,1,#cutters)
          if new_active_cutter ~= active_cutter then
            for i=1,#cutters,1
            do
              cutters[i]:set_display_mode(0)
            end 
            local display_mode = nav_active_control == 3 and 1 or 2  
            cutters[new_active_cutter]:set_display_mode(display_mode)
            active_cutter = new_active_cutter
            cutter_to_play = active_cutter 
            selected_cutter_group = active_cutter
            sample_player.reset() 
          end
        else
          nav_active_control = util.clamp(nav_active_control+d,1,#sample_player_nav_labels)
          if waveform_loaded then 
            if nav_active_control == 3 then 
              for i=1,#cutters,1
              do
                cutters[i]:set_display_mode(0)
              end 
              cutters[active_cutter]:set_display_mode(1)
            elseif nav_active_control == 4 then 
              for i=1,#cutters,1
              do
                cutters[i]:set_display_mode(0)
              end 
              cutters[active_cutter]:set_display_mode(2)
            end
          end
        end 
      elseif n==3 then
        d = util.clamp(d,-1,1)
        if nav_active_control == 1 then
          local r = cutter_rates[active_cutter]
          local adj_amt = (d>0) and (r>0 and 0.05 or 0.001) or (r>0 and 0.001 or 0.05)
          sample_position = util.clamp(sample_position + (d*adj_amt),0, 1)
          softcut.position(1,sample_position*length)
          softcut.position(2,sample_position*length)
        elseif nav_active_control == 2 then
          local new_play_mode = util.clamp(play_mode+d,0,#play_mode_text-1)
          sample_player.set_play_mode(new_play_mode)
        elseif nav_active_control == 3 then
          if alt_key_active == true then
            local active_cutter_edge = cutters[active_cutter]:get_active_edge()
            local cutter = cutters[active_cutter]
            if active_cutter_edge == 1 then -- adjust start cuttter
              cutter:set_start_x(util.clamp(cutters[active_cutter]:get_start_x()+(d*1),0,cutters[active_cutter]:get_finish_x()))
            else
              cutter:set_finish_x(util.clamp(cutters[active_cutter]:get_finish_x()+(d*1),cutters[active_cutter]:get_start_x(), 128))
            end
            sample_player.cutters_start_finish_update()
            if play_mode > 1 and cutter_to_play == active_cutter then sample_player.reset() end 
          else
            cutters[active_cutter]:rotate_cutter_edge(d)
          end
        elseif nav_active_control == 4 then
          if alt_key_active == true then
            for i=1,#cutters,1
            do  
              if i == selected_cutter_group  and (d<0 and cutters[i]:get_start_x() == 0) or (d>0 and cutters[i]:get_finish_x() == 128) then
                break
              elseif i == selected_cutter_group then
                cutters[i]:set_start_x(util.clamp(cutters[i]:get_start_x()+(d*1),0,cutters[i]:get_finish_x()))
                cutters[i]:set_finish_x(util.clamp(cutters[i]:get_finish_x()+(d*1),cutters[i]:get_start_x(), 128))
                sample_player.cutters_start_finish_update()
                if play_mode > 1 and cutter_to_play == active_cutter then 
                  sample_player.reset() 
                end 
              end
            end
          end
        elseif nav_active_control == 5 then
          local rate = cutter_rates[active_cutter]
          rate = rate + d
          rate = rate ~= 0 and rate or rate + d
          rate = util.clamp(rate,-20,20)
          -- if play_mode < 2 then cutter_rates[1] = rate else cutter_rates[active_cutter] = rate end
          if alt_key_active == false then
            cutter_rates[active_cutter] = rate 
          else
            for i=1,#cutter_rates,1
            do
              cutter_rates[i] = rate
            end
          end
          
          sample_player.reset() 
        elseif nav_active_control == 6 then
          level = util.clamp(level+(d)/100,0,1)
          softcut.level(1,level)
        elseif nav_active_control == 7 then
          autogen = util.clamp(autogen+d,1,20)
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
      -- p3_index = util.clamp(d+p3_index,1,5)
    elseif n==3 then
      --[[
      local d_mul = alt_pressed == true and 0.001*d or 0.1*d   
      if p3_index==1 then
        -- vinyl = util.clamp(d_mul + vinyl,0,10)
        -- engine.vinyl(vinyl)
        pitchshift = util.clamp(d_mul + pitchshift,0,10)
        engine.pitchshift(pitchshift)
      elseif p3_index==2 then
        phaser = util.clamp(d_mul + phaser,0,10)
        engine.phaser(phaser)
      elseif p3_index==3 then
        delay = util.clamp(d_mul + delay,0,10)
        engine.delay(delay)
      elseif p3_index==4 then
        strobe = util.clamp(d_mul + strobe,0,5)
        engine.strobe(strobe)
      elseif p3_index==5 then
        drywet = util.clamp(d_mul + drywet,0,1)
        engine.drywet(drywet)
      end
      ]]
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
        if #cutters > 1 and nav_active_control > 1 and nav_active_control < 7 then
          table.remove(cutters, active_cutter)
          table.remove(cutter_rates, active_cutter)
          for i=1,#cutters,1
          do
            cutters[i]:set_cutter_id(i)
            cutters[i]:set_active_edge(1)
            cutters[i]:set_display_mode(0)
          end
          active_cutter = 1
          cutter_to_play = 1

          local display_mode = nav_active_control == 3 and 1 or 2
          cutters[active_cutter]:set_display_mode(display_mode)
          sample_player.update()
        elseif nav_active_control == 7 then

        end
      elseif n==3 and z==1 then
        if nav_active_control == 1 then
          playing = playing == 1 and 0 or 1
          softcut.play(1, playing)
        end
        if nav_active_control > 1 then

          local new_cutter_start_x, new_cutter_finish_x
          if cutters[active_cutter]:get_finish_x() < 60 then
            new_cutter_start_x = cutters[active_cutter]:get_finish_x() + 5
            new_cutter_finish_x = new_cutter_start_x + 10
          else
            new_cutter_start_x = cutters[active_cutter]:get_start_x() - 20
            new_cutter_finish_x = new_cutter_start_x + 10
          end
          table.insert(cutters, active_cutter+1, Cutter:new(active_cutter+1, new_cutter_start_x, new_cutter_finish_x))
          table.insert(cutter_rates, active_cutter+1,cutter_rates[active_cutter])
          sample_player.cutters_start_finish_update()
        end
        for i=1,#cutters,1
        do
          cutters[i]:set_cutter_id(i)
          cutters[i]:set_display_mode(0)
        end
        local display_mode = nav_active_control == 3 and 1 or 2
        cutters[active_cutter]:set_display_mode(display_mode)
        sample_player.update()
      end
    end
    if (not waveform_loaded or nav_active_control == 1) and n==2 and z==1 then
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
  end
end

return{
  enc=enc,
  key=key
}
