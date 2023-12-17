import model
import yaml

_: model.WebApp = yaml.decode(option("source"))
