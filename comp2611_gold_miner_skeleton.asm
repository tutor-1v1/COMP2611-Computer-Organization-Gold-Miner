https://tutorcs.com
WeChat: cstutorcs
QQ: 749389476
Email: tutorcs@163.com
.data
title: 		.asciiz "COMP2611 Gold Miner Game"
game_win:	.asciiz "You Win! Enjoy the game brought by COMP2611!"
game_lose:	.asciiz "You are fired!"

width:		.word 800 # the width of the screen
height:		.word 600 # the height of the screen

level_title:    .asciiz "Level:"
max_level:	.word 3 # the level limit is 3
game_level:	.word 1 # level of the game, initilized to be 1
level_time_limit:.word 90000 # the time limit of level in ms
level_timer:	.word 0 # the timer of level in ms
level_start:	.word 0 # the starting time of level
level_quota:	.word 0 # the quota of level
level_balance:	.word 0 # the balance of level

mineral_ids:	.word -1:200 # used to keep track of the ids of minerals
mineral_locs:	.word -1:400 # the array of initialized locations of minerals
mineral_sizes:	.word -1:400 # the array of sizes of minerals
mineral_base:	.word 2 # base id of minerals
mineral_num:	.word 0 # the number of minerals
gold_num:	.word 0 # the number of gold
gem_num:	.word 0 # the number of gem
rock_num:	.word 0 # the number of rock

dynamite_ids: 	.word -1:30 # used to keep track of the ids of dynamites
dynamite_base:	.word 60 # base id of the dynamite
dynamite_num:	.word 0 # the number of dynamites
dynamite_remain:.word 0 # the number of remaining dynamites


.text
main:		# Create the Game Screen
		li   $v0, 100 
		la   $a0, title
		la   $t0, width
		lw   $a1, 0($t0)
		la   $t0, height
		lw   $a2, 0($t0)
		syscall
		# play the background music
		li   $v0, 102
		li   $a0, 0
		li   $a1, 1
		syscall

game_level_init:# Set the parameters for the game level
		# set game level
	        li   $v0, 103
		li   $a0, 0
		la   $t0, game_level
		lw   $a1, 0($t0)
		syscall
		# Set level timer
		li   $v0, 103
		li   $a0, 1
		la   $t0, level_time_limit
		lw   $a1, 0($t0)
		addi $a1, $a1, -15000 # ms
		sw   $a1, 0($t0)
		syscall
		# Set level quota
		li   $v0, 103
		li   $a0, 2
		la   $t0, level_quota
		lw   $a1, 0($t0)
		addi $a1, $a1, 2000
		sw   $a1, 0($t0)
		syscall
		# Set level balance
		li   $v0, 103
		li   $a0, 3
		la   $t0, level_balance
		sw   $zero, 0($t0)
		li   $a1, 0
		syscall
		# Gold number increase by 3
		la   $t0, gold_num
		lw   $t1, 0($t0)
		addi $t1, $t1, 3
		sw   $t1, 0($t0)
		# Gem number increase by 2
		la   $t0, gem_num
		lw   $t1, 0($t0)
		addi $t1, $t1, 2
		sw   $t1, 0($t0)
		# Rock number increase by 4
		la   $t0, rock_num
		lw   $t1, 0($t0)
		addi $t1, $t1, 4
		sw   $t1, 0($t0)
		# Available dynamites set to level
		la   $t0, dynamite_num
		la   $t1, game_level
		lw   $t1, 0($t1)
		sw   $t1, 0($t0)
		# Get level starting time
		jal  get_time
		la   $t0, level_start
		sw   $v0, 0($t0)
		
game_start:	# Initialize the game by create Game Objects based on game level
		jal  init_game

main_loop:	jal  get_time
		add  $s6, $v0, $zero # $s6: starting time of the game
		jal  update_timer
		jal  check_game_status # task 6
		bne  $v0, $zero, game_end_status
		jal  update_hook_status # task 2, 3
		jal  update_minteral_status # task 4
		jal  update_dynamite_status # task 5
		jal  process_input
		jal  move_hook # task 1
		jal  move_minerals
		jal  move_dynamites
		# refresh screen
		li   $v0, 101
		syscall
		add  $a0, $s6, $zero
		li   $a1, 30 # iteration gap: 30 milliseconds
		jal  have_a_nap
		j    main_loop
		
game_end_status:# $v0 hold the game status of current level, $v0 = 1 win, $v0 = 2 lose
                li   $t0, 2 # $t0 = 2
                beq  $v0, $t0, game_over # game over if lose in any level
                # the following handles win at any level
                la   $t0, game_level
                lw   $t1, 0($t0) # $t1 = current game level
                la   $t0, max_level
                lw   $t2, 0($t0) # $t2 = max_level
                beq  $t1, $t2, win # winning at max level means winning the game
                # if the winning level is lower than max_level, promote to the next level
                addi $t1, $t1, 1
                la   $t0, game_level
                sw   $t1, 0($t0) # promote to next level
                # destroy all minerals and dynamites in last level
                jal  destroy_minerals
                jal  destroy_dynamites
		# start game next level 
                j    game_level_init
