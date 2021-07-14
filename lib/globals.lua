-- global functions and variables 

-------------------------------------------
-- global functions
-------------------------------------------

page_scroll = function (delta)
  pages:set_index_delta(util.clamp(delta, -1, 1), false)
end

-------------------------------------------
-- global variables
-------------------------------------------

updating_controls = false
OUTPUT_DEFAULT = 4
SCREEN_FRAMERATE = 1/15
menu_status = false
pages = 0

alt_key_active = false
screen_level_graphics = 15
screen_size = vector:new(127,64)
center = vector:new(screen_size.x/2, screen_size.y/2)
pages = 1 -- WHAT IS THIS FOR?!?!?
num_pages = 3

initializing = true


