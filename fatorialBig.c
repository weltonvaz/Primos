#include <stdio.h>
#include <openssl/bn.h>

int main(int argc, char *argv[])
{
   BIGNUM *fat; // declaração de uma variável Big
   BN_ULONG a, f; // apenas um long int normal
   char *resp;
   int i;

   /* Primeiro tem que alocar as variáveis BIGNUM */
   fat = BN_new();

   for (i = 1; i < argc; i++) {
      printf("Calculando fatorial de %s\n", argv[i]); 

      /* convertendo string em long int */
      f = atoll(argv[i]); 

      /* forma de atribuir 1 a uma variável BIGNUM */
      BN_dec2bn(&fat, "1"); 

      for (a = 2; a <= f; a++) {
         BN_mul_word(fat, a);
      } 

      /* gerando uma string imprimível do resultado */
      resp = BN_bn2dec(fat); 

      /* impressão do resultado (agora é uma string) */
      printf("Fatorial de %s = %s\n", argv[i], resp);
   }
}
