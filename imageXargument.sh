#!/bin/bash
obsid=$1
wget "http://nxsa.esac.esa.int/nxsa-sl/servlet/data-action-aio?obsno=${obsid}&level=PPS&name=EPX000OIMAGE8000&extension=FTZ" -O image${obsid}.ftz
done
