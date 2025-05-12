BITS 64

; 变量定义
VideoBase:        dq 0
LastLine:         dq 0
FG_Color:         dd 0x0000FF00
BG_Color:         dd 0x00000000
Line_Color:       dd 0x00F7CA12
Screen_Pixels:    dd 0
Screen_Bytes:     dd 0
VideoPPSL:       dd 0
VideoX:           dw 0
VideoY:           dw 0
Screen_Rows:      dw 0
Screen_Cols:      dw 0
Screen_Cursor_Row:dw 0
Screen_Cursor_Col:dw 0

; ui_init 函数
ui_init:
    push rdx
    push rcx
    push rax

    ; 获取屏幕相关值
    mov rcx, SCREEN_LFB_GET
    call [b_system]
    mov [VideoBase], rax
    mov [LastLine], rax

    xor eax, eax
    mov rcx, SCREEN_X_GET
    call [b_system]
    mov [VideoX], ax

    mov rcx, SCREEN_Y_GET
    call [b_system]
    mov [VideoY], ax

    mov rcx, SCREEN_PPSL_GET
    call [b_system]
    mov [VideoPPSL], eax

    ; 计算屏幕参数
    xor eax, eax
    xor ecx, ecx
    mov ax, [VideoX]
    mov cx, [VideoY]
    mul ecx
    mov [Screen_Pixels], eax

    mov ecx, 4
    mul ecx
    mov [Screen_Bytes], eax

    call screen_clear

    ; 计算显示参数
    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    mov ax, [VideoX]
    mov cl, [font_width]
    div cx
    mov [Screen_Cols], ax

    xor eax, eax
    xor edx, edx
    xor ecx, ecx
    mov ax, [VideoY]
    mov cl, [font_height]
    div cx
    mov [Screen_Rows], ax

    ; 重写内核 b_output 函数
    mov rax, output_chars
    mov [0x100018], rax

    ; 设置 b_user 调用入口点
    mov rax, ui_api
    mov [0x100048], rax

    pop rax
    pop rcx
    pop rdx
    ret

; ui_input 函数
ui_input:
    push rdi
    push rdx
    push rax

    mov rdx, rcx
    xor ecx, ecx

ui_input_more:
    mov al, '_'
    call output_char

ui_input_halt:
    hlt
    call [b_input]
    jz ui_input_halt

ui_input_process:
    cmp al, 0x1C
    je ui_input_done

    cmp al, 0x0E
    je ui_input_backspace

    cmp al, 32
    jl ui_input_more

    cmp al, 126
    jg ui_input_more

    cmp rcx, rdx
    je ui_input_more

    stosb
    inc rcx
    call output_char
    jmp ui_input_more

ui_input_backspace:
    test rcx, rcx
    jz ui_input_more

    mov al, ' '
    call output_char
    call dec_cursor
    call dec_cursor
    dec rdi
    mov byte [rdi], 0x00
    dec rcx
    jmp ui_input_more

ui_input_done:
    xor al, al
    stosb
    mov al, ' '
    call output_char

    pop rax
    pop rdx
    pop rdi
    ret

; ui_output 函数
ui_output:
    push rcx
    call string_length
    call output_chars
    pop rcx
    ret

; output_chars 函数
output_chars:
    push rsi
    push rcx
    push rax

output_chars_nextchar:
    cmp rcx, 0
    jz output_chars_done
    dec rcx
    lodsb

    cmp al, 0x0A
    je output_chars_newline

    cmp al, 0x0D
    je output_chars_cr

    cmp al, 9
    je output_chars_tab

    call output_char
    jmp output_chars_nextchar

output_chars_newline:
    mov ax, [Screen_Cursor_Row]
    cmp ax, [Screen_Rows]
    jl output_chars_newline_skip_clear
    call screen_clear
    mov word [Screen_Cursor_Row], 0
    jmp output_chars_nextchar

output_chars_newline_skip_clear:
    call output_newline
    jmp output_chars_nextchar

output_chars_cr:
    mov al, [rsi]
    cmp al, 0x0A
    je output_chars_newline

    push rcx
    xor eax, eax
    xor ecx, ecx
    mov [Screen_Cursor_Col], ax
    mov cx, [Screen_Cols]
    mov al, ' '

