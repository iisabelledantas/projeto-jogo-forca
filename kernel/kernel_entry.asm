; kernel/kernel_entry.asm - Kernel com suporte ao teclado
[BITS 16]
[ORG 0x1000]

; === CONSTANTES ===
MAX_ERROS           equ 6
PALAVRA_MAX_LEN     equ 12
TOTAL_PALAVRAS      equ 5

; === VARIÁVEIS GLOBAIS ===
palavra_atual       db 0
tentativas_erradas  db 0
letras_tentadas     times 26 db 0
palavra_descoberta  times PALAVRA_MAX_LEN db '_'
palavra_descoberta_end db 0
jogo_terminado      db 0
ultima_tecla        db 0

; Função principal chamada pelo bootloader
kernel_main:
    ; Setup inicial
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x9000
    
    ; Instalar handler do teclado
    call setup_keyboard_interrupt
    
    ; Habilitar interrupções
    sti
    
    ; Inicializar jogo
    call clear_screen
    call init_game
    call game_main_loop

; === CONFIGURAÇÃO DE INTERRUPÇÕES ===
setup_keyboard_interrupt:
    cli
    
    ; Salvar handler original do teclado (IRQ1 = INT 09h)
    mov ax, 0
    mov es, ax
    mov bx, 9 * 4       ; INT 09h offset na IVT
    
    ; Instalar nosso handler
    mov word [es:bx], keyboard_handler
    mov word [es:bx+2], 0
    
    sti
    ret

; Handler de interrupção do teclado
keyboard_handler:
    pusha
    push es
    push ds
    
    ; Configurar segmentos
    xor ax, ax
    mov ds, ax
    
    ; Ler scan code do teclado
    in al, 0x60
    
    ; Verificar se é uma tecla pressionada (não liberada)
    test al, 0x80
    jnz keyboard_done
    
    ; Converter scan code para ASCII
    call scancode_to_ascii
    mov [ultima_tecla], al
    
keyboard_done:
    ; Enviar EOI (End of Interrupt) para o PIC
    mov al, 0x20
    out 0x20, al
    
    pop ds
    pop es
    popa
    iret

; Converter scan code para ASCII - versão completa A-Z
scancode_to_ascii:
    ; Q=0x10, W=0x11, E=0x12, R=0x13, T=0x14, Y=0x15, U=0x16, I=0x17, O=0x18, P=0x19
    cmp al, 0x10    ; Q
    jne try_w
    mov al, 'Q'
    ret
try_w:
    cmp al, 0x11    ; W
    jne try_e
    mov al, 'W'
    ret
try_e:
    cmp al, 0x12    ; E
    jne try_r
    mov al, 'E'
    ret
try_r:
    cmp al, 0x13    ; R
    jne try_t
    mov al, 'R'
    ret
try_t:
    cmp al, 0x14    ; T
    jne try_y
    mov al, 'T'
    ret
try_y:
    cmp al, 0x15    ; Y
    jne try_u
    mov al, 'Y'
    ret
try_u:
    cmp al, 0x16    ; U
    jne try_i
    mov al, 'U'
    ret
try_i:
    cmp al, 0x17    ; I
    jne try_o
    mov al, 'I'
    ret
try_o:
    cmp al, 0x18    ; O
    jne try_p
    mov al, 'O'
    ret
try_p:
    cmp al, 0x19    ; P
    jne try_a
    mov al, 'P'
    ret
    
    ; A=0x1E, S=0x1F, D=0x20, F=0x21, G=0x22, H=0x23, J=0x24, K=0x25, L=0x26
try_a:
    cmp al, 0x1E    ; A
    jne try_s
    mov al, 'A'
    ret
try_s:
    cmp al, 0x1F    ; S
    jne try_d
    mov al, 'S'
    ret
try_d:
    cmp al, 0x20    ; D
    jne try_f
    mov al, 'D'
    ret
try_f:
    cmp al, 0x21    ; F
    jne try_g
    mov al, 'F'
    ret
