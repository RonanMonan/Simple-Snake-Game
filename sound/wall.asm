

draw_top_wall proc near

    mov     al, wall_color

    mov     bx, 0
    mov     dx, 20
@@draw_block:
    mov     cx, bx

    call    draw_cell

    add     bx, 10

    cmp     bx, 640
    jne     @@draw_block

    ret

draw_top_wall endp


draw_bottom_wall proc near

    mov     al, wall_color

    mov     bx, 0
    mov     dx, 340
@@draw_block:
    mov     cx, bx

    call    draw_cell

    add     bx, 10

    cmp     bx, 640
    jne     @@draw_block

    ret

draw_bottom_wall endp


draw_left_wall proc near

    mov     al, wall_color

    mov     bx, 20
    mov     cx, 0
@@draw_block:
    mov     dx, bx

    call    draw_cell

    add     bx, 10

    cmp     bx, 340
    jne     @@draw_block

    ret

draw_left_wall endp


draw_right_wall proc near

    mov     al, wall_color

    mov     bx, 20
    mov     cx, 630
@@draw_block:
    mov     dx, bx

    call    draw_cell

    add     bx, 10

    cmp     bx, 340
    jne     @@draw_block

    ret

draw_right_wall endp


wall_check proc near

    cmp     cx, 0
    je      @@game_over

    cmp     cx, 630
    je      @@game_over

    cmp     dx, 20
    je      @@game_over

    cmp     dx, 340
    je      @@game_over

    jmp     @@exit

@@game_over:
    call    game_over

@@exit:
    ret

wall_check endp