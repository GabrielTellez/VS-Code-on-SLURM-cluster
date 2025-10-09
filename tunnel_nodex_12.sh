#!/bin/bash

#SBATCH --output="tunnel_log/tunnel_node-%J.log"
#SBATCH --job-name="tunnel_nodex"
#SBATCH -p short          # Cola para correr el job.  Especificar gpu partition/queue (required)
#SBATCH --mem=64G       # Memoria Virtual/RAM, Default=2048
#SBATCH --cpus-per-task=12
#SBATCH --time 2-00:00:00

# activate environment
module load python/3.11

# find open port
PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
scontrol update JobId="$SLURM_JOB_ID" Comment="$PORT"

# start sshd server on the available port
echo "Starting sshd on port $PORT"
/usr/sbin/sshd -D -p ${PORT} -f /dev/null -h ${HOME}/.ssh/id_rsa
