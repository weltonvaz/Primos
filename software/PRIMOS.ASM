;-----------------------------------------------------------------------------;
; Programa para mostrar el modo protegido del 80386.                          ;
; El programa tiene dos tareas: una muestra una lista de n£meros primos       ;
; mediante el m‚todo de divisiones sucesivas en la parte superior de la       ;
; pantalla, y la otra muestra una lista de n£meros primos mediante el m‚todo  ;
; de potenciaci¢n en la parte inferior de la pantalla.                        ;
; Adem s hay dos interrupciones: IRQ0 (timer - INT 08h) para el manejo del    ;
; "scheduler" (rutina que determina cu l es la tarea que debe correr en un    ;
; instante determinado en un sistema multitarea) e IRQ1 (teclado - INT 09h)   ;
; para el manejo de las teclas de funci¢n y entrada de n£meros.               ;
;                                                                             ;
; Hecho por Dario Alejandro Alpern                                            ;
;                                                                             ;
; Versiones del programa:                                                     ;
; - Versi¢n 2.0 (marzo de 1997): Se agreg¢ la tarea que muestra n£meros       ;
;   primos mediante potenciaci¢n. Se agreg¢ separaci¢n de millares en los     ;
;   n£meros primos que se muestran. Se agreg¢ "equ" para aclarar el signifi-  ;
;   cado de ciertas variables.                                                ;
;   Se agreg¢ manejo de las teclas Pausa y Break.                             ;
; - Versi¢n 1.0 (octubre de 1995): Programa original.                         ;
;-----------------------------------------------------------------------------;
        .386p
;Segmento in£til que s¢lo se utiliza para inicializar los saltos lejanos.
nada    segment use16 at 0
dummy   label far
nada    ends
;-----------------------------------------------------------------------------
; Segmento de c¢digo y datos.
codigo  segment use16
        org 100h
        assume cs:codigo,ds:codigo
comienzo:jmp inicio
;---------------------------------------------------------------------------
; Definici¢n de campos de bits del byte de derechos de acceso:
DA_SEGMENTO_PRESENTE  equ 80h  ;El segmento se encuentra en memoria.
DA_NIVEL_PRIVILEGIO_0 equ 00h  ;Mayor privilegio. Acceso a todos los recursos.
DA_NIVEL_PRIVILEGIO_1 equ 20h
DA_NIVEL_PRIVILEGIO_2 equ 40h
DA_NIVEL_PRIVILEGIO_3 equ 60h  ;Menor privilegio.
DA_SEGMENTO_CODIGO    equ 18h  ;Segmento con c¢digo ejecutable.
DA_SEGMENTO_DATOS     equ 10h  ;Segmento sin c¢digo ejecutable. Siempre se
                               ;puede leer.
DA_OFFSET_MENOR_LIM   equ 00h  ;El offset v lido en el segmento de datos es
                               ;menor o igual que el l¡mite.
DA_OFFSET_MAYOR_LIM   equ 04h  ;El offset v lido en el segmento de datos es
                               ;mayor que el l¡mite.
DA_LECTURA_ESCRITURA  equ 02h  ;El segmento de datos se puede leer y escribir.
DA_SOLO_LECTURA       equ 00h  ;El segmento de datos se puede leer pero no
                               ;escribir.
DA_LECTURA_EJECUCION  equ 02h  ;El segmento de c¢digo se puede leer y ejecutar.
DA_SOLO_EJECUCION     equ 00h  ;El segmento de c¢digo se puede ejecutar pero
                               ;no se pueden leer sus bytes.
;Byte de derechos de acceso para el segmento de c¢digo que se usa aqu¡:
DA_CODIGO             equ DA_SEGMENTO_PRESENTE   + \
                          DA_NIVEL_PRIVILEGIO_0  + \
                          DA_SEGMENTO_CODIGO     + \
                          DA_LECTURA_EJECUCION
;Byte de derechos de acceso para los segmentos de datos que se usan aqu¡:
DA_DATOS              equ DA_SEGMENTO_PRESENTE   + \
                          DA_NIVEL_PRIVILEGIO_0  + \
                          DA_SEGMENTO_DATOS      + \
                          DA_OFFSET_MENOR_LIM    + \
                          DA_LECTURA_ESCRITURA
DA_TSS_286            equ 81h   ;Descriptor de TSS tipo 286.
DA_TSS_386            equ 89h   ;Descriptor de TSS tipo 386.
DA_TSS_GATE           equ 85h   ;Descriptor de compuerta de tarea.
;-----------------------------------------------------------------------------
; Macro para definir el descriptor (ocho bytes):
descriptor macro base, limite, derechos_acceso
           IF derechos_acceso and 10h     ;; Segmento de c¢digo o datos.
              IF limite GT 0FFFFFh        ;; Si granularidad = 4KB:
                 dw ((limite) SHR 12) and 0FFFFh
              ELSE
                 dw (limite) and 0FFFFh   ;; Bytes 1-0 del l¡mite.
              ENDIF
              dw (base) and 0FFFFh        ;; Bytes 1-0 de la base.
              db ((base) SHR 16) and 0FFh ;; Byte 2 de la base. 
              db derechos_acceso          ;; Byte de derechos de acceso.
              IF limite GT 0FFFFFh
                 db 80h + ((limite) SHR 28) ;; Indicar granularidad = 4KB.
              ELSE
                 db (limite) SHR 16       ;; Byte 2 del l¡mite. 
              ENDIF
              db (base) SHR 24            ;; Byte 3 de la base.
           ELSE                           ;; Segmento de tabla del sistema.
              dw limite
              dw base
              db 0
              db derechos_acceso
              db 0
              db 0
           ENDIF
           ENDM
;-----------------------------------------------------------------------------
; Valores que van en la tabla de descriptores globales (diez descriptores),
; ocho bytes por descriptor.
gdt     equ qword ptr $ - 8  ;Inicio de la tabla de descriptores globales.
;
; 1ø descriptor: Segmento de c¢digo.
code_sel equ $ - gdt    ;Valor del selector del segmento de c¢digo.
        descriptor 0, 0FFFFh, DA_CODIGO
;
; 2ø descriptor: Segmento de pila y datos (alias del segmento de c¢digo).
data_sel equ $ - gdt    ;Valor del selector del segmento de datos.
        descriptor 0, 0FFFFh, DA_DATOS
;
; 3ø descriptor: Segmento de buffer de pantalla.
pant_sel equ $ - gdt    ;Valor del selector del buffer de pantalla.
        descriptor 0B0000h, 0FFFFh, DA_DATOS ;El valor de la base es para
                        ;adaptador monocromo. Si el adaptador es color, la base
                        ;se cambia en tiempo de ejecuci¢n.
;
; 4ø descriptor: Segmento de parte inferior del buffer de pantalla.
pant_inf_sel equ $-gdt  ;Valor del selector de la parte inferior de pantalla.
        descriptor 0B0000h+15*80*2, 0FFFFh, DA_DATOS
;
; 5ø Descriptor: Descriptor de segmento de estado de la tarea (TSS) inicial.
TSS_inic_sel equ $-gdt  ;Valor del selector del TSS inicial.
        descriptor TSS_original, <size TSS_386 - 1>, DA_TSS_286
;
; 6ø Descriptor: Descriptor de segmento de estado de la tarea (TSS)
;                primos_division.
TSS_pri1_sel equ $-gdt  ;Valor del selector del TSS de primos_division.
        descriptor TSS_primos_division, <size TSS_386 - 1>, DA_TSS_386
;
; 7ø Descriptor: Descriptor de segmento de estado de la tarea (TSS)
;                primos_potenciacion.
TSS_pri2_sel equ $-gdt  ;Valor del selector de TSS de primos_potenciacion.
        descriptor TSS_primos_potenciacion, <size TSS_386 - 1>, DA_TSS_386
;
; 8ø Descriptor: Descriptor de segmento de estado de la tarea (TSS) int8.
TSS_int8_sel equ $-gdt  ;Valor del selector de TSS de la interrupci¢n 8.
        descriptor TSS_int8, <size TSS_386 - 1>, DA_TSS_286
;
; 9ø Descriptor: Descriptor de segmento de estado de la tarea (TSS) int9.
TSS_int9_sel equ $-gdt  ;Valor del selector de TSS de la interrupci¢n 9.
        descriptor TSS_int9, <size TSS_386 - 1>, DA_TSS_386
;
; 10ø descriptor: Segmento de pila (alias del segmento de c¢digo).
dir_cero_sel equ $-gdt  ;Valor del selector del segmento de datos.
        descriptor 0, 0FFFFh, DA_DATOS
fin_gdt equ $
; Valores que van en la tabla de descriptores de interrupci¢n
; (dos descriptores correspondientes a INT 8 e INT 9)
idt     equ $ - 64      ;Inicio de la tabla de interrupci¢n.
;
; 1ø Descriptor: Compuerta de interrupci¢n correspondiente a INT 8.
        descriptor TSS_int8_sel, 0, DA_TSS_GATE
;
; 2ø Descriptor: Compuerta de interrupci¢n correspondiente a INT 9.
        descriptor TSS_int9_sel, 0, DA_TSS_GATE
fin_idt equ $
;-----------------------------------------------------------------------------
; Estructura del segmento de estado de la tarea (TSS).
TSS_386         struc
 back_link      dw 0,0
 PL0_ESP_value  dd 0
 PL0_SS_value   dd data_sel
 PL1_ESP_value  dd 0
 PL1_SS_value   dw 0,0
 PL2_ESP_value  dd 0
 PL2_SS_value   dw 0,0
 CR3_value      dd 0
 EIP_value      dd 0
 EFLAGS_value   dd 00003202h
 EAX_value      dd 0
 ECX_value      dd 0
 EDX_value      dd 0
 EBX_value      dd 0
 ESP_value      dd 0
 EBP_value      dd 0
 ESI_value      dd 0
 EDI_value      dd 0
 ES_value       dd 0
 CS_value       dd code_sel
 SS_value       dd data_sel
 DS_value       dd data_sel
 FS_value       dd 0
 GS_value       dd 0
 LDT_value      dd 0
 DEBUG_value    dw 0
 bitmap_offset  dw 0
 bitmap_end     db 255