try_g:
    cmp al, 0x22    ; G
    jne try_h
    mov al, 'G'
    ret
try_h:
    cmp al, 0x23    ; H
    jne try_j
    mov al, 'H'
    ret
try_j:
    cmp al, 0x24    ; J
    jne try_k
    mov al, 'J'
    ret
try_k:
    cmp al, 0x25    ; K
    jne try_l
    mov al, 'K'
    ret
try_l:
    cmp al, 0x26    ; L
    jne try_z
    mov al, 'L'
    ret
    
    ; Z=0x2C, X=0x2D, C=0x2E, V=0x2F, B=0x30, N=0x31, M=0x32
try_z:
    cmp al, 0x2C    ; Z
    jne try_x
    mov al, 'Z'
    ret
try_x:
    cmp al, 0x2D    ; X
    jne try_c
    mov al, 'X'
    ret
try_c:
    cmp al, 0x2E    ; C
    jne try_v
    mov al, 'C'
    ret
try_v:
    cmp al, 0x2F    ; V
    jne try_b
    mov al, 'V'
    ret
try_b:
    cmp al, 0x30    ; B
    jne try_n
    mov al, 'B'
    ret
try_n:
    cmp al, 0x31    ; N
    jne try_m
    mov al, 'N'
    ret
try_m:
    cmp al, 0x32    ; M
    jne try_space
    mov al, 'M'
    ret
try_space:
    cmp al, 0x39    ; SPACE
    jne try_enter
    mov al, ' '
    ret
try_enter:
    cmp al, 0x1C    ; ENTER
    jne key_not_found
    mov al, 13      ; CR
    ret
key_not_found:
    mov al, 0       ; Tecla não reconhecida
    ret

; === INICIALIZAÇÃO ===
init_game:
    mov byte [tentativas_erradas], 0
    mov byte [jogo_terminado], 0
    mov byte [ultima_tecla], 0
    
    ; Limpar letras tentadas
    mov di, letras_tentadas
    mov cx, 26
    xor al, al
    rep stosb
    
    call setup_palavra_descoberta
    call draw_interface
    ret

setup_palavra_descoberta:
    ; Pegar palavra atual
    mov al, [palavra_atual]
    mov bl, PALAVRA_MAX_LEN
    mul bl
    mov si, palavras
    add si, ax
    
    ; Copiar palavra para buffer interno
    mov di, palavra_atual_buffer
    mov cx, PALAVRA_MAX_LEN
setup_copy:
    lodsb
    stosb
    test al, al
    jz setup_copy_done
    loop setup_copy
setup_copy_done:
    
    ; Inicializar palavra_descoberta
    mov si, palavra_atual_buffer
    mov di, palavra_descoberta
    xor cx, cx
setup_underscores:
    lodsb
    test al, al
    jz setup_underscores_done
    mov al, '_'
    stosb
    inc cx
    jmp setup_underscores
setup_underscores_done:
    mov al, 0
    stosb
    mov [palavra_tamanho], cl
    ret

; === LOOP PRINCIPAL ===
game_main_loop:
    ; Verificar se jogo terminou
    mov al, [jogo_terminado]
    test al, al
    jnz game_over_screen
    
    ; Atualizar tela
    call draw_game_state
    
    ; Verificar se há tecla pressionada
    mov al, [ultima_tecla]
    test al, al
    jz game_main_loop
    
    ; Processar tecla
    call process_key
    mov byte [ultima_tecla], 0  ; Limpar tecla processada
    
    ; Pequeno delay
    mov cx, 5000
game_delay:
    nop
    loop game_delay
    
    jmp game_main_loop

