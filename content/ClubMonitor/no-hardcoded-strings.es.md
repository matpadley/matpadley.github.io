---
title: "Sin Cadenas Codificadas a Mano: Localizar un Front End de Uno Platform"
date: 2026-08-01T09:00:00+01:00
draft: false
description: "Una traducción ausente recurre en silencio al inglés, así que una compilación en verde no prueba nada. Las garantías tenían que ser lints, y probar una interfaz que se dibuja entera en un solo canvas obligó a comprobar la cultura guardada y los píxeles en lugar del texto."
summary: "Una traducción ausente recurre en silencio al inglés, así que una compilación en verde no prueba nada. Las garantías tenían que ser lints, y probar una interfaz que se dibuja entera en un solo canvas obligó a comprobar la cultura guardada y los píxeles en lugar del texto."
tags:
  - club-monitor
  - uno-platform
  - localization
  - xaml
  - playwright
  - testing
  - ci
source:
  - "2026-07-31-1700-multilingual-phase-4-frontend-groundwork.md"
  - "2026-07-31-1800-multilingual-phase-5-pages-off-hardcoded-strings.md"
  - "2026-07-31-1900-multilingual-phase-6-tests-and-ci.md"
  - "2026-08-01-0900-multilingual-phase-7-documentation.md"
---

Una vez que el contrato de fallos de la API pasó a ser legible por máquina, la mitad interesante del trabajo multilingüe se trasladó al front end de Uno Platform. Ese trabajo tuvo tres partes: decidir en qué idioma debe mostrarse la aplicación, sacar del marcado cada cadena visible para el usuario y encontrar algo capaz de detectar realmente una traducción que falta.

## Decidir qué idioma mostrar

El orden de negociación es corto, pero cada cláusula se gana su sitio:

1. Una anulación explícita en el dispositivo, si existe.
2. Si no, la configuración regional del sistema, ajustada a una cultura admitida.
3. Si no, inglés.

Al iniciar sesión, un dispositivo que aún no tiene anulación adopta el `PreferredLanguage` guardado en la cuenta, pero una anulación existente nunca se sustituye en silencio. El selector de la aplicación escribe la anulación de inmediato y sincroniza la cuenta en la medida de lo posible.

El ajuste importa más de lo que parece. Un dispositivo configurado como `fr-CA` o `es-419` debe obtener francés o español, no caer hasta el inglés porque la etiqueta regional exacta no esté en el conjunto admitido. `SupportedCultures.Clamp` reduce una etiqueta regional a su idioma antes de rendirse.

Dos detalles de implementación son fáciles de errar. **La cultura se aplica antes de que exista la primera ventana** —`CultureService.Initialize()` es la primera línea de `OnLaunched`— y **cambiar de idioma reconstruye la raíz de la aplicación**, porque las búsquedas de recursos se resuelven a medida que se construyen los visuales. Establecer solo `PrimaryLanguageOverride` deja en el idioma anterior todo lo que ya está en pantalla. El shell ya reconstruía la raíz al cambiar de tema y recordaba la página actual al hacerlo, de modo que un cambio de idioma reutiliza exactamente esa ruta y el usuario se queda donde estaba.

Algo deliberadamente no construido: una pregunta al iniciar sesión sobre qué prevalece cuando la anulación del dispositivo y el idioma de la cuenta no coinciden. La especificación dice que la anulación del dispositivo siempre gana y que el inicio de sesión nunca la sustituye en silencio. La mitad de un inicio de sesión es mal sitio para plantear una pregunta cuya respuesta la especificación no necesita.

## Sacar las cadenas del marcado

Los archivos de recursos pasaron de una sola entrada a 142 por cultura. La mayor parte es la porción mecánica: un `x:Uid` en cada control, a lo largo de la pantalla de inicio de sesión, el panel, los miembros, las ligas, las clasificaciones y el perfil de jugador.

Otra parte no es mecánica en absoluto, y ahí es donde vive de verdad la localización:

