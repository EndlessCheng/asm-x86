;=============================================================================== 
SECTION header vstart=0                     ;�����û�����ͷ���� 
    program_length  dd program_end          ;�����ܳ���[0x00]
    
    ;�û�������ڵ�
    code_entry      dw start                ;ƫ�Ƶ�ַ[0x04]
                    dd section.code.start   ;�ε�ַ[0x06] 
    
    realloc_tbl_len dw (header_end-realloc_begin)/4
                                            ;���ض�λ�������[0x0a]
    
    realloc_begin:
    ;���ض�λ��           
    code_segment    dd section.code.start   
    data_segment    dd section.data.start  
    stack_segment   dd section.stack.start 
    
header_end:                

;===============================================================================
SECTION code align=16 vstart=0         ;�������Σ�16�ֽڶ��룩
put_string:                            ;��ʾ�ַ�����0��β�� 
                                       ;���룺DS:BX=����ַ
      push ax
      push bx
      push si
      
      mov ah,0x0e                      ;INT 0x10��0x0e�Ź��� 
      mov si,bx                        ;�ַ�����ʼƫ�Ƶ�ַ 
      mov bl,0x07                      ;��ʾ���� 
      
 .gchr:      
      mov al,[si]                      ;���ȡҪ��ʾ���ַ� 
      or al,al                         ;���AL����Ϊ�㣬�� 
      jz .rett                         ;��ת�����̷���ָ�� 
      int 0x10                         ;BIOS�ַ���ʾ���ܵ��� 
      inc si                           ;��һ���ַ� 
      jmp .gchr
      
 .rett:
      pop si
      pop bx
      pop ax
            
      ret

;------------------------------------------------------------------------------- 
write_dsp:
      push dx
      push ax
      
      mov dx,022ch
 .@22c:
      in al,dx                        
      and al,1000_0000b	               ;����22c�˿ڵĵ�7λ��ֱ������Ϊ0
      jnz .@22c

      pop ax
      out dx,al
      pop dx
      
      ret

;-------------------------------------------------------------------------------
read_dsp:
      push dx
      
      mov dx,22eh
 .@22e:
      in al,dx                          
      and al,1000_0000b                ;����22e�˿ڵ�λ7��ֱ�������1
      jz .@22e
      mov dx,22ah
      in al,dx                         ;��ʱ���Դ�22a�˿ڶ�ȡ����
      
      pop dx
      
      ret

