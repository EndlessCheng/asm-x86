         ;�����嵥17-2
         ;�ļ�����c17_core.asm
         ;�ļ�˵��������ģʽ΢�ͺ��ĳ��� 
         ;�������ڣ�2012-07-12 23:15
;-------------------------------------------------------------------------------
         ;���¶��峣��
         flat_4gb_code_seg_sel  equ  0x0008      ;ƽ̹ģ���µ�4GB�����ѡ���� 
         flat_4gb_data_seg_sel  equ  0x0018      ;ƽ̹ģ���µ�4GB���ݶ�ѡ���� 
         idt_linear_address     equ  0x8001f000  ;�ж�������������Ի���ַ 
;-------------------------------------------------------------------------------          
         ;���¶����
         %macro alloc_core_linear 0              ;���ں˿ռ��з��������ڴ� 
               mov ebx,[core_tcb+0x06]
               add dword [core_tcb+0x06],0x1000
               call flat_4gb_code_seg_sel:alloc_inst_a_page
         %endmacro 
;-------------------------------------------------------------------------------
         %macro alloc_user_linear 0              ;������ռ��з��������ڴ� 
               mov ebx,[esi+0x06]
               add dword [esi+0x06],0x1000
               call flat_4gb_code_seg_sel:alloc_inst_a_page
         %endmacro
         
;===============================================================================
SECTION  core  vstart=0x80040000

         ;������ϵͳ���ĵ�ͷ�������ڼ��غ��ĳ��� 
         core_length      dd core_end       ;���ĳ����ܳ���#00

         core_entry       dd start          ;���Ĵ������ڵ�#04

;-------------------------------------------------------------------------------
         [bits 32]
;-------------------------------------------------------------------------------
         ;�ַ�����ʾ���̣�������ƽ̹�ڴ�ģ�ͣ� 
put_string:                                 ;��ʾ0��ֹ���ַ������ƶ���� 
                                            ;���룺EBX=�ַ��������Ե�ַ

         push ebx
         push ecx

         cli                                ;Ӳ�������ڼ䣬���ж�

  .getc:
         mov cl,[ebx]
         or cl,cl                           ;��⴮������־��0�� 
         jz .exit                           ;��ʾ��ϣ����� 
         call put_char
         inc ebx
         jmp .getc

  .exit:

         sti                                ;Ӳ��������ϣ������ж�

         pop ecx
         pop ebx

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
         and ebx,0x0000ffff                 ;׼��ʹ��32λѰַ��ʽ�����Դ� 
         
         cmp cl,0x0d                        ;�س�����
         jnz .put_0a                         
         
         mov ax,bx                          ;���°��س������� 
         mov bl,80
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

  .put_0a:
         cmp cl,0x0a                        ;���з���
         jnz .put_other
         add bx,80                          ;����һ�� 
         jmp .roll_screen

  .put_other:                               ;������ʾ�ַ�
         shl bx,1
         mov [0x800b8000+ebx],cl            ;�ڹ��λ�ô���ʾ�ַ� 

         ;���½����λ���ƽ�һ���ַ�
         shr bx,1
         inc bx

  .roll_screen:
         cmp bx,2000                        ;��곬����Ļ������
         jl .set_cursor

         cld
         mov esi,0x800b80a0                 ;С�ģ�32λģʽ��movsb/w/d 
         mov edi,0x800b8000                 ;ʹ�õ���esi/edi/ecx 
         mov ecx,1920
         rep movsd
         mov bx,3840                        ;�����Ļ���һ��
         mov ecx,80                         ;32λ����Ӧ��ʹ��ECX
  .cls:
         mov word [0x800b8000+ebx],0x0720
         add bx,2
         loop .cls

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
read_hard_disk_0:                           ;��Ӳ�̶�ȡһ���߼�������ƽ̹ģ�ͣ� 
                                            ;EAX=�߼�������
                                            ;EBX=Ŀ�껺�������Ե�ַ
                                            ;���أ�EBX=EBX+512
         cli
         
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
      
         sti
      
         retf                               ;Զ���� 

