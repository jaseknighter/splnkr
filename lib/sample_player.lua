--------------------------
-- play samples
--------------------------
saved = "..."
level = 0.20
rec = 1.0
pre = 1.0
-- rate = 1
length = 1
sample_position = 1
last_sample_position = nil
playhead_position = 1
selecting = false
file_selected = false
waveform_loaded = false
subnav_title = ""
playing = 0
cutters = {}
cutter_rates = {1,1}
active_cutter = 1

selected_cutter_group = 1

play_mode = 1 
record_mode = 2
autogen = 5
cutter_start_x_sec, cutter_finish_x_sec = nil
cutter_to_play = 1

left_side = 10
right_side = 120

nav_active_control = 1

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
  "full loop",
  "all cuts",
  "sel cut",
}

sample_player = {}

function sample_player.load_file(file)
  selecting = false
  if file ~= "cancel" then
    file_selected = true
    sample_player_nav_labels[1] = "select/play sample"

    softcut.buffer_clear_region(1,-1)
    local ch, samples = audio.file_info(file)
    length = samples/48000
    -- softcut.buffer_read_mono(file,0,1,-1,1,1)
    -- softcut.buffer_read_mono(file,0,1,-1,1,2)
    softcut.buffer_read_stereo(file,0,0,-1)
    sample_player.init_cutters()
    sample_player.reset()
    waveform_loaded = true
    new_sample_load_completed()
  else
    sample_player.update()
  end
end

function sample_player.reset()
  for i=1,2 do
    softcut.enable(i,1)
    softcut.buffer(i,i)
    softcut.loop(i,1)
    if cutters[1] then
      if play_mode > 1 then
        if play_mode == 3 then cutter_to_play = selected_cutter_group end
        cutter_start_x_sec = util.linlin(10,120,0,length,cutters[cutter_to_play]:get_start_x_updated())
        cutter_finish_x_sec = util.linlin(10,120,0,length,cutters[cutter_to_play]:get_finish_x_updated())      
      else 
        cutter_start_x_sec = 1
        cutter_finish_x_sec = 1+length
      end 
      softcut.loop_start(i,cutter_start_x_sec)
      softcut.loop_end(i,cutter_finish_x_sec)
    else 
      softcut.loop_start(i,1)
      softcut.loop_end(i,1+length)
      softcut.position(i,sample_position)
    end 
    local rate = play_mode < 2 and cutter_rates[1] or cutter_rates[cutter_to_play]
    softcut.rate(i,rate)
    softcut.play(1,1)
    playing = 1
    softcut.fade_time(1,0)
  end
  sample_player.cutters_start_finish_update()
  sample_player.update_content(1,1,length,128)
end

function sample_player.set_play_mode(mode)
-- mode 0: stop
-- mode 1: play entire sample
-- mode 2: play cutters in sequence
-- mode 3: play selected cutter
  play_mode = mode
  if play_mode == 0 then
    playing = 0
    softcut.play(1, playing)
  else
    if play_mode == 1 then
      playing = 1
      softcut.play(1, playing)
    end
    sample_player.reset()
  end
end

-- function sample_player.copy_cut()
--   local rand_copy_end = math.random(1,util.round(length))
--   local rand_copy_start = math.random(1,util.round(rand_copy_end - (rand_copy_end/10)))
--   local rand_dest = math.random(1,util.round(length))
--   softcut.buffer_copy_mono(2,1,rand_copy_start,rand_dest,rand_copy_end-rand_copy_start,0.1,math.random(0,1))
--   sample_player.update_content(1,1,length,128)
-- end

-- WAVEFORMS
local interval = 0
waveform_samples = {}
scale = 30

function sample_player.on_render(ch, start, i, s)
  waveform_samples = s
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

local reset_cutter_to_play = false

