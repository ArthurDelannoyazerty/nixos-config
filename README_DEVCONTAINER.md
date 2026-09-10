# Devcontainer

Workspace Nix non-root (`arthur`, UID/GID 999) pour VS Code + Kubernetes.

Le `$HOME` et `/nix` sont persistants. Les outils ponctuels peuvent donc être installés sans reconstruire l'image.

```bash
# Temporaire
nix shell nixpkgs#just

# Persistant
nix profile install nixpkgs#just
```

## Files

```text
hosts/devcontainer/
├── default.nix
├── README_DEVCONTAINER.md
├── scripts/
│   ├── entrypoint.sh
│   ├── seed-nix.sh
│   ├── sync-dotfiles.sh
│   ├── install-extensions.sh
│   ├── doctor.sh
│   └── with-gpu-libs.sh
└── k8s/
    ├── statefulset.yaml
    └── service.yaml
```

`default.nix` construit l'image. `seed-nix.sh` initialise le `/nix` persistant. `entrypoint.sh` prépare le workspace et synchronise les dotfiles. `doctor.sh` vérifie rapidement l'environnement.

Les dotfiles sont automatiquement clonés/mis à jour depuis:

```text
https://github.com/ArthurDelannoyazerty/dotfiles
```

Ils vivent dans `~/dotfiles`; ils ne sont pas inclus dans l'image.

Après la première connexion VS Code:

```bash
devcontainer-install-extensions
```

La commande utilise `~/dotfiles/code/extensions.txt` et peut être relancée sans problème.

Si `setup.sh` du repo dotfiles change ses liens:

```bash
bash ~/dotfiles/setup.sh
```

Diagnostic:

```bash
devcontainer-doctor
```

> Anyone entering the pod as `arthur` has access to everything readable/writable by `arthur`. The Kubernetes security context protects the cluster, not the contents of Arthur's home directory.

<details>
<summary><code>k8s/service.yaml</code> — headless Service used by the StatefulSet</summary>

```yaml
apiVersion: v1
kind: Service
metadata:
  name: devcontainer-arthur
  namespace: dev-backend
spec:
  clusterIP: None
  selector:
    app.kubernetes.io/name: devcontainer-arthur
  ports:
    - name: dev-http
      port: 8000
      targetPort: 8000
```

This does not expose SSH or the container outside the cluster. It mainly provides the governing Service required by the StatefulSet.

</details>

<details>
<summary><code>k8s/statefulset.yaml</code> — persistent non-root development workspace</summary>

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: devcontainer-arthur
  namespace: dev-backend

spec:
  serviceName: devcontainer-arthur
  replicas: 1
  revisionHistoryLimit: 3

  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain
    whenScaled: Retain

  selector:
    matchLabels:
      app.kubernetes.io/name: devcontainer-arthur

  template:
    metadata:
      labels:
        app.kubernetes.io/name: devcontainer-arthur

    spec:
      automountServiceAccountToken: false
      runtimeClassName: nvidia
      terminationGracePeriodSeconds: 30

      securityContext:
        runAsNonRoot: true
        runAsUser: 999
        runAsGroup: 999
        fsGroup: 999
        fsGroupChangePolicy: OnRootMismatch
        seccompProfile:
          type: RuntimeDefault

      tolerations:
        - effect: NoSchedule
          key: project
          operator: Equal
          value: ia
        - effect: NoSchedule
          key: gpu
          operator: Equal
          value: h200

      initContainers:
        - name: seed-nix
          image: ghcr.io/arthurdelannoyazerty/nix-devcontainer:REPLACE_WITH_GIT_SHA
          imagePullPolicy: IfNotPresent
          command:
            - /bin/devcontainer-seed-nix
          args:
            - /persist

          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL

          volumeMounts:
            - name: nix
              mountPath: /persist
            - name: tmp
              mountPath: /tmp

      containers:
        - name: workspace
          image: ghcr.io/arthurdelannoyazerty/nix-devcontainer:REPLACE_WITH_GIT_SHA
          imagePullPolicy: IfNotPresent

          env:
            - name: NVIDIA_DRIVER_CAPABILITIES
              value: compute,utility

          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL

          resources:
            limits:
              nvidia.com/gpu: 1

          volumeMounts:
            - name: home
              mountPath: /home/arthur
            - name: nix
              mountPath: /nix
              subPath: nix
            - name: tmp
              mountPath: /tmp

          readinessProbe:
            exec:
              command:
                - /bin/test
                - -f
                - /tmp/devcontainer-ready
            periodSeconds: 10
            timeoutSeconds: 2

      volumes:
        - name: tmp
          emptyDir: {}

  volumeClaimTemplates:
    - metadata:
        name: home
      spec:
        accessModes:
          - ReadWriteOnce
        # storageClassName: YOUR_STORAGE_CLASS
        resources:
          requests:
            storage: 50Gi

    - metadata:
        name: nix
      spec:
        accessModes:
          - ReadWriteOnce
        # storageClassName: YOUR_STORAGE_CLASS
        resources:
          requests:
            storage: 30Gi
```

The init container seeds the persistent Nix store as UID 999. The main container keeps its root filesystem read-only while `/home/arthur`, `/nix`, and `/tmp` remain writable.

Remove `runtimeClassName`, the GPU toleration and `nvidia.com/gpu` if the workspace does not need a GPU.

</details>

Apply with:

```bash
kubectl apply -f hosts/devcontainer/k8s/service.yaml
kubectl apply -f hosts/devcontainer/k8s/statefulset.yaml
```

