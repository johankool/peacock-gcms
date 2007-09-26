#!/bin/sh
cd "`dirname \"$0\"`"
cd MOs
mogenerator -model ../JKLibrary.xcdatamodel -includem include.m
