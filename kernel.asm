%include "pm.inc"

org   0x9000

VRAM_ADDRESS  equ  0x000a0000

jmp   LABEL_BEGIN

[SECTION .gdt]
 ;                                  段基址          段界限                属性
LABEL_GDT:          Descriptor        0,            0,                   0  
LABEL_DESC_CODE32:  Descriptor        0,      SegCode32Len - 1,       DA_C + DA_32
LABEL_DESC_VIDEO:   Descriptor        0B8000h,         0ffffh,            DA_DRW
LABEL_DESC_VRAM:    Descriptor        0,         0ffffffffh,            DA_DRW
LABEL_DESC_STACK:   Descriptor        0,             TopOfStack,        DA_DRWA+DA_32

GdtLen     equ    $ - LABEL_GDT
GdtPtr     dw     GdtLen - 1
           dd     0

SelectorCode32    equ   LABEL_DESC_CODE32 -  LABEL_GDT
SelectorVideo     equ   LABEL_DESC_VIDEO  -  LABEL_GDT
SelectorStack     equ   LABEL_DESC_STACK  -  LABEL_GDT
SelectorVram      equ   LABEL_DESC_VRAM   -  LABEL_GDT


[SECTION  .s16]
[BITS  16]
LABEL_BEGIN:
     mov   ax, cs
     mov   ds, ax
     mov   es, ax
     mov   ss, ax
     mov   sp, 0100h

     mov   al, 0x13
     mov   ah, 0
     int   0x10

     xor   eax, eax
     mov   ax,  cs
     shl   eax, 4
     add   eax, LABEL_SEG_CODE32
     mov   word [LABEL_DESC_CODE32 + 2], ax
     shr   eax, 16
     mov   byte [LABEL_DESC_CODE32 + 4], al
     mov   byte [LABEL_DESC_CODE32 + 7], ah

     xor   eax, eax
     mov   ax, ds
     shl   eax, 4
     add   eax,  LABEL_GDT
     mov   dword  [GdtPtr + 2], eax

     lgdt  [GdtPtr]

     cli   ;关中断

     in    al,  92h
     or    al,  00000010b
     out   92h, al

     mov   eax, cr0
     or    eax , 1
     mov   cr0, eax

     jmp   dword  SelectorCode32: 0

     [SECTION .s32]
     [BITS  32]
     LABEL_SEG_CODE32:
     ;initialize stack for c code
     mov  ax, SelectorStack
     mov  ss, ax
     mov  esp, TopOfStack

     mov  ax, SelectorVram
     mov  ds,  ax

HariMain:; Function begin
        push    ebp                                     
        mov     ebp, esp                                
        sub     esp, 24                                
        mov     dword [ebp-0CH], 655360                
        jmp     ?_002                                   

?_001:  mov     eax, dword [ebp-0CH]                    
        and     eax, 0FH                                
        sub     esp, 8                                  
        push    eax                                    
        push    dword [ebp-0CH]                         
        call    write_mem8                              
        add     esp, 16                                
        add     dword [ebp-0CH], 1                     
?_002:  cmp     dword [ebp-0CH], 720895                
        jle     ?_001  
?_003:  call    io_hlt                                 
        jmp     ?_003

 write_mem8:   ;void write_mem8(int addr, int data)
        mov      ecx, [esp + 4]
        mov      al, [esp + 8]
        mov      [ecx], al
        ret


    io_hlt:  ;void io_hlt(void);
      HLT
      RET

SegCode32Len   equ  $ - LABEL_SEG_CODE32

[SECTION .gs]
ALIGN 32
[BITS 32]
LABEL_STACK:
times 512  db 0
TopOfStack  equ  $ - LABEL_STACK

