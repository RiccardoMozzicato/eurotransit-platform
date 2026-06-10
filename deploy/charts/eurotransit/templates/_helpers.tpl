{{/*
Common labels for an EuroTransit service.
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
*/}}
{{- define "eurotransit.selectorLabels" -}}
app.kubernetes.io/name: {{ .svc }}
app.kubernetes.io/part-of: eurotransit
{{- end -}}
