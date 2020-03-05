#!/bin/bash
# <Guión para respaldar bases de datos en MySQL Community Server 8.0.19>
# Copyright (C) <2020>  <Jimmy Olano 🇻🇪>
#
# Este programa es software libre: puedes redistribuirlo y/o modificarlo
# bajo los términos de la Licencia Pública General de GNU, publicada por
# la Fundación de Software Libre, ya sea la versión 3 de la Licencia, o
# (a su elección) cualquier versión posterior.
#
# Este programa se distribuye con la esperanza de que sea útil,
# pero SIN NINGUNA GARANTÍA; sin siquiera la garantía implícita de
# MERCADEO o APTITUD PARA UN PROPÓSITO PARTICULAR.  Vea el
# GNU General Public License para más detalles.
#
# Debería usted haber recibido una copia de la Licencia Pública General de GNU
# junto con este programa. Si no es así, vaya a <https://www.gnu.org/licenses/>.
#
# English language:
#    <Script for backing up databases MySQL Community Server 8.0.19>
#    Copyright (C) <2020>  <Jimmy Olano 🇻🇪>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ¿Qué hace este guión?
# Crea una carpeta maestra de respaldo en el "home" del usuario y crea subcarpetas
# para el tipo de base de datos y luego una carpeta para cada mes.
# De la lista de base de datos a (respaldar y/o ignorar) extrae la información
# con MySQLDump y la comprime con gzip de manera "amigable" para rsync. 
# Última actualización de este guión: jueves 5 de marzo de 2020.

# Inicio de variables personalizables
	# Credenciales: recomendado usar "auth_socket" para conectar SIN CONTRASEÑA 
	# (en inglés: https://www.percona.com/blog/2019/11/01/use-mysql-without-a-password/ )
	ksUsuario="nombre_del_usuario(a)"
	ksContrasena="contraseña"
	# Servidor local por defecto ("auth_socket" solo usa "localhost");
	# sino usar dirección IP o URL.
	ksAnfitrionRemoto="localhost"
	# Si el servidor es remoto ASEGURAR el envío de contraseña
	# (en inglés: https://dev.mysql.com/doc/refman/8.0/en/password-security-user.html )

	# Carpeta principal con los respaldos.
	ksDestino="$HOME/Respaldos"
	# Carpeta secundaria, una para cada tipo de base de datos,
	# una carpeta para cada mes.
	ksSeparador="_"
	ksDestinoAnuarioMes="$ksDestino/Respaldos$ksSeparador""MySQL/$(date +"%Y-%m%b")"
	# Lista de base de datos a respaldar, por defecto (valor="") TODAS las que el 
	# usuario tenga derechos; de lo contrario separar nombres con un espacio.
	ksBD_a_respaldar=""
	# Lista de base de datos a ignorar separadas por un simple espacio
	ksBD_a_ignorar="information_schema prueba pruebas"
# Fin de variables personalizables

# Variables automáticas «no modificar».
	ksAnfitrionLocal="$(hostname)"
	ksJustoAhora="$(date +"%Y-%m%b-%d%a@%H%M")"
	ksNom_Archivo_Resp=""

# Variables automáticas «SE PUEDEN AJUSTAR, DE SER NECESARIO».
	ksMYSQL="$(which mysql)"
	ksMYSQLDUMP="$(which mysqldump)"
	ksGZIP="$(which gzip)"

# Crea los directorios necesarios
	[ ! -d $ksDestinoAnuarioMes ] && mkdir -p $ksDestinoAnuarioMes || :

# Comienza respaldo, primero lista las bases de datos disponibles para el usuario
	ksLista_BDs="$( $ksMYSQL -u $ksUsuario -p$ksContrasena -h $ksAnfitrionRemoto -Bse 'SHOW DATABASES;')"

	for base_dato in $ksLista_BDs
		do
			# Revisa la lista de bases de datos a respaldar.
			if [ "$ksBD_a_respaldar" == "" ]; then
				ksRespaldar=true
			else
				ksRespaldar=false
				for i in $ksBD_a_respaldar
					do
						if [ "$base_dato" == "$i" ]; then
							ksRespaldar=true
						fi
					done
			fi
			
			# Pero si está en la lista de ignorar, pues pasa a la siguiente BD.
			if [ $ksRespaldar == true ] ; then
				if [ "$ksBD_a_ignorar" == "" ]; then
					ksRespaldar=true
				else
					ksRespaldar=true
					for i in $ksBD_a_ignorar
						do
							if [ "$base_dato" == "$i" ]; then
								ksRespaldar=false
							fi
						done
				fi
			fi		  
			if [ $ksRespaldar == true ] ; then
				Nom_Archivo_Resp=$ksDestinoAnuarioMes"/Respaldo"$ksSeparador"MySQL"
				Nom_Archivo_Resp=$Nom_Archivo_Resp$ksSeparador$ksJustoAhora$ksSeparador
				Nom_Archivo_Resp=$Nom_Archivo_Resp$ksAnfitrionRemoto$ksSeparador$base_dato".gz"
				# Respaldo en sí
				ksMYSQLDUMP_ARG=" -u $ksUsuario "
				if [ "$ksContrasena" != "" ]; then 
					ksMYSQLDUMP_ARG=$ksMYSQLDUMP_ARG" -p$ksContrasena"
				fi
				ksMYSQLDUMP_ARG=$ksMYSQLDUMP_ARG" $base_dato -h $ksAnfitrionRemoto --column-statistics=0"
				#echo "$ksMYSQLDUMP $ksMYSQLDUMP_ARG | $ksGZIP -9 --rsyncable > $Nom_Archivo_Resp"
				$ksMYSQLDUMP $ksMYSQLDUMP_ARG | $ksGZIP -9 --rsyncable > $Nom_Archivo_Resp
			fi
		done
		
# Fin del guión, ¡que tengáis un feliz día!
