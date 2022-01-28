
--------------------------
-- play samples

-- todo: move variables into local scope
-- todo: address softcut params set to 1 in the reset function:
--      softcut.enable(voice,1)
--      softcut.buffer(voice,1)
--      softcut.loop(voice,1)
-- todo: in spl.reset set softcut.play according to currently playing voices
-- todo: is playing variable used for anything

--------------------------
sample_player_live = {}
spl = sample_player_live

spl.mode = "live"
spl.waveform_samples = {}
spl.selected_voice = 4
spl.enabled_voices = {}
spl.sample_positions = {}
spl.playhead_positions = {}
spl.cutter_assignments = {}
spl.play_modes = {}
spl.last_play_mode = {}
spl.voices_start_finish = {}
spl.voices_start_finish[1] = {}
spl.voices_start_finish[2] = {}
spl.voices_start_finish[3] = {}
spl.voices_start_finish[4] = {}
spl.voices_start_finish[5] = {}
spl.voices_start_finish[6] = {}
-- local cutter_start_sec_x, cutter_finish_x_sec

spl.selecting = false
spl.file_selected = false
-- playing = 0
spl.cutters = {}
spl.voice_rates = {1,1,1}
spl.active_cutter = 1
spl.num_cutters = 1
spl.selected_cutter_group = 1

spl.levels = {1,1,1,1,1,1}
spl.length = 10
spl.last_sample_positions = {}

spl.live_voices = {}

local subnav_title = ""

spl.nav_active_control = 1

spl_nav_labels = {
  "select/scrub voice: " .. 4,
  "play mode",
  "adj cut ends",
  "move cutter",
  "rate",
  "buffer length",
  "pre/rec/in",
  "sample level",
  "autogenerate clips"
}

sample_player.play_mode_labels = {
  "stop",
  "loop all",
  "all cuts",
  "sel cut",
  "1-shot"
}

function spl.init()
  -- softcut.buffer_clear()
  softcut.buffer_clear_channel (2)	
  for i=4,6,1 do
    softcut.level_input_cut(1,i,1.0)
    softcut.level_input_cut(2,i,1.0)
    softcut.level(i,0.8)
    softcut.buffer(i,2)
    softcut.loop(i,1)
    
    softcut.enable(i,1)
    softcut.phase_quant(i,0.1)
    spl.sample_positions[i] = 0
    spl.playhead_positions[i] = 1
    spl.cutter_assignments[i] = 0
    -- spl.play_modes[i] = i == 1 and 1 or 0
    spl.play_modes[i] = 0

    spl.voice_rates[i] = i == 4 and 1 or 0
  end
  softcut.poll_start_phase()
  softcut.event_render(sample_player.on_render)

  spl.cut_detector = CutDetector:new()

  if spl.mode == "live" then
    for i=4,6,1 do
      spl.live_voices[i] = {} 
      spl.live_voices[i].rec = 0.50
      spl.live_voices[i].pre = 0.50

      -- set voice record level 
      softcut.rec_level(i,spl.live_voices[i].rec)
      -- set voice pre level
      softcut.pre_level(i,spl.live_voices[i].pre)
      -- set record state of voice 1 to 1
      softcut.rec(i,1)
    end
    spl.cut_detector.set_bright_start()
    spl.update()
    spl.autogenerate_cutters(spl.num_cutters)
    -- spl.set_play_mode(4,1)
    -- spl.reset(4, true)
  end
end

function spl.play_check(voice)
  if spl.get_play_mode(voice) < 1 then
    spl.set_play_mode(voice,1)
  end
end

function spl.get_cutter_assignment(voice) 
  return spl.cutter_assignments[voice] 
end

function spl.set_cutter_assignment(voice, cutter_assignment) 
  spl.cutter_assignments[voice] = cutter_assignment
  spl.reset(voice, true)
end

function spl.set_rate(voice, rate)
  spl.voice_rates[voice] = rate
  spl.reset(voice)
end

