# Connect VS Code to a SLURM cluster

This document explains how to connect Visual Studio Code on your local machine to a generic SLURM-based cluster for interactive/remote development. It references three example files included in this folder: `config`, `tunnel_gpux.sh`, and `tunnel_nodex_12.sh`.

## Prerequisites

- Latest VS Code on your local machine.
- The "Remote Development" extension pack installed in VS Code (ms-vscode-remote.vscode-remote-extensionpack).
- An account on your SLURM cluster and SSH access.
- A local SSH key (~/.ssh/id_rsa and ~/.ssh/id_rsa.pub) or generate one with `ssh-keygen -t rsa`.

## 1) One-time setup (local ~/.ssh/config and cluster key install)

1. Edit your local SSH config file (`~/.ssh/config`) and add entries similar to the examples below.

Use the provided `config` file as a template for your `~/.ssh/config`. Replace `your_cluster_login_node` and `your_username_here` with values for your cluster. The `config` file defines two SSH targets: `gpux` and `nodex`.

2. Generate an SSH key locally if you don't already have one:

```pwsh
ssh-keygen -t rsa
```

3. Copy your local public key to the cluster (replace the login alias if you renamed it):

```pwsh
ssh-copy-id your_cluster_login_node
```

(This installs your public key on the cluster so passwordless auth works for the ProxyCommand connections.)

## 2) Create the SBATCH job script on the cluster

Use the provided SBATCH scripts as templates and adapt them to your cluster. Two examples are included:

- `tunnel_gpux.sh` — SBATCH script for GPU reservations.
- `tunnel_nodex_12.sh` — SBATCH script for a multi-core node.

Copy the script you want to use to your home directory on the cluster and submit it with `sbatch`.

## 3) Per-connection steps (every time you want to connect)

1. From your local terminal, SSH to the cluster login host and submit the appropriate tunnel job. Example (adjust names):

```pwsh
ssh your_cluster_login_node
sbatch ~/tunnel_gpux.sh   # for GPU 
# or
sbatch ~/tunnel_nodex_12.sh  # for multi-core node
```

2. Confirm your job is running (the job must be in state R). Example (on the cluster):

```bash
squeue -u <username>
```

Sample output will show a JOBID, partition, NAME (tunnel), USER, ST (R), and NODELIST. The job's node appears in NODELIST.

3. In VS Code, open the Remote Explorer ("Connect to Host - Remote SSH") and choose the SSH target that matches the script you submitted: `gpux` for `tunnel_gpux.sh`, or `nodex` for `tunnel_nodex_12.sh`. VS Code will use the ProxyCommand defined in `config` to connect to the job's compute node and forwarded sshd port.

4. Open your project files and work remotely. When finished, cancel the job on the cluster (or it will end when walltime expires):

```bash
scancel <JOBID>
```

## Tips and notes

- Make sure the SBATCH job reaches the `R` (running) state. The ProxyCommand uses `squeue` output to locate the node and ssh port.
- If you change your SSH private key path or names, update the `sshd` command and `-h` option in the sbatch script accordingly.
- The `ControlMaster`/`ControlPath` lines speed up multiple SSH connections from the same client; keep them unless you know why to change them.
If VS Code fails to connect, try testing the ProxyCommand manually to see what host:port it outputs:

```pwsh
ssh your_cluster_login_node "squeue --me --name=tunnel --states=R -h -O NodeList,Comment"
```

You'll see something like: `node-01,12345` where the second field is the port number recorded by the sbatch script.

## Troubleshooting

- If `ssh-copy-id` fails, you can manually append your `~/.ssh/id_rsa.pub` contents to `~/.ssh/authorized_keys` on the cluster (make sure permissions are correct: `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/authorized_keys`).
- Ensure `sshd` exists on the compute nodes and that the path `/usr/sbin/sshd` is correct for your cluster.
- If the job never enters `R`, check partition and resource requests in the SBATCH script.


