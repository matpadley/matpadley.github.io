---
title: "La semana en que el front end empezó a hablar con la API"
date: 2026-08-28T11:00:00+01:00
draft: false
description: "Un motor de permisos se eliminó una semana después de construirse, nueve pantallas pasaron a un único sistema de diseño, la aplicación consiguió una pila de contenedores e integración continua, y el inicio de sesión por fin llamó a una API real — donde Safari lo bloqueó por un motivo que solo parecía CORS."
summary: "Un motor de permisos se eliminó una semana después de construirse, nueve pantallas pasaron a un único sistema de diseño, la aplicación consiguió una pila de contenedores e integración continua, y el inicio de sesión por fin llamó a una API real — donde Safari lo bloqueó por un motivo que solo parecía CORS."
tags:
  - club-monitor
  - weeknotes
  - avalonia
  - dotnet
  - docker
  - github-actions
  - design-system
source:
  - 2026-08-24-1300-remove-user-groups-and-enforce-platform-features.md
  - 2026-08-24-1600-development-role-sign-in.md
  - 2026-08-26-1500-friendlier-sign-in-screen.md
  - 2026-08-26-1730-shared-control-styles-across-every-screen.md
  - 2026-08-27-0740-land-friendlier-login-branch.md
  - 2026-08-27-1030-club-admin-gates-on-members-leagues-cups.md
  - 2026-08-27-1450-login-page-register-link.md
  - 2026-08-27-1730-create-club-only-shell-for-new-accounts.md
  - 2026-08-27-1924-github-actions-build-and-test-workflows.md
  - 2026-08-27-1945-dev-api-endpoint-and-container-stack.md
  - 2026-08-27-2015-compose-migrate-service.md
  - 2026-08-27-2040-verify-compose-stack.md
  - 2026-08-28-1035-front-end-auth-calls-the-api.md
  - 2026-08-28-1100-browser-head-served-over-http.md
---

La semana anterior terminó con un motor de permisos, una frontera de multiinquilino redibujada y un
front end que no podía iniciar sesión en nada. Esta semana borró lo primero, conservó lo segundo y
por fin cerró la brecha de lo tercero — la aplicación ya crea cuentas reales contra una API real que
corre en un contenedor.

## Borrar una funcionalidad tres días después de construirla

Los grupos de usuarios se fueron. La autorización de club vuelve a tener dos roles: `Admin` y
`Standard`, con Super Admin como rol exclusivo de plataforma, sin vínculo con ningún club.

Lo decidieron dos cosas. La primera es un argumento de diseño directo — una liga de club tiene uno o
dos administradores, y un Admin de club ya tenía todos los permisos de forma implícita, así que los
paquetes resolvían un problema de delegación que este producto no tiene. Las pantallas del front end
funcionaban con filas de marcador de posición codificadas a mano y nada las consumía.

La segunda merece recordarse. **`ManageGroups` era una vía de autoescalada.** Un miembro Standard con
solo `ManageGroups` podía editar su propio grupo para añadir `ManageAdmins` y después ascenderse a
Admin de club — echando por tierra todo el sentido de «darle autoridad sin convertirlo en Admin». Un
motor de permisos cuya concesión más débil reconstruye el rol más fuerte no es un modelo más fino, es
el mismo modelo con pasos de más.

Lo que se conservó, por ser independiente de los grupos: la frontera de multiinquilino del Super
Admin, los dominios de inquilino, las funcionalidades de club y el autoservicio de club. La regla
que ahora queda escrita es que si algún día un club necesita de verdad una delegación más fina, la
respuesta es un rol con nombre, no un motor de permisos.

El mismo repaso hizo **reales los interruptores de funcionalidades de plataforma**. Existían, pero
el método que los comprueba no tenía ningún llamador fuera de su propia prueba — de modo que un
Super Admin podía desactivar Competiciones para un club alojado, recibir un `200` y no cambiar nada.
Ahora hay controles al crear una liga o copa, al inscribir jugadores, al programar partidos, al
registrar resultados, al leer una tabla de clasificación, en cada escritura de personalización y al
unirse a una competición de ámbito de plataforma.

Dos detalles sobre cómo se leen esos rechazos:

- El guardián de competiciones devuelve un **veredicto** — `Allowed`, `NotAdmin` o
  `FeatureDisabled` — en lugar de un booleano, así que una funcionalidad desactivada informa
  `FeatureNotEnabled` en vez de «no eres administrador». Decirle a un Admin de club legítimo que le
  falta autoridad lo manda a cazar un problema de permisos que no existe.
- **La clasificación se controla contra el club dueño de la competición**, no contra el de quien
  llama, para que la regla siga valiendo para un lector público sin club propio cuando llegue la
  publicación anónima.

## Iniciar sesión como alguien, antes de que hubiera alguien

Nada que dependiera del rol podía verse ni demostrarse, porque el servicio de autenticación de
relleno aceptaba cualquier credencial y acuñaba una sesión sin rol alguno. Así que la página de
inicio de sesión recibió un panel de **Development sign-in**: una identidad falsa por rol; al pulsar
una se acuña una sesión localmente y se enruta al shell exactamente igual que un inicio de sesión
real.

Es el tipo de comodidad que llega a producción por accidente, así que las salvaguardas están
deliberadamente en capas:

- Todas las identidades y la bandera `IsEnabled` viven dentro de un `#if DEBUG`. Una compilación
  Release no contiene identidades de prueba, y la lista vacía repliega el panel.
- El comando **vuelve a comprobar `IsEnabled`** en lugar de fiarse de que el panel estuviera oculto,
  de modo que a una compilación Release no se la puede convencer de abrir una sesión falsa
  invocándolo directamente.
- El token de acceso es el centinela `development-sign-in-not-issued-by-the-api` — sin forma de JWT,
  rechazado por la API, así que una sesión de desarrollo solo alcanza pantallas dibujadas con datos
  locales.
- Una prueba de salvaguarda vuelve a leer el archivo fuente **como texto** y falla si una identidad
  sale del guardián. Una ejecución de pruebas es en sí una compilación Debug, así que el
  *comportamiento* Release no puede ejecutarse — solo puede comprobarse el guardián que lo produce.
  Verificado también a mano: las direcciones falsas aparecen tres veces en el ensamblado Debug y
  cero veces en el Release.

La sesión ganó `Role` e `IsSuperAdmin` como dos campos separados a propósito. Super Admin es un rol
de plataforma que se ostenta fuera de cualquier club, así que esa identidad lleva un rol de club
nulo — juntarlos en un solo campo habría recreado la confusión que la semana anterior costó un día
desenredar.

## La aplicación dejó de parecer un formulario

La pantalla de inicio de sesión era una columna centrada de controles Fluent sin estilo, y era lo
primero que veía cualquiera. Se convirtió en una composición de dos partes: un panel de marca oscuro
con el nombre de la aplicación, un titular y marcas de campo dibujadas, junto al formulario de
acceso.

Elegido por anchura, nunca por plataforma — una `ContainerQuery` a 720px, coincidiendo con el propio
punto de ruptura del shell. Por encima, el panel de marca es una columna anclada a la izquierda; por
debajo, el mismo material se pliega en una banda de cabecera sobre el formulario.

Algunas decisiones en el detalle:

- El escudo y los iconos de ojo y ojo tachado son recursos `StreamGeometry` dibujados en la vista,
  no imágenes, de modo que se recolorean con el tema y se mantienen nítidos a cualquier densidad.
- Las marcas de campo están ancladas al centro y a los bordes del propio panel en vez de a
  coordenadas fijas, así que conservan sus proporciones a cualquier altura de ventana.
- La revelación de la contraseña es **una única caja enmascarada cuyo carácter de máscara cambia** —
  Avalonia trata `'\0'` como «no enmascarar» — en lugar de una segunda caja con una copia en claro
  de la contraseña. Al iniciar sesión se vuelve a enmascarar, para que una contraseña revelada no
  quede en pantalla para quien llegue después.
- El aviso de invitación dice que las cuentas empiezan con una invitación de un administrador de
  club, que es el modelo real de cuentas, en lugar de un enlace de «registrarse» a un flujo que no
  existía. (Existió el jueves. Más abajo.)

Dos días después ese tratamiento alcanzó a las otras nueve pantallas — y lo importante es que el
sistema se **extrajo, no se replicó**. La pantalla de acceso había declarado sus estilos en su propio
bloque `UserControl.Styles`, lo cual está bien para una pantalla y mal para nueve: las
personalizaciones de marca de un club aterrizan como reemplazos de las claves de pincel compartidas,
así que un estilo que fija sus valores a mano es una pantalla a la que la personalización no llega.
Todos los estilos de control y todas las geometrías de icono se movieron a `Themes/Controls.axaml`,
fusionado **después** de `FluentTheme` porque una colección de estilos se aplica en orden y estas
reglas existen para ganar a las de Fluent. Fluent pinta los estados de un botón en su
`ContentPresenter` interno, no en el botón, así que todo lo que deba sobrevivir al paso del puntero
se establece a través de la parte de la plantilla.

Después, veinte declaraciones `Opacity="0.7"` repartidas por nueve archivos pasaron a ser una clase
`muted`. La opacidad atenuaba el elemento *y* lo que se veía a través de él, así que la misma línea
secundaria se leía distinta sobre una tarjeta de fila que sobre el fondo de página. Ocho copias de un
encabezado de 28px seminegrita pasaron a `pageTitle`; diez cajas de texto tomaron una clase `field`;
los valores de solo lectura recibieron su propia clase para que un valor que nadie puede cambiar deje
de parecer uno que alguien olvidó terminar.

Vinieron con ello dos salvaguardas. Una prueba estática falla ante cualquier vista que atenúe texto
con `Opacity`, declare un color hexadecimal literal o fije un tamaño de fuente de display — un fallo
se arregla añadiendo la clase que falta, no borrando la aserción. Y una prueba de hoja de renderizado
dibuja cada pantalla a PNG a 1200px y 390px con píxeles reales de Skia, algo que se ganó su sitio de
inmediato: así se cazaron las tarjetas de fila que dejaban espacio muerto bajo contenido alineado
arriba.

## Un control que en realidad nunca se cerró

`CupsViewModel` tenía una propiedad `IsClubAdmin`, y solo era alcanzable desde XAML, y solo en
parte. Los botones de fila enlazaban `IsVisible="{Binding IsClubAdmin}"` dentro de un `DataTemplate`
— que enlaza contra el elemento de la fila, no contra el view model de la página, así que no resolvía
nada. Los enlaces compilados no están activados en este proyecto, de modo que fallaba **en silencio
en tiempo de ejecución** y no en compilación, y los botones se mostraban para todo el mundo.

Corregir el enlace tampoco habría bastado. Un `IsVisible` local gana al setter de estilo, así que un
enlace por botón habría anulado la container query de 500px que oculta esos botones en diseños
estrechos. Y el diseño estrecho llega a editar y eliminar mediante toque y deslizamiento, donde no
hay ningún botón que ocultar — así que un control puramente visual deja ambas rutas abiertas de par
en par.

El control vive ahora en dos sitios a propósito: en el *contenedor* de acciones de fila en XAML,
alcanzando el view model de la página mediante `$parent[ItemsControl]` y dejando a la container
query al mando de los botones en sí, y en los comandos del view model, que es lo que cierra las
rutas gestuales. Super Admin deliberadamente no es una vía de entrada — un rol nulo se lee como no
administrador, con una prueba por view model que lo fija.

## Una cuenta, un club, y dónde ponerlos

La API admitía el autorregistro desde que llegó su handler de registro, y cualquier usuario
autenticado podía crear un club y convertirse en su primer Admin. El front end no alcanzaba ninguna
de las dos cosas: la única ruta hacia una cuenta era una invitación sobre la que la aplicación no
podía actuar.

El registro llegó con una página detrás del enlace — nombre visible, correo, contraseña,
confirmación y un código de invitación opcional. Un único botón de revelar gobierna ambas cajas de
contraseña, porque una confirmación que el usuario no puede leer no confirma nada. El decorado de
marca se trasladó a dos vistas compartidas y sin contexto de datos para que el registro luzca el
mismo material sin una segunda copia.

Importaron dos detalles del contrato. `RegisterAsync` devuelve un resultado de inicio de sesión,
porque la API autentica directamente una cuenta recién creada — así que el éxito termina donde
termina un inicio de sesión, en vez de devolver al usuario a reescribir las credenciales que acaba
de elegir. Y una caja de invitación vacía se envía como `null`, no como `""`, porque la API
interpreta un código presente pero vacío como uno suministrado y erróneo.

