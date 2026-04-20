include "icurses/text.m";

IcView: module
{
	PATH: con "/dis/lib/icurses/view.dis";

	init: fn();

	callstrlen2: fn(s: string, width: int): int;
	callwrap: fn(s: string, width: int): array of string;
	callwrapnums: fn(n: int): array of int;
};