- **Texto elegido en tiempo de ejecución.** Los mensajes del doble factor, los fallos de passkey, el saludo según la hora del día, un título de clasificación construido a partir de una cadena de formato: `x:Uid` no puede expresar nada de eso. Pasan por una búsqueda de `LocalizedStrings`. Los mensajes dinámicos de la pantalla de inicio de sesión vivían enteramente en el code-behind, del que la regla «sin literales en XAML» no dice nada.
- **Valores de enumeración que llegan de la API.** Roles, estados, tipos de competición, visibilidad y estado de partido llegan por la red como nombres de enumeración en inglés: `Admin`, `Active`, `League`, `Public`, `Scheduled`. Son datos, no literales, así que un barrido del marcado nunca los toca. Dejados como están, mantienen las listas de Miembros y Ligas visiblemente en inglés en una pantalla por lo demás francesa. `EnumLabels` los traduce, y un valor no reconocido se muestra tal cual, de modo que un miembro de enumeración nuevo que la aplicación no conoce degrada a inglés en lugar de a una etiqueta en blanco.
- **Texto entre etiquetas de elementos.** La línea del enfrentamiento eran dos elementos `Run` en línea con un ` vs ` literal entre ellos. `x:Uid` no puede alcanzar un nodo de texto desnudo, y codificar el separador a mano codifica también el orden de las palabras, que le corresponde al traductor. `Match_Fixture` es `{0} vs {1}`, de modo que un idioma que lo ordene de otra forma puede hacerlo.
- **Encabezados de columna abreviados.** `P/W/D/L` en la tabla de clasificación no es cosmético: pasa a ser `J/G/N/P` en francés y `PJ/G/E/P` en español.

El selector de idioma muestra English / Français / Español como endónimos, cada uno en su propio idioma y en todas las culturas, como es convención en los selectores de idioma. Los comentarios de los recursos lo indican de forma explícita, porque valores idénticos en tres culturas parecen, si no, exactamente una traducción que falta.

## Lo único que detecta una traducción ausente

Un recurso ausente en una cultura recurre en silencio al idioma predeterminado en tiempo de ejecución. La aplicación parece perfectamente sana mientras muestra inglés a un usuario francés. Una compilación en verde no prueba nada.

Así que las garantías son lints, y se ejecutan como pruebas unitarias corrientes que leen los archivos `.resw` directamente del repositorio: sin navegador, sin carga de trabajo de Uno, sin aplicación en ejecución.

- Todas las culturas definen exactamente las mismas claves, y ninguna tiene un valor vacío.
- Cada miembro de `ErrorCode` tiene un mensaje en todas las culturas. El proyecto de pruebas referencia a la API, así que lee la propia enumeración en vez de una lista de nombres copiada.
- Ninguna entrada `ErrorCode_*` remite a un código que ya no existe, y en todas partes hay un respaldo genérico `Error_Unknown`.
- Ningún atributo literal `Text`/`Content`/`PlaceholderText`/`Header` en el XAML de la aplicación, y ningún texto literal entre etiquetas de elementos.
- **Todo `x:Uid` está respaldado por una entrada de recurso.** Este es el que más importa: un `x:Uid` mal escrito o sin respaldo no rompe la compilación, el control simplemente se muestra en blanco en tiempo de ejecución.
- Ningún `.Text = "literal"` en el code-behind de las páginas.

Cada lint se verificó introduciendo la violación a la que apunta y confirmando que la suite se ponía en rojo, para después revertirlo: un lint que analiza el directorio equivocado pasa tan silenciosamente como un código limpio.

Al principio solo eran alcanzables desde el trabajo de CI de extremo a extremo, que necesita SQL Server, la API y la cabecera web. Ahora se ejecutan también en el trabajo rápido de compilación y pruebas mediante `--filter TestCategory=Static`: nueve pruebas en aproximadamente una décima de segundo, sin lanzar navegador, de modo que una traducción ausente o una cadena codificada a mano hace fallar una pull request de inmediato.

## Probar una interfaz que no se puede consultar

El plan pedía que los fixtures de Playwright existentes dejaran de basarse en texto literal en inglés y pasaran a `AutomationProperties.AutomationId`. Ninguna de las dos mitades resultó aplicable.

Nunca se habían basado en texto inglés: las pruebas de inicio de sesión comprueban qué rutas de API llama la aplicación y los estados HTTP; las pruebas de humo comprueban el elemento canvas, el estado HTTP y la ausencia de errores de página. Ambas eran ya independientes del idioma, así que traducir la aplicación no rompió nada.

Y pasar a `AutomationId` no es posible. La cabecera WebAssembly de Uno dibuja con Skia dentro de un único `<canvas>`. Sondear una aplicación en ejecución confirmó que todo el documento es `DIV/CANVAS/INPUT` con `innerText` vacío: ninguna cadena renderizada ni ningún `AutomationId` es alcanzable desde Playwright. En lugar de inventar trabajo, ambos fixtures dejan ahora constancia de la restricción en sus comentarios de documentación, para que la siguiente persona no pase una tarde redescubriéndola. Los `AutomationId` se quedan en el XAML; sirven a la automatización nativa y de escritorio, solo que no a la cabecera de navegador.