output_chars_cr_clearline:
    call output_char
    dec cx
    jnz output_chars_cr_clearline
    dec word [Screen_Cursor_Row]
    xor eax, eax
    mov [Screen_Cursor_Col], ax
    pop rcx
    jmp output_chars_nextchar

output_chars_tab:
    push rcx
    mov ax, [Screen_Cursor_Col]
    mov cx, ax
    add ax, 8
    shr ax, 3
    shl ax, 3
    sub ax, cx
    mov cx, ax
    mov al, ' '

output_chars_tab_next:
    call output_char
    dec cx
    jnz output_chars_tab_next
    pop rcx
    jmp output_chars_nextchar

output_chars_done:
    pop rax
    pop rcx
    pop rsi
    ret

; output_char 函数
output_char:
    call glyph
    call inc_cursor
    ret

; output_newline 函数
output_newline:
    push rax
    mov word [Screen_Cursor_Col], 0
    mov ax, [Screen_Rows]
    dec ax
    cmp ax, [Screen_Cursor_Row]
    je output_newline_wrap
    inc word [Screen_Cursor_Row]
    jmp output_newline_done

output_newline_wrap:
    mov word [Screen_Cursor_Row], 0

output_newline_done:
    call draw_line
    pop rax
    ret

; glyph 函数
glyph:
    push rsi
    push rdx
    push rcx
    push rbx
    push rax

    and eax, 0x000000FF
    cmp al, 0x20
    jl hidden
    cmp al, 127
    jg hidden
    sub rax, 0x20

    mov ecx, font_h
    mul ecx
    mov rsi, font_data
    add rsi, rax

    xor ebx, ebx
    xor edx, edx
    xor eax, eax
    mov ax, [Screen_Cursor_Row]
    mov cx, font_h
    mul cx
    mov bx, ax
    shl ebx, 16

    xor edx, edx
    xor eax, eax
    mov ax, [Screen_Cursor_Col]
    mov cx, font_w
    mul cx
    mov bx, ax

    xor eax, eax
    xor ecx, ecx
    xor edx, edx

glyph_nextline:
    lodsb

glyph_nextpixel:
    cmp ecx, font_w
    je glyph_bailout
    rol al, 1
    bt ax, 0
    jc glyph_pixel
    push rax
    mov eax, [BG_Color]
    call pixel
    pop rax
    jmp glyph_skip

glyph_pixel:
    push rax
    mov eax, [FG_Color]
    call pixel
    pop rax

glyph_skip:
    inc ebx
    inc ecx
    jmp glyph_nextpixel

glyph_bailout:
    xor ecx, ecx
    sub ebx, font_w
    add ebx, 0x00010000
    inc edx
    cmp edx, font_h
    jne glyph_nextline

glyph_done:
    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop rsi
    ret

; pixel 函数
pixel:
    push rdi
    push rdx
    push rcx
    push rbx
    push rax

    push rax
    mov rax, rbx
    shr eax, 16
    xor ecx, ecx
    mov cx, [VideoPPSL]
    mul ecx
    and ebx, 0x0000FFFF
    add eax, ebx
    mov rbx, rax
    mov rdi, [VideoBase]
    pop rax
    shl ebx, 2
    add rdi, rbx
    stosd

    pop rax
    pop rbx
    pop rcx
    pop rdx
    pop rdi
    ret

; screen_clear 函数
screen_clear:
    push rdi
    push rcx
    push rax

    mov word [Screen_Cursor_Col], 0
    mov word [Screen_Cursor_Row], 0

    mov rdi, [VideoBase]
    mov eax, [BG_Color]
    mov ecx, [Screen_Bytes]
    shr ecx, 2
    rep stosd

    call draw_line

    pop rax
    pop rcx
    pop rdi
    ret

; draw_line 函数
draw_line:
    push rdi
    push rdx
    push rcx
    push rax

    mov rdi, [LastLine]
    mov cx, [VideoPPSL]
    mov eax, [BG_Color]
    rep stosd

    mov ax, [Screen_Cursor_Row]
    inc ax
    cmp ax, [Screen_Rows]
    jne draw_line_skip
    mov rdi, [VideoBase]

draw_line_skip:
    xor eax, eax
    mov ax, [VideoPPSL]
    mov ecx, 12
    mul ecx
    mov ecx, eax
    mov eax, [BG_Color]
    rep stosd

    pop rax
    pop rcx
    pop rdx
    pop rdi
    ret

; inc_cursor 函数
inc_cursor:
    push rax

    inc word [Screen_Cursor_Col]
    mov ax, [Screen_Cursor_Col]
    cmp ax, [Screen_Cols]
    jne inc_cursor_done
    mov word [Screen_Cursor_Col], 0
    inc word [Screen_Cursor_Row]
    mov ax, [Screen_Cursor_Row]
    cmp ax, [Screen_Rows]
    jne inc_cursor_done
    mov word [Screen_Cursor_Row], 0

inc_cursor_done:
    pop rax
    ret

; dec_cursor 函数
dec_cursor:
    push rax

    cmp word [Screen_Cursor_Col], 0
    jne dec_cursor_done
    dec word [Screen_Cursor_Row]
    mov ax, [Screen_Cols]
    mov word [Screen_Cursor_Col], ax

dec_cursor_done:
    dec word [Screen_Cursor_Col]
    pop rax
    ret

; string_length 函数
string_length:
    push rdi
    push rax

    xor ecx, ecx
    xor eax, eax
    mov rdi, rsi
    not rcx
    repne scasb
    not rcx
    dec rcx

    pop rax
    pop rdi
    ret

; ui_api 函数
ui_api:
    and ecx, 0xFF
    lea ecx, [ui_api_table+ecx*2]
    mov cx, [ecx]
    jmp rcx

ui_api_ret:
    ret

ui_api_get_fg:
    mov eax, [FG_Color]
    ret

ui_api_get_bg:
    mov eax, [BG_Color]
    ret

ui_api_get_cursor_row:
    xor eax, eax
    mov ax, [Screen_Cursor_Row]
    ret

ui_api_get_cursor_col:
    xor eax, eax
    mov ax, [Screen_Cursor_Col]
    ret

ui_api_get_cursor_row_max:
    xor eax, eax
    mov ax, [Screen_Rows]
    ret

ui_api_get_cursor_col_max:
    xor eax, eax
    mov ax, [Screen_Cols]
    ret

ui_api_set_fg:
    mov [FG_Color], eax
    ret

ui_api_set_bg:
    mov [BG_Color], eax
    ret

ui_api_set_cursor_row:
    mov [Screen_Cursor_Row], ax
    ret

ui_api_set_cursor_col:
    mov [Screen_Cursor_Col], ax
    ret

ui_api_set_cursor_row_max:
    mov [Screen_Rows], ax
    ret

ui_api_set_cursor_col_max:
    mov [Screen_Cols], ax
    ret

; UI API 索引表
ui_api_table:
    dw ui_api_ret         ; 0x00
    dw ui_api_get_fg      ; 0x01
    dw ui_api_get_bg      ; 0x02
    dw ui_api_get_cursor_row ; 0x03
    dw ui_api_get_cursor_col ; 0x04
    dw ui_api_get_cursor_row_max ; 0x05
    dw ui_api_get_cursor_col_max ; 0x06
    dw ui_api_ret         ; 0x07
    dw ui_api_ret         ; 0x08
    dw ui_api_ret         ; 0x09
    dw ui_api_ret         ; 0x0A
    dw ui_api_ret         ; 0x0B
    dw ui_api_ret         ; 0x0C
    dw ui_api_ret         ; 0x0D
    dw ui_api_ret         ; 0x0E
    dw ui_api_ret         ; 0x0F
    dw ui_api_ret         ; 0x10
    dw ui_api_set_fg      ; 0x11
    dw ui_api_set_bg      ; 0x12
    dw ui_api_set_cursor_row ; 0x13
    dw ui_api_set_cursor_col ; 0x14
    dw ui_api_set_cursor_row_max ; 0x15
    dw ui_api_set_cursor_col_max ; 0x16

%include 'ui/fonts/pc.fnt'

