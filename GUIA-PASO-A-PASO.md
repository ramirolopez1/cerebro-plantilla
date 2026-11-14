# Guía paso a paso

Tiempo estimado: de 1 a 3 horas la primera vez, casi todo esperando que la IA lea y escriba.

## Antes de empezar

- **Claude Code** instalado y con sesión iniciada (o la herramienta de agentes que uses).
- **Git** y una cuenta de **GitHub**, con la **verificación en dos pasos activada**.
- **GitHub CLI** (`gh`) instalado y con sesión: `gh auth login`.
- **PowerShell** (viene con Windows; en Mac o Linux, instalá `pwsh`). Los scripts de seguridad lo usan.
- Elegí qué **modelo** usar. Ver el README: uno potente una sola vez, o uno barato por tandas.

## 1. Copiá la plantilla

En GitHub, tocá **Use this template** (si está publicada como plantilla), o copiá esta carpeta a una carpeta nueva, **fuera de tus otros proyectos**, por ejemplo `Documentos\mi-cerebro`. Ahí vas a trabajar.

## 2. Activá los controles locales

Dentro de la carpeta nueva:

```
git init
git config core.hooksPath sistema/hooks
```

Esto activa el control que frena los commits de agentes que toquen algo fuera de `buzon/`.

## 3. Elegí tu criterio de privacidad

Abrí `yo/limites-para-agentes.md` y marcá **una** opción: solo roles, o nombres con roles. Es tu decisión y la leen todos los agentes.

## 4. Pegale el prompt a Claude Code

Abrí Claude Code **dentro de la carpeta nueva**, elegí el modelo y pegá el [prompt corto](PROMPT-PARA-CLAUDE-CODE.md), con tus datos en los corchetes. Si Claude Code solo ve la carpeta actual, agregá tus carpetas de notas con `/add-dir`.

## 5. Respondé la entrevista y revisá el plan

La IA va a leer tus fuentes (en solo lectura), después te hará 10 a 12 preguntas y te mostrará el árbol de páginas que piensa crear. **Revisá ese plan**: ahí se decide qué entra. Si ves una carpeta con datos de terceros o algo que no querés, pedí que la saque.

## 6. Auditá antes de subir

Cuando termine de escribir, corré vos mismo:

```
powershell -NoProfile -File sistema\auditar-secretos.ps1
powershell -NoProfile -File sistema\verificar-enlaces.ps1
```

El resultado tiene que ser **LIMPIO** y **todo bien**. Abrí además dos o tres páginas al azar y leelas: la auditoría busca patrones, no entiende el contexto.

## 7. Subilo como privado y comprobalo

```
git add -A
git commit -m "[curacion] Primer armado del segundo cerebro"
gh repo create mi-cerebro --private --source . --push
```

Verificá que **quedó privado de verdad**: abrí `https://github.com/TU-USUARIO/mi-cerebro` en una ventana de incógnito o en otro navegador. Tiene que decir "404", no mostrar el repo.

## 8. Conectá a tus agentes

- Cada agente necesita **acceso de lectura** al repo. Usá una llave de solo lectura (*deploy key*) o un token con permisos mínimos para ese repo. **Nunca** compartas tu token principal.
- Probá con una pregunta real, por ejemplo: "dejá una nota en el buzón que diga que me gustan las manzanas rojas", y comprobá que aparece en `buzon/`.

## 9. Programá el mantenimiento semanal

Creá una tarea programada de Claude (una vez por semana, con un modelo barato) que haga lo que dice `sistema/rutina-semanal.md`: integrar el buzón y correr la revisión de salud. Que **no suba nada** si la auditoría encuentra algo.

## Qué hacer si algo sale mal

- **La auditoría encontró algo:** no subas. Sacá el dato, volvé a correrla y recién ahí commiteá.
- **Subiste una clave por error:** cambiala **ya** en el servicio que corresponda. Borrar el archivo no alcanza, porque queda en el historial.
- **Un agente escribió fuera de `buzon/`:** revertí ese commit (`git revert`) y revisá sus permisos.
- **No funcionó con tu modelo:** anotalo en `aprendizajes/` con qué modelo, qué falló y cómo lo resolviste.
