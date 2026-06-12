# OpenShift Quay GitOps

Despliegue de **Red Hat Quay 3.16** en OpenShift siguiendo las mejores prácticas de GitOps con Argo CD y Kustomize.

## Estructura del proyecto

```
├── argocd/
│   └── applications/
│       ├── openshift-gitops.yaml     # Application: operador GitOps (self-managed)
│       └── quay-registry.yaml        # Application: Quay Registry
├── clusters/
│   ├── openshift-gitops/
│   │   └── base/                     # Operador OpenShift GitOps
│   │       ├── kustomization.yaml
│   │       └── subscription.yaml
│   └── quay/
│       ├── base/                     # Manifiestos base (reutilizables)
│       │   ├── kustomization.yaml
│       │   ├── namespace.yaml
│       │   ├── operator-group.yaml
│       │   ├── subscription.yaml
│       │   └── quay-registry.yaml
│       └── overlays/
│           └── production/           # Overlay de producción
│               ├── kustomization.yaml
│               ├── config-bundle-secret.yaml
│               └── quay-registry-patch.yaml
└── scripts/
    └── bootstrap.sh                  # Script de bootstrap automatizado
```

## Requisitos previos

- OpenShift Container Platform 4.14+
- CLI `oc` autenticado contra el clúster
- Acceso al catálogo `redhat-operators`
- (Opcional) OpenShift Data Foundation si se usa `objectstorage: managed: true`

## Bootstrap

El script `scripts/bootstrap.sh` automatiza todo el proceso:

1. Instala el operador OpenShift GitOps
2. Aprueba el InstallPlan y espera a que ArgoCD esté disponible
3. Aplica todas las Applications de ArgoCD

### Despliegue rápido

1. **Fork/clone** este repositorio
2. **Editar** los marcadores de posición (`<...>`) en:
   - `clusters/quay/overlays/production/config-bundle-secret.yaml`
3. **Ejecutar el bootstrap**:
   ```bash
   ./scripts/bootstrap.sh
   ```

### Despliegue manual (paso a paso)

1. **Instalar OpenShift GitOps**:
   ```bash
   oc apply -k clusters/openshift-gitops/base
   ```
2. **Aprobar** el InstallPlan del operador GitOps:
   ```bash
   oc -n openshift-operators get installplan
   oc -n openshift-operators patch installplan <INSTALL_PLAN_NAME> \
     --type merge --patch '{"spec":{"approved":true}}'
   ```
3. **Esperar** a que ArgoCD esté disponible:
   ```bash
   oc wait --for=condition=Available deployment/openshift-gitops-server \
     -n openshift-gitops --timeout=300s
   ```
4. **Aplicar** las Applications de ArgoCD:
   ```bash
   oc apply -f argocd/applications/
   ```
5. **Aprobar** el InstallPlan del operador Quay:
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
