; boot/boot.asm - Bootloader corrigido que chama kernel_main
[BITS 16]
[ORG 0x7C00]

KERNEL_OFFSET equ 0x1000

start:
    ; Inicializar registradores
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    
    ; Limpar tela
    mov ax, 0x0003
    int 0x10
    
    ; Mensagem do bootloader
    mov si, msg_loading
    call print_string
    
    ; Carregar kernel
    call load_kernel
    
    ; Mensagem de transição
    mov si, msg_jumping
    call print_string
    
    ; Pular para kernel_main (não para o início do arquivo)
    call KERNEL_OFFSET

load_kernel:
    ; Parâmetros para leitura do disco
    mov ah, 0x02    ; Função: ler setores
    mov al, 6       ; Número de setores (aumentado para 6)
    mov ch, 0       ; Cilindro 0
    mov cl, 2       ; Setor 2
    mov dh, 0       ; Cabeça 0
    mov dl, 0       ; Drive 0
    
    mov bx, KERNEL_OFFSET
    int 0x13
    jc disk_error
    
    mov si, msg_loaded
    call print_string
    ret

disk_error:
    mov si, msg_error
    call print_string
    jmp halt

print_string:
    mov ah, 0x0E
    mov bh, 0x00
    mov bl, 0x07
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

halt:
    hlt
    jmp halt

; Mensagens
msg_loading: db 'BOOTLOADER: Carregando kernel...', 0x0D, 0x0A, 0
msg_loaded:  db 'Kernel carregado com sucesso!', 0x0D, 0x0A, 0
msg_jumping: db 'Iniciando kernel...', 0x0D, 0x0A, 0
msg_error:   db 'ERRO: Falha ao carregar kernel!', 0x0D, 0x0A, 0

; Preenchimento e assinatura
times 510-($-$$) db 0
dw 0xAA55