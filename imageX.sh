#!/bin/bash
obsids=( 0602420201 0602420301 0602420401 )
for obsid in ${obsids[@]} ; do
wget "http://nxsa.esac.esa.int/nxsa-sl/servlet/data-action-aio?obsno=${obsid}&level=PPS&name=EPX000OIMAGE8000&extension=FTZ" -O image${obsid}.ftz
done