Lo que *sí* es observable desde fuera del canvas resulta ser suficiente. Las pruebas de idioma de extremo a extremo manejan la configuración regional real del navegador —`en-US`, `fr-FR`, `es-ES`, más `de-DE` para demostrar que un idioma no admitido recurre al respaldo y `fr-CA` para demostrar que una etiqueta regional se ajusta— y comprueban dos cosas:

1. **La cultura que resolvió la aplicación.** Uno persiste `ApplicationLanguages.PrimaryLanguageOverride` en el almacenamiento local, así que la prueba vuelve a leer el idioma resuelto por su nombre en lugar de inferirlo.
2. **Los píxeles renderizados**, que demuestran que la cultura resuelta llegó realmente a la pantalla en vez de limitarse a calcularse y guardarse.

Dos decisiones deliberadas en la comparación de píxeles. **Sin imágenes de referencia**: los renderizados se comparan entre sí dentro de una misma ejecución, porque una referencia versionada se rompería con cada cambio de fuente, tema o disposición sin decirnos nunca más que «estos dos difieren». Y **un control de determinismo**: la prueba renderiza el inglés dos veces y comprueba que los bytes coinciden antes de afirmar que el francés difiere. Sin eso, «los píxeles difieren» sería cierto de dos renderizados cualesquiera, y un renderizador no determinista daría una prueba permanentemente verde y sin sentido.

En lugar de esperar un intervalo fijo antes de la captura, el ayudante sondea hasta que dos capturas consecutivas coinciden. Una espera fija tiene que ser lo bastante larga para el runner de CI más lento en su peor día y sigue siendo una conjetura; el sondeo llevó la suite de unos dos minutos a 39 segundos.

## Auditar la documentación contra el código

La especificación y `CLAUDE.md` se escribieron antes de que nada de esto existiera, así que el último paso fue contrastar cada afirmación con el código en vez de releerlos por su tono. Aparecieron desviaciones reales:

- **Códigos de error que no existen.** La especificación ponía `MustBeSignedInToJoinClub` e `InvalidTwoFactorCode` como ejemplos. Los miembros reales son `NotSignedIn` e `InvalidVerificationCode`. Cualquiera que programara un cliente con los nombres documentados habría comparado cadenas que la API nunca envía.
- **Un verbo HTTP equivocado**: el endpoint de idioma estaba documentado como PATCH; es `PUT /api/auth/language`.
- **Una regla cierta pero incompleta.** Ambos documentos decían que cada cadena del front end es una entrada `.resw` «referenciada mediante `x:Uid`» y que ninguna se «establece desde el code-behind»; leído literalmente, eso prohíbe justo el mecanismo que `LocalizedStrings` y `EnumLabels` tuvieron que usar. Ahora se describen las tres vías, con `x:Uid` como opción por defecto.
- **Comportamiento documentado que no existe.** Ambos indicaban en presente que los correos de invitación usan el idioma del destinatario. No hay correo de invitación; ese handler crea una membresía pendiente y no envía nada.

La auditoría también sacó a la luz una trampa que merece nombrarse. La lista de culturas se declara en tres sitios que no pueden referenciarse entre sí: la constante de la API, la constante de la aplicación y las carpetas `Strings/`. Las pruebas de recursos codificaban a mano una **cuarta** copia. Añadir un idioma a las constantes y publicar un `.resw` nuevo habría dejado ese archivo completamente sin verificar —sin comparación de claves, sin control de valores vacíos, sin cobertura de códigos de error— justo cuando esas comprobaciones más importan, y en silencio, porque todo seguiría pasando.

En vez de documentar la trampa, se eliminó. Las pruebas ahora descubren las carpetas `Strings/`, y otra prueba coteja ese conjunto con el `SupportedCultures.All` de la API. Una constante sin recursos, o recursos sin constante, fallan con un mensaje que nombra todo lo que hay que actualizar. Verificado añadiendo una carpeta `Strings/de` suelta y confirmando el fallo. Como beneficio adicional, la lista de «añadir un idioma» del README ya no necesita una línea de «y actualizar las pruebas»: las pruebas siguen a los recursos.
