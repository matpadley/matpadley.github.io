---
title: "La semana en que Club Monitor se convirtió en un repositorio"
date: 2026-08-22T09:00:00+01:00
draft: false
description: "Siete semanas de trabajo sin confirmar por fin obtuvieron un historial de git, el front end ganó navegación y pantallas reales, el pipeline de OpenAPI se reconstruyó dos veces, y el rol de Super Admin se partió en dos al descubrirse que leía los datos de todos los clubes."
summary: "Siete semanas de trabajo sin confirmar por fin obtuvieron un historial de git, el front end ganó navegación y pantallas reales, el pipeline de OpenAPI se reconstruyó dos veces, y el rol de Super Admin se partió en dos al descubrirse que leía los datos de todos los clubes."
tags:
  - club-monitor
  - weeknotes
  - avalonia
  - dotnet
  - openapi
  - multi-tenancy
  - security
source:
  - 2026-08-19-0930-docs-uno-to-avalonia.md
  - 2026-08-19-1500-fix-browser-session-store-module-path.md
  - 2026-08-19-1630-add-shell-side-nav-burger-menu.md
  - 2026-08-20-1400-cups-header-layout.md
  - 2026-08-20-1500-cups-add-modal.md
  - 2026-08-20-1530-fix-cups-header-grid-not-stretching.md
  - 2026-08-20-1600-cups-list-seeded-from-swagger-model.md
  - 2026-08-20-1600-leagues-members-add-modal.md
  - 2026-08-20-1700-shared-theme-colour-palette.md
  - 2026-08-20-1730-add-swagger.md
  - 2026-08-20-1800-fix-swagger-codegen-path-traversal-false-positive.md
  - 2026-08-20-1900-openapi-typed-responses.md
  - 2026-08-20-1930-fix-swagger-codegen-additionalproperties-bug.md
  - 2026-08-20-1945-no-tests-for-generated-swagger-code.md
  - 2026-08-20-2015-fix-swagger-codegen-jsonconverter-errors.md
  - 2026-08-20-2030-serve-swagger-ui-in-development.md
  - 2026-08-20-2130-migrate-to-builtin-openapi.md
  - 2026-08-21-0830-code-review-and-commit-subagents.md
  - 2026-08-21-0900-initial-import.md
  - 2026-08-21-1030-members-delete-button-and-swipe.md
  - 2026-08-21-1030-screen-builder-subagent.md
  - 2026-08-21-1200-members-edit-button-and-tap.md
  - 2026-08-21-1330-member-edit-page.md
  - 2026-08-21-1500-cups-leagues-edit-and-delete.md
  - 2026-08-21-1630-user-groups-permission-bundles.md
  - 2026-08-21-1800-super-admin-tenancy-boundary.md
  - 2026-08-22-0900-club-self-service-sports-and-creation.md
---

Dos semanas tranquilas y, después, el tramo más intenso que ha tenido el proyecto. Entre el 19 y el
22 de agosto, Club Monitor consiguió su primer commit, un shell de navegación, tres pantallas de
lista funcionales, un pipeline de OpenAPI que se construyó y luego se tiró, y una corrección de
seguridad que desmontó un rol y lo volvió a montar más pequeño.

## Primero, los documentos mentían

El front end de este repositorio lleva tiempo siendo una solución de **Avalonia 12.1.1**. Todos los
documentos de referencia seguían describiendo un proyecto único de **Uno Platform** — y no es un
desajuste cosmético, porque ambos frameworks discrepan en casi todas las API que toca un cambio en
el front end. Cualquiera que leyera `CLAUDE.md` o la especificación habría recurrido a `x:Uid`, a
los archivos `.resw`, a `AdaptiveTrigger` y a
`ApplicationLanguages.PrimaryLanguageOverride`, ninguno de los cuales existe en Avalonia.

Así que la semana se abrió con una reescritura de la documentación: `.resx` y `{x:Static}` en lugar
de `.resw` y `x:Uid`, `ContainerQuery` en lugar de `AdaptiveTrigger`, una biblioteca compartida más
un proyecto por cabeza en lugar de un proyecto único, y `Avalonia.Headless.NUnit` señalado como el
lugar donde viven las aserciones de interfaz.

El detalle traicionero de la localización había que reescribirlo, no traducirlo. Avalonia no tiene
ninguna API de sustitución de idioma a nivel de plataforma, así que la aplicación aplica la suya
estableciendo `CultureInfo.DefaultThreadCurrentUICulture` — tras lo cual la cultura ambiental informa
de la última elección de la aplicación, no de la del sistema operativo. La configuración regional del
sistema debe capturarse al arrancar **antes** de aplicar la sustitución, o se pierde.

Dos documentos más antiguos — el plan multilingüe y una revisión de seguridad de agosto —
deliberadamente **no** se reescribieron. Son registros de un momento concreto de trabajo ya
completado sobre el front end de Uno, y convertir sus casillas marcadas en afirmaciones sobre
Avalonia habría falseado la historia. Cada uno recibió un aviso de sustitución en su lugar.

## Un shell para navegar, y un bug escondido en la precedencia de valores de Avalonia

La aplicación no tenía navegación alguna después del inicio de sesión: entrabas y aterrizabas en una
página de inicio desnuda, sin forma de llegar a nada más. Ahora tiene un shell persistente
Inicio/Miembros/Ligas/Clasificaciones — una barra lateral en anchuras amplias, un botón de
hamburguesa que abre un menú deslizante en las estrechas.

La división se decide **por anchura, nunca por plataforma**. Una `ContainerQuery` a 720px decide, de
modo que el navegador de un teléfono obtiene el diseño de teléfono, y una ventana de escritorio
estrecha también.

Solo que al principio no decidía nada. La barra lateral y la barra superior estaban escritas con
`IsVisible="True"` e `IsVisible="False"` como atributos XAML locales, y la precedencia de valores de
Avalonia sitúa un valor local por encima de cualquier setter de estilo — así que los setters de la
container query no hacían nada en silencio y el diseño no cambiaba a ninguna anchura. La corrección
consistió en mover tanto el valor por defecto como el consultado a setters de `Style`. Fue la prueba
headless escrita para el caso estrecho la que lo cazó, fallando con «Expected False, but was True»
hasta que los atributos locales desaparecieron.

Esa prueba necesitaba un sitio donde vivir, y así llegó a existir `tests/ClubMonitor.UiTests` — el
proyecto al que las reglas llevaban semanas refiriéndose sin que nada lo hubiera creado. También
sacó a la luz un pequeño problema de alcance global: `Avalonia.Headless.NUnit` construye una `App`
nueva por prueba en el mismo proceso, y el estado de conexión de las DevTools es global al proceso,
así que la segunda prueba lanzaba una excepción en `App.Initialize()` hasta que la conexión quedó
protegida tras una bandera estática.

Un bug distinto y más afilado ya había bloqueado por completo la cabeza WebAssembly.
`LocalStorageSessionStore` importaba `"./session-store.js"` y recibía un 404 en
`_framework/session-store.js`, de modo que la aplicación nunca pasaba de `Program.Main`. El
especificador de módulo de `JSHost.ImportAsync` se resuelve respecto a la ubicación del *runtime* —
`_framework/`, donde vive `dotnet.js` — no respecto a la raíz de la aplicación. El `../` inicial es
estructural, y ahora lleva una nota `<remarks>` que lo dice, porque parece exactamente lo que una
limpieza eliminaría.

## Tres pantallas, y el mismo bug de diseño dos veces

Copas, Ligas y Miembros recibieron cada una una cabecera con el título arriba a la izquierda y un
botón «+» arriba a la derecha, un diálogo de añadir y, con el tiempo, acciones de Editar y Eliminar
por fila.

Los diálogos son **superposiciones dentro de la vista**, no `Window`: las cabezas Browser e iOS se
ejecutan bajo ciclos de vida de vista única sin soporte para ventanas hijas, así que un diálogo
basado en `Window` solo funcionaría en escritorio.

El botón «+» pasó un rato pegado al título en lugar de situarse en el borde derecho, pese a un
`Grid ColumnDefinitions="*,Auto"` que debería haberlo empujado allí. La causa era un atributo en un
ancestro: el `StackPanel` de contenido tenía `HorizontalAlignment="Left"`, lo que hace que un panel
se dimensione a su propio contenido en vez de a su `MaxWidth`. El `Grid` de Avalonia da a las
columnas con estrella una anchura efectivamente nula al medir su propio `DesiredSize` — una columna
con estrella se resuelve durante el *arrange*, contra el tamaño final que devuelva el padre — así
que un padre que se encoge hasta su contenido no dejaba nada en lo que la columna con estrella
pudiera expandirse. Quitar la alineación lo arregló sin mover nada visualmente, porque `MaxWidth` ya
dispone un elemento limitado como si estuviera alineado a la izquierda. Hay una prueba de regresión
que comprueba el `Bounds.Right` del botón, verificada: falla en 266 con el marcado antiguo y pasa en
640 con la corrección.

Las acciones de fila llegaron después a las tres listas, y la affordance se elige de nuevo por
anchura — esta vez a **500px, no a 720**. Las listas ocupan el área de contenido del shell, 220px
más estrecha que la ventana allí donde se muestra la barra lateral; a 720, una ventana de escritorio
corriente habría caído en el diseño táctil, y `SwipeGestureRecognizer.IsMouseEnabled` es `false` por
defecto, así que un usuario con ratón no habría tenido forma alguna de eliminar nada.

Las anchuras amplias tienen botones de Editar y Eliminar. Las estrechas tienen un **toque** para
editar y un **deslizamiento a la izquierda** para eliminar, con una línea de ayuda que lo indica.
Tres detalles de los reconocedores de gestos de Avalonia resultaron importantes:

- `SwipeGestureEvent` y `TappedEvent` **burbujean** ambos, de modo que un único manejador en el
  `ItemsControl` ve todas las filas — que es lo que hace esto viable, ya que un `DataTemplate` no
  puede llevar un `x:Name`.
- El reconocedor lanza `SwipeGesture` **repetidamente** mientras el dedo sigue moviéndose, así que
  el manejador registra `SwipeGestureEventArgs.Id` e ignora las repeticiones de un gesto que ya
  atendió.
- `Delta` es *inicio menos actual*, así que una X positiva es un dedo moviéndose hacia la
  **izquierda**. El código lee `SwipeDirection` en su lugar, y una prueba fija la correspondencia
  para que el signo no parezca una errata.

A la tercera copia, se extrajeron dos piezas en vez de triplicarlas: `IEditPage<TItem>`, que permite
a `ShellViewModel.OpenEditPage` gestionar una sola vez abrir, guardar, cancelar y desuscribir, y
`RowGestures<TItem>`, que llevó `MembersView.axaml.cs` de unas setenta líneas de manejador a una
única llamada a `Attach` y regaló el comportamiento a Copas y Ligas.

La edición también salió de una superposición para tener su propia página — con la regla de que **la
lista no navega por sí misma**. `MembersViewModel` lanza `EditMemberRequested`; el shell es dueño de
la transición. Eso mantiene la página comprobable de forma aislada y mantiene el conocimiento de la
navegación en el único view model que ya lo tiene. La página de edición deliberadamente no es un
destino de navegación: `SelectedNavKey` permanece en Miembros mientras está abierta, así que el
resaltado de la barra lateral y el menú de hamburguesa siguen comportándose bien.

Junto a eso, el equivalente a cinco vistas de diccionarios de color casi duplicados se consolidó en
un único `Themes/Theme.axaml` con claves semánticas. No es orden por el orden: las personalizaciones
de marca de un club están especificadas como reemplazos de esas mismas claves a nivel de aplicación,
así que una vista que declara su propia copia es una vista a la que la personalización no llega.

## Un control de localización que hubo que escribir dos veces

Se añadió `LocalizationTests` para comprobar que los archivos `.resx` en inglés, francés y español
se mantienen en paridad. La primera versión pasaba contra una clave francesa rota a propósito, lo
que es una buena razón para sabotear tus propias pruebas antes de confiar en ellas: una búsqueda de
recurso que falla en un satélite **recae en el recurso neutro**, así que una traducción francesa
ausente se muestra en inglés y ninguna prueba que pase por `ResourceManager` puede verlo.

La versión que funciona compara los archivos `.resx` como archivos, conjunto de claves contra
conjunto de claves. Repetida contra el mismo sabotaje, nombra tanto la clave sin traducir como la
mal escrita.

## El pipeline de OpenAPI, construido y luego sustituido

Este fue el hilo más largo de la semana, y terminó en un sitio distinto de donde empezó.

Empezó con Swashbuckle y un esquema de seguridad JWT bearer, restringido a Development — una
instancia desplegada que describe sus propias rutas y DTO es exactamente el detalle interno del que
se mantiene deliberadamente libre el endpoint anónimo `/health`.

Después, una pregunta sobre si un handler necesitaba un view model aparte destapó algo sistémico: el
cliente generado producía `public void ApiMembersGet()` para todas y cada una de las rutas, porque
ningún endpoint declaraba metadatos de respuesta de OpenAPI. Cada ruta de Minimal API en los ocho
archivos de endpoints recibió `.WithName()`, `.WithTags()` y una extensión
`ProducesHandlerResult<T>()` que declara el esquema de éxito más un `ErrorResponse` con nombre para
400/401/403/404/409. Etiquetar por funcionalidad además dividió la salida generada, que pasó de una
única clase de unas 8.600 líneas a una clase por funcionalidad. Las dos rutas de redirección
pensadas para la navegación del navegador se excluyeron por completo de la descripción — un método
de cliente generado que las llamara se limitaría a seguir la redirección.

Después empezó a fallar el propio generador, tres veces seguidas:

1. **Un falso positivo de path traversal.** El fork incorporado de swagger-codegen rechaza cualquier
   ruta que contenga `..`, y el propio argumento `-o ../club_monitor/...` del script lo activaba. Se
   corrigió canonizando el directorio de salida donde se almacena el argumento de línea de comandos
   — no debilitando la comprobación de traversal, que es una protección legítima frente a nombres de
   archivo derivados de la especificación que se escapen durante la generación.
2. **`Dictionary<String, >` en 44 de los 46 modelos generados.** Todo record sobre el que Swashbuckle
   hace reflexión obtiene `additionalProperties: false`, y la plantilla de C# del generador emite un
   tipo base `Dictionary` en cuanto `additionalProperties` está presente — dejando en blanco el
   argumento genérico cuando no hay esquema con el que rellenarlo. Como nada en la base de código
   valida los cuerpos de petición contra su esquema JSON, la bandera era informativa, y un
   transformador de esquema que la suprimiera no costaba nada.
3. **Una avalancha de referencias a `JsonConverter` sin resolver.** El proyecto generado emitía una
   disposición heredada de `.NET Framework 4.5` + `packages.config` cuyo `HintPath` apuntaba a una
   carpeta que nadie restaura. Cambiar el generador a salida de estilo SDK lo arregló, junto con un
   `Directory.Packages.props` local que ensombrece al del repositorio — la gestión centralizada de
   paquetes de NuGet usa el archivo **más cercano** subiendo por el árbol y no los fusiona, así que
   un subárbol con versiones en línea necesita el suyo propio.

Por el camino entró una regla en `CLAUDE.md`: **nunca escribir pruebas para el cliente generado**.
Ese árbol se regenera íntegramente en cada ejecución — ocurrió dos veces en una tarde — así que unas
pruebas escritas a mano contra él solo reafirmarían la salida del generador y acabarían sobrescritas
en silencio.

Y luego salió toda la capa de Swashbuckle. ASP.NET Core 10 incluye un generador de OpenAPI propio,
así que `AddOpenApi`/`MapOpenApi` sustituyó a `AddSwaggerGen`, Scalar sustituyó a la interfaz de
Swagger como explorador exclusivo de Development, y el filtro de esquema se portó a un
`IOpenApiSchemaTransformer`. El esquema bearer pasó a ser un transformador de documento activado por
inyección de dependencias que descubre el esquema JWT registrado mediante
`IAuthenticationSchemeProvider`. `Microsoft.OpenApi` se fijó explícitamente en 2.12.0, porque la
versión que llega de forma transitiva tiene un aviso conocido de gravedad alta (desbordamiento de
pila por referencias circulares de esquemas).

El resultado es un documento OpenAPI 3.1.1 con 48 esquemas, un esquema bearer aplicado a cada
operación, y una compilación limpia sin avisos de paquete vulnerable.

## El repositorio por fin tuvo un repositorio

La mañana del día 21, `git log` seguía fallando con una rama sin nacer y sin HEAD. Todo lo descrito
arriba, y todo lo de las siete semanas anteriores, existía únicamente en el disco.

La importación inicial confirmó los 545 archivos como primer commit, tras volver a comprobar que
`.gitignore` excluía la salida de compilación y que ningún `.pfx`, `.env`, perfil de publicación o
`secrets.json` se había preparado para el commit. Como el hook de seguridad de git del repositorio
deniega los commits directamente sobre `main` o `master` — y todavía no había un `main` del que
ramificar — la importación fue a una rama creada desde el HEAD sin nacer.

Por esas mismas fechas se escribieron tres subagentes de proyecto, para que la revisión y el
aterrizaje fueran pasos separados y con alcance explícito: un `code-reviewer` de solo lectura que
lleva como lista de comprobación las trampas concretas de este repositorio, un `change-committer`
que aplica los hallazgos y abre la PR sin sortear los hooks de git, y un `screen-builder` que conoce
los ocho sitios que toca añadir una pantalla — donde lo que se olvida es el cableado, no la vista.

## Y después el modelo de autorización se reconstruyó, dos veces en dos días

La pertenencia tenía exactamente dos roles, `Standard` y `Admin`, así que un club solo podía decir
«todo» o «nada». Un club que quisiera un tesorero tenía que ceder también la personalización, las
competiciones, los miembros y la suscripción.

La primera respuesta fueron los grupos de usuarios: siete permisos, concesiones en una tabla hija en
vez de una máscara de bits para que sigan siendo legibles en las migraciones, y la pertenencia al
grupo apuntando a `Membership` en lugar de a `User` — de modo que un grupo solo significa algo dentro
de su propio club, sacar a alguien de un club se lleva sus concesiones, y «un usuario del club B en
un grupo del club A» es irrepresentable.

Lo que merece la pena registrar es lo que **no** cambió. La petición era algo que funcionara con
passkeys y autenticación de terceros tanto como con contraseñas, y **no cambió ni una línea del
código de inicio de sesión**. Todas las rutas — contraseña, proveedor externo, passkey, ambos
remates del doble factor, registro, selección de club — desembocan en una única fábrica donde se
acuña el token, y ese token lleva el sujeto, el club activo, el sello de seguridad y la finalidad.
Ningún rol. Ningún permiso. La autoridad ya se resolvía en el servidor en cada petición, así que los
grupos heredaron gratis la independencia respecto a las credenciales. El trabajo consistía en
*preservar* esa propiedad, que ahora una nueva clase de pruebas fija de tres maneras.

Al día siguiente resultó que algo mucho más grave llevaba tiempo alojado en una sola línea.

`TenantContext.BypassTenantFilter` estaba definido como `=> IsSuperAdmin`. El rol de plataforma y
«leer las filas de todos los clubes» eran, por tanto, la misma propiedad — de modo que un Super
Admin podía leer la plantilla, las competiciones, los partidos y los resultados de cualquier club.
No es para lo que existe el rol. Un Super Admin gestiona la parte comercial de los clubes alojados
en un dominio multiinquilino: suscripción, dominio, funcionalidades. Si un club está en el dominio
principal, el Super Admin no debería ver más que su **nombre**.

Ahora las dos propiedades están separadas. `IsSuperAdmin` es el rol de plataforma, que concede
alcance de configuración sobre los clubes de un dominio de inquilino y ningún alcance sobre los
datos, en ninguna parte. `BypassTenantFilter` elimina todos los filtros de inquilino y **solo** lo
activa el mantenimiento sin ninguna persona detrás — siembra de datos, migraciones, pruebas. Nada
alcanzable desde una petición HTTP lo activa.

Otros cuatro puntos concedían cada uno por su cuenta alcance a los Super Admins y tuvieron que
seguir el mismo camino: el guardián de permisos y el guardián de administración de competiciones
dejaron de devolver verdadero para el rol, los datos de siembra ganaron un club en el dominio
principal al que apuntan las pruebas de privacidad, y el filtro de consulta de competiciones ganó
una cláusula explícita `IsSuperAdmin && ClubId == null`.

Esta última sacó a la luz un bug latente que merece nombrarse. Dejar que las competiciones de ámbito
de plataforma se emparejen con `c.ClubId == tenant.ClubId` depende de que un null case con otro
null — algo que resulta cierto con el proveedor InMemory que usan las pruebas, y nunca en SQL, donde
`NULL = NULL` es desconocido. Un bug de corrección dependiente del proveedor, encontrado solo porque
se estaba reescribiendo el código de alrededor.

Un nuevo DTO hace la fuga irrepresentable en vez de meramente comprobada: todos los campos de
configuración son nullables y todos valen null para un club del dominio principal, y el tipo no
lleva miembros, ligas, copas ni clasificaciones de ninguna forma, para ningún club. Las
competiciones de ámbito de plataforma ahora rechazan de plano a los clubes del dominio principal,
puesto que una competición así expone necesariamente los jugadores inscritos de un club.

## Con lo que quedaban dos preguntas, resueltas el sábado

Si la plataforma no puede ver a los miembros de un club, ¿por qué decide qué deportes practica ese
club? Y ¿por qué no puede existir un club sin que la plataforma lo cree?

Ambas cosas pasaron al club. La asignación de deportes se convirtió en un permiso de club — uno real
esta vez, cuando antes se había eliminado precisamente *porque* estaba reservada al Super Admin, lo
que la convertía en un permiso que un club podía conceder y que aun así sería rechazado. El catálogo
sigue siendo propiedad de la plataforma: un club elige qué deportes practica, no puede inventarse
uno del que la plataforma nunca ha oído hablar.

La creación de clubes pasó a estar disponible para cualquier usuario autenticado, que se convierte
en el primer Admin del club, en el dominio principal — lo que resuelve la anomalía por la que un
Super Admin creaba un club y acto seguido no podía configurarlo.

El handler que asigna un deporte necesitaba una comprobación que antes no usaba: recibe un
identificador de club en el cuerpo de la petición, lo cual era inofensivo cuando solo un Super Admin
podía llamarlo, y se convierte en un agujero entre inquilinos en cuanto quien llama tiene un permiso
acotado a un club. Ahora el club del cuerpo se contrasta con el del token, con una prueba nombrada
exactamente para eso. Y `CreateClubRequest` perdió su campo `InitialAdminUserId` — dejar que quien
llama designe al primer Admin permitiría a cualquiera convertir a un desconocido en Admin de un club
que nunca pidió, y un primer Admin puede invitar y promocionar. Eliminar el campo lo hace
irrepresentable en lugar de meramente validado.

La semana terminó con 268 pruebas de API y 181 de front end, todas en verde.
