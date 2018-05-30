/*
 * rsset.c
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "super98.h"

#define CMDNUM  3
#define BAUDNUM 10

void cmd_speed(char *argv);
void cmd_er(char *argv);
void cmd_rs(char *argv);

int main(int argc, char **argv)
{
	char *cmdstr[CMDNUM] = {
		"speed", "er", "rs",
	};
	int i;

	argc--;
	argv++;
	if (argc == 0) {
		printf("usage: rsset <cmd> <arg>...\n");
		printf("  speed <num>: set baud\n");
		printf("  er {on|off}: switch ER line\n");
		printf("  rs {on|off}: switch RS line\n");
		return 0;
	}
	while (argc >= 2) {
		for (i = 0; i < CMDNUM; i++) {
			if (stricmp(cmdstr[i], *argv) == 0) {
				break;
			}
		}
		switch (i) {
		case 0:
			cmd_speed(*(argv + 1));
			break;
		case 1:
			cmd_er(*(argv + 1));
			break;
		case 2:
			cmd_rs(*(argv + 1));
			break;
		default:
			fprintf(stderr, "rsset: %s: unknown command\n", *argv);
			return 1;
		}
		argc -= 2;
		argv += 2;
	}
	if (argc != 0) {
		fprintf(stderr, "rsset: %s: missing argument\n", *argv);
		return 1;
	}
	return 0;
}

void cmd_speed(char *argv)
{
	unsigned int tbl[BAUDNUM] = {
		75, 150, 300, 600, 1200, 2400, 4800, 9600, 19200, 38400U
	};
	unsigned int baud;
	int i;

	baud = (unsigned int)strtol(argv, NULL, 10);
	for (i = 0; i < BAUDNUM; i++) {
		if (baud == tbl[i]) {
			break;
		}
	}
	if (i == BAUDNUM) {
		fprintf(stderr, "rsset: speed %s: uh?\n", argv);
	} else {
		SetSpeed(i);
	}
}

void cmd_er(char *argv)
{
	if (stricmp(argv, "on") == 0) {
		SetErOn();
	} else if (stricmp(argv, "off") == 0) {
		SetErOff();
	} else {
		fprintf(stderr, "rsset: er %s: uh?\n", argv);
	}
}

void cmd_rs(char *argv)
{
	if (stricmp(argv, "on") == 0) {
		SetRsOn();
	} else if (stricmp(argv, "off") == 0) {
		SetRsOff();
	} else {
		fprintf(stderr, "rsset: rs %s: uh?\n", argv);
	}
}

/* rsset.c */
