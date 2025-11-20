

parse_args proc near

    xor     dx, dx
    mov     si, 80h
    lodsb

@@arg_processing:
    lodsb

    cmp     al, 9h
    je      @@skip_space
    cmp     al, 20h
    je      @@skip_space

    cmp     al, 2dh
    je      @@key_found
    cmp     al, 2fh
    je      @@key_found

    ret

@@skip_space:
    loop    @@arg_processing

@@key_found:
    lodsb

    cmp     al, 43h ; C: snake color
    jne     @@next_1
    call    set_snake_color

@@next_1:
    cmp     al, 63h ; c: snake color
    jne     @@next_2
    call    set_snake_color

@@next_2:
    cmp     al, 48h ; H: help
    jne     @@next_3
    call    show_help_and_quit

@@next_3:
    cmp     al, 68h ; h: help
    jne     @@next_4
    call    show_help_and_quit

@@next_4:
    cmp     al, 44h ; D: die
    jne     @@next_5
    call    set_die_on_cut

@@next_5:
    cmp     al, 64h ; d: die
    jne     @@next_6
    call    set_die_on_cut

@@next_6:
    cmp     al, 4ch ; L: len
    jne     @@next_7
    call    set_len

@@next_7:
    cmp     al, 6ch ; l: len
    jne     @@next_8
    call    set_len

@@next_8:
    cmp     al, 46h ; F: food
    jne     @@next_9
    call    set_food_count

@@next_9:
    cmp     al, 66h ; f: food
    jne     @@next_l
    call    set_food_count

@@next_l:
    loop    @@arg_processing

    ret

parse_args endp


show_help_and_quit proc near

    mov     ah, 9
    lea     dx, cli_help_msg
    int     21h
    int     20h

show_help_and_quit endp