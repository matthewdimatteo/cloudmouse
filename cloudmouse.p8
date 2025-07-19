pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- cloudmouse
-- by matthew dimatteo

-- tab 0: game loop, hud
-- tab 1: camera, map
-- tab 2: player
-- tab 3: animation
-- tab 4: collection
-- tab 5: containers and shots
-- tab 6: pickups, enemies

-- animate the gold clouds

function _init()

	-- camera position
	camx = 0
	camy = 48*8
	
	-- toggle hud
	show_hud=true

	-- physics forces
	fric = 0.85 -- friction
	grav = 0.18 -- gravity
	
	-- game variables
	gameover = false 
	lives  = 3
	health = 100
	score  = 0

	-- player starting position
	startx = 7.5*8
	starty = 62*8

	-- variables for plyr
	make_plyr() -- tab 3
	
	-- variables for clouds
	num_clouds=0 -- cloud count
	range = num_clouds -- to draw
	limit = 1 -- max to draw
	capacity=limit*10 -- max ammo
	maxlimit=7 -- max limit

	-- object tables
	containers={} -- cloud containers
	make_container() -- first container

	pickups={} -- collectible clouds
	clouds={} -- collected clouds
	shots ={} -- cloud projectiles
	enemies={} -- enemy objects
	lostclouds=0
	
	-- map bg tile coords
	bgx = 127
	bgy = 0
	
	-- width of map portion
	-- allocated to bg tiles
	bgw = 8 -- in pixels
	
	-- night/day cycle
	sky = 12 -- sky color
	m = 0 -- map timer
	dayspd = 2 -- speed of day
	
	-- cloud animation timer
	animtime = 0
	
	-- elapsed game time (depr.)
	t = 0 -- game timer
	hrs  = 0
	mins = 0
	secs = 0
	
	-- hitbox coords
	rx1=0	ry1=0	rx2=0	ry2=0
	
	-- debug
	test =""
	test2=""
	test3=""
end -- /function _init()

function _update()
	-- carry up to 10 times as
	-- many clouds as can trail
	-- behind you
	capacity = limit*10
	
	-- manage camera/map/screen
	set_cam() -- tab 1
	toggle_map() -- tab 1
	
	-- move and animate player
	move_plyr() --  tab 2
	animate(plyr,plyr.first,plyr.last,plyr.rate)
	
	-- animate and move
	-- collectible clouds
	anim_clouds() -- tab 3

	-- allow plyr to collect
	-- clouds and gold clouds
	collect(plyr,0) -- tab 4
	collect(plyr,1) -- tab 4
	
	-- determine number of clouds
	-- to move (prevent collision
	-- between enemies and
	-- reserve clouds not on scrn
	if num_clouds > limit then
		range = limit
		for i=1,range do
			cloud=clouds[i]
			move_cloud(cloud)
		end -- /for
	else
		-- move all collected clouds
		foreach(clouds,move_cloud)
	end -- /if num_clouds > limit
	
	-- shoot clouds
	shoot() -- tab 6
	foreach(shots,move_shot) -- tab 6	

	-- make pickups,enemies (tab 7)
	spawn("pickup",60)
	spawn("enemy",60)
	foreach(pickups,move_pickup)
	foreach(enemies,move_enemy)
end -- /function _update()

function _draw()
	cls() -- refresh screen
	
	-- draw sky background
	draw_bg() -- tab 1
	
	-- draw foreground
	map() -- draw map
	
	-- draw player
	spr(plyr.n,plyr.x,plyr.y,1,1,plyr.flip)
	
	-- draw cloud containers
	foreach(containers,draw_container)

	-- determine number of clouds
	-- to draw
	if num_clouds > limit then
		range = limit
		print("+"..num_clouds-limit,plyr.x,plyr.y-8,0)
		for i=1,range do
			cloud=clouds[i]
			draw_cloud(cloud)
		end -- /for
	else
		-- draw all collected clouds
		foreach(clouds,draw_cloud)
	end -- /if num_clouds > limit
	
	-- draw dropped clouds
	foreach(shots,draw_shot)

	-- draw cloud pickups
	foreach(pickups,draw_pickup)
	
	-- draw enemies
	foreach(enemies,draw_enemy)
	
	-- print debug data
	test = ""
	print(test,camx+2,camy+20,0)
	test2= ""
	print(test2,camx+2,camy+28,0)
	
	-- draw hud
	if show_hud == true then
		minimap()
		draw_health()
		draw_score()
		draw_clock()
	end -- /if show_hud
	
end -- /function _draw()

-- draw framed hud elements
-- given x,y, width,height,
-- and fill and stroke colors
function draw_hudbox(text,x,y,w,h,f,s)

	-- draw border box
	rect(x-2,y-2,x+w+1,y+h+1,s)
	
	-- draw filled box
	rectfill(x-1,y-1,x+w,y+h,f)
	
	-- print text
	print(text,x,y,0)
	
end -- /function draw_hudbox

-- healthbar
function draw_health()
	
	-- draw life meter
	for l=1,lives do
		local n = 80
		local x = camx+(l*11)-9
		local y = camy+2
		spr(n,x,y)
		rect(x-1,y-1,x+8,y+7,5)
	end -- /for l

	-- track sky color (for health
	-- bar background)
	if bgy <= 6 then
		sky = 12 -- light blue
	elseif bgy == 7 then
		sky = 9  -- orange
	elseif bgy == 8 then
		sky = 14 -- pink
	elseif bgy == 9 then
		sky = 2  -- dark purple
	elseif bgy >= 10 
	and bgy <= 13 then
		sky = 1  -- dark blue
	elseif bgy == 14 then
		sky = 13 -- blue-gray
	elseif bgy == 15 then
		sky = 6  -- light gray
	end -- /if/elseif bgy
	
	-- determine healthbar position
	healthx=camx+3
	healthy=camy+13
	
	-- determine healthbar width
	healthw=flr(health/100*27)
	
	-- determine healthbar color
	if health >= 70 then
		healthc=11 -- green
	elseif health >= 50 then
		healthc=10 -- yellow
	elseif health >= 40 then
		if sky != 9 then
			healthc=9 -- orange
		else
			healthc=15 -- tan
		end -- /if sky != 9
	elseif health >= 20 then
		healthc=8 -- red
	else
		healthc=2 -- dark purple
	end -- /if/elseif health
	
	-- draw healthbar
	draw_hudbox("",healthx,healthy,healthw,3,healthc,healthc)
	
	-- draw frame representing
	-- maximum health
	rect(healthx-2,healthy-2,camx+32,healthy+5,5)

end -- /function draw_health()

-- score box
function draw_score()

	-- determine score box width
	-- and x position
	if score < 10 then
		scorex=camx+106
		scorew=19
	elseif score < 100 then
		scorex=camx+102
		scorew=23
	elseif score < 1000 then
		scorex=camx+98
		scorew=27
	elseif score < 10000 then
		scorex=camx+94
		scorew=31
	else
		scorex=camx+90
		scorew=35
	end -- /if/elseif score
	
	-- determine score y position
	scorey = camy+3
	
	-- draw score
	draw_hudbox("pts:"..score,scorex,scorey,scorew,5,7,0)

end -- /function format_score()

-- in-game clock
function draw_clock()
	
	-- set in-game time (map bgy
	-- to hour of in-game day)
	dayhour = 8+bgy*1.5
	if dayhour > 24 then
		dayhour -= 24
	end -- /if dayhour > 24
	
	-- format minutes as remainder
	-- of hours, multiplied by 60
	daymins = dayhour%flr(dayhour)*60
	
	-- format hours digits
	if flr(dayhour) > 12 then
		clockhrs = flr(dayhour)-12
	elseif flr(dayhour) == 0 then
		clockhrs = 12
	else
		clockhrs = flr(dayhour)
	end -- /if flr(dayhour) > 12
	
	-- format am/pm
	if flr(dayhour) < 12 then
		clockampm = "am"
	else
		clockampm = "pm"
	end -- /if flr(dayhour) < 12
	
	-- format minutes digits
	if daymins < 10 then
		clockmins = "0"..daymins
	else
		clockmins = daymins
	end -- /if daymins < 10
	
	-- set clock string
	clock = clockhrs..":"..clockmins.." "..clockampm
	
	-- determine where to position
	-- clock based on string width
	if clockhrs < 10 then
		clockx=camx+98
		clockw=27
	else
		clockx=camx+94
		clockw=31
	end -- /if clockhrs < 10
	
	-- clock y position
	clocky=camy+120
	
	-- draw clock
	draw_hudbox(clock,clockx,clocky,clockw,5,7,0)
end -- /function
-->8
-- camera and map functions

-- set camera
function set_cam()

	-- center camera on player
	camx=plyr.x-64+plyr.w/2
	camy=plyr.y-64+plyr.h/2
	
	-- constrain camera to screen
	if camx < 0 then
		camx = 0
	end -- /if camx < 0
	
	if camx > 1024-128-bgw then
		camx = 1024-128-bgw
	end -- /if camx > 1024-256
	
	if camy < 0 then
		camy = 0
	end -- /if camy < 0
	
	if camy > 512-128 then
		camy = 512-128
	end -- /if camy > 512-128

	-- plug in the camera position
	camera(camx,camy)
	
end -- /function set_cam()

-- draw sky background
function draw_bg()
	
	-- increment map timer
	m+=dayspd
	
	-- set sky color based on time
	if m%200==0 then
		bgy += 1
		m=0
	end -- /if m%200==0
	
	-- loop back to beginning
	if bgy > 15  then
		bgy = 0
	end -- /if bgy > 15
	
	-- sample 1 sky tile from map
	-- to repeat across all tiles
	-- on current screen
	for x=0,15 do
	 for y=0,15 do
			map(bgx,bgy,camx+x*8,camy+y*8,1,1)
		end -- /for y
	end -- /for x
	
end -- /function draw_bg()

-- draw minimap
function minimap()

	-- determine which column
	-- and row on the map the
	-- player is in
	col = flr(plyr.x/128)
	row = flr(plyr.y/128)

	-- x,y iterators
	local x=0
	local y=0
	
	-- minimap tile sprite number
	local n=52
	
	-- draw grid of rooms
	for x=0,7 do
	 for y=0,3 do
			
			-- yellow tile to indicate
			-- current room on minimap
			if x==col and y==row
			then
				n=53
			else
				n=52
			end -- /if
			
			-- draw tile
			spr(n,2+camx+x*3,115+camy+y*3)
			
		end -- /for x
	end -- /for y

end -- /function minimap()

-- toggle minimap
function toggle_map()
	if btnp(🅾️) then
		if show_hud == true then
			show_hud = false
		else
			show_hud = true
		end -- /if/else
	end -- /if btnp()
end -- /function toggle_map()

-- place plyr at start of lvl
function respawn()
	startx = camx+64-plyr.w/2
	starty = camy+120-plyr.h
	plyr.x = startx
	plyr.y = starty
end -- /function respawn()

-- map collision function
function mcollide(obj,dir,flag)
	
	-- determine location of map
	-- tile relative to player
	-- (depending on direction)
	if dir == ⬅️ then
		x1 = obj.x-1
		y1 = obj.y
		x2 = x1
		y2 = y1+obj.h-1
	elseif dir == ➡️ then
		x1 = obj.x+obj.w
		y1 = obj.y
		x2 = x1
		y2 = y1+obj.h-1
	elseif dir == ⬆️ then
		x1 = obj.x+2
		y1 = obj.y-1
		x2 = x1+obj.w-3
		y2 = y1
	elseif dir == ⬇️ then
		x1 = obj.x+3
		y1 = obj.y+obj.h
		x2 = obj.x+obj.w-4
		y2 = y1
	end -- /if dir
	
	-- map to hitbox coords
	rx1=x1	rx2=x2	ry1=y1	ry2=y2
	
	-- find sprite number of
	-- map tile adjacent to plyr
	-- (check 4 points)
	n1=mget(flr(x1/8),flr(y1/8))
	n2=mget(flr(x2/8),flr(y1/8))
	n3=mget(flr(x1/8),flr(y2/8))
	n4=mget(flr(x2/8),flr(y2/8))
	
	-- check for flag on that
	-- sprite (at all 4 points)
	f1=fget(n1,flag)
	f2=fget(n2,flag)
	f3=fget(n3,flag)
	f4=fget(n4,flag)
	
	-- if at least 1 of the 4
	-- points is a sprite with
	-- the flag, then collision
	-- is true; return true/false
	if f1 or f2 or f3 or f4 then
		return true
	else
		return false
	end -- /if f1 or f2 or f3 or f4

end -- /mcollide()
-->8
-- player functions

-- make player
function make_plyr()

	-- table
	plyr = {} 
	
	plyr.first= 64
	plyr.last = 64
	plyr.rate = 18
	plyr.xspd=0.5 -- x speed
	plyr.yspd=2 -- y speed

	-- default sprite
	plyr.n = plyr.first
	
	-- plug in starting coords
	plyr.x = startx
	plyr.y = starty

	-- width and height (8px)
	plyr.w = 8
	plyr.h = 8
	
	-- active speed
	plyr.dx=0 -- change in x
	plyr.dy=0 -- change in y
	
	-- player state
	plyr.dir = ➡️ -- direction
	plyr.flip = false
	plyr.t = 0 -- animation timer
	
end -- /function make_plyr()

-- move player function
-- call in _update()
function move_plyr()
	
	-- apply friction so the plyr
	-- eventually stops moving
	plyr.dx *= fric
	
	-- apply gravity so the plyr
	-- does not float endlessly
	plyr.dy += grav
	
	-- move left
	if btn(⬅️) then
		-- subtract from change in x
		plyr.dx -= plyr.xspd
		
		-- track player's direction
		plyr.dir = ⬅️
		
		-- flip the sprite
		plyr.flip = true
	end -- /if btn(⬅️)
	
	-- move right
	if btn(➡️) then
		-- add to change in x
		plyr.dx += plyr.xspd

		-- track player's direction
		plyr.dir = ➡️
		
		-- un-flip sprite
		plyr.flip = false
	end -- /if btn(⬅️)
	
	-- up
	if btn(⬆️) then
		plyr.dy = -plyr.yspd
	end -- /if btnp(⬆️/❎)
	
	-- update x,y by the calculated
	-- change (delta x, delta y)
	plyr.x += plyr.dx
	plyr.y += plyr.dy

	-- constrain to map bounds
	if plyr.x < 0 then 
		plyr.x = 0 
	end -- /if plyr.x < 0

	if plyr.x > 1024-bgw-plyr.w then 
		plyr.x = 1024-bgw-plyr.w
	end -- /if plyr.x > 1024

	if plyr.y < 0 then 
		plyr.y = 0
	end -- /if plyr.y < 0

	if plyr.y > 512-plyr.h then 
		plyr.y = 512-plyr.h
	end -- /if plyr.y > 512
	
end -- /function move_plyr()
-->8
-- animation
function animate(obj,first,last,rate)

	-- start animation timer
	obj.t += 1
	
	if obj.t >= rate then
		
		-- go to next sprite
		obj.n += 1
		
		-- loop animation
		if obj.n > last then
			obj.n = first
		end
		
		-- reset timer
		obj.t = 0
		
	end -- /if
end -- /function animate()

-- animate all map tile clouds
function anim_clouds()

	-- speed of animation
	animrate = 20
	
	-- start animation timer
	animtime += 1
	
	if animtime > animrate then
	
		local a=flr(camx/8)
		local b=flr(camy/8)
		
		-- loop through all tiles
		-- on screen and swap the
		-- tiles flagged for animation
		for x=a,a+15 do
			for y=b,b+15 do
			
				-- determine which type
				-- of cloud it is
				local n = mget(x,y)
				local f0 = fget(n,0) -- reg
				local f1 = fget(n,1) -- gold
				
				-- if it's a pickup
				if f0 or f1 then
				
					-- regular clouds
					if f0 then
						if n==3 or n==4 then
							first = 3
							last  = 4
						end -- /if/elseif n
					-- gold cloud containers
					elseif f1 then 
						if n >= 19 and n <=21 then
							first = 19
							last  = 21
						end -- if n
					end -- /if/else if f0/f1
				
					-- animate sprite
					if n >= last then
						mset(x,y,first)
					else
						mset(x,y,n+1)
					end -- /if n > last
					
				end -- /if f0 or f1
				
			end -- /for y
		end -- /for x
	
		-- reset animation timer
		animtime = 0
		
	end -- /if animtime
		
end -- /function
-->8
-- collection
function collect(obj,f)

	-- obj is the object that
	-- is doing the collecting
	-- so collect(plyr,3) allows
	-- the plyr to collect clouds
	-- by colliding with them

	-- f is the flag number
	-- 3 = collectible clouds
	-- 4 = gold clouds
	
	-- determine player's x,y
	-- location as a tile value
	local x1 = flr(obj.x/8)
	local y1 = flr(obj.y/8)
	local x2 = flr((obj.x+obj.w)/8)
	local y2 = flr((obj.y+obj.h)/8)
		
	-- get sprite number of tile
	-- at 4 points
	n1 = mget(x1,y1)
	n2 = mget(x2,y1)
	n3 = mget(x1,y2)
	n4 = mget(x2,y2)
	
	-- check for flag on sprite
	-- at 4 points
	f1 = fget(n1,f)
	f2 = fget(n2,f)
	f3 = fget(n3,f)
	f4 = fget(n4,f)
	
	-- x,y, sprite number of tile
	-- that triggered collision
	local x = 0
	local y = 0
	local n = 0
	
	-- determine which point
	-- triggered collision
	if f1 then
		n=n1	x=x1	y=y1
	elseif f2 then
		n=n2	x=x2	y=y1
	elseif f3 then
		n=n3	x=x1	y=y2
	elseif f4 then
		n=n4	x=x2	y=y2
	end -- /if
	
	-- if there is collision
	-- with any collectible cloud
	if f1 or f2 or f3 or f4 then
		
		-- swap in blank tile
		mset(x,y,0)
		
		-- collect objs based on
		-- flag number passed in
		if f==0 then 
			get_cloud()
		elseif f==1 then 
			get_container()
		end -- /if f
		
	end -- /if f1/2/f3/f4

end -- /function collect()
function get_cloud()
	
	if num_clouds < capacity then
	
		-- add to total
		num_clouds += 1
	
		-- create new cloud object
		-- for collection
		local cloud = {}
	
		-- index number
		cloud.i = num_clouds
		cloud.n = 3
		cloud.x = plyr.x
		cloud.y = plyr.y
		cloud.w = 8
		cloud.h = 8
		cloud.dx = plyr.dx/4
		cloud.dy = 0
	
		-- add to collection
		add(clouds,cloud)
		score += 1
		sfx(0) -- collection sound
	
	-- score pts as compensation
	-- for clouds collided with
	-- beyond your capacity
	else
		score += 5
		sfx(3)
	end
end -- /function get_cloud()

-- collect gold clouds to
-- increase the number of
-- clouds that can follow you
function get_container()
	if limit < maxlimit then
		limit += 1 -- increase limit
		score += 30
		sfx(7)
		make_container()
	else
		score += 100 -- compensation
		sfx(3)
	end -- /if limit < maxlimit
end -- /function get_container()

function make_container()
	local container = {}
	container.i = limit 
	container.n = 6
	container.x = plyr.x
	container.y = plyr.y
	container.w = 8
	container.h = 8
	container.dx = plyr.dx/4
	container.dy = 0

	-- add to collection
	add(containers,container)
end -- /function make_container()
-->8
-- containers and shots

-- draw either cloud or container
-- try this out
function draw_obj(obj)
	-- offset cloud x,y based on
	-- number of clouds
	local offsetx=obj.i*8
	local offsety=obj.i*8
	
	-- apply player's x momentum
	-- to cloud offset
	obj *= -plyr.dx/4
	
	-- apply offset to x,y position
	obj.x = plyr.x+offsetx
	obj.y = plyr.y+offsety
	
	-- draw container sprite
	spr(obj.n,obj.x,obj.y)
end -- /function draw_obj()

-- draw cloud container
function draw_container(container)
	-- offset cloud x,y based on
	-- number of clouds
	local offsetx=container.i*8
	local offsety=container.i*8
	
	-- apply player's x momentum
	-- to cloud offset
	offsetx *= -plyr.dx/4
	
	-- apply offset to x,y position
	container.x = plyr.x+offsetx
	container.y = plyr.y+offsety
	
	-- draw container sprite
	spr(container.n,container.x,container.y)
end -- /function draw_container()

-- draw cloud object
function draw_cloud(cloud)

	-- offset cloud x,y based on
	-- number of clouds
	local offsetx=cloud.i*8
	local offsety=cloud.i*8
	
	-- apply player's x momentum
	-- to cloud offset
	offsetx *= -plyr.dx/4
	
	-- apply offset to x,y position
	cloud.x = plyr.x+offsetx
	cloud.y = plyr.y+offsety
	
	-- draw cloud sprite
	spr(cloud.n,cloud.x,cloud.y)	
end -- /function draw_cloud()

function move_cloud(cloud)
	-- collect other clouds by
	-- colliding your collected
	-- clouds into them
	collect(cloud,1)
	collect(cloud,2)
	
	-- detect collision w/pickups
	for pickup in all(pickups) do
		if collide(cloud,pickup) then
			get_cloud()
			del(pickups,pickup)
			sfx(0)
		end -- /if collide w/shot
	end -- /for pickup

	-- detect collision w/enemies
	for enemy in all(enemies) do
		if collide(cloud,enemy) then
			deli(clouds,num_clouds)
			num_clouds -= 1
			del(enemies,enemy)
			score += 10
			sfx(6)
		end -- /if collide w/cloud
	end -- /for enemy
end -- /function move_cloud

-- shoot clouds
-- press ❎ to drop a cloud
function shoot(cloud)
	if btnp(❎) then
		if num_clouds > 0 then
			make_shot(plyr.x,plyr.y,plyr.dx)
			num_clouds -= 1
			deli(clouds,num_clouds+1)
			sfx(2)
		else
			sfx(1) -- empty sound
		end -- /if num_clouds > 0
		
	end -- /if btnp(❎)
end -- /function shoot()

-- make shot (drop a cloud)
function make_shot(x,y,dx)
	local shot = {}
	
	-- start at position of last
	-- cloud following player
	local i=min(limit,num_clouds)
	shot.x=clouds[i].x
	shot.y=y+plyr.h+(i*8)
	
	-- width and height
	shot.w=8
	shot.h=8
	
	-- active speed
	shot.dx=dx -- from constructor
	shot.dy=0 -- start at 0
	
	-- add to table of all shots
	add(shots,shot)
end -- /function make_shot

-- move shot
function move_shot(shot)

	-- apply physics to shot
	shot.dx *= fric
	shot.dy += grav
	
	-- update position of shot
	shot.x += shot.dx
	shot.y += shot.dy
	
	-- delete shots that go
	-- off screen
	if shot.y > camy+128 then
		del(shots,shot)
	end -- /if y > camy

	-- detect collision w/enemies
	for enemy in all(enemies) do
		if collide(shot,enemy) then
			del(shots,shot)
			del(enemies,enemy)
			score += 25
			sfx(5)
		end -- /if collide w/shot
	end -- /for
	
end -- /function move_shot

-- draw shot
function draw_shot(shot)
	spr(3,shot.x,shot.y)
end -- /function draw_shot
-->8
-- pickups and enemies

-- spawn any obj with type,
-- spawn rate, and direction
function spawn(type,rate,dir)

	-- get params from constructor
	local type = type
	local rate = rate 
	local dir = dir 

	-- random spawn timer
	local rnd_gen = flr(rnd(rate))
	if rnd_gen == 1 then
	
		local x = 0
		local y = 0
		local dx= 0
		local dy= 0

		-- randomize direction if 
		-- not passed into function
		if not dir then
			dir = flr(rnd(4))
		end -- /if dir

		if dir == 0 then 
			-- left
			dx = -1
			dy = 0
			x = camx+132
		elseif dir == 1 then 
			-- right
			dx = 1
			dy = 0
			x = camx-4
		elseif dir == 2 then 
			-- up
			dx = 0
			dy = -1
			y = camy+132
		elseif dir == 3 then 
			-- down
			dx = 0
			dy = 1
			y = camy-4
		end -- /if/elseif rnd_dir

		-- if moving l/r, start
		-- at random y position
		if dx != 0 then 
			-- randomize y between 8-120
			local ymin = camy+8
			local ymed = camy+flr(rnd(112))
			local ymax = camy+112
			y = mid(ymin,ymed,ymax)
		end -- /if dx != 0

		-- of moving up/down,
		-- start and random x pos
		if dy != 0 then 
			-- randomize x between 8-120
			local xmin = camx+8
			local xmed = camx+flr(rnd(112))
			local xmax = camx+112
			x = mid(xmin,xmed,xmax)
		end -- /if dy != 0

		-- spawn obj at x,y
		-- with speed dx,dy
		if type == "pickup" then
			make_pickup(x,y,dx,dy)
		elseif type == "enemy" then 
			make_enemy(x,y,dx,dy)
		end -- /if/elseif type
		
	end -- /if rnd_gen == 1
end -- /function spawn(obj)

-- make a single pickup object
function make_pickup(x,y,dx,dy)

	-- new object
	local pickup = {}

	-- sprite number, size
	pickup.n = 3
	pickup.w = 8
	pickup.h = 8

	-- get position and speed
	-- from constructor
	pickup.x = x
	pickup.y = y
	pickup.dx= dx 
	pickup.dy= dy 
	
	-- add obj to table
	add(pickups,pickup)
end -- /function make_pickup()

function move_pickup(pickup)

	pickup.x += pickup.dx
	pickup.y += pickup.dy

	-- delete if off screen
	if pickup.x < 0
	or pickup.x > 1024-bgw
	or pickup.y < 0
	or pickup.y > 512 
	then
		del(pickups,pickup)
	end
 
	-- detect collision w/plyr
	-- loop through all pickups
	for pickup in all(pickups) do
		if collide(pickup,plyr) then
		
			-- remove the pickup
			del(pickups,pickup)

			-- collect cloud
			get_cloud()
		end -- /if collide
	end -- /for
end -- /function move_pickup()

-- draw pickup
function draw_pickup(pickup)
  spr(pickup.n,pickup.x,pickup.y)
end -- /draw_pickup()

-- enemy functions

-- make a single enemy object
function make_enemy(x,y,dx,dy)

	-- new object
	local enemy = {}

	-- sprite number, size
	enemy.n = 96
	enemy.w = 8
	enemy.h = 8

	-- get position and speed
	-- from constructor
	enemy.x = x
	enemy.y = y
	enemy.dx= dx 
	enemy.dy= dy 
	
	-- add obj to table
	add(enemies,enemy)
end -- /make_enemy()

function move_enemy(enemy)

	enemy.x += enemy.dx
	enemy.y += enemy.dy
  
	-- delete if off screen
	if enemy.x < 0
	or enemy.x > 1024-bgw
	or enemy.y < 0
	or enemy.y > 512 
	then
		del(enemies,enemy)
	end
 
	-- detect collision w/plyr
	-- loop through all enemies
	for enemy in all(enemies) do
		if collide(enemy,plyr) then
		
			-- remove the enemy
			del(enemies,enemy)
			
			-- lose your clouds
			if num_clouds > 0 then 
				lostclouds = num_clouds
				scatter(lostclouds)
				num_clouds = 0
				clouds={}
				lostclouds = 0 -- reset
			end -- /if num_clouds > 0
			
			-- play a loss sound
			sfx(8)
			
			-- take damange
			health -= 10

			-- lose a life and respawn
			if health <= 0 then
				lives -= 1
				health = 100
				make_plyr() -- respawn plyr
			end -- /if health <= 0

			-- game over if lives < 1
			if lives < 1 then 
				gameover = true
			end -- /if lives < 1

		end -- /if collide w/plyr
	
	end -- /for
 
end -- /function move_enemy()

-- draw enemy
function draw_enemy(enemy)
  spr(enemy.n,enemy.x,enemy.y)
end -- /draw_enemy()

-- scatter lost clouds after
-- collision with enemy
function scatter(lostclouds)

	-- get from constructor
	local lostclouds = lostclouds

	-- max number of clouds 
	local lim = 8
	if lostclouds > lim then 
		lostclouds = lim
	end -- /if lostclouds > lim

	local buffer = 10

	-- create pickups for each
	-- lost cloud, around plyr
	for i=1,lostclouds+1 do 
		local x = plyr.x
		local y = plyr.y
		local dx = 0
		local dy = 0
		
		-- determine x, dx
		if i == 1 or i == 5
		then 
			x = plyr.x+plyr.w/2
			dx= 0
		elseif i >= 2 and i <= 4
		then
			x = plyr.x+plyr.w + buffer
			dx= 1
		elseif i >=6 and i <= 8
		then 
			x = plyr.x - buffer
			dx= -1
		end -- /if i (dx)

		-- determine y, dy
		if i == 3 or i == 7
		then 
			y = plyr.y + plyr.h/2
			dy= 0
		elseif i <= 2 or i == 8
		then 
			y = plyr.y + buffer
			dy= -1
		elseif i >= 4 and i <= 6
		then 
			y = plyr.y + plyr.h + buffer
			dy= 1
		end -- /if i (dy)

		make_pickup(x,y,dx,dy)
	end -- /for

end -- /function scatter()

-- collision btwn objects a,b
function collide(a,b)

	if b.x+b.w >= a.x
	and b.x <= a.x+a.w
	and b.y+b.h >= a.y
	and b.y <= a.y+a.h
	then
		return true
	else
		return false
	end -- /if
 
end -- /function collide(a,b)
__gfx__
00000000cccccccc1111111100000000000000000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc1111111100077000000000000000000000500500000000000000000000000000000000000000000000000000000000000000000000000000
00700700cccccccc1111111100777700000770000000000005000050000000000000000000000000000000000000000000000000000000000000000000000000
00077000cccccccc1111111107777770007777000000000050000005000000000000000000000000000000000000000000000000000000000000000000000000
00077000cccccccc1111111107777770077777700000000050000005000000000000000000000000000000000000000000000000000000000000000000000000
00700700cccccccc1111111100777700077777700000000005000050000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc1111111100000000007777000000000000555500000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccc1111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000099999999dddddddd00055000000000000005500700000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000099999999dddddddd005aa50007055000005aa50000000000000000000005500000000000000000000000000000000000000000000000000000000000
0000000099999999dddddddd05aaaa50005aa50005aaaa5000000000000000000055550000055000000000000000000000000000000000000000000000000000
0000000099999999dddddddd5aaaaaa505aaaa505aaaaaa500000000000000000555555000555500000000000000000000000000000000000000000000000000
0000000099999999dddddddd5aaaaaa55aaaaaa55aaaaaa500000000000000000555555005555550000000000000000000000000000000000000000000000000
0000000099999999dddddddd05aaaa505aaaaaa505aaaa5000000000000000000055550005555550000000000000000000000000000000000000000000000000
0000000099999999dddddddd0055550005aaaa500055550000000000000000000000000000555500000000000000000000000000000000000000000000000000
0000000099999999dddddddd00000000005555077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeee6666666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000eeeeeeee6666666600000000000000000000000000000000000000000005500000055000000000000000000000000000000000000000000000000000
00000000eeeeeeee6666666600000000000000000000000000000000000000000055550000555500000000000000000000000000000000000000000000000000
00000000eeeeeeee6666666600000000000000000000000000000000000000000555555005555550000000000000000000000000000000000000000000000000
00000000eeeeeeee6666666600000000000000000000000000000000000000000555555005555550000000000000000000000000000000000000000000000000
00000000eeeeeeee6666666600000000000000000000000000000000000000000055550000555500000000000000000000000000000000000000000000000000
00000000eeeeeeee66666666000000000000000000000000000000000000000000c0000000000c00000000000000000000000000000000000000000000000000
00000000eeeeeeee66666666000000000000000000000000000000000000000000000c0000c00000000000000000000000000000000000000000000000000000
0000000022222222000000000000000055000000aa00000000000000000000000005500000055000000000000000000000000000000000000000000000000000
0000000022222222000000000000000055000000aa00000000000000000000000055550000555500000000000000000000000000000000000000000000000000
00000000222222220000000000000000000000000000000000000000000000000555555005555550000000000000000000000000000000000000000000000000
00000000222222220000000000000000000000000000000000000000000000000555555005555550000000000000000000000000000000000000000000000000
00000000222222220000000000000000000000000000000000000000000000000055550000555500000000000000000000000000000000000000000000000000
0000000022222222000000000000000000000000000000000000000000000000000a00000000a000000000000000000000000000000000000000000000000000
0000000022222222000000000000000000000000000000000000000000000000000aa000000aa000000000000000000000000000000000000000000000000000
00000000222222220000000000000000000000000000000000000000000000000000a000000a0000000000000000000000000000000000000000000000000000
77000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7dd00770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00d5d500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77d6e6d7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
776ddd67000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77ccc77c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7ddcc77c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cddddddc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccd5d5cc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cddddddc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77d6e6d7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
776ddd67000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c6ccccc6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88000088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08800880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05a00a50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05500550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008ee800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000310000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000003100000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000031000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000101000000000000000000000000000002020200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000130000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000001300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000012
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000022
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001300000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000700002104023040260500050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
000400000a7500d750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000300502d0502a05026050210501d0502f40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090000185501d550205502555027550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001965019650000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000900001e75022750267502a7502c750007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
001000002775024750297500070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00090000210501e0501905018050190501c0501f0502005024050290502d050320503305000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0009000030750307502e7502b7502975024750227501d75018750167500c750077500575000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001f050000001f050000001d050000001d050000001c050000001c050000001d050000001d050000001f050000001f05000000000000000000000000000000000000000000000000000000000000000000
