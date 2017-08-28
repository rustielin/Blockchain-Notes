#!/bin/bash
for i in {1..8}; do 
	pandoc -o note$i.md note$i.tex; 
	cat note$i.md | sed 's\{.* .unnumbered}\\g' > testnote$i.md; 
	mv testnote$i.md note$i.md;
done 
