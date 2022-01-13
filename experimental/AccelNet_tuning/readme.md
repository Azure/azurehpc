# How to tune Accelerated Networking on HB120_v2 and HB60

The performance benefits of enabling accelerated networking on HBV3, HBv2 and HB60 can only be realized if some network tuning is applied to the front-end network.
>Note: These manual network tuning will be unnecessary once, similar network tuning are included in HPC marketplace images.

  - Change the number of  multi-purpose channels for the $DEVICE (see below) network device. By default the HB and HC SKU's have 31. Overall, 4 seems to give the best performance.

Find device associated with accelerated networking virtual function.
```
[hpcadmin@hbv3vmss000004 ~]$ ibdev2netdev | grep an0
mlx5_an0 port 1 ==> <b>enP45424s1</b> (Up)
```
>Note: The device name may change on different nodes, in this example DEVICE=enP45424s1

  ```bash
  ethtool -L $DEVICE combined 4
  ```
  - Pin the first four multi-purpose channels of $DEVICE  to vNUMA 0

    First get the first four multi-purpose channel indices
  ```bash
  ls /sys/class/net/$DEVICE/device/msi_irqs
  53  55  57  59  61  63  65  67  69  71  73  75  77  79  81  83
54  56  58  60  62  64  66  68  70  72  74  76  78  80  82  84
  ```
>NOTE: It may be useful to see all irqs (see /proc/interrupts), ignore the first index (in this case 53), it is associated with a different irq.

  map first four multi-purpose channel to vNUMA 0
  ```bash
  echo "0" > /proc/irq/${irq_index[0]}/smp_affinity_list
  echo "1" > /proc/irq/${irq_index[1]}/smp_affinity_list
  echo "2" > /proc/irq/${irq_index[2]}/smp_affinity_list
  echo "3" > /proc/irq/${irq_index[3]}/smp_affinity_list
  ```

  >Note : The script map_irq_to_numa.sh will do these tuning steps automatically.

  ## Script usage: map_to_numa.sh

  ```bash
  map_irq_to_numa.sh <Starting core_id index> <Number of multi-purpose channels>
  ```
  >Note: Default starting core_id index is 0 and Default number of multi-purpose channels is 4

  ```bash
  [root@hbv2vmss000001 data]# ./map_irq_to_numa.sh
combined unmodified, ignoring
no channel parameters changed, aborting
current values: tx 0 rx 0 other 0 combined 4
Channel parameters for eth2:
Pre-set maximums:
RX:             0
TX:             0
Other:          0
Combined:       31
Current hardware settings:
RX:             0
TX:             0
Other:          0
Combined:       4

0, 54
0
1, 55
1
2, 56
2
3, 57
3

  ```

  ```bash
  [root@hbv2vmss000000 data]# ./map_irq_to_numa.sh 0 8
Channel parameters for eth2:
Pre-set maximums:
RX:             0
TX:             0
Other:          0
Combined:       31
Current hardware settings:
RX:             0
TX:             0
Other:          0
Combined:       8

0, 54
0
1, 55
1
2, 56
2
3, 57
3
4, 58
4
5, 59
5
6, 60
6
7, 61
7
  ```
