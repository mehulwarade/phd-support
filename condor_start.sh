ssh -t 192.168.5.101 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.102 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.103 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.104 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.105 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.106 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.107 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.108 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.109 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.110 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.111 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.112 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.113 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.114 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.115 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.116 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.117 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.118 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.119 "echo mcs | sudo -S condor_master"
ssh -t 192.168.5.120 "echo mcs | sudo -S condor_master"

sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node1/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node2/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node3/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node4/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node5/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node6/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node7/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node8/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node9/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node10/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node11/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node12/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node13/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node14/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node15/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node16/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node17/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node18/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node19/etc/condor/
sudo cp /home/mehul/shared_fs/condor_config.local /home/mehul/nfs/node20/etc/condor/

pid=$(pgrep -u condor condor_master) && sudo kill $pid   # Not working remotely
pgrep condor_master | sudo xargs kill

ssh -t 192.168.5.101 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.102 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.103 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.104 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.105 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.106 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.107 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.108 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.109 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.110 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.111 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.112 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.113 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.114 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.115 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.116 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.117 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.118 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.119 "pgrep condor_master | sudo xargs kill"
ssh -t 192.168.5.120 "pgrep condor_master | sudo xargs kill"

pgrep condor_master | echo mcs | sudo -S  xargs kill