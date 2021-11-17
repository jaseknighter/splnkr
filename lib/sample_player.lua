-- softcut.position(2,3000)

--------------------------
-- play samples

-- todo: move variables into local scope
-- todo: address softcut params set to 1 in the reset function:
--      softcut.enable(voice,1)
--      softcut.buffer(voice,1)
--      softcut.loop(voice,1)
-- todo: insample_player.reset set softcut.play according to currently playing voices
-- todo: is playing variable used for anything

--------------------------
sample_player = {}
sample_player.waveform_samples = {}
sample_player.selected_voice = 1
sample_player.enabled_voices = {}
sample_player.sample_positions = {}
sample_player.playhead_positions = {}
sample_player.cutter_assignments = {}
sample_player.play_modes = {}
sample_player.last_play_mode = {}
sample_player.voices_start_finish = {}
sample_player.voices_start_finish[1] = {}
sample_player.voices_start_finish[2] = {}
sample_player.voices_start_finish[3] = {}
sample_player.voices_start_finish[4] = {}
sample_player.voices_start_finish[5] = {}
sample_player.voices_start_finish[6] = {}
-- local cutter_start_sec_x, cutter_finish_x_sec

sample_player.selecting = false
sample_player.file_selected = false
-- playing = 0
cutters = {}
sample_player.voice_rates = {1,1}
sample_player.active_cutter = 1
sample_player.num_cutters = 1
sample_player.selected_cutter_group = 1
record_mode = 2

elipsis_counter = 0
saved = "..."
sample_player.levels = {1,1,1,1,1,1}
rec = 1.0
pre = 1.0
length = 1
sample_player.last_sample_positions = {}
waveform_loaded = false
subnav_title = ""
autogen = 1 --5
left_side = 10
right_side = 120
sample_player.nav_active_control = 1
cutter_to_play = false

sample_player_nav_labels = {
  "k2 to select sample",
  "play mode",
  "adj cut ends",
  "move cutter",
  "rate",
  "sample level",
  "autogenerate clips"
}

play_mode_text = {
  "stop",
  "loop all",
  "all cuts",
  "sel cut",
  "1-shot"
}

function sample_player.init()
  softcut.buffer_clear()
  audio.level_adc_cut(1)
  for i=1,6,1 do
    softcut.level_input_cut(1,i,1.0)
    softcut.level_input_cut(2,i,1.0)
    softcut.level(i,0.8)
    softcut.buffer(i,1)
    softcut.loop(i,1)
    
    softcut.enable(1,1)
    softcut.phase_quant(i,0.1)
    sample_player.sample_positions[i] = 0
    sample_player.playhead_positions[i] = 1
    sample_player.cutter_assignments[i] = 0
    -- sample_player.play_modes[i] = i == 1 and 1 or 0
    sample_player.play_modes[i] = 0

    sample_player.voice_rates[i] = i == 1 and 1 or 0
  end
  softcut.event_phase(sample_player.playhead_position_update)
  softcut.poll_start_phase()
  softcut.event_render(sample_player.on_render)
end

function sample_player.play_live()

  sample_player.selecting = false
  play_live = true 
  
  sample_player.num_cutters = 1
  
  sample_player_nav_labels[1] = "select/play/scrub voice: " .. 1

  softcut.buffer_clear_region(1,-1)
  
  -- for i=1,6,1 do
  --   sample_player.reset(i)
  -- end
  
  waveform_loaded = true
  -- clock.run(sample_player.init_cutters)
  sample_player.autogenerate_cutters(sample_player.num_cutters)
  
  -- clock.run(cut_detector.set_bright_start)
  
  -- sample_player.set_play_mode(1,1)
  softcut.play(1,1)


end

function sample_player.load_file(file)
  sample_player.selecting = false
  sample_player.num_cutters = 1
  if file ~= "cancel" then
    sample_player.file_selected = true
    sample_player_nav_labels[1] = "select/play/scrub voice: " .. 1

    softcut.buffer_clear_region(1,-1)
    local ch, samples = audio.file_info(file)
    length = samples/48000
    softcut.buffer_read_mono(file,0,0,-1,1,1)
    -- softcut.buffer_read_mono(file,0,1,-1,1,2)
    -- softcut.buffer_read_stereo(file,0,0,-1)
    for i=1,6,1 do
      sample_player.reset(i)
    end
    -- sample_player.reset(1)
    waveform_loaded = true
    -- clock.run(sample_player.init_cutters)
    sample_player.autogenerate_cutters(sample_player.num_cutters)
    sample_player.set_play_mode(1,1)
    clock.run(cut_detector.set_bright_start)
  end