game_over:      li   $v0, 106 # create game lose text
		li   $a0, -1 # special id for lose_text
		li   $a1, 300
		li   $a2, 300
		la   $a3, game_lose
		syscall
		li   $v0, 101 # refresh screen
		syscall 
		li   $v0, 102 # play lose sound
		li   $a0, 2
		li   $a1, 0
		syscall 
		j    game_pause
win:		li   $v0, 106 # game win text
		addi $a0, $zero, -2 # special id for win_text
		addi $a1, $zero, 80
		addi $a2, $zero, 280
		la   $a3, game_win
		syscall 
		li   $v0, 101 # refresh screen
		syscall 
		li   $v0, 102 # play win sound
		li   $a0, 1
		li   $a1, 0
		syscall 
game_pause:	add  $a0, $s6, $zero
		addi $a1, $zero, 600
		jal  have_a_nap # count 10 mins from start
		li   $v0, 10 # exit
		syscall 


#--------------------------------------------------------------------
# func: init_game (num_gold, num_gem, num_rock, num_dynamite)
# 1. create the hook: located at the point (389, 100)
# 2. create minerals;
# 3. init the ids for dynamite
#--------------------------------------------------------------------
init_game:	# preserve stack
		addi $sp, $sp, -28
		sw   $ra, 24($sp)
		sw   $s0, 20($sp)
		sw   $s1, 16($sp)
		sw   $s2, 12($sp)
		sw   $s3, 8($sp)
		sw   $s4, 4($sp)
		sw   $s5, 0($sp)
		# 1. create the hook
		li   $v0, 105
		li   $a0, 1 # the id of hook is 1
		li   $a1, 0 # hook type
		li   $a2, 389 # the x_loc of hook
		li   $a3, 100 # the y_loc of hook
		syscall
		li   $v0, 112 # set hook's speed
		li   $a0, 1 # hook's id
		li   $a1, 12 # the speed of hook
		syscall
		# 2. create the specified number of minerals
		# 2.1 Gold
		la   $t0, gold_num
		lw   $a0, 0($t0) # the count of required mineral
		# ----------------------------------------------
		# since the game image is not really rectanglar,
		# you can set the size to be smaller for greater 
		# the sense of impact (challenge mode!!!). However,
		# this does not change the actual image size because
		# GUI is handled in Java. This affects the collision 
		# checks. Same applies for all other minerals.
		# ----------------------------------------------
		li   $a1, 1  # the mineral type
		li   $s2, 60 # the image width by default, more challenging if set to 50
		li   $s3, 45 # the image height by default, more challenging if set to 35
		li   $s4, 6 # the speed
		li   $s5, 500 # the price
		jal  create_multi_minerals
		# 2.2 Gem
		la   $t0, gem_num
		lw   $a0, 0($t0)
		li   $a1, 2
		li   $s2, 30
		li   $s3, 18
		li   $s4, 9
		li   $s5, 1500
		jal  create_multi_minerals
		# 2.3 Rock
		la   $t0, rock_num
		lw   $a0, 0($t0)
		li   $a1, 3
		li   $s2, 100
		li   $s3, 75
		li   $s4, 3
		li   $s5, 0
		jal  create_multi_minerals
		# 3. init dynamites
		la   $t0, dynamite_num
		lw   $a0, 0($t0)
		li   $a1, 4
		jal  init_dynamite
		# refresh screen
		li   $v0, 101
		syscall
ig_exit:	# restore stack
		lw   $ra, 24($sp)
		lw   $s0, 20($sp)
		lw   $s1, 16($sp)
		lw   $s2, 12($sp)
		lw   $s3, 8($sp)
		lw   $s4, 4($sp)
		lw   $s5, 0($sp)
		addi $sp, $sp, 28
		jr   $ra


#--------------------------------------------------------------------
# func create_multi_Minerals(total_num, created_num)
# @total_num: the number of Minerals needs to be created
# @created_num: the number of Minerals previously created
# Some attributes are passed through stack
# $s2: width
# $s3: height
# $s4: speed
# $s5: price
# Create multiple Minerals on the Game Screen.
#--------------------------------------------------------------------
create_multi_minerals:
		addi $sp, $sp, -16
		sw   $ra, 12($sp)
		sw   $s0, 8($sp) 
		sw   $s1, 4($sp)
		sw   $s6, 0($sp)
		add  $s0, $a0, $zero # $s0: total required creation num
		la   $t0, mineral_num
		lw   $s1, 0($t0) # $s1: created num
		add  $s6, $a1, $zero # $s6: the mineral type