;-------------------------------------------------------------------------------
;������Գ����Ǽ���һ�γɹ������ҵ��Էǳ����ѡ�������̿����ṩ���� 
put_hex_dword:                              ;�ڵ�ǰ��괦��ʮ��������ʽ��ʾ
                                            ;һ��˫�ֲ��ƽ���� 
                                            ;���룺EDX=Ҫת������ʾ������
                                            ;�������
         pushad

         mov ebx,bin_hex                    ;ָ����ĵ�ַ�ռ��ڵ�ת����
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
      
         popad
         retf
      
;-------------------------------------------------------------------------------
set_up_gdt_descriptor:                      ;��GDT�ڰ�װһ���µ�������
                                            ;���룺EDX:EAX=������ 
                                            ;�����CX=��������ѡ����
         push eax
         push ebx
         push edx

         sgdt [pgdt]                        ;ȡ��GDTR�Ľ��޺����Ե�ַ 

         movzx ebx,word [pgdt]              ;GDT����
         inc bx                             ;GDT���ֽ�����Ҳ����һ��������ƫ��
         add ebx,[pgdt+2]                   ;��һ�������������Ե�ַ

         mov [ebx],eax
         mov [ebx+4],edx

         add word [pgdt],8                  ;����һ���������Ĵ�С

         lgdt [pgdt]                        ;��GDT�ĸ�����Ч

         mov ax,[pgdt]                      ;�õ�GDT����ֵ
         xor dx,dx
         mov bx,8
         div bx                             ;����8��ȥ������
         mov cx,ax
         shl cx,3                           ;���������Ƶ���ȷλ��

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

         xor eax,eax
  .b1:
         bts [page_bit_map],eax
         jnc .b2
         inc eax
         cmp eax,page_map_len*8
         jl .b1
         
         mov ebx,message_3
         call flat_4gb_code_seg_sel:put_string
         hlt                                ;û�п��Է����ҳ��ͣ�� 
         
  .b2:
         shl eax,12                         ;����4096��0x1000�� 
         
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
          
         pop esi
         pop ebx
         pop eax
         
         retf  

;-------------------------------------------------------------------------------
create_copy_cur_pdir:                       ;������ҳĿ¼�������Ƶ�ǰҳĿ¼����
                                            ;���룺��
                                            ;�����EAX=��ҳĿ¼�������ַ 
         push esi
         push edi
         push ebx
         push ecx
         
         call allocate_a_4k_page            
         mov ebx,eax
         or ebx,0x00000007
         mov [0xfffffff8],ebx

         invlpg [0xfffffff8]

         mov esi,0xfffff000                 ;ESI->��ǰҳĿ¼�����Ե�ַ
         mov edi,0xffffe000                 ;EDI->��ҳĿ¼�����Ե�ַ
         mov ecx,1024                       ;ECX=Ҫ���Ƶ�Ŀ¼����
         cld
         repe movsd 
         
         pop ecx
         pop ebx
         pop edi
         pop esi
         
         retf
         
;-------------------------------------------------------------------------------
general_interrupt_handler:                  ;ͨ�õ��жϴ������
         push eax
          
         mov al,0x20                        ;�жϽ�������EOI 
         out 0xa0,al                        ;���Ƭ���� 
         out 0x20,al                        ;����Ƭ����
         
         pop eax
          
         iretd

;-------------------------------------------------------------------------------
general_exception_handler:                  ;ͨ�õ��쳣�������
         mov ebx,excep_msg
         call flat_4gb_code_seg_sel:put_string
         
         hlt

;-------------------------------------------------------------------------------
rtm_0x70_interrupt_handle:                  ;ʵʱʱ���жϴ������

         pushad

         mov al,0x20                        ;�жϽ�������EOI
         out 0xa0,al                        ;��8259A��Ƭ����
         out 0x20,al                        ;��8259A��Ƭ����

         mov al,0x0c                        ;�Ĵ���C���������ҿ���NMI
         out 0x70,al
         in al,0x71                         ;��һ��RTC�ļĴ���C������ֻ����һ���ж�
                                            ;�˴����������Ӻ��������жϵ����
         ;�ҵ�ǰ����״̬Ϊæ�������������е�λ��
         mov eax,tcb_chain                  
  .b0:                                      ;EAX=����ͷ��ǰTCB���Ե�ַ
         mov ebx,[eax]                      ;EBX=��һ��TCB���Ե�ַ
         or ebx,ebx
         jz .irtn                           ;����Ϊ�գ����ѵ�ĩβ�����жϷ���
         cmp word [ebx+0x04],0xffff         ;��æ���񣨵�ǰ���񣩣�
         je .b1
         mov eax,ebx                        ;��λ����һ��TCB�������Ե�ַ��
         jmp .b0         

         ;����ǰΪæ�������Ƶ���β
  .b1:
         mov ecx,[ebx]                      ;����TCB�����Ե�ַ
         mov [eax],ecx                      ;����ǰ��������в��

  .b2:                                      ;��ʱ��EBX=��ǰ��������Ե�ַ
         mov edx,[eax]
         or edx,edx                         ;�ѵ�����β�ˣ�
         jz .b3
         mov eax,edx
         jmp .b2

  .b3:
         mov [eax],ebx                      ;��æ�����TCB��������β��
         mov dword [ebx],0x00000000         ;��æ�����TCB���Ϊ��β

         ;������������һ����������
         mov eax,tcb_chain
  .b4:
         mov eax,[eax]
         or eax,eax                         ;�ѵ���β��δ���ֿ�������
         jz .irtn                           ;δ���ֿ������񣬴��жϷ���
         cmp word [eax+0x04],0x0000         ;�ǿ�������
         jnz .b4

         ;����������͵�ǰ�����״̬��ȡ��
         not word [eax+0x04]                ;���ÿ��������״̬Ϊæ
         not word [ebx+0x04]                ;���õ�ǰ����æ����״̬Ϊ����
         jmp far [eax+0x14]                 ;����ת��

  .irtn:
         popad

         iretd

;-------------------------------------------------------------------------------
terminate_current_task:                     ;��ֹ��ǰ����
                                            ;ע�⣬ִ�д�����ʱ����ǰ��������
                                            ;�����С���������ʵҲ�ǵ�ǰ�����
                                            ;һ���� 
         ;�ҵ�ǰ����״̬Ϊæ�������������е�λ��
         mov eax,tcb_chain
  .b0:                                      ;EAX=����ͷ��ǰTCB���Ե�ַ
         mov ebx,[eax]                      ;EBX=��һ��TCB���Ե�ַ
         cmp word [ebx+0x04],0xffff         ;��æ���񣨵�ǰ���񣩣�
         je .b1
         mov eax,ebx                        ;��λ����һ��TCB�������Ե�ַ��
         jmp .b0
         
  .b1:
         mov word [ebx+0x04],0x3333         ;�޸ĵ�ǰ�����״̬Ϊ���˳���
         
  .b2:
         hlt                                ;ͣ�����ȴ�����������ָ�����ʱ��
                                            ;������� 
         jmp .b2 