end

function sample_player.play_check(voice)
  if sample_player.get_play_mode(voice) < 1 then
    sample_player.set_play_mode(voice,1)
  end
end

function sample_player.get_cutter_assignment(voice) 
  return sample_player.cutter_assignments[voice] 
end

function sample_player.set_cutter_assignment(voice, cutter_assignment) 
  sample_player.cutter_assignments[voice] = cutter_assignment
  sample_player.reset(voice, true)
end

function sample_player.set_rate(voice, rate)
  sample_player.voice_rates[voice] = rate
  sample_player.reset(voice)
end

function sample_player.set_direction(voice, direction)
  if direction > 0 and sample_player.voice_rates[voice] < 0 then
    sample_player.voice_rates[voice] = sample_player.voice_rates[voice] * -1
    sample_player.reset(voice)
  elseif direction < 0 and sample_player.voice_rates[voice] > 0 then
    sample_player.voice_rates[voice] = sample_player.voice_rates[voice] * -1
    sample_player.reset(voice)
  end
end

function sample_player.set_level(voice, level)
  softcut.level(voice,level)
end

function sample_player.select_next_voice(direction)
  sample_player.selected_voice = util.clamp(direction+sample_player.selected_voice,1,6)
  sample_player.active_cutter = sample_player.cutter_assignments[sample_player.selected_voice]
  sample_player.selected_cutter_group = sample_player.active_cutter
  sample_player_nav_labels[1] = "select/play/scrub voice: " .. sample_player.selected_voice
  for i=1,#cutters,1
  do
    cutters[i]:set_display_mode(0)
  end 
  if sample_player.active_cutter > 0 then
    local display_mode = sample_player.nav_active_control == 3 and 1 or 2  
    cutters[sample_player.active_cutter]:set_display_mode(display_mode)
  end
  if sample_player.enabled_voices[sample_player.selected_voice] == nil then
    -- sample_player.set_play_mode(sample_player.selected_voice,1)
  end
end

function sample_player.reset(voice, set_position_at_start)
  softcut.buffer(voice,1)
  softcut.loop(voice,1)
  
  if cutters[1] then
    if sample_player.play_modes[voice] > 1 and sample_player.cutter_assignments[voice] > 0 then
       sample_player.voices_start_finish[voice][1] = util.linlin(10,120,0,length,cutters[sample_player.cutter_assignments[voice]]:get_start_x_updated())
      sample_player.voices_start_finish[voice][2] = util.linlin(10,120,0,length,cutters[sample_player.cutter_assignments[voice]]:get_finish_x_updated())      
    else 
      sample_player.voices_start_finish[voice][1] = 0
      sample_player.voices_start_finish[voice][2] = 0+length
    end 
    softcut.loop_start(voice,sample_player.voices_start_finish[voice][1])
    softcut.loop_end(voice,sample_player.voices_start_finish[voice][2])
  end 
  local play_mode = sample_player.play_modes[voice]
  local rate = sample_player.voice_rates[voice]
  
  softcut.rate(voice,rate)
  -- playing = 1
  softcut.fade_time(voice,0)
  sample_player.cutters_start_finish_update()
  
  if sample_player.play_modes[voice] > 0 then
    softcut.play(voice,1)
    if set_position_at_start then 
      local pos
      if sample_player.voice_rates[voice] > 0 then
        pos = sample_player.voices_start_finish[1][1]
      else
        pos = sample_player.voices_start_finish[1][2]
      end
      softcut.position(voice, pos)
    end
  else
    softcut.play(voice,0)
  end
  sample_player.update_content(1,0,length,128)
end

