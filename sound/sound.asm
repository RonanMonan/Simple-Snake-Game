

food_beep proc near

    mov     ah, 07h
    call    beep

    ret

food_beep endp


pois_beep proc near

    mov     ah, 01h
    call    long_beep

    ret

pois_beep endp


key_beep proc near

    mov     ah, 11h
    call    beep

    ret

key_beep endp


step_beep proc near

    mov     ah, 10h
    call    beep

    ret

step_beep endp


pause_beep proc near

    mov     ah, 10h
    call    beep

    mov     ah, 10h
    call    beep

    mov     ah, 09h
    call    long_beep

    mov     ah, 09h
    call    beep

    ret

pause_beep endp


game_over_beep proc near

    mov     ah, 09h
    call    long_beep

    mov     ah, 11h
    call    long_beep

    mov     ah, 12h
    call    long_beep

game_over_beep endp


beep proc near

    call    turn_on

    mov     cx, 800
    call    set_freq

    call    turn_off

    ret

beep endp


long_beep proc near

    call    turn_on

    mov     cx, 9600
    call    set_freq

    call    turn_off

    ret

long_beep endp


set_freq proc near

    push    ax
    push    bx
    push    cx

    mov     bx, ax

    mov     al, 182
    out     43h, al

    mov     ax, bx

    out     42h, al
    mov     al, ah
    out     42h, al

    mov     bx, 25

@@pause1:
    pop     cx
    push    cx

@@pause2:
    dec     cx
    jne     @@pause2
    dec     bx
    jne     @@pause1

    pop     cx
    pop     bx
    pop     ax

    ret

set_freq endp


turn_on proc near

    push    ax
    in      al, 61h
    or      al, 00000011b
    out     61h, al
    pop     ax

    ret

turn_on endp


turn_off proc near

    push    ax
    in      al, 61h
    and     al, 11111100b
    out     61h, al
    pop     ax

    ret

turn_off endp