# Jogo da Forca no micro Kernel

[Acesse aqui o video de demostração](https://drive.google.com/file/d/1b5LtY4ZmgiSHmgq1FYM-ne87D3qKfrKE/view?usp=sharing)

### Estrutura de Arquivos
```
projeto/
├── boot/
│   └── boot.asm         
├── kernel/
│   └── kernel_entry.asm  
├── Makefile   
├── boot.bin
├── image.bin
├── kernel.bin            
└── README.md    

## Como Compilar e Executar

### Pré-requisitos

```bash
sudo apt update
sudo apt install nasm qemu-system-x86
```

### Compilação

```bash
# Clonar/baixar o projeto
cd projeto-jogo-forca

# Limpar builds anteriores
make clean

# Compilar bootloader e kernel
make build

# Verificar arquivos gerados
ls -la *.bin
# Deve mostrar: boot.bin, kernel.bin, image.bin
```

### Execução
```bash
# Executar o jogo
make run

# Executar manualmente
qemu-system-i386 -fda image.bin -boot a
```

## Como Jogar

### Controles

- **ENTER**: Avançar para próxima palavra - Dessa forma, escolhendo uma palavra.
- **A-Z**: Tentar uma letra

### Palavras do Jogo

1. **KERNEL** 
2. **SISTEMA** 
3. **COMPUTER**  
4. **ASSEMBLY** 
5. **PROGRAMAR** 