-- mode 0: stop
-- mode 1: play entire sample
-- mode 2: play cutters in sequence
-- mode 3: play selected cutter
function sample_player.set_play_mode(voice, mode)
  sample_player.play_modes[voice] = mode
  if sample_player.enabled_voices[voice] ~= 1 then
    sample_player.enabled_voices[voice] = 1
    softcut.position(voice,1)
    if sample_player.voice_rates[voice] == 0 then
      for i=1,#sample_player.voice_rates,1 do
        if sample_player.voice_rates[i] ~= 0 then
          sample_player.voice_rates[voice] = sample_player.voice_rates[i]
          break
        end
      end
    end
    softcut.enable(voice, 1)
  end
  sample_player.reset(voice)
end

function sample_player.get_play_mode(voice)
  return sample_player.play_modes[voice] 
end

function sample_player.set_last_play_mode(voice, mode)
  sample_player.last_play_mode[voice] = mode
end

function sample_player.get_last_play_mode(voice)
  return sample_player.last_play_mode[voice] 
end

-- WAVEFORMS
function sample_player.on_render(ch, start, i, s)
  sample_player.waveform_samples = s
  interval = i
  -- sample_player.update()
end

function sample_player.cutters_start_finish_update()
  for i=1,#cutters,1
  do
    if cutters[i] then
      local start_x = cutters[i]:get_start_x()
      local finish_x = cutters[i]:get_finish_x()
      start_x = util.linlin(0,128,10,120,cutters[i]:get_start_x())
      finish_x = util.linlin(0,128,10,120,cutters[i]:get_finish_x())
      cutters[i]:cutters_start_finish_update(
        start_x, finish_x
      )
    end
  end
end

function sample_player.playhead_position_update(voice,pos)
  sample_player.sample_positions[voice] = (pos) / length
  if waveform_loaded then
    local next_cutter_to_play = util.wrap(sample_player.cutter_assignments[voice]+1,1,#cutters)
    local rate = tonumber(sample_player.voice_rates[voice])
    if (next_cutter_to_play and (sample_player.sample_positions[voice] and sample_player.last_sample_positions[voice]) and (rate > 0 and sample_player.sample_positions[voice] < sample_player.last_sample_positions[voice]) or 
    (rate < 0 and sample_player.sample_positions[voice] > sample_player.last_sample_positions[voice])) then
      if sample_player.play_modes[voice] == 2 then -- all cuts
        if  (rate > 0 and sample_player.sample_positions[voice] < sample_player.last_sample_positions[voice]) then 
          sample_player.sample_positions[voice] = sample_player.last_sample_positions[voice] - 1
        else
          sample_player.sample_positions[voice] = sample_player.last_sample_positions[voice] + 1
        end
        sample_player.cutter_assignments[voice] = next_cutter_to_play
        sample_player.voices_start_finish[voice][1] = util.linlin(10,120,0,length,cutters[sample_player.cutter_assignments[voice]]:get_start_x_updated())
        sample_player.voices_start_finish[voice][2] = util.linlin(10,120,0,length,cutters[sample_player.cutter_assignments[voice]]:get_finish_x_updated()) 
        sample_player.reset(voice)
      elseif sample_player.play_modes[voice] > 2 then -- selected cut/repeat/1shot
        if sample_player.play_modes[voice] < 4 then
          sample_player.reset(voice)
        else -- stop 1-shot
          sample_player.set_play_mode(voice,0)
        end
      end
    end

    if sample_player.play_modes[voice] > 1 then
      if sample_player.cutter_assignments[voice] < 1 then
        sample_player.cutter_assignments[voice] = 1
      end
      local start = cutters[sample_player.cutter_assignments[voice]]:get_start_x_updated()
      local finish = cutters[sample_player.cutter_assignments[voice]]:get_finish_x_updated()
      local active_cutter_sample_position = (pos - sample_player.voices_start_finish[voice][1])/(sample_player.voices_start_finish[voice][2]-sample_player.voices_start_finish[voice][1])
      sample_player.playhead_positions[voice] = util.linlin(0,1,start,finish,active_cutter_sample_position)
    else 
      sample_player.playhead_positions[voice] = util.linlin(0,1,10,120,sample_player.sample_positions[voice])
    end
    if sample_player.selecting == false and menu_status == false then 
      sample_player.update() 
    end  
  end

  sample_player.last_sample_positions[voice] = sample_player.sample_positions[voice]
end

function sample_player.update_content(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 128)
end
--/ WAVEFORMS


function sample_player.autogenerate_cutters(num_cutters)
  if waveform_loaded then

    -- make evenly spaced cuts
    if  alt_key_active then
      cutters = {}
      cutter_rates = {}
      local cutter1_start_x = 0
      local cutter1_finish_x = 128/num_cutters
      cutters[1] = Cutter:new(1,cutter1_start_x,cutter1_finish_x)
      cutter_rates[1] = 1

      local cutter_spacing = 128/num_cutters
      for i=2,num_cutters,1
      do
        local new_cutter_start_x, new_cutter_finish_x
        new_cutter_start_x = cutter_spacing*(i-1)
        new_cutter_finish_x = cutter_spacing*(i)
        table.insert(cutters, i, Cutter:new(i, new_cutter_start_x, new_cutter_finish_x))
        table.insert(cutter_rates, i,1)
      end
    else
      -- make cuts according to sample levels
      cutters = {}
      cutter_rates = {}
      
      -- get the cut indices and resort them lowest to highest
      local sorted_cut_indices = cut_detector.get_sorted_cut_indices()
      autogen_cut_indices = {}
      for i=1,num_cutters-1,1
      do
        local new_cutter1, new_cutter2
        new_cutter1 = sorted_cut_indices[i] and sorted_cut_indices[i] or 0
        table.insert(autogen_cut_indices,new_cutter1)
      end
      
      table.sort(autogen_cut_indices)
      
      local cutter_first_start_x = 0
      local cutter_first_finish_x = autogen_cut_indices[1]
      cutters[1] = Cutter:new(1,cutter_first_start_x,cutter_first_finish_x)
      cutter_rates[1] = 1

      for i=1,num_cutters-1,1
      do
        local new_cutter_start_x = autogen_cut_indices[i]
        local new_cutter_finish_x = autogen_cut_indices[i+1] and autogen_cut_indices[i+1] or 128
        table.insert(cutters, i+1, Cutter:new(i+1, new_cutter_start_x, new_cutter_finish_x))
        table.insert(cutter_rates, i+1,1)
      end
    end
    sample_player.cutters_start_finish_update()
    sample_player.active_cutter = 1
    sample_player.selected_cutter_group = 1
    cutter_to_play = 1
    local display_mode = sample_player.nav_active_control == 3 and 1 or 2
    cutters[1]:set_display_mode(display_mode)
    sample_player.update()     
  end
end

function sample_player.draw_sub_nav ()
  screen.level(10)
  screen.rect(2,10, screen_size.x-2, 3)
  screen.fill()
  screen.level(0)
  local num_field_menu_areas = #sample_player_nav_labels
  local area_menu_width = (screen_size.x-5)/num_field_menu_areas
  screen.rect(2+(area_menu_width*(sample_player.nav_active_control-1)),10, area_menu_width, 3)
  screen.fill()
  screen.level(4)
  for i=1, num_field_menu_areas+1,1
  do
    if i < num_field_menu_areas+1 then
      screen.rect(2+(area_menu_width*(i-1)),10, 1, 3)
    else
      screen.rect(2+(area_menu_width*(i-1))-1,10, 1, 3)
    end
  end
  screen.fill()
end

function set_saving_elipses()
  elipsis_counter = elipsis_counter + 1
  if elipsis_counter == 30 then 
    elipsis_counter = 0
    if #saving_elipses < 3 then
      saving_elipses = saving_elipses .. "." 
    else
      saving_elipses = "" 
    end
  end
end

function sample_player.draw_top_nav (msg)
  if (waveform_loaded == false) or sample_player.nav_active_control == 1 or sample_player.nav_active_control == 7 then
    subnav_title = sample_player_nav_labels[sample_player.nav_active_control] 
  else
    subnav_title = sample_player_nav_labels[sample_player.nav_active_control] .. "["..sample_player.selected_voice.."]"
  end
  if msg == nil then
    if sample_player.nav_active_control == 2 then
      subnav_title = subnav_title .. ": " .. play_mode_text[sample_player.play_modes[sample_player.selected_voice]+1]
    elseif sample_player.nav_active_control == 3 then
      local cut_loc
      local active_edge = cutters[sample_player.active_cutter]:get_active_edge()
      if active_edge == 1 then -- adjust start cuttter
        cut_loc = cutters[sample_player.active_cutter]:get_start_x()/128*length
        cut_loc = math.floor(cut_loc * 10^3 + 0.5) / 10^3 -- round to nearest 1000th
        subnav_title = subnav_title .. ": " .. cut_loc
      else
        cut_loc = cutters[sample_player.active_cutter]:get_finish_x()/128*length
        cut_loc = math.floor(cut_loc * 10^3 + 0.5) / 10^3 -- round to nearest 1000th
        subnav_title = subnav_title .. ": " .. cut_loc
      end
    elseif sample_player.nav_active_control == 4 then
      local start = cutters[sample_player.active_cutter]:get_start_x()
      start = start and start or 0
      local finish = cutters[sample_player.active_cutter]:get_finish_x()
      finish = finish and finish or 1
      local clip_loc = (start + (finish-start)/2)/128*length
      clip_loc = math.floor(clip_loc * 10^3 + 0.5) / 10^3 -- round to nearest 1000th
      subnav_title = subnav_title .. ": " .. clip_loc
    elseif sample_player.nav_active_control == 5 then
      local rate = sample_player.voice_rates[sample_player.selected_voice]
        subnav_title = subnav_title .. ": " .. rate
      -- local cutter_to_show = sample_player.active_cutter
      -- subnav_title = subnav_title .. "[" .. cutter_to_show .. "]: " .. rate
    elseif sample_player.nav_active_control == 6 then
      subnav_title = subnav_title .. ": " .. sample_player.levels[sample_player.selected_voice]
    elseif sample_player.nav_active_control == 7 then
      subnav_title = subnav_title .. ": " .. sample_player.num_cutters
    end

    screen.level(15)
    screen.stroke()
    screen.rect(0,0,screen_size.x,10)
    screen.fill()
    screen.level(0)
    screen.move(4,7)
    screen.text(subnav_title)
    if sample_player.file_selected == true or play_live == true then
      sample_player.draw_sub_nav()
    end
  else
    screen.level(15)
    screen.stroke()
    screen.rect(0,0,screen_size.x,10)
    screen.fill()
    screen.level(0)
    screen.move(4,7)
    clock.run(set_saving_elipses)
    screen.text(msg .. saving_elipses)
  end
  -- navigation marks
  screen.level(0)
  screen.rect(0,(pages.index-1)/NUM_PAGES*10,2,math.floor(10/NUM_PAGES))
  screen.fill()
end

-- local c = 0
local scale = 50
local numit = 0
function sample_player.update()
  if pages.index == 1 and menu_status == false and sample_player.selecting == false then
    screen.clear()
    if show_instructions == true then 
      instructions.display() 
    else
      -- draw the waveform
      local x_pos = 0
      if cut_detector.bright_checked == false then
        -- cut_detector.set_bright_completed()
      end
      
      if (waveform_loaded == true) then
        
        for i,s in ipairs(sample_player.waveform_samples) do
        
          local brightness = util.round(math.abs(s) * (scale*sample_player.levels[sample_player.selected_voice]))
          brightness = util.round(util.linlin(0,30,0,15, brightness))
          screen.level(brightness)
          if cut_detector.bright_checked == false then
            cut_detector.set_bright(math.abs(s) * 10000)
          end
          local x = util.linlin(0,128,10,120,x_pos)
          screen.move(x, 25)
          screen.line_rel(0, 20)
          screen.stroke()
          x_pos = x_pos + 1
        end
        end
      if cut_detector.bright_checked == false then
        cut_detector.set_bright_completed()
      end
      -- draw the cutters
      for i=1,#cutters,1
      do
        cutters[i]:update()
      end
      -- draw the playhead positions for each voice
      for i=1,6,1 do
        local playhead_screen_level 
        if i == sample_player.selected_voice then
          screen.level(15)
        elseif sample_player.play_modes[i] > 0 then
          screen.level(4)
        else 
          -- screen.level(0)
        end
        local playhead_pos = sample_player.playhead_positions[i]
        if playhead_pos and playhead_pos >= 10 and playhead_pos <=120 then
          screen.move(sample_player.playhead_positions[i],20)
          screen.line_rel(0, 35)
          screen.line_rel(3, 0)
          screen.text(i)
          screen.stroke()

        end 
      end
    end
    if saving == false then
      sample_player.draw_top_nav()
    else
      sample_player.draw_top_nav("saving")
    end
    -- screen.update()
  end
end

return sample_player