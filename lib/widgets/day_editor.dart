// `DayEditorSheet` quedó retirado de toda la app: `RegisterScreen`
// (lib/screens/register_screen.dart) es ahora el único editor de día,
// tanto para hoy como para fechas pasadas/futuras vía su parámetro
// `targetDate`. Ya no queda ningún lugar que instancie DayEditorSheet — se
// vació este archivo para no seguir cargando ese código sin uso en el
// bundle. Si hiciera falta revisar el diseño original, buscar en el
// historial de versiones.
