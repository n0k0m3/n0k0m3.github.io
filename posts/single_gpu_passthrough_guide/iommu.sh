#!/bin/bash
shopt -s nullglob

for iommu_group in $(find /sys/kernel/iommu_groups/ -maxdepth 1 -mindepth 1 -type d);do
    echo "IOMMU group $(basename "$iommu_group")";
    for device in $(\ls -1 "$iommu_group"/devices/); do
        if ! [[ -e "$iommu_group"/devices/"$device"/reset ]]; then
            echo -n "[NORES]";
        fi;
        echo -n $'\t';lspci -nns "$device";
    done;
    echo;
done;
