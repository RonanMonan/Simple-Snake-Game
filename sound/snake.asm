.model tiny
locals
.386


.data

    max_len     equ  100
    curr_len    dw  2

    score       dw  0

    ; --- HIGHSCORE VARS ---
    highscore   dw  0
    filename    db  "HISCORE.DAT", 0
    file_handle dw  ?
    hiscore_msg db  "Hi-Score: ", 0dh, 0ah, 24h
    ; --- END HIGHSCORE VARS ---

    ; --- LOGIN/REGISTER VARS ---
    login_title_msg db  "SNAKE - v1.0", 0dh, 0ah
                    db  "=============", 0dh, 0ah, 0ah, 24h
    menu_msg        db  "1. Login", 0dh, 0ah
                    db  "2. Register", 0dh, 0ah
                    db  "3. Quit", 0dh, 0ah, 0ah
                    db  "Select an option: ", 24h
    login_prompt    db  "--- Login ---", 0dh, 0ah, 0ah, 24h
    reg_prompt      db  "--- Register ---", 0dh, 0ah, 0ah, 24h
    user_prompt     db  "Username: ", 24h
    pass_prompt     db  "Password: ", 24h
    
    login_fail_msg  db  0ah, 0dh, "Login failed. Invalid username or password.", 0dh, 0ah, 24h
    login_success_msg db 0ah, 0dh, "Login successful! Starting game...", 0dh, 0ah, 24h
    reg_success_msg db  0ah, 0dh, "Registration complete! You may now log in.", 0dh, 0ah, 24h
    reg_fail_msg    db  0ah, 0dh, "Error: Could not create user file.", 0dh, 0ah, 24h
    any_key_msg     db  0dh, 0ah, "Press any key to continue...", 24h
    
    ; Buffers for text input
    user_buffer     db  21      ; Max 20 chars
                    db  ?       ; Actual
                    db  21 dup(?)
    pass_buffer     db  21      ; Max 20 chars
                    db  ?       ; Actual
                    db  21 dup(?)
                    
    ; File I/O vars
    users_filename  db  "USERS.DAT", 0
    record_buffer   db  40 dup(0)       ; 20 bytes for user, 20 for pass
    ; --- END LOGIN VARS ---

    food_count  dw  20  ; <--- INCREASED
    pois_count  dw  10  ; <--- INCREASED

    start_head_x    equ  100
    start_head_y    equ  120

    snake_xs    dw  max_len*2 dup(start_head_x)
    snake_ys    dw  max_len*2 dup(start_head_y)


    head_x      dw  ?
    head_y      dw  ?

    tail_x      dw  ?
    tail_y      dw  ?

    head_dx     dw  1
    head_dy     dw  0

    cell_size       dw  10

    body_color      db  ?
    head_color      db  ?
    snake_color     db  10
    text_color      db  15
    wall_color      db  8

    delay           dd  100000
    min_delay       dd  49000
    max_delay       dd  1200000

    die_on_cut      db  0

    game_over_msg   db  "GAME OVER", 0dh, 0ah, 24h
    pause_msg       db  "PAUSE", 0dh, 0ah, 24h
    score_msg       db  "Score: ", 0dh, 0ah, 24h

    cli_help_msg    db  "snake.com [/c N] [/l N] [/f N] [/h]", 0dh, 0ah
                    db  "    ---------------------------    ", 0dh, 0ah
                    db  " /c is for color:  0-f ", 0dh, 0ah
                    db  " /l is for length: 2-9 ", 0dh, 0ah
                    db  " /f is for food:   1-9 ", 0dh, 0ah
                    db  " /h is for help ", 0dh, 0ah, 24h

    help_msg        db  "                           →    ←    ↓    ↑     ", 0dh, 0ah
                    db  "                           right  left   down   up    ", 0dh, 0ah
                    db  "                          --------------------------- ", 0dh, 0ah
                    db  "                             - slower     faster +    ", 0dh, 0ah
                    db  "                          --------------------------- ", 0dh, 0ah
                    db  "                            p pause       quit <C+c>  ", 0dh, 0ah, 24h


.code

    org 100h

start:
    jmp     main
    include argparse.asm
    include goods.asm
    include graphics.asm
    include keyboard.asm
    include sound.asm
    include wall.asm
    include login.asm     ; <--- INCLUDE LOGIN FILE

main:
    call    parse_args
    call    login_menu          ; <--- CALL LOGIN SYSTEM FIRST
    
    ; --- Only run this if login was successful ---
    call    store_mode_n_page
    call    set_mode_n_page
    call    read_highscore    

    call    prepare_map
    call    prepare_goods
    call    prepare_snake
    call    main_loop

    call    game_over

main_loop proc near