TSS_386         ends
TSS_286         struc
 backlink       dw 0
 PL0_SP_val     dw 0
 PL0_SS_val     dw data_sel
 PL1_SP_val     dw 0
 PL1_SS_val     dw 0
 PL2_SP_val     dw 0
 PL2_SS_val     dw 0
 IP_val         dw 0
 FLAGS_val      dw 3202h
 AX_val         dw 0
 CX_val         dw 0
 DX_val         dw 0
 BX_val         dw 0
 SP_val         dw 0
 BP_val         dw 0
 SI_val         dw 0
 DI_val         dw 0
 ES_val         dw 0
 CS_val         dw code_sel
 SS_val         dw data_sel
 DS_val         dw data_sel
 LDT_val        dw 0
TSS_286         ends
base            equ comienzo - 100h
TSS_original    TSS_286 <,,,,,,,,,,,,,,,,,0,0,0,0>
TSS_primos_division     TSS_386 <,pila_primos_division + 100h - base,,,,,,,primos_division - base,,,,,,pila_primos_division + 100h - base,2,,5,pant_sel,,,,,,,,size TSS_386 - 1>
TSS_primos_potenciacion     TSS_386 <,pila_primos_potenciacion + 100h - base,,,,,,,primos_potenciacion - base,,,,,,pila_primos_potenciacion + 100h - base,2,,5,pant_inf_sel,,,,,,,size TSS_386 - 1>
TSS_int8        TSS_286 <,pila_int8 + 100h - base,,,,,,int8han - base,,,20,10,,pila_int8 + 100h - base,,,,dir_cero_sel>
TSS_int9        TSS_386 <,pila_int9 + 100h - base,,,,,,,int9han - base,3002h,,,,,pila_int9 + 100h - base,,,,pant_sel,,,,,,,,size TSS_386 - 1>
LSD_d_ajustado   dd 0
MSD_d_ajustado   dd 0
LSD_d_aux dd 0
MSD_d_aux dd 0
base_SPRP dd 0
res_LO  dd 0
res_HI  dd 0
bits_d  dw 0
valor_s dw 0
picint  db 0
gdtr    label fword     ;Informaci¢n a almacenar en el GDTR (6 bytes).
        dw fin_gdt - gdt - 1  ;L¡mite de la tabla de descriptores globales.
        dw gdt          ;Base de la tabla de descriptores globales.
        dw 0            ;Se llena durante la ejecuci¢n del programa.
idtr    label fword     ;Informaci¢n a almacenar en el IDTR (6 bytes).
        dw fin_idt - idt - 1  ;L¡mite de la IDT.
        dw idt          ;Base de la tabla de descriptores de interrupci¢n.
        dw 0            ;Se llena durante la ejecuci¢n del programa.
real_idtr df 0          ;Espacio para almacenar el IDTR en modo real.
texto1  dw 11*160+0*2
        db "Tiempo: 50%  ",24,": M s, ",25,": Menos, F1 = Detener,"
        db " F2 = Continuar, F3 = Cambiar n£mero",0
;El ASCII 24 es la flecha hacia arriba, y el ASCII 25 es la flecha hacia abajo.
texto2  dw 12*160+8*2
        db "Hecho por Dar¡o Alejandro Alpern en marzo de 1997 (versi¢n 2.0)",0
texto3  dw 13*160+0*2
        db "Tiempo: 50%  ",25,": M s, ",24,": Menos, F4 = Detener,"
        db " F5 = Continuar, F6 = Cambiar n£mero",0
texto4  dw 12*160+8*2
        db "               Nuevo n£mero:                                   ",0
texto5  db "Este programa no puede correr en modo virtual 8086.",13,10
        db "Pruebe eliminando la l¡nea DEVICE=EMM386 en CONFIG.SYS",13,10,"$"
texto6  db "Este programa requiere 80386 o posterior.",13,10,"$"
; Definici¢n del byte de estado:
SCAN_CODE_E1    equ 128         ;El scan code anterior fue E1.
SCAN_CODE_E0    equ 64          ;El scan code anterior fue E0 (si bit 7=0).
SCAN_DESPUES_E1 equ 64          ;Cantidad de scan codes despu‚s del E1
                                ;(si bit 7=1).
APRETO_PAUSA    equ 32          ;Se apret¢ la tecla Pausa.
APRETO_ESC      equ 16          ;Se apret¢ la tecla Esc.
RUN_POTEN       equ 8           ;La tarea primos_potenciaci¢n est  corriendo.
RUN_DIVISION    equ 4           ;La tarea primos_divisi¢n est  corriendo.
CAMBIANDO_POT   equ 2           ;Cambiando n£mero tarea primos_potenciaci¢n.
CAMBIANDO_DIV   equ 1           ;Cambiando n£mero tarea primos_divisi¢n.
estado  db RUN_POTEN + RUN_DIVISION
port6845 dw 3B4h
;--------------------------------------------------------------;
; Tarea mitad superior pantalla (hallar primos por divisiones) ;
;--------------------------------------------------------------;
primos_division: mov esi,5      ;Primer divisor. Los divisores ser n:
                                ;5,7,11,13,17,19,23,25,29,31,...
        jmp short comparar_divisor_div
;Realizar la divisi¢n de 64 bits (EBX:EDI) extendidos a 96 por 32 bits (ESI).
;Lo que necesitamos nosotros es el resto (si vale cero, entonces EBX:EDI no
;es primo).
bucle_div_64_32:xor edx,edx     ;Extender el dividendo.
        mov eax,ebx             ;Poner la parte alta del dividendo.
        div esi                 ;Realizar la primera parte de la divisi¢n.
        mov eax,edi             ;Poner la parte baja del dividendo.
        div esi                 ;Realizar la segunda parte de la divisi¢n.
        and edx,edx             ;¨El resto vale cero?
        jz short prox_num_div   ;Si es as¡ saltar porque el n£mero no es primo.
        add esi,2               ;Obtener el siguiente divisor.
        xor edx,edx             ;Extender el dividendo.
        mov eax,ebx             ;Poner la parte alta del dividendo.
        div esi                 ;Realizar la primera parte de la divisi¢n.
        mov eax,edi             ;Poner la parte baja del dividendo.
        div esi                 ;Realizar la segunda parte de la divisi¢n.
        and edx,edx             ;¨El resto vale cero?
        jz short prox_num_div   ;Si es as¡ saltar porque el n£mero no es primo.
        add esi,4               ;Obtener el siguiente divisor.
comparar_divisor_div:
        cmp ebx,esi             ;Ver si es necesario seguir extendiendo el
                                ;dividendo a 96 bits.
        jae bucle_div_64_32     ;Saltar si es as¡.
;Realizar la divisi¢n de 64 bits (EBX:EDI) por 32 bits (ESI).
;Lo que necesitamos nosotros es el resto (si vale cero, entonces EBX:EDI no
;es primo) y el cociente (si es menor que el divisor EBX:EDI es primo).
bucle_div_32_32:mov edx,ebx     ;Poner la parte alta del dividendo.
        mov eax,edi             ;Poner la parte baja del dividendo.
        div esi                 ;Realizar la divisi¢n.
        and edx,edx             ;¨El resto vale cero?
        jz short prox_num_div   ;Si es as¡ saltar porque el n£mero no es primo.
        add esi,2               ;Obtener el siguiente divisor.
        mov edx,ebx             ;Poner la parte alta del dividendo.
        mov eax,edi             ;Poner la parte baja del dividendo.
        div esi                 ;Realizar la divisi¢n.
        and edx,edx             ;¨El resto vale cero?
        jz short prox_num_div   ;Si es as¡ saltar porque el n£mero no es primo.
        add esi,4               ;Obtener el siguiente divisor.
        cmp eax,esi             ;¨El divisor supera al cociente?
        jae bucle_div_32_32     ;Saltar si no es as¡.
;En este punto se sabe que EBX:EDI es primo, por lo que hay que mostrarlo.
        call mostrar_numero
;Hallar el pr¢ximo valor de EBX:EDI para ver si es primo o no.
prox_num_div:
        add edi,ebp             ;Sumar el valor adecuado.
        adc ebx,0
        xor bp,2 xor 4          ;Cambiar el indicador de sumar 2 ¢ 4.
        jmp primos_division
;---------------------------------------------------;
; Subrutina para mostrar los n£meros en la pantalla ;
; Esta subrutina est  compartida por ambas tareas   ;
;---------------------------------------------------;
mostrar_numero:
        cli                     ;No debe ocurrir ning£n cambio de tarea.
        push ebp                ;Preservar registros afectados.
        push edi
        push ebx
;Conversi¢n binario (EBX:EDI = 64 bits) a decimal (hasta 20 d¡gitos).
        mov bp,10               ;EBP = Divisor.
        mov cx,3                ;Contador para separador de millares.
        mov si,sp
        add si,25+4+4+4         ;SI = Puntero al final del buffer temporario.
bucle_bin_a_dec1:
        cmp ebx,ebp             ;¨Se puede realizar la divisi¢n sin overflow?
        jb short bucle_bin_a_dec2  ;Saltar si es as¡.
        xor edx,edx             ;Extender el dividendo.
        mov eax,ebx             ;Cargar la parte alta del dividendo.
        div ebp                 ;Realizar la primera parte de la divisi¢n.
segunda_division:
        mov ebx,eax             ;Salvar la nueva parte alta del dividendo.
        mov eax,edi             ;Cargar la parte baja del dividendo.
        div ebp                 ;Realizar la segunda parte de la divisi¢n.
        mov edi,eax             ;Salvar la nueva parte baja del dividendo.
        add dl,"0"              ;Convertir el resto a ASCII.
        mov [si],dl             ;Guardar el resto en el buffer temporario
                                ;(de esta manera se obtiene el d¡gito
                                ;"de la derecha" o menos significativo).
        loop no_insertar_separador1
        dec si
        mov byte ptr [si],"."
        mov cl,3                ;Reinicializar contador para separador.
no_insertar_separador1:
        dec si                  ;Apuntar al d¡gito anterior.
        jmp bucle_bin_a_dec1    ;Seguir dividiendo.
bucle_bin_a_dec2:
        mov edx,ebx             ;Cargar la parte alta del dividendo.
        mov eax,edi             ;Cargar la parte baja del dividendo.
        div ebp                 ;Dividir por 10.
        mov edi,eax             ;Dejar la parte baja en el registro que estaba.
        xor ebx,ebx             ;La parte alta debe ser cero.
        add dl,"0"              ;Convertir el resto a ASCII.
        mov [si],dl             ;Guardar el resto en el buffer temporario
                                ;(de esta manera se obtiene el d¡gito
                                ;"de la derecha" o menos significativo).
        loop no_insertar_separador2
        dec si
        mov byte ptr [si],"."
        mov cl,3                ;Reinicializar contador para separador.
no_insertar_separador2:
        dec si                  ;Apuntar al d¡gito anterior.
        and eax,eax             ;¨El n£mero vale cero?
        jnz bucle_bin_a_dec2    ;Seguir dividiendo si no es as¡.
        cmp byte ptr [si+1],"."
        jnz short no_es_separador
        inc si
no_es_separador:
        mov bp,sp
        add bp,25+4+4+4         ;BP = Puntero al final del buffer temporario.
        mov cx,bp
        inc cx
        sub cx,si               ;CX = Cantidad de d¡gitos del n£mero.
        add cx,cx               ;Convertir a bytes de buffer de pantalla.
        add cx,[bp+1]           ;Agregarle la posici¢n actual del buffer de
                                ;pantalla.
        cmp cx,10*80*2          ;¨Se sobrepasa el final con lo que quedar¡a
                                ;el n£mero cortado?
        jbe short poner_numero  ;Saltar si no es as¡.
;Hacer un "scroll" (correr una l¡nea hacia arriba llenando la l¡nea de abajo
;con espacios) de la porci¢n activa de la pantalla.
        xchg bx,si              ;Preservar el registro SI.
        xor di,di               ;DI = Posici¢n del car cter superior izquierdo
        mov si,160              ;SI = Extremo izquierdo de la segunda l¡nea.
        mov cx,9*80/2           ;CX = Cantidad de dwords a mover.
        rep movs dword ptr es:[di],dword ptr es:[si]  ;Realizar el "scroll".
        mov eax,07200720h       ;Dos caracteres de espacio con atributo blanco
                                ;sobre negro.
        mov cl,80/2             ;CX = Cantidad de dwords a poner.
        rep stos dword ptr es:[di]  ;Poner los espacios.
        xchg bx,si              ;Restaurar el registro SI.
        mov word ptr [bp+1],9*80*2 ;Indicar la nueva posici¢n donde se deben
                                ;mostrar los caracteres.
poner_numero:
        mov ah,07h              ;Atributo blanco sobre negro.
        mov di,[bp+1]           ;Obtener la posici¢n del buffer de pantalla.
        inc si                  ;Apuntar a la primera posici¢n del buffer.
poner_digito:
        lodsb                   ;Obtener el d¡gito.
        stosw                   ;Poner el car cter en buffer de pantalla.
        cmp si,bp               ;¨Se termin¢ el buffer?
        jbe poner_digito        ;Saltar si no es as¡.
        mov al,179              ;Mostrar una barra vertical.
        stosw
        mov [bp+1],di           ;Preservar el puntero.
        pop ebx                 ;Restaurar registros afectados.
        pop edi
        pop ebp
        sti                     ;Permitir nuevamente interrupciones 8 y 9.
        ret                     ;Fin de la subrutina.
posnum  equ 12*80+37
;----------------------------------------------------------------;
; Tarea mitad inferior pantalla (hallar primos por potenciacion) ;
;----------------------------------------------------------------;
; Como realizar potenciaciones es un proceso lento, descartamos aquellos
; n£meros que tengan algun divisor menor que 257.
primos_potenciacion: mov esi,5  ;Primer divisor. Los divisores ser n:
                                ;5,7,11,13,17,19,23,25,29,31,...
        mov ecx,257             ;M ximo divisor.
        jmp short comparar_divisor_pot
;Realizar la divisi¢n de 64 bits (EBX:EDI) extendidos a 96 por 32 bits (ESI).
;Lo que necesitamos nosotros es el resto (si vale cero, entonces EBX:EDI no
;es primo).
segundo_bucle_div_64_32:
        cmp esi,ecx             ;¨Se sobrepas¢ el m ximo divisor?
        ja short comenzar_potenciacion ;Comenzar con potenciaci¢n si es as¡.
        xor edx,edx             ;Extender el dividendo.
        mov eax,ebx             ;Poner la parte alta del dividendo.
        div esi                 ;Realizar la primera parte de la divisi¢n.
        mov eax,edi             ;Poner la parte baja del dividendo.
        div esi                 ;Realizar la segunda parte de la divisi¢n.
        and edx,edx             ;¨El resto vale cero?
        jz short prox_num_pot   ;Si es as¡ saltar porque el n£mero no es primo.
        add esi,2               ;Obtener el siguiente divisor.
        xor edx,edx             ;Extender el dividendo.
        mov eax,ebx             ;Poner la parte alta del dividendo.
        div esi                 ;Realizar la primera parte de la divisi¢n.
        mov eax,edi             ;Poner la parte baja del dividendo.
        div esi                 ;Realizar la segunda parte de la divisi¢n.
        and edx,edx             ;¨El resto vale cero?
        jz short prox_num_pot   ;Si es as¡ saltar porque el n£mero no es primo.
        add esi,4               ;Obtener el siguiente divisor.
comparar_divisor_pot:
        cmp ebx,esi             ;Ver si es necesario seguir extendiendo el
                                ;dividendo a 96 bits.
        jae segundo_bucle_div_64_32  ;Saltar si es as¡.
;Realizar la divisi¢n de 64 bits (EBX:EDI) por 32 bits (ESI).
;Lo que necesitamos nosotros es el resto (si vale cero, entonces EBX:EDI no
;es primo) y el cociente (si es menor que el divisor EBX:EDI es primo).
segundo_bucle_div_32_32:
        cmp esi,ecx             ;¨Se sobrepas¢ el m ximo divisor?
        ja short comenzar_potenciacion  ;Comenzar con potenciaci¢n si es as¡.
        mov edx,ebx             ;Poner la parte alta del dividendo.
        mov eax,edi             ;Poner la parte baja del dividendo.
        div esi                 ;Realizar la divisi¢n.
        and edx,edx             ;¨El resto vale cero?
        jz short prox_num_pot   ;Si es as¡ saltar porque el n£mero no es primo.
        add esi,2               ;Obtener el siguiente divisor.
        mov edx,ebx             ;Poner la parte alta del dividendo.
        mov eax,edi             ;Poner la parte baja del dividendo.
        div esi                 ;Realizar la divisi¢n.
        and edx,edx             ;¨El resto vale cero?
        jz short prox_num_pot   ;Si es as¡ saltar porque el n£mero no es primo.
        add esi,4               ;Obtener el siguiente divisor.
        cmp eax,esi             ;¨El divisor supera al cociente?
        jae segundo_bucle_div_32_32     ;Saltar si no es as¡.
;En este punto se sabe que EBX:EDI es primo, por lo que hay que mostrarlo.
mostrar_primo:
        call mostrar_numero
;Hallar el pr¢ximo valor de EBX:EDI para ver si es primo o no.
prox_num_pot:
        add edi,ebp             ;Sumar el valor adecuado.
        adc ebx,0
        xor bp,2 xor 4          ;Cambiar el indicador de sumar 2 ¢ 4.
        jmp primos_potenciacion
mostrar_primo_pot:
        pop ebp                 ;Restaurar el indicador de sumar 2 ¢ 4.
        jmp mostrar_primo       ;Mostrar el n£mero primo.
;
; Verificar si el n£mero es primo utilizando el m‚todo de potenciaci¢n que
; figura en http://www.utm.edu/research/primes/prove2.html (tercer par grafo)
; de Chris K. Caldwell:
;
; Si tenemos que verificar el n£mero impar "n", hacemos n-1=(2^s)d donde "d" es
; impar y s>0: decimos que n es a-SPRP si a^d=1 (mod n) o bien (a^d)^(2^r)=-1
; para alg£n valor r tal que 0<=r<s.
;
; Entonces:
; - Si n < 9.080.191 es 31 y 73-SPRP entonces n es primo.
; - Si n < 4.759.123.141 es 2, 7 y 61-SPRP entonces n es primo.
; - Si n < 1.000.000.000.000 es 2, 13, 23 y 1662803-SPRP entonces n es primo.
; - Si n < 2.152.302.898.747 es 2, 3, 5, 7 y 11-SPRP entonces n es primo.
; - Si n < 3.474.749.660.383 es 2, 3, 5, 7, 11 y 13-SPRP entonces n es primo.
; - Si n < 341.550.071.728.321 es 2, 3, 5, 7, 11, 13 y 17-SPRP entonces n es
;   primo.
; 
; Como este test no cubre n£meros mayores que el £ltimo mencionado, en caso de
; que aparezca alg£n n£mero con esa condici¢n deber  utilizarse el m‚todo de
; la divisi¢n (que para estos n£meros es muy lento) hasta que alguien
; encuentre c¢mo contin£a la tabla.
;
comenzar_potenciacion:
        push ebp                ;Preservar sumando (2 ¢ 4).
        push ebx                ;Preservar MSD del n£mero a verificar.
        push edi                ;Preservar LSD del n£mero a verificar.
        dec di                  ;Hallar n-1.
        bsf ecx,edi             ;ECX = Bit menos significativo de EDI a uno.
                                ;      Este es el valor de s.
        jz short LSD_n_es_cero  ;Saltar si EDI vale cero.
        shrd edi,ebx,cl
        shr ebx,cl              ;EBX:EDI = d = (n-1) / 2^s.
        jmp short se_hallo_s
LSD_n_es_cero:
        mov edi,ebx
        xor ebx,ebx             ;EBX:EDI = (n-1) / 2^32
        bsf ecx,edi             ;ECX = Bit menos significativo de EDI a uno.
                                ;      Este es el valor de (s-32).
        shr edi,cl              ;EBX:EDI = (n-1) / 2^(32+s-32)
                                ;        = (n-1) / 2^s.
        add cl,32               ;ECX = s.
se_hallo_s:
        mov valor_s,cx          ;Almacenar el valor de s.
;
; Para realizar el c lculo de la potenciaci¢n m s abajo, se utilizar  el
; m‚todo de elevar al cuadrado y multiplicar. Para ello, partiendo del bit
; m s significativo puesto a uno, se barrer n los diferentes bits de "d"
; (sin incluir el bit a uno m s significativo) hasta llegar al bit cero. Si el
; bit vale cero, se debe elevar al cuadrado, si vale uno, adem s de elevar al
; cuadrado hay que multiplicar por la base. Por esto hay que hallar la cantidad
; de bits a procesar y hay que justificar el n£mero "d" a la izquierda (as¡ se
; pueden barrer f cilmente los diferentes bits realizando desplazamientos a la
; izquierda).
;
        bsr ecx,ebx             ;ECX = Bit m s significativo del MSD de "d"
                                ;a uno.
        jz short MSD_d_es_cero ;Saltar si el MSD de "d" vale cero.
; Ahora hay que desplazar "d" hacia la izquierda (32-CL) bits. Para ello,
; se aprovechar  el hecho de que los procesadores 80386 y posteriores toman
; la cuenta de desplazamiento m¢dulo 32. De esta manera, desplazar (32-CL) bits
; hacia la izquierda se puede codificar como si se desplazara -CL bits.
        neg cl                  ;Desplazar hacia la izquierda -CL bits.
        jz short bit_0_MSD_d_a_uno ;Si CL = 0 el bit 0 vale uno, por lo que el
                                ;MSD no tiene bits significativos.
        shld ebx,edi,cl         ;Desplazar hacia la izquierda EDX:EAX.
        shl edi,cl
        sub cl,32               ;CL = -(Cantidad de bits significativos).
        jmp short hallar_bits_d ;Hallar contador (negando CL).
bit_0_MSD_d_a_uno:
        mov ebx,edi             ;Poner en el MSD los bits significativos.
        mov cl,32               ;Indicar que hay 32 bits significativos.
        jmp short almacenar_d_ajustado ;Almacenar d ajustado y cant de bits.
MSD_d_es_cero:
        mov ebx,edi             ;Mover los bits significativos hacia el MSD.
        bsr ecx,ebx             ;ECX = Bit m s significativo del LSD de d
                                ;a uno.
        neg cl                  ;Desplazar hacia la izquierda -CL bits.
        jz short d_uno          ;Si CL = 0 el bit 0 vale uno, por lo que d
                                ;vale uno.
        shl ebx,cl              ;Desplazar el factor hacia la izquierda.
hallar_bits_d:
        neg cl                  ;CL = Cantidad de bits significativos de d.
almacenar_d_ajustado:        
        mov MSD_d_ajustado,ebx  ;Almacenar el valor de "d" ajustado.
        mov LSD_d_ajustado,edi
d_uno:
        mov bits_d,cx           ;Almacenar la cantidad de d¡gitos
                                ;significativos de "d".
        pop edi                 ;Restaurar LSD del n£mero a verificar.
        pop ebx                 ;Restaurar MSD del n£mero a verificar.
        and ebx,ebx             ;¨El n£mero entra en un dword?
        jnz short verif_2do_caso ;Saltar si no es as¡.
        cmp edi,9080191         ;Ver si el n£mero entra dentro del primer caso.
        jae short es_2do_caso   ;Saltar si no es as¡.
        mov al,31               ;Comprobar si el n£mero es 31-SPRP.
        call verificar_SPRP
        mov al,73               ;Comprobar si el n£mero es 73-SPRP.
        call verificar_SPRP
        jmp mostrar_primo_pot   ;Si lo es, mostrar el n£mero primo.
verif_2do_caso:
        cmp ebx,1               ;Ver si el n£mero entra en el segundo caso.
        jnz short test_2do_caso
        cmp edi,1BAA74C5h
test_2do_caso:
        jae short verif_3er_caso ;Saltar si no es as¡.
es_2do_caso: 
        mov al,2                ;Comprobar si el n£mero es 2-SPRP.
        call verificar_SPRP
        mov al,7                ;Comprobar si el n£mero es 7-SPRP.
        call verificar_SPRP
        mov al,61               ;Comprobar si el n£mero es 61-SPRP.
        call verificar_SPRP
        jmp mostrar_primo_pot   ;Si lo es, mostrar el n£mero primo.
verif_3er_caso:
        mov al,2                ;Comprobar si el n£mero es 2-SPRP.
        call verificar_SPRP
        cmp ebx,0E8h            ;Ver si el n£mero entra en el tercer caso.
        jnz short test_3er_caso
        cmp edi,0D4A51000h
test_3er_caso:
        jae short es_4to_caso   ;Saltar si no es as¡.
        mov al,13               ;Comprobar si el n£mero es 13-SPRP.
        call verificar_SPRP
        mov al,23               ;Comprobar si el n£mero es 23-SPRP.
        call verificar_SPRP
        mov eax,1662803         ;Comprobar si el n£mero es 1.662.803-SPRP.
        call verificar_dword_SPRP
        jmp mostrar_primo_pot
es_4to_caso:
        mov al,3                ;Comprobar si el n£mero es 3-SPRP.
        call verificar_SPRP
        mov al,5                ;Comprobar si el n£mero es 5-SPRP.
        call verificar_SPRP
        mov al,7                ;Comprobar si el n£mero es 7-SPRP.
        call verificar_SPRP
        mov al,11               ;Comprobar si el n£mero es 11-SPRP.
        call verificar_SPRP
        cmp ebx,000001F5h       ;Ver si el n£mero entra en el cuarto caso.
        jnz short test_11
        cmp edi,1F3FEE3Bh
test_11:
        jb mostrar_primo_pot    ;Si es as¡ el n£mero es primo.
        mov al,13               ;Comprobar si el n£mero es 13-SPRP.
        call verificar_SPRP
        cmp ebx,00000329h       ;Ver si el n£mero entra en el quinto caso.
        jnz short test_13
        cmp edi,07381CDFh
test_13:
        jb mostrar_primo_pot    ;Si es as¡ el n£mero es primo.
        mov al,17               ;Comprobar si el n£mero es 17-SPRP.
        call verificar_SPRP
        cmp ebx,000136A3h       ;Ver si el n£mero entra en el sexto caso.
        jnz short test_17
        cmp edi,52B2C8C1h
test_17:
        jb mostrar_primo_pot    ;Si es as¡ el n£mero es primo.
        mov ecx,-1              ;Forzar divisiones sucesivas.
        mov esi,257             ;Comprobar a partir del £ltimo divisor probado.
        pop ebp                 ;Restaurar sumando (2 ¢ 4).
        jmp comparar_divisor_pot ;Verificar si el n£mero es primo.
;
; Subrutina para comprobar si EBX:EDI es AL-SPRP.
verificar_SPRP:
        and eax,0FFh            ;EAX <- Base SPRP.
;
; Subrutina para comprobar si EBX:EDI es EAX-SPRP.
verificar_dword_SPRP:
        test ebx,ebx            ;¨El n£mero a verificar tiene m s de 32 bits?
        jnz short verificar_SPRP_64_bits ;Si es as¡, utilizar rutina de 64 bits
        mov ebp,eax             ;EBP <- Base SPRP.
        mov cx,bits_d           ;Obtener la cantidad de bits de d.
        jcxz no_hay_ciclo_pot_32_bits ;Saltar si d no tiene bits significativos
                                ;Esto ocurre si d = 1 => n = 2^k+1 con k>=0.
        mov ebx,MSD_d_ajustado  ;Obtener el valor de d justificado a la izq.
; Con el siguiente ciclo se hallar  EAX ^ d (mod EDI) (primera parte del test).
ciclo_pot_32_bits:
        mul eax                 ;Elevar al cuadrado.
        div edi                 ;Hallar m¢dulo EDI.
        mov eax,edx             ;EAX = Resto de la divisi¢n.
        shl ebx,1               ;Obtener siguiente bit de d.
        jnc short fin_ciclo_pot_32 ;Si vale cero, no se debe multiplicar por
                                ;la base de SPRP.
        mul ebp                 ;Multiplicar por la base.
        div edi                 ;Hallar m¢dulo EDI.
        mov eax,edx             ;EAX = Resto de la divisi¢n.
fin_ciclo_pot_32:
        loop ciclo_pot_32_bits  ;Seguir procesando el resto de los bits de d.
        xor ebx,ebx             ;Poner EBX a cero como estaba antes. 
no_hay_ciclo_pot_32_bits:
        cmp eax,1               ;¨La base ^ d (mod n) = 1?
        jz short SPRP_OK        ;Si es as¡, se cumple el test.
        mov cx,valor_s          ;Obtener el valor de s.