cmm_loop:	beq  $s0, $zero, cmm_exit # if total = 0, finish creation
		# calculate id
		la   $t0, mineral_base
		lw   $t1, 0($t0)
		add  $a0, $t1, $s1 # id = base + created_num
		# get the allocated grid for mineral's location
		# it returns [-1, -1] if there exists 46 minerals in the cave already
		li   $v0, 104
		syscall
		add  $a1, $s6, $zero # mineral type
		add  $a2, $v0, $zero # xLoc
		add  $a3, $v1, $zero # yLoc
		# before syscall, store (id, x_loc, y_loc, width, height) into arrays
		la   $t0, mineral_ids
		sll  $t1, $s1, 2
		add  $t1, $t1, $t0
		sw   $a0, 0($t1) # save id
		la   $t0, mineral_locs
		sll  $t1, $s1, 3
		add  $t1, $t1, $t0
		sw   $a2, 0($t1) # save x_loc
		sw   $a3, 4($t1) # save y_loc
		la   $t0, mineral_sizes
		sll  $t1, $s1, 3
		add  $t1, $t1, $t0
		sw   $s2, 0($t1) # save width
		sw   $s3, 4($t1) # save height
		# create object mineral
		li   $v0, 105
		syscall
		# set speed
		li   $v0, 112
		add  $a1, $s4, $zero
		syscall
		# set price
		li   $v0, 117
		add  $a1, $s5, $zero
		syscall
		addi $s1, $s1, 1 # created_num++
		subi $s0, $s0, 1 # total_num--
		j    cmm_loop
cmm_exit:	# accumulate the created minerals
		la   $t0, mineral_num
		sw   $s1, 0($t0)
		lw   $ra, 12($sp)
		lw   $s0, 8($sp)
		lw   $s1, 4($sp)
		lw   $s2, 0($sp)
		addi $sp, $sp, 16
		jr   $ra


#--------------------------------------------------------------------
# func init_dynamite(num_dynamites)
# Initialize the "data structure" for dynamites:
# dynamite_num = @num_dynamites, dynamite_count = 0, dynamite_ids[:dynamite_num] = 0;
#--------------------------------------------------------------------
init_dynamite:	addi $sp, $sp, -12
		sw   $ra, 8($sp)
		sw   $s0, 4($sp)
		sw   $s1, 0($sp)
		add  $s0, $a0, $zero # $s0 = num_dynamites
		# update available dynamites
		li   $v0, 103
		li   $a0, 4
		add  $a1, $s0, $zero
		syscall
		la   $t0, dynamite_remain # dynamite_remain = dynamite_num
		sw   $s0, 0($t0)
		la   $s1, dynamite_ids # $s1: the dynamite id array
ind_loop:	beq  $s0, $zero, ind_exit # loop if dynamite_num > 0
		addi $s0, $s0, -1 # i--
		sll  $t0, $s0, 2
		add  $t0, $t0, $s1 # the address of dynamite_ids[i] = &dynamite_ids[0] + i
		sw   $zero, 0($t0) # dynamite_ids[i] = 0, which indicates non-existence
		j    ind_loop
ind_exit:	lw   $ra, 8($sp)
		lw   $s0, 4($sp)
		lw   $s1, 0($sp)
		addi $sp, $sp, 12
		jr   $ra
		
		
#--------------------------------------------------------------------
# func update_timer
# Update the level timer on screen. 
# Since the sleep function severely distorts time calculation, 
# here we use the starting time of level as the basis to calculate time passed.
#--------------------------------------------------------------------
update_timer:	addi $sp, $sp, -12
		sw   $ra, 8($sp)
		sw   $s0, 4($sp)
		sw   $s1, 0($sp)
		jal  get_time
		la   $t0, level_start
		lw   $t0, 0($t0) # $t0: the level's starting time
		sub  $s0, $v0, $t0 # $s0: time passed = now's time - level's starting time
		la   $t1, level_time_limit
		lw   $s1, 0($t1) # $s1: the level's time limit
		sub  $a1, $s1, $s0 # timer = time limit - time passed
		la   $t0, level_timer
		sw   $a1, 0($t0) # save the timer
		li   $v0, 103
		li   $a0, 1
		syscall
		lw   $ra, 8($sp)
		lw   $s0, 4($sp)
		lw   $s1, 0($sp)
		addi $sp, $sp, 12
		jr   $ra



#--------------------------------------------------------------------
# func: check_game_status
# Check whether the game is over!
# 1. player wins the game when the balance >= quota
# 2. player loses the game when the timer <= 0
# @return: $v0={0: not end; 
# 		1: win;
# 		2: lose
#--------------------------------------------------------------------
check_game_status: 
# =================================== TODO ==========================================
# Task6: check_game_status
# 	Check whether the game should continue, has been won, or has been lost.
# ============================= You codes start here ================================
		li   $v0, 0
		jr   $ra
# ============================= Your codes end here =================================


