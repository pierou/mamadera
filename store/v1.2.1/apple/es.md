# App Store Connect — ficha ES (es-ES)

Versión **1.2.1** (build 11). Campos pegados tal cual en App Store Connect →
**Versiones** → español. Límites ASC: nombre 30, subtítulo 30, palabras clave 100,
texto promocional 170, descripción 4 000, Novedades 4 000.

## Nombre de la app — **guardar** `Mamadera Bebé` (13/30)

Aprobado y publicado desde v1.1.0: renombrarlo rompe el historial ASO y vuelve a lanzar
una revisión de unicidad. Cambiar solo por decisión del propietario.

## Subtítulo — dos opciones

| opción | valor | |
|---|---|---|
| **guardar** | `Recién nacido, 100 % privado` | 28/30 |
| candidato | `Tomas, sueño y crecimiento` | 26/30 |

El candidato nombra el tercer eje de medida (peso / estatura / temperatura), ausente de
todos los campos desde v1.1.0. Decisión del propietario — ASC indexa el subtítulo.

## Palabras clave (100)

```
recien-nacido,toma,sueno,panal,seguimiento,privacidad,sin-nube,lactancia,copia-seguridad,crecimiento
```

`crecimiento` se añade a las nueve palabras originales, ninguna eliminada. 100/100 justos
— sin tildes y sin espacios tras las comas (ASC los cuenta).

## Texto promocional (170)

```
Peso, estatura y temperatura cifrados en tu dispositivo y visibles en el historial junto a tomas, sueño y pañales. Ningún dato sale del teléfono.
```

## Descripción (4 000)

```
Registra las tomas, el sueño, los pañales y la salud de tu bebé — todo guardado localmente en tu dispositivo con cifrado. Sin nube, sin telemetría, sin rastreo.

QUÉ PUEDES HACER
• Anotar tomas de pecho y biberón, alimentación sólida en gramos, sueños y cambios de pañal — incluida la textura de las heces
• Registrar peso, estatura y temperatura: los valores se cifran en el dispositivo y se leen en el historial, junto a los demás eventos
• Editar o suprimir una medida directamente desde el historial
• Seguir las rutinas de salud (vitaminas D y K) con sus recordatorios, y crear recordatorios personalizados vinculados a un cuidado
• Mantener recordatorios independientes para cada bebé
• Registrar un evento con su fecha y hora exactas, aunque lo anotes más tarde
• Mantener perfiles separados para cada bebé
• Exportar todos los datos en un único archivo JSON y restaurarlos cuando quieras — 100 % en el dispositivo, sin cuenta ni nube

PRIVACIDAD POR DISEÑO
Mamadera se construyó priorizando la privacidad: las notas sensibles y las medidas se cifran en reposo, la aplicación no pide permisos innecesarios y nada se sube nunca. La única salida de datos es la exportación JSON que inicias tú mismo y el panel de compartir de tu dispositivo. Gratis, de código abierto y bajo licencia MIT.

Ideal para padres que valoran su privacidad — y para bebés que merecen la suya.
```

## Novedades — archivo listo para pegar

[`../release-notes/apple-whatsnew-es.txt`](../release-notes/apple-whatsnew-es.txt) —
generado desde `assets/patch_notes/es.json`, para que la tienda y el diálogo « Novedades »
de la app no digan cosas distintas.

## Notas para el equipo de revisión

- Sin cuenta de demostración: la app funciona desde el primer arranque, con las condiciones
  aceptadas y nada que conectar.
- Para ver las medidas cifradas: Inicio → botón Peso → guardar, y luego la pestaña
  Historial — la fila aparece allí con su unidad.
- « Leche materna » ofrece un conmutador ml / minutos; los demás tipos de alimentación
  tienen unidad fija.
- Sin contenido médico, sin diagnóstico, sin consejo: la app guarda lo que anota el
  padre o la madre. La lactancia es contenido parental, no sexual.
