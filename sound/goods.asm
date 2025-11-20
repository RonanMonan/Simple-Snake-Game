; --- ADDED MORE COORDINATES ---
    food_xs     dw  140, 560, 340, 380, 440, 450, 400, 90, 90, 550
                dw  120, 160, 180, 220, 240, 260, 480, 520, 580, 600
    food_ys     dw  140, 60, 30, 30, 110, 80, 100, 90, 300, 240
                dw  40, 80, 120, 160, 200, 220, 260, 280, 310, 330
    
    ; --- food_found IS REMOVED ---

    ; --- ADDED MORE COORDINATES ---
    pois_xs     dw  50, 110, 70, 200, 300, 400, 500, 250, 350, 450
    pois_ys     dw  80, 110, 130, 100, 150, 200, 250, 280, 300, 50
    pois_found  dw  10 dup(0) ; <--- INCREASED SIZE

    food_color      db  14
    pois_color      db  5


; --- MODIFIED food_check PROCEDURE ---
food_check proc near

    push    ax
    push    bx
    push    cx
    push    dx

    mov     bx, 0

@@checking_loop:
    cmp     bx, [food_count]
    je      @@exit
    mov     cx, food_xs[bx]
    mov     dx, food_ys[bx]
    cmp     cx, head_x
    jne     @@continue
    cmp     dx, head_y
    jne     @@continue

    ; --- FOOD FOUND ---
    mov     cx, score
    add     cx, 1
    mov     score, cx
    
    call    food_beep
    
    mov     cx, food_xs[bx] ; Save old coords for lengthen
    mov     dx, food_ys[bx]
    
    call    update_coords   ; Update snake arrays first
    call    lengthen        ; Lengthen snake
    call    regenerate_food ; bx still holds the index

@@continue:
    add     bx, 2
    jmp     @@checking_loop

@@exit:

    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ret

food_check endp


; --- MODIFIED pois_check PROCEDURE ---
pois_check proc near

    push    ax
    push    bx
    push    cx
    push    dx

    mov     bx, 0

@@checking_loop:
    cmp     bx, [pois_count]
    je      @@exit
    mov     cx, pois_xs[bx]
    mov     dx, pois_ys[bx]
    cmp     cx, head_x
    jne     @@continue
    cmp     dx, head_y
    jne     @@continue
    mov     ax, 0
    cmp     pois_found[bx], ax
    je      @@found
@@continue:
    add     bx, 2
    jmp     @@checking_loop

@@found:
    call    pois_beep
    call    game_over   ; <--- CHANGED TO GAME OVER
    ; --- All other logic removed ---

@@exit:

    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ret

pois_check endp


; --- NEW regenerate_food PROCEDURE ---
regenerate_food proc near
    ; Assumes BX holds the index of the food to regenerate
    push    ax
    push    cx
    push    dx
    push    si ; Use si for snake check

@@get_coords:
    ; Get Random X (10-620)
    mov     ah, 0
    int     1Ah     ; Get timer tick in DX
    mov     ax, dx
    xor     dx, dx
    mov     cx, 62  ; (630-10) / 10 = 62
    div     cx      ; Remainder in DX (0-61)
    mov     ax, dx
    mov     dx, 10
    mul     dx      ; AX = 0-610
    add     ax, 10  ; AX = 10-620
    push    ax      ; Save new X coord

    ; Get Random Y (30-330)
    mov     ah, 0
    int     1Ah     ; Get timer tick again
    mov     ax, dx
    xor     dx, dx
    mov     cx, 31  ; (340-30) / 10 = 31
    div     cx      ; Remainder in DX (0-30)
    mov     ax, dx
    mov     dx, 10
    mul     dx      ; AX = 0-300
    add     ax, 30  ; AX = 30-330
    push    ax      ; Save new Y coord

    ; --- Check for collision with snake ---
    pop     dx      ; DX = new Y
    pop     cx      ; CX = new X
    mov     si, 0   ; Snake index

@@snake_check_loop:
    cmp     si, [curr_len]
    je      @@coords_ok ; End of snake, no collision
    
    cmp     cx, snake_xs[si]
    jne     @@next_segment
    cmp     dx, snake_ys[si]
    jne     @@next_segment
    
    ; Collision found! Get new coords
    jmp     @@get_coords

@@next_segment:
    add     si, 2
    jmp     @@snake_check_loop

@@coords_ok:
    ; New coords are in CX, DX. Index is in BX.
    mov     food_xs[bx], cx
    mov     food_ys[bx], dx

    ; Draw the new food item
    mov     al, food_color
    call    draw_cell

    pop     si
    pop     dx
    pop     cx
    pop     ax
    ret
regenerate_food endp