; En el siguiente ciclo se elevar  al cuadrado hasta s veces el resultado de
; la primera parte del test. Si en alg£n momento el resultado es -1, el test
; se cumple (segunda parte del test de SPRP).
ciclo_cuad_32_bits:
        inc eax                 ;Si EAX = -1 (mod EDI), deber  ser EAX = EDI-1,
        cmp eax,edi             ;ya que 0 <= EAX < EDI.
        jz short SPRP_OK        ;Si EAX = -1 (mod EDI) se cumple el test.
        dec eax                 ;Restaurar el valor.
        mul eax                 ;Elevar al cuadrado.
        div edi                 ;Hallar m¢dulo EDI.
        mov eax,edx             ;EAX = Resto de la divisi¢n.
        loop ciclo_cuad_32_bits ;Cerrar el ciclo.
; Si no se cumpli¢ ninguna de las dos partes del test, el n£mero es compuesto.
es_compuesto:
        pop ax                  ;No retornar a rutina de verificaci¢n SPRP.
        pop ebp                 ;Restaurar sumando (2 ¢ 4).
        jmp prox_num_pot        ;Hallar el pr¢ximo n£mero a verificar.
SPRP_OK:
        ret                     ;Fin de la subrutina.
verificar_SPRP_64_bits:
        mov ecx,LSD_d_ajustado  ;Copiar el valor de d ajustado a otro lugar
        mov LSD_d_aux,ecx       ;ya que se va a modificar (este valor se va
        mov ecx,MSD_d_ajustado  ;a necesitar posteriormente).
        mov MSD_d_aux,ecx
        mov base_SPRP,eax       ;Preservar la base de SPRP.
        xor edx,edx             ;EDX:EAX = Base de SPRP.
        mov cx,bits_d           ;Obtener la cantidad de bits de d.
        jcxz no_hay_ciclo_pot_64_bits ;Saltar si d no tiene bits significativos
                                ;Esto ocurre si d = 1 => n = 2^k+1 con k>=0.
; Con el siguiente ciclo se hallar  EAX ^ d (mod EDI) (primera parte del test).
ciclo_pot_64_bits:
        shl LSD_d_aux,1         ;Obtener siguiente bit de d.
        rcl MSD_d_aux,1
        mov esi,eax
        mov ebp,edx             ;EBP:ESI <- Multiplicador actual.
; Si el bit vale cero, s¢lo hay que elevar al cuadrado, mientras que si vale
; uno, aparte de elevar al cuadrado, hay que multiplicar por la base de SPRP.
        jnc short multiplicador_ok ;El bit vale cero (no multiplicar por base)
        push edx                ;EDX:EAX <- EDX:EAX * base_SPRP
        mul base_SPRP
        push edx
        xchg ebp,eax
        mul base_SPRP
        pop edx
        add edx,eax
        mov eax,ebp
        pop ebp
multiplicador_ok:
        call mult_modulo_EBX_EDI ;EDX:EAX <- EBP:ESI * EDX:EAX  (mod EBX:EDI).
        loop ciclo_pot_64_bits  ;Seguir procesando el resto de los bits de d.
no_hay_ciclo_pot_64_bits:
        test edx,edx            ;¨La base ^ d (mod n) = 1?
        jnz short hallar_cuadrados
        cmp eax,1
        jz SPRP_OK              ;Si es as¡, se cumple el test.
hallar_cuadrados:
        mov cx,valor_s          ;Obtener el valor de s.
; En el siguiente ciclo se elevar  al cuadrado hasta s veces el resultado de
; la primera parte del test. Si en alg£n momento el resultado es -1, el test
; se cumple (segunda parte del test de SPRP).
ciclo_cuad_64_bits:
        mov esi,edi             ;¨Es EDX:EAX = -1 (mod EBX:EDI)?
        mov ebp,ebx
        stc
        sbb esi,eax
        sbb ebp,edx
        or ebp,esi
        jz SPRP_OK              ;Si es as¡ se cumple el test.
        mov ebp,edx
        mov esi,eax
        call mult_modulo_EBX_EDI ;Elevar al cuadrado modulo EBX:EDI.
        loop ciclo_cuad_64_bits ;Cerrar el ciclo.
        jmp es_compuesto        ;Si no se cumpli¢ el test, el n£mero es
                                ;compuesto.

; Subrutina para hallar EBP:ESI * EDX:EAX  (mod EBX:EDI) -> EDX:EAX.
mult_modulo_EBX_EDI:
        mov res_LO,edi
        sub res_LO,esi
        mov res_HI,ebx
        sbb res_HI,ebp          ;res = - EBP:ESI (mod EBX:EDI)
        push cx                 ;Preservar contador.
        bsr ecx,edx             ;ECX = Bit m s significativo del MSD del factor
                                ;a uno.
        jz short MSD_factor_es_cero ;Saltar si el MSD del factor vale cero.
; Ahora hay que desplazar el factor hacia la izquierda (32-CL) bits. Para ello,
; se aprovechar  el hecho de que los procesadores 80386 y posteriores toman
; la cuenta de desplazamiento m¢dulo 32. De esta manera, desplazar (32-CL) bits
; hacia la izquierda se puede codificar como si se desplazara -CL bits.
        neg cl                  ;Desplazar hacia la izquierda -CL bits.
        jz short bit_0_MSD_a_uno ;Si CL = 0 el bit 0 vale uno, por lo que el
                                ;MSD no tiene bits significativos.
        shld edx,eax,cl         ;Desplazar hacia la izquierda EDX:EAX.
        shl eax,cl
        sub cl,32               ;CL = -(Cantidad de bits significativos).
        jmp short hallar_contador ;Hallar contador (negando CL).
bit_0_MSD_a_uno:
        mov edx,eax             ;Poner en el MSD los bits significativos.
        mov cl,32               ;Indicar que hay 32 bits significativos.
        jmp short ciclo_interno_64 ;Comenzar con el ciclo de multiplicaci¢n.
MSD_factor_es_cero:
        mov edx,eax             ;Mover los bits significativos hacia el MSD.
        bsr ecx,edx             ;ECX = Bit m s significativo del LSD del factor
                                ;a uno.
        jz short factor_cero    ;Si el LSD vale cero, el factor vale cero.
        neg cl                  ;Desplazar hacia la izquierda -CL bits.
        jz short factor_uno     ;Si CL = 0 el bit 0 vale uno, por lo que el
                                ;factor vale uno.
        shl edx,cl              ;Desplazar el factor hacia la izquierda.
hallar_contador:
        neg cl                ;CL = Cantidad de bits significativos del factor.
; Ciclo para realizar la multiplicaci¢n.
ciclo_interno_64:
        add esi,esi             ;Multiplicar factor por dos.
        adc ebp,ebp
        sub esi,edi             ;Hallar factor m¢dulo EBX:EDI.
        sbb ebp,ebx
        jnc short ver_bit_factor ;Saltar si el valor hallado no es negativo.
        add esi,edi             ;Hallar factor m¢dulo EBX:EDI (valor positivo).
        adc ebp,ebx
ver_bit_factor:
        add eax,eax             ;Hallar el siguiente bit del factor.
        adc edx,edx
        jnc short fin_ciclo_interno_64 ;Saltar si el bit vale cero.
        sub esi,res_LO          ;Sumar el factor inicial (m¢dulo EBX:EDI).
        sbb ebp,res_HI
        jnc short fin_ciclo_interno_64 ;Saltar si es cero o positivo.
        add esi,edi             ;Hallar factor m¢dulo EBX:EDI (valor positivo).
        adc ebp,ebx
fin_ciclo_interno_64:
        loop ciclo_interno_64   ;Cerrar ciclo.
factor_uno:
        mov eax,esi             ;Poner el factor en los registros resultado.
        mov edx,ebp
factor_cero:
        pop cx                  ;Restaurar el contador.
        ret                     ;Fin de la subrutina.
;-------------------------------------------------;
; Manejador de la interrupci¢n de teclado (INT 9) ;
;-------------------------------------------------;
; N¢tese el manejo de la tecla Pausa, cuyo scan code es: E1 1D 45 E1 9D C5.
; Esta tecla es la £nica cuyo prefijo es E1.
int9han:in al,60h               ;AL = Tecla apretada o soltada seg£n bit 7.
        test estado,SCAN_CODE_E1 ;¨El scan code anterior fue E1?
        jnz short procesar_E1   ;Saltar si es as¡.
        cmp al,0E1h             ;¨Se est  apretando la tecla Pausa?
        jz short apretando_Pausa
        and estado,not APRETO_PAUSA ;Salir del modo Pausa (si estaba).
        test estado,SCAN_CODE_E0 ;¨El scan code anterior fue E0?
        jnz procesar_E0         ;Saltar si es as¡.
        mov bx,offset tabla     ;Apuntar a la tabla de teclas.
        mov cx,30               ;Cantidad de teclas reconocidas.
int9han1:cmp al,[bx]            ;Ver si se apret¢ la tecla correspondiente
                                ;a la entrada de la tabla.
        jz short int9han2       ;Saltar si es as¡.
        add bx,3                ;Apuntar a la pr¢xima entrada de la tabla.
        loop int9han1           ;Terminar el bucle.
        jmp short int9han3      ;No procesar la tecla.
int9han2:call word ptr [bx+1]   ;Llamar a la subrutina correspondiente a la
                                ;tecla presionada.
int9han3:mov al,61h             ;Indicarle al PIC un fin de interrupci¢n
        out 20h,al              ;espec¡fico de IRQ 1 (interrupci¢n 0).
        iretd                   ;Terminar la interrupci¢n.
;Cuando se ejecute la pr¢xima INT 9 va a ejecutar a partir de este punto.
        jmp int9han             ;Volver a ejecutar la interrupci¢n.
apretando_Pausa:
        or estado,SCAN_CODE_E1  ;Indicar que lleg¢ el scan code E1.
        jmp int9han3            ;Terminar la interrupci¢n.
