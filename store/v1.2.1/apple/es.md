# App Store Connect — ficha ES (es-ES)

Versión **1.2.1** (build 11). Cada campo tiene **un solo archivo** en
[`../fields/`](../fields/): ese es el que se pega, nunca una transcripción.

## Nombre — guardar `Mamadera Bebé`

Aprobado y publicado desde v1.1.0. Renombrar rompe el historial ASO y reabre el control de
unicidad de Apple. Decisión del propietario, no una tarea de release.

## Subtítulo — dos opciones

| opción | valor | límite |
|---|---|---|
| **guardar** | `Recién nacido, 100 % privado` | 28/30 |
| candidato | `Tomas, sueño y crecimiento` | 26/30 |

El candidato nombra el tercer eje de medida (peso / estatura / temperatura), ausente de todos
los campos desde v1.1.0. **Ojo:** la app nunca escribe « tomas » ni « pecho » — su botón
(`homeButtonMiam`) dice **Alimento** y el subtipo (`feedingSubtypeNatural`) dice **Leche
Materna**. `make store-check` lo marca como WARN: es una decisión de revisión, no un detalle.

## Campos largos — pegar desde `../fields/`

| campo ASC | archivo | límite | origen |
|---|---|---|---|
| Palabras clave | `../fields/apple-es-keywords.txt` | 100 | editorial — nunca traducido por la máquina |
| Texto promocional | `../fields/apple-es-promo.txt` | 170 | TranslateGemma, alineado |
| Descripción | `../fields/apple-es-description.txt` | 4 000 | TranslateGemma, alineado |
| Novedades | `../release-notes/apple-whatsnew-es.txt` | 4 000 | `assets/patch_notes/es.json` |

El texto español lo hizo TranslateGemma y se alineó término a término contra
`lib/l10n/app_es.arb`; la salida bruta del modelo está en [`../machine/es/`](../machine/es/).
Si una palabra no convence, se acorta **`store/source/en/`** (o se añade una regla de
alineamiento citada en `scripts/build_store_package.py`) y se relanza
`python3 scripts/build_store_package.py --translate`. Editar `../fields/` a mano pierde esa frase
en el siguiente build.

## Notas para el equipo de revisión

- Sin cuenta de demostración: funciona desde el primer arranque, condiciones aceptadas, nada
  que conectar.
- Para ver las medidas cifradas: Inicio → botón **Peso** → Guardar, y luego la pestaña
  **Historial** — la fila aparece con su unidad (`6,18 kg`).
- « Leche Materna » ofrece un conmutador ml / minutos; los demás tipos tienen unidad fija.
- Sin contenido médico, sin diagnóstico, sin consejo: la app guarda lo que anota el padre o la
  madre. La lactancia es contenido parental, no sexual.
