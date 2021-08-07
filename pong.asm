IDEAL
MODEL small
STACK 100h

DATASEG
	;screen variables:
	x_center dw 0A0h ; 320/200d
	y_center dw 64h ; 200/2
	time_aux db 0
	
	screen_width dw 140h ;320d
	screen_height dw 0C8h ;200d
	
	;menu variables:
	two_players_game db 'TWO PLAYERS ------ press P','$'
	one_player_easy db  'ONE PLAYER EASY -- press R','$'
	exit_game db        'EXIT ------------- press Q','$'
	game_over db 'GAME OVER$',13,10,'$'
	

	;players variables:
	left_player_points db 00h
	right_player_points db 00h
	left_player_x_position db 07h
	right_player_x_position db 1Fh
	players_y_position db 02h
	player1_won_str db 'player 1 won!$'
	player2_won_str db 'player 2 won!$'
	computer_turn db 0h
	
	;rockets variables:
	rocket_width dw 05h
	rocket_height dw 20h;
	rocket_velocity dw 0Fh; 
	
	right_rocket_x dw 136h; 310d
	right_rocket_y dw 03h; 3d
	
	r_rocket_maxX dw 13bh ; 315d:  right_rocket_x + rocket_width (310d + 5d)
	r_rocket_maxY dw 03h ; right_rocket_y
	r_rocket_minX dw 136h ; right_rocket_x
	r_rocket_minY dw 24h ; 36d: right_rocket_y + rocket_height (5d + 31d) 
	
	left_rocket_x dw 05h
	left_rocket_y dw 03h
	l_rocket_maxX dw 0Ah ; 10d:  left_rocket_x + rocket_width (5d + 5d)
	l_rocket_maxY dw 05h ; left_rocket_y
	l_rocket_minX dw 03h ; left_rocket_x
	l_rocket_minY dw 24h ; 36d: left_rocket_y + rocket_height (5d + 31d)
	
	;ball variables:
	ball_size dw 04h;
	ball_distance dw 0Ah
	ball_distance_square dw 64h 
	ball_maximum_y dw 09h
	ball_velocity_x dw 06h
	ball_velocity_y dw 08h
	
	ball_x dw 0A0h;
	ball_y dw 64h;
	ball_maxX dw 0A4h ;164d: ball_x + ball_width
	ball_maxY dw 64h ;ball_y
	ball_minX dw 0A0h;ball_x
	ball_minY dw 68h;104d: ball_y + ball_height

	
