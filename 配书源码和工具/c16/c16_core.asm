         ;�����嵥16-1
         ;�ļ�����c16_core.asm
         ;�ļ�˵��������ģʽ΢�ͺ��ĳ��� 
         ;�������ڣ�2012-06-20 00:05

         ;���³������岿�֡��ں˵Ĵ󲿷����ݶ�Ӧ���̶�
         core_code_seg_sel     equ  0x38    ;�ں˴����ѡ����
         core_data_seg_sel     equ  0x30    ;�ں����ݶ�ѡ���� 
         sys_routine_seg_sel   equ  0x28    ;ϵͳ�������̴���ε�ѡ���� 
         video_ram_seg_sel     equ  0x20    ;��Ƶ��ʾ�������Ķ�ѡ����
         core_stack_seg_sel    equ  0x18    ;�ں˶�ջ��ѡ����
         mem_0_4_gb_seg_sel    equ  0x08    ;����0-4GB�ڴ�Ķε�ѡ����

;-------------------------------------------------------------------------------
         ;������ϵͳ���ĵ�ͷ�������ڼ��غ��ĳ��� 
         core_length      dd core_end       ;���ĳ����ܳ���#00

         sys_routine_seg  dd section.sys_routine.start
                                            ;ϵͳ�������̶�λ��#04

         core_data_seg    dd section.core_data.start
                                            ;�������ݶ�λ��#08

         core_code_seg    dd section.core_code.start
                                            ;���Ĵ����λ��#0c


         core_entry       dd start          ;���Ĵ������ڵ�#10
                          dw core_code_seg_sel

;===============================================================================
         [bits 32]
;===============================================================================
SECTION sys_routine vstart=0                ;ϵͳ�������̴���� 
;-------------------------------------------------------------------------------
         ;�ַ�����ʾ����
put_string:                                 ;��ʾ0��ֹ���ַ������ƶ���� 
                                            ;���룺DS:EBX=����ַ
         push ecx
  .getc:
         mov cl,[ebx]
         or cl,cl
         jz .exit
         call put_char
         inc ebx
         jmp .getc

  .exit:
         pop ecx
         retf                               ;�μ䷵��

;-------------------------------------------------------------------------------
put_char:                                   ;�ڵ�ǰ��괦��ʾһ���ַ�,���ƽ�
                                            ;��ꡣ�����ڶ��ڵ��� 
                                            ;���룺CL=�ַ�ASCII�� 
         pushad

         ;����ȡ��ǰ���λ��
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;����
         mov ah,al

         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         in al,dx                           ;����
         mov bx,ax                          ;BX=������λ�õ�16λ��

         cmp cl,0x0d                        ;�س�����
         jnz .put_0a
         mov ax,bx
         mov bl,80
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

  .put_0a:
         cmp cl,0x0a                        ;���з���
         jnz .put_other
         add bx,80
         jmp .roll_screen

  .put_other:                               ;������ʾ�ַ�
         push es
         mov eax,video_ram_seg_sel          ;0x800b8000�ε�ѡ����
         mov es,eax
         shl bx,1
         mov [es:bx],cl
         pop es

         ;���½����λ���ƽ�һ���ַ�
         shr bx,1
         inc bx

  .roll_screen:
         cmp bx,2000                        ;��곬����Ļ������
         jl .set_cursor

         push ds
         push es
         mov eax,video_ram_seg_sel
         mov ds,eax
         mov es,eax
         cld
         mov esi,0xa0                       ;С�ģ�32λģʽ��movsb/w/d 
         mov edi,0x00                       ;ʹ�õ���esi/edi/ecx 
         mov ecx,1920
         rep movsd
         mov bx,3840                        ;�����Ļ���һ��
         mov ecx,80                         ;32λ����Ӧ��ʹ��ECX
  .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         pop es
         pop ds

         mov bx,1920

  .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         inc dx                             ;0x3d5
         mov al,bh
         out dx,al
         dec dx                             ;0x3d4
         mov al,0x0f
         out dx,al
         inc dx                             ;0x3d5
         mov al,bl
         out dx,al

         popad
         
         ret                                

;-------------------------------------------------------------------------------
read_hard_disk_0:                           ;��Ӳ�̶�ȡһ���߼�����
                                            ;EAX=�߼�������
                                            ;DS:EBX=Ŀ�껺������ַ
                                            ;���أ�EBX=EBX+512
         push eax 
         push ecx
         push edx
      
         push eax
         
         mov dx,0x1f2
         mov al,1
         out dx,al                          ;��ȡ��������

         inc dx                             ;0x1f3
         pop eax
         out dx,al                          ;LBA��ַ7~0

         inc dx                             ;0x1f4
         mov cl,8
         shr eax,cl
         out dx,al                          ;LBA��ַ15~8

         inc dx                             ;0x1f5
         shr eax,cl
         out dx,al                          ;LBA��ַ23~16

         inc dx                             ;0x1f6
         shr eax,cl
         or al,0xe0                         ;��һӲ��  LBA��ַ27~24
         out dx,al

         inc dx                             ;0x1f7
         mov al,0x20                        ;������
         out dx,al

  .waits:
         in al,dx
         and al,0x88
         cmp al,0x08
         jnz .waits                         ;��æ����Ӳ����׼�������ݴ��� 

         mov ecx,256                        ;�ܹ�Ҫ��ȡ������
         mov dx,0x1f0
  .readw:
         in ax,dx
         mov [ebx],ax
         add ebx,2
         loop .readw

         pop edx
         pop ecx
         pop eax
      
         retf                               ;�μ䷵�� 

