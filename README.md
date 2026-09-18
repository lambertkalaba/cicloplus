# CicloPlus — Proyecto Flutter

Código fuente de la app (carpeta `lib/`). Le falta el "esqueleto" nativo de
iOS/Android, que se genera automáticamente en tu computadora con el comando
`flutter create` (necesita internet y no lo pude ejecutar yo desde aquí).

## Qué incluye

- `lib/models/day_entry.dart` — modelo de datos de un día (flujo + síntomas).
- `lib/services/storage_service.dart` — guardado local con `shared_preferences`.
- `lib/services/cycle_predictor.dart` — lógica de predicción de ciclo/ovulación (la misma que probamos en el prototipo web).
- `lib/services/reminder_service.dart` — programa la notificación local de "tu periodo llega en X días".
- `lib/theme/app_theme.dart` — colores y tema visual.
- `lib/widgets/` — calendario, tarjeta de estado, tarjeta de alarma, editor de día (con diario, vida sexual e historial dentro), historial.
- `lib/screens/home_screen.dart` — pantalla principal: solo calendario + alarma. Al tocar un día se abre el editor en una ventana modal (como en el prototipo web).
- `lib/main.dart` — punto de entrada.

## Cómo está organizada la pantalla (igual que el prototipo aprobado)
- **Pantalla principal:** encabezado, tarjeta de próximo periodo/ventana fértil, tarjeta de alarma de menstruación, y el calendario.
- **Al tocar un día:** se abre una hoja modal con flujo, síntomas, vida sexual (relación sexual / sin protección), diario de texto libre, botones de guardar/borrar, e historial de ciclos.

**Importante:** no tengo acceso a internet en mi entorno de trabajo, así que
no pude instalar Flutter ni compilar este código para probarlo de forma
automática. Lo revisé a mano (sintaxis, imports, nombres) con mucho cuidado,
y la lógica de predicción la verifiqué por separado en otro lenguaje con los
mismos resultados que el prototipo web. Aun así, el primer `flutter analyze`
que corras en tu máquina es el que va a confirmar que compila 100%.

## Instalación paso a paso (desde cero)

### 1. Instalar Flutter
- Ve a **docs.flutter.dev/get-started/install** y descarga el instalador para tu sistema operativo (Windows/Mac/Linux).
- Sigue el asistente. Al final corre en una terminal:
  ```
  flutter doctor
  ```
  Esto te dice qué falta (por ejemplo, Android Studio o Xcode).

### 2. Instalar el IDE/herramientas según tu plataforma
- **Para Android:** instala **Android Studio** (gratis) → abre "SDK Manager" y asegúrate de tener el Android SDK instalado.
- **Para iOS (solo si usas Mac):** instala **Xcode** desde la App Store.

### 3. Crear el esqueleto del proyecto
En una terminal, dentro de la carpeta donde quieras el proyecto:
```
flutter create --org com.cicloplus cicloplus_app
```
Esto genera las carpetas `android/`, `ios/`, `web/`, etc. que yo no puedo generar sin internet.

### 4. Copiar el código que te entregué
- Reemplaza la carpeta `lib/` que genera `flutter create` por la carpeta `lib/` que te di.
- Reemplaza también el archivo `pubspec.yaml` por el que te entregué (tiene las dependencias correctas: `shared_preferences`, `intl`, `flutter_local_notifications`, `timezone`).

### 5. Instalar dependencias y correr
```
cd cicloplus_app
flutter pub get
flutter analyze
flutter run
```
`flutter run` con un emulador de Android abierto (o tu celular conectado por USB con "depuración USB" activada) va a instalar la app y abrirla.

### 6. Permisos para que la alarma funcione de verdad
La app usa `flutter_local_notifications` para programar el aviso de "tu periodo llega en X días" directamente en el sistema operativo (no depende de tener la app abierta). Para que funcione en cada plataforma:

**Android** — en `android/app/src/main/AndroidManifest.xml`, dentro de `<manifest>`, agrega:
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

**iOS** — no necesitas tocar nada manualmente; el propio código pide permiso de notificaciones la primera vez que activas la alarma.

Si `flutter pub get` instala una versión de `flutter_local_notifications` distinta a la que fijé en `pubspec.yaml` y `flutter analyze` marca un error en `lib/services/reminder_service.dart`, casi siempre es un cambio pequeño de nombre de método — es la única parte del proyecto que no pude verificar por completo sin internet (lo explico también como comentario en ese archivo).

## Siguientes pasos (cuando quieras seguir avanzando conmigo)
1. Crear tu cuenta de Firebase y pasarme el `firebaseConfig` para integrar login y sincronización en la nube.
2. Generar el ícono de la app y las capturas de pantalla para las tiendas.
3. Configurar RevenueCat para las suscripciones cuando quieras monetizar.
