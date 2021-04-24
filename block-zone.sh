#! /bin/bash

# Autor: amperis - 2021
# Denegacion de Zonas de Internet a atraves de IPTABLES.
# Utilizar este scrip junto con las reglas generales de su IPTABLES
# Requisttos: iptables, wget, ipset
# Ejecutar como: sudo block-zone.sh
# Consultar zonas en : https://www.ipdeny.com/ipblocks/

# Lista de zonas a bloquear
COUNTRY=( "as" "cn" "af" "ru" "eg" "in" "kr" "hk" "jp" "pl" "ua")

# Carpeta temporal para almacenar los .zone descargados
ARCHIVOS_ZONA=/etc/blockbygeo/zones

echo "block-zone.sh v0.1 - by amperis"

if [ ! -e $ARCHIVOS_ZONA/ ]; then
   echo "Creado carpeta para las zonas..,"
    mkdir -p $ARCHIVOS_ZONA
fi

echo "Parando servicios de iptables"
service iptables stop

echo "Borrando todos los ipset..."
ipset destroy

echo "Arrancando servicios iptables..."
service iptables start

echo "Borrando archivos de zona..."
rm -f $ARCHIVOS_ZONA/*

for x in ${COUNTRY[@]}; do
   echo "Descargando zona: $x"
   wget --quiet -P . http://www.ipdeny.com/ipblocks/data/countries/"$x".zone -O $ARCHIVOS_ZONA/"$x".zone

   echo "Añadiendo IP de la zona $x al ipset..."
   ipset -N $x hash:net
   zonefile=( $(cat $ARCHIVOS_ZONA/"$x".zone) )
   for i in "${zonefile[@]}"; do
      echo -n "."
      ipset -A "$x" "$i" -exist
   done
   echo ""
   echo "Aplicando a iptables la nueva zona $x..."
   iptables -I INPUT 1 -m set --match-set $x src -j DROP
   echo "===== Zona $x cargada ====="
done

