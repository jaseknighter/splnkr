Sequin = {}

function Sequin:new(id)
  local sq = {}
  setmetatable(sq, Sequin)
  sq.id = id
  sq.active_outputs = {}
  
  
  function sq.print_outputs(inner_table)
    local tab_to_print
    
    if inner_table then 
      tab_to_print = inner_table 
    elseif sq.output_table then
      tab_to_print = sq.output_table 
    else 
      return
    end

    for k, v in pairs(tab_to_print) do 
      if type(v) == "table" then
        sq.set_outputs(v)
      end
      if k == "table_type" then
        --print("found table_type", k, v,table_type)
      end
      if k == "control_name" then
        --print("found control_name", k, v)
      end
      if k == "value_heirarchy" then
        --print("found value_heirarchy", k, v)
      end
      if k == "value" then
        --print("found value", k, v)
      end
      if k == "output_data" then
        if v then
          --print("found key/value",k,v) 
          --print("found outputs.value",v,v.value) 
          --print("found outputs.value_heirarchy",v.value_heirarchy) 
          -- table.insert(sq.active_outputs,v)
        else
          print("can't find value data in sequin")
        end
      end

    end
  end

  function sq.set_output_table(output_table)
    -- table.insert(sq.active_outputs,output_table)
    sq.active_outputs[1] = output_table
    --print(">>>update sequin",#sq.active_outputs)
    sqao = sq.active_outputs
    
  end

  return sq

end

return Sequin