#--------------------------------------------------------------------
# func update_hook_status
# Check and change the status of the hook according to these conditions:
# 1. if the hook goes beyong the screen, it should start rewinding;
# 2. if the hook reaches the winch, its status should be reset to start rotating;
#--------------------------------------------------------------------
update_hook_status:
		addi $sp, $sp, -8
		sw   $ra, 4($sp)
		sw   $s0, 0($sp)
		# check hook's condition
		li   $v0, 108 # get hook's location
		li   $a0, 1 # hook's id
		syscall
		# if it goes beyond screen
		sge  $t0, $v0, 850 # if the hook's x_loc >= 850
		sle  $t1, $v0, -50 # if the hook's x_loc <= -50
		sge  $t2, $v1, 650 # if the hook's y_loc >= 650
		sle  $t3, $v1, 0 # if the hook's y_loc <= 0
		or   $t0, $t0, $t1
		or   $t0, $t0, $t2
		or   $t0, $t0, $t3
		bne  $t0, $zero, uhs_rewind # any true condition leads to rewind
		# if it is hooked and reaches the winch
		sle  $t0, $v1, 80 # if the hook's y_loc <= 80, i.e. the horizontal line where the winch locates
		beq  $t0, $zero, uhs_exit # if hook has not reached the winch
		li   $v0, 118 # get isHooked
		syscall
		beq  $v0, $zero, uhs_exit # if hook is not hooked => the special case whrere the swinging is not implemented
uhs_rotate:	# if the hook has reached the winch when it is hooked (either a mineral or the boundaries)
		li   $v0, 119 # toggle isHooked to stop the hook from rewinding
		syscall
		li   $v0, 121 # toggle isShoot to start hook's rotation
		syscall
		li   $v0, 109 # reset hook's location
		li   $a1, 389 # the x_loc of hook
		li   $a2, 100 # the y_loc of hook
		syscall
		li   $v0, 112 # reset hook's speed
		li   $a1, 12 # the speed of hook
		syscall
		li   $v0, 114 # reset hook's direction
		li   $a1, 0 # the direction of hook
		syscall
		j    uhs_exit
uhs_rewind:	li   $v0, 119 # toggle isHooked to let the hook rewind
		syscall
uhs_exit:	lw   $ra, 4($sp)
		lw   $s0, 0($sp)
		addi $sp, $sp, 8
		jr   $ra


#--------------------------------------------------------------------
# func update_minteral_status
# Check and change the status of the minerals according to these conditions:
# 1. if a mineral is not hooked
#	1.1 if the hook is already attached with something, do nothing;
#	1.2 if it intersects with the hook, attach it to the hook;
# 2. if a mineral is hooked
# 	2.1 if it reaches the winch, cash in and destroy;
#--------------------------------------------------------------------
update_minteral_status: # check minerals' condition
		addi $sp, $sp, -20
		sw   $ra, 16($sp)
		sw   $s0, 12($sp)
		sw   $s1, 8($sp)
		sw   $s2, 4($sp)
		sw   $s3, 0($sp)
		la   $t0, mineral_num
		lw   $s0, 0($t0) # $s0: the number of minerals
		la   $s1, mineral_ids # $s1: the id array
ums_loop:	beq  $s0, $zero, ums_exit # if all minerals are checked
		addi $t0, $s0, -1 # i = n - 1
		sll  $t0, $t0, 2
		add  $s2, $s1, $t0 # $s2: the address that stores the mineral's id
		lw   $s3, 0($s2) # $s3: the id of the mineral
		beq  $s3, $zero, ums_next # this mineral has already been sold
		# check if it is hooked
		li   $v0, 118
		add  $a0, $s3, $zero
		syscall
		bne  $v0, $zero, ums_hooked # if this mineral is hooked
ums_unhooked:	# check if this unhooked mineral intersects with the hook
		# but the hook must not attach to other minerals
		li   $v0, 118 # get hook's isHooked
		li   $a0, 1
		syscall
		bne  $v0, $zero, ums_next # the hook has hooked to something else
		addi $a0, $s0, -1 # mineral's index
		jal  check_hook_hit
		beq  $v0, $zero, ums_next # if the mineral does not intersect, check next
ums_intersect:  # if the two intesect
		# handle isHooked
		li   $v0, 119 # toggle isHooked
		add  $a0, $s3, $zero # for the mineral
		syscall
		li   $v0, 119 # toggle isHooked
		li   $a0, 1 # for the hook
		syscall
		# align location
		li   $v0, 108 # get hook's location
		li   $a0, 1
		syscall
		add  $a0, $s3, $zero
		add  $a1, $v0, $zero
		add  $a2, $v1, $zero
		li   $v0, 109 # set mineral's location
		syscall
		# align direction
		li   $v0, 113 # get hook's direction
		li   $a0, 1
		syscall
		add  $a0, $s3, $zero
		add  $a1, $v0, $zero
		li   $v0, 114 # set mineral's direction
		syscall
		# align speed
		li   $v0, 111 # get mineral's speed
		add  $a0, $s3, $zero
		syscall
		li   $a0, 1
		add  $a1, $v0, $zero
		li   $v0, 112 # set hook's speed
		syscall
		# play hit sound
		li   $v0, 102
		li   $a0, 4
		li   $a1, 0
		syscall
		j    ums_next
