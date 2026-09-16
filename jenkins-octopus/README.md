# Reto CI/CD — Jenkins + Octopus Deploy

## Objetivo

Implementar una arquitectura de **Continuous Integration (CI) y Continuous Deployment (CD) desacoplada**, utilizando **Jenkins** para construir, validar y publicar los artefactos de la aplicación, y **Octopus Deploy** para gestionar sus releases y despliegues.

Durante el reto se automatizará el ciclo de una aplicación compuesta por:

- Base de datos.
- Backend.
- Frontend.

En esta arquitectura:

- **Jenkins** será responsable de Continuous Integration.
- **Docker Hub** almacenará y distribuirá las imágenes.
- **Octopus Deploy Cloud** gestionará los releases y el proceso de Continuous Deployment.
- **Octopus Tentacle** ejecutará el deployment sobre el ambiente destino.

Jenkins estará instalado de forma **self-hosted** sobre una máquina virtual creada mediante Vagrant.

La misma VM funcionará también como **Deployment Target de Octopus** mediante un Linux Tentacle configurado en modo Polling.

Para administrar la construcción y despliegue de los diferentes componentes se utilizará **Docker Compose**.

```text
Repositorio Git
      │
      ▼
Jenkins
(Self-hosted / Vagrant VM)
      │
      │ CI
      ▼
Code → Build → Test → Release → Push
                               │
                               ▼
                           Docker Hub
                               │
                               │ Artefactos
                               ▼
                       Octopus Deploy Cloud
                               │
                               │ CD
                               ▼
                       Polling Tentacle
                        (Vagrant VM)
                               │
                               ▼
                        Docker Compose
                               │
                        Pull → Deploy
                               │
                               ▼
                          Verificación
```

---

## 1. Preparación del repositorio

Realice un **fork** del repositorio del diplomado hacia su propia cuenta de GitHub.

Configure temporalmente el repositorio como **privado**, ya que durante el laboratorio se trabajará con credenciales, tokens, API Keys y otros datos de configuración.

Clone su fork:

```bash
git clone <URL_DE_SU_FORK>
```

Ingrese al repositorio clonado.

La arquitectura correspondiente a este reto se encuentra en:

```text
jenkins-octopus/
```

Su estructura principal es:

```text
jenkins-octopus/
├── Jenkinsfile
├── Vagrantfile
├── compose.yml
├── .env.dev
├── .env.prod
├── backend/
├── db/
├── frontend/
└── scripts/
    ├── install-jenkins.sh
    ├── install-octopus-tentacle.sh
    └── register-octopus-target.sh
```

---

## 2. Preparación de la infraestructura

En este reto utilizaremos una máquina virtual para alojar diferentes componentes de la arquitectura.

La VM tendrá:

```text
Vagrant VM
├── Docker
├── Jenkins
└── Octopus Tentacle
```

Aunque Jenkins y el Deployment Target se encuentran en la misma VM para simplificar el laboratorio, representan responsabilidades diferentes dentro del pipeline.

### Vagrantfile

Revise el archivo:

```text
jenkins-octopus/Vagrantfile
```

Este archivo se encarga de:

- Crear una máquina virtual Ubuntu.
- Configurar CPU y memoria.
- Exponer los puertos necesarios hacia el host.
- Instalar Docker mediante el provisioner de Vagrant.
- Ejecutar el script de instalación de Jenkins.
- Ejecutar el script de instalación de Octopus Tentacle.

### Instalación de Jenkins

Revise:

```text
scripts/install-jenkins.sh
```

Este script instala las dependencias necesarias para ejecutar Jenkins y configura el servicio dentro de la máquina virtual.

Jenkins será responsable de ejecutar el proceso de **Continuous Integration**.

### Instalación de Octopus Tentacle

Revise:

```text
scripts/install-octopus-tentacle.sh
```

Este script instala **Octopus Tentacle** dentro de la VM.

Tentacle permitirá posteriormente registrar la máquina como un **Deployment Target** de Octopus Deploy.

---

## 3. Crear la máquina virtual