;------------------------------------------------------------------------------- 
         pgdt             dw  0             ;�������ú��޸�GDT 
                          dd  0

         pidt             dw  0
                          dd  0
                          
         ;������ƿ���
         tcb_chain        dd  0 

         core_tcb   times  32  db 0         ;�ںˣ��������������TCB

         page_bit_map     db  0xff,0xff,0xff,0xff,0xff,0xff,0x55,0x55
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
                          dw  flat_4gb_code_seg_sel

         salt_2           db  '@ReadDiskData'
                     times 256-($-salt_2) db 0
                          dd  read_hard_disk_0
                          dw  flat_4gb_code_seg_sel

         salt_3           db  '@PrintDwordAsHexString'
                     times 256-($-salt_3) db 0
                          dd  put_hex_dword
                          dw  flat_4gb_code_seg_sel

         salt_4           db  '@TerminateProgram'
                     times 256-($-salt_4) db 0
                          dd  terminate_current_task
                          dw  flat_4gb_code_seg_sel

         salt_item_len   equ $-salt_4
         salt_items      equ ($-salt)/salt_item_len

         excep_msg        db  '********Exception encounted********',0

         message_0        db  '  Working in system core with protection '
                          db  'and paging are all enabled.System core is mapped '
                          db  'to address 0x80000000.',0x0d,0x0a,0

         message_1        db  '  System wide CALL-GATE mounted.',0x0d,0x0a,0
         
         message_3        db  '********No more pages********',0
         
         core_msg0        db  '  System core task running!',0x0d,0x0a,0
         
         bin_hex          db '0123456789ABCDEF'
                                            ;put_hex_dword�ӹ����õĲ��ұ� 

         core_buf   times 512 db 0          ;�ں��õĻ�����

         cpu_brnd0        db 0x0d,0x0a,'  ',0
         cpu_brand  times 52 db 0
         cpu_brnd1        db 0x0d,0x0a,0x0d,0x0a,0