process_key:
    mov bl, [ultima_tecla]

    ; Verificar se é espaço (reiniciar jogo)
    cmp bl, ' '
    je restart_current_game
    
    ; Verificar se é ENTER (próxima palavra)
    cmp bl, 13
    je next_word
    
    ; Verificar se é uma letra válida (A-Z)
    cmp bl, 'A'
    jl process_key_invalid
    cmp bl, 'Z'
    jg process_key_invalid
    
    ; Verificar se já foi tentada
    sub bl, 'A'
    mov bh, 0
    mov al, [letras_tentadas + bx]
    test al, al
    jnz process_key_already_tried
    
    ; Marcar como tentada
    mov byte [letras_tentadas + bx], 1
    
    ; Verificar se a letra está na palavra
    add bl, 'A'
    call check_letter
    ret

restart_current_game:
    call init_game
    ret

next_word:
    inc byte [palavra_atual]
    mov al, [palavra_atual]
    cmp al, TOTAL_PALAVRAS
    jl restart_game
    mov byte [palavra_atual], 0
restart_game:
    call init_game
    ret

process_key_invalid:
process_key_already_tried:
    ret

check_letter:
    ; BL = letra sendo testada
    mov si, palavra_atual_buffer
    mov di, palavra_descoberta
    xor dx, dx
    xor al, al

check_loop:
    mov cl, [si]
    test cl, cl
    jz check_done
    
    cmp cl, bl
    jne check_next
    
    mov [di], bl
    mov al, 1
    
check_next:
    inc si
    inc di
    inc dx
    jmp check_loop

check_done:
    test al, al
    jnz check_success
    inc byte [tentativas_erradas]
    
check_success:
    call check_game_state
    ret

check_game_state:
    ; Verificar derrota
    cmp byte [tentativas_erradas], MAX_ERROS
    jl check_victory
    mov byte [jogo_terminado], 2
    ret
    
check_victory:
    ; Verificar vitória
    mov si, palavra_descoberta
check_victory_loop:
    lodsb
    test al, al
    jz check_victory_won
    cmp al, '_'
    je check_victory_not_yet
    jmp check_victory_loop
    
check_victory_won:
    mov byte [jogo_terminado], 1
    ret
    
check_victory_not_yet:
    ret

; === INTERFACE GRÁFICA ===
clear_screen:
    push es
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov ax, 0x0720
    mov cx, 2000
    rep stosw
    pop es
    ret

draw_interface:
    push es
    mov ax, 0xB800
    mov es, ax
    
    ; Título
    mov di, (1 * 160) + (28 * 2)
    mov si, titulo_msg
    mov ah, 0x4F
    call print_string_vga
    
    ; Subtítulo
    mov di, (2 * 160) + (25 * 2)
    mov si, subtitulo_msg
    mov ah, 0x0E
    call print_string_vga
    
    ; Instruções
    mov di, (3 * 160) + (15 * 2)
    mov si, instrucoes_msg
    mov ah, 0x0B
    call print_string_vga
    
    call draw_game_border
    pop es
    ret

draw_game_border:
    push es
    mov ax, 0xB800
    mov es, ax
    
    ; Borda superior
    mov di, (5 * 160) + (8 * 2)
    mov ah, 0x0B
    mov al, '+'
    mov es:[di], ax
    
    mov al, '-'
    add di, 2
    mov cx, 62
border_top:
    mov es:[di], ax
    add di, 2
    loop border_top
    
    mov al, '+'
    mov es:[di], ax
    
    ; Bordas laterais
    mov cx, 13
    mov bx, 6
border_sides:
    mov di, bx
    mov ax, 160
    mul di
    mov di, ax
    add di, (8 * 2)
    
    mov ah, 0x0B
    mov al, '|'
    mov es:[di], ax
    
    add di, (62 * 2)
    mov es:[di], ax
    
    inc bx
    loop border_sides
    
    ; Borda inferior
    mov di, (19 * 160) + (8 * 2)
    mov ah, 0x0B
    mov al, '+'
    mov es:[di], ax
    
    mov al, '-'
    add di, 2
    mov cx, 62
border_bottom:
    mov es:[di], ax
    add di, 2
    loop border_bottom
    
    mov al, '+'
    mov es:[di], ax
    
    pop es
    ret

draw_game_state:
    push es
    mov ax, 0xB800
    mov es, ax
    
    call draw_hangman
    call draw_palavra
    call draw_letras_tentadas
    call draw_status
    
    pop es
    ret

draw_hangman:
    mov al, [tentativas_erradas]
    
    ; Base da forca
    mov di, (8 * 160) + (15 * 2)
    mov ah, 0x06
    mov al, '|'
    mov es:[di], ax
    mov es:[di + 160], ax
    mov es:[di + 320], ax
    mov es:[di + 480], ax
    mov es:[di + 640], ax
    
    ; Topo horizontal
    mov di, (8 * 160) + (15 * 2)
    mov al, '+'
    mov es:[di], ax
    add di, 2
    mov al, '-'
    mov cx, 4
draw_top:
    mov es:[di], ax
    add di, 2
    loop draw_top
    mov al, '+'
    mov es:[di], ax
    
    ; Corda
    mov di, (9 * 160) + (19 * 2)
    mov al, '|'
    mov es:[di], ax
    
    ; Partes do corpo baseado nos erros
    mov cl, [tentativas_erradas]
    test cl, cl
    jz draw_hangman_done
    
    ; 1 erro: Cabeça
    mov di, (10 * 160) + (19 * 2)
    mov ah, 0x0C
    mov al, 'O'
    mov es:[di], ax
    
    cmp cl, 1
    je draw_hangman_done
    
    ; 2 erros: Corpo
    mov di, (11 * 160) + (19 * 2)
    mov al, '|'
    mov es:[di], ax
    mov es:[di + 160], ax
    
    cmp cl, 2
    je draw_hangman_done
    
    ; 3 erros: Braço esquerdo
    mov di, (11 * 160) + (18 * 2)
    mov al, '/'
    mov es:[di], ax
    
    cmp cl, 3
    je draw_hangman_done
    
    ; 4 erros: Braço direito
    mov di, (11 * 160) + (20 * 2)
    mov al, '\'
    mov es:[di], ax
    
    cmp cl, 4
    je draw_hangman_done
    
    ; 5 erros: Perna esquerda
    mov di, (13 * 160) + (18 * 2)
    mov al, '/'
    mov es:[di], ax
    
    cmp cl, 5
    je draw_hangman_done
    
    ; 6 erros: Perna direita - Game Over
    mov di, (13 * 160) + (20 * 2)
    mov al, '\'
    mov es:[di], ax
    
draw_hangman_done:
    ret

draw_palavra:
    mov di, (15 * 160) + (32 * 2)
    mov si, palavra_descoberta
    mov ah, 0x0F
    
draw_palavra_loop:
    lodsb
    test al, al
    jz draw_palavra_done
    
    mov es:[di], ax
    add di, 2
    mov al, ' '
    mov ah, 0x07
    mov es:[di], ax
    add di, 2
    
    jmp draw_palavra_loop
    
draw_palavra_done:
    ret

draw_letras_tentadas:
    mov di, (16 * 160) + (10 * 2)
    mov si, tentadas_label
    mov ah, 0x0A
    call print_string_vga
    
    mov di, (17 * 160) + (10 * 2)
    mov si, letras_tentadas
    mov bl, 'A'
    mov cx, 26
    
draw_tentadas_loop:
    lodsb
    test al, al
    jz draw_tentadas_next
    
    mov ah, 0x08
    mov al, bl
    mov es:[di], ax
    add di, 2
    mov al, ' '
    mov ah, 0x07
    mov es:[di], ax
    add di, 2
    
draw_tentadas_next:
    inc bl
    loop draw_tentadas_loop
    
    ret