ums_hooked:	# check if it reaches the winch
		li   $v0, 108 # get mineral's location
		add  $a0, $s3, $zero
		syscall
		sle  $t0, $v1, 80 # if the mineral's y_loc <= 80
		beq  $t0, $zero, ums_next # if the mineral has not reached the winch, check next
		addi $a0, $s0, -1 # mineral's index
		# update level balance and destroy the mineral
		jal  update_mineral_at_winch
ums_next: 	addi $s0, $s0, -1
		j    ums_loop
ums_exit:	lw   $ra, 16($sp)
		lw   $s0, 12($sp)
		lw   $s1, 8($sp)
		lw   $s2, 4($sp)
		lw   $s3, 0($sp)
		addi $sp, $sp, 20
		jr   $ra


#--------------------------------------------------------------------
# func check_hook_hit(mineral_index)
# Check whether the hook collides with the specified mineral. 
# @params: $a0: mineral_index
# 
# @return: $v0={0: not intersected
# 		1: intersected
#--------------------------------------------------------------------
check_hook_hit:
# =================================== TODO ==========================================
# Task3: check_hook_hit
# 	This procedure pushes the coordinates of two game objects into the stack, 
# 	and then calls the procedure check_intersection implemented in task 2.
# Hints:
#	You could reference the following procedure to help you complete:
# 		get hook's location (hook's id is 1 by default)
# 		read documentation to find hook's size
# 		store hook's rect to stack
# 		get mineral's location and size (reference create_multi_minerals)
# 		store mineral's rect to stack
# 		call check_intersection
# 		reset stacks
# ============================= You codes start here ================================
		jr   $ra
# ============================= Your codes end here =================================
		

#--------------------------------------------------------------------
# func update_mineral_at_winch(mineral_index)
# Given the mineral's id, update the level balance and destroy the object according.
# @params: $a0: mineral_index
#--------------------------------------------------------------------
update_mineral_at_winch:
# =================================== TODO ==========================================
# Task4: update_mineral_at_winch
# 	This procedure manages the operations after the mineral has reached the winch. 
# 	They include updating level balance and destroying the mineral.
# Hints:
# 	You should destroy the object with syscall, and locate the mineral in the 
#	mineral_ids array and set it 0 to remove it from game logic (see move_minerals).
#	The price of the mineral can be acquired from syscall.
# ============================= You codes start here ================================
		jr   $ra
# ============================= Your codes end here =================================


#--------------------------------------------------------------------
# func update_dynamite_status
# Check and change the status of the dynamites according to these conditions:
# 1. if the dynamite falls outside of the screen, it should be destroyed;
# 2. if the dynamite hits a mineral, they should both be destroyed.
#--------------------------------------------------------------------
update_dynamite_status:	# check minerals' condition
		addi $sp, $sp, -16
		sw   $ra, 12($sp)
		sw   $s0, 8($sp)
		sw   $s1, 4($sp)
		sw   $s2, 0($sp)
		la   $t0, dynamite_num
		lw   $s0, 0($t0) # $s0: the number of minerals
		la   $s1, dynamite_ids # $s1: the id array
uds_loop:	beq  $s0, $zero, uds_exit # if no available dynamites left
		addi $s0, $s0, -1 # dynamite_num--
		sll  $t0, $s0, 2
		add  $t0, $s1, $t0  # the address of dynamite_ids[i] = &dynamite_ids[0] + i
		lw   $s2, 0($t0) # $s2: dynamite_ids[i]
		beq  $s2, $zero, uds_loop # if dynamite_ids[i] == 0, the dynamite does not exist
		# check dynamite's location
		li   $v0, 108 # get location
		add  $a0, $s2, $zero
		syscall
		# if it goes beyond screen
		sge  $t0, $v0, 850 # if the dynamite's x_loc >= 850
		sle  $t1, $v0, -50 # if the dynamite's x_loc <= -50
		sge  $t2, $v1, 650 # if the dynamite's y_loc >= 650
		sle  $t3, $v1, -50 # if the dynamite's y_loc <= -50
		or   $t0, $t0, $t1
		or   $t0, $t0, $t2
		or   $t0, $t0, $t3
		bne  $t0, $zero, uds_destroy # any true condition leads to destroy
		# check if dynamite intercepts with any minerals
		add  $a0, $s2, $zero # dynamite_id
		jal  check_dynamite_hit
		beq  $v0, $zero, uds_loop # if the mineral does not intersect, check next
		# reset hook's speed because it is hooked to nothing now
		li   $v0, 112 # set speed
		li   $a0, 1 # hook's id
		li   $a1, 12 # hook's speed by default
		syscall
uds_destroy:	li   $v0, 107 # destroy dynamite
		add  $a0, $s2, $zero
		syscall
		sll  $t0, $s0, 2
		add  $t0, $s1, $t0  # the address of dynamite_ids[i] = &dynamite_ids[0] + i
		sw   $zero, 0($t0) # dynamite_ids[i] = 0
		j    uds_loop
uds_exit:	lw   $ra, 12($sp)
		lw   $s0, 8($sp)
		lw   $s1, 4($sp)
		lw   $s2, 0($sp)
		addi $sp, $sp, 16
		jr   $ra
		

#--------------------------------------------------------------------
# func check_dynamite_hit(dynamite_id)
# Check whether the dynamite collides with any mineral. This procedure 
# loops over the minerals to call the procedure check_intersection for result.
# @params: $a0: dynamite_id
# 
# @return: $v0={0: not intersected
# 		1: intersected
#--------------------------------------------------------------------
check_dynamite_hit:
# =================================== TODO ==========================================
# Task5: check_dynamite_hit
# 	This procedure loops over the minerals to find any intersected minerals.
# 	It pushes the coordinates of two game objects into the stack, 
# 	and then calls the procedure check_intersection implemented in task 2.
#	It should also destroy the intersected mineral before jumping back to return address.
# Hints:
#	You could reference the following procedure to help you complete:
#		setup the loop conditions for all minerals
# 		get dynamite's location
# 		read documentation to find dynamite's size
# 		store dynamite's rect to stack
# 		get mineral's location and size (reference create_multi_minerals)
# 		store mineral's rect to stack
# 		call check_intersection
# 		reset stacks
#		if they are not intersected, go to the next mineral or return
#		if they are intersected, destroy the mineral (as in task 4) and return with result.
# ============================= You codes start here ================================
		li   $v0, 0
		jr   $ra
# ============================= Your codes end here =================================


#--------------------------------------------------------------------
# func process_input
# React to the keyboard input.
#--------------------------------------------------------------------
process_input:	addi $sp, $sp, -4
		sw   $ra, 0($sp)
		jal  get_keyboard_input # $v0: the return value
		li   $t0, 32 # corresponds to key 'space'
		beq  $v0, $t0, pi_hook
		li   $t0, 100 # corresponds to key 'd'
		beq  $v0, $t0, pi_dynamite
		j    pi_exit
pi_dynamite:	jal  throw_dynamite
		j    pi_exit
pi_hook:	jal  shoot_hook
		j    pi_exit
pi_exit:	lw   $ra, 0($sp)
		addi $sp, $sp, 4
		jr   $ra


#--------------------------------------------------------------------
# func shoot_hook
# 1. toggle isShoot to stop rotation and start moving forward.
# 2. if it isShoot is true, player cannot control it.
#--------------------------------------------------------------------
shoot_hook:	addi $sp, $sp, -4
		sw   $ra, 0($sp)
		li   $v0, 120 # check isShoot
		li   $a0, 1 # hook's id
		syscall
		bne  $v0, $zero, shoot_hook_end # the hook is shoot
		li   $v0, 121 #toggle isShoot
		syscall
		# play emit sound
		li   $v0, 102
		li   $a0, 3
		li   $a1, 0
		syscall
shoot_hook_end: lw   $ra, 0($sp)
		addi $sp, $sp, 4
		jr   $ra


#--------------------------------------------------------------------
# func throw_dynamite
# 1. check whether there are avaiable bombs to use.
# 2. if yes, create one bomb object
#--------------------------------------------------------------------
throw_dynamite:	addi $sp, $sp, -20
		sw   $ra, 16($sp)
		sw   $s0, 12($sp)
		sw   $s1, 8($sp)
		sw   $s2, 4($sp)
		sw   $s3, 0($sp)
		la   $t0, dynamite_remain
		lw   $s0, 0($t0) # $s0: the remaining number of dynamites
		beq  $s0, $zero, td_exit # if no remaining dynamites left
		# find the slot for a new dynamite
		la   $t0, dynamite_num
		lw   $s1, 0($t0) # $s1: the number of dynamites avilable in the level
		la   $s2, dynamite_ids # $s2: the dynamites array's address
td_loop:	beq  $s1, $zero, td_exit # if no available dynamites left
		addi $s1, $s1, -1 # dynamite_num--
		sll  $t0, $s1, 2
		add  $t0, $s2, $t0  # the address of dynamite_ids[i] = &dynamite_ids[0] + i
		lw   $t1, 0($t0) # dynamite_ids[i]
		bne  $t1, $zero, td_loop # if dynamite_ids[i] != 0, the dynamite exists
		# update available dynamites
		li   $v0, 103
		li   $a0, 4
		la   $t0, dynamite_remain
		addi $s0, $s0, -1 # dynamite_remain--
		sw   $s0, 0($t0) # save it
		add  $a1, $s0, $zero
		syscall
		# register the dynamite id
		la   $t0, dynamite_base
		lw   $s3, 0($t0) # $s3: the id value to be used
		add  $s3, $s3, $s0 # id = base + remain_num
		sll  $t0, $s1, 2
		add  $t0, $s2, $t0  # the address of dynamite_ids[i] = &dynamite_ids[0] + i
		sw   $s3, 0($t0)
		# create a dynamite
		li   $v0, 105
		add  $a0, $s3, $zero # the id
		li   $a1, 4
		li   $a2, 400 # initial x_loc
		li   $a3, 100 # initial y_loc
		syscall
		# set the speed
		li   $v0, 112
		li   $a1, 15
		syscall
		# set the direction
		li   $v0, 113 # get hook's direction
		li   $a0, 1
		syscall
		add  $a0, $s3, $zero
		add  $a1, $v0, $zero
		li   $v0, 114 # set mineral's direction
		syscall
		# play emit sound
		li   $v0, 102
		li   $a0, 3
		li   $a1, 0
		syscall
