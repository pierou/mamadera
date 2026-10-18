# Google Play Console — fiche ES (es-ES)

Versión **1.2.1** (build 11 → `versionCode` 11). Límites Play: título 30, descripción
corta 80, descripción completa 4 000, notas de versión 500.

## Título — dos opciones

| opción | valor | |
|---|---|---|
| **guardar** | `Mamadera Seguimiento Bebé` | 25/30 |
| candidato | `Mamadera: Peso y tomas` | 22/30 |

El título es la señal ASO más fuerte de una ficha publicada: se cambia por estrategia,
no por release. Decisión del propietario.

## Descripción corta — dos opciones

| opción | valor | |
|---|---|---|
| **guardar** | `Seguimiento privado de bebé: tomas, sueño, pañales — sin nube ni rastreo` | 72/80 |
| candidato | `Seguimiento privado: tomas, peso, sueño y pañales, sin nube y cifrado` | 69/80 |

El candidato nombra el peso, ausente de los textos desde v1.1.0 mientras la medida está
en producción desde v1.2.0.

## Descripción completa (4 000)

```
Registra las tomas, el sueño, los cambios de pañal, el crecimiento y la rutina de salud de tu recién nacido con privacidad total. Todos los datos se guardan en tu dispositivo — sin nube, sin telemetría, sin rastreo.

Características:
• Registro de tomas de pecho y biberón, y de alimentación sólida en gramos
• Peso, estatura y temperatura — valores cifrados en el dispositivo
• Las medidas aparecen en el historial junto a los demás eventos, y se editan o suprimen desde ahí
• Historial de pañales, con textura de las heces
• Recordatorios de salud (vitamina D/K) — y recordatorios personalizados vinculados a un cuidado
• Recordatorios independientes para cada niño
• Registro retroactivo de un evento con fecha y hora exactas
• Múltiples perfiles de bebé
• Copia de seguridad y restauración en JSON, 100 % en el dispositivo
• Notas cifradas en reposo

Mamadera es de código abierto bajo licencia MIT. Los datos de tu bebé nunca salen de tu teléfono, a menos que inicies tú mismo la exportación JSON y pases el archivo al panel de compartir de tu dispositivo.
```

## Notas de versión (500)

Pegar [`../release-notes/play-es.txt`](../release-notes/play-es.txt) — 419/500.

## Seguridad de los datos (sin cambios si nada cambió de verdad)

«No recopilo, comparto ni permito el acceso a ningún dato» — intacto: v1.2.1 añade una
columna `unit` a la base local, sin red y sin nuevos permisos. Mantener la nota libre:

> Todos los datos de seguimiento del bebé se guardan localmente en el dispositivo en una
> base SQLite; las notas de texto sensibles se cifran campo por campo con AES-256-GCM (el
> archivo de la base no está cifrado). Ningún dato sale del teléfono salvo que inicies tú
> la exportación JSON. No recopilamos, compartimos ni transmitimos datos de usuario.

Categoría: **Salud y forma física** (recomendación — la categoría publicada no está
consignada en `docs/`, verificarla en la Console antes de tocarla). Público objetivo:
padres de recién nacidos, declarado «Niños» — ya en su sitio, sin cambio.
