#!/usr/bin/env bash

# set -x   # enable debug mode

#########################################
### change backing file path in snapshots
#########################################

VM_IMAGES_DIR_CURRENT="/home/${USER}/mnt/VM/images/" # folder containing qcow2 files, including the (external) snapshots
VM_IMAGES_DIR_OLD="/run/media/${USER}/1TB-M2NVME/01_VM/images/" # old backing file path

# all VM qcow2 files incl. snaphosts are in VM_IMAGES_DIR_CURRENT

# check if path ${VM_IMAGES_DIR_CURRENT} exists:
if [[ ! -d "${VM_IMAGES_DIR_CURRENT}" ]]; then
    echo "Error: Folder '${VM_IMAGES_DIR_CURRENT}' does not exist, exit."
    exit 1
fi

# 1. recreate old paths
# - To change the backing file path in the snapshot files, i had to temporary create symlinks for the old paths, since `qemu-img rebase ...` checks for the old paths.
# - But they do not exist anymore, since my external usb drive is now mounted via fstab in a different path.
sudo mkdir -p "${VM_IMAGES_DIR_OLD}"
sudo chown "${USER}:${USER}" "${VM_IMAGES_DIR_OLD}"

# 2. array for the backing file names, which have to be "created" as symlinks
declare -a backing_files_to_link=()

# 3. collect all backing file names # search all files in folder ${VM_IMAGES_DIR_CURRENT}:
while IFS= read -r -d $'\0' file; do
    backing_file=$(sudo qemu-img info "$file" | grep "backing file:" | sed "s/backing file: //")
    if [ -n "$backing_file" ]; then
        backing_file_name=$(basename "$backing_file")
        if [[ ! " ${backing_files_to_link[*]} " =~ ${backing_file_name} ]]; then
            backing_files_to_link+=("$backing_file_name")
        fi
    fi
done < <(sudo find "${VM_IMAGES_DIR_CURRENT}" -maxdepth 1 -type f -print0)

# 4. temporary create symlinks for all backing file names to the old path
for file in "${backing_files_to_link[@]}"; do
    target="${VM_IMAGES_DIR_CURRENT}${file}"
    link="${VM_IMAGES_DIR_OLD}${file}"

    if sudo test -f "${target}"; then
        echo "Creating symlink: ${link} -> ${target}"
        sudo ln -sf "${target}" "${link}"
    else
        echo "ERROR: Backing file '${target}' does NOT exist at new path!"
        exit 1
    fi
done

# 5. adjust backing file path in snapshot file
while IFS= read -r -d $'\0' file; do
    backing_file=$(sudo qemu-img info "$file" | grep "backing file:" | sed "s/backing file: //")

	# check if backing file exists and if it is not the backing file itself:
    if [ -n "$backing_file" ] && [ "$backing_file" != "$file" ]; then
		# adjust backing file path to the new one (all occurances of VM_IMAGES_DIR_OLD):
        new_backing_file="${backing_file//${VM_IMAGES_DIR_OLD}/${VM_IMAGES_DIR_CURRENT}}"

		# show which file will be adjusted and execute rebase:
        echo "Adjust: ${file} -> Backing File: $(basename "$new_backing_file")"
        if ! sudo qemu-img rebase -F qcow2 -b "${new_backing_file}" "${file}"; then
            echo "Failed to adjust backing file for '${file}'"
            continue
        fi
    else
        echo "Skipping file '${file}': contains no 'backing file' or it is the backing file itself."
    fi
done < <(sudo find "${VM_IMAGES_DIR_CURRENT}" -maxdepth 1 -type f -print0)

# 6. delete temporary created symlinks
for file in "${backing_files_to_link[@]}"; do
    echo "Deleting temporary symlink '${VM_IMAGES_DIR_OLD}${file}'"
    sudo rm -f "${VM_IMAGES_DIR_OLD}${file}"
done
