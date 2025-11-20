login_menu proc near
    ; This is the main entry point for the login system.
    ; It runs in text mode.
	; Displays the login/register/quit menu.
    
    call    clear_screen

    mov     ah, 9
    lea     dx, login_title_msg
    int     21h

    lea     dx, menu_msg
    int     21h

@@wait_for_key:
    ; Wait for a keypress (1, 2, or 3)
    mov     ah, 08h     ; Get char without echo
    int     21h

    cmp     al, '1'
    je      @@do_login
    cmp     al, '2'
    je      @@do_register
    cmp     al, '3'
    je      @@do_quit

    jmp     @@wait_for_key  ; Invalid key, loop back

@@do_login:
    call    handle_login
    ; If login is successful, it will return here
    cmp     al, 1
    je      @@success
    jmp     login_menu  ; Failed login, return to menu

@@do_register:
    call    handle_register
    jmp     login_menu  ; After registering, return to menu

@@success:
    ; Successful login, clear screen and return to main
    call    clear_screen
    ret

@@do_quit:
    call    quit        ; User chose to quit
    
login_menu endp

; Reads USERS.DAT, compares entered credentials with file records.
handle_login proc near
    push    bx
    push    cx
    push    dx
    push    si
    push    di

    call    clear_screen
    mov     ah, 9
    lea     dx, login_prompt
    int     21h
    
    ; --- Get Username ---
    mov     ah, 9
    lea     dx, user_prompt
    int     21h
    lea     dx, user_buffer
    call    get_string
    
    ; --- Get Password ---
    mov     ah, 9
    lea     dx, pass_prompt
    int     21h
    lea     dx, pass_buffer
    call    get_string

    ; --- Open USERS.DAT file for reading ---
    mov     ah, 3Dh
    mov     al, 0                   ; Read-Only
    lea     dx, users_filename
    int     21h
    
    jc      @@login_fail            ; File not found or error
    mov     file_handle, ax         ; Store file handle

@@read_loop:
    ; --- Read 40-byte record from file ---
    mov     ah, 3Fh
    mov     bx, file_handle
    mov     cx, 40                  ; Read 40 bytes
    lea     dx, record_buffer
    int     21h
    
    cmp     ax, 40                  ; Did we read a full record?
    jne     @@login_fail            ; If not, end of file or error

    ; --- Compare Username ---
    lea     si, user_buffer + 2     ; Point to entered username
    lea     di, record_buffer       ; Point to file username
    mov     cl, [user_buffer + 1]   ; Get length of entered username
    xor     ch, ch
    cld                             ; Clear direction flag
    repe    cmpsb                   ; Compare byte-by-byte
    jne     @@read_loop             ; Not a match, read next record

    ; User string matched, now check if the rest of the
    ; 20-byte file buffer is empty (nulls)
    mov     bl, [user_buffer + 1]   ; Get length again
    mov     bh, 20
    sub     bh, bl                  ; BH = 20 - length
    mov     cx, bx                  ; CX = bytes remaining to check
    xor     al, al                  ; Check for AL = 0
    repne   scasb                   ; Scan for any non-null chars
    jne     @@read_loop             ; Mismatch (e.g. "admin" vs "admin123")
    
    ; --- Username is an exact match, now compare password ---
    lea     si, pass_buffer + 2     ; Point to entered password
    lea     di, record_buffer + 20  ; Point to file password
    mov     cl, [pass_buffer + 1]   ; Get length of entered password
    xor     ch, ch
    repe    cmpsb                   ; Compare
    jne     @@login_fail            ; Wrong password
    
    ; --- Check padding for password ---
    mov     bl, [pass_buffer + 1]
    mov     bh, 20
    sub     bh, bl
    mov     cx, bx
    xor     al, al
    repne   scasb
    jne     @@login_fail            ; Mismatch (e.g. "pass" vs "pass123")

    ; --- SUCCESS! ---
    mov     ah, 3Eh                 ; Close file
    mov     bx, file_handle
    int     21h
    
    mov     ah, 9
    lea     dx, login_success_msg
    int     21h
    
    ; Wait 1.5 seconds (1,500,000 microseconds = 16E360h)
    mov     cx, 0016h               ; High part of 1,500,000
    mov     dx, 0E360h              ; Low part of 1,500,000
    mov     ah, 86h
    int     15h
    
    mov     al, 1                   ; Return 1 for success
    jmp     @@login_exit

@@login_fail:
    ; --- FAILURE ---
    mov     ah, 3Eh                 ; Close file (ignore error if not open)
    mov     bx, file_handle
    int     21h
    
    mov     ah, 9
    lea     dx, login_fail_msg
    int     21h
    call    wait_for_key_press
    
    mov     al, 0                   ; Return 0 for failure

@@login_exit:
    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    ret
handle_login endp


; Creates a new record and saves it to USERS.DAT.
handle_register proc near
    push    bx
    push    cx
    push    dx
    push    si
    push    di

    call    clear_screen
    mov     ah, 9
    lea     dx, reg_prompt
    int     21h

    ; --- Get Username ---
    mov     ah, 9
    lea     dx, user_prompt
    int     21h
    lea     dx, user_buffer
    call    get_string

    ; --- Get Password ---
    mov     ah, 9
    lea     dx, pass_prompt
    int     21h
    lea     dx, pass_buffer
    call    get_string
    
    ; --- Zero-out the 40-byte record buffer ---
    lea     di, record_buffer
    mov     cx, 20  ; 20 words = 40 bytes
    xor     ax, ax
    rep     stosw
    
    ; --- Copy username into first 20 bytes of record ---
    lea     si, user_buffer + 2         ; Source: text data
    lea     di, record_buffer           ; Destination: start of buffer
    mov     cl, [user_buffer + 1]       ; Get actual length
    xor     ch, ch                      ; Clear high byte of CX
    rep     movsb                       ; Copy the string
    
    ; --- Copy password into last 20 bytes of record ---
    lea     si, pass_buffer + 2         ; Source: text data
    lea     di, record_buffer + 20      ; Destination: 20 bytes in
    mov     cl, [pass_buffer + 1]       ; Get actual length
    xor     ch, ch                      ; Clear high byte of CX
    rep     movsb                       ; Copy the string

    ; --- Open/Create the USERS.DAT file ---
    mov     ah, 3Dh                 ; Open File
    mov     al, 2                   ; Read/Write mode
    lea     dx, users_filename
    int     21h
    
    jc      @@create_file           ; If open failed (doesn't exist), create it
    mov     file_handle, ax         ; Store file handle
    jmp     @@seek_end              ; File opened, now seek to end

@@create_file:
    mov     ah, 3Ch                 ; Create File
    mov     cx, 0                   ; Normal attribute
    lea     dx, users_filename
    int     21h
    
    jc      @@reg_fail              ; If create also failed, exit
    mov     file_handle, ax         ; Store new file handle

@@seek_end:
    ; Move file pointer to the end of the file to append
    mov     ah, 42h
    mov     al, 2                   ; Move from end of file
    mov     bx, file_handle
    mov     cx, 0                   ; 0 offset
    mov     dx, 0
    int     21h
    
    ; --- Write the 40-byte record to the file ---
    mov     ah, 40h                 ; Write to file
    mov     bx, file_handle
    mov     cx, 40                  ; Write 40 bytes
    lea     dx, record_buffer
    int     21h
    jc      @@reg_fail              ; Handle write error

    ; --- Close the file ---
    mov     ah, 3Eh
    mov     bx, file_handle
    int     21h

    ; --- Show success message ---
    mov     ah, 9
    lea     dx, reg_success_msg
    int     21h
    call    wait_for_key_press
    jmp     @@reg_exit

@@reg_fail:
    ; --- Show failure message ---
    mov     ah, 9
    lea     dx, reg_fail_msg
    int     21h
    call    wait_for_key_press

@@reg_exit:
    pop     di
    pop     si
    pop     dx
    pop     cx
    pop     bx
    ret
handle_register endp

; Gets user input for username/password.
get_string proc near
    ; Gets a buffered string from DOS
    ; DX must point to a DOS input buffer structure
    
    push    ax
    mov     ah, 0Ah     ; Buffered input
    int     21h
    
    ; Add a newline so next print is on a new line
    mov     ah, 2
    mov     dl, 0Dh     ; Carriage Return
    int     21h
    mov     dl, 0Ah     ; Line Feed
    int     21h
    
    pop     ax
    ret
get_string endp

; Clears the text mode screen.
clear_screen proc near
    push    ax
    push    cx
    push    dx
    
    mov     ax, 0600h   ; AH=06 (scroll up), AL=00 (full screen)
    mov     cx, 0000    ; CH,CL = top-left (row, col)
    mov     dx, 184Fh   ; DH,DL = bottom-right (row 24, col 79)
    mov     bh, 07      ; Normal attribute (white on black)
    int     10h
    
    mov     ah, 02h     ; Set cursor position
    mov     bh, 0       ; Page 0
    mov     dx, 0       ; Row 0, Col 0
    int     10h
    
    pop     dx
    pop     cx
    pop     ax
    ret
clear_screen endp

; “Press any key to continue…” message.
wait_for_key_press proc near
    push    ax
    mov     ah, 9
    lea     dx, any_key_msg
    int     21h
    
    mov     ah, 08h     ; Wait for key press
    int     21h
    
    pop     ax
    ret
wait_for_key_press endp