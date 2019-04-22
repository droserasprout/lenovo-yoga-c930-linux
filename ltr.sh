#!/bin/bash
counter=0

until [ $counter -gt 32 ]
do
echo $counter > /sys/kernel/debug/pmc_core/ltr_ignore
echo "LTR ignore for" $counter

rtcwake  -m freeze -s 10

residency=$(cat /sys/devices/system/cpu/cpuidle/low_power_idle_cpu_residency_us)
echo "residency is" $residency

if [ $residency -gt 0 ]; then
        echo "Residency is non zero!"
        break
fi

((counter++))
sleep 2
done
