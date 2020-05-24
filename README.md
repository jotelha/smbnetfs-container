# smbnetfs container

Mounts configured smb shares at `/mnt/smb` within container and runs indefinitely.

Provide smb share credtials to container at `/run/secrets/smbnetfs.auth` in accord with
format described at https://wiki.ubuntuusers.de/Samba_Client_SMBNetFS/#Konfigurationsdateien.