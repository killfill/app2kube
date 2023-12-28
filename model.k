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

schema Ingress:
    hostname: str
    class: str = ""
    tls: bool = False
    path: str = "/"