procesar_E1:
        add estado,SCAN_DESPUES_E1 ;Incrementar la cantidad de scan codes
                                ;despu‚s del E1.
        jnc short int9han3      ;Todav¡a no llegaron todos los scan codes de
                                ;la tecla Pausa.
        or estado,APRETO_PAUSA  ;Indicar que se apret¢ la tecla Pausa.
        jmp int9han3            ;Fin de la interrupci¢n.
;Procesamiento de flecha arriba y flecha abajo.
tics_tarea2 equ <byte ptr TSS_int8.DX_val>
flecha: mov al,tics_tarea2      ;AL = Cantidad de tics de tarea 1.
        add al,dl               ;Sumar o restar 1 (dependiendo de la flecha)
        cmp al,20               ;¨Est  fuera del l¡mite?
        ja int9han3             ;Terminar la interrupci¢n si es as¡.
        mov tics_tarea2,al      ;Actualizar la cantidad de tics.
        mov bx,11*160+8*2       ;Mostrar en la pantalla el porcentaje de la
        call mos_porc           ;tarea 1.
        mov al,20
        sub al,tics_tarea2
        mov bx,13*160+8*2       ;Mostrar en la pantalla el porcentaje de la
        call mos_porc           ;tarea 2.
        jmp int9han3            ;Fin de la interrupci¢n.
;Subrutina para mostrar porcentaje: BX = Posici¢n en la pantalla.
;                                   AL = Cantidad de tics (0-20).
mos_porc:shr al,1               ;AL = Decenas.
        rcr ah,1                ;Bit 7 de AH = cero o cinco.
        cmp al,10               ;¨Las decenas valen diez (mostrar dos d¡gitos)?
        jnz short mos_porc1     ;Saltar si no es as¡.
        mov byte ptr es:[bx],"1" ;Mostrar el primer d¡gito.
        mov byte ptr es:[bx+2],"0" ;Mostrar el segundo d¡gito.
        add bx,4                ;Ir a la posici¢n de las unidades.
        jmp short mos_porc2     ;Mostrar las unidades.
mos_porc1:and al,al             ;¨Hay decenas?
        jz short mos_porc2      ;Saltar si no hay (no mostrarlas).
        add al,"0"              ;Convertir las decenas a ASCII.
        mov es:[bx],al          ;Poner el d¡gito en la pantalla.
        add bx,2                ;Apuntar a la posici¢n de las unidades.
mos_porc2:and ah,ah             ;Ver cu nto valen las unidades.
        mov al,"0"              ;Suponer que valen cero.
        jns short mos_porc3     ;Saltar si valen cero.
        mov al,"5"              ;Las unidades valen cinco.
mos_porc3:mov es:[bx],al        ;Poner las unidades en pantalla.
        mov byte ptr es:[bx+2],"%" ;Mostrar el s¡mbolo de porcentaje.
        mov byte ptr es:[bx+4]," " ;Borrar el car cter de la derecha.
fin_subr:ret                    ;Terminar la subrutina.
tecBREAK:
        test estado,CAMBIANDO_DIV or CAMBIANDO_POT
                                ;¨Se est  ingresando un n£mero?
        mov estado,APRETO_ESC   ;Indicar que se apret¢ la tecla ESC (bit 4=1)
        jz int9han3             ;Terminar si no se est  ingresando un n£mero.
        call cancelar_entrada   ;Cancelar el ingreso de n£mero.
        jmp int9han3            ;Terminar el manejador de interrupci¢n.
procesar_E0:and estado,not SCAN_CODE_E0 ;Indicar que ya se est  procesando E0.
        cmp al,48h              ;¨La tecla presionada es la flecha arriba?
        mov dl,1
        jz short flecha         ;Saltar si es as¡.
        cmp al,50h              ;¨La tecla presionada es la flecha abajo?
        mov dl,255
        jz short flecha         ;Saltar si es as¡.
        cmp al,46h              ;¨La tecla presionada es CTRL-BREAK?
        jz tecBREAK             ;Saltar si es as¡.
        cmp al,1Ch              ;¨La tecla presionada es el Enter gris?
        jnz int9han3            ;Saltar si no es as¡.
        call tecENT             ;Convertir el n£mero entrado a binario.
        jmp int9han3            ;Terminar el manejador de interrupci¢n.
tecENT: test estado,CAMBIANDO_POT or CAMBIANDO_DIV
                                ;Ver si se est  entrando un n£mero.
        jz finsubr              ;Salir de la subrutina si no es as¡.
        mov si,posnum*2         ;Posici¢n del primer d¡gito en la pantalla.
        xor eax,eax             ;EAX = Va a contener el d¡gito a sumar.
        xor ebx,ebx             ;ECX:EBX = Contiene el n£mero que se est 
        xor ecx,ecx             ;formando.
tecENT1:mov ebp,ebx             ;EDI:EBP <- ECX:EBX.
        mov edi,ecx
        mov al,es:[si]          ;Obtener el d¡gito en ASCII.
        add si,2                ;Apuntar al siguiente d¡gito en la pantalla.
        sub al,"0"              ;Convertir a binario.
        jc short tecENT2        ;Saltar si no es un d¡gito (se acab¢).
        add ebx,ebx             ;ECX:EBX <- ECX:EBX * 10
        adc ecx,ecx             ;(correr un d¡gito hacia la izquierda).
        add ebx,ebx
        adc ecx,ecx
        add ebx,ebp
        adc ecx,edi
        add ebx,ebx
        adc ecx,ecx
        add ebx,eax             ;ECX:EBX <- ECX:EBX + EAX
        adc ecx,0               ;(sumar el d¡gito).
        jmp tecENT1             ;Procesar el siguiente d¡gito.
;En este momento el par de registros ECX:EBX contienen el n£mero entrado.
tecENT2:xor edx,edx             ;Hallar el resto de ECX:EBX / 6.
        mov eax,ecx
        mov edi,6
        div edi
        mov eax,ebx
        div edi
        mov ebp,2               ;Sumando para el caso en que el resto valga 5.
        cmp dl,5                ;¨El resto vale 5?
        jz short tecENT3        ;Saltar si es as¡.
        mov bp,4                ;Sumando para el caso en que el resto valga 1.
        cmp dl,1                ;¨El resto vale 1?
        jz short tecENT3        ;Saltar si es as¡.
        add ebx,1               ;Seguro que el n£mero no va a ser primo, por lo
        adc ecx,0               ;que hay que incrementarlo.
        jmp tecENT2             ;Hacer lo mismo con el n£mero incrementado.
tecENT3:test estado,CAMBIANDO_DIV ;¨Qu‚ n£mero se estaba cambiando?
        mov si,offset TSS_primos_potenciacion ;Suponer que era el de
                                              ;primos_potenciacion.
        jz short tecENT4          ;Saltar si se estaba cambiando el de
                                  ;primos_potenciacion.
        mov si,offset TSS_primos_division ;Se estaba cambiando el de
                                  ;primos_division.
;Mover primero la doble palabra (32 bits) m s significativa y luego la
;doble palabra menos significativa.
tecENT4:mov dword ptr [si+EBX_value],ecx
        mov dword ptr [si+EDI_value],ebx
        mov word ptr [si+EIP_value],offset primos_potenciacion
        mov word ptr [si+ESP_value],offset pila_primos_potenciacion + 100h - base
        jz short offset_puesto
        mov word ptr [si+EIP_value],offset primos_division
        mov word ptr [si+ESP_value],offset pila_primos_division + 100h - base
offset_puesto:
        mov [si+EBP_value],ebp
        and estado,not (CAMBIANDO_POT or CAMBIANDO_DIV)
                                 ;Indicar que no se est  entrando un n£mero.
        mov cx,26*80             ;Poner el cursor fuera de la pantalla as¡ no
        call ponercur            ;se lo ve.
        mov bx,offset texto2     ;Mostrar el texto original.
        jmp short mostex
tecF1:  and estado,not RUN_DIVISION  ;Detener primos_division.
        ret
tecF2:  or estado,RUN_DIVISION   ;Continuar primos_division.
        ret
tecF3:  mov al,1                 ;Indicar que se cambiar  el n£mero de la
                                 ;tarea primos_division.
camnum: and estado,not (CAMBIANDO_POT or CAMBIANDO_DIV)
                                 ;Indicar en la variable de estado cu l es el
        or estado,al             ;n£mero que se est  cambiando.
        mov bx,offset texto4     ;Mostrar el texto "Nuevo n£mero:" en pantalla.
        call mostex
        mov cx,posnum            ;Situar el cursor a la derecha del texto.
;Subrutina para situar el cursor en una posici¢n determinada de la pantalla.
;Entrada: CX = L¡nea * 80 + Columna del cursor.
ponercur:mov dx,port6845        ;DX = Port de control del controlador de video.
        mov al,0eh              ;Indicarle que hay que escribir la parte alta
        out dx,al               ;(MSB) de la posici¢n del cursor.
        jmp $+2
        jmp $+2
        inc dx                  ;Apuntar al port de datos del 6845.
        mov al,ch               ;Obtener el valor a enviar al 6845.
        out dx,al               ;Escribir el valor.
        jmp $+2
        jmp $+2
        dec dx                  ;Apuntar al port de control del 6845,
        mov al,0fh              ;Indicarle que hay que escribir la parte baja
        out dx,al               ;(LSB) de la posici¢n del cursor.
        jmp $+2
        jmp $+2
        inc dx                  ;Apuntar al port de datos del 6845.
        mov al,cl               ;Obtener el valor a enviar al 6845.
        out dx,al               ;Escribir el valor.
        ret
tecF4:  and estado,not RUN_POTEN ;Detener primos_potenciacion.
        ret
tecF5:  or estado,RUN_POTEN     ;Continuar primos_potenciacion.
        ret
tecF6:  mov al,CAMBIANDO_POT    ;Indicar que se cambiar  el n£mero de la
                                ;tarea primos_potenciacion.
        jmp camnum              ;Ir a cambiar el n£mero.
