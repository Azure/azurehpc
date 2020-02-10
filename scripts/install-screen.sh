#!/bin/bash

sudo yum install -y screen

cat << EOF > /home/$USER/.screenrc
screen -t "top"  0 top
screen -t "bash 1"  0 bash
defscrollback 10000
sessionname local
shelltitle bash
startup_message off
vbell off
bind = resize =
bind + resize +2
bind - resize -2
bind _ resize max
caption always "%{= wr} \$HOSTNAME %{= wk} %-Lw%{= wr}%n%f %t%{= wk}%+Lw %{= wr} %=%c %Y-%m-%d "
zombie cr
escape ^]]
EOF