;-------------------------------------------------------------------------------
fill_descriptor_in_ldt:                     ;��LDT�ڰ�װһ���µ�������
                                            ;���룺EDX:EAX=������
                                            ;          EBX=TCB����ַ
                                            ;�����CX=��������ѡ����
         push eax
         push edx
         push edi

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
      
         mov ebp,esp                        ;Ϊ����ͨ����ջ���ݵĲ�����׼��
      
         ;��յ�ǰҳĿ¼��ǰ�벿�֣���Ӧ��2GB�ľֲ���ַ�ռ䣩 
         mov ebx,0xfffff000
         xor esi,esi
  .b1:
         mov dword [ebx+esi*4],0x00000000
         inc esi
         cmp esi,512
         jl .b1

         mov eax,cr3
         mov cr3,eax                        ;ˢ��TLB 
         
         ;���¿�ʼ�����ڴ沢�����û�����
         mov eax,[ebp+40]                   ;�Ӷ�ջ��ȡ���û�������ʼ������
         mov ebx,core_buf                   ;��ȡ����ͷ������
         call flat_4gb_code_seg_sel:read_hard_disk_0

         ;�����ж����������ж��
         mov eax,[core_buf]                 ;����ߴ�
         mov ebx,eax
         and ebx,0xfffff000                 ;ʹ֮4KB���� 
         add ebx,0x1000                        
         test eax,0x00000fff                ;����Ĵ�С������4KB�ı�����? 
         cmovnz eax,ebx                     ;���ǡ�ʹ�ô����Ľ��

         mov ecx,eax
         shr ecx,12                         ;����ռ�õ���4KBҳ�� 
         
         mov eax,[ebp+40]                   ;��ʼ������
         mov esi,[ebp+36]                   ;�Ӷ�ջ��ȡ��TCB�Ļ���ַ
  .b2:
         alloc_user_linear                  ;�꣺���û������ַ�ռ��Ϸ����ڴ� 
         
         push ecx
         mov ecx,8
  .b3:
         call flat_4gb_code_seg_sel:read_hard_disk_0               
         inc eax
         loop .b3

         pop ecx
         loop .b2

         ;���ں˵�ַ�ռ��ڴ����û������TSS
         alloc_core_linear                  ;�꣺���ں˵ĵ�ַ�ռ��Ϸ����ڴ�
                                            ;�û������TSS������ȫ�ֿռ��Ϸ��� 
         
         mov [esi+0x14],ebx                 ;��TCB����дTSS�����Ե�ַ 
         mov word [esi+0x12],103            ;��TCB����дTSS�Ľ���ֵ 
          
         ;���û�����ľֲ���ַ�ռ��ڴ���LDT 
         alloc_user_linear                  ;�꣺���û������ַ�ռ��Ϸ����ڴ�

         mov [esi+0x0c],ebx                 ;��дLDT���Ե�ַ��TCB�� 

         ;������������������
         mov eax,0x00000000
         mov ebx,0x000fffff                 
         mov ecx,0x00c0f800                 ;4KB���ȵĴ��������������Ȩ��3
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0011B         ;����ѡ���ӵ���Ȩ��Ϊ3
         
         mov ebx,[esi+0x14]                 ;��TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+76],cx                    ;��дTSS��CS�� 

         ;�����������ݶ�������
         mov eax,0x00000000
         mov ebx,0x000fffff                 
         mov ecx,0x00c0f200                 ;4KB���ȵ����ݶ�����������Ȩ��3
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0011B         ;����ѡ���ӵ���Ȩ��Ϊ3
         
         mov ebx,[esi+0x14]                 ;��TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+84],cx                    ;��дTSS��DS�� 
         mov [ebx+72],cx                    ;��дTSS��ES��
         mov [ebx+88],cx                    ;��дTSS��FS��
         mov [ebx+92],cx                    ;��дTSS��GS��
         
         ;�����ݶ���Ϊ�û������3��Ȩ�����ж�ջ 
         alloc_user_linear                  ;�꣺���û������ַ�ռ��Ϸ����ڴ�
         
         mov ebx,[esi+0x14]                 ;��TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+80],cx                    ;��дTSS��SS��
         mov edx,[esi+0x06]                 ;��ջ�ĸ߶����Ե�ַ 
         mov [ebx+56],edx                   ;��дTSS��ESP�� 

         ;���û�����ľֲ���ַ�ռ��ڴ���0��Ȩ����ջ
         alloc_user_linear                  ;�꣺���û������ַ�ռ��Ϸ����ڴ�

         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c09200                 ;4KB���ȵĶ�ջ������������Ȩ��0
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0000B         ;����ѡ���ӵ���Ȩ��Ϊ0

         mov ebx,[esi+0x14]                 ;��TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+8],cx                     ;��дTSS��SS0��
         mov edx,[esi+0x06]                 ;��ջ�ĸ߶����Ե�ַ
         mov [ebx+4],edx                    ;��дTSS��ESP0�� 

         ;���û�����ľֲ���ַ�ռ��ڴ���1��Ȩ����ջ
         alloc_user_linear                  ;�꣺���û������ַ�ռ��Ϸ����ڴ�

         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c0b200                 ;4KB���ȵĶ�ջ������������Ȩ��1
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0001B         ;����ѡ���ӵ���Ȩ��Ϊ1

         mov ebx,[esi+0x14]                 ;��TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+16],cx                    ;��дTSS��SS1��
         mov edx,[esi+0x06]                 ;��ջ�ĸ߶����Ե�ַ
         mov [ebx+12],edx                   ;��дTSS��ESP1�� 

         ;���û�����ľֲ���ַ�ռ��ڴ���2��Ȩ����ջ
         alloc_user_linear                  ;�꣺���û������ַ�ռ��Ϸ����ڴ�

         mov eax,0x00000000
         mov ebx,0x000fffff
         mov ecx,0x00c0d200                 ;4KB���ȵĶ�ջ������������Ȩ��2
         call flat_4gb_code_seg_sel:make_seg_descriptor
         mov ebx,esi                        ;TCB�Ļ���ַ
         call fill_descriptor_in_ldt
         or cx,0000_0000_0000_0010B         ;����ѡ���ӵ���Ȩ��Ϊ2

         mov ebx,[esi+0x14]                 ;��TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+24],cx                    ;��дTSS��SS2��
         mov edx,[esi+0x06]                 ;��ջ�ĸ߶����Ե�ַ
         mov [ebx+20],edx                   ;��дTSS��ESP2�� 

         ;�ض�λU-SALT 
         cld

         mov ecx,[0x0c]                     ;U-SALT��Ŀ�� 
         mov edi,[0x08]                     ;U-SALT��4GB�ռ��ڵ�ƫ�� 
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
         mov [edi-256],eax                  ;���ַ�����д��ƫ�Ƶ�ַ 
         mov ax,[esi+4]
         or ax,0000000000000011B            ;���û������Լ�����Ȩ��ʹ�õ�����
                                            ;��RPL=3 
         mov [edi-252],ax                   ;���������ѡ���� 
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
         mov esi,[ebp+36]                   ;�Ӷ�ջ��ȡ��TCB�Ļ���ַ
         mov eax,[esi+0x0c]                 ;LDT����ʼ���Ե�ַ
         movzx ebx,word [esi+0x0a]          ;LDT�ν���
         mov ecx,0x00408200                 ;LDT����������Ȩ��0
         call flat_4gb_code_seg_sel:make_seg_descriptor
         call flat_4gb_code_seg_sel:set_up_gdt_descriptor
         mov [esi+0x10],cx                  ;�Ǽ�LDTѡ���ӵ�TCB��

         mov ebx,[esi+0x14]                 ;��TCB�л�ȡTSS�����Ե�ַ
         mov [ebx+96],cx                    ;��дTSS��LDT�� 

         mov word [ebx+0],0                 ;������=0
      
         mov dx,[esi+0x12]                  ;�γ��ȣ����ޣ�
         mov [ebx+102],dx                   ;��дTSS��I/Oλͼƫ���� 
      
         mov word [ebx+100],0               ;T=0
      
         mov eax,[0x04]                     ;�������4GB��ַ�ռ��ȡ��ڵ� 
         mov [ebx+32],eax                   ;��дTSS��EIP�� 

         pushfd
         pop edx
         mov [ebx+36],edx                   ;��дTSS��EFLAGS�� 

         ;��GDT�еǼ�TSS������
         mov eax,[esi+0x14]                 ;��TCB�л�ȡTSS����ʼ���Ե�ַ
         movzx ebx,word [esi+0x12]          ;�γ��ȣ����ޣ�
         mov ecx,0x00408900                 ;TSS����������Ȩ��0
         call flat_4gb_code_seg_sel:make_seg_descriptor
         call flat_4gb_code_seg_sel:set_up_gdt_descriptor
         mov [esi+0x18],cx                  ;�Ǽ�TSSѡ���ӵ�TCB

         ;�����û������ҳĿ¼
         ;ע�⣡ҳ�ķ����ʹ������ҳλͼ�����ģ����Բ�ռ�����Ե�ַ�ռ� 
         call flat_4gb_code_seg_sel:create_copy_cur_pdir
         mov ebx,[esi+0x14]                 ;��TCB�л�ȡTSS�����Ե�ַ
         mov dword [ebx+28],eax             ;��дTSS��CR3(PDBR)��
                   
         popad
      
         ret 8                              ;�������ñ�����ǰѹ��Ĳ��� 
      