Lo cual creó de inmediato un problema nuevo: registrarse crea una cuenta, no una pertenencia, así
que un usuario recién llegado aterrizaba en una aplicación de cinco secciones sin nada detrás de
ninguna. El shell ahora construye **solo** una página de Crear club para una sesión así, la convierte
en la única entrada tanto de la barra lateral como del menú de hamburguesa, y **rechaza las secciones
de club en `Navigate` además de ocultarlas** — ocultar un botón no es lo mismo que cerrar una ruta.

La página empieza por el mensaje y no por el formulario: una bienvenida con el nombre del usuario y
después qué falta y por qué. Con el resto de la navegación ausente, «¿por qué falta todo?» es la
primera pregunta que la pantalla tiene que responder. El deporte se elige del catálogo maestro en
lugar de escribirse, porque la API recibe un *identificador* de deporte, y el selector distingue
«todavía cargando» de «nada que mostrar».

Crear un club convierte a su creador en el primer Admin, así que el shell lanza una sesión
actualizada y todo el shell se reconstruye a su alrededor — que es lo que pone en pantalla el resto
de la navegación.

## CI, contenedores y un paso de migración que no es un paso de arranque

Aterrizaron dos workflows de compilación y pruebas, uno por cada mitad del repositorio, ambos sobre
pull requests hacia `main` y ambos filtrados por rutas. Deliberadamente no hay disparador `push`:
todo cambio llega a `main` mediante una PR, así que una ejecución disparada por push solo duplicaría
la que la PR ya tuvo.

Nombran archivos de proyecto concretos en vez de la solución, porque la solución también lleva las
cabezas de iOS y Android — iOS necesita un runner de macOS con un Xcode compatible, y Android no es
un objetivo soportado. La suite de interfaz corre en **Debug a propósito**: las identidades de
desarrollo están tras `#if DEBUG`, y las pruebas que las cubren también. La mitad Release de esa
salvaguarda la cubre la compilación Release de la cabeza de escritorio en el mismo job. La cabeza de
navegador se **publica**, no solo se compila, porque el SDK de WebAssembly hace su empaquetado y su
reenlazado nativo en tiempo de publicación — y la salida publicada es exactamente lo que servirá App
Service.

Una nota para más adelante: como ambos workflows usan filtros de rutas, una PR solo de documentación
no ejecuta ninguno. Si se convierten en comprobaciones obligatorias, una ejecución filtrada se
informa como omitida y puede bloquear la PR.

En paralelo, el front end por fin aprendió dónde está su API. `ApiConfiguration.BaseUrl` resuelve
primero una constante compilada, luego el entorno del proceso (solo escritorio) y después un
localhost por defecto — y el entorno no puede ser la única fuente, porque un proceso de iOS no
hereda nada del entorno del shell que lo lanza y el navegador no tiene entorno de sistema operativo
en absoluto. Un objetivo de MSBuild escribe la constante desde `CLUBMONITOR_API_URL` en tiempo de
compilación.

Dos detalles de MSBuild costaron una compilación cada uno y ahora están comentados en su sitio. Un
atributo `Include` reconoce comodines, así que `public const string? Url` — que contiene un `?` — se
leyó como un comodín de un carácter que no coincidía con ningún archivo, y la línea desapareció de la
salida generada sin ningún aviso. Y `IntermediateOutputPath` no está definido hasta que se ejecutan
los objetivos comunes, así que calcularlo en el cuerpo del proyecto dejaba el archivo generado en el
directorio del proyecto, donde el glob por defecto lo compilaba una segunda vez.

La API recibió una pila de contenedores: SQL Server, la API y — tras replantearlo — las migraciones
como servicio propio. La primera versión hacía que la API migrara sola al arrancar, tras un
interruptor exclusivo de Development, porque la imagen de ejecución no lleva SDK. Funcionaba, pero
metía el paso de esquema en la ruta de arranque de la API: una migración fallida se manifestaba como
una API que no arranca en lugar de como un paso con su propio código de salida, y la imagen enviada
*podía* migrar una base de datos, a una variable de entorno de hacerlo donde no debía.

Ahora un servicio `migrate` de un solo uso ejecuta un bundle de migraciones de EF y termina, y la API
depende de él con `condition: service_completed_successfully`, de modo que una migración fallida
detiene la pila en vez de entregar una API sobre un esquema a medio construir. La cadena de conexión
es un ancla de YAML compartida por ambos, así que lo que migra y lo que lee no pueden desviarse a
bases distintas. El código de migración al arranque se **borró** en lugar de desactivarse — la
salvaguarda es la ausencia de la ruta de código, no una comprobación de entorno sobre ella.