function spl.set_direction(voice, direction)
  if direction > 0 and spl.voice_rates[voice] < 0 then
    spl.voice_rates[voice] = spl.voice_rates[voice] * -1
    spl.reset(voice)
  elseif direction < 0 and spl.voice_rates[voice] > 0 then
    spl.voice_rates[voice] = spl.voice_rates[voice] * -1
    spl.reset(voice)
  end
end

function spl.set_level(voice, level)
  softcut.level(voice,level)
end

function spl.set_pre(voice, pre_level)
  spl.live_voices[voice].pre = pre_level
  softcut.pre_level(voice,pre_level)
end

function spl.set_rec(voice, rec_level)
  spl.live_voices[voice].rec = rec_level
  softcut.rec_level(voice,rec_level)
end

function spl.select_next_voice(direction)
  spl.selected_voice = util.clamp(direction+spl.selected_voice,4,6)
  spl.active_cutter = spl.cutter_assignments[spl.selected_voice]
  spl.selected_cutter_group = spl.active_cutter
  spl_nav_labels[1] = "select/scrub voice: " .. spl.selected_voice
  for i=1,#spl.cutters,1
  do
    spl.cutters[i]:set_display_mode(0)
  end 
  if spl.active_cutter > 0 then
    local display_mode = spl.nav_active_control == 3 and 1 or 2  
    spl.cutters[spl.active_cutter]:set_display_mode(display_mode)
  end
end

function spl.reset(voice, set_position_at_start)
  if spl.cutters[1] then
    if spl.play_modes[voice] > 1 and spl.cutter_assignments[voice] > 0 then
       spl.voices_start_finish[voice][1] = util.linlin(10,120,0,spl.length,spl.cutters[spl.cutter_assignments[voice]]:get_start_x_updated())
      spl.voices_start_finish[voice][2] = util.linlin(10,120,0,spl.length,spl.cutters[spl.cutter_assignments[voice]]:get_finish_x_updated())      
    else 
      spl.voices_start_finish[voice][1] = 0
      spl.voices_start_finish[voice][2] = 0+spl.length
    end 
    softcut.loop_start(voice,spl.voices_start_finish[voice][1])
    softcut.loop_end(voice,spl.voices_start_finish[voice][2])
  end 
  local rate = spl.voice_rates[voice]
  softcut.rate(voice,rate)
  softcut.fade_time(voice,0.1)
  spl.cutters_start_finish_update()
  
  if spl.play_modes[voice] > 0 then
    softcut.play(voice,1)
    if set_position_at_start then 
      local pos
      pos = spl.sample_positions[voice] * spl.length
      softcut.position(voice, pos)
      softcut.enable(voice,1)
    end
  else
    softcut.play(voice,0)
    softcut.enable(voice,0)
  end
end

-- mode 0: stop
-- mode 1: play entire sample
-- mode 2: play spl.cutters in sequence
-- mode 3: play selected cutter
function spl.set_play_mode(voice, mode)
  spl.play_modes[voice] = mode
  if spl.enabled_voices[voice] ~= 1 then
    spl.enabled_voices[voice] = 1
    softcut.position(voice,1)
    if spl.voice_rates[voice] == 0 then
      for i=1,#spl.voice_rates,1 do
        if spl.voice_rates[i] ~= 0 then
          spl.voice_rates[voice] = spl.voice_rates[i]
          break
        end
      end
    end
    -- softcut.enable(voice, 1)
  end
  spl.reset(voice, true)
end

function spl.get_play_mode(voice)
  return spl.play_modes[voice] 
end

function spl.set_last_play_mode(voice, mode)
  spl.last_play_mode[voice] = mode
end

function spl.get_last_play_mode(voice)
  return spl.last_play_mode[voice] 
end

-- WAVEFORMS
-- function spl.on_render(ch, start, i, s)
--   print("on render",ch, start, i, s)
--   spl.waveform_samples = s
--   interval = i
  -- spl.update()
-- end

function spl.cutters_start_finish_update()
  for i=1,#spl.cutters,1
  do
    if spl.cutters[i] then
      local start_x = spl.cutters[i]:get_start_x()
      local finish_x = spl.cutters[i]:get_finish_x()
      start_x = util.linlin(0,128,10,120,spl.cutters[i]:get_start_x())
      finish_x = util.linlin(0,128,10,120,spl.cutters[i]:get_finish_x())
      spl.cutters[i]:cutters_start_finish_update(
        start_x, finish_x
      )
    end
  end
end

function spl.update_content(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 128)
end

function spl.autogenerate_cutters(num_cutters, override)
  -- if spl.mode == "live" then
  local starting_cutter = spl.cutters[i] and spl.cutters[i]+1 or 1
  
local cutter_spacing = 128/num_cutters
local found_modified = false

for i=#spl.cutters,1,-1 do
  if (spl.cutters[i].modified ~= true and found_modified == false) or override == true then
    table.remove(spl.cutters,i)
  else
    found_modified = true
  end
end

for i=starting_cutter,num_cutters,1
  do
    if spl.cutters[i] == nil then
      local new_cutter_start_x, new_cutter_finish_x
      new_cutter_start_x = cutter_spacing*(i-1)
      new_cutter_finish_x = cutter_spacing*(i)
      table.insert(spl.cutters, i, Cutter:new(i, new_cutter_start_x, new_cutter_finish_x))
    end
      -- table.insert(cutter_rates, i,1)
  end
  for i=4,6,1 do
    if spl.cutter_assignments[i] > num_cutters then
      spl.cutter_assignments[i] = num_cutters
    end
  end

  spl.num_cutters = #spl.cutters
  sequencer_controller.refresh_output_control_specs_map()

  spl.cutters_start_finish_update()
  spl.active_cutter = 1
  spl.selected_cutter_group = 1
  local display_mode = spl.nav_active_control == 3 and 1 or 2
  spl.cutters[1]:set_display_mode(display_mode)

  for i=4,6,1 do
    if spl.cutter_assignments[i] > num_cutters then
      spl.cutter_assignments[i] = num_cutters
    end
  end
  spl.update()     

  -- end
end

function spl.draw_sub_nav ()
  screen.level(10)
  screen.rect(2,10, screen_size.x-2, 3)
  screen.fill()
  screen.level(0)
  local num_field_menu_areas = #spl_nav_labels
  local area_menu_width = (screen_size.x-5)/num_field_menu_areas
  screen.rect(2+(area_menu_width*(spl.nav_active_control-1)),10, area_menu_width, 3)
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