@@game_loop:
    call    handle_keyboard
    call    move_snake
    call    show_score
    call    wait_delay      ; <--- Renamed from 'wait'
    jmp     @@game_loop

    ret

main_loop endp

; Sets up the snake’s starting position.
init_snake proc near

    mov    head_x, start_head_x
    mov    head_y, start_head_y
    mov    bx, 0

@@fill:
    cmp    bx, curr_len
    je     @@exit
    mov    dx, snake_ys[bx]
    add    dx, [cell_size]
    add    bx, 2
    mov    snake_ys[bx], dx
    jmp    @@fill

@@exit:
    ret

init_snake endp

; Draws the walls.
prepare_map proc near

    call    draw_top_wall
    call    draw_bottom_wall
    call    draw_left_wall
    call    draw_right_wall

    ret

prepare_map endp

; Sets snake colors and draws it.
prepare_snake proc near

    mov     cl, snake_color
    sub     cl, 2
    mov     head_color, cl
    sub     cl, 7fh
    mov     body_color, cl

    call    init_snake
    call    draw_snake

    ret

prepare_snake endp

; Draws food/poison.
prepare_goods proc near

    call    draw_food
    call    draw_pois

    ret

prepare_goods endp

; Moves the snake by updating coordinates.
move_snake proc near

    call    empty_tail
    call    update_coords
    call    draw_snake
    call    step_beep

    ret

move_snake endp

; 
update_coords proc near

    call    update_head
    call    update_array
    call    update_tail

    ret

update_coords endp

; Logic for how the snake moves.
update_head proc near

    push    ax
    push    bx
    push    cx
    push    dx

    mov     cx, head_x
    mov     bx, cell_size
    mov     ax, head_dx
    imul    bl
    add     cx, ax
    mov     head_x, cx

    mov     cx, head_y
    mov     bx, cell_size
    mov     ax, head_dy
    imul    bl
    add     cx, ax
    mov     head_y, cx

    mov     cx, head_x
    mov     dx, head_y
    call    wall_check
    call    cut_check
    call    food_check
    call    pois_check

    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ret

update_head endp

; Logic for how the snake moves.
update_array proc near

    push    ax
    push    bx
    push    cx
    push    dx

    mov     bx, curr_len

@@filling_loop:
    cmp     bx, 0
    je      @@write_head
    sub     bx, 2
    mov     cx, snake_xs[bx]
    mov     dx, snake_ys[bx]
    add     bx, 2
    mov     snake_xs[bx], cx
    mov     snake_ys[bx], dx
    sub     bx, 2
    jmp     @@filling_loop

@@write_head:
    mov     cx, head_x
    mov     dx, head_y

    mov     bx, 0
    mov     snake_xs[bx], cx
    mov     snake_ys[bx], dx

    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ret

update_array endp

; Logic for how the snake moves.
update_tail proc near

    push    bx
    push    cx
    push    dx

    mov     bx, curr_len
    mov     cx, snake_xs[bx]
    mov     dx, snake_ys[bx]

    mov     tail_x, cx
    mov     tail_y, dx

    pop     dx
    pop     cx
    pop     bx

    ret

update_tail endp


cut_check proc near

    push    ax
    push    bx
    push    cx
    push    dx

    mov     bx, 2

@@checking_loop:
    cmp     bx, [curr_len]
    je      @@exit
    mov     cx, snake_xs[bx]
    mov     dx, snake_ys[bx]
    cmp     cx, head_x
    jne     @@continue
    cmp     dx, head_y
    je      @@cut
@@continue:
    add     bx, 2
    jmp     @@checking_loop

@@cut:
    cmp     die_on_cut, 1
    je      @@die
    push    bx
@@cutting_loop:
    cmp     bx, [curr_len]
    je      @@stop_cutting
    mov     cx, snake_xs[bx]
    mov     dx, snake_ys[bx]
    call    empty_cell
    add     bx, 2
    jmp     @@cutting_loop
@@stop_cutting:
    pop     bx
    cmp     bx, 2
    je      @@die
    mov     curr_len, bx

@@exit:

    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ret

@@die:
    call    game_over

cut_check endp


lengthen proc near

    push    ax
    push    bx
    push    cx
    push    dx

    mov     bx, 0
    mov     snake_xs[bx], cx
    mov     snake_ys[bx], dx

    mov     head_x, cx
    mov     head_y, dx

    call    update_head

    mov     ax, curr_len
    add     ax, 2
    mov     curr_len, ax

    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ret

lengthen endp


shorten proc near

    push    bx

    cmp     curr_len, 1
    jnz     @@continue
    call    game_over

@@continue:
    mov     bx, curr_len
    sub     bx, 2
    mov     curr_len, bx

    pop     bx

    ret

shorten endp


draw_snake proc near

    push    bx
    push    cx
    push    dx

    mov     bx, 0