;-------------------------------------------------------------------------------
;������Գ����Ǽ���һ�γɹ������ҵ��Էǳ����ѡ�������̿����ṩ���� 
put_hex_dword:                              ;�ڵ�ǰ��괦��ʮ��������ʽ��ʾ
                                            ;һ��˫�ֲ��ƽ���� 
                                            ;���룺EDX=Ҫת������ʾ������
                                            ;�������
         pushad
         push ds
      
         mov ax,core_data_seg_sel           ;�л����������ݶ� 
         mov ds,ax
      
         mov ebx,bin_hex                    ;ָ��������ݶ��ڵ�ת����
         mov ecx,8
  .xlt:    
         rol edx,4
         mov eax,edx
         and eax,0x0000000f
         xlat
      
         push ecx
         mov cl,al                           
         call put_char
         pop ecx
       
         loop .xlt
      
         pop ds
         popad
         
         retf
      
;-------------------------------------------------------------------------------
set_up_gdt_descriptor:                      ;��GDT�ڰ�װһ���µ�������
                                            ;���룺EDX:EAX=������ 
                                            ;�����CX=��������ѡ����
         push eax
         push ebx
         push edx

         push ds
         push es

         mov ebx,core_data_seg_sel          ;�л����������ݶ�
         mov ds,ebx

         sgdt [pgdt]                        ;�Ա㿪ʼ����GDT

         mov ebx,mem_0_4_gb_seg_sel
         mov es,ebx

         movzx ebx,word [pgdt]              ;GDT����
         inc bx                             ;GDT���ֽ�����Ҳ����һ��������ƫ��
         add ebx,[pgdt+2]                   ;��һ�������������Ե�ַ

         mov [es:ebx],eax
         mov [es:ebx+4],edx

         add word [pgdt],8                  ;����һ���������Ĵ�С

         lgdt [pgdt]                        ;��GDT�ĸ�����Ч

         mov ax,[pgdt]                      ;�õ�GDT����ֵ
         xor dx,dx
         mov bx,8
         div bx                             ;����8��ȥ������
         mov cx,ax
         shl cx,3                           ;���������Ƶ���ȷλ��

         pop es
         pop ds

         pop edx
         pop ebx
         pop eax

         retf
;-------------------------------------------------------------------------------
make_seg_descriptor:                        ;����洢����ϵͳ�Ķ�������
                                            ;���룺EAX=���Ի���ַ
                                            ;      EBX=�ν���
                                            ;      ECX=���ԡ�������λ����ԭʼ
                                            ;          λ�ã��޹ص�λ���� 
                                            ;���أ�EDX:EAX=������
         mov edx,eax
         shl eax,16
         or ax,bx                           ;������ǰ32λ(EAX)�������

         and edx,0xffff0000                 ;�������ַ���޹ص�λ
         rol edx,8
         bswap edx                          ;װ���ַ��31~24��23~16  (80486+)

         xor bx,bx
         or edx,ebx                         ;װ��ν��޵ĸ�4λ

         or edx,ecx                         ;װ������

         retf

;-------------------------------------------------------------------------------
make_gate_descriptor:                       ;�����ŵ��������������ŵȣ�
                                            ;���룺EAX=�Ŵ����ڶ���ƫ�Ƶ�ַ
                                            ;       BX=�Ŵ������ڶε�ѡ���� 
                                            ;       CX=�����ͼ����Եȣ�����
                                            ;          ��λ����ԭʼλ�ã�
                                            ;���أ�EDX:EAX=������������
         push ebx
         push ecx
      
         mov edx,eax
         and edx,0xffff0000                 ;�õ�ƫ�Ƶ�ַ��16λ 
         or dx,cx                           ;��װ���Բ��ֵ�EDX
       
         and eax,0x0000ffff                 ;�õ�ƫ�Ƶ�ַ��16λ 
         shl ebx,16                          
         or eax,ebx                         ;��װ��ѡ���Ӳ���
      
         pop ecx
         pop ebx
      
         retf                                   
                             
;-------------------------------------------------------------------------------
allocate_a_4k_page:                         ;����һ��4KB��ҳ
                                            ;���룺��
                                            ;�����EAX=ҳ�������ַ
         push ebx
         push ecx
         push edx
         push ds
         
         mov eax,core_data_seg_sel
         mov ds,eax
         
         xor eax,eax
  .b1:
         bts [page_bit_map],eax
         jnc .b2
         inc eax
         cmp eax,page_map_len*8
         jl .b1
         
         mov ebx,message_3
         call sys_routine_seg_sel:put_string
         hlt                                ;û�п��Է����ҳ��ͣ�� 
         
  .b2:
         shl eax,12                         ;����4096��0x1000�� 
         
         pop ds
         pop edx
         pop ecx
         pop ebx
         
         ret
         
