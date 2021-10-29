         ;�����嵥13-2
         ;�ļ�����c13_core.asm
         ;�ļ�˵��������ģʽ΢�ͺ��ĳ��� 
         ;�������ڣ�2011-10-26 12:11

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
         mov eax,video_ram_seg_sel          ;0xb8000�ε�ѡ����
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
allocate_memory:                            ;�����ڴ�
                                            ;���룺ECX=ϣ��������ֽ���
                                            ;�����ECX=��ʼ���Ե�ַ 
         push ds
         push eax
         push ebx
      
         mov eax,core_data_seg_sel
         mov ds,eax
      
         mov eax,[ram_alloc]
         add eax,ecx                        ;��һ�η���ʱ����ʼ��ַ
      
         ;����Ӧ���м������ڴ�������ָ��
          
         mov ecx,[ram_alloc]                ;���ط������ʼ��ַ

         mov ebx,eax
         and ebx,0xfffffffc
         add ebx,4                          ;ǿ�ƶ��� 
         test eax,0x00000003                ;�´η������ʼ��ַ�����4�ֽڶ���
         cmovnz eax,ebx                     ;���û�ж��룬��ǿ�ƶ��� 
         mov [ram_alloc],eax                ;�´δӸõ�ַ�����ڴ�
                                            ;cmovccָ����Ա������ת�� 
         pop ebx
         pop eax
         pop ds

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

;===============================================================================
SECTION core_data vstart=0                  ;ϵͳ���ĵ����ݶ�
;-------------------------------------------------------------------------------
         pgdt             dw  0             ;�������ú��޸�GDT 
                          dd  0

         ram_alloc        dd  0x00100000    ;�´η����ڴ�ʱ����ʼ��ַ

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
                          dd  return_point
                          dw  core_code_seg_sel

         salt_item_len   equ $-salt_4
         salt_items      equ ($-salt)/salt_item_len

         message_1        db  '  If you seen this message,that means we '
                          db  'are now in protect mode,and the system '
                          db  'core is loaded,and the video display '
                          db  'routine works perfectly.',0x0d,0x0a,0

         message_5        db  '  Loading user program...',0
         
         do_status        db  'Done.',0x0d,0x0a,0
         
         message_6        db  0x0d,0x0a,0x0d,0x0a,0x0d,0x0a
                          db  '  User program terminated,control returned.',0

         bin_hex          db '0123456789ABCDEF'
                                            ;put_hex_dword�ӹ����õĲ��ұ� 
         core_buf   times 2048 db 0         ;�ں��õĻ�����

         esp_pointer      dd 0              ;�ں�������ʱ�����Լ���ջָ��     

         cpu_brnd0        db 0x0d,0x0a,'  ',0
         cpu_brand  times 52 db 0
         cpu_brnd1        db 0x0d,0x0a,0x0d,0x0a,0

