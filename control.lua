local fuelNotEnoughWarning = false
local wireWarning = false

script.on_event(defines.events.on_built_entity, function(event)
  if (event.created_entity.name == "train-creator-chest") then
    addTCCToTable(event.created_entity)
    end
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
  if (event.created_entity.name == "train-creator-chest") then
    addTCCToTable(event.created_entity)
  end
end)

script.on_event(defines.events.on_pre_player_mined_item, function(event)
  if event.entity.name == "train-creator-chest" then
	removeCreator(event.entity)
  end
end)

script.on_event(defines.events.on_robot_pre_mined, function(event)
  if event.entity.name == "train-creator-chest" then
	removeCreator(event.entity)
  end
end)

script.on_event(defines.events.on_entity_died, function(event)
  if event.entity.name == "train-creator-chest" then
	removeCreator(event.entity)
  end
end)

		
script.on_init(function()
  onLoad()
end)

script.on_event(defines.events.on_tick, function(event)
	if event.tick%120 == 0 then
		for i, TrainCreator in ipairs(TrainCreators) do
		 updateTrainCreator(TrainCreator)
	    end
	end
end)

script.on_load(function()
  onLoad()
end)

function onLoad()
  if not global.TrainCreators then
    global.TrainCreators = {}
  end
  TrainCreators = global.TrainCreators
end

function addTCCToTable(entity)
  table.insert(TrainCreators, entity)
  game.players[1].print("Connect chest to a station, rail signal and constant combinator with red/green wire. Set the chest to request from signal network for simplest operation. Request locos and wagons in the build order desired in the combinator. Request fuel for automatic fueling. If there is a train near the wired station it will be used as a template for the created train otherwise the train will be assigned the name of the wired station as a destination. If the wired station has a number as the first characters this will be treated as the number of trains to build. Otherwise unlimited trains will be built.")
end

function removeCreator(entity)
	for i, TrainCreator in ipairs(TrainCreators) do
		if notNil(TrainCreator, "position") then
			if TrainCreator.position.x == entity.position.x and TrainCreator.position.y == entity.position.y then
				table.remove(TrainCreators, i)
				break
			end
		end
	end
end

local function checkConnectedWire(wire)
  local combinator = nil
  local stop = nil
  local signal = nil
  for _, ent in pairs(wire) do
    if ent.name == "rail-signal" then
      signal_count = signal_count + 1
      signal = ent
    end
    if ent.type == "train-stop" then
      station_count = station_count + 1
      stop = ent
    end
    if ent.name == "constant-combinator" then
      const_comb_count = const_comb_count + 1
      combinator = ent
    end
  end

  return signal, stop, combinator
end 

function updateTrainCreator(creator_chest)
	--Check if creator is connected via circuit network to a single station and rail signal
	station_count = 0
	signal_count = 0
	const_comb_count = 0
  signal = nil
  stop = nil

  signalRed,   stopRed,   combinatorRed   = checkConnectedWire(creator_chest.circuit_connected_entities.red)
  signalGreen, stopGreen, combinatorGreen = checkConnectedWire(creator_chest.circuit_connected_entities.green)

  if combinatorRed ~= nil and combinatorGreen ~= nil then
    if not wireWarning then
       game.print("You can only hook up a red or green wire not both. Please disconnect a color.")
       wireWarning = true
     end
     return false
  elseif combinatorRed ~= nil then
    combinator = combinatorRed
  elseif combinatorGreen ~= nil then
    combinator = combinatorGreen
  end

  if signalRed ~= nil then
    signal = signalRed
  elseif signalGreen ~= nil then
    signal = signalGreen
  end

  if stopRed ~= nil then
    stop = stopRed
  elseif stopGreen ~= nil then
    stop = stopGreen
  end

  -- Got this far so both red and green wire not connected, resetting warning message boolean
  wireWarning = false

	if signal_count == 1 and station_count == 1 and const_comb_count == 1 then
		--if the train signal is green, try and build the train

		if signal.signal_state == defines.signal_state.open then
			--check if this station has trains to build
			num, station_name = trains_to_build(stop)
			if num ~= "0" then
				build_train(creator_chest, combinator, stop, signal, num, station_name)
			end

		end
	end