;-------------------------------------------------------------------------------
alloc_inst_a_page:                          ;����һ��ҳ������װ�ڵ�ǰ���
                                            ;�㼶��ҳ�ṹ��
                                            ;���룺EBX=ҳ�����Ե�ַ
         push eax
         push ebx
         push esi
         push ds
         
         mov eax,mem_0_4_gb_seg_sel
         mov ds,eax
         
         ;�������Ե�ַ����Ӧ��ҳ���Ƿ����
         mov esi,ebx
         and esi,0xffc00000
         shr esi,20                         ;�õ�ҳĿ¼������������4 
         or esi,0xfffff000                  ;ҳĿ¼��������Ե�ַ+����ƫ�� 

         test dword [esi],0x00000001        ;Pλ�Ƿ�Ϊ��1�����������Ե�ַ�� 
         jnz .b1                            ;���Ѿ��ж�Ӧ��ҳ��
          
         ;���������Ե�ַ����Ӧ��ҳ�� 
         call allocate_a_4k_page            ;����һ��ҳ��Ϊҳ�� 
         or eax,0x00000007
         mov [esi],eax                      ;��ҳĿ¼�еǼǸ�ҳ��
          
  .b1:
         ;��ʼ���ʸ����Ե�ַ����Ӧ��ҳ�� 
         mov esi,ebx
         shr esi,10
         and esi,0x003ff000                 ;����0xfffff000�����10λ���� 
         or esi,0xffc00000                  ;�õ���ҳ������Ե�ַ
         
         ;�õ������Ե�ַ��ҳ���ڵĶ�Ӧ��Ŀ��ҳ��� 
         and ebx,0x003ff000
         shr ebx,10                         ;�൱������12λ���ٳ���4
         or esi,ebx                         ;ҳ��������Ե�ַ 
         call allocate_a_4k_page            ;����һ��ҳ�������Ҫ��װ��ҳ
         or eax,0x00000007
         mov [esi],eax 
          
         pop ds
         pop esi
         pop ebx
         pop eax
         
         retf  

;-------------------------------------------------------------------------------
create_copy_cur_pdir:                       ;������ҳĿ¼�������Ƶ�ǰҳĿ¼����
                                            ;���룺��
                                            ;�����EAX=��ҳĿ¼�������ַ 
         push ds
         push es
         push esi
         push edi
         push ebx
         push ecx
         
         mov ebx,mem_0_4_gb_seg_sel
         mov ds,ebx
         mov es,ebx
         
         call allocate_a_4k_page            
         mov ebx,eax
         or ebx,0x00000007
         mov [0xfffffff8],ebx
         
         mov esi,0xfffff000                 ;ESI->��ǰҳĿ¼�����Ե�ַ
         mov edi,0xffffe000                 ;EDI->��ҳĿ¼�����Ե�ַ
         mov ecx,1024                       ;ECX=Ҫ���Ƶ�Ŀ¼����
         cld
         repe movsd 
         
         pop ecx
         pop ebx
         pop edi
         pop esi
         pop es
         pop ds
         
         retf
         
;-------------------------------------------------------------------------------
terminate_current_task:                     ;��ֹ��ǰ����
                                            ;ע�⣬ִ�д�����ʱ����ǰ��������
                                            ;�����С���������ʵҲ�ǵ�ǰ�����
                                            ;һ���� 
         mov eax,core_data_seg_sel
         mov ds,eax

         pushfd
         pop edx
 
         test dx,0100_0000_0000_0000B       ;����NTλ
         jnz .b1                            ;��ǰ������Ƕ�׵ģ���.b1ִ��iretd 
         jmp far [program_man_tss]          ;������������� 
  .b1: 
         iretd

sys_routine_end:

;===============================================================================
SECTION core_data vstart=0                  ;ϵͳ���ĵ����ݶ� 
;------------------------------------------------------------------------------- 
         pgdt             dw  0             ;�������ú��޸�GDT 
                          dd  0

         page_bit_map     db  0xff,0xff,0xff,0xff,0xff,0x55,0x55,0xff
                          db  0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
                          db  0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
                          db  0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff
                          db  0x55,0x55,0x55,0x55,0x55,0x55,0x55,0x55
                          db  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
                          db  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
                          db  0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
         page_map_len     equ $-page_bit_map
                          
         ;���ŵ�ַ������
         salt:
         salt_1           db  '@PrintString'
                     times 256-($-salt_1) db 0
                          dd  put_string
                          dw  sys_routine_seg_sel

         salt_2           db  '@ReadDiskData'
                     times 256-($-salt_2) db 0
                          dd  read_hard_disk_0
                          dw  sys_routine_seg_sel

         salt_3           db  '@PrintDwordAsHexString'
                     times 256-($-salt_3) db 0
                          dd  put_hex_dword
                          dw  sys_routine_seg_sel

         salt_4           db  '@TerminateProgram'
                     times 256-($-salt_4) db 0
                          dd  terminate_current_task
                          dw  sys_routine_seg_sel

         salt_item_len   equ $-salt_4
         salt_items      equ ($-salt)/salt_item_len

         message_0        db  '  Working in system core,protect mode.'
                          db  0x0d,0x0a,0

         message_1        db  '  Paging is enabled.System core is mapped to'
                          db  ' address 0x80000000.',0x0d,0x0a,0
         
         message_2        db  0x0d,0x0a
                          db  '  System wide CALL-GATE mounted.',0x0d,0x0a,0
         
         message_3        db  '********No more pages********',0
         
         message_4        db  0x0d,0x0a,'  Task switching...@_@',0x0d,0x0a,0
         
         message_5        db  0x0d,0x0a,'  Processor HALT.',0
         
        
         bin_hex          db '0123456789ABCDEF'
                                            ;put_hex_dword�ӹ����õĲ��ұ� 

         core_buf   times 512 db 0          ;�ں��õĻ�����

         cpu_brnd0        db 0x0d,0x0a,'  ',0
         cpu_brand  times 52 db 0
         cpu_brnd1        db 0x0d,0x0a,0x0d,0x0a,0

         ;������ƿ���
         tcb_chain        dd  0

         ;�ں���Ϣ
         core_next_laddr  dd  0x80100000    ;�ں˿ռ�����һ���ɷ�������Ե�ַ        
         program_man_tss  dd  0             ;�����������TSS������ѡ���� 
                          dw  0

core_data_end:
               
;===============================================================================
SECTION core_code vstart=0
;-------------------------------------------------------------------------------
fill_descriptor_in_ldt:                     ;��LDT�ڰ�װһ���µ�������
                                            ;���룺EDX:EAX=������
                                            ;          EBX=TCB����ַ
                                            ;�����CX=��������ѡ����
         push eax
         push edx
         push edi
         push ds

         mov ecx,mem_0_4_gb_seg_sel
         mov ds,ecx

         mov edi,[ebx+0x0c]                 ;���LDT����ַ
         
         xor ecx,ecx
         mov cx,[ebx+0x0a]                  ;���LDT����
         inc cx                             ;LDT�����ֽ���������������ƫ�Ƶ�ַ
         
         mov [edi+ecx+0x00],eax
         mov [edi+ecx+0x04],edx             ;��װ������

         add cx,8                           
         dec cx                             ;�õ��µ�LDT����ֵ 

         mov [ebx+0x0a],cx                  ;����LDT����ֵ��TCB

         mov ax,cx
         xor dx,dx
         mov cx,8
         div cx
         
         mov cx,ax
         shl cx,3                           ;����3λ������
         or cx,0000_0000_0000_0100B         ;ʹTIλ=1��ָ��LDT�����ʹRPL=00 

         pop ds
         pop edi
         pop edx
         pop eax
     
         ret
      
;-------------------------------------------------------------------------------
load_relocate_program:                      ;���ز��ض�λ�û�����
                                            ;����: PUSH �߼�������
                                            ;      PUSH ������ƿ����ַ
                                            ;������� 
         pushad
      
         push ds
         push es
      
         mov ebp,esp                        ;Ϊ����ͨ����ջ���ݵĲ�����׼��
      
         mov ecx,mem_0_4_gb_seg_sel
         mov es,ecx
      
         ;��յ�ǰҳĿ¼��ǰ�벿�֣���Ӧ��2GB�ľֲ���ַ�ռ䣩 
         mov ebx,0xfffff000
         xor esi,esi
  .b1:
         mov dword [es:ebx+esi*4],0x00000000
         inc esi
         cmp esi,512
         jl .b1
         
         ;���¿�ʼ�����ڴ沢�����û�����
         mov eax,core_data_seg_sel
         mov ds,eax                         ;�л�DS���ں����ݶ�

         mov eax,[ebp+12*4]                 ;�Ӷ�ջ��ȡ���û�������ʼ������
         mov ebx,core_buf                   ;��ȡ����ͷ������
         call sys_routine_seg_sel:read_hard_disk_0

         ;�����ж����������ж��
         mov eax,[core_buf]                 ;����ߴ�
         mov ebx,eax
         and ebx,0xfffff000                 ;ʹ֮4KB���� 
         add ebx,0x1000                        
         test eax,0x00000fff                ;����Ĵ�С������4KB�ı�����? 
         cmovnz eax,ebx                     ;���ǡ�ʹ�ô����Ľ��

         mov ecx,eax
         shr ecx,12                         ;����ռ�õ���4KBҳ�� 
         
         mov eax,mem_0_4_gb_seg_sel         ;�л�DS��0-4GB�Ķ�
         mov ds,eax

         mov eax,[ebp+12*4]                 ;��ʼ������
         mov esi,[ebp+11*4]                 ;�Ӷ�ջ��ȡ��TCB�Ļ���ַ
  .b2:
         mov ebx,[es:esi+0x06]              ;ȡ�ÿ��õ����Ե�ַ
         add dword [es:esi+0x06],0x1000
         call sys_routine_seg_sel:alloc_inst_a_page

         push ecx
         mov ecx,8
  .b3:
         call sys_routine_seg_sel:read_hard_disk_0
         inc eax
         loop .b3

         pop ecx
         loop .b2

         ;���ں˵�ַ�ռ��ڴ����û������TSS
         mov eax,core_data_seg_sel          ;�л�DS���ں����ݶ�
         mov ds,eax

         mov ebx,[core_next_laddr]          ;�û������TSS������ȫ�ֿռ��Ϸ��� 
         call sys_routine_seg_sel:alloc_inst_a_page
         add dword [core_next_laddr],4096
         
         mov [es:esi+0x14],ebx              ;��TCB����дTSS�����Ե�ַ 
         mov word [es:esi+0x12],103         ;��TCB����дTSS�Ľ���ֵ 
          
         ;���û�����ľֲ���ַ�ռ��ڴ���LDT 
         mov ebx,[es:esi+0x06]              ;��TCB��ȡ�ÿ��õ����Ե�ַ
         add dword [es:esi+0x06],0x1000
         call sys_routine_seg_sel:alloc_inst_a_page
         mov [es:esi+0x0c],ebx              ;��дLDT���Ե�ַ��TCB�� 

         ;������������������
         mov eax,0x00000000
         mov ebx,0x000fffff                 
         mov ecx,0x00c0f800                 ;4KB���ȵĴ��������������Ȩ��3
         call sys_routine_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0011B         ;����ѡ���ӵ���Ȩ��Ϊ3
         
         mov ebx,[es:esi+0x14]              ;��TCB�л�ȡTSS�����Ե�ַ
         mov [es:ebx+76],cx                 ;��дTSS��CS�� 

         ;�����������ݶ�������
         mov eax,0x00000000
         mov ebx,0x000fffff                 
         mov ecx,0x00c0f200                 ;4KB���ȵ����ݶ�����������Ȩ��3
         call sys_routine_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0011B         ;����ѡ���ӵ���Ȩ��Ϊ3
         
         mov ebx,[es:esi+0x14]              ;��TCB�л�ȡTSS�����Ե�ַ
         mov [es:ebx+84],cx                 ;��дTSS��DS�� 
         mov [es:ebx+72],cx                 ;��дTSS��ES��
         mov [es:ebx+88],cx                 ;��дTSS��FS��
         mov [es:ebx+92],cx                 ;��дTSS��GS��
         
         ;�����ݶ���Ϊ�û������3��Ȩ�����ж�ջ 
         mov ebx,[es:esi+0x06]              ;��TCB��ȡ�ÿ��õ����Ե�ַ
         add dword [es:esi+0x06],0x1000
         call sys_routine_seg_sel:alloc_inst_a_page
         
         mov ebx,[es:esi+0x14]              ;��TCB�л�ȡTSS�����Ե�ַ
         mov [es:ebx+80],cx                 ;��дTSS��SS��
         mov edx,[es:esi+0x06]              ;��ջ�ĸ߶����Ե�ַ 
         mov [es:ebx+56],edx                ;��дTSS��ESP�� 

         ;���û�����ľֲ���ַ�ռ��ڴ���0��Ȩ����ջ
         mov ebx,[es:esi+0x06]              ;��TCB��ȡ�ÿ��õ����Ե�ַ
         add dword [es:esi+0x06],0x1000
         call sys_routine_seg_sel:alloc_inst_a_page

         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c09200                 ;4KB���ȵĶ�ջ������������Ȩ��0
         call sys_routine_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0000B         ;����ѡ���ӵ���Ȩ��Ϊ0

         mov ebx,[es:esi+0x14]              ;��TCB�л�ȡTSS�����Ե�ַ
         mov [es:ebx+8],cx                  ;��дTSS��SS0��
         mov edx,[es:esi+0x06]              ;��ջ�ĸ߶����Ե�ַ
         mov [es:ebx+4],edx                 ;��дTSS��ESP0�� 

         ;���û�����ľֲ���ַ�ռ��ڴ���1��Ȩ����ջ
         mov ebx,[es:esi+0x06]              ;��TCB��ȡ�ÿ��õ����Ե�ַ
         add dword [es:esi+0x06],0x1000
         call sys_routine_seg_sel:alloc_inst_a_page

         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c0b200                 ;4KB���ȵĶ�ջ������������Ȩ��1
         call sys_routine_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0001B         ;����ѡ���ӵ���Ȩ��Ϊ1

         mov ebx,[es:esi+0x14]              ;��TCB�л�ȡTSS�����Ե�ַ
         mov [es:ebx+16],cx                 ;��дTSS��SS1��
         mov edx,[es:esi+0x06]              ;��ջ�ĸ߶����Ե�ַ
         mov [es:ebx+12],edx                ;��дTSS��ESP1�� 

         ;���û�����ľֲ���ַ�ռ��ڴ���2��Ȩ����ջ
         mov ebx,[es:esi+0x06]              ;��TCB��ȡ�ÿ��õ����Ե�ַ
         add dword [es:esi+0x06],0x1000
         call sys_routine_seg_sel:alloc_inst_a_page

         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c0d200                 ;4KB���ȵĶ�ջ������������Ȩ��2
         call sys_routine_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0010B         ;����ѡ���ӵ���Ȩ��Ϊ2

         mov ebx,[es:esi+0x14]              ;��TCB�л�ȡTSS�����Ե�ַ
         mov [es:ebx+24],cx                 ;��дTSS��SS2��
         mov edx,[es:esi+0x06]              ;��ջ�ĸ߶����Ե�ַ
         mov [es:ebx+20],edx                ;��дTSS��ESP2�� 


         ;�ض�λSALT 
         mov eax,mem_0_4_gb_seg_sel         ;���������4GB�����ַ�ռ�ʱ�� 
         mov es,eax                         
                                                    
         mov eax,core_data_seg_sel
         mov ds,eax
      
         cld

         mov ecx,[es:0x0c]                  ;U-SALT��Ŀ�� 
         mov edi,[es:0x08]                  ;U-SALT��4GB�ռ��ڵ�ƫ�� 
  .b4:
         push ecx
         push edi
      
         mov ecx,salt_items
         mov esi,salt
  .b5:
         push edi
         push esi
         push ecx

         mov ecx,64                         ;�������У�ÿ��Ŀ�ıȽϴ��� 
         repe cmpsd                         ;ÿ�αȽ�4�ֽ� 
         jnz .b6
         mov eax,[esi]                      ;��ƥ�䣬��esiǡ��ָ�����ĵ�ַ
         mov [es:edi-256],eax               ;���ַ�����д��ƫ�Ƶ�ַ 
         mov ax,[esi+4]
         or ax,0000000000000011B            ;���û������Լ�����Ȩ��ʹ�õ�����
                                            ;��RPL=3 
         mov [es:edi-252],ax                ;���������ѡ���� 
  .b6:
      
         pop ecx
         pop esi
         add esi,salt_item_len
         pop edi                            ;��ͷ�Ƚ� 
         loop .b5
      
         pop edi
         add edi,256
         pop ecx
         loop .b4

         ;��GDT�еǼ�LDT������
         mov esi,[ebp+11*4]                 ;�Ӷ�ջ��ȡ��TCB�Ļ���ַ
         mov eax,[es:esi+0x0c]              ;LDT����ʼ���Ե�ַ
         movzx ebx,word [es:esi+0x0a]       ;LDT�ν���
         mov ecx,0x00408200                 ;LDT����������Ȩ��0
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [es:esi+0x10],cx               ;�Ǽ�LDTѡ���ӵ�TCB��

         mov ebx,[es:esi+0x14]              ;��TCB�л�ȡTSS�����Ե�ַ
         mov [es:ebx+96],cx                 ;��дTSS��LDT�� 

         mov word [es:ebx+0],0              ;������=0
      
         mov dx,[es:esi+0x12]               ;�γ��ȣ����ޣ�
         mov [es:ebx+102],dx                ;��дTSS��I/Oλͼƫ���� 
      
         mov word [es:ebx+100],0            ;T=0
      
         mov eax,[es:0x04]                  ;�������4GB��ַ�ռ��ȡ��ڵ� 
         mov [es:ebx+32],eax                ;��дTSS��EIP�� 

         pushfd
         pop edx
         mov [es:ebx+36],edx                ;��дTSS��EFLAGS�� 

         ;��GDT�еǼ�TSS������
         mov eax,[es:esi+0x14]              ;��TCB�л�ȡTSS����ʼ���Ե�ַ
         movzx ebx,word [es:esi+0x12]       ;�γ��ȣ����ޣ�
         mov ecx,0x00408900                 ;TSS����������Ȩ��0
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [es:esi+0x18],cx               ;�Ǽ�TSSѡ���ӵ�TCB

         ;�����û������ҳĿ¼
         ;ע�⣡ҳ�ķ����ʹ������ҳλͼ�����ģ����Բ�ռ�����Ե�ַ�ռ� 
         call sys_routine_seg_sel:create_copy_cur_pdir
         mov ebx,[es:esi+0x14]              ;��TCB�л�ȡTSS�����Ե�ַ
         mov dword [es:ebx+28],eax          ;��дTSS��CR3(PDBR)��
                   
         pop es                             ;�ָ������ô˹���ǰ��es�� 
         pop ds                             ;�ָ������ô˹���ǰ��ds��
      
         popad
      
         ret 8                              ;�������ñ�����ǰѹ��Ĳ��� 
      
;-------------------------------------------------------------------------------
append_to_tcb_link:                         ;��TCB����׷��������ƿ�
                                            ;���룺ECX=TCB���Ի���ַ
         push eax
         push edx
         push ds
         push es
         
         mov eax,core_data_seg_sel          ;��DSָ���ں����ݶ� 
         mov ds,eax
         mov eax,mem_0_4_gb_seg_sel         ;��ESָ��0..4GB��
         mov es,eax
         
         mov dword [es: ecx+0x00],0         ;��ǰTCBָ�������㣬��ָʾ������
                                            ;��һ��TCB
                                             
         mov eax,[tcb_chain]                ;TCB��ͷָ��
         or eax,eax                         ;����Ϊ�գ�
         jz .notcb 
         
  .searc:
         mov edx,eax
         mov eax,[es: edx+0x00]
         or eax,eax               
         jnz .searc
         
         mov [es: edx+0x00],ecx
         jmp .retpc
         
  .notcb:       
         mov [tcb_chain],ecx                ;��Ϊ�ձ�ֱ�����ͷָ��ָ��TCB
         
  .retpc:
         pop es
         pop ds
         pop edx
         pop eax
         
         ret
         
;-------------------------------------------------------------------------------
start:
         mov ecx,core_data_seg_sel          ;��DSָ��������ݶ� 
         mov ds,ecx

         mov ecx,mem_0_4_gb_seg_sel         ;��ESָ��4GB���ݶ� 
         mov es,ecx

         mov ebx,message_0                    
         call sys_routine_seg_sel:put_string
                                         
         ;��ʾ������Ʒ����Ϣ 
         mov eax,0x80000002
         cpuid
         mov [cpu_brand + 0x00],eax
         mov [cpu_brand + 0x04],ebx
         mov [cpu_brand + 0x08],ecx
         mov [cpu_brand + 0x0c],edx
      
         mov eax,0x80000003
         cpuid
         mov [cpu_brand + 0x10],eax
         mov [cpu_brand + 0x14],ebx
         mov [cpu_brand + 0x18],ecx
         mov [cpu_brand + 0x1c],edx

         mov eax,0x80000004
         cpuid
         mov [cpu_brand + 0x20],eax
         mov [cpu_brand + 0x24],ebx
         mov [cpu_brand + 0x28],ecx
         mov [cpu_brand + 0x2c],edx

         mov ebx,cpu_brnd0                  ;��ʾ������Ʒ����Ϣ 
         call sys_routine_seg_sel:put_string
         mov ebx,cpu_brand
         call sys_routine_seg_sel:put_string
         mov ebx,cpu_brnd1
         call sys_routine_seg_sel:put_string

         ;׼���򿪷�ҳ����
         
         ;����ϵͳ�ں˵�ҳĿ¼��PDT
         ;ҳĿ¼������ 
         mov ecx,1024                       ;1024��Ŀ¼��
         mov ebx,0x00020000                 ;ҳĿ¼�������ַ
         xor esi,esi
  .b1:
         mov dword [es:ebx+esi],0x00000000  ;ҳĿ¼�������� 
         add esi,4
         loop .b1
         
         ;��ҳĿ¼�ڴ���ָ��ҳĿ¼�Լ���Ŀ¼��
         mov dword [es:ebx+4092],0x00020003 

         ;��ҳĿ¼�ڴ��������Ե�ַ0x00000000��Ӧ��Ŀ¼��
         mov dword [es:ebx+0],0x00021003    ;д��Ŀ¼�ҳ��������ַ�����ԣ�      

         ;�����������Ǹ�Ŀ¼�����Ӧ��ҳ����ʼ��ҳ���� 
         mov ebx,0x00021000                 ;ҳ��������ַ
         xor eax,eax                        ;��ʼҳ�������ַ 
         xor esi,esi
  .b2:       
         mov edx,eax
         or edx,0x00000003                                                      
         mov [es:ebx+esi*4],edx             ;�Ǽ�ҳ�������ַ
         add eax,0x1000                     ;��һ������ҳ�������ַ 
         inc esi
         cmp esi,256                        ;���Ͷ�1MB�ڴ��Ӧ��ҳ������Ч�� 
         jl .b2
         
  .b3:                                      ;�����ҳ������Ϊ��Ч
         mov dword [es:ebx+esi*4],0x00000000  
         inc esi
         cmp esi,1024
         jl .b3 

         ;��CR3�Ĵ���ָ��ҳĿ¼������ʽ����ҳ���� 
         mov eax,0x00020000                 ;PCD=PWT=0
         mov cr3,eax

         mov eax,cr0
         or eax,0x80000000
         mov cr0,eax                        ;������ҳ����

         ;��ҳĿ¼�ڴ��������Ե�ַ0x80000000��Ӧ��Ŀ¼��
         mov ebx,0xfffff000                 ;ҳĿ¼�Լ������Ե�ַ 
         mov esi,0x80000000                 ;ӳ�����ʼ��ַ
         shr esi,22                         ;���Ե�ַ�ĸ�10λ��Ŀ¼����
         shl esi,2
         mov dword [es:ebx+esi],0x00021003  ;д��Ŀ¼�ҳ��������ַ�����ԣ�
                                            ;Ŀ�굥Ԫ�����Ե�ַΪ0xFFFFF200
                                             
         ;��GDT�еĶ�������ӳ�䵽���Ե�ַ0x80000000
         sgdt [pgdt]
         
         mov ebx,[pgdt+2]
         
         or dword [es:ebx+0x10+4],0x80000000
         or dword [es:ebx+0x18+4],0x80000000
         or dword [es:ebx+0x20+4],0x80000000
         or dword [es:ebx+0x28+4],0x80000000
         or dword [es:ebx+0x30+4],0x80000000
         or dword [es:ebx+0x38+4],0x80000000
         
         add dword [pgdt+2],0x80000000      ;GDTRҲ�õ������Ե�ַ 
         
         lgdt [pgdt]
        
         jmp core_code_seg_sel:flush        ;ˢ�¶μĴ���CS�����ø߶����Ե�ַ 
                                             
   flush:
         mov eax,core_stack_seg_sel
         mov ss,eax
         
         mov eax,core_data_seg_sel
         mov ds,eax
          
         mov ebx,message_1
         call sys_routine_seg_sel:put_string

         ;���¿�ʼ��װΪ����ϵͳ����ĵ����š���Ȩ��֮��Ŀ���ת�Ʊ���ʹ����
         mov edi,salt                       ;C-SALT�����ʼλ�� 
         mov ecx,salt_items                 ;C-SALT�����Ŀ���� 
  .b4:
         push ecx   
         mov eax,[edi+256]                  ;����Ŀ��ڵ��32λƫ�Ƶ�ַ 
         mov bx,[edi+260]                   ;����Ŀ��ڵ�Ķ�ѡ���� 
         mov cx,1_11_0_1100_000_00000B      ;��Ȩ��3�ĵ�����(3���ϵ���Ȩ����
                                            ;�������)��0������(��Ϊ�üĴ���
                                            ;���ݲ�������û����ջ) 
         call sys_routine_seg_sel:make_gate_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+260],cx                   ;�����ص���������ѡ���ӻ���
         add edi,salt_item_len              ;ָ����һ��C-SALT��Ŀ 
         pop ecx
         loop .b4

         ;���Ž��в��� 
         mov ebx,message_2
         call far [salt_1+256]              ;ͨ������ʾ��Ϣ(ƫ������������) 
      
         ;Ϊ�����������TSS�����ڴ�ռ�
         mov ebx,[core_next_laddr]
         call sys_routine_seg_sel:alloc_inst_a_page
         add dword [core_next_laddr],4096

         ;�ڳ����������TSS�����ñ�Ҫ����Ŀ 
         mov word [es:ebx+0],0              ;������=0

         mov eax,cr3
         mov dword [es:ebx+28],eax          ;�Ǽ�CR3(PDBR)

         mov word [es:ebx+96],0             ;û��LDT������������û��LDT������
         mov word [es:ebx+100],0            ;T=0
         mov word [es:ebx+102],103          ;û��I/Oλͼ��0��Ȩ����ʵ�ϲ���Ҫ��
         
         ;���������������TSS������������װ��GDT�� 
         mov eax,ebx                        ;TSS����ʼ���Ե�ַ
         mov ebx,103                        ;�γ��ȣ����ޣ�
         mov ecx,0x00408900                 ;TSS����������Ȩ��0
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [program_man_tss+4],cx         ;��������������TSS������ѡ���� 

         ;����Ĵ���TR�е�������������ڵı�־��������Ҳ�����˵�ǰ������˭��
         ;�����ָ��Ϊ��ǰ����ִ�е�0��Ȩ�����񡰳������������������TSS����
         ltr cx

         ;���ڿ���Ϊ�������������������ִ����

         ;�����û������������ƿ� 
         mov ebx,[core_next_laddr]
         call sys_routine_seg_sel:alloc_inst_a_page
         add dword [core_next_laddr],4096
         
         mov dword [es:ebx+0x06],0          ;�û�����ֲ��ռ�ķ����0��ʼ��
         mov word [es:ebx+0x0a],0xffff      ;�Ǽ�LDT��ʼ�Ľ��޵�TCB��
         mov ecx,ebx
         call append_to_tcb_link            ;����TCB��ӵ�TCB���� 
      
         push dword 50                      ;�û�����λ���߼�50����
         push ecx                           ;ѹ��������ƿ���ʼ���Ե�ַ 
       
         call load_relocate_program         
      
         mov ebx,message_4
         call sys_routine_seg_sel:put_string
         
         call far [es:ecx+0x14]             ;ִ�������л���
         
         mov ebx,message_5
         call sys_routine_seg_sel:put_string

         hlt
            
core_code_end:

;-------------------------------------------------------------------------------
SECTION core_trail
;-------------------------------------------------------------------------------
core_end: