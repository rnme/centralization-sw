# Centralización RNME

Monitoreo de repiradores RNME.

## Motivación

El proyecto Respirador Neumático Modular de Emergencia (RNME) tiene como objetivo la fabricación de respiradores artificiales.

El respirador cuenta con una interfaz de control embebida y una interfaz web disponible a través de una red local provista por el sistema embebido, a la cual se accede a través de un dispositivo móvil.

Se contempla que el respirador pueda ser usado en instalaciones colectivas, en la que múltiples pacientes sean suministrados por respiradores RNME dentro de un mismo recinto. El propósito de este repositorio es implementar un sistema de monitoreo centralizado para todos los respiradores de una instalación que pueda ser usado por el personal responsable de la instalación.

## Arquitectura

El sistema de monitoreo está conformado por dos subsistemas:
* Por un lado, un subsistema de adquisición de datos, que se encarga de obtener los datos de los respiradores que interesa monitorear.
* Por otro, un tablero de monitoreo, el cual permite visualizar los datos de los respiradores en tiempo real al personal de la instalación.

### Adquisición de datos

El subsistema de adquisición está dividido en dos módulos, los cuales se encargan de reportar los datos de los respiradores en una base de datos de series temporales. Cada módulo está contenido en su propio subdirectorio:
* `receiver/` contiene el módulo receptor, que se encarga de recibir y almacenar los datos reportados por los respiradores en la base de datos.
* `watchdog/` contiene el módulo que oficia de *watchdog* de conectividad. Este módulo se encarga de detectar y reportar cuándo se pierde la conectividad con un respirador.

#### Receptor

El receptor se implementa con una API REST a la cual el dispositivo móvil usado como control remoto de cada respirador reporta periódicamente los datos del estado actual del respirador.

Para la recepción, la API implementa un único método, `POST /ventilators/:id/measurements`, el cual recibe un objeto JSON con el siguiente formato en el cuerpo del mensaje:
```
{
  "status": 0,
  "fr": 0,
  "ie": 0,
  "pause": 0,
  "vc": 0,
  "fio2": 0,
  "peep": 0
}
```
El parámetro del cuerpo `:id` corresponde al número de cama del respirador que se está reportando. Los parámetros del cuerpo del mensaje son:
* `status`: *(Entero.)* Código de estado de alarma. El valor `0` indica el estado OK; `1` indica un estado de advertencia; `2` indica un estado de alarma.
* `fr`: *(Entero.)* Frecuencia de respiración (*FR*) en respiraciones por minuto (rpm).
* `i:e`: *(Entero.)* Relación de el tiempo de inspiración sobre el tiempo de expiración (*I:E*). Se debe ingresar el valor del denominador, asumiendo una inspiración de tiempo 1.
* `pause`: *(Entero.)* Duración de pausa entre una inspiración y su correspondiente expiración (*Pausa inspiración*), medido en milisegundos (ms).
* `vc`: *(Entero.)* Volumen controlado (*VC*), medido en mililitros (ml).
* `fio2`: *(Entero.)* Fracción de oxígeno inspirado (*FiO2*), medido en porcentaje (%).
* `peep`: *(Entero.)* Presión de final de espiración positiva (*PEEP*), medido en centímetros de agua (cmH2O).

Existe un método adicional, `POST /reset`, que permite borrar todos los datos de la base de datos. Esto puede ser útil cuando figuran muchos respiradores desconectados en el tablero debido a que no están siendo usados actualmente.

#### Watchdog

El watchdog es un proceso que consulta periódicamente los datos reportados de la base de series temporales para detectar y reportar si se perdió la comunicación con algún respirador. Para cada respirador, en cada período el proceso obtiene la última medición recibida por el respirador; si la marca de tiempo de recepción de esa medición es más vieja que un intervalo dado configurable, se considera que se perdió conectividad con el respirador y el proceso inserta una medición en la base de datos un registro indicando que el respirador está desconectado.

### Tablero de monitoreo

El tablero de monitoreo consiste de un tablero de [Grafana](https://grafana.com/) que cuenta con un único panel, el cual muestra el estado actual de los respiradores. Los datos que se muestran se actualizan cada 5 segundos.

## Cómo contribuir

### Ambiente de desarrollo virtualizado

Se cuenta con un ambiente de desarrollo automatizado mediante Vagrant y VirtualBox.

El ambiente de desarrollo corre sobre una máquina virtual y requiere que la virtualización por hardware esté habilitada, lo cual se hace a través del BIOS o la UEFI. En caso de duda, verificar que el hardware soporta virtualización; en Ubuntu, se puede verificar a través de la herramienta `kvm-ok`.
```
$ sudo apt install cpu-checker
...
$ sudo kvm-ok
INFO: /dev/kvm exists
KVM acceleration can be used
```

La máquina virtual se configura a través [Vagrant](https://www.vagrantup.com/), el cual se instala a través de los paquetes distribuidos en su web.

En particular, se usa [VirtualBox](https://www.virtualbox.org/) como proveedor de Vagrant; en Ubuntu se puede instalar a través de los paquetes oficiales.
```
$ sudo apt install virtualbox
```
Para evitar problemas con las *guest additions* de VirtualBox, se recomienda instalar el siguiente plugin de Vagrant:
```
$ vagrant plugin install vagrant-vbguest
```

Para iniciar la máquina virtual se corre el comando `vagrant up` dentro del repositorio. Al final del proceso (puede llegar a demorar varios minutos la primera vez que se corre) se puede acceder a la máquina virtual por SSH a través del comando `vagrant ssh`. En caso de error se puede reintentar el proceso mediante el comando `vagrant provision` o `vagrant up --provision`. Para apagar la máquina virtual se corre el comando `vagrant halt` y para borrarla `vagrant destroy`.

Dentro del ambiente virtual, el repositorio se monta como carpeta compartida en la ruta `/vagrant`. Dentro de ese directorio, se puede levantar los servicios mediante `docker-compose`:
```
docker-compose up
```

El servicio de recepción de datos se puede acceder en http://localhost:5000, mientras que el tablero de monitoreo se encuentra en http://localhost:3000.

Junto con los servicios de los respiradores, en el entorno de desarrollo se levanta un proceso que simula la actividad de 23 respiradores, con identificadores del 3 al 25. Se recomienda usar los respiradores de identificador 1 y 2 para pruebas.

## Despliegue

La aplicación se desarrolló sobre un sistema operativo Ubuntu 18.04, por lo que se recomienda usarlo para el ambiente de producción.

Antes de correr la aplicación, el ambiente de producción debe tener instalado [Docker Compose](https://docs.docker.com/compose/install/). (Se puede usar el playbook de Ansible `provisioning/install.yml` para instalarlo.) Además, se deben configurar credenciales de los servicios que se levantan en un archivo `.env` en la raíz del repositorio. Se puede usar el archivo `.env.example` como base.

Una vez configurado todo, se puede desplegar la aplicación localmente con el script `deploy.sh`.

## Agradecimientos

El desarrollo de este sistema de monitoreo fue posible gracias a la ayuda de Martín Inzaurralde de la empresa HG, cuya experiencia en proyectos similares fue un insumo fundamental para el diseño de la arquitectura de la solución.
