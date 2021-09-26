Sequinset = {}

function Sequinset.new(num_sets)
  ss = {}
  ss.num_sets = num_sets or 9
  for i=1,ss.num_sets,1 do
    local id = i
    ss[i] = Sequin:new(id)
  end

  setmetatable(ss, Sequinset )
  return ss
end

return Sequinset