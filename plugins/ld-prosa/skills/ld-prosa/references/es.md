# Prosa en español

Leer antes de escribir prosa en español: el chat cuando el locale es `es` o
`es-AR`, y los artefactos solo si `LD_PROSA_ARTIFACTS=es`.

Una sola pregunta decide: **¿quién hace qué?** Si el lector tiene que
reconstruir el agente o la acción, la oración se comprimió de más. Los seis casos
de abajo son síntomas de eso, no una lista para memorizar.

El paper que ancla la regla mide inglés (arXiv 2610.29162) y no trae evidencia en
español. Esta derivación es una heurística: cada caso se justifica por la misma
pregunta, no por un corpus.

## Seis formas de esconder al agente en español

1. **Pasiva con `se` sin agente.** "Se decidió posponer el deploy" → "El equipo
   pospuso el deploy". El `se` impersonal está bien cuando el agente no importa o
   no se conoce ("se cayó el build"); cuando sí importa, el lector tiene que
   preguntarlo.
2. **Nominalizaciones y cadenas de `de`.** "la implementación de la validación de
   los datos" → "validamos los datos cuando se cargan". El verbo convertido en
   sustantivo esconde quién valida; la cadena de `de` es el equivalente español
   del compuesto de sustantivos.
3. **Participio sin relativo.** "el valor pasado al loader" → "el valor que el
   loader recibe". El agente sigue ahí, pero hay que desenterrarlo.
4. **Gerundio en cadena.** "El servicio corre en un contenedor, leyendo la config,
   aplicando los cambios y reiniciando" → "El servicio corre en un contenedor: lee
   la config, aplica los cambios y reinicia". La cadena superpone tres acciones y
   el lector no sabe cuál es la principal.
5. **Sujeto elidido ambiguo.** "El cliente envía el pedido y lo valida" → "El
   cliente envía el pedido y el servidor lo valida". El español omite el sujeto
   gratis; con dos terceras personas, el lector no sabe quién valida.
6. **Sujeto inanimado con verbo animado.** "El test se queja" o "la config sabe
   qué hacer" → "el test falla con este mensaje" o "la config define qué hacer".
   En jerga técnica la personificación es idiomática; el tell es el verbo que pide
   un humano para entenderse.

## Falsos positivos

La prosa humana limpia produce estas marcas sin IA. No reescribas por una suelta:
actuá sobre un racimo.

- Voseo, modismos rioplatenses y lunfardo técnico ("de una", "igual", "che").
- Oraciones cortas y fragmentos deliberados: en castellano técnico son ritmo, no
  staccato.
- Un `se` impersonal correcto, una raya, una sola frase enfática.
- Vocabulario formal o académico: el español académico nominaliza de verdad.
- Comillas angulares o curvas, y `commit`/`deploy` mezclados con castellano: es el
  borde duro del harness, no un tell.
- Un `obviamente` o un `básicamente` suelto; el tell es el bloque de muletillas.

## Preservar

- Detalle específico difícil de fabricar: un número, un nombre de archivo, el
  texto exacto de un error.
- Posición defendible y tensión sin resolver: "esto es un footgun y todavía no sé
  por qué".
- Variación de largo entre oraciones.
- Paréntesis y autocorrecciones genuinas.
- Referencias con fecha, slang de una época, chistes internos.