;-------------------------------------------------------------------------------
append_to_tcb_link:                         ;��TCB����׷��������ƿ�
                                            ;���룺ECX=TCB���Ի���ַ
         cli
         
         push eax
         push ebx

         mov eax,tcb_chain
  .b0:                                      ;EAX=����ͷ��ǰTCB���Ե�ַ
         mov ebx,[eax]                      ;EBX=��һ��TCB���Ե�ַ
         or ebx,ebx
         jz .b1                             ;����Ϊ�գ����ѵ�ĩβ
         mov eax,ebx                        ;��λ����һ��TCB�������Ե�ַ��
         jmp .b0

  .b1:
         mov [eax],ecx
         mov dword [ecx],0x00000000         ;��ǰTCBָ�������㣬��ָʾ������
                                            ;��һ��TCB
         pop ebx
         pop eax
         
         sti
         
         ret
         
;-------------------------------------------------------------------------------
start:
         ;�����ж���������IDT
         ;�ڴ�֮ǰ����ֹ����put_string���̣��Լ��κκ���stiָ��Ĺ��̡�
          
         ;ǰ20�������Ǵ������쳣ʹ�õ�
         mov eax,general_exception_handler  ;�Ŵ����ڶ���ƫ�Ƶ�ַ
         mov bx,flat_4gb_code_seg_sel       ;�Ŵ������ڶε�ѡ����
         mov cx,0x8e00                      ;32λ�ж��ţ�0��Ȩ��
         call flat_4gb_code_seg_sel:make_gate_descriptor

         mov ebx,idt_linear_address         ;�ж�������������Ե�ַ
         xor esi,esi
  .idt0:
         mov [ebx+esi*8],eax
         mov [ebx+esi*8+4],edx
         inc esi
         cmp esi,19                         ;��װǰ20���쳣�жϴ������
         jle .idt0

         ;����Ϊ������Ӳ��ʹ�õ��ж�����
         mov eax,general_interrupt_handler  ;�Ŵ����ڶ���ƫ�Ƶ�ַ
         mov bx,flat_4gb_code_seg_sel       ;�Ŵ������ڶε�ѡ����
         mov cx,0x8e00                      ;32λ�ж��ţ�0��Ȩ��
         call flat_4gb_code_seg_sel:make_gate_descriptor

         mov ebx,idt_linear_address         ;�ж�������������Ե�ַ
  .idt1:
         mov [ebx+esi*8],eax
         mov [ebx+esi*8+4],edx
         inc esi
         cmp esi,255                        ;��װ��ͨ���жϴ������
         jle .idt1

         ;����ʵʱʱ���жϴ������
         mov eax,rtm_0x70_interrupt_handle  ;�Ŵ����ڶ���ƫ�Ƶ�ַ
         mov bx,flat_4gb_code_seg_sel       ;�Ŵ������ڶε�ѡ����
         mov cx,0x8e00                      ;32λ�ж��ţ�0��Ȩ��
         call flat_4gb_code_seg_sel:make_gate_descriptor

         mov ebx,idt_linear_address         ;�ж�������������Ե�ַ
         mov [ebx+0x70*8],eax
         mov [ebx+0x70*8+4],edx

         ;׼�������ж�
         mov word [pidt],256*8-1            ;IDT�Ľ���
         mov dword [pidt+2],idt_linear_address
         lidt [pidt]                        ;�����ж���������Ĵ���IDTR

         ;����8259A�жϿ�����
         mov al,0x11
         out 0x20,al                        ;ICW1�����ش���/������ʽ
         mov al,0x20
         out 0x21,al                        ;ICW2:��ʼ�ж�����
         mov al,0x04
         out 0x21,al                        ;ICW3:��Ƭ������IR2
         mov al,0x01
         out 0x21,al                        ;ICW4:�����߻��壬ȫǶ�ף�����EOI

         mov al,0x11
         out 0xa0,al                        ;ICW1�����ش���/������ʽ
         mov al,0x70
         out 0xa1,al                        ;ICW2:��ʼ�ж�����
         mov al,0x04
         out 0xa1,al                        ;ICW3:��Ƭ������IR2
         mov al,0x01
         out 0xa1,al                        ;ICW4:�����߻��壬ȫǶ�ף�����EOI

         ;���ú�ʱ���ж���ص�Ӳ�� 
         mov al,0x0b                        ;RTC�Ĵ���B
         or al,0x80                         ;���NMI
         out 0x70,al
         mov al,0x12                        ;���üĴ���B����ֹ�������жϣ����Ÿ�
         out 0x71,al                        ;�½������жϣ�BCD�룬24Сʱ��

         in al,0xa1                         ;��8259��Ƭ��IMR�Ĵ���
         and al,0xfe                        ;���bit 0(��λ����RTC)
         out 0xa1,al                        ;д�ش˼Ĵ���

         mov al,0x0c
         out 0x70,al
         in al,0x71                         ;��RTC�Ĵ���C����λδ�����ж�״̬

         sti                                ;����Ӳ���ж�

         mov ebx,message_0
         call flat_4gb_code_seg_sel:put_string

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
         call flat_4gb_code_seg_sel:put_string
         mov ebx,cpu_brand
         call flat_4gb_code_seg_sel:put_string
         mov ebx,cpu_brnd1
         call flat_4gb_code_seg_sel:put_string

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
         call flat_4gb_code_seg_sel:make_gate_descriptor
         call flat_4gb_code_seg_sel:set_up_gdt_descriptor
         mov [edi+260],cx                   ;�����ص���������ѡ���ӻ���
         add edi,salt_item_len              ;ָ����һ��C-SALT��Ŀ 
         pop ecx
         loop .b4

         ;���Ž��в��� 
         mov ebx,message_1
         call far [salt_1+256]              ;ͨ������ʾ��Ϣ(ƫ������������) 

         ;���PCIe�豸 



         ;��ʼ��������������������������ƿ�TCB
         mov word [core_tcb+0x04],0xffff    ;����״̬��æµ
         mov dword [core_tcb+0x06],0x80100000    
                                            ;�ں�����ռ�ķ�������￪ʼ��
         mov word [core_tcb+0x0a],0xffff    ;�Ǽ�LDT��ʼ�Ľ��޵�TCB�У�δʹ�ã�
         mov ecx,core_tcb
         call append_to_tcb_link            ;����TCB��ӵ�TCB����

         ;Ϊ�����������TSS�����ڴ�ռ�
         alloc_core_linear                  ;�꣺���ں˵������ַ�ռ�����ڴ�

         ;�ڳ����������TSS�����ñ�Ҫ����Ŀ 
         mov word [ebx+0],0                 ;������=0
         mov eax,cr3
         mov dword [ebx+28],eax             ;�Ǽ�CR3(PDBR)
         mov word [ebx+96],0                ;û��LDT������������û��LDT������
         mov word [ebx+100],0               ;T=0
         mov word [ebx+102],103             ;û��I/Oλͼ��0��Ȩ����ʵ�ϲ���Ҫ��
         
         ;���������������TSS������������װ��GDT�� 
         mov eax,ebx                        ;TSS����ʼ���Ե�ַ
         mov ebx,103                        ;�γ��ȣ����ޣ�
         mov ecx,0x00408900                 ;TSS����������Ȩ��0
         call flat_4gb_code_seg_sel:make_seg_descriptor
         call flat_4gb_code_seg_sel:set_up_gdt_descriptor
         mov [core_tcb+0x18],cx             ;�Ǽ��ں������TSSѡ���ӵ���TCB

         ;����Ĵ���TR�е�������������ڵı�־��������Ҳ�����˵�ǰ������˭��
         ;�����ָ��Ϊ��ǰ����ִ�е�0��Ȩ�����񡰳������������������TSS����
         ltr cx

         ;���ڿ���Ϊ�������������������ִ����

         ;�����û������������ƿ� 
         alloc_core_linear                  ;�꣺���ں˵������ַ�ռ�����ڴ�
         
         mov word [ebx+0x04],0              ;����״̬������ 
         mov dword [ebx+0x06],0             ;�û�����ֲ��ռ�ķ����0��ʼ��
         mov word [ebx+0x0a],0xffff         ;�Ǽ�LDT��ʼ�Ľ��޵�TCB��
      
         push dword 50                      ;�û�����λ���߼�50����
         push ebx                           ;ѹ��������ƿ���ʼ���Ե�ַ 
         call load_relocate_program
         mov ecx,ebx         
         call append_to_tcb_link            ;����TCB��ӵ�TCB����

         ;�����û������������ƿ�
         alloc_core_linear                  ;�꣺���ں˵������ַ�ռ�����ڴ�

         mov word [ebx+0x04],0              ;����״̬������
         mov dword [ebx+0x06],0             ;�û�����ֲ��ռ�ķ����0��ʼ��
         mov word [ebx+0x0a],0xffff         ;�Ǽ�LDT��ʼ�Ľ��޵�TCB��

         push dword 100                     ;�û�����λ���߼�100����
         push ebx                           ;ѹ��������ƿ���ʼ���Ե�ַ
         call load_relocate_program
         mov ecx,ebx
         call append_to_tcb_link            ;����TCB��ӵ�TCB����

  .core:
         mov ebx,core_msg0
         call flat_4gb_code_seg_sel:put_string
         
         ;������Ա�д��������ֹ�����ڴ�Ĵ���
          
         jmp .core
            
core_code_end:

;-------------------------------------------------------------------------------
SECTION core_trail
;-------------------------------------------------------------------------------
core_end: