; Displays “Start / High Scores / Exit” options.
show_menu proc near
    ; Set text mode (80x25)
    mov     ax, 0003h
    int     10h

    ; Clear screen
    mov     ax, 0600h
    mov     bh, 07h
    mov     cx, 0000h
    mov     dx, 184Fh
    int     10h

    ; Set cursor to top
    mov     ah, 02h
    mov     bh, 0
    mov     dx, 0
    int     10h

    ; Print menu message
    mov     ah, 09h
    lea     dx, menu_msg
    int     21h

    ; Wait for key press
    mov     ah, 00h
    int     16h

    ; Check input
    cmp     al, '1'
    je      @@start_game
    cmp     al, '2'
    je      @@show_scores
    cmp     al, '3'
    je      @@exit_game

    jmp     show_menu ; Invalid key, reload menu

@@start_game:
    ; (Re)set game state before starting
    mov     curr_len, 6
    mov     score, 0
    mov     head_dx, 1
    mov     head_dy, 0
    mov     head_x, start_head_x
    mov     head_y, start_head_y
    ; Reset food/poison

    ; Set graphics mode and start game
    call    set_mode_n_page
    call    prepare_map
    call    prepare_goods
    call    prepare_snake
    call    main_loop ; This will loop until game over
    jmp     show_menu ; After game, return to menu

@@show_scores:
    call    show_high_scores
    jmp     show_menu ; Return to menu

@@exit_game:
    call    quit

    ret
show_menu endp

; Reads from SCORES.DAT.
read_scores_from_file proc near
    ; Clear buffer first
    mov     di, offset scores_buffer
    mov     cx, max_scores
    xor     ax, ax
@@clear_loop:
    stosw
    loop    @@clear_loop

    ; Open file (AH=3Dh, AL=0 Read-only)
    mov     ah, 3Dh
    mov     al, 0
    lea     dx, scores_file
    int     21h
    jc      @@exit_read ; File not found, buffer is 0s

    mov     file_handle, ax

    ; Read from file (AH=3Fh)
    mov     ah, 3Fh
    mov     bx, file_handle
    mov     cx, max_scores * 2 ; 5 scores * 2 bytes/score
    lea     dx, scores_buffer
    int     21h

    mov     score_count, ax
    shr     score_count, 1 ; Convert bytes read to word count

    ; Close file (AH=3Eh)
    mov     ah, 3Eh
    mov     bx, file_handle
    int     21h

@@exit_read:
    ret
read_scores_from_file endp

; Writes the scores.
write_scores_to_file proc near
    ; Create/Truncate file (AH=3Ch)
    mov     ah, 3Ch
    mov     cx, 0 ; Normal attribute
    lea     dx, scores_file
    int     21h
    jc      @@exit_write ; Error creating file

    mov     file_handle, ax

    ; Write to file (AH=40h)
    mov     ah, 40h
    mov     bx, file_handle
    mov     cx, max_scores * 2 ; Write all 5 scores
    lea     dx, scores_buffer
    int     21h

    ; Close file (AH=3Eh)
    mov     ah, 3Eh
    mov     bx, file_handle
    int     21h

@@exit_write:
    ret
write_scores_to_file endp


; Sorts high scores (bubble sort).
sort_scores proc near
    push    ax
    push    bx
    push    cx
    push    si
    push    di

    mov     cx, max_scores - 1
@@outer_loop:
    push    cx
    mov     si, offset scores_buffer
    mov     di, offset scores_buffer
    add     di, 2
    
@@inner_loop:
    mov     ax, [si]
    mov     bx, [di]
    cmp     ax, bx
    jge     @@no_swap ; Descending order (>=)

    ; Swap
    mov     [si], bx
    mov     [di], ax

@@no_swap:
    add     si, 2
    add     di, 2
    loop    @@inner_loop

    pop     cx
    loop    @@outer_loop

    pop     di
    pop     si
    pop     cx
    pop     bx
    pop     ax
    ret
sort_scores endp


; Replaces the lowest score if your score is higher.
update_scores proc near
    call    read_scores_from_file

    mov     ax, score ; Get the final score
    
    ; Compare new score to the lowest high score
    ; (Assumes list is sorted, lowest is at the end)
    mov     si, (max_scores - 1) * 2 ; Offset to last score
    cmp     ax, scores_buffer[si]
    jle     @@exit_update ; Not a high score

    ; Replace lowest score and re-sort
    mov     scores_buffer[si], ax
    call    sort_scores
    call    write_scores_to_file

@@exit_update:
    ret
update_scores endp


; Displays scores on screen.
show_high_scores proc near
    ; Clear screen
    mov     ax, 0600h
    mov     bh, 07h
    mov     cx, 0000h
    mov     dx, 184Fh
    int     10h

    ; Set cursor
    mov     ah, 02h
    mov     bh, 0
    mov     dx, 0
    int     10h

    ; Print title
    mov     ah, 09h
    lea     dx, scores_title_msg
    int     21h

    call    read_scores_from_file

    ; Loop and print each score
    mov     cx, max_scores
    mov     si, offset scores_buffer
@@print_loop:
    mov     ax, [si]
    call    print_number_text ; Call new text-based print
    add     si, 2
    loop    @@print_loop

    ; Wait for key
    mov     ah, 00h
    int     16h
    ret
show_high_scores endp


; Converts score numbers into text for printing.
print_number_text proc near
    push    ax
    push    bx
    push    cx
    push    dx
    push    di

    mov     di, offset temp_num_str
    add     di, 4 ; Point to end of "00000"
    mov     bx, 10
    mov     cx, 5 ; Max 5 digits

@@convert_loop:
    xor     dx, dx
    div     bx
    add     dl, '0' ; Convert remainder to ASCII
    mov     [di], dl
    dec     di
    dec     cx
    test    ax, ax
    jnz     @@convert_loop
    
    ; Add leading spaces
@@leading_spaces:
    cmp     cx, 0
    je      @@print_it
    mov     byte ptr [di], ' '
    dec     di
    dec     cx
    jmp     @@leading_spaces

@@print_it:
    inc     di ; Point back to first char
    mov     ah, 09h
    lea     dx, [di]
    int     21h

    pop     di
    pop     dx
    pop     cx
    pop     bx
    pop     ax
    ret
print_number_text endp