tecESC: test estado,CAMBIANDO_DIV or CAMBIANDO_POT
                                ;Ver si se est  entrando un n£mero.
        jnz short cancelar_entrada  ;Saltar si es as¡.
tecESC1:mov estado,APRETO_ESC   ;Indicar que se apret¢ la tecla ESC (bit 4=1)
        ret                     ;y que ejecute la tarea nula (bits 3,2=00)
cancelar_entrada:
        mov cx,26*80            ;Poner el cursor fuera de la pantalla as¡ no
        call ponercur           ;se lo ve.
        and estado,not (CAMBIANDO_DIV or CAMBIANDO_POT)
                                ;Indicar que no se est  entrando un n£mero.
        mov bx,offset texto2    ;Mostrar el texto original.
;Subrutina para mostrar texto. Entrada: BX = Puntero al texto.
;                                       SI = Posici¢n en la pantalla.
mostex: mov si,[bx]             ;Obtener la posici¢n de pantalla.
        add bx,2                ;Apuntar al primer car cter del texto.
mostex1:mov al,[bx]             ;Obtener el car cter del texto.
        mov es:[si],al          ;Ponerlo en la pantalla.
        inc bx                  ;Incrementar el puntero del texto.
        add si,2                ;Incrementar el puntero del buffer de pantalla.
        cmp byte ptr [bx],0     ;¨Se acab¢ el texto?
        jnz mostex1             ;Saltar si no es as¡.
finsubr:ret                     ;Fin de la subrutina.
tecnum: dec cx                  ;CL = D¡gito presionado.
        cmp cl,10               ;Si se apret¢ un d¡gito de la l¡nea superior
        jb short tecnum1        ;el n£mero est  bien, mientras que si se
        sub cl,10               ;apret¢ del pad num‚rico hay que restar 10.
tecnum1:add cl,"0"              ;Convertir el d¡gito a ASCII.
        call obtencur           ;SI = L¡nea * 80 + Columna (posici¢n cursor)
        cmp si,posnum+19        ;Ver si se lleg¢ al l¡mite derecho.
        jz finsubr              ;Salir de la subrutina si es as¡.
        push cx                 ;Preservar el d¡gito ASCII en la pila.
        mov cx,si               ;CX = Posici¢n del cursor.
        inc cx
        call ponercur           ;Moverlo un lugar a la derecha.
        add si,si               ;Convertir a posici¢n de buffer de pantalla.
        pop ax                  ;Obtener el d¡gito en ASCII.
        mov es:[si],al          ;Poner el d¡gito en la pantalla.
        ret                     ;Fin de la subrutina.
tecBACK:test estado,CAMBIANDO_POT or CAMBIANDO_DIV
                                ;Ver si se est  entrando un n£mero.
        jz finsubr              ;Salir de la subrutina si no es as¡.
        call obtencur           ;SI = L¡nea * 80 + Columna (posici¢n cursor)
        cmp si,posnum           ;Ver si se lleg¢ al l¡mite izquierdo.
        jz finsubr              ;Salir de la subrutina si es as¡.
        dec si
        mov cx,si               ;CX = Nueva posici¢n del cursor.
        call ponercur           ;Mover el cursor un lugar hacia la izquierda.
        add si,si               ;Convertir a posici¢n de buffer de pantalla.
        mov byte ptr es:[si]," ";Poner un espacio en dicha posici¢n.
        ret                     ;Fin de la subrutina.
tecE0:  or estado,SCAN_CODE_E0  ;Indicar que el c¢digo recibido fue E0.
        ret                     ;Fin de la subrutina.
;Tabla de teclas y sus subrutinas.
;La tecla est  representada por su "scan code".
;Las teclas que tienen dos bytes de scan code (el primero siempre es E0)
;se procesan aparte.
tabla   db 3Bh               ;Tecla F1
        dw tecF1
        db 3Ch               ;Tecla F2
        dw tecF2
        db 3Dh               ;Tecla F3
        dw tecF3
        db 3Eh               ;Tecla F4
        dw tecF4
        db 3Fh               ;Tecla F5
        dw tecF5
        db 40h               ;Tecla F6
        dw tecF6
        db 01h               ;Tecla Esc
        dw tecESC
        db 1Ch               ;Tecla Enter o Enter gris (con E0 adelante)
        dw tecENT
        db 0Eh               ;Tecla Backspace
        dw tecBACK
        db 0E0h              ;C¢digo especial del teclado expandido.
        dw tecE0
        db 49h               ;Tecla 9 (pad num‚rico)
        dw tecnum
        db 48h               ;Tecla 8 (pad num‚rico) o flecha arriba (con E0)
        dw tecnum
        db 47h               ;Tecla 7 (pad num‚rico)
        dw tecnum
        db 4Dh               ;Tecla 6 (pad num‚rico)
        dw tecnum
        db 4Ch               ;Tecla 5 (pad num‚rico)
        dw tecnum
        db 4Bh               ;Tecla 4 (pad num‚rico)
        dw tecnum
        db 51h               ;Tecla 3 (pad num‚rico)
        dw tecnum
        db 50h               ;Tecla 2 (pad num‚rico) o flecha abajo (con E0)
        dw tecnum
        db 4Fh               ;Tecla 1 (pad num‚rico)
        dw tecnum
        db 52h               ;Tecla 0 (pad num‚rico)
        dw tecnum
        db 0Ah               ;Tecla 9
        dw tecnum
        db 09h               ;Tecla 8
        dw tecnum
        db 08h               ;Tecla 7
        dw tecnum
        db 07h               ;Tecla 6
        dw tecnum
        db 06h               ;Tecla 5
        dw tecnum
        db 05h               ;Tecla 4
        dw tecnum
        db 04h               ;Tecla 3
        dw tecnum
        db 03h               ;Tecla 2
        dw tecnum
        db 02h               ;Tecla 1
        dw tecnum
        db 0Bh               ;Tecla 0
        dw tecnum
;Subrutina para obtener la posici¢n del cursor en la pantalla.
;Salida: Registro SI = L¡nea * 80 + Columna del cursor.
obtencur:mov dx,port6845     ;DX = Port de control del controlador de video.
        mov al,0Eh           ;Indicarle que hay que leer la parte alta
        out dx,al            ;(MSB) de la posici¢n del cursor.
        jmp $+2
        jmp $+2
        inc dx               ;Apuntar al port de datos del 6845.
        in al,dx             ;Leer el valor.
        mov ah,al            ;Ponerlo en la parte alta de AX.
        jmp $+2
        jmp $+2
        dec dx               ;Apuntar al port de control del 6845,
        mov al,0Fh           ;Indicarle que hay que leer la parte baja
        out dx,al            ;(LSB) de la posici¢n del cursor.
        jmp $+2
        jmp $+2
        inc dx               ;Apuntar al port de datos del 6845.
        in al,dx             ;Leer el valor.
        mov si,ax            ;Poner el resultado en SI.
        ret                  ;Fin de la subrutina.
;------------------------------------------------;
; Manejador de la interrupci¢n del timer (INT 8) ;
;------------------------------------------------;
int8han:mov al,60h           ;Indicarle al PIC un fin de interrupci¢n
        out 20h,al           ;espec¡fico de la IRQ 0 (interrupci¢n 8).
        jmp $+2
        jmp $+2
;Habilitar la interrupci¢n de teclado y deshabilitar la del timer. Esto se hace
;as¡ porque como en el descriptor de la tabla de interrupci¢n IDT hay una
;compuerta de tarea, la interrupci¢n no es reentrante. Si se llegara a ocurrir
;nuevamente la interrupci¢n ocurrir¡a una excepci¢n 13.
        mov al,0FDh          ;Habilitar la interrupci¢n de teclado.
        out 21h,al           ;y deshabilitar la del timer.
        loop tiempo_no_cero  ;Decrementar el contador de tiempo de tarea.
        mov cl,20            ;Si lleg¢ a cero ponerlo al valor inicial.
tiempo_no_cero:
        test estado,APRETO_PAUSA ;¨Se apret¢ la tecla Pausa?
        mov ax,TSS_inic_sel  ;Seleccionar la tarea nula.
        jnz short nueva_tarea ;Saltar si es as¡.
        mov al,estado        ;Bits 3 y 2 del estado: 00 = nada,
                             ;01 = primos_division, 10 = primos_potenciacion,
                             ;11 = ambas tareas.
        cmp cl,dl            ;¨Tarea primos_division o tarea primos_potenc?
        ja short ir_a_primos_pot ;Ir a tarea primos_potenciacion.
        test al,RUN_DIVISION ;Ver si la tarea primos_division est  activa.
        mov ax,TSS_pri1_sel  ;Selector de la tarea primos_division.
        jmp short tarea_activa?
ir_a_primos_pot:
        test al,RUN_POTEN    ;Ver si la tarea primos_potenciacion est  activa.
        mov ax,TSS_pri2_sel  ;Selector de la tarea primos_potenciacion.
tarea_activa?:
        jnz short nueva_tarea ;Saltar si es as¡.
        mov al,TSS_inic_sel  ;Selector de la tarea nula.
nueva_tarea:
        mov salto,ax         ;Almacenar el selector de TSS para saltar all¡.
        mov al,0FEh          ;Indicarle al PIC que deshabilite la 
        out 21h,al           ;interrupci¢n de teclado.
        mov byte ptr gdt[TSS_int8_sel + 5],81h ;TSS 286 desocupado.
        mov byte ptr gdt[TSS_pri1_sel + 5],89h ;TSS 386 desocupado.
        mov byte ptr gdt[TSS_pri2_sel + 5],89h ;TSS 386 desocupado.
        mov byte ptr gdt[TSS_inic_sel + 5],81h ;TSS 286 desocupado.
        jmp far ptr dummy        ;Cambiar de tarea.
        org $-2                  ;Mover la posici¢n de ensamblado para que
                                 ;apunte al segmento del salto intersegmento.
