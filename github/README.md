# Reto CI/CD --- GitHub Actions + Self-Hosted Runner

## Objetivo

Implementar un pipeline de **Continuous Integration (CI) y Continuous
Deployment (CD)** utilizando **GitHub Actions** como plataforma de
orquestación y una máquina virtual creada con **Vagrant** como
**self-hosted runner**.

Durante el reto se automatizará la construcción, validación, publicación
y despliegue de una aplicación compuesta por:

-   Base de datos.
-   Backend.
-   Frontend.

La arquitectura combina una plataforma CI/CD administrada en cloud con
infraestructura de ejecución administrada por el equipo.

En este reto, la construcción y el despliegue de los componentes se
realizarán **directamente mediante comandos Docker y los Dockerfiles
proporcionados**. **No se utilizará Docker Compose**. El objetivo es
implementar explícitamente la construcción, publicación y ejecución de
cada componente y comprender las dependencias existentes entre ellos.

``` text
GitHub Cloud
      │
      │ GitHub Actions
      ▼
Self-hosted Runner
   (Vagrant VM)
      │
      ├── CI
      │   Code
      │     ↓
      │   Build
      │     ↓
      │   Test
      │     ↓
      │   Release
      │     ↓
      │   Docker Hub
      │
      └── CD
          Pull
            ↓
          Deploy
            ↓
        Verificación
```

------------------------------------------------------------------------

## 1. Preparación del repositorio

Realice un **fork** del repositorio del diplomado hacia su propia cuenta
de GitHub.

Configure temporalmente el repositorio como **privado**, ya que durante
el laboratorio se trabajará con credenciales, tokens y secretos. Más
adelante se analizarán buenas prácticas para gestionar este tipo de
información correctamente.

Clone su fork:

``` bash
git clone <URL_DE_SU_FORK>
```

Ingrese al repositorio clonado.

------------------------------------------------------------------------

## 2. Preparación del Self-Hosted Runner

La infraestructura necesaria para el runner se encuentra dentro de:

``` text
github/
├── Vagrantfile
└── scripts/
    ├── install-github-runner.sh
    └── register-github-runner.sh
```

### Vagrantfile

El `Vagrantfile` define la máquina virtual que funcionará como entorno
de ejecución de los workflows.

Entre otras configuraciones:

-   Utiliza Ubuntu como sistema operativo.
-   Configura los recursos de CPU y memoria.
-   Instala Docker mediante el provisioner de Vagrant.
-   Ejecuta el script encargado de instalar las dependencias necesarias
    para el GitHub Actions Runner.

Revise su contenido antes de crear la máquina.

### Script de instalación

El archivo:

``` text
github/scripts/install-github-runner.sh
```

prepara la VM instalando las dependencias necesarias y crea el usuario y
directorios que serán utilizados por el GitHub Actions Runner.

Este script es ejecutado automáticamente durante el aprovisionamiento de
Vagrant.

### Crear la máquina virtual

Ubíquese en el directorio que contiene el `Vagrantfile`:

``` bash
cd github
```

Cree y aprovisione la máquina:

``` bash
vagrant up
```

Al finalizar, ingrese a ella:

``` bash
vagrant ssh
```

Compruebe que Docker se encuentra disponible antes de continuar.

------------------------------------------------------------------------

## 3. Registrar el Self-Hosted Runner en GitHub

La máquina virtual existe, pero GitHub todavía no sabe que puede
utilizarla para ejecutar jobs.

Ingrese en su repositorio de GitHub y navegue hacia:

**Settings → Actions → Runners → New self-hosted runner**

Seleccione **Linux** y la arquitectura correspondiente.

GitHub mostrará las instrucciones necesarias para registrar un nuevo
runner. De esta información necesitaremos principalmente:

-   **Repository URL:** URL del repositorio al cual se asociará el
    runner.
-   **Token:** token temporal generado por GitHub para registrar el
    nuevo runner.

> El token de registro del runner no es el mismo token que
> posteriormente utilizaremos para Docker Hub.

Edite:

``` text
github/scripts/register-github-runner.sh
```

