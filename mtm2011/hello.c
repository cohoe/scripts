#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

char buffer[81];

main()
{
	int i;
	int isPalin(int);
	int isPrime(int);
	char intro[] = "This is a number";
	printf("Hello World\n");
	for(i=0; i<15000; i++) {
		if(isPrime(i)==1 && isPalin(i)==1) {
			printf("%s %d is a palindrome\n",intro,i);
		}
	}
}

int isPalin(int input_num) {
	char s[81];
	sprintf(s,"%d",input_num);
	   int i,l;
	l =  strlen(s);
	for(i=0; i<l/2; i++) {
		if(s[i] != s[l-i-1]) { return 0; }
	}
	return 1;
}

int isPrime (int myInt) {
	int loop;

	for (loop = 2; loop < myInt/2+1; loop++) {
		if (myInt%loop==0) {
			return 0;
		}
	}
	return 1;
}