@@drawing_loop:
    cmp     bx, [curr_len]
    je      @@exit
    mov     cx, snake_xs[bx]
    mov     dx, snake_ys[bx]
    mov     al, snake_color
    call    draw_body
    add     bx, 2
    jmp     @@drawing_loop

@@exit:
    mov     cx, snake_xs[0]
    mov     dx, snake_ys[0]
    call    draw_head

    pop     dx
    pop     cx
    pop     bx

    ret

draw_snake endp


empty_tail proc near

    mov     cx, tail_x
    mov     dx, tail_y
    call    empty_cell

    ret

empty_tail endp


set_snake_color proc near

    lodsb
    lodsb

    mov     snake_color, al

    ret

set_snake_color endp


inc_speed proc near

    mov     dx, word ptr delay+2
    shr     dx, 1
    cmp     dx, word ptr min_delay+2
    jle     @@exit
    mov     word ptr delay+2, dx

@@exit:
    ret

inc_speed endp


dec_speed proc near

    mov     dx, word ptr delay+2
    shl     dx, 1
    cmp     dx, word ptr max_delay+2
    jge     @@exit
    mov     word ptr delay+2, dx

@@exit:
    ret

dec_speed endp


set_die_on_cut proc near

    push    ax

    mov     al, 0
    mov     die_on_cut, al

    pop     ax

    ret

set_die_on_cut endp


set_food_count proc near

    push    ax

    lodsb
    lodsb

    sub     al, 30h
    shl     al, 1
    xor     ah, ah
    mov     food_count, ax

    pop     ax

    ret

set_food_count endp


set_len proc near

    push    ax

    lodsb
    lodsb

    sub     al, 30h
    xor     ah, ah
    shl     al, 1
    sub     al, 2
    mov     curr_len, ax

    pop     ax

    ret

set_len endp


change_dir_down proc near

    push    ax

    mov     ax, 1
    add     ax, head_dy
    test    ax, ax
    jnz     @@change_dir
    call    game_over

@@change_dir:
    ; head_dx = 0 && head_dy = 1
    mov     head_dx, 0
    mov     head_dy, 1

    pop     ax

    ret

change_dir_down endp


change_dir_up proc near

    push    ax

    mov     ax, -1
    add     ax, head_dy
    test    ax, ax
    jnz     @@change_dir
    call    game_over

@@change_dir:
    ; head_dx = 0 && head_dy = -1
    mov     head_dx, 0
    mov     head_dy, -1

    pop     ax

    ret

change_dir_up endp


change_dir_right proc near

    push    ax

    mov     ax, 1
    add     ax, head_dx
    test    ax, ax
    jnz     @@change_dir
    call    game_over

@@change_dir:
    ; head_dx = 1 && head_dy = 0
    mov     head_dx, 1
    mov     head_dy, 0

    pop     ax

    ret

change_dir_right endp


change_dir_left proc near

    push    ax

    mov     ax, -1
    add     ax, head_dx
    test    ax, ax
    jnz     @@change_dir
    call    game_over


@@change_dir:
    ; head_dx = -1 && head_dy = 0
    mov     head_dx, -1
    mov     head_dy, 0

    pop     ax

    ret

change_dir_left endp


pause proc near

    mov     dh, 12
    lea     bp, pause_msg
    mov     cx, 5

    mov     ah, 0fh
    int     10h

    sub     ah, cl
    shr     ax, 8
    mov     bl, 2
    div     bl
    mov     dl, al

    mov     bh, curr_page
    mov     bl, text_color
    mov     al, 1
    mov     ah, 13h
    int     10h

    call    pause_beep

    call    wait_for_key

    mov     cx, 280
    mov     dx, 170
@@erase_text:
    cmp     cx, 360
    jge     @@continue
    call    empty_cell
    add     cx, 10
    jmp     @@erase_text

@@continue:
    call    draw_snake

    ret

pause endp


show_help proc near

    mov     dl, 0
    mov     dh, 8
    lea     bp, help_msg
    mov     cx, 332

    mov     ah, 0fh
    int     10h

    mov     ah, 05h
    mov     al, 1
    int     10h

    mov     bh, 1
    mov     bl, text_color
    mov     al, 1
    mov     ah, 13h
    int     10h

    call    wait_for_key

    mov     ah, 05h
    mov     al, curr_page
    int     10h

    ret

show_help endp


game_over proc near

    ; --- NEW HIGHSCORE CHECK ---
    mov     ax, score
    cmp     ax, highscore
    jle     @@skip_save     ; Jump if score is not higher
    
    mov     highscore, ax   ; New high score!
    call    save_highscore  ; Save it to the file
