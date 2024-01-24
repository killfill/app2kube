schema WebApp:
    name: str
    image: str
    namespace: str = "default"
    port: int = 80
    env: {str:str} = {}
    annotations: {str:str} = {}
    labels: {str:str} = {}
    imagePullSecret: str = ""
    replicas: int = 1
    ingress?: Ingress
    command?: [str] = None
    volumes?: [Volume] = []
    runAsUser?: int = -1
    requests?: ResourceDef = None
    limits?: ResourceDef = None
    strategy?: "RollingUpdate" | "Recreate" = None

schema Ingress:
    hostname: str
    class: str = ""
    tls: bool = False
    path: str = "/"

schema Volume:
    name: str
    path: str
    size: str = "10Gi"
    type: "emptyDir" | "pvc" = "pvc"
    check:
        path not in ["/", "/boot", "/home", "dev", "/etc", "/root"]

schema ResourceDef:
    cpu: str = None
    memory: str = None