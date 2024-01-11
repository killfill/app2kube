import model
import manifests

import k8s.api.core.v1 as k8core
import k8s.api.apps.v1 as k8apps
import k8s.api.networking.v1 as k8snet

_def_labels = {renderBy: 'app2kube'}
_def_annotations = {renderBy: 'app2kube'}

kubeRender = lambda app: model.WebApp {
    _common_metadata = {
            name = app.name
            namespace = app.namespace
            annotations = app.annotations | _def_annotations
            labels = app.labels
        }

    _deployment = k8apps.Deployment {
        metadata = _common_metadata
        spec = {
            replicas: app.replicas
            selector.matchLabels = {app = app.name}
            template = {
                metadata = {
                    annotations = app.annotations | _def_annotations
                    labels = {app = app.name}
                }
                spec = {
                    if app.runAsUser > -1:
                        securityContext = {
                            runAsUser = app.runAsUser
                        }
                    containers = [{
                        name = "main"
                        image = app.image
                        ports = [{containerPort = app.port}]
                        env = [{name: k, value: app.env[k]} for k in app.env]
                        if app.command:
                            command = app.command
                        volumeMounts = [{
                            name = vol.name
                            mountPath = vol.path
                        } for vol in app.volumes]
                    }]
                    if app.imagePullSecret:
                        imagePullSecrets = [{name = app.imagePullSecret}]
                    volumes = [{
                        name = vol.name
                        if vol.type == "pvc":
                            persistentVolumeClaim.claimName = app.name + '-' + vol.name
                        if vol.type == "emptyDir":
                            emptyDir = {}
                    } for vol in app.volumes]
                }
            }
        }
    }
    _service = k8core.Service {
        metadata = _common_metadata
        spec = {
            type = "ClusterIP"
            ports = [{port: app.port}]
            selector = {app = app.name}
        }
    }
    _ingress = app.ingress and k8snet.Ingress {
        metadata = _common_metadata
        if app.ingress.tls:
            metadata.annotations = app.annotations | {"kubernetes.io/tls-acme": "true"}
        spec = k8snet.IngressSpec {
            if app.ingress.class:
                ingressClassName = app.ingress.class
            rules = [{
                host = app.ingress.hostname
                http.paths = [{
                    path = app.ingress.path
                    pathType = "Prefix"
                    backend.service = k8snet.IngressServiceBackend {
                        name = app.name
                        port = k8snet.ServiceBackendPort {
                            number = app.port
                        }
                    }
                }]
            }]
        }
        if app.ingress.tls:
            spec.tls = [{hosts = [app.ingress.hostname], secretName = "ingress-tls-${app.name}"}]
    }
    _pvcs = [k8core.PersistentVolumeClaim {
        metadata = _common_metadata
        metadata.name = metadata.name + '-' + vol.name
        spec = k8core.PersistentVolumeClaimSpec {
            accessModes = ["ReadWriteOnce"]
            resources = k8core.ResourceRequirements {
                requests = {storage: vol.size}
            }
        }
    } for vol in app.volumes if vol.type == "pvc"]
    #Looks like the return value is the last statement
    [_deployment, _service, _ingress, _pvcs]
}

manifests.yaml_stream(sum([kubeRender(app) for app in model.WebApp.instances()], []))
