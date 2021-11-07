-- code to update/draw the pages (screens)

page_scroll = function (delta)
  pages:set_index_delta(util.clamp(delta, -1, 1), false)
  screen_dirty = true
end

local draw_top_nav = function()
  -- if nav_off == false then
  screen.level(15)
  screen.stroke()
  screen.rect(0,0,screen_size.x,10)
  screen.fill()
  screen.level(0)
  -- end
  screen.move(4,7)
  
  -- if (pages.index ~= 3 or show_instructions == true) and observe_screen == true then 
  --   observe_screen = false 
  --   nav_off = false
  -- end

  if pages.index == 1 then
  elseif pages.index == 2 then
    local graph_active_node = envelopes[active_envelope].active_node
    local env_nav_text = ''
    if graph_active_node == -1 then 
      local env_level_text = envelopes[active_envelope].get_env_level() 
      local mult = 10^2
      env_level_text = math.floor(env_level_text * mult + 0.5) / mult
      env_nav_text = 'env level ' .. env_level_text
    elseif graph_active_node == 0 then 
      env_nav_text = 'env length ' .. envelopes[active_envelope].get_env_time() .. 's'
    else
      env_nav_text =  'node ' .. graph_active_node .. ': '
      if envelopes[active_envelope].active_node_param == 1 then
        env_nav_text = env_nav_text.. ' time ' .. envelopes[active_envelope].graph_nodes[graph_active_node].time .. 's'
      elseif envelopes[active_envelope].active_node_param == 2 then
        local level = envelopes[active_envelope].graph_nodes[graph_active_node].level 
        env_nav_text = env_nav_text.. ' level ' .. level
      elseif envelopes[active_envelope].active_node_param == 3 then
        local curve = envelopes[active_envelope].graph_nodes[graph_active_node].curve .. '°'
        env_nav_text = env_nav_text.. ' curve ' .. curve
      end
    end 
    
    if show_instructions == true then
      env_nav_text = "instructions" 
    elseif show_env_mod_params then
      env_nav_text = envelopes[active_envelope].get_control_label()
    end
    screen.text("plow " .. env_nav_text)
  elseif pages.index == 3 then
    local bcrumbs = sequencer_screen.get_control_bcrumbs() 
    local sequencer_screen_label = "sqncr "
    sequencer_screen_label = bcrumbs and sequencer_screen_label .. bcrumbs or sequencer_screen_label
    screen.text(sequencer_screen_label)
  elseif pages.index == 4 then
  elseif pages.index == 5 then
  end

  -- navigation marks
  screen.level(0)
  screen.rect(0,(pages.index-1)/5*10,2,2)
  screen.fill()
  screen.update()
end

local update_pages = function()
  if initializing == false then
    
    if pages.index == 1 then
      sample_player.update()
    elseif pages.index == 2 then
      
      envelopes[1].redraw()
      draw_top_nav()
    elseif pages.index == 3 then
        screen.clear()
        draw_top_nav()
        sequencer_screen.update()
    elseif pages.index == 4 then

    elseif pages.index == 5 then

    end
  end

  local menu_status = norns.menu.status()
  if menu_status == false then
    -- draw_top_nav()
  end


  screen.update()

end




return {
  update_pages = update_pages
}
