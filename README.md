# OpenShift Quay GitOps

Despliegue de **Red Hat Quay 3.16** en OpenShift siguiendo las mejores prácticas de GitOps con Argo CD y Kustomize.

## Estructura del proyecto

```
├── argocd/
│   └── applications/
│       └── quay-registry.yaml       # Application de Argo CD
└── clusters/
    └── quay/
        ├── base/                     # Manifiestos base (reutilizables)
        │   ├── kustomization.yaml
        │   ├── namespace.yaml
        │   ├── operator-group.yaml
        │   ├── subscription.yaml
        │   └── quay-registry.yaml
        └── overlays/
            └── production/           # Overlay de producción
                ├── kustomization.yaml
                ├── config-bundle-secret.yaml
                └── quay-registry-patch.yaml
```

## Requisitos previos

- OpenShift Container Platform 4.14+
- Argo CD / OpenShift GitOps Operator instalado
- Acceso al catálogo `redhat-operators`
- (Opcional) OpenShift Data Foundation si se usa `objectstorage: managed: true`

## Despliegue rápido

1. **Fork/clone** este repositorio
2. **Editar** los marcadores de posición (`<...>`) en:
   - `clusters/quay/overlays/production/config-bundle-secret.yaml`
3. **Aplicar** la Application de Argo CD:
   ```bash
   oc apply -f argocd/applications/quay-registry.yaml
   ```
4. **Aprobar** el InstallPlan generado (ya que `installPlanApproval: Manual`):
   ```bash
   oc -n quay-enterprise get installplan
   oc -n quay-enterprise patch installplan <INSTALL_PLAN_NAME> \
     --type merge --patch '{"spec":{"approved":true}}'
   ```

## Producción

Para un entorno productivo, se recomienda:

| Componente | Recomendación |
|---|---|
| `postgres` | `managed: false` + Amazon RDS / Azure DB / Crunchy Operator |
| `objectstorage` | `managed: false` + AWS S3 / GCS / Azure Blob |
| `clairpostgres` | `managed: false` + instancia PostgreSQL dedicada |
| Secrets | Sealed Secrets / External Secrets Operator / HashiCorp Vault |
| TLS | Cert-manager con Let's Encrypt o certificados corporativos |

## Referencias

- [Red Hat Quay 3.16 - Deploying on OpenShift](https://docs.redhat.com/en/documentation/red_hat_quay/3.16/html-single/deploying_the_red_hat_quay_operator_on_openshift_container_platform/index)
- [Red Hat Quay 3.16 - Configuration Guide](https://docs.redhat.com/en/documentation/red_hat_quay/3/html-single/configure_red_hat_quay/index)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
