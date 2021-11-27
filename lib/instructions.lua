-- screen instructions: accessed by pressing Key 1 (K1) and Key 2 (K2)

local instructions = {}

instructions.display = function ()
  screen.level(15)
  if pages.index == 1 then
    screen.move(5,20)
    if waveform_loaded == true then
      screen.text("e2: next/prev control")
      screen.move(5, 28)
    end
    if (sample_player.nav_active_control == 1) then
      screen.text("k2: select sample")
      if waveform_loaded == true then
        screen.move(5, 36)
        screen.text("e1 + k3: scrub playhead")
        screen.move(5, 44)
        screen.text("e3: select active voice")
        screen.move(5, 52)
        -- screen.text("k3: start/stop playhead")
      end
    elseif (sample_player.nav_active_control == 2) then
      screen.text("k1 + k2: stop/start sel voice")
      screen.move(5, 36)
        --screen.text("k2/k3: delete/add cutter")
        screen.text("e3: set play mode sel")
      screen.move(5, 44)
      screen.text("k1 + e3: set play mode all")
      screen.move(5, 52)
    elseif (sample_player.nav_active_control == 3) then
      --screen.text("k2/k3: delete/add cutter")
      screen.text("k1 + k2: stop/start sel voice")
      screen.move(5, 36)
      screen.text("k1 + e2: select cutter")
      screen.move(5, 44)
      screen.text("e3: select cutter end")
      screen.move(5, 52)
      screen.text("k1 + e3: adjust end")
      screen.move(5, 60)
      screen.text("k1 + e1: fine adjust end")
    elseif (sample_player.nav_active_control == 4) then
      screen.text("k1 + k2: stop/start sel voice")
      screen.move(5, 36)
      --screen.text("k2/k3: delete/add cutter")
      screen.text("k1 + e2: select cutter")
      screen.move(5, 44)
      screen.text("k1 + e3: adjust cutter")
      screen.move(5, 52)
      screen.text("k1 + e1: fine adjust cutter")
      screen.move(5, 60)
    elseif (sample_player.nav_active_control == 5) then
      screen.text("k1 + k2: stop/start sel voice")
      screen.move(5, 36)
      --screen.text("k2/k3: delete/add cutter")
      screen.text("e3: adj rate")
      screen.move(5, 44)
      screen.text("k1 + e3: fine adj rate")
      screen.move(5, 52)
      screen.text("k1 + e3: adj selected rate")
      screen.move(5, 60)
    elseif (sample_player.nav_active_control == 6) then
      screen.text("k1 + k2: stop/start sel voice")
      screen.move(5, 36)
      --screen.text("k2/k3: delete/add cutter")
      screen.text("e3: adj sel level")
      screen.move(5, 44)
      screen.text("k1+e3: adj all levels")
      screen.move(5, 52)
    elseif (sample_player.nav_active_control == 7) then
      screen.text("k1 + k2: stop/start sel voice")
      screen.move(5, 36)
      screen.text("e3: autogen by level")
      screen.move(5, 44)
      screen.text("k1 + e3: autogen evenly")
      screen.move(5, 52)
      -- screen.text("PARAMS>EDIT: save clips")
      -- screen.move(5, 60)
      -- screen.text("to dust/audio/clipper/")
    end
  elseif pages.index == 2 then
    screen.move(5,20)
    screen.text("e2: select control")
    screen.move(5, 28)
    screen.text("e3: change control value")

    screen.move(5, 44)
    screen.text("k2/k3: -/+ control point")
    screen.move(5, 52)
    screen.text("k1 + k3: show mod controls")
    screen.move(5, 60)
  elseif pages.index == 3 then
    screen.move(5,20)
    screen.text("k2: select seq group")
    screen.move(5, 28)
    screen.text("k3: -/+ ctrl item")
    screen.move(5, 44)
    screen.text("k2: nav up")
    screen.move(5, 52)
    screen.text("k3: nav down")
    screen.move(5, 60)
  end
end

return instructions
