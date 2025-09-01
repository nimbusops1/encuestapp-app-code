 # EncuestApp - Código Fuente

Este repositorio contiene el código fuente de la aplicación **EncuestApp**, 
junto con los archivos necesarios para su construcción y despliegue continuo mediante Jenkins y Docker.

---

# Estructura del Repositorio
├── src/ # Código fuente de la aplicación
├── Dockerfile # Imagen Docker para la app
├── Jenkinsfile # Pipeline CI/CD para construir y desplegar
└── README.md # Este archivo


---

# Tecnologías Utilizadas

-  Docker
-  Jenkins
-  Kustomize (en otro repo: `encuestapp-k8s-infra`)
-  Harbor (como registro de imágenes)
-  Kubernetes (Minikube para desarrollo)

---

# Construcción de la Imagen

La imagen se construye automáticamente desde el `Dockerfile` con Jenkins cuando se hace push al branch `main`.

```bash
docker build -t 192.168.49.1/encuestapp-prueba/encuestapp:<TAG> .
....
````

Jenkinsfile

El archivo Jenkinsfile incluye:

   Checkout del código fuente

   Detección del entorno de despliegue ([deploy-dev], [deploy-stg], [deploy-prod][approved])

   Build de la imagen Docker

   Push a Harbor
 
   Modificación del archivo patch-deployment.yaml en el repo de manifiestos encuestapp-k8s-infra

   Trigger automático de despliegue vía ArgoCD

Despliegue Automático

El despliegue es gestionado por ArgoCD, el cual monitorea el repositorio de manifiestos Kubernetes (encuestapp-k8s-infra), el cual se actualiza automáticamente desde este pipeline.

Commits especiales

Para desplegar, se requiere agregar etiquetas en el mensaje de commit:

   "[deploy-dev]" → despliega en entorno de desarrollo

   "[deploy-stg]" → despliega en entorno de staging

   "[deploy-prod][approved]" → despliega en producción (solo si está aprobado)




agregando cambios