y complete los valores correspondientes a:

``` text
GITHUB_REPOSITORY_URL
GITHUB_RUNNER_TOKEN
```

El script se encargará de descargar/configurar el runner, registrarlo
contra el repositorio y configurarlo como servicio dentro de la VM.

Ejecute el script desde la máquina virtual:

``` bash
/vagrant/scripts/register-github-runner.sh
```

------------------------------------------------------------------------

## 4. Verificar el Runner

Regrese a:

**Settings → Actions → Runners**

El runner deberá aparecer registrado y disponible, normalmente en
estado:

``` text
Idle
```

Revise también los **labels** asociados al runner. Estos serán
utilizados posteriormente para indicar a GitHub Actions dónde deben
ejecutarse los jobs.

Antes de continuar, identifique:

-   ¿Dónde se encuentra GitHub Actions?
-   ¿Dónde se ejecutarán realmente los comandos del pipeline?
-   ¿Quién administra la infraestructura del runner?
-   ¿Qué ocurriría con los workflows si la VM estuviera apagada?

------------------------------------------------------------------------

# Parte I --- Continuous Integration

## 5. Preparar Docker Hub

El pipeline deberá publicar las imágenes generadas durante CI en
**Docker Hub**.

Cree o identifique los repositorios necesarios para almacenar las
imágenes de:

-   Database.
-   Backend.
-   Frontend.

### Crear un Access Token en Docker Hub

Genere un **Access Token** para que GitHub Actions pueda autenticarse
contra Docker Hub sin utilizar directamente la contraseña de su cuenta.

1.  Ingrese a Docker Hub.
2.  Abra su perfil de usuario.
3.  Ingrese a **Account Settings**.
4.  Busque la sección **Personal access tokens / Access Tokens**.
5.  Cree un nuevo token.
6.  Asígnele un nombre que permita identificar su propósito, por ejemplo
    `github-actions-cicd`.
7.  Otórguele los permisos necesarios para publicar imágenes en los
    repositorios utilizados durante el laboratorio.
8.  Copie y conserve el token generado.

> El valor completo del token puede mostrarse únicamente durante su
> creación.

### Registrar las credenciales en GitHub

En el repositorio vaya a:

**Settings → Secrets and variables → Actions**

Cree los **Secrets** necesarios para que el workflow pueda autenticarse
contra Docker Hub.

Necesitará almacenar, como mínimo:

-   El usuario de Docker Hub.
-   El Access Token generado anteriormente.

No escriba directamente estas credenciales dentro del archivo del
workflow.

------------------------------------------------------------------------

## 6. Construir el workflow de Continuous Integration

El archivo base se encuentra en:

``` text
.github/workflows/ci.yml
```

El workflow deberá ejecutarse utilizando el **self-hosted runner**
creado anteriormente.

No se proporciona la implementación completa. El equipo deberá construir
el pipeline utilizando jobs, steps, Actions, variables y Secrets de
GitHub Actions.

El pipeline deberá implementar las siguientes etapas conceptuales:

``` text
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

### Job --- Code

Debe obtener el código necesario para ejecutar el pipeline.

Utilice una **GitHub Action** apropiada para obtener el contenido del
repositorio en el entorno donde se ejecutará el job.

### Job --- Build

Debe construir las imágenes Docker correspondientes a:

``` text
database
backend
frontend
```

Utilice los `Dockerfile` proporcionados dentro de las carpetas
correspondientes.

Las imágenes deben quedar disponibles para las siguientes etapas del
pipeline.

### Job --- Test

Por el momento, este job puede contener únicamente una validación
sencilla, por ejemplo un `echo` que represente la ejecución de la etapa
de testing.

El objetivo inicial es comprender la estructura y las dependencias entre
los jobs del pipeline.

**Bonus:** implemente una validación real, por ejemplo:

-   Un **unit test** del backend o frontend.
-   Una prueba sobre el artefacto generado.
-   Una comprobación de que la imagen Docker fue construida
    correctamente.
-   Una prueba básica de ejecución del contenedor.

El pipeline no deberá continuar hacia las etapas posteriores si la
validación implementada falla.

### Job --- Release

Las imágenes construidas deberán recibir una versión que permita
identificar el resultado de una ejecución particular del pipeline.

Diseñe una estrategia de **Image Tag** que evite que diferentes
ejecuciones produzcan accidentalmente la misma versión.

Tenga presente que, para publicar una imagen en Docker Hub, el nombre
debe identificar también **el usuario u organización propietario del
repositorio**.

La estructura es:

``` text
<USUARIO_DOCKERHUB>/<REPOSITORIO>:<TAG>
```

Por ejemplo:

``` text
miusuario/backend:<VERSION>
miusuario/database:<VERSION>
miusuario/frontend:<VERSION>
```

Docker permite asignar nuevas etiquetas a una imagen. Por ejemplo:

``` bash
docker tag imagen-origen usuario/repositorio:tag
```

Además del tag versionado definido por el equipo, cada imagen deberá
mantener también:

``` text
latest
```

Por lo tanto, una misma imagen deberá poder identificarse mediante dos
referencias:

``` text
miusuario/backend:<VERSION>
miusuario/backend:latest
```

Tenga en cuenta que `latest` es un **tag mutable**: una publicación
posterior puede hacer que apunte a una imagen diferente. El tag
versionado permitirá identificar de manera precisa qué artefacto fue
generado por una ejecución particular.

### Job --- Push

Autentíquese contra Docker Hub utilizando los **Secrets** configurados
anteriormente.

Publique las tres imágenes con:

-   Su tag versionado.
-   El tag `latest`.

Al finalizar CI, Docker Hub deberá contener las imágenes de Database,
Backend y Frontend correspondientes al release generado.

------------------------------------------------------------------------

## 7. Dependencias entre jobs

Los jobs no deben ejecutarse como operaciones independientes sin ningún
orden.

Configure las dependencias necesarias para garantizar un flujo similar
a:

``` text
Code
  ↓
Build
  ↓
Test
  ↓
Release
  ↓
Push
```

Utilice las capacidades de GitHub Actions para indicar que un job
**depende de la finalización correcta de otro job**.

Observe también qué ocurre con los jobs posteriores cuando uno de los
jobs anteriores falla.

------------------------------------------------------------------------

# Parte II --- Continuous Deployment

## 8. Separar CI y CD

Continuous Integration y Continuous Deployment deberán implementarse
mediante **dos workflows diferentes**:

``` text
.github/workflows/
├── ci.yml
└── cd.yml
```

El objetivo es que el workflow de CD comience **únicamente después de
que Continuous Integration haya terminado correctamente**.

GitHub Actions permite disparar un workflow como consecuencia de la
finalización de otro mediante el evento `workflow_run`.

### Consideración sobre la Default Branch

Para que un workflow pueda ser disparado mediante `workflow_run`, **el
archivo del workflow que recibe el evento debe existir en la default
branch del repositorio**.

Por ejemplo, si la default branch es:

``` text
main
```

pero `cd.yml` existe únicamente en:

``` text
feature/cicd
```

el workflow de CI puede ejecutarse en la rama de trabajo, pero GitHub no
iniciará `cd.yml` mediante `workflow_run`, porque el workflow receptor
todavía no existe en la default branch.

Tenga esto en cuenta al definir la rama desde la cual realizará el reto.

------------------------------------------------------------------------

## 9. Construir el workflow de Continuous Deployment

El archivo base se encuentra en:

``` text
.github/workflows/cd.yml
```

El pipeline de CD deberá implementar:

``` text
PULL
  ↓
DEPLOY
  ↓
VERIFICACIÓN
```

Al igual que durante CI, **este workflow deberá trabajar directamente
con Docker, sin Docker Compose**.

### Job --- Pull

Obtenga desde Docker Hub las imágenes producidas previamente por CI.

El deployment debe consumir imágenes ya construidas y publicadas. **CD
no deberá volver a construir la aplicación.**

Conceptualmente:

``` text
CI
Código → Build → Test → Release → Docker Hub
                                  ↓
