#!/bin/bash

#SBATCH --output="tunnel_log/tunnel_gpux-%J.log"
#SBATCH --job-name="tunnel_gpux"
#SBATCH -p gpu          # Cola para correr el job.  Especificar gpu partition/queue (required)
#SBATCH --gres=gpu:1    # GPUs solicitadas (required), Default=1
#SBATCH -N 1            # Nodos requeridos, Default=1
#SBATCH -n 1            # Cores por nodo requeridos, Default=1
#SBATCH --mem=24G       # Memoria Virtual/RAM
#SBATCH --time 15-00:00:00

# activate environment
module load python/3.11

# find open port
PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')
scontrol update JobId="$SLURM_JOB_ID" Comment="$PORT"

# start sshd server on the available port
echo "Starting sshd on port $PORT"
/usr/sbin/sshd -D -p ${PORT} -f /dev/null -h ${HOME}/.ssh/id_rsa
