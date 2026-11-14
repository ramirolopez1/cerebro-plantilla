# Inventario de accesos

**Nunca el valor.** Para cada cosa: qué es, qué abre, **dónde está guardada exactamente** y cómo se renueva. Sirve para el día que te olvidás dónde dejaste algo.

| Qué es | Qué abre | Dónde está guardada | Cómo se renueva |
|---|---|---|---|
| Clave SSH del servidor | Entrar al servidor | Carpeta `.ssh` del usuario y copia en el gestor de contraseñas, entrada "Servidor SSH" | Generar una nueva y reemplazarla en el servidor |
| Token de GitHub | Subir y leer repos | Gestor de credenciales de `gh` | `gh auth refresh` |
| API key de [servicio] | [lo que abre] | Variable de usuario `NOMBRE_DE_LA_VARIABLE` | Desde el panel del servicio |

Las IP de la red local pueden ir con su número si lo decidiste en [límites para agentes](../yo/limites-para-agentes.md). Las IP públicas, no.
