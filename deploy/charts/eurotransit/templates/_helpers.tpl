{{- /*
Helm template helpers -> named snippets reused by every template in this chart.

Syntax crash-course:
- "define <name>" declares a named template; it renders nothing by itself
- Templates call it with "include <name> CONTEXT": "include" returns a STRING (unlike the builtin "template", which prints directly), so it can be piped to functions
- CONTEXT is whatever the caller passes. Our templates iterate services with "range $name, $svc := .Values.services", and inside a "range" the dot (.) is rebound -> so callers pass an explicit context built with "dict <svc> $name <root> $" ($ is always the chart root, surviving the rebinding)
- "nindent N" indents every line by N spaces (YAML is whitespace-sensitive, so the caller decides the depth: e.g. "| nindent 4" under "labels:")
*/ -}}

{{/*
Common labels for an EuroTransit service
Usage: {{ include "eurotransit.labels" (dict "svc" $name "root" $) }}
*/}}
{{- define "eurotransit.labels" -}}
app.kubernetes.io/name: {{ .svc }}
app.kubernetes.io/part-of: eurotransit
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/managed-by: {{ .root.Release.Service }}
{{- end -}}

{{/*
Selector labels (stable across versions; used by Service/Deployment selectors).
Kept SEPARATE from the full label set on purpose: selectors are immutable after creation, so they must never include mutable labels (release, version, ...)
*/}}
{{- define "eurotransit.selectorLabels" -}}
app.kubernetes.io/name: {{ .svc }}
app.kubernetes.io/part-of: eurotransit
{{- end -}}