;===============================================================================
SECTION core_code vstart=0
;-------------------------------------------------------------------------------
load_relocate_program:                      ;���ز��ض�λ�û�����
                                            ;���룺ESI=��ʼ�߼�������
                                            ;���أ�AX=ָ���û�����ͷ����ѡ���� 
         push ebx
         push ecx
         push edx
         push esi
         push edi
      
         push ds
         push es
      
         mov eax,core_data_seg_sel
         mov ds,eax                         ;�л�DS���ں����ݶ�
       
         mov eax,esi                        ;��ȡ����ͷ������ 
         mov ebx,core_buf                        
         call sys_routine_seg_sel:read_hard_disk_0

         ;�����ж����������ж��
         mov eax,[core_buf]                 ;����ߴ�
         mov ebx,eax
         and ebx,0xfffffe00                 ;ʹ֮512�ֽڶ��루�ܱ�512���������� 
         add ebx,512                        ;��9λ��Ϊ0 
         test eax,0x000001ff                ;����Ĵ�С������512�ı�����? 
         cmovnz eax,ebx                     ;���ǡ�ʹ�ô����Ľ�� 
      
         mov ecx,eax                        ;ʵ����Ҫ������ڴ�����
         call sys_routine_seg_sel:allocate_memory
         mov ebx,ecx                        ;ebx -> ���뵽���ڴ��׵�ַ
         push ebx                           ;������׵�ַ 
         xor edx,edx
         mov ecx,512
         div ecx
         mov ecx,eax                        ;�������� 
      
         mov eax,mem_0_4_gb_seg_sel         ;�л�DS��0-4GB�Ķ�
         mov ds,eax

         mov eax,esi                        ;��ʼ������ 
  .b1:
         call sys_routine_seg_sel:read_hard_disk_0
         inc eax
         loop .b1                           ;ѭ������ֱ�����������û�����

         ;��������ͷ����������
         pop edi                            ;�ָ�����װ�ص��׵�ַ 
         mov eax,edi                        ;����ͷ����ʼ���Ե�ַ
         mov ebx,[edi+0x04]                 ;�γ���
         dec ebx                            ;�ν��� 
         mov ecx,0x00409200                 ;�ֽ����ȵ����ݶ�������
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x04],cx                   

         ;������������������
         mov eax,edi
         add eax,[edi+0x14]                 ;������ʼ���Ե�ַ
         mov ebx,[edi+0x18]                 ;�γ���
         dec ebx                            ;�ν���
         mov ecx,0x00409800                 ;�ֽ����ȵĴ����������
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x14],cx

         ;�����������ݶ�������
         mov eax,edi
         add eax,[edi+0x1c]                 ;���ݶ���ʼ���Ե�ַ
         mov ebx,[edi+0x20]                 ;�γ���
         dec ebx                            ;�ν���
         mov ecx,0x00409200                 ;�ֽ����ȵ����ݶ�������
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x1c],cx

         ;���������ջ��������
         mov ecx,[edi+0x0c]                 ;4KB�ı��� 
         mov ebx,0x000fffff
         sub ebx,ecx                        ;�õ��ν���
         mov eax,4096                        
         mul dword [edi+0x0c]                         
         mov ecx,eax                        ;׼��Ϊ��ջ�����ڴ� 
         call sys_routine_seg_sel:allocate_memory
         add eax,ecx                        ;�õ���ջ�ĸ߶������ַ 
         mov ecx,0x00c09600                 ;4KB���ȵĶ�ջ��������
         call sys_routine_seg_sel:make_seg_descriptor
         call sys_routine_seg_sel:set_up_gdt_descriptor
         mov [edi+0x08],cx

         ;�ض�λSALT
         mov eax,[edi+0x04]
         mov es,eax                         ;es -> �û�����ͷ�� 
         mov eax,core_data_seg_sel
         mov ds,eax
      
         cld

         mov ecx,[es:0x24]                  ;�û������SALT��Ŀ��
         mov edi,0x28                       ;�û������ڵ�SALTλ��ͷ����0x2c��
  .b2: 
         push ecx
         push edi
      
         mov ecx,salt_items
         mov esi,salt
  .b3:
         push edi
         push esi
         push ecx

         mov ecx,64                         ;�������У�ÿ��Ŀ�ıȽϴ��� 
         repe cmpsd                         ;ÿ�αȽ�4�ֽ� 
         jnz .b4
         mov eax,[esi]                      ;��ƥ�䣬esiǡ��ָ�����ĵ�ַ����
         mov [es:edi-256],eax               ;���ַ�����д��ƫ�Ƶ�ַ 
         mov ax,[esi+4]
         mov [es:edi-252],ax                ;�Լ���ѡ���� 
  .b4:
      
         pop ecx
         pop esi
         add esi,salt_item_len
         pop edi                            ;��ͷ�Ƚ� 
         loop .b3
      
         pop edi
         add edi,256
         pop ecx
         loop .b2

         mov ax,[es:0x04]

         pop es                             ;�ָ������ô˹���ǰ��es�� 
         pop ds                             ;�ָ������ô˹���ǰ��ds��
      
         pop edi
         pop esi
         pop edx
         pop ecx
         pop ebx
      
         ret
      
;-------------------------------------------------------------------------------
start:
         mov ecx,core_data_seg_sel           ;ʹdsָ��������ݶ� 
         mov ds,ecx

         mov ebx,message_1
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

         mov ebx,cpu_brnd0
         call sys_routine_seg_sel:put_string
         mov ebx,cpu_brand
         call sys_routine_seg_sel:put_string
         mov ebx,cpu_brnd1
         call sys_routine_seg_sel:put_string

         mov ebx,message_5
         call sys_routine_seg_sel:put_string
         mov esi,50                          ;�û�����λ���߼�50���� 
         call load_relocate_program
      
         mov ebx,do_status
         call sys_routine_seg_sel:put_string
      
         mov [esp_pointer],esp               ;��ʱ�����ջָ��
       
         mov ds,ax
      
         jmp far [0x10]                      ;����Ȩ�����û�������ڵ㣩
                                             ;��ջ�����л� 

return_point:                                ;�û����򷵻ص�
         mov eax,core_data_seg_sel           ;ʹdsָ��������ݶ�
         mov ds,eax

         mov eax,core_stack_seg_sel          ;�л����ں��Լ��Ķ�ջ
         mov ss,eax 
         mov esp,[esp_pointer]

         mov ebx,message_6
         call sys_routine_seg_sel:put_string

         ;������Է�������û����������������ָ��
         ;Ҳ���Լ��ز�������������
       
         hlt
            
;===============================================================================
SECTION core_trail
;-------------------------------------------------------------------------------
core_end: