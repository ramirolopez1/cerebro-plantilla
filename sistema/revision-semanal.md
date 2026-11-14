# Revisión de salud semanal

Un agente recorre el cerebro y deja un informe. No arregla decisiones del dueño: las anota.

## Qué revisa

1. **Contradicciones** entre páginas (por ejemplo, el estado de un proyecto dicho distinto en dos lugares).
2. **Páginas viejas o sin fecha** que habría que volver a mirar contra la fuente.
3. **Enlaces rotos y páginas huérfanas** (`verificar-enlaces.ps1`).
4. **Datos que no deberían estar** (`auditar-secretos.ps1`) y cualquier valor de una credencial.
5. **Proyectos sin índice** o que enlazan fuera de su carpeta.
6. **Síntesis pendientes** en el buzón que nadie promovió.

## Qué deja

Un informe en `sistema/informes/AAAA-MM-DD.md` con: qué encontró, qué corrigió (solo lo mecánico) y qué necesita decisión del dueño. Si algo exige decisión, una nota en el [buzón](../buzon/README.md).

Se dispara desde la [rutina semanal](rutina-semanal.md).