end


	
		
function build_train(creator_chest, combinator, stop, signal, trains_to_build, station_name)
	build_orientation = signal.direction
	signal_x = signal.position.x
	signal_y = signal.position.y
	if build_orientation == 0 then -- signal for southbound travel
		build_location_x = signal_x + 1.5
		build_location_y = signal_y + 6.5
	elseif build_orientation == 2 then
		build_location_x = signal_x - 6.5
		build_location_y = signal_y + 1.5
	elseif build_orientation == 4 then -- signal for northbound travel
		build_location_x = signal_x - 1.5
		build_location_y = signal_y - 6.5
	elseif build_orientation == 6 then
		build_location_x = signal_x + 6.5
		build_location_y = signal_y - 1.5
	else
		game.players[1].print("Sorry, Train Creator not supported on Diagonal rails")
		return false
	end

	if build_orientation == 0 or build_orientation == 6 then
		sign = 1
	else
		sign = -1
	end

	if build_orientation == 0 or build_orientation == 4 then
		xmult = 0
		ymult = 1
	else
		xmult = 1
		ymult = 0
	end
	
	--work out how many locos and wagons we need to build - this is carried on the combinator circuit
	
	locos = 0
  locoName = ""
	cargo_wagons = 0
	fluid_wagons = 0
	artillery_wagons = 0
	fuel = 0
  trainToBuild = {}

  --TODO:make this into a function
	if combinator.get_circuit_network(defines.wire_type.green) ~= nil then
		for _, signal in ipairs(combinator.get_circuit_network(defines.wire_type.green).signals) do
			name =  signal.signal.name
			if game.entity_prototypes[name] ~= nil then
				if game.entity_prototypes[name].type == "locomotive" then
					locos = locos + signal.count
          trainToBuild[name] = signal.count
				elseif game.entity_prototypes[name].type == "cargo-wagon" then
					cargo_wagons = cargo_wagons + signal.count
          trainToBuild[name] = signal.count
				elseif game.entity_prototypes[name].type == "fluid-wagon" then
					fluid_wagons = fluid_wagons + signal.count
          trainToBuild[name] = signal.count
				elseif game.entity_prototypes[name].type == "artillery_wagon" then
					artillery_wagons = artillery_wagons + signal.count
          trainToBuild[name] = signal.count
				end
			elseif game.item_prototypes[name]~= nil then
				if game.item_prototypes[name].fuel_category == "chemical" then
						fuel = signal.count
						fuel_name = name
						fuel_stack = game.item_prototypes[name].stack_size
				end
			end
		end
	end
	if combinator.get_circuit_network(defines.wire_type.red) ~= nil then
		for _, signal in ipairs(combinator.get_circuit_network(defines.wire_type.red).signals) do
			name =  signal.signal.name
			if game.entity_prototypes[name] ~= nil then
				if game.entity_prototypes[name].type == "locomotive" then
					locos = locos + signal.count
          trainToBuild[name] = signal.count
				elseif game.entity_prototypes[name].type == "cargo-wagon" then
					cargo_wagons = cargo_wagons + signal.count
          trainToBuild[name] = signal.count
				elseif game.entity_prototypes[name].type == "fluid-wagon" then
					fluid_wagons = fluid_wagons + signal.count
          trainToBuild[name] = signal.count
				elseif game.entity_prototypes[name].type == "artillery_wagon" then
					artillery_wagons = artillery_wagons + signal.count
          trainToBuild[name] = signal.count
				end
			elseif game.item_prototypes[name]~= nil then
				if game.item_prototypes[name].fuel_category == "chemical" then
						fuel = signal.count
						fuel_name = name
						fuel_stack = game.item_prototypes[name].stack_size
				end
			end
		end
	end
	-- make sure at least 1 loco has been requested
	
	if locos == 0 then
		return nil
	end

  if fuel < locos and fuel_name ~= nil then
    if not fuelNotEnoughWarning then
      game.print("There is not enough fuel to fuel all trains")
      fuelNotEnoughWarning = true
    end
    return false
  else
    fuelNotEnoughWarning = false
  end

	
	-- and then make sure we have enough

	
	--check if we can build the required entities
	for i = 0, locos+ cargo_wagons + fluid_wagons + artillery_wagons-1, 1 do
		pos = {build_location_x + 7 * i * sign * xmult, build_location_y + 7 * i * sign * ymult}
		if game.surfaces[1].can_place_entity{name="locomotive", position = pos} == false then
			return false
		end
	end
	--Check there is enough

	chest_inv = creator_chest.get_inventory(defines.inventory.chest)

  for name, count in pairs(trainToBuild) do
    if not (chest_inv.get_item_count(name) >= count) then
      return false
    end
  end
	
	if fuel_name ~= nil then
		if not (chest_inv.get_item_count(fuel_name) >= fuel) then
			return false
		end
	else
		fuel_stack=0
	end
	
	-- finally - build it
	veh = 0
	cum_locos = 0
	fuel_per_loco = math.min(fuel/locos, fuel_stack*3)
	for i = 1, 18,1 do
		number = combinator.get_control_behavior().get_signal(i).count
		stack = combinator.get_control_behavior().get_signal(i).signal
		build = nil
    buildType = nil
    types = nil
		if stack ~= nil then
      if game.entity_prototypes[stack.name] ~= nil then
        types = game.entity_prototypes[stack.name].type
      end 

			if types == "locomotive" then
				locos = number
				build = stack.name
				if cum_locos > 0 then
					build_orientation = (build_orientation + 4)%8
				end
				cum_locos = locos + cum_locos
				build_num = locos
			elseif types == "cargo-wagon" then
				wagons = number
				build = stack.name
				build_num = wagons
			elseif types == "fluid-wagon" then
				wagons = number
				build = stack.name
				build_num = wagons
			elseif types == "artillery-wagon" then
				wagons = number
				build = stack.name
				build_num = wagons
			end
		end

		if (build ~= nil) and (build_num > 0) then
			for j = 1,build_num,1 do
				pos = {build_location_x + 7 * veh * sign * xmult, build_location_y + 7 * veh * sign * ymult}
				created=game.surfaces[1].create_entity{name=build, position = pos, direction = build_orientation, force="player"}
				veh = veh + 1
				creator_chest.get_inventory(defines.inventory.chest).remove{name = build, count=1}
				if not created then
					game.players[1].print("Something went wrong - is there curved track near the end of train?")
					return false
				end
				if types == "locomotive" then
					last_loco=created
					if fuel_per_loco > 0 then
						created.get_fuel_inventory().insert{name=fuel_name, count=fuel_per_loco}
						creator_chest.get_inventory(defines.inventory.chest).remove{name = fuel_name, count=fuel_per_loco}	
					end
				end
			end
		end
	end
	
	schedule = get_station_schedule(stop)
	if schedule ~= nil then
		last_loco.train.schedule = schedule
	else
		records= {{station=station_name, wait_conditions= {{compare_type = "and", type="full"}}}}
		last_loco.train.schedule = {current=1, records = records }
	end
	last_loco.train.manual_mode=false
	if trains_to_build ~= nil then
		stop.backer_name = (tonumber(trains_to_build) - 1)..station_name
	end
end	

function get_station_schedule(stop)
	--checks to see if there is a train at the station in the circuit and gets its schedule if southbound
	direction = stop.direction
	x = stop.position.x
	y = stop.position.y
	if (direction == 0) or (direction==2) then
		x = x - 2
		y = y + 2
	else
		x = x + 2
		y = y + 2
	end
	area = {{x-1,y-1}, {x+1, y+1}}
	locos = game.surfaces[1].find_entities_filtered{area=area, name="locomotive"}
	if locos[1]~= nil then
	
		return locos[1].train.schedule
	end
	return nil
end
	
		

function trains_to_build(train_stop)
	num = string.match(train_stop.backer_name, "^(%d+).+")
	remainder = string.match(train_stop.backer_name, "^%d*(.+)")
	return num, remainder
	
end

function notNil(class, var)
	value = false
	pcall (function()
		if class[var] then
			value = true
		end
	end)
	return value
end