Ubíquese en el directorio:

```bash
cd jenkins-octopus
```

Cree y aprovisione la máquina:

```bash
vagrant up
```

Cuando termine, ingrese a ella:

```bash
vagrant ssh
```

Compruebe que Docker esté disponible:

```bash
docker --version
```

Compruebe también que Jenkins se encuentre ejecutándose.

Desde su máquina host acceda a:

```text
http://localhost:8080
```

Durante el primer ingreso, Jenkins solicitará la contraseña inicial de administración.

Puede obtenerla desde la VM mediante:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Complete la configuración inicial de Jenkins.

---

# Parte I — Continuous Integration con Jenkins

## 4. Preparar Jenkins

Jenkins utiliza plugins para extender sus capacidades.

Verifique que la instalación disponga de los componentes necesarios para trabajar con:

- Git.
- Pipelines.
- Declarative Pipeline.
- Credentials.
- Ejecución de comandos sobre el sistema.

Si alguno no se encuentra disponible, ingrese a:

**Manage Jenkins → Plugins**

e instale los plugins necesarios.

---

## 5. Preparar Docker Hub

Docker Hub funcionará como **repositorio de las imágenes generadas durante CI y como punto de intercambio entre Jenkins y Octopus Deploy**.

Jenkins deberá realizar conceptualmente:

```text
Construir
   ↓
Validar
   ↓
Versionar
   ↓
Publicar
   ↓
Docker Hub
```

Cree o identifique repositorios para almacenar las imágenes correspondientes a:

- Database.
- Backend.
- Frontend.

### Crear un Access Token

Genere un Access Token para que Jenkins pueda autenticarse contra Docker Hub.

1. Ingrese a Docker Hub.
2. Abra su perfil.
3. Ingrese a **Account Settings**.
4. Abra **Personal access tokens / Access Tokens**.
5. Cree un nuevo token.
6. Asígnele un nombre que permita identificar su propósito, por ejemplo:

```text
jenkins-cicd
```

7. Otórguele los permisos necesarios para publicar imágenes.
8. Copie el token generado.

> Guarde el token cuando sea generado, ya que posteriormente podría no mostrarse nuevamente su valor completo.

---

## 6. Registrar las credenciales de Docker Hub en Jenkins

No escriba directamente el usuario y Access Token dentro del `Jenkinsfile`.

En Jenkins ingrese a:

**Manage Jenkins → Credentials**

Registre una credencial de tipo:

**Username with password**

Utilice:

- **Username:** usuario de Docker Hub.
- **Password:** Access Token generado.
- **ID:** un identificador que posteriormente pueda utilizarse desde el pipeline.

El `Jenkinsfile` deberá utilizar este identificador para recuperar las credenciales durante la publicación de las imágenes.

---

## 7. Configurar Jenkins para acceder al repositorio privado

Como el fork fue configurado como **privado**, Jenkins necesitará credenciales para poder obtener el `Jenkinsfile` y el código de la aplicación.

### Crear un Personal Access Token en GitHub

Desde GitHub:

1. Ingrese a su perfil.
2. Abra **Settings**.
3. Ingrese a **Developer settings**.
4. Abra la sección de **Personal access tokens**.
5. Genere un nuevo token.
6. Otórguele acceso al repositorio utilizado en el laboratorio.
7. Asegúrese de que tenga permisos de lectura sobre el contenido del repositorio.
8. Copie el token generado.

### Registrar las credenciales en Jenkins

En Jenkins ingrese a:

**Manage Jenkins → Credentials**

Cree una nueva credencial de tipo:

**Username with password**

Utilice:

- **Username:** su usuario de GitHub.
- **Password:** el Personal Access Token generado.
- **ID:** un identificador descriptivo, por ejemplo:

```text
github-repository
```

Cuando Jenkins accede a GitHub mediante HTTPS, el token se utiliza como contraseña.

---

## 8. Configurar el Pipeline desde SCM

El pipeline no deberá escribirse directamente desde la interfaz de Jenkins.

Jenkins deberá obtener el `Jenkinsfile` almacenado dentro del repositorio Git privado.

Cree un nuevo Job de tipo:

**Pipeline**

En la sección **Pipeline**, seleccione:

**Pipeline script from SCM**

Configure:

- **SCM:** Git.
- **Repository URL:** URL HTTPS de su fork.
- **Credentials:** credencial de GitHub creada anteriormente.
- **Branch:** rama sobre la cual está trabajando.
- **Script Path:** ruta del `Jenkinsfile`.

El archivo correspondiente al reto se encuentra en:

```text
jenkins-octopus/Jenkinsfile
```

Conceptualmente:

```text
Jenkins
   │
   │ Credenciales GitHub
   ▼
Repositorio privado
   ↓
Jenkinsfile
   ↓
Pipeline
```

De esta manera, Jenkins podrá leer tanto el `Jenkinsfile` como el código necesario para ejecutar el pipeline, manteniendo la definición del proceso versionada dentro del repositorio.

---

## 9. Revisar Docker Compose

La definición de los servicios se encuentra en:

```text
jenkins-octopus/compose.yml
```

Revise los tres servicios:

```text
database
backend
frontend
```

Observe especialmente:

- `build`
- `image`
- variables de entorno
- puertos
- dependencias entre servicios
- healthcheck
- volumen de la base de datos

En este reto se utilizará **Docker Compose para construir y administrar conjuntamente los componentes de la aplicación**.

Identifique qué Dockerfile utiliza cada servicio y qué imagen genera.

---

## 10. Construir el Jenkinsfile

El archivo base se encuentra en:

```text
jenkins-octopus/Jenkinsfile
```

Complete el pipeline utilizando **Declarative Pipeline**.

El pipeline deberá implementar:

```text
CODE
  ↓
BUILD
  ↓
TEST
  ↓
RELEASE
  ↓
PUSH
```

### Stage — Code

Obtenga el código del repositorio configurado como SCM.

Jenkins deberá disponer del código necesario antes de iniciar la construcción.

### Stage — Build

Utilice **Docker Compose** para construir las imágenes de los servicios definidos en:

```text
compose.yml
```

Compose deberá utilizar los diferentes contextos de construcción y Dockerfiles para producir las imágenes correspondientes a:

```text
Database
Backend
Frontend
```

Tenga presente desde qué directorio del workspace se está ejecutando Jenkins y dónde se encuentra el archivo `compose.yml`.

### Stage — Test

Por el momento, esta etapa puede contener únicamente una validación sencilla, por ejemplo un `echo` que represente la ejecución del proceso de testing.

El objetivo inicial es representar correctamente esta etapa dentro del pipeline.

**Bonus:** implemente una validación real, por ejemplo:

- Un unit test.
- Una validación de las imágenes generadas.
- Una ejecución temporal de un servicio.
- Una prueba básica sobre alguno de los artefactos.

Si la validación falla, el pipeline no deberá continuar hacia Release.

### Stage — Release

Genere un **Image Tag** que permita identificar de manera única el resultado de la ejecución.

Las imágenes deberán publicarse siguiendo la estructura:

```text
<USUARIO_DOCKERHUB>/<REPOSITORIO>:<TAG>
```

Por ejemplo:

```text
miusuario/backend:<VERSION>
miusuario/database:<VERSION>
miusuario/frontend:<VERSION>
```

Tenga presente que el nombre de la imagen publicada debe incluir **su usuario u organización de Docker Hub**.

Puede asignar nuevas etiquetas mediante:

```bash
docker tag imagen-origen usuario/repositorio:tag
```

Cada imagen deberá mantener:

- Un tag correspondiente al release.
- El tag `latest`.

Conceptualmente:

```text
miusuario/backend:<VERSION>
miusuario/backend:latest
```

La versión generada durante CI será utilizada posteriormente por **Octopus Deploy para identificar el release que debe desplegar**.

### Stage — Push

Autentíquese contra Docker Hub utilizando las credenciales almacenadas en Jenkins.

Publique las imágenes de:

```text
Database:<VERSION>
Database:latest

Backend:<VERSION>
Backend:latest

Frontend:<VERSION>
Frontend:latest
```

Al finalizar Jenkins, Docker Hub deberá contener los artefactos que posteriormente serán consumidos por Octopus.

---

# Parte II — Continuous Deployment con Octopus Deploy

## 11. Crear la instancia de Octopus Deploy Cloud

Antes de configurar Continuous Deployment, cree una cuenta en **Octopus Deploy** y aprovisione una instancia de **Octopus Cloud**.

Durante el registro, Octopus solicitará crear una instancia asociada a su cuenta u organización.

Esta instancia tendrá una URL similar a:

```text
https://<NOMBRE-DE-LA-INSTANCIA>.octopus.app
```

La instancia será utilizada para administrar:

- Projects.
- Environments.
- Deployment Targets.
- Releases.
- Variables.
- Spaces.
- Usuarios y permisos.

Conserve la URL de la instancia, ya que posteriormente será utilizada como:

```text
OCTOPUS_SERVER_URL
```

dentro del script:

```text
jenkins-octopus/scripts/register-octopus-target.sh
```

Si durante la configuración Octopus solicita crear un **Space**, puede utilizar el Space por defecto o crear uno específico para el laboratorio.

---

## 12. Crear el Environment

Dentro de su instancia de Octopus, cree un **Environment** que represente el ambiente donde será desplegada la aplicación.

Por ejemplo:

```text
Development
```

Posteriormente, la máquina virtual creada mediante Vagrant será registrada como un **Deployment Target** perteneciente a este Environment.

---

## 13. Crear una API Key en Octopus

Para registrar el Tentacle de la máquina virtual contra Octopus Cloud será necesario autenticarse mediante una **API Key**.

La API Key se genera desde el **perfil del usuario**.

En Octopus Deploy:

1. Ingrese a su instancia de Octopus Cloud.
2. Abra el menú de su **perfil de usuario**, ubicado en la parte superior derecha.
3. Ingrese a la configuración de su perfil.
4. Abra la sección **API Keys**.
5. Seleccione la opción para crear una nueva API Key.
6. Asígnele un nombre o propósito que permita identificarla, por ejemplo:

```text
Vagrant Deployment Target
```

7. Para este laboratorio, configure la API Key como:

```text
Agent
```

8. Asígnele los permisos necesarios para realizar el registro del Deployment Target.
9. Genere la API Key.
10. Copie inmediatamente su valor.

La llave tendrá una estructura similar a:

```text
API-XXXXXXXXXXXXXXXXXXXXXXXX
```

> Guarde el valor cuando sea generado. Octopus no vuelve a mostrar posteriormente el valor completo de la API Key.

Esta API Key será utilizada como:

```text
OCTOPUS_API_KEY
```

dentro del script de registro.

---

## 14. Configurar el Deployment Target

El script encargado de registrar la VM se encuentra en:

```text
jenkins-octopus/scripts/register-octopus-target.sh
```

Revise las variables ubicadas al comienzo del archivo:

```text
OCTOPUS_SERVER_URL
OCTOPUS_API_KEY
OCTOPUS_SPACE
OCTOPUS_ENVIRONMENT
TARGET_NAME
TARGET_ROLE
```

Complete los valores correspondientes a su instancia.

### ¿Qué representa cada dato?

**OCTOPUS_SERVER_URL**

URL de su instancia de Octopus Cloud.

**OCTOPUS_API_KEY**

API Key creada desde su perfil.

**OCTOPUS_SPACE**

Space donde se realizará el laboratorio.

**OCTOPUS_ENVIRONMENT**

Environment creado anteriormente.

**TARGET_NAME**

Nombre con el cual aparecerá la VM dentro de Octopus.

**TARGET_ROLE**

Rol que permitirá determinar qué Deployment Processes pueden ejecutarse sobre este target.

---

## 15. Registrar el Polling Tentacle

Desde la máquina virtual ejecute:

```bash
/vagrant/scripts/register-octopus-target.sh
```

El script se encargará de:

- Crear la instancia del Tentacle.
- Generar su certificado.
- Configurarlo en modo **Polling**.
- Registrarlo contra Octopus Cloud.
- Asociarlo con el Environment y Role definidos.
- Instalarlo como servicio.

Se utiliza **Polling Tentacle** porque la VM puede iniciar la comunicación hacia Octopus Cloud sin requerir que Octopus Cloud establezca directamente una conexión entrante hacia la VM local.

Conceptualmente:

```text
Octopus Cloud
      ▲
      │ Polling
      │
Linux Tentacle
      │
Vagrant VM
```

---

## 16. Verificar el Deployment Target

Regrese a Octopus Deploy y compruebe que la VM aparezca como un **Deployment Target disponible**.

Verifique:

- Nombre del target.
- Environment.
- Target Role.
- Estado de conectividad.

Antes de continuar, identifique:

- ¿Dónde se encuentra Octopus Server?
- ¿Dónde se ejecutarán realmente los comandos del deployment?
- ¿Quién inicia la conexión entre Octopus Cloud y la VM?
- ¿Qué responsabilidad tiene el Tentacle dentro de esta arquitectura?

---

## 17. Crear el Project de Octopus

Cree un nuevo **Project** para representar la aplicación.

Este Project contendrá el proceso encargado de desplegar las imágenes previamente generadas por Jenkins.

El Deployment Process deberá ejecutarse sobre los targets que posean el Role configurado durante el registro.

Conceptualmente:

```text
Octopus Project
      ↓
Deployment Process
      ↓
Target Role
      ↓
Deployment Target
```

---

## 18. Relacionar Release e Image Tag

Jenkins genera una versión durante la etapa **Release**.

Utilice ese mismo identificador para crear el **Release de Octopus**.

Conceptualmente:

```text
Jenkins

IMAGE_TAG = <VERSION>
      │
      ├── database:<VERSION>
      ├── backend:<VERSION>
      └── frontend:<VERSION>
      │
      ▼
Docker Hub


Octopus

Release = <VERSION>
```

De esta manera se establece trazabilidad entre:

```text
Build
  ↓
Artifact
  ↓
Release
  ↓
Deployment
```

Octopus proporciona la variable del sistema:

```text
#{Octopus.Release.Number}
```

que permite obtener el número del release actual dentro del Deployment Process.

Utilice este valor para identificar qué versión de las imágenes debe desplegarse.

---

## 19. Construir el Deployment Process

Configure un **Deployment Process** dentro del Project.

El proceso deberá ejecutar las acciones necesarias sobre el Deployment Target.

El flujo esperado es:

```text
PULL
  ↓
DEPLOY
  ↓
VERIFICACIÓN
```

### Step — Pull

Obtenga desde Docker Hub las imágenes correspondientes al número del release actual.

Utilice:

```text
#{Octopus.Release.Number}
```

para identificar el tag que debe descargarse.

Conceptualmente:

```text
miusuario/database:#{Octopus.Release.Number}
miusuario/backend:#{Octopus.Release.Number}
miusuario/frontend:#{Octopus.Release.Number}
```

El proceso de CD deberá **consumir las imágenes creadas por Jenkins y no volver a construirlas**.

### Step — Deploy

Utilice **Docker Compose** para desplegar la aplicación sobre el Deployment Target.

Compose deberá administrar conjuntamente:

```text
Database
   ↓
Backend
   ↓
Frontend
```

Utilice la configuración y variables de ambiente correspondientes al Environment que está desplegando.

El deployment deberá utilizar las imágenes versionadas previamente obtenidas desde Docker Hub.

### Step — Verificación

Compruebe que la plataforma se encuentre **arriba y accesible** después del deployment.

Realice una comprobación sencilla contra el endpoint expuesto por la aplicación.

Si la aplicación no responde correctamente, el proceso deberá indicar que el deployment no terminó satisfactoriamente.

Esta etapa busca comprobar el **estado del deployment**, no ejecutar nuevamente las pruebas realizadas durante CI.

---

## 20. Probar el proceso completo

Realice un cambio en la aplicación y ejecute nuevamente el pipeline de Jenkins.

Observe:

```text
Git
 ↓
Jenkins
 ↓
Code
 ↓
Build
 ↓
Test
 ↓
Release
 ↓
Push
 ↓
Docker Hub
```

Identifique el **Image Tag** generado durante Release.

Luego cree en Octopus un Release utilizando exactamente ese mismo identificador:

```text
Octopus Release = Image Tag
```

Ejecute el deployment hacia el Environment configurado.

El flujo completo deberá ser:

```text
Git
 ↓
Jenkins
 ↓
Continuous Integration
 ↓
Docker Hub
 ↓
Octopus Release
 ↓
Continuous Deployment
 ↓
Polling Tentacle
 ↓
Docker Compose
 ↓
Database
 ↓
Backend
 ↓
Frontend
 ↓
Verificación
```

---

## 21. Comprobar el resultado

Verifique:

- Que Jenkins obtenga el `Jenkinsfile` directamente desde Git.
- Que Jenkins pueda acceder correctamente al repositorio privado.
- Que Jenkins construya los tres componentes mediante Docker Compose.
- Que las imágenes sean publicadas en Docker Hub.
- Que exista un tag versionado y `latest`.
- Que las tres imágenes compartan el identificador del mismo release.
- Que el Deployment Target aparezca disponible en Octopus.
- Que el Release Number de Octopus coincida con el Image Tag generado durante CI.
- Que Octopus descargue las imágenes existentes y no vuelva a construirlas.
- Que Docker Compose despliegue Database, Backend y Frontend.
- Que la aplicación quede accesible después del deployment.
- Que Octopus registre el resultado del despliegue.

---

## 22. Preguntas para el análisis

Al finalizar el reto, discuta con su equipo:

1. ¿Dónde termina la responsabilidad de Jenkins y dónde comienza la de Octopus?
2. ¿Qué elemento permite desacoplar CI de CD en esta arquitectura?
3. ¿Qué función cumple Docker Hub entre Jenkins y Octopus?
4. ¿Qué ventajas ofrece utilizar el mismo identificador para el Image Tag y el Octopus Release?
5. ¿Qué diferencia existe entre construir un artefacto y desplegarlo?
6. ¿Qué función cumple el Tentacle?
7. ¿Por qué se utiliza un Polling Tentacle para la VM del laboratorio?
8. ¿Qué ventajas aporta Docker Compose al administrar los tres componentes?
9. ¿Qué ocurriría si el release de Octopus utiliza una versión que no existe en Docker Hub?
10. ¿Qué ocurre si Jenkins deja de estar disponible después de que las imágenes ya fueron publicadas? ¿Octopus podría continuar realizando un deployment?
11. ¿Qué problemas identifican en la gestión actual de credenciales, permisos y configuración?
12. ¿Qué cambiarían si esta arquitectura fuera utilizada en un ambiente productivo?

---

## Resultado esperado

Al finalizar el reto deberá tener una arquitectura funcional similar a:

```text
                    Git Repository
                          │
                          ▼
                       Jenkins
                  (Self-hosted VM)
                          │
                          │ CI
                          ▼
              Build → Test → Release
                          │
                          ▼
                     Docker Hub
                          │
                   Imágenes versionadas
                          │
                          ▼
                  Octopus Deploy Cloud
                          │
                    Release <VERSION>
                          │
                          ▼
                   Polling Tentacle
                          │
                    Deployment Target
                          │
                          ▼
                    Docker Compose
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
           Database    Backend     Frontend
                          │
                          ▼
                     Verificación
```

El resultado no consiste únicamente en desplegar la aplicación. El objetivo es comprender cómo una arquitectura puede **separar las responsabilidades de CI y CD entre herramientas especializadas**, utilizando artefactos versionados como punto de integración entre ambos procesos.

> **Jenkins construye y valida → Docker Hub almacena y distribuye → Octopus gestiona el release y el deployment → Tentacle ejecuta el despliegue en el ambiente destino.**