;-------------------------------------------------------------------------------
start:
      mov ax,[stack_segment]
      mov ss,ax                        ;�޸�SSʱ������������ִ����һָ
      mov sp,ss_pointer                ;��ǰ��ֹ�ж�
      
      mov ax,[data_segment]
      mov ds,ax

      mov bx,init_msg
      call put_string
               
      ;���¸�λDSPоƬ
      mov dx,0x226 
      mov al,1                         ;��һ������д��1������λ�˿� 
      out dx,al
    
      xor ax,ax
  .@1:
      dec ax
      jnz .@1                          ;һ��Ӳ��Ҫ�����ʱ(����3ms) 
    
      out dx,al                        ;�ڶ�����д��0������λ�˿� 

      call read_dsp
      cmp al,0xaa                      ;״ֵ̬0xaa��ʾ��ʼ����� 
      jz .@4
    
      mov bx,err_msg                   ;��ʾ������Ϣ 
      call put_string
      jmp .idle                        ;ֱ��ͣ�� 
      
  .@4:
      mov bx,done_msg
      call put_string
      
      ;���°�װ�жϴ������
      mov bx,intr_msg
      call put_string
      
      mov al,0x0d                      ;IR5���ŵ��жϺ� 
      mov bl,4                         ;ÿ���ж�����ռ4���ֽڡ����ε�Ч�ڣ� 
      mul bl                           ;mov bx,0x0d
      mov bx,ax                        ;shl bx,2
      
      cli                              ;��ֹ���޸�IVT�ڼ䷢���ж� 
      
      push es                          ;��ʱʹ��ES 
      xor ax,ax
      mov es,ax                        ;ָ���ڴ���ʹ����ж������� 
      mov word [es:bx],dsp_interrupt
                                       ;ƫ�Ƶ�ַ 
      inc bx
      inc bx
      mov word [es:bx],cs              ;��ǰ����� 
      pop es
      
      sti

      ;����IRQ5
      in al,0x21                       ;8259��Ƭ��IMR 
      and al,1101_1111B                ;����IR5 
      out 0x21,al
      
      mov bx,done_msg
      call put_string

      mov bx,dma_msg
      call put_string
                                       
      ;��DMA��������̣������乤��ģʽ����������ַ�ʹ��䳤��
      mov dx,0x0a	               ;DMAC1�����μĴ���
      mov al,00000_1_01B	       ;�ر���DMAC��1��ͨ�� 
      out dx,al                      
		
      mov ax,ds                        ;���㻺���������ַ
      mov bx,16
      mul bx
      add ax,voice_data
      adc dx,0
      mov bx,dx                        ;bx:ax=������20λ��ַ 

      xor al,al
      out 0x0c,al                      ;DMAC1�ߵʹ���������

      mov dx,0x02                      ;дͨ��1��ַ�뵱ǰ��ַ�Ĵ���
      out dx,al                        ;��8λDMA��ַ 
      mov al,ah
      out dx,al                        ;��8λDMA��ַ 

      mov dx,0x83                      ;дDMAͨ�� 1 ��ҳ��Ĵ���
      mov al,bl
      out dx,al

      mov dx,0x03                      ;дͨ��1�Ļ��ּ����뵱ǰ�ּ�����
      mov ax,init_msg-voice_data       ;���ݿ飨���������ã��Ĵ�С 
      dec ax                           ;DMAҪ��ʵ�ʴ�С��һ
      out dx,al                        ;���������ȵ�8λ
      mov al,ah
      out dx,al                        ;���������ȸ�8λ
       
      mov al,0101_1001b                ;����DMAC1ͨ��1������ʽ�����ֽڴ���/
      out 0x0b,al                      ;��ַ����/�Զ�Ԥ��/������/ͨ��1

      mov dx,0x0a                      ;DMAC1���μĴ���
      mov al,1                         ;����ͨ��1��������
      out dx,al

      mov al,0x40                      ;����DSP�����ʣ����ţ�
      call write_dsp
      mov ax,65536-(256000000/(1*8000))
      xchg ah,al                       ;ֻʹ�ý���ĸ�8λ 
      call write_dsp

      ;��ʾ��Ϣ
      mov bx,done_msg
      call put_string

      ;�������DSP��DMA����ģʽ�����ݳ��ȣ���������Ƶ����
      mov al,0x48
      call write_dsp
      mov ax,init_msg-voice_data       ;���ݿ飨���������ã��Ĵ�С
      shr ax,1                         ;������ΪDMA��һ��
      dec ax 
      call write_dsp                   ;д���ֽ� 
      xchg ah,al                      
      call write_dsp                   ;д���ֽ�
   
      ;���������
      mov al,0xd1
      call write_dsp

      ;����DSP�Ĵ���Ĳ���
      mov al,0x1c
      call write_dsp

      mov bx,play_msg
      call put_string
      
  .idle:
      hlt
      jmp .idle
       
;-------------------------------------------------------------------------------  
dsp_interrupt:                         ;�жϴ������
      push ax
      push bx
      push dx
      
      ;�˳��Զ���ʼ��ģʽ
      mov al,0xda
      call write_dsp
      
      ;�ر�������
      mov al,0xd3
      call write_dsp
       
      mov bx,done_msg
      call put_string
      
      mov bx,okay_msg
      call put_string

      mov dx,0x22f                     ;DSP�ж�Ӧ��
      in al,dx

      ;����EOI����жϿ�����(��Ƭ)
      mov al,0x20                      ;�жϽ�������EOI
      out 0x20,al                      ;������Ƭ 

      pop dx
      pop bx
      pop ax
      
      iret
      
;-------------------------------------------------------------------------------
SECTION data align=16 vstart=0

  voice_data   incbin "baby.wav",44
    
    init_msg       db 'Initializing sound blaster card...',0
    
    intr_msg       db 'Installing interrupt vector...',0
                   
     dma_msg       db 'Setup DMA ...',0
                   
    done_msg       db 'Done.',0x0d,0x0a,0
                   
    play_msg       db 'Voice is playing now...',0
    
    okay_msg       db 'Finished,stop.',0
    
     err_msg       db 'Sound card init failed.',0
                   
;===============================================================================
SECTION stack align=16 vstart=0
           
                 resb 256
ss_pointer:

;===============================================================================  
SECTION program_trail
program_end: