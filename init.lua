--If you are reading this, then you know some of the ideas that are going to be put into this mod, do not reveal any of it on the forum so
--that it's a surprise. Also, a bit of these ideas are deprecated, old, or are already complete. When I am satisfied with the code then
--it will be put on github. If you want to be the original sloppy setvelocity code it's in the functions backup file.

--to make the track wood seperate from the metal, you'll have to make a texture for each side
--make rails generate with the fire code 000000
--make the train travel around itself, under it's own power
--make the train serialize and deserialize it's data
--have the item id on the 
--eventually have the train number auto decrease and increase with how many vehicles physically exist in the world
--force load chunks with the trucks directions --an entire active train or car unless it stops
--instead of just crafting it, have a rail house that works as a huge crafting table, unmineable, and then have the doors open when the train is done crafting, and make it roll out
--have the train derail if the collision box of the body comes into contact with a node
--make sure that it is placed on a solid piece of track without turns
--make the train be able to go backwards
--make the train animation based on speed
--store last position of cotruck, if the same as last then stop
--make mobs get picked up by minecarts
--create some kind of thing to slow down the wheels based on how far apart they are
--have it scan the tracks when coming out of a turn to check if it is wide enough to turn
--diagnal track
--turn tables
--train lifts
--for smoother trains only change velocity when comparing the self.track with the one in front and it's different, ONLY CHECK NODE WHEN MATH.FLOOR( POS + 0.5) IS DIFFERENT FROM self.pos!

--[[	IMPORTANT!

--save all entities to a table in world file

--save all trains to file on shut down then force load them on startup so trains are attonomous

depending how small the train is, use variable speeds 0.005 0.01 0.015 etc

]]--

dofile(minetest.get_modpath("trains").."/functions.lua")

--these variables will be part of the api eventually

--round to nearest for the position, make sure that the speed you're setting it at matches to this decimal place. 2 = tenths, 3 = hundreths, 
--speed 0.1 = round_to 1, speed 0.25 = round_to 2, etc
--set it to round_to 0 train speed 1.0 for craziness
--in this you can do as many train speeds as you'd like
--the lower the acceleratin the the faster it accelerates, think 0-60







--make sure to center the node when the gear changes



round_to    = 2
train_speed = 0.01


--whole numbers only
truck_distance = 7
--keep this at 0.5 or spooky stuff will happen
prediction_distance = 0.5

		
--do this to allow multiple entities to work as one
train_table = {}

print("---------")
local file=io.open(minetest.get_worldpath().."/train_id.txt","r")
if file ~= nil then
	print("Reading TRAIN ID file")
	train_id = file:read("*all")
	file:close()
	train_id = tonumber(train_id)
else
	--file:close()
	print("Writing TRAIN ID file")
	local file=io.open(minetest.get_worldpath().."/train_id.txt","w")
	file:write("0")
	file:close(file)
	train_id = 0
end
	
print("---------")
print("")
print("")
print("Current train ID: "..train_id)
print("")
print("")
print("---------")

--These both have the ability to load or set table items because one might load before the other.
--########################################################################################################################################################
minetest.register_entity("trains:truck_front",
	{
		hp_max       = 1,
		physical     = true,
		weight       = 5,
		visual = "mesh",
		mesh = "cart.x",
		visual_size = {x=1, y=1},
		textures = {"cart.png"},
		collisionbox = {-0.395,-0.4,-0.395, 0.395,0.5,0.395},
		collide_with_objects = false,
		groups       = {"immortal"},
		is_visible   = true,
		cotruck      = nil,
		--speeds and rounding
		speed = {train_speed_1,train_speed_2,train_speed_3,train_speed_4},--this will be changed to api.train speed when the api is created
		round = {round_to_1,round_to_2,round_to_3,round_to_4},--make the track function see how many speeds there are and work with that
		--serialized variables
		gear         = 0,
		lastpos      = nil,
		stop         = false,
		position     = "front",
		id           = nil,
		direction    = nil,
		--deserialization
		on_activate = function(self,staticdata)
			train_functions.activate(self,staticdata)
			--grouping
			if not train_table[self.id] then
				train_table[self.id] = {}
			end
			train_table[self.id][1] = self.object:get_luaentity()
			if train_table[self.id][2] ~= nil then
				self.cotruck = train_table[self.id][2]
				train_table[self.id][2].cotruck = train_table[self.id][1]
			end
		end,
		--remove entire train
		on_punch = function(self, hitter)
			train_functions.remove_entities(self, hitter)
		end,
		--serialization and grouping
		get_staticdata = function(self)			
			train_functions.serialize(self)
			return minetest.serialize(self.tmp)
		end,		
		--physics stuff
		on_step = function(self)
			force_load_train(self)
			train_on_track(self)
		end
})
minetest.register_entity("trains:truck_rear",
	{
		hp_max       = 1,
		physical     = true,
		weight       = 5,
		visual = "mesh",
		mesh = "cart.x",
		visual_size = {x=1, y=1},
		textures = {"cart.png"},
		collisionbox = {-0.395,-0.4,-0.395, 0.395,0.5,0.395},
		collide_with_objects = false,
		groups       = {"immortal"},
		is_visible   = true,
		cotruck      = nil,
		--speeds and rounding
		speed = {train_speed_1,train_speed_2,train_speed_3,train_speed_4},--this will be changed to api.train speed when the api is created
		round = {round_to_1,round_to_2,round_to_3,round_to_4},--make the track function see how many speeds there are and work with that
		--serialized variables
		gear    = 0,
		lastpos      = nil,
		stop         = false,
		position     = "rear",
		id           = nil,
		direction    = nil,
		--deserialization
		on_activate = function(self,staticdata)
			train_functions.activate(self,staticdata)
			--grouping
			if not train_table[self.id] then
				train_table[self.id] = {}
			end
			train_table[self.id][2] = self.object:get_luaentity()			
			if train_table[self.id][1] ~= nil then
				self.cotruck = train_table[self.id][1]
				train_table[self.id][1].cotruck = train_table[self.id][2]
			end
		end,
		--remove entire train
		on_punch = function(self, hitter)
			train_functions.remove_entities(self, hitter)
		end,
		--serialization and grouping
		get_staticdata = function(self)
			train_functions.serialize(self)
			return minetest.serialize(self.tmp)
		end,
		--physics stuff
		on_step = function(self)
			force_load_train(self)
			train_on_track(self)
		end
})
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
minetest.register_entity("trains:engine",
	{
		hp_max       = 1,
		physical     = true,
		weight       = 5,
		collisionbox = {-0.395,-0.4,-0.395, 0.395,0.5,0.395},
		mesh         = "train.x",
		visual       = "mesh",
		visual_size = {x=2, y=2},
		tiles = {"default_dirt.png","default_dirt.png","default_dirt.png","default_dirt.png","default_dirt.png","default_dirt.png","default_dirt.png","default_dirt.png","default_dirt.png","default_dirt.png",},
		groups       = {"immortal"},
		is_visible   = true,
		--remove entire train
		on_punch = function(self, hitter)
			--reverse positions then directions
			local pos1  = train_table[self.id][1].object:getpos()
			local pos2  = train_table[self.id][2].object:getpos()
			local pos1    = {x=round(pos1.x, round_to),y=round(pos1.y, round_to),z=round(pos1.z, round_to)}
			local pos2    = {x=round(pos2.x, round_to),y=round(pos2.y, round_to),z=round(pos2.z, round_to)}
			train_table[self.id][1].object:setpos(pos2)
			train_table[self.id][2].object:setpos(pos1)
			if train_table[self.id][1].direction == 0 then
				train_table[self.id][1].direction = 2
			elseif train_table[self.id][1].direction == 1 then
				train_table[self.id][1].direction = 3	
			elseif train_table[self.id][1].direction == 2 then
				train_table[self.id][1].direction = 0
			elseif train_table[self.id][1].direction == 3 then
				train_table[self.id][1].direction = 1
			end		
			if train_table[self.id][2].direction == 0 then
				train_table[self.id][2].direction = 2
			elseif train_table[self.id][2].direction == 1 then
				train_table[self.id][2].direction = 3	
			elseif train_table[self.id][2].direction == 2 then
				train_table[self.id][2].direction = 0
			elseif train_table[self.id][2].direction == 3 then
				train_table[self.id][2].direction = 1
			end			
		end,	
		--serialized variables
		id           = nil,
		direction    = nil,
		--deserialization
		on_activate = function(self,staticdata)
			self.object:set_armor_groups({immortal=1})
			--set everything up
			if self.id == nil then
				self.id = train_id
			end
			--grouping
			if not train_table[self.id] then
				train_table[self.id] = {}
			end
			train_table[self.id][3] = self.object:get_luaentity()			
			--deserialization
			if staticdata then
				local data = minetest.deserialize(staticdata)
				if data then
					self.direction = data.direction
					self.id        = data.id
				end
			end
		end,
		--serialization and grouping
		get_staticdata = function(self)
			self.tmp = {
				direction = self.direction,
				id        = self.id,
			}
			return minetest.serialize(self.tmp)
		end,
		on_step = function(self)
			if train_table[self.id] ~= nil then
				if train_table[self.id][1] ~= nil and train_table[self.id][2] ~= nil then					
				--this is pilzadam's mob code, nice work pilzadam, this wouldn't be possible without you!
				--https://github.com/PilzAdam/mobs/blob/master/api.lua#L262
					--position
					local pos1  = train_table[self.id][1].object:getpos()
					local pos2  = train_table[self.id][2].object:getpos()
					print(round(math.abs(distance(pos1.x, pos1.z, pos2.x, pos2.z )),1))
					local cpos  = self.object:getpos()
					local pos   = {x=(pos2.x+pos1.x)/2, y=cpos.y, z=(pos2.z+pos1.z)/2}
					self.object:moveto(pos, false)
					--yaw
					local vec = {x=pos2.x-pos1.x, y=0, z=pos2.z-pos1.z}
					local yaw = math.atan(vec.z/vec.x)+math.pi/2
					if pos2.x < pos1.x then
						yaw = yaw + math.pi
					end
					self.object:setyaw(yaw)
				end
			end
		end,
})
--########################################################################################################################################################

























minetest.register_craftitem("trains:train", {
	description = "Train",
	inventory_image = "heli_inv.png",
	wield_image = "heli_inv.png",
	wield_scale = {x=1, y=1, z=1},
	
	on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.under
		if pointed_thing.type ~= "node" then
			return
		end
		if minetest.get_node(pointed_thing.above).name ~= "air" then
			return
		end
		if minetest.get_node_group(minetest.get_node(pointed_thing.under).name, "track") == 0 then
			return
		end
		if minetest.get_node(pointed_thing.under).param2 == 0 then
			--check if all straight rail
			for i = -(truck_distance/2),(truck_distance/2) do
				if minetest.get_node({x=pos.x,y=pos.y,z=pos.z+i}).name == "trains:track_straight" and minetest.get_node({x=pos.x,y=pos.y,z=pos.z+i}).param2 == 0 then
					--do nothing
				else
					minetest.chat_send_player(placer:get_player_name(), "There needs to be at least "..truck_distance.." straight tracks to place this train")
					return
				end
			end
			train_id = train_id + 1
			--this needs to be fixed to use rounding
			local posib = {0,2}
			local test = posib[math.random(1,2)]
			if test == 0 then
				local front   = minetest.add_entity({x=pos.x,y=pos.y,z=pos.z+(truck_distance/2)}, "trains:truck_front")
				local rear    = minetest.add_entity({x=pos.x,y=pos.y,z=pos.z-(truck_distance/2)}, "trains:truck_rear")
				front:get_luaentity().direction = test
				rear:get_luaentity().direction  = test
			elseif test == 2 then
				local front   = minetest.add_entity({x=pos.x,y=pos.y,z=pos.z-(truck_distance/2)}, "trains:truck_front")
				local rear    = minetest.add_entity({x=pos.x,y=pos.y,z=pos.z+(truck_distance/2)}, "trains:truck_rear")
				front:get_luaentity().direction = test
				rear:get_luaentity().direction  = test
			end
			local engine  = minetest.add_entity({x=pos.x,y=pos.y+1,z=pos.z}, "trains:engine")
			print("Train ID is now "..train_id)
			local file=io.open(minetest.get_worldpath().."/train_id.txt","w")
			file:write(train_id)
			file:close(file)
		end
		if minetest.get_node(pointed_thing.under).param2 == 1 then
			--check if all straight rail
			for i = -(truck_distance/2),(truck_distance/2) do
				if minetest.get_node({x=pos.x+i,y=pos.y,z=pos.z}).name == "trains:track_straight" and minetest.get_node({x=pos.x+i,y=pos.y,z=pos.z}).param2 == 1 then
					--do nothing
				else
					minetest.chat_send_player(placer:get_player_name(), "There needs to be at least "..truck_distance.." straight tracks to place this train")
					return
				end
			end			
			train_id = train_id + 1
			local posib = {1,3}
			local test = posib[math.random(1,2)]
			if test == 1 then
				local front   = minetest.add_entity({x=pos.x+(truck_distance/2),y=pos.y,z=pos.z}, "trains:truck_front")
				local rear    = minetest.add_entity({x=pos.x-(truck_distance/2),y=pos.y,z=pos.z}, "trains:truck_rear")
				front:get_luaentity().direction = test
				rear:get_luaentity().direction = test
			elseif test == 3 then
				local front   = minetest.add_entity({x=pos.x-(truck_distance/2),y=pos.y,z=pos.z}, "trains:truck_front")
				local rear    = minetest.add_entity({x=pos.x+(truck_distance/2),y=pos.y,z=pos.z}, "trains:truck_rear")		
				front:get_luaentity().direction = test
				rear:get_luaentity().direction = test	
			end
			local engine  = minetest.add_entity({x=pos.x,y=pos.y+1,z=pos.z}, "trains:engine")
			print("Train ID is now "..train_id)
			local file=io.open(minetest.get_worldpath().."/train_id.txt","w")
			file:write(train_id)
			file:close(file)
		end
	end,
})



minetest.register_node("trains:track_straight", {
	description = "Railroad Track",
	tiles = {"default_steel_block.png"},
	groups = {cracky=3,track=1},
	--sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	on_construct = function(pos)
		if minetest.get_node(pos).param2 == 2 then
			minetest.set_node(pos, {name="trains:track_straight", param2 = 0})
		elseif minetest.get_node(pos).param2 == 3 then
			minetest.set_node(pos, {name="trains:track_straight", param2 = 1})
		end
	end,
	node_box = {
		type = "fixed",
		fixed = {
		--rails
		{0.4, -0.4, -0.5, 0.5, -0.2, 0.5},
		{-0.5, -0.4, -0.5, -0.4, -0.2, 0.5},
		--sleeper
		{-0.7, -0.5, -0.2, 0.7, -0.4, 0.2},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.2, 0.5},
		},
})


minetest.register_node("trains:track_turn", {
	description = "Railroad Track",
	tiles = {"default_steel_block.png"},
	groups = {cracky=3,track=2},
	--sounds = default.node_sound_stone_defaults(),
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	is_ground_content = true,
	node_box = {
		type = "fixed",
		fixed = {
		{0.4, -0.4, -0.5, 0.5, -0.2, 0.5},
		{-0.5, -0.4, -0.5, 0.5, -0.2, -0.4},
		{-0.5, -0.4, 0.4, -0.4, -0.2, 0.5},
		--sleeper
		{-0.7, -0.5, -0.2, 0.7, -0.4, 0.2},
		},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.2, 0.5},
		},
})
