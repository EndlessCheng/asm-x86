         ;�����嵥16-2
         ;�ļ�����c16.asm
         ;�ļ�˵�����û����� 
         ;�������ڣ�2012-05-25 13:53   

         program_length   dd program_end          ;�����ܳ���#0x00
         entry_point      dd start                ;������ڵ�#0x04
         salt_position    dd salt_begin           ;SALT����ʼƫ����#0x08 
         salt_items       dd (salt_end-salt_begin)/256 ;SALT��Ŀ��#0x0C

;-------------------------------------------------------------------------------

         ;���ŵ�ַ������
         salt_begin:                                     

         PrintString      db  '@PrintString'
                     times 256-($-PrintString) db 0
                     
         TerminateProgram db  '@TerminateProgram'
                     times 256-($-TerminateProgram) db 0
;-------------------------------------------------------------------------------

         reserved  times 256*500 db 0            ;����һ���հ���������ʾ��ҳ

;-------------------------------------------------------------------------------
         ReadDiskData     db  '@ReadDiskData'
                     times 256-($-ReadDiskData) db 0
         
         PrintDwordAsHex  db  '@PrintDwordAsHexString'
                     times 256-($-PrintDwordAsHex) db 0
         
         salt_end:

         message_0        db  0x0d,0x0a,
                          db  '  ............User task is running with '
                          db  'paging enabled!............',0x0d,0x0a,0

         space            db  0x20,0x20,0
         
;-------------------------------------------------------------------------------
      [bits 32]
;-------------------------------------------------------------------------------

start:
          
         mov ebx,message_0
         call far [PrintString]
         
         xor esi,esi
         mov ecx,88
  .b1:
         mov ebx,space
         call far [PrintString] 
         
         mov edx,[esi*4]
         call far [PrintDwordAsHex]
         
         inc esi
         loop .b1 
        
         call far [TerminateProgram]              ;�˳�����������Ȩ���ص����� 
    
;-------------------------------------------------------------------------------
program_end: