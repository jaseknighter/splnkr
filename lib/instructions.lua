-- screen instructions: accessed by pressing Key 1 (K1) and Key 2 (K2)

local instructions = {}

instructions.display = function ()
  screen.level(15)
  screen.move(5,20)
  screen.text("e2: next/prev control")
  screen.move(5, 28)

  if (sample_player.nav_active_control == 1) then
    screen.text("k2: select sample")
    screen.move(5, 36)
    screen.text("e3: incr/decr playhead")
    screen.move(5, 44)
    screen.text("k3: start/stop playhead")
  elseif (sample_player.nav_active_control == 2) then
    screen.text("k2/k3: delete/add cutter")
    screen.move(5, 36)
    screen.text("e3: change play mode")
  elseif (sample_player.nav_active_control == 3) then
    screen.text("k2/k3: delete/add cutter")
    screen.move(5, 36)
    screen.text("k1 + e2: select cutter")
    screen.move(5, 44)
    screen.text("k1 + e3: adjust cutter")
    screen.move(5, 52)
    screen.text("k1 + e1: fine adjust cutter")
    screen.move(5, 60)
    screen.text("e3: select cutter end")
  elseif (sample_player.nav_active_control == 4) then
    screen.text("k2/k3: delete/add cutter")
    screen.move(5, 36)
    screen.text("k1 + e2: select cutter")
    screen.move(5, 44)
    screen.text("k1 + e3: adjust cutter")
    screen.move(5, 52)
    screen.text("k1 + e1: fine adjust cutter")
  elseif (sample_player.nav_active_control == 5) then
    screen.text("k2/k3: delete/add cutter")
    screen.move(5, 36)
    screen.text("k1 + e2: select rate")
    screen.move(5, 44)
    screen.text("e3: adj all rates")
    screen.move(5, 52)
    screen.text("k1 + e1: fine adjust rate")
    screen.move(5, 60)
    screen.text("k1 + e3: adj selected rate")
  elseif (sample_player.nav_active_control == 6) then
    screen.text("k2/k3: delete/add cutter")
    screen.move(5, 36)
    screen.text("e3: adjust level")
  elseif (sample_player.nav_active_control == 7) then
    screen.text("e3: autogen by level")
    screen.move(5, 36)
    screen.text("k1 + e3: autogen evenly")
    screen.move(5, 52)
    screen.text("PARAMS>EDIT: save clips")
    screen.move(5, 60)
    screen.text("to dust/audio/clipper/")
  end
  screen.update()
end

return instructions
