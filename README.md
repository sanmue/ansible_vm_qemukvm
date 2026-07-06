# ansible_vm_qemukvm

Recreates virtual machines, networks, Snapshots (dumped before via Script "vm_dump2xml.sh" (in playbooks/files/VM)).

## Requirements

- packages for Qemu KVM + user with corresponding authorization
- ansible-core (or ansible)

## Usage

- clone the repo to the home directory of the current user
- cd into the repo folder
- start main playbook `site.yml`: `ansible-playbook site.yml -vv -K`
