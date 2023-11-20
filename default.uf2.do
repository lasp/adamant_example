#!/bin/sh

elf=$2.elf
redo-ifchange $elf
elf2uf2 $elf $3
