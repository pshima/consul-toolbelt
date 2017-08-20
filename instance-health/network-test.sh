#!/bin/bash

startloop(){
  echo `date`; 
  sudo tc qdisc del dev eth0 root;
}

closeloop(){
  tc -s qdisc;
  sleep 300;
  sudo tc qdisc del dev eth0 root;
  echo `date`;
  sleep 120;
}

startloop
echo "Delay 250ms"
sudo tc qdisc add dev eth0 root netem delay 250ms 10ms 25% 
closeloop

startloop
echo "Delay 500ms"
sudo tc qdisc add dev eth0 root netem delay 500ms 10ms 25% 
closeloop

startloop
echo "Delay 1000ms"
sudo tc qdisc add dev eth0 root netem delay 1000ms 10ms 25% 
closeloop

startloop
echo "Loss Random 0.1"
sudo tc qdisc add dev eth0 root netem loss 0.1%
closeloop

startloop
echo "Loss Random 1.0"
sudo tc qdisc add dev eth0 root netem loss 1.0%
closeloop

startloop
echo "Loss Random 5.0"
sudo tc qdisc add dev eth0 root netem loss 5.0%
closeloop

startloop
echo "Loss 10 25"
sudo tc qdisc add dev eth0 root netem loss 10.0% 25%
closeloop

startloop
echo "Loss 25 25"
sudo tc qdisc add dev eth0 root netem loss 25.0% 25%
closeloop

startloop
echo "Loss 75 25"
sudo tc qdisc add dev eth0 root netem loss 75.0% 25%
closeloop

startloop
echo "Loss 99 25"
sudo tc qdisc add dev eth0 root netem loss 99.0% 25%
closeloop
