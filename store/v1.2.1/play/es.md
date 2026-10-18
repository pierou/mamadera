# Google Play Console — ficha ES (es-ES)

Versión **1.2.1** (`versionCode` 11). Play publica **por idioma**: cada localización tiene su
título, su descripción corta, su descripción completa y **sus notas de versión**.

## Título — dos opciones

| opción | valor | límite |
|---|---|---|
| **guardar** | `Mamadera Seguimiento Bebé` | 25/30 |
| candidato | `Mamadera: Peso y tomas` | 22/30 |

El título es la señal ASO más fuerte de una ficha publicada: se cambia por estrategia, no por
release. El candidato dice « tomas » — palabra que la app nunca muestra: su botón
(`homeButtonMiam`) dice **Alimento**. `make store-check` lo avisa.

## Pegar desde `fields/`

| campo Play | archivo | límite | origen |
|---|---|---|---|
| Descripción corta | `fields/play-es-short.txt` | 80 | TranslateGemma, alineado |
| Descripción completa | `fields/play-es-description.txt` | 4 000 | TranslateGemma, alineado |
| Notas de versión | `../release-notes/play-es.txt` | 500 | TranslateGemma, alineado |

Salida bruta del modelo en [`../machine/es/`](../machine/es/). Si una descripción pasa de
500, se acorta **`store/source/en/play-release-notes.txt`** y se relanza
`python3 scripts/build_store_package.py --translate`; no se recorta el español a mano.

## Seguridad de los datos — sin cambios en 1.2.1

« No recopilo, comparto ni permito el acceso a ningún dato ». 1.2.1 añade una columna `unit`
a la base local: sin red y sin nuevos permisos, no hay nada nuevo que declarar. Nota libre a
mantener:

> Todos los datos de seguimiento del bebé se guardan localmente en el dispositivo en una base
> SQLite; las notas de texto sensibles se cifran campo por campo con AES-256-GCM (el archivo
> de la base no está cifrado). Ningún dato sale del teléfono salvo que inicies tú la
> exportación JSON. No recopilamos, compartimos ni transmitimos datos de usuario.

Categoría: **Salud y forma física** (recomendación — la publicada no está consignada en
`docs/`, verificarla en la Console). Público: padres de recién nacidos, declarado « Niños ».

## Notas de versión — dónde van

En la **release** (caja « Notas de la versión », por idioma), no solo en la ficha: es lo que
el padre lee al actualizar. `../release-notes/play-es.txt`, 367/500.
