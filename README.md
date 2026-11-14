# Segundo cerebro para tus agentes: plantilla

Una carpeta de archivos Markdown, en un repo **privado** de GitHub, que le cuenta a cualquier agente de IA (Claude Code, Codex, Gemini, un bot) **quién sos, qué hacés y en qué estás trabajando**. Así dejás de explicarle todo desde cero a cada herramienta, y lo que aprende un agente le sirve a los demás.

Esta plantilla trae la estructura vacía, las reglas, dos scripts de seguridad y una guía. **No trae ningún dato personal**: lo llenás vos, con ayuda de Claude Code.

## La idea en tres piezas

1. **Archivos de texto (Markdown).** Los lee cualquier modelo de cualquier empresa.
2. **GitHub privado.** La carpeta vive en la nube, con historial: se ve qué cambió, cuándo y quién, y se puede volver atrás.
3. **Un índice bien hecho.** `AGENTS.md` (igual a `CLAUDE.md`) dice qué hay y dónde, con una sección de preguntas frecuentes. Un agente chico entra por ahí, va directo a la página justa y responde sin leer todo.

No hay base de datos ni servidor. Cada agente lee todo y **solo escribe en `buzon/`**; una rutina semanal revisa lo que dejaron y lo integra.

## Qué trae

| Carpeta o archivo | Para qué |
|---|---|
| `AGENTS.md` y `CLAUDE.md` | Índice raíz, preguntas frecuentes y reglas (son copias exactas) |
| `yo/` | Quién sos, cómo querés que trabaje una IA, y los **límites para agentes** |
| `proyectos/<nombre>/` | Una carpeta autocontenida por proyecto, con su índice |
| `mapa/` | Proyectos, personas y el **inventario de accesos** (dónde está cada clave, sin el valor) |
| `decisiones/` y `aprendizajes/` | Qué se decidió y por qué; lo que ya se aprendió |
| `buzon/` | La bandeja donde los agentes dejan notas |
| `sistema/` | Reglas, revisión semanal y los scripts de auditoría de secretos y de enlaces |

## Cómo se usa

Seguí [GUIA-PASO-A-PASO.md](GUIA-PASO-A-PASO.md). Resumen: copiás esta carpeta, abrís Claude Code ahí, pegás el [prompt corto](PROMPT-PARA-CLAUDE-CODE.md), respondés su entrevista, revisás el plan, auditás y recién ahí lo subís **como privado**.

## ¿Hace falta el modelo más caro?

No. Lo difícil (leer mucho, decidir qué importa, detectar contradicciones) lo hace mejor un modelo potente, pero se puede hacer con uno más económico si le das más tiempo y le pedís que **reparta la lectura en subagentes** y que **te pregunte antes de decidir**. Dos recomendaciones:

- Si tenés acceso a un modelo potente, usalo **una sola vez** para armar el cerebro, con razonamiento medio o alto. Para mantenerlo, alcanza uno barato.
- Con un modelo económico, hacelo por tandas (un proyecto por vez) y revisá más de cerca el resultado.

> Honestidad: esta plantilla se armó a partir de un cerebro real construido con un modelo potente. **Todavía no se probó de punta a punta con un modelo económico.** Si lo probás, anotá cómo te fue en `aprendizajes/`.

## Seguridad: leelo antes de subir nada

- Subilo **siempre como repo privado** y activá la verificación en dos pasos en tu cuenta de GitHub.
- **Nunca pongas el valor de una clave, contraseña o token.** El inventario de accesos dice *dónde* está, no *cuál* es. Git no olvida: lo que se sube queda en el historial aunque lo borres después.
- Cada agente que lea el repo deja una copia en otra máquina. Dale acceso de **solo lectura** y no le compartas tu token principal.
- Corré `sistema/auditar-secretos.ps1` antes de cada subida. Es una red de seguridad, no una garantía: revisá a mano lo que subís.

## Créditos

La idea de un segundo cerebro en Markdown leído por todos tus agentes, con un índice y un buzón, la mostró Benjamín Cordero en su video "Fable 5.2 ahora es el segundo cerebro de TODOS mis agentes". Se apoya en el patrón "LLM Wiki" de Andrej Karpathy: en vez de buscar en documentos cada vez, el agente construye y mantiene una wiki de archivos que se acumula. Esta plantilla es una adaptación independiente, sin código ni contenido copiado de ninguno de los dos.
