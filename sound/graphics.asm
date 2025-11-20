old_mode        db  ?
old_page        db  ?

curr_mode       db  10h
curr_page       db  0

end_x           dw  ?
end_y           dw  ?

; Saves the current screen mode and video page (so it can be restored later).
store_mode_n_page proc near

    mov     ah, 0fh
    int     10h
    mov     old_mode, al

    mov     ah, 0fh
    int     10h
    mov     old_page, bh

    ret

store_mode_n_page endp

; Sets the video mode to graphics mode (13h or 10h).
set_mode_n_page proc near

    mov     ah, 0
    mov     al, curr_mode
    int     10h

    mov     ah, 5
    mov     al, curr_page
    int     10h

    ret

set_mode_n_page endp

; Switches back to the original text mode when the game ends.
restore_mode_n_page proc near

    mov     dl, 0
    mov     ah, 02h
    int     10h

    mov     al, old_mode
    mov     ah, 0
    int     10h

    mov     al, old_page
    mov     ah, 05h
    int     10h

    ret

restore_mode_n_page endp

; Draws a single pixel at (CX, DX) using color in AL.
draw_pixel proc near

    push    ax
    push    bx

    mov     ah, 0ch
    mov     bh, curr_page
    int     10h

    pop     bx
    pop     ax

    ret

draw_pixel endp

; Draws a square block (a group of pixels). This is how the snake and food are drawn.
draw_cell proc near

    push    ax
    push    bx
    push    cx
    push    dx

    mov		bx, [cell_size]
    add		bx, cx
    mov 	[end_x], bx

    mov		bx, [cell_size]
    add		bx, dx
    mov 	[end_y], bx

    push	cx

set_cx:
    pop		cx
    push	cx

filling_loop:
    call	draw_pixel

    inc		cx
    mov		bx, [end_x]
    cmp		cx, bx
    jne		filling_loop

    inc		dx
    mov		bx, [end_y]
    cmp		dx, bx
    jne		set_cx

    pop		cx

    pop     dx
    pop     cx
    pop     bx
    pop     ax

    ret

draw_cell endp

; Special versions of draw_cell for the snake’s head and body.
draw_head proc near

    push    bx
    push    cx
    push    dx

    mov     al, snake_color
    call    draw_cell

    mov     bx, 8
    mov     cell_size, bx
    mov     al, head_color
    add     cx, 1
    add     dx, 1
    call    draw_cell

    mov     bx, 10
    mov     cell_size, bx

    pop     dx
    pop     cx
    pop     bx

    ret

draw_head endp

; Special versions of draw_cell for the snake’s head and body.
draw_body proc near

    push    bx
    push    cx
    push    dx

    mov     al, snake_color
    call    draw_cell

    mov     bx, 4
    mov     cell_size, bx
    mov     al, body_color
    add     cx, 3
    add     dx, 3
    call    draw_cell

    mov     bx, 10
    mov     cell_size, bx

    pop     dx
    pop     cx
    pop     bx

    ret

draw_body endp


; Loops through arrays of food or poison coordinates and draws them.
draw_food proc near

    push    bx
    push    cx
    push    dx

    mov     bx, 0

@@drawing_loop:
    cmp     bx, [food_count]
    je      @@exit


    mov     cx, food_xs[bx]
    mov     dx, food_ys[bx]
    mov     al, food_color
    call    draw_cell
    add     bx, 2
    jmp     @@drawing_loop


@@exit:

    pop     dx
    pop     cx
    pop     bx

    ret

draw_food endp

; Loops through arrays of food or poison coordinates and draws them.
draw_pois proc near

    push    bx
    push    cx
    push    dx

    mov     bx, 0

@@drawing_loop:
    cmp     bx, [pois_count]
    je      @@exit
    mov     cx, pois_xs[bx]
    mov     dx, pois_ys[bx]
    mov     al, pois_color
    call    draw_cell
    add     bx, 2
    jmp     @@drawing_loop

@@exit:

    pop     dx
    pop     cx
    pop     bx

    ret

draw_pois endp

; Draws a black cell (used when erasing part of the snake).
empty_cell proc near

    push    ax

    mov     al, 0
    call    draw_cell

    pop     ax

    ret

empty_cell endp