@@skip_save:
    ; --- END NEW CHECK ---

    mov     dh, 12
    lea     bp, game_over_msg
    mov     cx, 9

    mov     ah, 0fh
    int     10h

    sub     ah, cl
    shr     ax, 8
    mov     bl, 2
    div     bl
    mov     dl, al

    mov     bh, curr_page
    mov     bl, text_color
    mov     al, 1
    mov     ah, 13h
    int     10h

    call    game_over_beep

    call    wait_for_key

    call    restore_mode_n_page
    call    quit

    ret

game_over endp


; --- MODIFIED show_score PROCEDURE ---
show_score proc near
    push    ax
    push    bx
    push    cx
    push    dx

    ; --- Show "Hi-Score: " ---
    mov     dl, 0
    mov     dh, 0           ; Top line (row 0)
    lea     bp, hiscore_msg
    mov     cx, 10          ; Length of "Hi-Score: "
    mov     bh, 0
    mov     bl, text_color
    mov     al, 1
    mov     ah, 13h
    int     10h
    
    ; --- Show the highscore value ---
    mov     ax, highscore
    mov     cl, 0
    mov     bl, 10

@@1_hs:
    inc     cl
    mov     ah, 0
    div     bl
    mov     dl, ah
    push    dx
    cmp     al, 0
    jne     @@1_hs

@@2_hs:
    dec     cl
    pop     dx
    push    cx
    mov     al, dl
    add     al, 30h
    mov     ah, 09h
    mov     bh, 0
    mov     cx, 1
    mov     bl, text_color
    int     10h

    mov     ah, 03h
    mov     bh, 0
    int     10h
    inc     dl
    mov     ah, 02h
    int     10h
    pop     cx
    cmp     cl, 0
    jne     @@2_hs


    ; --- Show "Score: " ---
    mov     dl, 0
    mov     dh, 1           ; Second line (row 1)
    lea     bp, score_msg
    mov     cx, 7           ; Length of "Score: "
    mov     bh, 0
    mov     bl, text_color
    mov     al, 1
    mov     ah, 13h
    int     10h

    ; --- Show the current score value ---
    mov     ax, score
    mov     cl, 0
    mov     bl, 10

@@1:
    inc     cl
    mov     ah, 0
    div     bl
    mov     dl, ah
    push    dx
    cmp     al, 0
    jne     @@1

@@2:
    dec     cl
    pop     dx
    push    cx
    mov     al, dl
    add     al, 30h
    mov     ah, 09h
    mov     bh, 0
    mov     cx, 1
    mov     bl, text_color
    int     10h

    mov     ah, 03h
    mov     bh, 0
    int     10h
    inc     dl
    mov     ah, 02h
    int     10h
    pop     cx
    cmp     cl, 0
    jne     @@2

    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ret
show_score endp
; --- END MODIFIED show_score ---


; --- RENAMED 'wait' to 'wait_delay' ---
wait_delay proc near

    mov     ax, 8600h
    mov     cx, word ptr delay+2
    mov     dx, word ptr delay
    int     15h

    ret

wait_delay endp


wait_for_key proc near

    mov     ah, 8
    int     21h

    ret

wait_for_key endp


; --- FILE I/O PROCEDURES ---
read_highscore proc near
    push    ax
    push    bx
    push    dx

    ; Open the file (ah=3Dh) in read-only mode (al=0)
    mov     ah, 3Dh
    mov     al, 0
    lea     dx, filename
    int     21h
    
    jc      @@no_file       ; Jump if error (e.g., file not found)
    mov     file_handle, ax ; Store the file handle

    ; Read 2 bytes (size of dw) from the file (ah=3Fh)
    mov     ah, 3Fh
    mov     bx, file_handle
    mov     cx, 2           ; Read 2 bytes
    lea     dx, highscore   ; Store data in our 'highscore' variable
    int     21h

    ; Close the file (ah=3Eh)
    mov     ah, 3Eh
    mov     bx, file_handle
    int     21h

@@no_file:
    pop     dx
    pop     bx
    pop     ax
    ret
read_highscore endp


save_highscore proc near
    push    ax
    push    bx
    push    cx
    push    dx

    ; Create/Overwrite the file (ah=3Ch)
    mov     ah, 3Ch
    mov     cx, 0           ; Normal file attribute
    lea     dx, filename
    int     21h

    jc      @@save_error    ; Jump if error
    mov     file_handle, ax ; Store new file handle

    ; Write 2 bytes (ah=40h) to the file
    mov     ah, 40h
    mov     bx, file_handle
    mov     cx, 2           ; Write 2 bytes
    lea     dx, highscore   ; Write the value from 'highscore'
    int     21h

    ; Close the file (ah=3Eh)
    mov     ah, 3Eh
    mov     bx, file_handle
    int     21h

@@save_error:
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
save_highscore endp
; --- END FILE I/O PROCEDURES ---


quit proc near

   int      20h

quit endp


end start