draw_status:
    ; Erros
    mov di, (21 * 160) + (10 * 2)
    mov si, erros_label
    mov ah, 0x0C
    call print_string_vga
    
    mov al, [tentativas_erradas]
    add al, '0'
    mov ah, 0x0C
    mov es:[di], ax
    add di, 2
    
    mov al, '/'
    mov es:[di], ax
    add di, 2
    
    mov al, '6'
    mov es:[di], ax
    
    ; Número da palavra atual
    mov di, (21 * 160) + (50 * 2)
    mov si, palavra_num_label
    mov ah, 0x0E
    call print_string_vga
    
    mov al, [palavra_atual]
    inc al
    add al, '0'
    mov ah, 0x0E
    mov es:[di], ax
    add di, 2
    
    mov al, '/'
    mov es:[di], ax
    add di, 2
    
    mov al, '5'
    mov es:[di], ax
    
    ret

game_over_screen:
    push es
    mov ax, 0xB800
    mov es, ax
    
    ; Limpar área de mensagem
    mov di, (14 * 160) + (25 * 2)
    mov ah, 0x70
    mov al, ' '
    mov cx, 30
clear_msg_area:
    mov es:[di], ax
    add di, 2
    loop clear_msg_area
    
    ; Mostrar resultado
    mov al, [jogo_terminado]
    cmp al, 1
    je show_victory
    
    ; Derrota
    mov di, (14 * 160) + (32 * 2)
    mov si, derrota_msg
    mov ah, 0x4C
    call print_string_vga
    jmp show_word
    
show_victory:
    mov di, (14 * 160) + (30 * 2)
    mov si, vitoria_msg
    mov ah, 0x2F
    call print_string_vga
    
show_word:
    ; Mostrar palavra completa
    mov di, (15 * 160) + (22 * 2)
    mov si, palavra_era_label
    mov ah, 0x70
    call print_string_vga
    
    mov si, palavra_atual_buffer
    mov ah, 0x0F
    call print_string_vga
    
    ; Instruções
    mov di, (17 * 160) + (20 * 2)
    mov ah, 0x0E
    call print_string_vga
    
    ; Verificar teclas para controle
    mov al, [ultima_tecla]
    cmp al, ' '
    je game_over_restart
    cmp al, 13
    je game_over_next
    
    pop es
    ret

game_over_restart:
    mov byte [ultima_tecla], 0
    call init_game
    pop es
    ret

game_over_next:
    mov byte [ultima_tecla], 0
    inc byte [palavra_atual]
    mov al, [palavra_atual]
    cmp al, TOTAL_PALAVRAS
    jl game_over_next_ok
    mov byte [palavra_atual], 0
game_over_next_ok:
    call init_game
    pop es
    ret

print_string_vga:
    push es
    mov bx, 0xB800
    mov es, bx
print_loop:
    lodsb
    test al, al
    jz print_done
    mov es:[di], ax
    add di, 2
    jmp print_loop
print_done:
    pop es
    ret

; === DADOS ===
palavras:
    db 'KERNEL', 0, 0, 0, 0, 0, 0        ; 12 bytes
    db 'SISTEMA', 0, 0, 0, 0, 0           ; 12 bytes  
    db 'COMPUTER', 0, 0, 0, 0             ; 12 bytes
    db 'ASSEMBLY', 0, 0, 0, 0             ; 12 bytes
    db 'PROGRAMAR', 0, 0, 0               ; 12 bytes

palavra_atual_buffer times PALAVRA_MAX_LEN db 0
palavra_tamanho db 0

; Mensagens
titulo_msg:         db 'JOGO DA FORCA INTERATIVO', 0
subtitulo_msg:      db 'Micro Kernel - Fase 5', 0
instrucoes_msg:     db 'Tecle A-Z p/ adivinhar | ENTER=Proxima palavracl', 0
tentadas_label:     db 'Letras tentadas: ', 0
erros_label:        db 'Erros: ', 0
palavra_num_label:  db 'Palavra: ', 0
vitoria_msg:        db 'PARABENS! ACERTOU!', 0
derrota_msg:        db 'GAME OVER - ENFORCADO!', 0
palavra_era_label:  db 'A palavra era: ', 0

; Final do kernel
halt:
    hlt
    jmp halt