CODESEG
	;------------------------------------------------------------
	;PROCEDURES STARTS HERE
	;------------------------------------------------------------
	proc set_video_mode
		push ax
		push bx
		
		mov ah, 00h
		mov al, 13h ;video mode
		int 10h
		
		;set background to black
		mov ah, 0Bh
		mov bx, 00h
		int 10h
	
		pop bx
		pop ax
		ret
	endp set_video_mode
	
	proc get_system_time
		push ax
		
		mov ah, 2ch 
		int 21h
		
		pop ax
		ret
	endp get_system_time
	
	proc move_either_rocket
	;left rocket:
		;check if any key has been pressed (if not check for the right pedal)
		mov ah, 01h
		int 16h
		jnz continue ;if zf == 0 -> no key has been pressed
		jmp end_proc
		
		continue:
			;check which key has been pressed: 'W' or 'w' means up, 'S' or 's' means down
			mov ah, 00h
			int 16h
			cmp al, 'W'
			je move_left_rocket_up
			cmp al, 'w'
			je move_left_rocket_up
			
			cmp al, 'S'
			je move_left_rocket_down
			cmp al, 's'
			je move_left_rocket_down
			jmp check_right_rocket
			
			;moving left rocket up
			move_left_rocket_up:
				mov ax, [left_rocket_y]
				sub ax, [rocket_velocity]
				cmp ax, 00h
				jg cont
				jmp end_proc
				cont:
				;update l_rocket_variables:
				mov [left_rocket_y], ax
				mov [l_rocket_maxY], ax
				add ax, [rocket_height]
				mov [l_rocket_minY], ax
				jmp end_proc

			;moving left rocket down
			move_left_rocket_down:
				mov ax, [left_rocket_y]
				add ax, [rocket_velocity]
				add ax, [rocket_height]
				cmp ax, [screen_height]
				jg end_proc
				sub ax, [rocket_height]
				;update l_rocket_variables:
				mov [left_rocket_y], ax
				mov [l_rocket_maxY], ax
				add ax, [rocket_height]
				mov [l_rocket_minY], ax
				jmp end_proc
				
			;right rocket:
				check_right_rocket:
					call move_right_rocket
				
		end_proc:
			ret
	endp move_either_rocket
	
	proc move_right_rocket
			cmp ah, 48h ;up arrow key as scancode which is in ah register ah:scancode al:ascii code
			je move_right_rocket_up
					
			cmp ah, 50h ;down arrow key as scancode which is in ah register
			je move_right_rocket_down
			jmp finish_proc
					
			;moving right rocket up
			move_right_rocket_up:
				mov ax, [right_rocket_y]
				sub ax, [rocket_velocity]
				cmp ax, 00h
				jle finish_proc
				;update r_rocket_variables:
				mov [right_rocket_y], ax
				mov [r_rocket_maxY], ax
				add ax, [rocket_height]
				mov [r_rocket_minY], ax
				jmp finish_proc
						
			;moving right rocket down
			move_right_rocket_down:
				mov ax, [right_rocket_y]
				add ax, [rocket_velocity]
				add ax, [rocket_height]
				cmp ax, [screen_height]
				jg finish_proc
				sub ax, [rocket_height]
				;update r_rocket_variables:
				mov [right_rocket_y], ax
				mov [r_rocket_maxY], ax
				add ax, [rocket_height]
				mov [r_rocket_minY], ax
		finish_proc:
			ret
	endp move_right_rocket
	
	
	
	
	proc move_the_ball
		push ax
		;change x coordinate in the ball movement
		mov ax, [ball_velocity_x]
		add [ball_x], ax
		;update the maxX and minX ball variables:
		mov ax, [ball_x]
		mov [ball_minX],ax
		add ax, [ball_size]
		mov [ball_maxX], ax
		
		;check for width boundaries collisions
		;check left boundary 
		mov ax, [ball_size]
		cmp [word ptr ball_x], ax
		jnl check_right_boundry
		inc [right_player_points]
		jmp move_ball_to_center
		
		check_right_boundry:
			mov ax, [screen_width]
			sub ax, [ball_size]
			cmp [word ptr ball_x], ax
			jng move_on_y_axis
			inc [left_player_points]
			jmp move_ball_to_center
		move_on_y_axis:
			;change y coordinate in the ball movement
			mov ax, [ball_velocity_y]
			add [word ptr ball_y], ax
			;update the maxY and minY ball variables:
			mov ax, [ball_y]
			mov [ball_maxY],ax
			add ax, [ball_size]
			mov [ball_minY], ax
		
			;check for height boundaries collisions
			;check upper boundary
			mov ax, [ball_size]
			cmp [word ptr ball_y], ax
			jl neg_velocity_y
			
			;check bottom boundary
			mov ax, [screen_height]
			sub ax, [ball_size]
			cmp [word ptr ball_y],ax
			jg neg_velocity_y
			jmp check_ball_rocket_collisions
		
		move_ball_to_center:
			cmp [right_player_points],05h
			jge end_game
			cmp [left_player_points],05h
			jge end_game
			call caentral_the_ball
			pop ax
			ret
		
		;if one player got 5 points the game is over
		end_game:
			call draw_points
			
			;position cruiser
			mov ah, 02h
			mov bh, 00h
			mov dl, 0Dh
			mov dh, 04h
			int 10h
			
			cmp [right_player_points],05h
			jl left_player_won
			mov ah, 09h
			lea dx, [player2_won_str]
			int 21h
			jmp reset_points
			left_player_won:
			mov ah, 09h
			lea dx, [player1_won_str]
			int 21h
			
			reset_points:
				mov [left_player_points], 00h
				mov [right_player_points], 00h
			;recenter the ball:
			call caentral_the_ball
			;position cruiser
			mov ah, 02h
			mov bh, 00h
			mov dl, 0Fh
			mov dh, 06h
			int 10h
			
			mov ah, 09h
			lea dx, [game_over]
			int 21h
			call draw_menu
			
			pop ax
			jmp reading_menu
			
		neg_velocity_y:
			neg [ball_velocity_y]
			pop ax
			ret
			
		check_ball_rocket_collisions:
		;check right rocket-collisions
			mov ax, [ball_minX]
			mov bx, [r_rocket_maxX]
			cmp bx,ax
			jl left_rocket_collision
			mov ax, [ball_maxX]
			mov bx, [r_rocket_minX]
			cmp ax, bx
			jl left_rocket_collision
			mov ax, [ball_minY]
			mov bx, [r_rocket_maxY]
			cmp ax, bx
			jl left_rocket_collision
			mov ax, [ball_maxY]
			mov bx, [r_rocket_minY]
			cmp bx, ax
			jl left_rocket_collision
			;recalculate y velocity according to the hitting position of the ball in the rocket
			mov ax, [right_rocket_y]
			push ax
			call calculate_ball_new_velocity
			pop ax
			
			jmp neg_velocity_x
			
			
		;check left rocket-collisions
		left_rocket_collision:
			mov ax, [ball_maxX]
			mov bx, [l_rocket_minX]
			cmp ax, bx
			jl end_move_ball
			mov ax, [l_rocket_maxX]
			mov bx, [ball_minX]
			cmp ax, bx
			jl end_move_ball
			mov ax, [ball_maxY]
			mov bx, [l_rocket_minY]
			cmp bx, ax
			jl end_move_ball
			mov ax, [ball_minY]
			mov bx, [l_rocket_maxY]
			cmp ax, bx
			jl end_move_ball
			;recalculate y velocity according to the hitting position of the ball in the rocket
			mov ax, [left_rocket_y]
			push ax
			call calculate_ball_new_velocity
			pop ax
			
			jmp end_move_ball
					
		neg_velocity_x:
			neg [ball_velocity_x]

		end_move_ball:
			pop ax
			ret
		
	endp move_the_ball
	
	Rocket_y equ [bp+4]
	proc calculate_ball_new_velocity
		push bp
		mov bp, sp
		push ax
		push bx
		;using this function: ball_y = (max_val_y/(rocket_height/2))*((ball_y - rocket_y)-(rocket_height/2)) 
		mov ax, Rocket_y
		mov bx, [ball_y]
		sub bx, ax
		cmp bx, 10h
		jne chaging_ball_val
		mov [ball_velocity_y], 00h
		mov ax, [ball_distance]
		mov [ball_velocity_x], ax
		jmp end_calc
		chaging_ball_val:
			sub bx, 10h ;the middle of the rocket
				cmp bx, 00h
				jle negative
				xor ax,ax
				mov ax, [ball_maximum_y]
				imul bl ; ax = al*bl
				mov bl, 10h ;rocket_height/2
				idiv bl ;al = ax/bl
				xor ah,ah	
				cmp ax, 00h
				jne conts
				inc ax
				jmp conts
			negative:
				neg bx
				mov ax, [ball_maximum_y]
				mul bl ; ax = al*bl
				mov bl, 10h ;rocket_height/2
				div bl ;al = ax/bl
				xor ah,ah	
				neg ax
				cmp ax, 00h
				jne conts
				inc ax

			conts:
				mov [ball_velocity_y], ax
				call calculate_ball_x_new_velocity
		end_calc:
		pop bx
		pop ax
		pop bp
		ret
	endp calculate_ball_new_velocity
	
	;in order to keep the speed steady (same distance over the same amount of time)
	;we calculate x according to the new y so the distance remains the same
	;x = math.sqr(dis^2 - y^2)
	proc calculate_ball_x_new_velocity
		push ax
		push bx 
		push cx
		
		mov bx, [ball_distance_square]
		mov ax, [ball_velocity_y]
		imul ax ;y^2
		sub bx, ax
		;square_root:
			mov ax, bx
			mov bx, 0FFFFh
			mov cx, 00h
			square_root_loop:
				add bx, 02h
				inc cx
				sub ax, bx
				cmp ax, 00h
				jg square_root_loop
			mov [ball_velocity_x], cx
		
		pop cx
		pop bx
		pop ax
		ret
	endp calculate_ball_x_new_velocity
	
	
	proc caentral_the_ball
		push ax
		mov ax, [x_center]
		mov [ball_x], ax
		mov ax, [y_center]
		mov [ball_y], ax
		mov [ball_velocity_y], 06h
		cmp [ball_velocity_x], 00h
		jl neg_x
		mov [ball_velocity_x], 05h
		jmp end_central
		neg_x:
			mov [ball_velocity_x], -05h
		end_central:
			pop ax
			ret	
	endp caentral_the_ball
	
	proc clear_the_screen
		push ax
		push bx
		push dx
		
		mov ah, 06h
		mov al, 00h
		mov cx, 00h
		mov dl, 4Fh
		mov dh, 18h
		mov bh, 00h ;set the color
		int 10h
		
		pop dx
		pop bx
		pop ax
		ret
	endp clear_the_screen

	BallX equ [bp+4]
	BallY equ [bp+6]
	BallSize equ [bp+8]
	proc draw_ball
		push bp
		mov bp, sp

		mov cx, BallSize ;inner for loop counter
		mov si, BallSize ; outer for loop counter
		mov ax, BallX ; cols index
		push ax
		;creating nested for loop to draw the ball as matrix of pixels ;
		drawRows:
			cmp si, 00h
			jbe finish
			
			drawCols:
				push cx
				mov ah, 0ch ;writing a pixel configuration
				mov al, 02h ;choosing the pixel color
				mov bh, 00h ;setting the page number
				mov cx, [word ptr bp-2] ;setting the X location of the pixel
				mov dx, ballY ; setting the y location of the pixel
				int 10h ; execute the pixel writing
				pop cx
				inc [word bp-2]
				loop drawCols
				
			mov cx, BallSize
			inc BallY
			dec si
			mov ax, BallX
			mov [bp-2], ax
			jmp drawRows
			
		finish:
		pop ax
		pop bp
		ret
	endp draw_ball 	
	
	RocketY equ [bp+4]
	RocketX equ [bp+6]
	RocketHeight equ [bp+8]
	RocketWidth equ [bp+10]
	proc draw_rocket
		push bp
		mov bp, sp
		
		mov ax, RocketX
		push ax
		mov cx, Rocketwidth
		mov si, RocketHeight
		;outer loop
		draw_height:
			cmp si, 00h
			jbe proc_end
			;inner loop
			draw_width:
				push cx
				mov ah, 0ch
				mov al, 0fh ;white pixel
				mov bh, 00h ;page number
				mov cx, [word ptr bp-2] ;x position
				mov dx, RocketY ;y position
				int 10h
				inc [word bp-2]
				pop cx
				loop draw_width
			mov ax, RocketX
			mov [word ptr bp-2], ax
			inc RocketY
			mov cx, Rocketwidth
			dec si
			jmp draw_height
		proc_end:
			pop ax
			pop bp
			ret
	endp draw_rocket
	
	proc draw_points
	;draw left scores
	;changing cruiser position using ah=02h int 10h
	mov ah, 02h	
	mov bh, 00h ;page number
	mov dl, [left_player_x_position]
	mov dh, [players_y_position]
	int 10h
	
	;print the character to the screen using ah=02h int 21h
	mov ah, 02h
	mov dl, [left_player_points]
	add dl, 30h
	int 21h
	
	;draw right scores
	;changing cruiser position using ah=02h int 10h
	mov ah, 02h
	mov bh, 00h
	mov dl, [right_player_x_position]
	mov dh, [players_y_position]
	int 10h
	
	;print the character to the screen using ah=02h int 21h
	mov ah, 02h
	mov dl, [right_player_points]
	add dl, 30h
	int 21h
	ret
	endp draw_points
	
	proc draw_menu
		;reserve the register state:
		push ax
		push bx
		push dx
		
		;position the cruiser
		mov ah, 02h
		mov bh, 00h
		mov dl, 0Ah
		mov dh, 09h
		int 10h
		
		;printing the menu
		mov ah, 09h
		lea dx, [two_players_game]
		int 21h
		
		;reposition the cruiser
		mov ah, 02h
		mov bh, 00h
		mov dl, 0Ah
		mov dh, 0Ch
		int 10h
		
		;continue printing the menu
		mov ah, 09h
		lea dx, [one_player_easy]
		int 21h
		
		;reposition the cruiser
		mov ah, 02h
		mov bh, 00h
		mov dl, 0Ah
		mov dh, 0Fh
		int 10h
		
		;continue printing the menu
		mov ah, 09h
		lea dx, [exit_game]
		int 21h
		
		;return the original register state
		pop dx
		pop bx
		pop ax
		ret
	endp draw_menu
	
	;--------------------------------------------------------------------
	; AI LOGIC FOR AUTOMAT COMPUTER PLAYING AGAIN HUMAN
	;--------------------------------------------------------------------
	
	
	;~~~ easy AI - simply follow the x coordinate ~~~;
	proc computer_moves_left_rocket
		
		mov ax, [left_rocket_y]
		cmp  ax, [ball_y]
		jl is_middle
		;moving the rocket one step up
		move_up:
			mov ax, [left_rocket_y]
			sub ax, [rocket_velocity]
			cmp ax, 00h
			jge update_vars
			jmp right_rocket_turn
		is_middle:
			mov ax, [rocket_height]
			mov bx, 02h
			div bl ;  al contains rocket_height/2
			xor ah,ah
			mov bx, [left_rocket_y]
			add bx, ax
			cmp bx, [ball_y]
			jl move_down_rocket
			cmp bx, [ball_y]
			je right_rocket_turn ;exactly in the middle
			jmp move_up
			move_down_rocket:
				mov ax, [left_rocket_y]
				add ax, [rocket_velocity]
				add ax, [rocket_height]
				cmp ax, [screen_height]
				jg right_rocket_turn
				sub ax, [rocket_height]
		;update r_rocket_variables:
		update_vars:
			mov [left_rocket_y], ax
			mov [l_rocket_maxY], ax
			add ax, [rocket_height]
			mov [l_rocket_minY], ax
		right_rocket_turn:
			ret
	endp computer_moves_left_rocket
	
	proc is_my_turn
		cmp [ball_velocity_x], 00h ;checking the direction of the ball
		jg not_my_turn
		mov [computer_turn], 01h
		ret
		not_my_turn:
			mov [computer_turn], 00h
			ret
	endp is_my_turn
	
	
	
	
	;--------------------------------------------------------------------
	; MAIN STARTS HERE
	;--------------------------------------------------------------------
	start:
	mov ax, @data
	mov ds, ax
	
	call set_video_mode
	call draw_menu
	reading_menu:
		;check if any key was pressed:
		mov ah, 01h
		int 16h
		jz reading_menu

		mov ah, 00h ;reading keyboard character
		int 16h
		cmp al, 'P'
		je two_players_playing
		cmp al, 'p'
		je two_players_playing
		cmp al, 'R'
		je computer_vs_player
		cmp al, 'r'
		je computer_vs_player
		cmp al, 'Q'
		je exit
		cmp al, 'q'
		je exit
		jmp reading_menu
	
	;two players
	two_players_playing:
		;get initial system time
		call get_system_time
		mov [time_aux], dl
		
		timeChecksLoop:
			call get_system_time
			cmp [time_aux],dl
			je timeChecksLoop
			mov [time_aux], dl

			call clear_the_screen
			
			call move_either_rocket
			
			;drawing right rocket
			mov bx, [rocket_width]
			push bx
			mov bx, [rocket_height]
			push bx
			mov bx, [right_rocket_x]
			push bx
			mov bx, [right_rocket_y]
			push bx
			call draw_rocket
			pop bx
			pop bx
			pop bx
			pop bx
			;drawing left rocket
			mov bx, [rocket_width]
			push bx
			mov bx, [rocket_height]
			push bx
			mov bx, [left_rocket_x]
			push bx
			mov bx, [left_rocket_y]
			push bx
			call draw_rocket
			pop bx
			pop bx
			pop bx
			pop bx
			
			call move_the_ball
			
			;draw the ball
			mov bx, [ball_size]
			push bx
			mov bx, [ball_y]
			push bx
			mov bx, [ball_x]
			push bx
			call draw_ball
			pop bx
			pop bx
			pop bx
			
			call draw_points
			jmp timeChecksLoop
			
		exit:
			jmp exit_pong
		;~~~~~~~~~~~~~~~~~~~~~~~~~~;
		;player VS computer
		;~~~~~~~~~~~~~~~~~~~~~~~~~~;
		
		computer_vs_player:
			;get initial system time
			call get_system_time
			mov [time_aux], dl
		
			timeLoop:
				call get_system_time
				cmp [time_aux],dl
				je timeLoop
				mov [time_aux], dl

				call clear_the_screen
				;CHECK IF ANY KEY WAS PRESSED
				mov ah, 01h
				int 16h
				jz LEFT_ROCKET ;if zf == 0 -> no key has been pressed
				;check which key has been pressed
				mov ah, 00h
				int 16h
				call move_right_rocket
				LEFT_ROCKET:
					call is_my_turn
					cmp [computer_turn], 01h
					jne drawing
					call computer_moves_left_rocket	
				drawing:
				;drawing right rocket
				mov bx, [rocket_width]
				push bx
				mov bx, [rocket_height]
				push bx
				mov bx, [right_rocket_x]
				push bx
				mov bx, [right_rocket_y]
				push bx
				call draw_rocket
				pop bx
				pop bx
				pop bx
				pop bx
				;drawing left rocket
					mov bx, [rocket_width]
					push bx
					mov bx, [rocket_height]
					push bx
					mov bx, [left_rocket_x]
					push bx
					mov bx, [left_rocket_y]
					push bx
					call draw_rocket
					pop bx
					pop bx
					pop bx
					pop bx
				
				call move_the_ball
				
				;draw the ball
				mov bx, [ball_size]
				push bx
				mov bx, [ball_y]
				push bx
				mov bx, [ball_x]
				push bx
				call draw_ball
				pop bx
				pop bx
				pop bx
				
				call draw_points
				jmp timeLoop
		
		
	exit_pong:
		;return to text mode
		mov ah,00h
		mov al, 2h
		int 10h
		
		;safe exit
		mov ax, 4c00h
		int 21h
	end start	
		
	
