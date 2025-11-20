handle_keyboard proc near
@@check:
    ; check if no keys
    mov ah, 01h
    int 16h
    jz @@exit
    call key_beep
    xor ax, ax
    int 16h
	
; move down
@@maybe_down:          
    cmp ah, 50h        
    jne @@maybe_up      
    call change_dir_down
    jmp @@check

; move up
@@maybe_up:          
    cmp ah, 48h       
    jne @@maybe_left    
    call change_dir_up
    jmp @@check
	
; move left
@@maybe_left:          
    cmp ah, 4Bh         
    jne @@maybe_right  
    call change_dir_left
    jmp @@check
	
; move right
@@maybe_right:       
    cmp ah, 4Dh         
    jne @@maybe_p
    call change_dir_right
    jmp @@check
	
; pauses the game
@@maybe_p:
    ; p is for pause
    cmp ah, 19h
    jne @@maybe_space
    call pause
    jmp @@check
	
; show help menu
@@maybe_space:
    ; space is for help
    cmp ah, 39h
    jne @@maybe_plus
    call show_help
    jmp @@check
	
; increase the speed of the snake
@@maybe_plus:
    cmp ah, 0dh
    jne @@maybe_minus
    call inc_speed
    jmp @@check
	
; decrease the speed of the snake
@@maybe_minus:
    cmp ah, 0ch
    jne @@maybe_Cc
    call dec_speed
    jmp @@check
	
; quit the game
@@maybe_Cc:
    cmp ah, 2eh
    jne @@check
    call restore_mode_n_page
    call quit
@@exit:
    ret
handle_keyboard endp