function sample_player.playhead_position_update(i,pos)
  sample_position = (pos - 1) / length
  if cutters[cutter_to_play] then
    local next_cutter_to_play = util.wrap(cutter_to_play+1,1,#cutters)
    local rate = play_mode < 2 and cutter_rates[1] or cutter_rates[next_cutter_to_play]
    if (rate > 0 and sample_position < last_sample_position) or 
        (rate < 0 and sample_position > last_sample_position) then
      if play_mode == 2 then 
        if  (rate > 0 and sample_position < last_sample_position) then 
          sample_position = last_sample_position - 1
        else
          sample_position = last_sample_position + 1
        end
        cutter_to_play = next_cutter_to_play
        cutter_start_x_sec = util.linlin(10,120,1,length,cutters[cutter_to_play]:get_start_x_updated())
        cutter_finish_x_sec = util.linlin(10,120,1,length,cutters[cutter_to_play]:get_finish_x_updated()) 
        sample_player.reset()
      elseif play_mode == 3 then
        sample_player.reset()
      end
    end

    if play_mode > 1 then
      local start = cutters[cutter_to_play]:get_start_x_updated()
      local finish = cutters[cutter_to_play]:get_finish_x_updated()
      local active_cutter_sample_position = (pos - cutter_start_x_sec)/(cutter_finish_x_sec-cutter_start_x_sec)
      playhead_position = util.linlin(0,1,start,finish,active_cutter_sample_position)
    else 
      playhead_position = util.linlin(0,1,10,120,sample_position)
    end
    if selecting == false and menu_status == false then 
      sample_player.update() 
    end  
  end

  last_sample_position = sample_position
end

function sample_player.update_content(buffer,winstart,winend,samples)
  softcut.render_buffer(buffer, winstart, winend - winstart, 128)
end
--/ WAVEFORMS

function sample_player.init()
  softcut.buffer_clear()
  audio.level_adc_cut(1)
  softcut.level_input_cut(1,2,1.0)
  softcut.level_input_cut(2,2,1.0)
  softcut.level(1,0.2)
  softcut.level(2,0.2)
  softcut.phase_quant(1,0.01)
  softcut.event_phase(sample_player.playhead_position_update)
  softcut.poll_start_phase()
  softcut.event_render(sample_player.on_render)
  sample_player.reset()
end

function sample_player.init_cutters()
  cutters = {}
  local cutter1_start_x = 10
  local cutter1_finish_x = 20
  local cutter2_start_x = 40
  local cutter2_finish_x = 50
  cutters[1] = Cutter:new(1,cutter1_start_x,cutter1_finish_x)
  cutters[2] = Cutter:new(2,cutter2_start_x,cutter2_finish_x)
end

function sample_player.autogenerate_cutters(a)
  if waveform_loaded and nav_active_control > 1 then
    cutters = {}
    cutter_rates = {}
    local cutter1_start_x = 0
    local cutter1_finish_x = 128/a
    cutters[1] = Cutter:new(1,cutter1_start_x,cutter1_finish_x)
    cutter_rates[1] = 1

    local cutter_spacing = 128/a
    for i=2,a,1
    do
      local new_cutter_start_x, new_cutter_finish_x
      new_cutter_start_x = cutter_spacing*(i-1)
      new_cutter_finish_x = cutter_spacing*(i)

      table.insert(cutters, i, Cutter:new(i, new_cutter_start_x, new_cutter_finish_x))
      table.insert(cutter_rates, i,1)
    end
    sample_player.cutters_start_finish_update()


    active_cutter = 1
    cutter_to_play = 1
    local display_mode = nav_active_control == 3 and 1 or 2
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
  screen.rect(2+(area_menu_width*(nav_active_control-1)),10, area_menu_width, 3)
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

local elipsis_counter = 0
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
  subnav_title = sample_player_nav_labels[nav_active_control] 
  if msg == nil then
    if nav_active_control == 2 then
      subnav_title = subnav_title .. ": " .. play_mode_text[play_mode+1]
    elseif nav_active_control == 3 then
      local cut_loc
      local active_cutter_edge = cutters[active_cutter]:get_active_edge()
      if active_cutter_edge == 1 then -- adjust start cuttter
        cut_loc = cutters[active_cutter]:get_start_x()/128*length
        cut_loc = math.floor(cut_loc * 10^3 + 0.5) / 10^3 -- round to nearest 1000th
        subnav_title = subnav_title .. ": " .. cut_loc
      else
        cut_loc = cutters[active_cutter]:get_finish_x()/128*length
        cut_loc = math.floor(cut_loc * 10^3 + 0.5) / 10^3 -- round to nearest 1000th
        subnav_title = subnav_title .. ": " .. cut_loc
      end
    elseif nav_active_control == 4 then
      local start = cutters[active_cutter]:get_start_x()
      start = start and start or 0
      local finish = cutters[active_cutter]:get_finish_x()
      finish = finish and finish or 1
      local clip_loc = (start + (finish-start)/2)/128*length
      clip_loc = math.floor(clip_loc * 10^3 + 0.5) / 10^3 -- round to nearest 1000th
      subnav_title = subnav_title .. ": " .. clip_loc
    elseif nav_active_control == 5 then
      local rate = cutter_rates[active_cutter]
      local cutter_to_show = active_cutter
      subnav_title = subnav_title .. "[" .. cutter_to_show .. "]: " .. rate
    elseif nav_active_control == 6 then
      subnav_title = subnav_title .. ": " .. level
    elseif nav_active_control == 7 then
      subnav_title = subnav_title .. ": " .. autogen
    end

    screen.level(15)
    screen.stroke()
    screen.rect(0,0,screen_size.x,10)
    screen.fill()
    screen.level(0)
    screen.move(4,7)
    screen.text(subnav_title)
    if file_selected then
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

local c = 0
function sample_player.update()
  if pages.index == 1 and menu_status == false and selecting == false then
    screen.clear()
    if show_instructions == true then 
      instructions.display() 
    else
      screen.level(4)
      local x_pos = 0
      for i,s in ipairs(waveform_samples) do
        local height = util.round(math.abs(s) * (scale*level))
        screen.move(util.linlin(0,128,10,120,x_pos), 35 - height)
        screen.line_rel(0, 2 * height)
        screen.stroke()
        x_pos = x_pos + 1
      end
      screen.level(15)
      if playhead_position and playhead_position >= 10 and playhead_position <=120 then
        screen.move(playhead_position,18)
        screen.line_rel(0, 35)
        screen.stroke()
      end 
      for i=1,#cutters,1
      do
        cutters[i]:update()
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