td_exit:	lw   $ra, 16($sp)
		lw   $s0, 12($sp)
		lw   $s1, 8($sp)
		lw   $s2, 4($sp)
		lw   $s2, 0($sp)
		addi $sp, $sp, 20
		jr $ra


#--------------------------------------------------------------------
# func check_intersection(recA, recB)
# @recA: ((x1, y1), (x2, y2))
# @recB: ((x3, y3), (x4, y4))
# these 8 parameters are passed through stack!
# @params: the coordinates of RectA and RectB are passed through stack.
# 	   In total, 8 words are passed. RectA is followed by RectB, as shown below. 
#	
#	| RectA.topleft_x |
#	| RectA.topleft_y |
#	| RectA.botrigt_x |
#	| RectA.botrigh_y |
#	| RectB.topleft_x |
#	| RectB.topleft_y |
#	| RectB.botrigt_x |
#	| RectB.botrigh_y | <-- $sp 
#
# This function is to check whether the above two rectangles are intersected.
# @return $v0=1: true(intersect with each other); 0: false
#--------------------------------------------------------------------
check_intersection:
# =================================== TODO ==========================================
# Task2: check_intersection
# 	This procedure checks whether the two input rectangles are intersected. 
# 	Notice that the coordinates are passed through the stack.
# Hints:
# 	Firstly, load 8 parameters/coordinates from the stack.
# 	Secondly, check the conditions in which there could be no intersection:
# 		condition1: whether recA's left edge is to the right of recB's right edge;
# 		condition2: whether recA's right edge is to the left of recB's left edge;
# 		condition3: whether recA's top edge is below recB's bottom edge;
# 		condition4: whether recA's bottom edge is above recB's top edge.
# 	Thirdly, set the value of $v0 based on the check result and jump to return address.
# ============================= You codes start here ================================
		li   $v0, 0
		jr   $ra
# ============================= Your codes end here =================================


#--------------------------------------------------------------------
# func: move_hook
# Move the hook by one step.
#
# When the hook is not shoot:
# 	It stays in the initial position and swing in different angle (change direction).
# 	To swing in a pendulum, if the hook is going too far, make it move in the opposite direction.
# 		i.e. if old_direction + swinging delta degree < -85degrees or old_direction + delta degree > 85degrees:
# 			change the moving direction
# When the hook is shoot:
# 	It stops swinging and move forward until it hits a mineral or the boundaries.
#--------------------------------------------------------------------	
move_hook:  	addi $sp, $sp, -12
		sw   $ra, 8($sp)
		sw   $s0, 4($sp)
		sw   $s1, 0($sp)
		li   $v0, 120 # check isShoot
		li   $a0, 1 # id of hook
		syscall
		beq  $v0, $zero, move_hook_swing # the hook is not shoot
		li   $v0, 110 # update location
		li   $a0, 1 # id of hook
		syscall
		j    mh_exit
move_hook_swing:
# =================================== TODO ==========================================
# Task1: move_hook_swing
# 	This procedure moves the hook by changing its direction for one game iteration. 
# 	To swing in a pendulum, the hook should stay between -85 to 85 degrees.
# Hints:
# 	You could utilize the isClockwise boolean variable to help decide the swinging direction.
# ============================= You codes start here ================================
		# The following codes are the default behaviors, feel free to change them
		li   $v0, 115 # change direction
		li   $a0, 1 # id of hook
		li   $a1, -3 # swinging delta degree: -3 means clockwise movement
		syscall
# ============================= Your codes end here =================================
mh_exit:	lw   $ra, 8($sp)
		lw   $s0, 4($sp)
		lw   $s1, 0($sp)
		addi $sp, $sp, 12
		jr   $ra


#--------------------------------------------------------------------
# func: move_minerals
# If a mineral is hooked, it starts to move along the hook back to the winch.
#--------------------------------------------------------------------	
move_minerals:  addi $sp, $sp, -12
		sw   $ra, 8($sp)
		sw   $s0, 4($sp)
		sw   $s1, 0($sp)
		la   $t0, mineral_num
		lw   $s0, 0($t0) # $s0: the number of minerals
mm_loop:	beq  $s0, $zero, mm_exit
		la   $s1, mineral_ids # $s1: unchanged till the end
		addi $t0, $s0, -1 # mineral_num-1 to be the index
		sll  $t0, $t0, 2
		add  $t1, $s1, $t0 # $t1: the address of id
		lw   $a0, 0($t1) # $a0: the id of a mineral
		beq  $a0, $zero, mm_next # mineral_id equal 0 indicates non-existance
		# check isHooked
		li   $v0, 118
		syscall
		beq  $v0, $zero, mm_next # currently not isHooked
		# move the mineral because it is hooked
		li   $v0, 110 # update location
		syscall