Aquellas dos entradas terminaban ambas con «no verificado», porque Docker no estaba en marcha cuando
se escribieron. Desde entonces la pila se ha ejercitado de extremo a extremo: SQL llega a estado
saludable, `migrate` se ejecuta y sale con 0, y solo entonces arranca la API; se aplican las ocho
migraciones; una segunda ejecución informa «No migrations were applied» y sale con 0; hay veinte
tablas en la base de datos según `sqlcmd`, no solo según el registro. Y la ruta de fallo — la razón
de ser del servicio — sale con 1 con una contraseña deliberadamente incorrecta, reteniendo a la API.

## Y entonces inició sesión de verdad

`ApiAuthenticationService` sustituyó al servicio de relleno en todas las cabezas. El inicio de sesión
y el registro ahora publican contra los endpoints reales en la URL base compilada.

Ambos endpoints responden con la misma forma, así que ambos pasan por un único lector de respuesta;
las diferencias entre iniciar sesión y registrarse viven en la API. La sesión se construye a partir
de la respuesta en lugar de darse por supuesta — el rol almacenado es el que se ostenta en el club al
que el token está **acotado**, no el primer club de la lista, porque un usuario en dos clubes puede
tener un rol distinto en cada uno y el token solo autoriza en uno de ellos. Una cuenta sin club
obtiene un rol nulo, que es lo que deja al shell sobre su único apoyo de crear un club.

Nada lanza una excepción en un botón de inicio de sesión. Todo fallo vuelve como un resultado con un
código: el propio código de error estable de la API cuando respondió, y cuatro que este cliente
levanta cuando no pudo preguntarle — `NetworkUnavailable`, `TooManyAttempts` para un 429 que el
limitador de tasa responde sin cuerpo, `UnexpectedResponse` para un cuerpo que no se pudo analizar o
un 200 al que le falta algo que una sesión necesita, y `TwoFactorRequired`. La cancelación propia de
quien llama sigue propagándose, porque salir de una pantalla no es una credencial rechazada.

El doble factor se **informa, no se completa**. Una contraseña correcta en una cuenta con doble
factor produce un token pendiente y ningún token de acceso, y todavía no hay pantalla donde
presentar el desafío, así que aflora como un error legible en lugar de como una sesión que no
existe.

Del cableado cayó un bug discreto: el view model de inicio de sesión mapeaba un código de error que
la API nunca ha enviado, así que una contraseña incorrecta habría mostrado el genérico «algo ha ido
mal» en lugar de «credenciales incorrectas».

## Y entonces Safari se negó, por un motivo que no era CORS

Pulsar **Sign in** en la cabeza WebAssembly fallaba en Safari con:

```
Fetch API cannot load http://localhost:5239/api/auth/login due to access control checks.
```

Eso se lee como CORS, y no lo es. La política se verificó contra el contenedor en marcha desde ambos
orígenes — el preflight devuelve `204` con las cabeceras de permiso correctas, y un `POST` real
obtiene una respuesta JSON normal con las cabeceras CORS adjuntas.

El bloqueo real es **contenido mixto**, en el cliente, antes de que la petición llegue a enviarse. El
perfil de lanzamiento de la cabeza de navegador abría `https://localhost:7169` primero, y el endpoint
de API compilado en la cabeza es `http://localhost:5239`. La especificación Secure Contexts trata
`http://localhost` como potencialmente fiable y Chrome lo exime del bloqueo de contenido mixto;
WebKit no, e informa del rechazo con su redacción genérica de «access control checks». Nada llega a
Kestrel, así que ningún cambio en el servidor podría haberlo arreglado.

La solución es servir la cabeza de navegador por **http** — `http://localhost:5235` va ahora primero
en el perfil de lanzamiento. Es una solución y no un apaño: la API no tiene listener https en la
pila local, `http://localhost` sigue siendo un contexto seguro en todos los navegadores, así que las
passkeys y el resto de rutas de inicio de sesión funcionan allí, y la alternativa habría sido https
en ambos lados sin ganancia alguna.

La semana terminó con 255 pruebas de API y 280 pruebas de interfaz headless en verde, una aplicación
que crea cuentas reales contra una API en contenedor, e integración continua ejecutando ambas suites
en cada pull request.
