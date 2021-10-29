         ;�����嵥17-1
         ;�ļ�����c17_mbr.asm
         ;�ļ�˵����Ӳ���������������� 
         ;�������ڣ�2012-07-13 11:20        ;���ö�ջ�κ�ջָ�� 
         
         core_base_address equ 0x00040000   ;�������ں˼��ص���ʼ�ڴ��ַ 
         core_start_sector equ 0x00000001   ;�������ں˵���ʼ�߼������� 

;===============================================================================
SECTION  mbr  vstart=0x00007c00         

         mov ax,cs      
         mov ss,ax
         mov sp,0x7c00
      
         ;����GDT���ڵ��߼��ε�ַ
         mov eax,[cs:pgdt+0x02]             ;GDT��32λ�����ַ 
         xor edx,edx
         mov ebx,16
         div ebx                            ;�ֽ��16λ�߼���ַ 

         mov ds,eax                         ;��DSָ��ö��Խ��в���
         mov ebx,edx                        ;������ʼƫ�Ƶ�ַ 

         ;����0#���������Ĳ�λ 
         ;����1#������������ģʽ�µĴ����������
         mov dword [ebx+0x08],0x0000ffff    ;����ַΪ0������0xFFFFF��DPL=00 
         mov dword [ebx+0x0c],0x00cf9800    ;4KB���ȣ��������������������չ 

         ;����2#������������ģʽ�µ����ݶκͶ�ջ�������� 
         mov dword [ebx+0x10],0x0000ffff    ;����ַΪ0������0xFFFFF��DPL=00
         mov dword [ebx+0x14],0x00cf9200    ;4KB���ȣ����ݶ���������������չ 

         ;��ʼ����������Ĵ���GDTR
         mov word [cs: pgdt],23             ;��������Ľ���   
 
         lgdt [cs: pgdt]
      
         in al,0x92                         ;����оƬ�ڵĶ˿� 
         or al,0000_0010B
         out 0x92,al                        ;��A20

         cli                                ;�жϻ�����δ����

         mov eax,cr0                  
         or eax,1
         mov cr0,eax                        ;����PEλ
      
         ;���½��뱣��ģʽ... ...
         jmp dword 0x0008:flush             ;16λ��������ѡ���ӣ�32λƫ��
                                            ;����ˮ�߲����л�������
         [bits 32]               
  flush:                                  
         mov eax,0x00010                    ;�������ݶ�(4GB)ѡ����
         mov ds,eax
         mov es,eax
         mov fs,eax
         mov gs,eax
         mov ss,eax                         ;���ض�ջ��(4GB)ѡ����
         mov esp,0x7000                     ;��ջָ��
         
         ;���¼���ϵͳ���ĳ���
         mov edi,core_base_address

         mov eax,core_start_sector
         mov ebx,edi                        ;��ʼ��ַ
         call read_hard_disk_0              ;���¶�ȡ�������ʼ���֣�һ��������

         ;�����ж����������ж��
         mov eax,[edi]                      ;���ĳ���ߴ�
         xor edx,edx
         mov ecx,512                        ;512�ֽ�ÿ����
         div ecx

         or edx,edx
         jnz @1                             ;δ��������˽����ʵ����������1
         dec eax                            ;�Ѿ�����һ������������������1
   @1:
         or eax,eax                         ;����ʵ�ʳ��ȡ�512���ֽڵ����
         jz pge                             ;EAX=0 ?

         ;��ȡʣ�������
         mov ecx,eax                        ;32λģʽ�µ�LOOPʹ��ECX
         mov eax,core_start_sector
         inc eax                            ;����һ���߼��������Ŷ�
   @2:
         call read_hard_disk_0
         inc eax
         loop @2                            ;ѭ������ֱ�����������ں�

   pge:
         ;׼���򿪷�ҳ���ơ��Ӵˣ���Ҳ�����ڶ�֮��ת��תȥ��ʵ���κ�~ 
         
         ;����ϵͳ�ں˵�ҳĿ¼��PDT
         mov ebx,0x00020000                 ;ҳĿ¼��PDT�������ַ
         
         ;��ҳĿ¼�ڴ���ָ��ҳĿ¼���Լ���Ŀ¼��
         mov dword [ebx+4092],0x00020003 

         mov edx,0x00021003                 ;MBR�ռ����ޣ����澡����ʹ��������
         ;��ҳĿ¼�ڴ��������Ե�ַ0x00000000��Ӧ��Ŀ¼��
         mov [ebx+0x000],edx                ;д��Ŀ¼�ҳ��������ַ�����ԣ�      
                                            ;��Ŀ¼������ڹ��ɡ�
         ;��ҳĿ¼�ڴ��������Ե�ַ0x80000000��Ӧ��Ŀ¼��
         mov [ebx+0x800],edx                ;д��Ŀ¼�ҳ��������ַ�����ԣ�

         ;�����������Ǹ�Ŀ¼�����Ӧ��ҳ����ʼ��ҳ���� 
         mov ebx,0x00021000                 ;ҳ��������ַ
         xor eax,eax                        ;��ʼҳ�������ַ 
         xor esi,esi
  .b1:       
         mov edx,eax
         or edx,0x00000003                                                      
         mov [ebx+esi*4],edx                ;�Ǽ�ҳ�������ַ
         add eax,0x1000                     ;��һ������ҳ�������ַ 
         inc esi
         cmp esi,256                        ;���Ͷ�1MB�ڴ��Ӧ��ҳ������Ч�� 
         jl .b1
         
         ;��CR3�Ĵ���ָ��ҳĿ¼������ʽ����ҳ���� 
         mov eax,0x00020000                 ;PCD=PWT=0
         mov cr3,eax

         ;��GDT�����Ե�ַӳ�䵽��0x80000000��ʼ����ͬλ�� 
         sgdt [pgdt]
         mov ebx,[pgdt+2]
         add dword [pgdt+2],0x80000000      ;GDTRҲ�õ������Ե�ַ
         lgdt [pgdt]

         mov eax,cr0
         or eax,0x80000000
         mov cr0,eax                        ;������ҳ����
   
         ;����ջӳ�䵽�߶ˣ����Ƿǳ����ױ����Ե�һ���¡�Ӧ�����ں˵����ж���
         ;���Ƶ��߶ˣ�����һ��������ڼ��ص��û�����ֲ��ռ�������ݳ�ͻ��
         ;���Һ����뵽����������� 
         add esp,0x80000000                 
                                             
         jmp [0x80040004]  
       
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
      
         ret

;-------------------------------------------------------------------------------
         pgdt             dw 0
                          dd 0x00008000     ;GDT������/���Ե�ַ
;-------------------------------------------------------------------------------                             
         times 510-($-$$) db 0
                          db 0x55,0xaa