mm_next:	addi $s0, $s0, -1
		j    mm_loop
mm_exit:	lw   $ra, 8($sp)
		lw   $s0, 4($sp)
		lw   $s1, 0($sp)
		addi $sp, $sp, 12
		jr   $ra


#--------------------------------------------------------------------
# func: move_dynamites
# let the dynamites move forward
#--------------------------------------------------------------------	
move_dynamites: addi $sp, $sp, -12
		sw   $ra, 8($sp)
		sw   $s0, 4($sp)
		sw   $s1, 0($sp)
		la   $t0, dynamite_num
		lw   $s0, 0($t0) # $s0: the number of dynamites
md_loop:	beq  $s0, $zero, md_exit
		la   $s1, dynamite_ids # $s1: unchanged till the end
		addi $s0, $s0, -1 # dynamite_num-1 to be the index
		sll  $t0, $s0, 2
		add  $t1, $s1, $t0 # $t1: the address of id
		lw   $a0, 0($t1) # $a0: the id of a dynamite
		beq  $a0, $zero, md_loop # the dynamite does not exists
		li   $v0, 110 # update location
		syscall
		j    md_loop
md_exit:	lw   $ra, 8($sp)
		lw   $s0, 4($sp)
		lw   $s1, 0($sp)
		addi $sp, $sp, 12
		jr   $ra


#--------------------------------------------------------------------
# func: destroy_minerals
# destroy all the minerals in Java memory
#--------------------------------------------------------------------
destroy_minerals:
		addi $sp, $sp, -12
		sw   $ra, 8($sp)
		sw   $s0, 4($sp)
		sw   $s1, 0($sp)
		la   $t0, mineral_num
		lw   $s0, 0($t0) # $s0: the number of minerals
		la   $s1, mineral_ids # $s1: the id array
destroy_loop:	beq  $s0, $zero, destroy_exit
		addi $t0, $s0, -1 # i = n - 1
		sll  $t0, $t0, 2
		add  $t1, $s1, $t0 # $t1: the address of id
		lw   $a0, 0($t1) # $a0: the id of a mineral
		beq  $a0, $zero, destroy_next # the mineral is destroyed already
		li   $v0, 107 # destroy mineral
		syscall
		sw   $zero, 0($t1) # mineral_ids[i] = 0
destroy_next:	addi $s0, $s0, -1
		j    destroy_loop
destroy_exit:	lw   $ra, 8($sp)
		lw   $s0, 4($sp)
		lw   $s1, 0($sp)
		addi $sp, $sp, 12
		jr   $ra


#--------------------------------------------------------------------
# func: destroy_dynamites
# destroy all the dynamites in Java memory
#--------------------------------------------------------------------
destroy_dynamites:
		addi $sp, $sp, -12
		sw   $ra, 8($sp)
		sw   $s0, 4($sp)
		sw   $s1, 0($sp)
		la   $t0, dynamite_num
		lw   $s0, 0($t0) # $s0: the number of dynamites
		la   $s1, dynamite_ids # $s1: the id array
		j    destroy_loop # same as destroy minerals


#--------------------------------------------------------------------
# func: get_time
# Get the current time
# $v0 = current time
#--------------------------------------------------------------------
get_time:	li   $v0, 30
		syscall # this syscall also changes the value of $a1
		andi $v0, $a0, 0x3FFFFFFF # truncated to milliseconds from some years ago
		jr   $ra


#--------------------------------------------------------------------
# func: have_a_nap(last_iteration_time, nap_time)
#--------------------------------------------------------------------
have_a_nap:	addi $sp, $sp, -8
		sw   $ra, 4($sp)
		sw   $s0, 0($sp)
		add  $s0, $a0, $a1
		jal  get_time
		sub  $a0, $s0, $v0
		slt  $t0, $zero, $a0 
		bne  $t0, $zero, han_p
		li   $a0, 1 # sleep for at least 1ms
han_p:		li   $v0, 32 # syscall: let mars java thread sleep $a0 milliseconds
		syscall
		lw   $ra, 4($sp)
		lw   $s0, 0($sp)
		addi $sp, $sp, 8
		jr   $ra


#--------------------------------------------------------------------
# func get_keyboard_input
# $v0: ASCII value of the input character if input is available;
#      otherwise, the value is 0;
#--------------------------------------------------------------------
get_keyboard_input:
		addi $sp, $sp, -4
		sw   $ra, 0($sp)
		add  $v0, $zero, $zero
		lui  $a0, 0xFFFF
		lw   $a1, 0($a0)
		andi $a1, $a1, 1
		beq  $a1, $zero, gki_exit
		lw   $v0, 4($a0)
gki_exit:	lw   $ra, 0($sp)
		addi $sp, $sp, 4
		jr   $ra