CD                            Pull → Deploy
```

### Job --- Deploy

Despliegue individualmente los contenedores utilizando las imágenes
descargadas desde Docker Hub.

El equipo deberá determinar los comandos Docker necesarios para
configurar:

-   La red entre los contenedores.
-   Variables de entorno.
-   Nombres de los contenedores.
-   Puertos.
-   Comunicación entre los servicios.

Los componentes deberán iniciarse respetando sus dependencias:

``` text
1. Database
      ↓
2. Backend
      ↓
3. Frontend
```

Considere que:

> **Un contenedor iniciado no necesariamente significa que la aplicación
> dentro del contenedor esté lista para recibir conexiones.**

Implemente una estrategia sencilla para evitar que un servicio
dependiente intente conectarse antes de que el servicio anterior esté
disponible.

### Job --- Verificación

Compruebe que la plataforma desplegada se encuentre **arriba y
accesible** después del deployment.

Realice una comprobación sencilla contra el endpoint expuesto por la
aplicación.

Si la aplicación no responde correctamente, el job deberá fallar.

Esta etapa busca verificar el **estado del deployment**, no ejecutar
nuevamente las pruebas realizadas durante CI.

------------------------------------------------------------------------

## 10. Probar el pipeline completo

Realice un cambio en la aplicación y envíelo al repositorio.

Observe el comportamiento completo:

``` text
Push
 ↓
Continuous Integration
 ↓
Build
 ↓
Test
 ↓
Release
 ↓
Docker Hub
 ↓
Continuous Deployment
 ↓
Pull
 ↓
Database
 ↓
Backend
 ↓
Frontend
 ↓
Verificación
```

Compruebe:

-   Que los jobs se ejecuten sobre el self-hosted runner.
-   Que CI termine correctamente antes de iniciar CD.
-   Que las imágenes sean publicadas en Docker Hub.
-   Que las tres imágenes puedan identificarse mediante el mismo
    release.
-   Que exista tanto un tag versionado como `latest`.
-   Que CD consuma las imágenes existentes y no las reconstruya.
-   Que Database, Backend y Frontend se desplieguen respetando sus
    dependencias.
-   Que la aplicación desplegada quede accesible.

------------------------------------------------------------------------

## 11. Preguntas para el análisis

Al terminar el reto, discuta con su equipo:

1.  ¿Qué responsabilidades permanecen en GitHub Cloud y cuáles fueron
    trasladadas al self-hosted runner?
2.  ¿Qué ventajas y desventajas encontraron al administrar su propio
    runner?
3.  ¿Por qué CI y CD se implementaron como workflows independientes?
4.  ¿Qué información permite relacionar un artefacto generado durante CI
    con un deployment?
5.  ¿Qué problemas podría generar utilizar únicamente `latest`?
6.  ¿Qué ocurre si el self-hosted runner deja de estar disponible?
7.  ¿Qué partes del pipeline podrían ejecutarse en runners diferentes?
8.  ¿Qué problemas identifican en la forma en que se gestionaron
    credenciales, permisos e infraestructura?
9.  ¿Qué mejorarían si esta arquitectura fuera utilizada en un ambiente
    productivo?

------------------------------------------------------------------------

## Resultado esperado

Al finalizar el reto deberá tener una arquitectura funcional similar a:

``` text
                 GitHub Cloud
                      │
                GitHub Actions
                      │
              Self-hosted Runner
                (Vagrant VM)
                      │
          ┌───────────┴────────────┐
          │                        │
          ▼                        ▼
         CI                       CD
          │                        │
   Build / Test              Pull Images
          │                        │
       Release                     ▼
          │                    Database
          ▼                        ↓
      Docker Hub                Backend
                                   ↓
                                Frontend
                                   ↓
                              Verificación
```

El resultado no consiste únicamente en tener una aplicación desplegada.
El objetivo es comprender **cómo una plataforma CI/CD administrada puede
orquestar trabajos ejecutados sobre infraestructura propia, cómo separar
CI de CD y cómo utilizar artefactos versionados como frontera entre
ambos procesos**.
