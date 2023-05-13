{{/*
Create OIDC External Url
*/}}
{{- define "shp.embedded.keycloak.oidc.externalUrl" }}
{{- if .Values.global.opentdf.common.oidcUrlPath }}
{{- printf "%s/%s" .Values.global.opentdf.common.oidcExternalBaseUrl .Values.global.opentdf.common.oidcUrlPath }}
{{- else }}
{{- default .Values.global.opentdf.common.oidcExternalBaseUrl }}
{{- end }}
{{- end }}

{{/*
Create a white space delimited list of expected certs to be loaded into the truststore
*/}}
{{- define "shp.embedded.keycloak.x509bundle" }}
{{- if .Values.trustedCertSecret }}
{{- $s := (lookup "v1" "Secret" .Release.Namespace .Values.trustedCertSecret) }}
{{- $cert_list:= list }}
{{- range $k := $s.data }}
{{- $cert_list = append $cert_list ( printf "/etc/x509/https/%s" $k ) }}
{{- end }}
{{- printf "%s" ( join " " $cert_list ) }}
{{- else }}
{{- print "" }}
{{- end }}
{{- print "" }}
{{- end }}


{{/*
Create Extra Volumes
*/}}
{{- define "shp.embedded.keycloak.extraVolumes" -}}
- name: custom-entrypoint
  configMap:
    name: {{ .Values.fullnameOverride }}-custom-entrypoint
    defaultMode: 511
{{- if .Values.trustedCertSecret -}}
- name: x509
  secret:
    secretName: {{ .Values.trustedCertSecret }}
{{- end -}}
{{- end }}

{{/*
Create Extra Volumes Mounts
*/}}
{{- define "shp.embedded.keycloak.extraVolumeMounts" -}}
{{- if .Values.trustedCertSecret -}}
- name: x509
  mountPath: /etc/x509/https
{{- end -}}
- name: custom-entrypoint
  mountPath: /opt/keycloak/custom_bin/kc_custom_entrypoint.sh
  subPath: kc_custom_entrypoint.sh
{{- end }}

{{/*
Create Extra Env From
*/}}
{{- define "shp.embedded.keycloak.extraEnvFrom" -}}
- secretRef:
    name: {{ .Values.fullnameOverride }}-extraenv
{{- end }}


{{- define "shp.embedded.keycloak.extraEnv" -}}
- name: CLAIMS_URL
  value: http://entitlement-pdp:3355/entitlements
- name: JAVA_OPTS_APPEND
  value: -Djgroups.dns.query={{ include "keycloak.fullname" . }}-headless
- name: KC_DB
  value: postgres
- name: KC_DB_URL_PORT
  value: "5432"
- name: KC_LOG_LEVEL
  value: INFO
- name: KC_HOSTNAME_STRICT
  value: "false"
- name: KC_HOSTNAME_STRICT_BACKCHANNEL
  value: "false"
- name: KC_HOSTNAME_STRICT_HTTPS
  value: "false"
- name: KC_HOSTNAME_URL
  value: {{ ( include "shp.embedded.keycloak.oidc.externalUrl" . ) | quote }}
- name: KC_HOSTNAME_ADMIN_URL
  value: {{ ( include "shp.embedded.keycloak.oidc.externalUrl" . ) | quote }}
- name: KC_HTTP_ENABLED
  value: "true"
- name: KC_FEATURES
  value: "preview,token-exchange"
- name: X509_CA_BUNDLE
  value: {{ (include "shp.embedded.keycloak.x509bundle" . ) | quote }}
{{- end }}