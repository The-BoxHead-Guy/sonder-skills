---
name: daily-report
description: >
  Generate a concise daily standup report in Spanish from git commit history.
  Use when the user asks for "daily report", "reporte diario", "today's report",
  "commit report", "what I did today", "gen report", or any request to summarize
  the day's changes. Outputs a compressed team-ready message with 2-3 lines per
  project, not a verbose changelog.
---

# Daily Report — Standup Style

Generate an ultra-compressed daily report in Spanish from today's git commits.
The report communicates what was done in 2-3 lines per project — enough for a
team standup, not a detailed changelog.

## Process

### 1. Gather Commit Data

```bash
git log --oneline --since="YYYY-MM-DD 00:00:00" --until="YYYY-MM-DD 23:59:59" \
  --no-merges --format="%h %s"
```

Use today's date.

### 2. Classify by Project

Group commits by the project directory (e.g., `ssg.nexovial.net`, `scaem.app`, etc.).

### 3. Compress Into Features

Group related commits into logical features. For each feature, write ONE line:
what was done and why it matters. No implementation details, no jargon.

**Distillation rule:** If you need more than 200 characters to explain a feature,
you're including implementation details. Cut to the essence.

### 4. Write the Report

Use this **exact** template:

```
# Reporte de Carlos — <Month in Spanish> <Day>, <Year>

1. ✅ <Project> - <Feature>: <what it does and why it matters>.
2. ✅ <Project> - <Feature>: <what it does and why it matters>.
3. ✅ <Project> - <Feature>: <what it does and why it matters>.

Bugs corregidos: <only include bugs fixed in this report if any based in changes>
- <additional context if needed>.


```

**Rules:**
- Start with "Buen día equipo. Reporto que todo lo planificado para hoy está completo:"
- Each item starts with `N. ✅ <Project> - <Feature>: <one-line explanation>.`
- Max 200 chars per line including prefix — if you need more, compress harder.
- Use plain Spanish, no English jargon unless unavoidable.
- No sub-bullets, no nested lists, no markdown formatting.
- End with "Saludos,\nCarlos"
- If there are bugs fixed or unplanned work, add "Además se ..." paragraph before the sign-off.
- Never include commit hashes, counts, percentages, or technical details.

### 5. Month Names in Spanish (for date context)

enero, febrero, marzo, abril, mayo, junio, julio, agosto, septiembre, octubre, noviembre, diciembre

### 6. Output

Output directly in the chat response. Do NOT write to a file or create a commit.

### Example Output

```
# Reporte de Carlos — Junio 1, 2026

1. ✅ ssg.nexovial.net - Separación de fuentes: Las tres fuentes de reportes ahora se consultan desde una vista unificada.
2. ✅ ssg.nexovial.net - Frecuencias actualizadas: ScrapMap a 15min, audio cada 5min con configuración independiente.
3. ✅ scaem.app - Tablero reactivo: Se refresca cada 30seg y responde a eventos sin esperar el ciclo completo.
4. ✅ ssg.nexovial.net - Prompt de locutor: Ahora procesa múltiples fuentes y comunica de forma más natural.

Bugs corregidos:


- Detecciones de ScrapMap heredaban guiones viejos de otras detecciones eliminadas.
```