function spl.draw_top_nav (msg)
  if show_instructions == true then
    subnav_title = "sampler instructions"
  elseif spl.nav_active_control == 1 or spl.nav_active_control == 6 or spl.nav_active_control == 9 then
    subnav_title = spl_nav_labels[spl.nav_active_control] 
  else
    subnav_title = spl_nav_labels[spl.nav_active_control] .. "["..spl.selected_voice.."]"
  end
  if msg == nil then
    if spl.nav_active_control == 2 then
      subnav_title = subnav_title .. ": " .. sample_player.play_mode_labels[spl.play_modes[spl.selected_voice]+1]
    elseif spl.nav_active_control == 3 and spl.cutters[spl.active_cutter] then
      local cut_loc
      local active_edge = spl.cutters[spl.active_cutter]:get_active_edge()
      if active_edge == 1 then -- adjust start cuttter
        cut_loc = spl.cutters[spl.active_cutter]:get_start_x()/128*spl.length
        cut_loc = math.floor(cut_loc * 10^3 + 0.5) / 10^3 -- round to nearest 1000th
        subnav_title = subnav_title .. ": " .. cut_loc
      else
        cut_loc = spl.cutters[spl.active_cutter]:get_finish_x()/128*spl.length
        cut_loc = math.floor(cut_loc * 10^3 + 0.5) / 10^3 -- round to nearest 1000th
        subnav_title = subnav_title .. ": " .. cut_loc
      end
    elseif spl.nav_active_control == 4 and spl.cutters[spl.active_cutter] then
      local start = spl.cutters[spl.active_cutter]:get_start_x()
      start = start and start or 0
      local finish = spl.cutters[spl.active_cutter]:get_finish_x()
      finish = finish and finish or 1
      local clip_loc = (start + (finish-start)/2)/128*spl.length
      clip_loc = math.floor(clip_loc * 10^3 + 0.5) / 10^3 -- round to nearest 1000th
      subnav_title = subnav_title .. ": " .. clip_loc
    elseif spl.nav_active_control == 5 then
      local rate = spl.voice_rates[spl.selected_voice]
      subnav_title = subnav_title .. ": " .. rate
    elseif spl.nav_active_control == 6 then
      subnav_title = subnav_title .. ": " .. spl.length
    elseif spl.nav_active_control == 7 then
      local pre = spl.live_voices[spl.selected_voice].pre
      local rec = spl.live_voices[spl.selected_voice].rec
      local input = fn.round_decimals (params:get("input_level"),2)
      subnav_title = subnav_title .. ": " .. pre .. "/" .. rec .. "/" .. input
    elseif spl.nav_active_control == 8 then
      subnav_title = subnav_title .. ": " .. spl.levels[spl.selected_voice]
    elseif spl.nav_active_control == 9 then
      subnav_title = subnav_title .. ": " .. spl.num_cutters
    end

    screen.level(15)
    screen.stroke()
    screen.rect(0,0,screen_size.x,10)
    screen.fill()
    screen.level(0)
    screen.move(4,7)
    screen.text(subnav_title)
    if spl.file_selected == true or spl.mode == "live" then
      spl.draw_sub_nav()
    end
  elseif show_instructions == false then 
    screen.level(15)
    screen.stroke()
    screen.rect(0,0,screen_size.x,10)
    screen.fill()
    screen.level(0)
    screen.move(4,7)
    clock.run(set_saving_elipses)
    screen.text(msg .. saving_elipses)
  else 
    spl.draw_sub_nav()
  end
  -- navigation marks
  screen.level(0)
  screen.rect(0,(pages.index-1)/NUM_PAGES*10,2,math.floor(10/NUM_PAGES))
  screen.fill()
end

local scale = 50
function spl.update()
  if pages.index == 2 and menu_status == false and spl.selecting == false then
    screen.clear()
    if show_instructions == true then 
      instructions.display() 
    else
      -- draw the waveform
      local x_pos = 0
      
      if (spl.mode == "live") then
        for i,s in ipairs(spl.waveform_samples) do
          local brightness = util.round(math.abs(s) * (scale*spl.levels[spl.selected_voice]))
          brightness = util.round(util.linlin(0,30,0,15, brightness))
          screen.level(brightness)
          if spl.cut_detector.bright_checked == false then
            spl.cut_detector.set_bright(math.abs(s) * 10000)
          end
          local x = util.linlin(0,128,10,120,x_pos)
          screen.move(x, 25)
          screen.line_rel(0, 20)
          screen.stroke()
          x_pos = x_pos + 1
        end
      end
      if spl.cut_detector.bright_checked == false then
        spl.cut_detector.set_bright_completed()
      end
      -- draw the spl.cutters
      for i=1,#spl.cutters,1
      do
        spl.cutters[i]:update()
      end
      -- draw the playhead positions for each voice
      for i=4,6,1 do
        local playhead_screen_level 
        if i == spl.selected_voice then
          screen.level(15)
        elseif spl.play_modes[i] > 0 then
          screen.level(4)
        else 
          -- screen.level(0)
        end
        local playhead_pos = spl.playhead_positions[i]
        if playhead_pos and playhead_pos >= 10 and playhead_pos <=120 then
          screen.move(spl.playhead_positions[i],20)
          screen.line_rel(0, 35)
          screen.line_rel(3, 0)
          screen.text(i)
          screen.stroke()
        end 
      end
      spl.update_content(2,0,spl.length,128)
    end
    if saving == false then
      spl.draw_top_nav()
    else
      spl.draw_top_nav("saving")
    end
    -- screen.update()
  end
end

return spl