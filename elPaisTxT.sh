#!/bin/bash
# Sencillo script para extraer las noticias del RSS del periódico El País (seguro funciona para otros https://servicios.elpais.com/rss/)
# Y convertir las noticias a archivos de TXT para una consulta más placentera.
# 
# Falta mejorar el formateo del html a Markdown, pero bueno de a poco.
#
# Por: Emilio Ruiz (www.emilio.com.mx)
# Lunes 8 de julio de 2019
#

# Archivos temporales
temp=temp.txt
temp2=temp2.txt
temp3=temp3.txt
temp4=temp4.txt
# URL del xml
xml='https://elpais.com/tag/rss/latinoamerica/a/'
# Obtenemos el xml y lo guardamos temporalmente
wget -q -O - $xml > $temp
# Extraemos las etiquetas xmls <link> y lo que hay en ellas
egrep -o '<link>[^"]+' $temp  | uniq > $temp2
# Quitamos las etiquetas <link> y dejamos solamente las URLS
egrep -o 'https?://[^"]+' $temp2  | uniq > $temp
# De las URLS quitamos variables como ?var=variable para sólo dejar la URL del artículo
grep -Eo  '(http|https)://[a-zA-Z0-9./?=_-]*' $temp > $temp2
# Quitamos las 2 primeras líneas pues sólo enlazan al xml fuente
tail +3 $temp2 > $temp


#
# Función para extraer y formatear cada url del RSS a un archivo de texto en formato MARKDOWN
#
function rss2txt(){

# Descargamos el html desde el url pasado, $1 es el parámetro pasado a través del for con la variable $linea
wget -q -O - $1 > $temp4

# Extraemos el título de la página que está guardada en $TEMP
grep -o 'headline".*h1>\|^--.*' $temp4 | sed "s/headline\">//g" | sed "s#</h1>##g" > $temp2 
tituloPagina=$(cat $temp2)


# Extraemos todo el contenido entre las etiquetas <p></p>
grep -E "^<p>.*</p>$" $temp4 > $temp3
# Concatenamos título y contenido
echo "=======================================================" >> $temp2
cat $temp2 > $temp4
echo "Fuente: "$1 >> $temp4
echo '' >> $temp4
cat $temp3 >> $temp4


# Formateamos para MARKDOWN las etiquetas <p></p> por nueva línea \n
sed "s/<p>/\n/g" $temp4 > $temp2
sed "s#</p># #g" $temp2 > $temp3
sed "s#<em>#**#g" $temp3 > $temp2
sed "s#</em>#**#g" $temp2 > $temp3
# Formateamos las etiquetas Anchor convertimos de <a href="" target="_blank"> lo pasamos a ( y </a> lo pasamos a )
sed "s#<a href=\"#(#g" $temp3 > $temp2
sed "s#target=\"_blank\">#)#g" $temp2 > $temp3
sed "s#\" )#) #g" $temp3 > $temp2
sed "s#</a>##g" $temp2 > $temp3
# Formateamos entidades HTML
sed "s#&Iacute;#Í#g" $temp3 > $temp2
sed "s#&nbsp;# #g" $temp2 > $temp3


# Reemplazar tildes
nombreArchivo=$(echo $tituloPagina | sed "s/ /-/g")
nombreArchivo=$(echo $nombreArchivo | sed "s/á/a/g")
nombreArchivo=$(echo $nombreArchivo | sed "s/é/e/g")
nombreArchivo=$(echo $nombreArchivo | sed "s/í/i/g")
nombreArchivo=$(echo $nombreArchivo | sed "s/ó/o/g")
nombreArchivo=$(echo $nombreArchivo | sed "s/ú/u/g")
nombreArchivo=$(echo $nombreArchivo | sed "s/ñ/n/g")
nombreArchivo=$(echo $nombreArchivo | sed "s/://g")
nombreArchivo=$(echo $nombreArchivo | sed "s/‘//g")

# Reemplazar comas y comillas
# Analizar lo de las comas porque en los títulos a veces aparecen 7,5 millones
nombreArchivo=$(echo $nombreArchivo | sed "s/“//g")
nombreArchivo=$(echo $nombreArchivo | sed "s/”//g")

tituloInicial='el-pais-'

cat $temp2 > $tituloInicial$nombreArchivo.txt
}

while IFS= read -r linea; do
	rss2txt $linea
done < $temp
rm $temp $temp2 $temp3 $temp4