salto   dw 0
;Cuando se ejecute la pr¢xima INT 8 va a ejecutar a partir de este punto.
        jmp int8han              ;Volver a ejecutar la interrupci¢n.
;Subrutina para cambiar la velocidad del timer. Entrada: El registro CX
;contiene la m xima cuenta. El tiempo entre interrupciones ser  de 
;(CX / 1193180) segundos. Si CX = 0, reemplazar en la f¢rmula por 65536.
timer:  mov al,00110110b         ;bit 7,6 = (00) timer 0.
                                 ;bit 5,4 = (11) escribir LSB y luego MSB.
                                 ;bit 3-1 = (011) generar onda cuadrada.
                                 ;bit 0 = (0) contador binario.
        out 43h,al               ;salida al registro de control del PIT
                                 ;(Programmable Interval Timer).
        jmp $+2
        mov al,cl                ;Escribir el LSB de la cuenta del timer.
        out 40h,al
        jmp $+2
        mov al,ch                ;Escribir el MSB de la cuenta del timer.
        out 40h,al
        ret
inicio: mov dx,offset texto6   ;Puntero al texto de procesador incorrecto.
test86: pushf                  ;Sirve para rechazar un 8086. En este procesador
        pop ax                 ;los bits 15-12 del registro de indicadores
        and ax,0FFFh           ;siempre est n a uno.
        push ax
        popf
        pushf
        pop ax
        add ax,1000h
        jc short mal
test286:pushf                  ;Sirve para rechazar un 80286. En este
        pop ax                 ;procesador los bits 15-12 del registro de
        or ax,0F000h           ;indicadores siempre est n a cero en modo real.
        push ax
        popf
        pushf
        pop ax
        and ax,0F000h
        jz short mal
virtual?:smsw ax        ;Sirve para ver si el 80386 est  en modo virtual.
        test al,1       ;Aqu¡ no puede utilizarse MOV EAX,CR0 ya que esta
                        ;instrucci¢n genera una excepci¢n 13 en modo virtual.
        jz short modo_real
        mov dx,offset texto5
mal:    mov ah,9             ;Mostrar el mensaje de error.
        int 21h
        mov ax,4c01h         ;Terminar el programa con c¢digo de salida 1.
        int 21h
modo_real:in al,21h          ;Almacenar en un lugar temporal los IRQ habili-
        mov picint,al        ;tados en el controlador de interrupciones (PIC).
        mov real_cs,cs       ;Llenar el campo correspondiente al segmento en
                             ;el salto intersegmento que est  m s abajo.
        mov ah,0Fh           ;Obtener el tipo de pantalla: 7 = Monocrom tico,
        int 10h              ;otro valor = color.
        mov bx,0B000h        ;Segmento para buffer de video monocromo.
        cmp al,7             ;Ver si es monocromo.
        jz short inicio1     ;Saltar si es as¡.
        mov port6845,3D4h    ;Port de tarjeta color.
        mov bx,0B800h        ;Segmento para buffer de video color.
        or byte ptr gdt[pant_sel + 3],80h    ;Ajustar en la GDT las bases de
        or byte ptr gdt[pant_inf_sel + 3],80h;los segmentos para tarjeta color.
inicio1:mov es,bx
        xor di,di            ;Limpiar la pantalla.
        mov cx,25*80         ;25 l¡neas * 80 caracteres.
        mov ax,0720h         ;Car cter espacio con atributo blanco sobre negro.
        cld                  ;Direcci¢n de escritura hacia arriba.
        rep stosw            ;Llenar los 4000 bytes con los espacios.
        mov cl,80            ;Generar las dos l¡neas horizontales.
        mov si,10*80*2
inicio2:mov byte ptr es:[si],196
        mov byte ptr es:[si+4*80*2],196
        add si,2
        loop inicio2
        mov bx,offset texto1  ;Mostrar los tres textos en la zona central.
        call mostex
        mov bx,offset texto2
        call mostex
        mov bx,offset texto3
        call mostex
        mov cx,26*80          ;Sacar el cursor de la pantalla poni‚ndolo en
        call ponercur         ;la l¡nea 26.
        xor eax,eax
        mov ax,cs
        shl eax,4             ;EAX = Direcci¢n lineal de inicio de este
                              ;segmento.
        add dword ptr gdt[code_sel + 2],eax ;Poner los verdaderos inicios
        add dword ptr gdt[data_sel + 2],eax ;(bases) de los segmentos.
        add dword ptr gdt[TSS_inic_sel + 2],eax
        add dword ptr gdt[TSS_pri1_sel + 2],eax
        add dword ptr gdt[TSS_pri2_sel + 2],eax
        add dword ptr gdt[TSS_int8_sel + 2],eax
        add dword ptr gdt[TSS_int9_sel + 2],eax
        add dword ptr gdtr[2],eax
        add dword ptr idtr[2],eax
        mov al,0FFh     ;Deshabilitar todas las IRQ del PIC.
        out 21h,al
        jmp $+2
        mov cx,3580     ;Hacer un tic del timer cada 0,003 segundos.
        call timer      ;Esta ser  la resoluci¢n del "scheduler" (interr. 8).
        sidt real_idtr  ;Almacenar en memoria el IDTR del modo real.
        lgdt gdtr       ;Cargar el GDTR.
        lidt idtr       ;Cargar el IDTR.
        push code_sel   ;Poner en la pila el descriptor y el offset del
        push offset modo_protegido ;c¢digo en modo protegido.
        smsw ax         ;Pasar a modo protegido poniendo a uno el bit 0
        or al,1         ;(Protection Enable) de CR0. Las instrucciones SMSW y
        lmsw ax         ;LMSW operan con la mitad (16 bits) baja de CR0 (MSW).
        retf            ;Ir a ejecutar c¢digo en modo protegido.
                        ;En este caso es la instrucci¢n siguiente.
modo_protegido:
        mov ax,TSS_inic_sel
        ltr ax          ;Cargar el registro puntero de TSS.
;Cargar los registros de segmento con el selector del segmento de pila. Es
;fundamental cargar todos los registros, ya que, como antes de comenzar el
;programa tienen cualquier valor, al realizar un cambio de tarea tomar  el
;valor del segmento real como un selector en modo protegido. Como esta entrada
;generalmente no est  definida en la GDT, ocurrir  una excepci¢n 13.
        mov ax,data_sel
        mov ds,ax
        mov ss,ax
        mov es,ax
        mov fs,ax
        mov gs,ax
        mov al,0FEh     ;Habilitar £nicamente la INT 8 (reloj).
        out 21h,al
        jmp $+2
espera: test estado,APRETO_ESC ;¨Se apret¢ la tecla ESC?
        jz espera       ;Saltar si no es as¡.
        mov al,0FFh     ;Deshabilitar todas las interrupciones.
        out 21h,al
        jmp $+2
        mov eax,cr0     ;Volver a modo real poniendo a cero el bit 0 de CR0.
        and al,0feh     ;Con la instrucci¢n LMSW no se puede poner a cero
        mov cr0,eax     ;este bit (por compatibilidad con el 80286).
        jmp far ptr dummy ;Aqu¡ es absolutamente necesario un salto DIRECTO
                          ;intersegmento. No funciona ni el m‚todo de retf
                          ;(como arriba) ni un salto indirecto.
        org $-4           ;Mover la posici¢n de ensamblado para que
                          ;apunte al offset del salto intersegmento.
        dw regreso_a_modo_real ;Offset del salto.
real_cs dw 0              ;Segmento del salto. Debe copiarse aqu¡ el valor del
                          ;segmento de c¢digo inicial (en modo real) en tiempo
                          ;de ejecuci¢n (si el programa hubiese sido .EXE esto
                          ;no hubiera sido necesario).
regreso_a_modo_real:
        mov ax,cs         ;Restaurar el valor del segmento
        mov ss,ax         ;de pila en modo real.
        lidt ss:real_idtr ;Restaurar el valor de IDTR en modo real.
        xor cx,cx         ;Restaurar la velocidad del timer.
        call timer
        mov al,ss:picint  ;Restaurar las habilitaciones de la PIC.
        out 21h,al
        jmp $+2
;Como no se increment¢ el tic de reloj durante la ejecuci¢n del programa,
;la hora que indicar  el DOS estar  atrasada, por lo que hay que leer la
;hora del reloj de tiempo real mediante la BIOS e indic rselo al DOS
;mediante la funci¢n de poner la hora. La BIOS devuelve la hora en BCD,
;mientras que el DOS espera la hora en binario.
        mov ah,2          ;Utilizar la funci¢n de BIOS para leer la hora.
        int 1Ah           ;CH = Hora, CL = Minutos, DH = Segundos (en BCD).
        mov al,ch
        mov ah,ch
        shr ah,4          ;AH = Decenas de horas.
        and al,0Fh        ;AL = Unidades de horas.
        aad
        mov ch,al         ;CH = Hora (en binario).
        mov al,cl
        mov ah,cl
        shr ah,4          ;AH = Decenas de minutos.
        and al,0Fh        ;AL = Unidades de minutos.
        aad
        mov cl,al         ;CL = Minutos (en binario).
        mov al,dh
        mov ah,dh
        shr ah,4          ;AH = Decenas de segundos.
        and al,0Fh        ;AL = Unidades de segundos.
        aad
        mov dh,al         ;DH = Segundos (en binario).
        mov dl,50         ;DL = Cent‚simas de segundo.
        mov ah,2Dh        ;Poner la hora del DOS.
        int 21h
        mov ax,4c00h      ;Terminar el programa.
        int 21h
        align 4           ;Hacer que el SP sea m£ltiplo de 4 (por velocidad).
pila_primos_division        equ $
pila_primos_potenciacion    equ $+100h
pila_int8       equ $+200h
pila_int9       equ $+300h
codigo  ends
        end comienzo
