import 'package:flutter/material.dart';

import '../services/locale_controller.dart';

/// Textos traducidos de la app (español, inglés, francés, alemán).
///
/// Empieza cubriendo las pantallas principales (header, pestañas,
/// calendario, alarma de menstruación y Configuración). El resto del
/// contenido — notificaciones, PDF, textos educativos largos de
/// Estadísticas — se traduce en rondas siguientes; mientras tanto sigue
/// mostrándose en español como hasta ahora.
///
/// Uso: `AppStrings.of(context).home` en vez de un string literal.
/// `AppStrings.of(context)` lee el idioma actual desde [LocaleController]
/// (vía `AnimatedBuilder`/`ListenableBuilder` en main.dart, que reconstruye
/// todo el árbol cuando cambia), así que no hace falta pasar el idioma a mano.
class AppStrings {
  final String code;
  const AppStrings._(this.code);

  static AppStrings of(BuildContext context) => AppStrings._(LocaleController.instance.languageCode);

  /// Variante sin `BuildContext`, para código que no corre dentro del
  /// árbol de widgets (p. ej. al programar notificaciones locales por
  /// adelantado). Recibe el código de idioma ya resuelto, normalmente
  /// desde `SettingsService.loadLanguage()`.
  static AppStrings forCode(String code) => AppStrings._(code);

  String _t(Map<String, String> table) => table[code] ?? table['es']!;
  List<String> _tList(Map<String, List<String>> table) => table[code] ?? table['es']!;

  // ---- General ----
  String get appName => 'CicloPlus';

  String get tabCalendar => _t({'es': 'Calendario', 'en': 'Calendar', 'fr': 'Calendrier', 'de': 'Kalender', 'ru': 'Календарь', 'ar': 'التقويم', 'hi': 'कैलेंडर', 'bn': 'ক্যালেন্ডার', 'pt': 'Calendário'});
  String get tabTimeline => _t({'es': 'Línea de tiempo', 'en': 'Timeline', 'fr': 'Chronologie', 'de': 'Zeitleiste', 'ru': 'Хронология', 'ar': 'الجدول الزمني', 'hi': 'टाइमलाइन', 'bn': 'টাইমলাইন', 'pt': 'Linha do tempo'});
  String get tabReview => _t({'es': 'Revisión', 'en': 'Review', 'fr': 'Bilan', 'de': 'Überblick', 'ru': 'Обзор', 'ar': 'المراجعة', 'hi': 'समीक्षा', 'bn': 'পর্যালোচনা', 'pt': 'Revisão'});
  String get tabStats => _t({'es': 'Estadísticas', 'en': 'Statistics', 'fr': 'Statistiques', 'de': 'Statistiken', 'ru': 'Статистика', 'ar': 'الإحصائيات', 'hi': 'आंकड़े', 'bn': 'পরিসংখ্যান', 'pt': 'Estatísticas'});

  // ==================== review_screen.dart ====================
  String get reviewTitle => _t({'es': 'Revisar mi historial', 'en': 'Review my history', 'fr': 'Consulter mon historique', 'de': 'Meinen Verlauf ansehen', 'ru': 'Просмотреть мою историю', 'ar': 'مراجعة سجلي', 'hi': 'मेरा इतिहास देखें', 'bn': 'আমার ইতিহাস দেখুন', 'pt': 'Revisar meu histórico'});
  String get reviewMyCycles => _t({'es': 'Mis ciclos', 'en': 'My cycles', 'fr': 'Mes cycles', 'de': 'Meine Zyklen', 'ru': 'Мои циклы', 'ar': 'دوراتي', 'hi': 'मेरे चक्र', 'bn': 'আমার চক্র', 'pt': 'Meus ciclos'});
  String get reviewPeriodDaysLabel => _t({'es': 'Días', 'en': 'Days', 'fr': 'Jours', 'de': 'Tage', 'ru': 'Дни', 'ar': 'الأيام', 'hi': 'दिन', 'bn': 'দিন', 'pt': 'Dias'});
  String get reviewAvgPeriod => _t({'es': 'Periodo medio', 'en': 'Average period', 'fr': 'Règles moyennes', 'de': 'Durchschnittliche Periode', 'ru': 'Средняя менструация', 'ar': 'متوسط مدة الحيض', 'hi': 'औसत पीरियड', 'bn': 'গড় পিরিয়ড', 'pt': 'Período médio'});
  String get reviewAvgCycle => _t({'es': 'Ciclo medio', 'en': 'Average cycle', 'fr': 'Cycle moyen', 'de': 'Durchschnittlicher Zyklus', 'ru': 'Средний цикл', 'ar': 'متوسط الدورة', 'hi': 'औसत चक्र', 'bn': 'গড় চক্র', 'pt': 'Ciclo médio'});
  String get reviewHistory => _t({'es': 'Historia', 'en': 'History', 'fr': 'Historique', 'de': 'Verlauf', 'ru': 'История', 'ar': 'السجل', 'hi': 'इतिहास', 'bn': 'ইতিহাস', 'pt': 'Histórico'});
  String get reviewIrregular => _t({'es': 'Irregular', 'en': 'Irregular', 'fr': 'Irrégulier', 'de': 'Unregelmäßig', 'ru': 'Нерегулярный', 'ar': 'غير منتظم', 'hi': 'अनियमित', 'bn': 'অনিয়মিত', 'pt': 'Irregular'});
  String get reviewRegular => _t({'es': 'Regular', 'en': 'Regular', 'fr': 'Régulier', 'de': 'Regelmäßig', 'ru': 'Регулярный', 'ar': 'منتظم', 'hi': 'नियमित', 'bn': 'নিয়মিত', 'pt': 'Regular'});
  String get reviewBasedOnCycles => _t({
        'es': 'Basado en tus últimos ciclos',
        'en': 'Based on your recent cycles',
        'fr': 'Basé sur vos derniers cycles',
        'de': 'Basierend auf deinen letzten Zyklen',
        'ru': 'На основе твоих последних циклов',
        'ar': 'بناءً على دوراتك الأخيرة',
        'hi': 'आपके हाल के चक्रों के आधार पर',
        'bn': 'আপনার সাম্প্রতিক চক্রের ভিত্তিতে',
        'pt': 'Com base nos seus últimos ciclos',
      });
  String get reviewNextPeriodLabel => _t({
        'es': 'Próximo periodo previsto',
        'en': 'Next period expected',
        'fr': 'Prochaines règles prévues',
        'de': 'Nächste erwartete Periode',
        'ru': 'Ожидаемая следующая менструация',
        'ar': 'الدورة القادمة المتوقعة',
        'hi': 'अगला पीरियड अनुमानित',
        'bn': 'পরবর্তী পিরিয়ড প্রত্যাশিত',
        'pt': 'Próximo período previsto',
      });
  String reviewInDays(int days) => _t({
        'es': days == 1 ? 'en 1 día' : 'en $days días',
        'en': days == 1 ? 'in 1 day' : 'in $days days',
        'fr': days == 1 ? 'dans 1 jour' : 'dans $days jours',
        'de': days == 1 ? 'in 1 Tag' : 'in $days Tagen',
        'ru': days == 1 ? 'через 1 день' : 'через $days дн.',
        'ar': days == 1 ? 'خلال يوم واحد' : 'خلال $days أيام',
        'hi': days == 1 ? '1 दिन में' : '$days दिनों में',
        'bn': days == 1 ? '১ দিনে' : '$days দিনে',
        'pt': days == 1 ? 'em 1 dia' : 'em $days dias',
      });
  String get reviewNoDataYet => _t({
        'es': 'Aún sin datos suficientes',
        'en': 'Not enough data yet',
        'fr': 'Pas encore assez de données',
        'de': 'Noch nicht genug Daten',
        'ru': 'Пока недостаточно данных',
        'ar': 'لا توجد بيانات كافية بعد',
        'hi': 'अभी पर्याप्त डेटा नहीं है',
        'bn': 'এখনও পর্যাপ্ত তথ্য নেই',
        'pt': 'Ainda não há dados suficientes',
      });
  String reviewFertileWindow(String range, String ovulation) => _t({
        'es': 'Ventana fértil estimada: $range · ovulación $ovulation',
        'en': 'Estimated fertile window: $range · ovulation $ovulation',
        'fr': 'Fenêtre de fertilité estimée : $range · ovulation $ovulation',
        'de': 'Geschätztes fruchtbares Fenster: $range · Eisprung $ovulation',
        'ru': 'Предполагаемое фертильное окно: $range · овуляция $ovulation',
        'ar': 'نافذة الخصوبة المقدرة: $range · الإباضة $ovulation',
        'hi': 'अनुमानित उपजाऊ अवधि: $range · ओव्यूलेशन $ovulation',
        'bn': 'আনুমানিক উর্বর সময়কাল: $range · ডিম্বস্ফোটন $ovulation',
        'pt': 'Janela fértil estimada: $range · ovulação $ovulation',
      });
  String get reviewVsAverage => _t({
        'es': 'Este ciclo vs promedio',
        'en': 'This cycle vs average',
        'fr': 'Ce cycle vs moyenne',
        'de': 'Dieser Zyklus vs Durchschnitt',
        'ru': 'Этот цикл по сравнению со средним',
        'ar': 'هذه الدورة مقارنة بالمتوسط',
        'hi': 'यह चक्र बनाम औसत',
        'bn': 'এই চক্র বনাম গড়',
        'pt': 'Este ciclo vs média',
      });
  String get reviewLongerThanAvg => _t({
        'es': 'más largo que tu media',
        'en': 'longer than your average',
        'fr': 'plus long que votre moyenne',
        'de': 'länger als dein Durchschnitt',
        'ru': 'длиннее твоего среднего',
        'ar': 'أطول من متوسطك',
        'hi': 'आपके औसत से लंबा',
        'bn': 'আপনার গড়ের চেয়ে দীর্ঘ',
        'pt': 'mais longo que sua média',
      });
  String get reviewShorterThanAvg => _t({
        'es': 'más corto que tu media',
        'en': 'shorter than your average',
        'fr': 'plus court que votre moyenne',
        'de': 'kürzer als dein Durchschnitt',
        'ru': 'короче твоего среднего',
        'ar': 'أقصر من متوسطك',
        'hi': 'आपके औसत से छोटा',
        'bn': 'আপনার গড়ের চেয়ে ছোট',
        'pt': 'mais curto que sua média',
      });
  String get reviewSameAsAvg => _t({
        'es': 'igual que tu media',
        'en': 'same as your average',
        'fr': 'identique à votre moyenne',
        'de': 'gleich wie dein Durchschnitt',
        'ru': 'совпадает с твоим средним',
        'ar': 'مطابق لمتوسطك', 'hi': 'तुम्हारे औसत जितना ही', 'bn': 'তোমার গড়ের সমান', 'pt': 'igual à sua média',
      });
  String get reviewRegularity => _t({'es': 'Regularidad', 'en': 'Regularity', 'fr': 'Régularité', 'de': 'Regelmäßigkeit', 'ru': 'Регулярность', 'ar': 'الانتظام', 'hi': 'नियमितता', 'bn': 'নিয়মিততা', 'pt': 'Regularidade'});
  String get reviewRegularityRange => _t({
        'es': 'dentro de 21-35 días',
        'en': 'within 21-35 days',
        'fr': 'entre 21 et 35 jours',
        'de': 'innerhalb von 21-35 Tagen',
        'ru': 'в пределах 21-35 дней',
        'ar': 'ضمن 21-35 يومًا',
        'hi': '21-35 दिनों के भीतर',
        'bn': '২১-৩৫ দিনের মধ্যে',
        'pt': 'entre 21 e 35 dias',
      });
  String get reviewEducationalNote => _t({
        'es':
            'La predicción se calcula con el promedio de tus últimos ciclos. Un ciclo se considera irregular si dura menos de 21 o más de 35 días.',
        'en':
            'The prediction is calculated from the average of your recent cycles. A cycle is considered irregular if it lasts fewer than 21 or more than 35 days.',
        'fr':
            'La prédiction est calculée à partir de la moyenne de vos derniers cycles. Un cycle est considéré irrégulier s\'il dure moins de 21 ou plus de 35 jours.',
        'de':
            'Die Vorhersage basiert auf dem Durchschnitt deiner letzten Zyklen. Ein Zyklus gilt als unregelmäßig, wenn er weniger als 21 oder mehr als 35 Tage dauert.',
        'ru': 'Прогноз рассчитывается на основе среднего значения твоих последних циклов. Цикл считается нерегулярным, если он длится менее 21 или более 35 дней.',
        'ar': 'يُحسب التوقع بناءً على متوسط دوراتك الأخيرة. تُعتبر الدورة غير منتظمة إذا استمرت أقل من 21 يومًا أو أكثر من 35 يومًا.', 'hi': 'यह अनुमान आपके हाल के चक्रों के औसत से निकाला जाता है। अगर कोई चक्र 21 दिनों से कम या 35 दिनों से ज़्यादा चलता है, तो उसे अनियमित माना जाता है।', 'bn': 'এই পূর্বাভাসটি আপনার সাম্প্রতিক চক্রগুলোর গড় থেকে হিসাব করা হয়। কোনো চক্র ২১ দিনের কম বা ৩৫ দিনের বেশি হলে তাকে অনিয়মিত ধরা হয়।', 'pt': 'A previsão é calculada com base na média dos seus últimos ciclos. Um ciclo é considerado irregular se durar menos de 21 ou mais de 35 dias.',
      });
  String get reviewSeeAll => _t({'es': 'Ver todos', 'en': 'See all', 'fr': 'Tout voir', 'de': 'Alle ansehen', 'ru': 'Смотреть все', 'ar': 'عرض الكل', 'hi': 'सभी देखें', 'bn': 'সব দেখুন', 'pt': 'Ver tudo'});
  String get reviewEmpty => _t({
        'es': 'Aún no hay ciclos suficientes para mostrar tu historial. Sigue registrando tu periodo.',
        'en': 'Not enough cycles yet to show your history. Keep logging your period.',
        'fr': "Pas encore assez de cycles pour afficher votre historique. Continuez à enregistrer vos règles.",
        'de': 'Noch nicht genug Zyklen für deinen Verlauf. Trage deine Periode weiter ein.',
        'ru': 'Пока недостаточно циклов, чтобы показать твою историю. Продолжай записывать свой период.',
        'ar': 'لا توجد دورات كافية بعد لعرض سجلك. استمري في تسجيل دورتك الشهرية.',
        'hi': 'आपका इतिहास दिखाने के लिए अभी पर्याप्त चक्र नहीं हैं। अपना पीरियड दर्ज करना जारी रखें।',
        'bn': 'আপনার ইতিহাস দেখানোর জন্য এখনও যথেষ্ট চক্র নেই। আপনার পিরিয়ড লগ করা চালিয়ে যান।',
        'pt': 'Ainda não há ciclos suficientes para mostrar seu histórico. Continue registrando seu período.',
      });

  // ---- Diagrama "Etapas del ciclo" dentro de review_screen.dart ----
  String get reviewStagesTitle =>
      _t({'es': 'Etapas', 'en': 'Stages', 'fr': 'Étapes', 'de': 'Phasen', 'ru': 'Этапы', 'ar': 'المراحل', 'hi': 'चरण', 'bn': 'পর্যায়', 'pt': 'Etapas'});
  String get reviewStagesSubtitle =>
      _t({'es': 'Ciclo menstrual', 'en': 'Menstrual cycle', 'fr': 'Cycle menstruel', 'de': 'Menstruationszyklus', 'ru': 'Менструальный цикл', 'ar': 'الدورة الشهرية', 'hi': 'मासिक चक्र', 'bn': 'মাসিক চক্র', 'pt': 'Ciclo menstrual'});
  String get reviewStagesCurrentPrefix =>
      _t({'es': 'Estás en:', 'en': "You're in:", 'fr': 'Vous êtes en :', 'de': 'Du bist in:', 'ru': 'Ты на этапе:', 'ar': 'أنتِ الآن في:', 'hi': 'आप अभी हैं:', 'bn': 'আপনি এখন আছেন:', 'pt': 'Você está em:'});
  String get reviewStagesNoData => _t({
        'es': 'Registra tu periodo para ver en qué etapa estás.',
        'en': 'Log your period to see which stage you\'re in.',
        'fr': 'Enregistrez vos règles pour voir dans quelle étape vous êtes.',
        'de': 'Trage deine Periode ein, um deine aktuelle Phase zu sehen.',
        'ru': 'Отмечай свой период, чтобы видеть, на каком этапе ты находишься.',
        'ar': 'سجّلي دورتك لمعرفة المرحلة التي أنتِ فيها.', 'hi': 'यह देखने के लिए कि आप किस चरण में हैं, अपना पीरियड दर्ज करें।', 'bn': 'আপনি কোন পর্যায়ে আছেন তা দেখতে আপনার পিরিয়ড লগ করুন।', 'pt': 'Registre seu período para ver em que estágio você está.',
      });
  String get reviewStagesDurationLabel =>
      _t({'es': 'Duración', 'en': 'Duration', 'fr': 'Durée', 'de': 'Dauer', 'ru': 'Длительность', 'ar': 'المدة', 'hi': 'अवधि', 'bn': 'স্থিতিকাল', 'pt': 'Duração'});
  String get reviewStagesDaysLeftLabel =>
      _t({'es': 'Te quedan', 'en': 'Days left', 'fr': 'Il reste', 'de': 'Verbleibend', 'ru': 'Осталось', 'ar': 'المتبقي', 'hi': 'बचे हुए दिन', 'bn': 'বাকি দিন', 'pt': 'Dias restantes'});
  String reviewStagesDaysCount(int d) {
    if (d == 1) return _t({'es': '1 día', 'en': '1 day', 'fr': '1 jour', 'de': '1 Tag', 'ru': '1 день', 'ar': 'يوم واحد', 'hi': '1 दिन', 'bn': '১ দিন', 'pt': '1 dia'});
    return _t({'es': '$d días', 'en': '$d days', 'fr': '$d jours', 'de': '$d Tage', 'ru': '$d дн.', 'ar': '$d أيام', 'hi': '$d दिन', 'bn': '$d দিন', 'pt': '$d dias'});
  }
  String get reviewStagesNotThere => _t({
        'es': 'Esta etapa aún te espera.',
        'en': 'This stage is still ahead of you.',
        'fr': 'Cette étape vous attend encore.',
        'de': 'Diese Phase liegt noch vor dir.',
        'ru': 'Этот этап ещё впереди.',
        'ar': 'هذه المرحلة لم تأتِ بعد.',
        'hi': 'यह चरण अभी आना बाकी है।',
        'bn': 'এই পর্যায় এখনও আসেনি।',
        'pt': 'Esta etapa ainda está por vir.',
      });
  String get reviewStagesWhatsHappening => _t({
        'es': 'Qué está pasando en tu cuerpo',
        'en': "What's happening in your body",
        'fr': 'Ce qui se passe dans ton corps',
        'de': 'Was in deinem Körper passiert',
        'ru': 'Что происходит в твоём теле',
        'ar': 'ما الذي يحدث في جسمك', 'hi': 'तुम्हारे शरीर में क्या हो रहा है', 'bn': 'তোমার শরীরে কী ঘটছে', 'pt': 'O que está acontecendo no seu corpo',
      });

  String get settingsTooltip => _t({'es': 'Configuración', 'en': 'Settings', 'fr': 'Paramètres', 'de': 'Einstellungen', 'ru': 'Настройки', 'ar': 'الإعدادات', 'hi': 'सेटिंग्स', 'bn': 'সেটিংস', 'pt': 'Configurações'});
  String get signOutTooltip => _t({'es': 'Cerrar sesión', 'en': 'Sign out', 'fr': 'Déconnexion', 'de': 'Abmelden', 'ru': 'Выйти из аккаунта', 'ar': 'تسجيل الخروج', 'hi': 'साइन आउट करें', 'bn': 'সাইন আউট করুন', 'pt': 'Sair'});
  String get signOutConfirmTitle =>
      _t({'es': '¿Cerrar sesión?', 'en': 'Sign out?', 'fr': 'Se déconnecter ?', 'de': 'Abmelden?', 'ru': 'Выйти из аккаунта?', 'ar': 'تسجيل الخروج؟', 'hi': 'साइन आउट करें?', 'bn': 'সাইন আউট করবেন?', 'pt': 'Sair da conta?'});
  String get signOutConfirmBody => _t({
        'es': 'Tus datos quedan guardados. Podrás volver a iniciar sesión cuando quieras.',
        'en': 'Your data stays saved. You can sign back in anytime.',
        'fr': 'Vos données restent enregistrées. Vous pourrez vous reconnecter quand vous voulez.',
        'de': 'Deine Daten bleiben gespeichert. Du kannst dich jederzeit wieder anmelden.',
        'ru': 'Твои данные останутся сохранены. Ты сможешь снова войти, когда захочешь.',
        'ar': 'تبقى بياناتك محفوظة. يمكنك تسجيل الدخول مرة أخرى في أي وقت.', 'hi': 'आपका डेटा सेव रहेगा। आप जब चाहें दोबारा लॉग इन कर सकते हैं।', 'bn': 'আপনার তথ্য সংরক্ষিত থাকবে। আপনি যখন চান আবার লগ ইন করতে পারবেন।', 'pt': 'Seus dados continuam salvos. Você pode fazer login novamente quando quiser.',
      });
  String get cancel => _t({'es': 'Cancelar', 'en': 'Cancel', 'fr': 'Annuler', 'de': 'Abbrechen', 'ru': 'Отмена', 'ar': 'إلغاء', 'hi': 'रद्द करें', 'bn': 'বাতিল করুন', 'pt': 'Cancelar'});
  String get edit => _t({'es': 'Editar', 'en': 'Edit', 'fr': 'Modifier', 'de': 'Bearbeiten', 'ru': 'Редактировать', 'ar': 'تعديل', 'hi': 'संपादित करें', 'bn': 'সম্পাদনা করুন', 'pt': 'Editar'});
  String get close => _t({'es': 'Cerrar', 'en': 'Close', 'fr': 'Fermer', 'de': 'Schließen', 'ru': 'Закрыть', 'ar': 'إغلاق', 'hi': 'बंद करें', 'bn': 'বন্ধ করুন', 'pt': 'Fechar'});
  String get signOut => _t({'es': 'Cerrar sesión', 'en': 'Sign out', 'fr': 'Se déconnecter', 'de': 'Abmelden', 'ru': 'Выйти из аккаунта', 'ar': 'تسجيل الخروج', 'hi': 'साइन आउट करें', 'bn': 'সাইন আউট করুন', 'pt': 'Sair'});

  // ---- Calendario / leyenda ----
  String get legendPeriod => _t({'es': 'Periodo', 'en': 'Period', 'fr': 'Règles', 'de': 'Periode', 'ru': 'Менструация', 'ar': 'الدورة', 'hi': 'पीरियड', 'bn': 'পিরিয়ড', 'pt': 'Período'});
  String get legendPrediction => _t({'es': 'Previsto', 'en': 'Prediction', 'fr': 'Prédiction', 'de': 'Vorhersage', 'ru': 'Прогноз', 'ar': 'متوقع', 'hi': 'अनुमानित', 'bn': 'পূর্বাভাস', 'pt': 'Previsão'});
  String get legendFertile => _t({'es': 'Fértil', 'en': 'Fertile', 'fr': 'Fertile', 'de': 'Fruchtbar', 'ru': 'Фертильный', 'ar': 'خصوبة', 'hi': 'उपजाऊ', 'bn': 'উর্বর', 'pt': 'Fértil'});
  String get legendOvulation => _t({'es': 'Ovulación', 'en': 'Ovulation', 'fr': 'Ovulation', 'de': 'Eisprung', 'ru': 'Овуляция', 'ar': 'الإباضة', 'hi': 'ओव्यूलेशन', 'bn': 'ডিম্বস্ফোটন', 'pt': 'Ovulação'});
  // Anillo verde sin relleno que marca el día de hoy en el calendario —
  // se explica en la leyenda para que se distinga claramente del círculo
  // morado sólido de ovulación/selección.
  String get legendToday => _t({'es': 'Hoy', 'en': 'Today', 'fr': "Aujourd'hui", 'de': 'Heute', 'ru': 'Сегодня', 'ar': 'اليوم', 'hi': 'आज', 'bn': 'আজ', 'pt': 'Hoje'});

  String get calendarHint => _t({
        'es': 'Toca cualquier día del calendario para registrar tu flujo, síntomas y notas.',
        'en': 'Tap any day on the calendar to log your flow, symptoms and notes.',
        'fr': 'Touchez un jour du calendrier pour enregistrer votre flux, symptômes et notes.',
        'de': 'Tippe auf einen Tag im Kalender, um Blutung, Symptome und Notizen einzutragen.',
        'ru': 'Нажми на любой день в календаре, чтобы отметить выделения, симптомы и заметки.',
        'ar': 'اضغطي على أي يوم في التقويم لتسجيل الإفرازات والأعراض والملاحظات.', 'hi': 'अपने फ्लो, लक्षण और नोट्स दर्ज करने के लिए कैलेंडर में किसी भी दिन पर टैप करें।', 'bn': 'আপনার ফ্লো, লক্ষণ ও নোট লগ করতে ক্যালেন্ডারের যেকোনো দিনে ট্যাপ করুন।', 'pt': 'Toque em qualquer dia do calendário para registrar seu fluxo, sintomas e notas.',
      });
  String get calendarHintDismiss =>
      _t({'es': 'No volver a mostrar', 'en': "Don't show again", 'fr': 'Ne plus afficher', 'de': 'Nicht mehr anzeigen', 'ru': 'Больше не показывать', 'ar': 'عدم الإظهار مرة أخرى', 'hi': 'दोबारा न दिखाएं', 'bn': 'আর দেখাবেন না', 'pt': 'Não mostrar novamente'});

  String get privacyNote => _t({
        'es':
            '🔒 Tus registros están asociados a tu cuenta y guardados en este dispositivo. Cuando actives la sincronización en la nube podrás verlos también desde otro dispositivo o desde la web.',
        'en':
            '🔒 Your entries are tied to your account and stored on this device. Once cloud sync is on, you\'ll also see them on another device or on the web.',
        'fr':
            '🔒 Vos données sont liées à votre compte et enregistrées sur cet appareil. Une fois la synchronisation cloud activée, vous les verrez aussi sur un autre appareil ou sur le web.',
        'de':
            '🔒 Deine Einträge sind mit deinem Konto verknüpft und auf diesem Gerät gespeichert. Sobald die Cloud-Synchronisierung aktiv ist, siehst du sie auch auf einem anderen Gerät oder im Web.',
        'ru': '🔒 Твои записи привязаны к твоему аккаунту и хранятся на этом устройстве. Когда включишь синхронизацию с облаком, сможешь видеть их также с другого устройства или в вебе.',
        'ar': '🔒 سجلاتك مرتبطة بحسابك ومحفوظة على هذا الجهاز. عند تفعيل المزامنة السحابية، ستتمكنين من رؤيتها أيضًا من جهاز آخر أو من الويب.', 'hi': '🔒 आपके रिकॉर्ड आपके खाते से जुड़े हैं और इस डिवाइस में सेव हैं। क्लाउड सिंक चालू करने पर आप उन्हें किसी दूसरे डिवाइस या वेब से भी देख सकेंगे।', 'bn': '🔒 আপনার রেকর্ডগুলো আপনার অ্যাকাউন্টের সাথে যুক্ত এবং এই ডিভাইসে সংরক্ষিত। ক্লাউড সিঙ্ক চালু করলে আপনি সেগুলো অন্য ডিভাইস বা ওয়েব থেকেও দেখতে পারবেন।', 'pt': '🔒 Seus registros estão associados à sua conta e salvos neste dispositivo. Ao ativar a sincronização na nuvem, você também poderá vê-los em outro dispositivo ou na web.',
      });

  String get logToday => _t({'es': 'Registrar hoy', 'en': 'Log today', 'fr': "Enregistrer aujourd'hui", 'de': 'Heute eintragen', 'ru': 'Отметить сегодня', 'ar': 'تسجيل اليوم', 'hi': 'आज दर्ज करें', 'bn': 'আজ লগ করুন', 'pt': 'Registrar hoje'});

  // ---- Alarma de menstruación ----
  String get reminderTitle =>
      _t({'es': '🔔 Alarma de menstruación', 'en': '🔔 Period reminder', 'fr': '🔔 Alarme de règles', 'de': '🔔 Periodenerinnerung', 'ru': '🔔 Напоминание о менструации', 'ar': '🔔 تذكير بالدورة الشهرية', 'hi': '🔔 पीरियड रिमाइंडर', 'bn': '🔔 পিরিয়ড রিমাইন্ডার', 'pt': '🔔 Lembrete de menstruação'});
  String get reminderSubtitleOff => _t({
        'es': 'Avísame antes de que llegue mi periodo',
        'en': 'Notify me before my period arrives',
        'fr': 'Prévenez-moi avant l\'arrivée de mes règles',
        'de': 'Benachrichtige mich, bevor meine Periode kommt',
        'ru': 'Предупреждай меня перед началом менструации',
        'ar': 'أعلميني قبل بدء دورتي',
        'hi': 'मेरा पीरियड आने से पहले मुझे बताएं',
        'bn': 'আমার পিরিয়ড আসার আগে আমাকে জানান',
        'pt': 'Me avise antes da minha menstruação chegar',
      });
  String reminderSubtitleNoData(int days) => _t({
        'es': 'Te avisaré $days día(s) antes — registra tu periodo para calcularlo',
        'en': "I'll notify you $days day(s) before — log your period so I can calculate it",
        'fr': 'Je vous préviendrai $days jour(s) avant — enregistrez vos règles pour que je puisse calculer',
        'de': 'Ich benachrichtige dich $days Tag(e) vorher — trage deine Periode ein, damit ich sie berechnen kann',
        'ru': 'Я предупрежу тебя за $days дн. — отметь свой период, чтобы я мог это рассчитать',
        'ar': 'سأنبّهك قبل $days أيام — سجّلي دورتك لأتمكن من حساب ذلك',
        'hi': '$days दिन पहले आपको बताऊंगी — इसकी गणना के लिए अपना पीरियड दर्ज करें',
        'bn': '$days দিন আগে আপনাকে জানাবো — এটি হিসাব করতে আপনার পিরিয়ড লগ করুন',
        'pt': 'Vou te avisar $days dia(s) antes — registre seu período para eu poder calcular',
      });
  String reminderSubtitleOn(int days) => _t({
        'es': 'Activa: $days día(s) antes de tu próximo periodo',
        'en': 'Active: $days day(s) before your next period',
        'fr': 'Actif : $days jour(s) avant vos prochaines règles',
        'de': 'Aktiv: $days Tag(e) vor deiner nächsten Periode',
        'ru': 'Активно: за $days дн. до твоей следующей менструации',
        'ar': 'مفعّل: قبل $days أيام من دورتك القادمة',
        'hi': 'सक्रिय: आपके अगले पीरियड से $days दिन पहले',
        'bn': 'সক্রিয়: আপনার পরবর্তী পিরিয়ডের $days দিন আগে',
        'pt': 'Ativo: $days dia(s) antes do seu próximo período',
      });
  /// Mensaje mostrado (SnackBar) cuando la usuaria activa uno de los
  /// interruptores de fecha del ciclo (Inicio/Fin de período, Introducir
  /// período, Periodo fértil, Ovulación, Autoexamen de mamas) pero todavía
  /// no hay datos suficientes para calcular una fecha por defecto
  /// (CyclePredictor.predictNextPeriod() == null porque getCycles() está
  /// vacío). Antes esto revertía el interruptor sin ninguna explicación,
  /// dando la impresión de que "no funcionaba" — ver ReminderScreen.
  /// _openDateTimeSheetFor.
  String get reminderNeedsPeriodDataFirst => _t({
        'es': 'Registra al menos un periodo para poder calcular esta fecha',
        'en': 'Log at least one period first so I can calculate this date',
        'fr': "Enregistrez d'abord au moins une période pour que je puisse calculer cette date",
        'de': 'Erfasse zuerst mindestens eine Periode, damit ich dieses Datum berechnen kann',
        'ru': 'Отметь хотя бы одну менструацию, чтобы я мог рассчитать эту дату',
        'ar': 'سجّلي دورة واحدة على الأقل حتى أتمكن من حساب هذا التاريخ', 'hi': 'इस तारीख की गणना करने के लिए कम से कम एक पीरियड दर्ज करें', 'bn': 'এই তারিখ হিসাব করতে অন্তত একটি পিরিয়ড লগ করুন', 'pt': 'Registre pelo menos um período para eu poder calcular essa data',
      });

  String get reminderBefore => _t({'es': 'Avisar', 'en': 'Notify', 'fr': 'Prévenir', 'de': 'Benachrichtigen', 'ru': 'Уведомить', 'ar': 'تنبيه', 'hi': 'सूचित करें', 'bn': 'জানান', 'pt': 'Notificar'});
  String reminderDayOption(int d) {
    if (d == 1) return _t({'es': '1 día antes', 'en': '1 day before', 'fr': '1 jour avant', 'de': '1 Tag vorher', 'ru': 'За 1 день', 'ar': 'قبل يوم واحد', 'hi': '1 दिन पहले', 'bn': '১ দিন আগে', 'pt': '1 dia antes'});
    return _t({'es': '$d días antes', 'en': '$d days before', 'fr': '$d jours avant', 'de': '$d Tage vorher', 'ru': 'За $d дн.', 'ar': 'قبل $d أيام', 'hi': '$d दिन पहले', 'bn': '$d দিন আগে', 'pt': '$d dias antes'});
  }

  // ---- Pantalla "Obtener Recordatorio" (reminder_screen.dart) ----
  String get reminderScreenTitleLine1 => _t({'es': 'Obtener', 'en': 'Get', 'fr': 'Obtenir', 'de': 'Erhalte', 'ru': 'Получить', 'ar': 'الحصول عليه', 'hi': 'पाएं', 'bn': 'পান', 'pt': 'Obter'});
  String get reminderScreenTitleLine2 =>
      _t({'es': 'Recordatorio', 'en': 'Reminder', 'fr': 'un rappel', 'de': 'Erinnerung', 'ru': 'Напоминание', 'ar': 'تذكير', 'hi': 'रिमाइंडर', 'bn': 'রিমাইন্ডার', 'pt': 'Lembrete'});
  String get reminderRowPeriod => _t({'es': 'Periodo', 'en': 'Period', 'fr': 'Règles', 'de': 'Periode', 'ru': 'Менструация', 'ar': 'الدورة', 'hi': 'पीरियड', 'bn': 'পিরিয়ড', 'pt': 'Período'});
  String get reminderRowOvulation => _t({'es': 'Ovulación', 'en': 'Ovulation', 'fr': 'Ovulation', 'de': 'Eisprung', 'ru': 'Овуляция', 'ar': 'الإباضة', 'hi': 'ओव्यूलेशन', 'bn': 'ডিম্বস্ফোটন', 'pt': 'Ovulação'});
  String get reminderRowFertile =>
      _t({'es': 'Días fértiles', 'en': 'Fertile days', 'fr': 'Jours fertiles', 'de': 'Fruchtbare Tage', 'ru': 'Фертильные дни', 'ar': 'أيام الخصوبة', 'hi': 'उपजाऊ दिन', 'bn': 'উর্বর দিন', 'pt': 'Dias férteis'});
  String get reminderScreenEntry => _t({
        'es': 'Obtener recordatorio',
        'en': 'Get reminder',
        'fr': 'Obtenir un rappel',
        'de': 'Erinnerung erhalten',
        'ru': 'Получить напоминание',
        'ar': 'الحصول على تذكير',
        'hi': 'रिमाइंडर पाएं',
        'bn': 'রিমাইন্ডার পান',
        'pt': 'Obter lembrete',
      });

  // ---- Configuración ----
  String get settingsAppColor => _t({'es': 'Color de la app', 'en': 'App color', 'fr': "Couleur de l'app", 'de': 'App-Farbe', 'ru': 'Цвет приложения', 'ar': 'لون التطبيق', 'hi': 'ऐप का रंग', 'bn': 'অ্যাপের রঙ', 'pt': 'Cor do app'});
  String get settingsPinTitle =>
      _t({'es': 'Protección con PIN', 'en': 'PIN protection', 'fr': 'Protection par code', 'de': 'PIN-Schutz', 'ru': 'Защита PIN-кодом', 'ar': 'الحماية برمز PIN', 'hi': 'पिन सुरक्षा', 'bn': 'পিন সুরক্ষা', 'pt': 'Proteção por PIN'});
  String get settingsPinToggle =>
      _t({'es': '🔒 Pedir PIN al abrir', 'en': '🔒 Require PIN to open', 'fr': "🔒 Demander le code à l'ouverture", 'de': '🔒 PIN beim Öffnen verlangen', 'ru': '🔒 Запрашивать PIN при открытии', 'ar': '🔒 طلب رمز PIN عند الفتح', 'hi': '🔒 खोलते समय पिन मांगें', 'bn': '🔒 খোলার সময় পিন চাওয়া হোক', 'pt': '🔒 Pedir PIN para abrir'});
  String get on_ => _t({'es': 'Activado', 'en': 'On', 'fr': 'Activé', 'de': 'Aktiviert', 'ru': 'Включено', 'ar': 'مفعّل', 'hi': 'चालू', 'bn': 'চালু', 'pt': 'Ativado'});
  String get off_ => _t({'es': 'Desactivado', 'en': 'Off', 'fr': 'Désactivé', 'de': 'Deaktiviert', 'ru': 'Выключено', 'ar': 'معطّل', 'hi': 'बंद', 'bn': 'বন্ধ', 'pt': 'Desativado'});

  // ---- Apariencia de la pareja (Configuración) ----
  // Título/descripción de la tarjeta y nombres de las 5 combinaciones de
  // ilustración en kCoupleIllustrations (settings_service.dart) — antes
  // estaban en español fijo (título, descripción y opt.name), a petición
  // de la usuaria ahora cambian con el idioma de la app igual que el resto
  // de Configuración.
  String get settingsCoupleAppearanceTitle => _t({
        'es': 'Apariencia de tu pareja',
        'en': "Your partner's appearance",
        'fr': 'Apparence de votre partenaire',
        'de': 'Aussehen deines Partners',
        'ru': 'Внешность партнёра',
        'ar': 'مظهر شريكك',
        'hi': 'आपके साथी की उपस्थिति',
        'bn': 'আপনার সঙ্গীর চেহারা',
        'pt': 'Aparência do seu parceiro',
      });
  String get settingsCoupleAppearanceHint => _t({
        'es': 'Elige cómo se ve la ilustración de la pareja en la pantalla Hoy',
        'en': 'Choose how the couple illustration looks on the Today screen',
        'fr': "Choisissez à quoi ressemble l'illustration du couple sur l'écran Aujourd'hui",
        'de': 'Wähle, wie die Paar-Illustration auf dem Heute-Bildschirm aussieht',
        'ru': 'Выберите, как будет выглядеть иллюстрация пары на экране «Сегодня»',
        'ar': 'اختر شكل رسم الزوجين في شاشة اليوم',
        'hi': 'चुनें कि आज स्क्रीन पर जोड़े का चित्रण कैसा दिखे',
        'bn': 'আজকের স্ক্রিনে দম্পতির চিত্রায়ন কেমন দেখাবে তা বেছে নিন',
        'pt': 'Escolha como a ilustração do casal aparece na tela Hoje',
      });
  String coupleIllustrationName(String id) {
    switch (id) {
      case 'mixta_inversa':
        return _t({
          'es': 'Ella oscura, él claro',
          'en': 'Her dark, his light',
          'fr': 'Elle foncée, lui clair',
          'de': 'Sie dunkel, er hell',
          'ru': 'Она тёмная, он светлый',
          'ar': 'هي داكنة، هو فاتح',
          'hi': 'महिला सांवली, पुरुष गोरा',
          'bn': 'নারী কালো, পুরুষ ফর্সা',
          'pt': 'Ela escura, ele claro',
        });
      case 'blanca':
        return _t({
          'es': 'Ella clara, él claro',
          'en': 'Her light, his light',
          'fr': 'Elle claire, lui clair',
          'de': 'Sie hell, er hell',
          'ru': 'Она светлая, он светлый',
          'ar': 'هي فاتحة، هو فاتح',
          'hi': 'महिला गोरी, पुरुष गोरा',
          'bn': 'নারী ফর্সা, পুরুষ ফর্সা',
          'pt': 'Ela clara, ele claro',
        });
      case 'negra':
        return _t({
          'es': 'Ella oscura, él oscuro',
          'en': 'Her dark, his dark',
          'fr': 'Elle foncée, lui foncé',
          'de': 'Sie dunkel, er dunkel',
          'ru': 'Она тёмная, он тёмный',
          'ar': 'هي داكنة، هو داكن',
          'hi': 'महिला सांवली, पुरुष सांवला',
          'bn': 'নারী কালো, পুরুষ কালো',
          'pt': 'Ela escura, ele escuro',
        });
      case 'lesbica':
        return _t({
          'es': 'Ella y ella',
          'en': 'Her and her',
          'fr': 'Elle et elle',
          'de': 'Sie und sie',
          'ru': 'Она и она',
          'ar': 'هي وهي',
          'hi': 'महिला और महिला',
          'bn': 'নারী ও নারী',
          'pt': 'Ela e ela',
        });
      case 'mixta':
      default:
        return _t({
          'es': 'Ella clara, él oscuro',
          'en': 'Her light, his dark',
          'fr': 'Elle claire, lui foncé',
          'de': 'Sie hell, er dunkel',
          'ru': 'Она светлая, он тёмный',
          'ar': 'هي فاتحة، هو داكن',
          'hi': 'महिला गोरी, पुरुष सांवला',
          'bn': 'নারী ফর্সা, পুরুষ কালো',
          'pt': 'Ela clara, ele escuro',
        });
    }
  }

  String get settingsPregnancyTitle =>
      _t({'es': 'Modo embarazo', 'en': 'Pregnancy mode', 'fr': 'Mode grossesse', 'de': 'Schwangerschaftsmodus', 'ru': 'Режим беременности', 'ar': 'وضع الحمل', 'hi': 'गर्भावस्था मोड', 'bn': 'গর্ভাবস্থা মোড', 'pt': 'Modo gravidez'});
  String get settingsPregnancyToggle =>
      _t({'es': '🤰 Activar modo embarazo', 'en': '🤰 Enable pregnancy mode', 'fr': '🤰 Activer le mode grossesse', 'de': '🤰 Schwangerschaftsmodus aktivieren', 'ru': '🤰 Включить режим беременности', 'ar': '🤰 تفعيل وضع الحمل', 'hi': '🤰 गर्भावस्था मोड चालू करें', 'bn': '🤰 গর্ভাবস্থা মোড চালু করুন', 'pt': '🤰 Ativar modo gravidez'});
  String get settingsLmpLabel => _t({
        'es': 'Fecha de último periodo',
        'en': 'Last period date',
        'fr': 'Date des dernières règles',
        'de': 'Datum der letzten Periode',
        'ru': 'Дата последней менструации',
        'ar': 'تاريخ آخر دورة شهرية',
        'hi': 'आखिरी पीरियड की तारीख',
        'bn': 'শেষ পিরিয়ডের তারিখ',
        'pt': 'Data da última menstruação',
      });

  // ---- Ciclo irregular ----
  // Interruptor manual para personas cuyo ciclo varía demasiado como para
  // confiar en una fecha exacta de predicción. Al activarlo, CyclePredictor
  // amplía el rango mostrado ("entre el 12 y el 19") en vez de dar una
  // fecha única, incluso si el historial de ciclos aún no es suficiente
  // para detectar la irregularidad automáticamente.
  String get settingsIrregularCycleTitle =>
      _t({'es': 'Ciclo irregular', 'en': 'Irregular cycle', 'fr': 'Cycle irrégulier', 'de': 'Unregelmäßiger Zyklus', 'ru': 'Нерегулярный цикл', 'ar': 'دورة غير منتظمة', 'hi': 'अनियमित चक्र', 'bn': 'অনিয়মিত চক্র', 'pt': 'Ciclo irregular'});
  String get settingsIrregularCycleToggle => _t({
        'es': '🔀 Mi ciclo es irregular',
        'en': '🔀 My cycle is irregular',
        'fr': '🔀 Mon cycle est irrégulier',
        'de': '🔀 Mein Zyklus ist unregelmäßig',
        'ru': '🔀 Мой цикл нерегулярный',
        'ar': '🔀 دورتي غير منتظمة',
        'hi': '🔀 मेरा चक्र अनियमित है',
        'bn': '🔀 আমার চক্র অনিয়মিত',
        'pt': '🔀 Meu ciclo é irregular',
      });
  String get settingsIrregularCycleHint => _t({
        'es':
            'Si activas esto, las predicciones de fecha serán menos exactas pero más realistas: en vez de un día concreto, mostraremos un rango más amplio de días probables.',
        'en':
            "If you turn this on, date predictions will be less precise but more realistic: instead of one exact day, we'll show a wider range of likely days.",
        'fr':
            "Si vous activez ceci, les prédictions de date seront moins précises mais plus réalistes : au lieu d'un jour exact, nous afficherons une plage de jours probables plus large.",
        'de':
            'Wenn du dies aktivierst, werden die Datumsvorhersagen ungenauer, aber realistischer: statt eines genauen Tages zeigen wir eine breitere Spanne wahrscheinlicher Tage.',
        'ru': 'Если ты включишь это, прогнозы дат будут менее точными, но более реалистичными: вместо одного конкретного дня мы покажем более широкий диапазон вероятных дней.',
        'ar': 'إذا فعّلتِ هذا، ستكون توقعات التاريخ أقل دقة لكن أكثر واقعية: بدلاً من يوم محدد، سنعرض نطاقًا أوسع من الأيام المحتملة.',
        'hi': 'अगर आप इसे चालू करते हैं, तो तारीख के अनुमान कम सटीक लेकिन ज़्यादा असल जैसे होंगे: एक तय दिन की जगह, हम संभावित दिनों की एक बड़ी सीमा दिखाएंगे।',
        'bn': 'আপনি এটি চালু করলে, তারিখের পূর্বাভাস কম নির্ভুল কিন্তু বেশি বাস্তবসম্মত হবে: একটি নির্দিষ্ট দিনের বদলে, আমরা সম্ভাব্য দিনগুলোর একটি বিস্তৃত পরিসর দেখাবো।',
        'pt': 'Se você ativar isso, as previsões de data serão menos exatas, porém mais realistas: em vez de um dia exato, mostraremos uma faixa mais ampla de dias prováveis.',
      });

  // ---- Sección "Bienestar" (temperatura, agua, sueño, peso) ----
  // Interruptor para ocultar por completo esta sección opcional del
  // registro diario, Estadísticas y Línea de tiempo — pensado para quien
  // no quiere llevar ese seguimiento. Los datos ya guardados no se
  // borran, solo dejan de mostrarse mientras esté desactivado.
  String get settingsWellnessTitle =>
      _t({'es': 'Bienestar', 'en': 'Wellness', 'fr': 'Bien-être', 'de': 'Wohlbefinden', 'ru': 'Самочувствие', 'ar': 'الرفاهية', 'hi': 'स्वास्थ्य', 'bn': 'সুস্থতা', 'pt': 'Bem-estar'});
  String get settingsWellnessToggle => _t({
        'es': '🌿 Mostrar temperatura, agua, sueño y peso',
        'en': '🌿 Show temperature, water, sleep and weight',
        'fr': '🌿 Afficher température, eau, sommeil et poids',
        'de': '🌿 Temperatur, Wasser, Schlaf und Gewicht anzeigen',
        'ru': '🌿 Показывать температуру, воду, сон и вес',
        'ar': '🌿 إظهار درجة الحرارة والماء والنوم والوزن',
        'hi': '🌿 तापमान, पानी, नींद और वज़न दिखाएं',
        'bn': '🌿 তাপমাত্রা, পানি, ঘুম ও ওজন দেখান',
        'pt': '🌿 Mostrar temperatura, água, sono e peso',
      });
  String get settingsWellnessHint => _t({
        'es':
            'Si lo desactivas, esta sección desaparece del registro diario, Estadísticas y Línea de tiempo. Tus datos guardados no se borran: si lo vuelves a activar, reaparecen tal cual.',
        'en':
            "If you turn this off, this section disappears from the daily log, Statistics and Timeline. Your saved data isn't deleted: if you turn it back on, it reappears as-is.",
        'fr':
            "Si vous désactivez ceci, cette section disparaît du journal quotidien, des Statistiques et de la Chronologie. Vos données enregistrées ne sont pas supprimées : si vous réactivez, elles réapparaissent telles quelles.",
        'de':
            'Wenn du dies deaktivierst, verschwindet dieser Abschnitt aus dem Tagesprotokoll, den Statistiken und der Zeitleiste. Deine gespeicherten Daten werden nicht gelöscht: Wenn du es wieder aktivierst, erscheinen sie unverändert.',
        'ru': 'Если ты это выключишь, раздел исчезнет из дневника, Статистики и Хронологии. Твои сохранённые данные не удаляются: если снова включишь, они появятся такими же.',
        'ar': 'إذا أوقفتِ هذا، سيختفي هذا القسم من السجل اليومي والإحصائيات والجدول الزمني. بياناتك المحفوظة لن تُحذف: إذا أعدتِ تفعيله، ستظهر كما هي.',
        'hi': 'अगर आप इसे बंद करते हैं, तो यह सेक्शन दैनिक रिकॉर्ड, आंकड़े और टाइमलाइन से हट जाएगा। आपका सेव किया गया डेटा डिलीट नहीं होता: अगर आप इसे दोबारा चालू करते हैं, तो यह वैसे का वैसा वापस आ जाएगा।',
        'bn': 'আপনি এটি বন্ধ করলে, এই বিভাগটি দৈনিক লগ, পরিসংখ্যান এবং টাইমলাইন থেকে অদৃশ্য হয়ে যাবে। আপনার সংরক্ষিত তথ্য মুছে যায় না: আবার চালু করলে, তা যেমন ছিল তেমনই ফিরে আসবে।',
        'pt': 'Se você desativar isso, esta seção desaparece do registro diário, das Estatísticas e da Linha do tempo. Seus dados salvos não são apagados: se você ativar de novo, eles reaparecem como estavam.',
      });
  String get dayEditorWellnessDisableQuick => _t({
        'es': 'Ocultar esta sección',
        'en': 'Hide this section',
        'fr': 'Masquer cette section',
        'de': 'Diesen Abschnitt ausblenden',
        'ru': 'Скрыть этот раздел',
        'ar': 'إخفاء هذا القسم',
        'hi': 'यह सेक्शन छिपाएं',
        'bn': 'এই বিভাগ লুকান',
        'pt': 'Ocultar esta seção',
      });
  String get dayEditorWellnessEnableQuick => _t({
        'es': 'Mostrar esta sección',
        'en': 'Show this section',
        'fr': 'Afficher cette section',
        'de': 'Diesen Abschnitt anzeigen',
        'ru': 'Показать этот раздел',
        'ar': 'إظهار هذا القسم',
        'hi': 'यह सेक्शन दिखाएं',
        'bn': 'এই বিভাগ দেখান',
        'pt': 'Mostrar esta seção',
      });
  String get dayEditorWellnessDisabledConfirm => _t({
        'es': 'Bienestar oculto. Puedes reactivarlo aquí mismo o en Configuración cuando quieras.',
        'en': 'Wellness hidden. You can turn it back on right here or in Settings anytime.',
        'fr': 'Bien-être masqué. Vous pouvez le réactiver ici même ou dans Paramètres à tout moment.',
        'de': 'Wohlbefinden ausgeblendet. Du kannst es genau hier oder jederzeit in den Einstellungen wieder aktivieren.',
        'ru': 'Раздел «Самочувствие» скрыт. Ты можешь снова включить его прямо здесь или в Настройках в любое время.',
        'ar': 'تم إخفاء قسم الرفاهية. يمكنك إعادة تفعيله من هنا أو من الإعدادات في أي وقت.',
        'hi': 'स्वास्थ्य सेक्शन छिपा दिया गया है। आप इसे यहीं से या जब चाहें सेटिंग्स में फिर से चालू कर सकते हैं।',
        'bn': 'সুস্থতা বিভাগ লুকানো হয়েছে। আপনি এখানেই বা যেকোনো সময় সেটিংসে গিয়ে এটি আবার চালু করতে পারেন।',
        'pt': 'Bem-estar ocultado. Você pode reativá-lo bem aqui ou nas Configurações quando quiser.',
      });
  String get dayEditorWellnessEnabledConfirm => _t({
        'es': 'Bienestar activado de nuevo.',
        'en': 'Wellness turned back on.',
        'fr': 'Bien-être réactivé.',
        'de': 'Wohlbefinden wieder aktiviert.',
        'ru': 'Раздел «Самочувствие» снова включён.',
        'ar': 'تم إعادة تفعيل قسم الرفاهية.',
        'hi': 'स्वास्थ्य सेक्शन फिर से चालू कर दिया गया है।',
        'bn': 'সুস্থতা বিভাগ আবার চালু করা হয়েছে।',
        'pt': 'Bem-estar ativado novamente.',
      });

  String get settingsPillTitle => _t({
        'es': 'Recordatorio de anticonceptivo',
        'en': 'Birth control reminder',
        'fr': 'Rappel de contraception',
        'de': 'Erinnerung an Verhütung',
        'ru': 'Напоминание о контрацепции',
        'ar': 'تذكير بوسيلة منع الحمل',
        'hi': 'गर्भनिरोधक रिमाइंडर',
        'bn': 'জন্মনিয়ন্ত্রণ রিমাইন্ডার',
        'pt': 'Lembrete de anticoncepcional',
      });
  String get settingsPillToggle => _t({
        'es': '💊 Recuérdame tomar la pastilla',
        'en': '💊 Remind me to take the pill',
        'fr': '💊 Me rappeler de prendre la pilule',
        'de': '💊 Erinnere mich an die Pille',
        'ru': '💊 Напоминай мне принять таблетку',
        'ar': '💊 ذكّريني بأخذ حبة منع الحمل',
        'hi': '💊 मुझे गोली लेने की याद दिलाएं',
        'bn': '💊 আমাকে পিল খাওয়ার কথা মনে করিয়ে দিন',
        'pt': '💊 Me lembrar de tomar a pílula',
      });

  String get settingsDailyTitle =>
      _t({'es': 'Recordatorio diario', 'en': 'Daily reminder', 'fr': 'Rappel quotidien', 'de': 'Tägliche Erinnerung', 'ru': 'Ежедневное напоминание', 'ar': 'تذكير يومي', 'hi': 'दैनिक रिमाइंडर', 'bn': 'দৈনিক রিমাইন্ডার', 'pt': 'Lembrete diário'});
  String get settingsDailyToggle => _t({
        'es': '✍️ Recuérdame registrar mi día',
        'en': '✍️ Remind me to log my day',
        'fr': '✍️ Me rappeler de noter ma journée',
        'de': '✍️ Erinnere mich, meinen Tag einzutragen',
        'ru': '✍️ Напоминай мне отмечать свой день',
        'ar': '✍️ ذكّريني بتسجيل يومي',
        'hi': '✍️ मुझे अपना दिन दर्ज करने की याद दिलाएं',
        'bn': '✍️ আমাকে আমার দিন লগ করার কথা মনে করিয়ে দিন',
        'pt': '✍️ Me lembrar de registrar meu dia',
      });

  String settingsActiveAt(String time) =>
      _t({'es': 'Activado a las $time', 'en': 'On at $time', 'fr': 'Activé à $time', 'de': 'Aktiv um $time', 'ru': 'Включено в $time', 'ar': 'مفعّل في الساعة $time', 'hi': '$time बजे चालू', 'bn': '$time-এ চালু', 'pt': 'Ativado às $time'});

  String get settingsHour => _t({'es': 'Hora', 'en': 'Time', 'fr': 'Heure', 'de': 'Uhrzeit', 'ru': 'Время', 'ar': 'الوقت', 'hi': 'समय', 'bn': 'সময়', 'pt': 'Hora'});
  String get settingsChooseDate => _t({'es': 'Elegir fecha', 'en': 'Choose date', 'fr': 'Choisir une date', 'de': 'Datum wählen', 'ru': 'Выбрать дату', 'ar': 'اختيار التاريخ', 'hi': 'तारीख चुनें', 'bn': 'তারিখ বেছে নিন', 'pt': 'Escolher data'});

  String get settingsDiaryTitle =>
      _t({'es': 'Registro diario', 'en': 'Daily log', 'fr': 'Journal quotidien', 'de': 'Tagesprotokoll', 'ru': 'Дневник', 'ar': 'السجل اليومي', 'hi': 'दैनिक रिकॉर्ड', 'bn': 'দৈনিক লগ', 'pt': 'Registro diário'});
  String get settingsSexAlwaysVisible => _t({
        'es': '❤️ Mostrar "Vida sexual" siempre visible',
        'en': '❤️ Always show "Sex life"',
        'fr': '❤️ Toujours afficher "Vie sexuelle"',
        'de': '❤️ „Sexualleben" immer anzeigen',
        'ru': '❤️ Всегда показывать «Интимная жизнь»',
        'ar': '❤️ إظهار "الحياة الجنسية" دائمًا', 'hi': '❤️ "यौन जीवन" हमेशा दिखाएं', 'bn': '❤️ "যৌন জীবন" সবসময় দেখান', 'pt': '❤️ Mostrar "Vida sexual" sempre visível',
      });
  String get settingsSexAlwaysVisibleOn => _t({
        'es': 'Se muestra junto a Flujo y Síntomas',
        'en': 'Shown next to Flow and Symptoms',
        'fr': 'Affiché à côté de Flux et Symptômes',
        'de': 'Wird neben Blutung und Symptomen angezeigt',
        'ru': 'Показывается рядом с Выделениями и Симптомами',
        'ar': 'يظهر بجانب الإفرازات والأعراض', 'hi': 'फ्लो और लक्षणों के साथ दिखाया जाता है', 'bn': 'ফ্লো ও লক্ষণের পাশে দেখানো হয়', 'pt': 'Aparece junto com Fluxo e Sintomas',
      });
  String get settingsSexAlwaysVisibleOff => _t({
        'es': 'Está dentro de "Más detalles" (opcional)',
        'en': 'Inside "More details" (optional)',
        'fr': 'Dans "Plus de détails" (facultatif)',
        'de': 'In „Mehr Details" (optional)',
        'ru': 'Находится внутри «Больше деталей» (необязательно)',
        'ar': 'داخل "مزيد من التفاصيل" (اختياري)', 'hi': 'यह "और विवरण" में मौजूद है (वैकल्पिक)', 'bn': 'এটি "আরও বিস্তারিত"-এর মধ্যে আছে (ঐচ্ছিক)', 'pt': 'Está dentro de "Mais detalhes" (opcional)',
      });

  String get settingsProfileTitle => _t({'es': 'Mi perfil', 'en': 'My profile', 'fr': 'Mon profil', 'de': 'Mein Profil', 'ru': 'Мой профиль', 'ar': 'ملفي الشخصي', 'hi': 'मेरी प्रोफ़ाइल', 'bn': 'আমার প্রোফাইল', 'pt': 'Meu perfil'});
  String get settingsHeightLabel => _t({'es': 'Talla', 'en': 'Height', 'fr': 'Taille', 'de': 'Größe', 'ru': 'Рост', 'ar': 'الطول', 'hi': 'कद', 'bn': 'উচ্চতা', 'pt': 'Altura'});
  String get settingsHeightHint => _t({
        'es': 'Con tu altura calculamos tu IMC en Estadísticas usando el último peso que registres.',
        'en': "With your height, we calculate your BMI in Statistics using the last weight you log.",
        'fr': "Avec votre taille, nous calculons votre IMC dans Statistiques à partir de votre dernier poids enregistré.",
        'de': 'Mit deiner Größe berechnen wir deinen BMI in Statistiken anhand deines zuletzt eingetragenen Gewichts.',
        'ru': 'По твоему росту мы рассчитываем твой ИМТ в Статистике, используя последний записанный вес.',
        'ar': 'باستخدام طولك، نحسب مؤشر كتلة الجسم في الإحصائيات بالاعتماد على آخر وزن تسجّلينه.', 'hi': 'आपकी लंबाई से हम आपके द्वारा दर्ज किए गए आखिरी वज़न का उपयोग करके आंकड़ों में आपका बीएमआई निकालते हैं।', 'bn': 'আপনার উচ্চতা দিয়ে আমরা আপনার সবশেষ লগ করা ওজন ব্যবহার করে পরিসংখ্যানে আপনার বিএমআই হিসাব করি।', 'pt': 'Com sua altura, calculamos seu IMC nas Estatísticas usando o último peso que você registrar.',
      });
  String get profileNameLabel => _t({'es': 'Nombre', 'en': 'Name', 'fr': 'Prénom', 'de': 'Name', 'ru': 'Имя', 'ar': 'الاسم', 'hi': 'नाम', 'bn': 'নাম', 'pt': 'Nome'});
  String get profileNameHint => _t({'es': 'Ej. Ana', 'en': 'E.g. Anna', 'fr': 'Ex. Anna', 'de': 'Z. B. Anna', 'ru': 'Напр. Анна', 'ar': 'مثال: سارة', 'hi': 'उदा. अंजलि', 'bn': 'যেমন: অন্তরা', 'pt': 'Ex. Ana'});
  String get profileBirthDateLabel =>
      _t({'es': 'Fecha de nacimiento', 'en': 'Date of birth', 'fr': 'Date de naissance', 'de': 'Geburtsdatum', 'ru': 'Дата рождения', 'ar': 'تاريخ الميلاد', 'hi': 'जन्म तिथि', 'bn': 'জন্ম তারিখ', 'pt': 'Data de nascimento'});
  String get profileReferenceWeightLabel => _t({
        'es': 'Peso de referencia',
        'en': 'Reference weight',
        'fr': 'Poids de référence',
        'de': 'Referenzgewicht',
        'ru': 'Контрольный вес',
        'ar': 'الوزن المرجعي',
        'hi': 'संदर्भ वज़न',
        'bn': 'রেফারেন্স ওজন',
        'pt': 'Peso de referência',
      });
  String get profileReferenceWeightHint => _t({
        'es': 'Opcional, distinto del peso diario de Bienestar.',
        'en': 'Optional, separate from the daily weight in Wellness.',
        'fr': 'Facultatif, distinct du poids quotidien de Bien-être.',
        'de': 'Optional, unabhängig vom täglichen Gewicht in Wohlbefinden.',
        'ru': 'Необязательно, отличается от ежедневного веса в разделе «Самочувствие».',
        'ar': 'اختياري، ويختلف عن الوزن اليومي في قسم الرفاهية.',
        'hi': 'वैकल्पिक, वेलनेस के दैनिक वजन से अलग।',
        'bn': 'ঐচ্ছিক, ওয়েলনেসের দৈনিক ওজন থেকে আলাদা।',
        'pt': 'Opcional, diferente do peso diário em Bem-estar.',
      });
  String get profileLastNameLabel =>
      _t({'es': 'Apellido', 'en': 'Last name', 'fr': 'Nom de famille', 'de': 'Nachname', 'ru': 'Фамилия', 'ar': 'اسم العائلة', 'hi': 'उपनाम', 'bn': 'পদবি', 'pt': 'Sobrenome'});
  String get profileLastNameHint => _t({
        'es': 'Opcional, ej. Gómez',
        'en': 'Optional, e.g. Smith',
        'fr': 'Facultatif, ex. Dupont',
        'de': 'Optional, z. B. Müller',
        'ru': 'Необязательно, напр. Иванова',
        'ar': 'اختياري، مثال: العلي',
        'hi': 'वैकल्पिक, जैसे शर्मा',
        'bn': 'ঐচ্ছিক, যেমন সেন',
        'pt': 'Opcional, ex. Silva',
      });
  String get profileNotSet =>
      _t({'es': 'Sin definir', 'en': 'Not set', 'fr': 'Non défini', 'de': 'Nicht angegeben', 'ru': 'Не указано', 'ar': 'غير محدد', 'hi': 'निर्धारित नहीं', 'bn': 'নির্ধারিত নয়', 'pt': 'Não definido'});

  // ---- Configuración > Datos (editar nombre, apellido, fecha de
  // nacimiento, talla y peso de referencia) ----
  String get settingsDataTitle => _t({'es': 'Datos', 'en': 'Data', 'fr': 'Données', 'de': 'Daten', 'ru': 'Данные', 'ar': 'البيانات', 'hi': 'डेटा', 'bn': 'তথ্য', 'pt': 'Dados'});
  String get settingsDataHint => _t({
        'es': 'Edita tu nombre, edad, talla y peso de referencia.',
        'en': 'Edit your name, age, height and reference weight.',
        'fr': 'Modifiez votre prénom, âge, taille et poids de référence.',
        'de': 'Bearbeite deinen Namen, dein Alter, deine Größe und dein Referenzgewicht.',
        'ru': 'Измени своё имя, возраст, рост и контрольный вес.',
        'ar': 'عدّلي اسمك وعمرك وطولك ووزنك المرجعي.',
        'hi': 'अपना नाम, उम्र, कद और संदर्भ वजन संपादित करें।',
        'bn': 'আপনার নাম, বয়স, উচ্চতা এবং রেফারেন্স ওজন সম্পাদনা করুন।',
        'pt': 'Edite seu nome, idade, altura e peso de referência.',
      });
  String get settingsDataEdit => _t({'es': 'Editar datos', 'en': 'Edit data', 'fr': 'Modifier les données', 'de': 'Daten bearbeiten', 'ru': 'Редактировать данные', 'ar': 'تعديل البيانات', 'hi': 'डेटा संपादित करें', 'bn': 'তথ্য সম্পাদনা করুন', 'pt': 'Editar dados'});
  String get settingsDataDialogTitle =>
      _t({'es': 'Editar mis datos', 'en': 'Edit my data', 'fr': 'Modifier mes données', 'de': 'Meine Daten bearbeiten', 'ru': 'Редактировать мои данные', 'ar': 'تعديل بياناتي', 'hi': 'मेरा डेटा संपादित करें', 'bn': 'আমার তথ্য সম্পাদনা করুন', 'pt': 'Editar meus dados'});

  String get settingsBackupTitle =>
      _t({'es': 'Copia de seguridad', 'en': 'Backup', 'fr': 'Sauvegarde', 'de': 'Sicherung', 'ru': 'Резервная копия', 'ar': 'النسخ الاحتياطي', 'hi': 'बैकअप', 'bn': 'ব্যাকআপ', 'pt': 'Backup'});
  String get settingsBackupHint => _t({
        'es': 'Descarga tus datos como archivo, o restáuralos en otro dispositivo.',
        'en': 'Download your data as a file, or restore it on another device.',
        'fr': 'Téléchargez vos données sous forme de fichier ou restaurez-les sur un autre appareil.',
        'de': 'Lade deine Daten als Datei herunter oder stelle sie auf einem anderen Gerät wieder her.',
        'ru': 'Скачай свои данные в виде файла или восстанови их на другом устройстве.',
        'ar': 'حمّلي بياناتك كملف، أو استعيديها على جهاز آخر.',
        'hi': 'अपना डेटा फ़ाइल के रूप में डाउनलोड करें, या किसी अन्य डिवाइस पर पुनर्स्थापित करें।',
        'bn': 'আপনার তথ্য ফাইল হিসেবে ডাউনলোড করুন, অথবা অন্য ডিভাইসে পুনরুদ্ধার করুন।',
        'pt': 'Baixe seus dados como arquivo, ou restaure-os em outro dispositivo.',
      });
  String get settingsExport => _t({'es': '⬇️ Exportar datos', 'en': '⬇️ Export data', 'fr': '⬇️ Exporter les données', 'de': '⬇️ Daten exportieren', 'ru': '⬇️ Экспортировать данные', 'ar': '⬇️ تصدير البيانات', 'hi': '⬇️ डेटा निर्यात करें', 'bn': '⬇️ তথ্য এক্সপোর্ট করুন', 'pt': '⬇️ Exportar dados'});
  String get settingsImport => _t({'es': '⬆️ Importar datos', 'en': '⬆️ Import data', 'fr': '⬆️ Importer les données', 'de': '⬆️ Daten importieren', 'ru': '⬆️ Импортировать данные', 'ar': '⬆️ استيراد البيانات', 'hi': '⬆️ डेटा आयात करें', 'bn': '⬆️ তথ্য ইমপোর্ট করুন', 'pt': '⬆️ Importar dados'});

  String get settingsPrivacyTitle =>
      _t({'es': 'Privacidad', 'en': 'Privacy', 'fr': 'Confidentialité', 'de': 'Datenschutz', 'ru': 'Конфиденциальность', 'ar': 'الخصوصية', 'hi': 'गोपनीयता', 'bn': 'গোপনীয়তা', 'pt': 'Privacidade'});
  String get settingsPrivacyHint => _t({
        'es': 'Consulta cómo protegemos y usamos tus datos.',
        'en': 'See how we protect and use your data.',
        'fr': 'Découvrez comment nous protégeons et utilisons vos données.',
        'de': 'Erfahre, wie wir deine Daten schützen und verwenden.',
        'ru': 'Узнай, как мы защищаем и используем твои данные.',
        'ar': 'اطّلعي على كيفية حمايتنا واستخدامنا لبياناتك.',
        'hi': 'देखें कि हम आपके डेटा की सुरक्षा और उपयोग कैसे करते हैं।',
        'bn': 'আমরা কীভাবে আপনার তথ্য সুরক্ষিত ও ব্যবহার করি তা দেখুন।',
        'pt': 'Veja como protegemos e usamos seus dados.',
      });
  String get settingsPrivacyPolicyLink =>
      _t({'es': 'Ver política de privacidad', 'en': 'View privacy policy', 'fr': 'Voir la politique de confidentialité', 'de': 'Datenschutzrichtlinie ansehen', 'ru': 'Посмотреть политику конфиденциальности', 'ar': 'عرض سياسة الخصوصية', 'hi': 'गोपनीयता नीति देखें', 'bn': 'গোপনীয়তা নীতি দেখুন', 'pt': 'Ver política de privacidade'});
  String get settingsPrivacyPolicyError => _t({
        'es': 'No se pudo abrir el enlace. Inténtalo de nuevo.',
        'en': "Couldn't open the link. Please try again.",
        'fr': "Impossible d'ouvrir le lien. Veuillez réessayer.",
        'de': 'Der Link konnte nicht geöffnet werden. Bitte versuche es erneut.',
        'ru': 'Не удалось открыть ссылку. Попробуй ещё раз.',
        'ar': 'تعذّر فتح الرابط. حاولي مرة أخرى.',
        'hi': 'लिंक नहीं खोला जा सका। कृपया फिर से प्रयास करें।',
        'bn': 'লিংকটি খোলা যায়নি। আবার চেষ্টা করুন।',
        'pt': 'Não foi possível abrir o link. Tente novamente.',
      });

  String get settingsAppointmentsTitle =>
      _t({'es': 'Citas médicas', 'en': 'Medical appointments', 'fr': 'Rendez-vous médicaux', 'de': 'Arzttermine', 'ru': 'Медицинские приёмы', 'ar': 'المواعيد الطبية', 'hi': 'चिकित्सा नियुक्तियाँ', 'bn': 'চিকিৎসা অ্যাপয়েন্টমেন্ট', 'pt': 'Consultas médicas'});
  String get settingsAppointmentsHint => _t({
        'es': 'Guarda tus citas (ginecólogo, revisiones, análisis) y te avisamos ese día.',
        'en': "Save your appointments (gynecologist, check-ups, tests) and we'll remind you that day.",
        'fr': 'Enregistrez vos rendez-vous (gynécologue, contrôles, analyses) et nous vous préviendrons ce jour-là.',
        'de': 'Speichere deine Termine (Frauenarzt, Vorsorge, Untersuchungen) und wir erinnern dich an diesem Tag.',
        'ru': 'Сохраняй свои приёмы (гинеколог, осмотры, анализы), и мы напомним тебе в этот день.',
        'ar': 'احفظي مواعيدك (طبيبة النساء، الفحوصات، التحاليل) وسنذكّرك في ذلك اليوم.',
        'hi': 'अपनी नियुक्तियाँ (स्त्री रोग विशेषज्ञ, जांच, टेस्ट) सेव करें और हम उस दिन आपको याद दिलाएंगे।',
        'bn': 'আপনার অ্যাপয়েন্টমেন্ট (স্ত্রীরোগ বিশেষজ্ঞ, চেকআপ, পরীক্ষা) সংরক্ষণ করুন এবং আমরা সেদিন আপনাকে মনে করিয়ে দেব।',
        'pt': 'Salve suas consultas (ginecologista, check-ups, exames) e avisaremos você naquele dia.',
      });
  String get settingsAppointmentsEmpty => _t({
        'es': 'No tienes citas guardadas todavía.',
        'en': "You don't have any saved appointments yet.",
        'fr': "Vous n'avez pas encore de rendez-vous enregistrés.",
        'de': 'Du hast noch keine gespeicherten Termine.',
        'ru': 'У тебя пока нет сохранённых приёмов.',
        'ar': 'ليس لديك مواعيد محفوظة بعد.',
        'hi': 'अभी तक आपकी कोई सहेजी गई नियुक्ति नहीं है।',
        'bn': 'এখনও আপনার কোনো সংরক্ষিত অ্যাপয়েন্টমেন্ট নেই।',
        'pt': 'Você ainda não tem consultas salvas.',
      });
  String get settingsAppointmentAdd =>
      _t({'es': '+ Añadir cita', 'en': '+ Add appointment', 'fr': '+ Ajouter un rendez-vous', 'de': '+ Termin hinzufügen', 'ru': '+ Добавить приём', 'ar': '+ إضافة موعد', 'hi': '+ नियुक्ति जोड़ें', 'bn': '+ অ্যাপয়েন্টমেন্ট যোগ করুন', 'pt': '+ Adicionar consulta'});
  String get settingsAppointmentLabelHint => _t({
        'es': 'Ej. Ginecólogo, Papanicolau, mamografía...',
        'en': 'E.g. Gynecologist, Pap smear, mammogram...',
        'fr': 'Ex. Gynécologue, frottis, mammographie...',
        'de': 'Z. B. Frauenarzt, Abstrich, Mammografie ...',
        'ru': 'Напр. Гинеколог, мазок Папаниколау, маммография...',
        'ar': 'مثال: طبيبة النساء، مسحة عنق الرحم، تصوير الثدي...',
        'hi': 'जैसे स्त्री रोग विशेषज्ञ, पैप स्मीयर, मैमोग्राम...',
        'bn': 'যেমন স্ত্রীরোগ বিশেষজ্ঞ, প্যাপ স্মিয়ার, ম্যামোগ্রাম...',
        'pt': 'Ex. Ginecologista, Papanicolau, mamografia...',
      });
  String get settingsAppointmentDialogTitle =>
      _t({'es': 'Nueva cita médica', 'en': 'New appointment', 'fr': 'Nouveau rendez-vous', 'de': 'Neuer Termin', 'ru': 'Новый медицинский приём', 'ar': 'موعد طبي جديد', 'hi': 'नई चिकित्सा नियुक्ति', 'bn': 'নতুন চিকিৎসা অ্যাপয়েন্টমেন্ট', 'pt': 'Nova consulta médica'});
  String get settingsAppointmentPickDate =>
      _t({'es': 'Elegir fecha y hora', 'en': 'Choose date and time', 'fr': 'Choisir la date et l\'heure', 'de': 'Datum und Uhrzeit wählen', 'ru': 'Выбрать дату и время', 'ar': 'اختيار التاريخ والوقت', 'hi': 'तारीख और समय चुनें', 'bn': 'তারিখ ও সময় বেছে নিন', 'pt': 'Escolher data e hora'});
  String get settingsAppointmentSave => _t({'es': 'Guardar cita', 'en': 'Save appointment', 'fr': 'Enregistrer', 'de': 'Termin speichern', 'ru': 'Сохранить приём', 'ar': 'حفظ الموعد', 'hi': 'नियुक्ति सहेजें', 'bn': 'অ্যাপয়েন্টমেন্ট সংরক্ষণ করুন', 'pt': 'Salvar consulta'});
  String get settingsAppointmentDelete =>
      _t({'es': 'Eliminar cita', 'en': 'Delete appointment', 'fr': 'Supprimer le rendez-vous', 'de': 'Termin löschen', 'ru': 'Удалить приём', 'ar': 'حذف الموعد', 'hi': 'नियुक्ति हटाएं', 'bn': 'অ্যাপয়েন্টমেন্ট মুছুন', 'pt': 'Excluir consulta'});

  String get settingsHealthSyncTitle => _t({
        'es': 'Apple Salud / Google Fit',
        'en': 'Apple Health / Google Fit',
        'fr': 'Apple Santé / Google Fit',
        'de': 'Apple Health / Google Fit',
        'ru': 'Apple Health / Google Fit',
        'ar': 'Apple Health / Google Fit',
        'hi': 'Apple Health / Google Fit',
        'bn': 'Apple Health / Google Fit',
        'pt': 'Apple Saúde / Google Fit',
      });
  String get settingsHealthSyncToggle => _t({
        'es': '🔗 Sincronizar peso, sueño y temperatura',
        'en': '🔗 Sync weight, sleep and temperature',
        'fr': '🔗 Synchroniser poids, sommeil et température',
        'de': '🔗 Gewicht, Schlaf und Temperatur synchronisieren',
        'ru': '🔗 Синхронизировать вес, сон и температуру',
        'ar': '🔗 مزامنة الوزن والنوم ودرجة الحرارة',
        'hi': '🔗 वजन, नींद और तापमान सिंक करें',
        'bn': '🔗 ওজন, ঘুম ও তাপমাত্রা সিঙ্ক করুন',
        'pt': '🔗 Sincronizar peso, sono e temperatura',
      });
  String get settingsHealthSyncHint => _t({
        'es': 'Si ya registras estos datos en Salud o Google Fit, los usamos para completar tu día automáticamente.',
        'en': 'If you already track these in Health or Google Fit, we use them to fill in your day automatically.',
        'fr': "Si vous suivez déjà ces données dans Santé ou Google Fit, nous les utilisons pour compléter votre journée automatiquement.",
        'de': 'Wenn du diese Werte bereits in Health oder Google Fit erfasst, füllen wir damit automatisch deinen Tag aus.',
        'ru': 'Если ты уже отслеживаешь эти данные в Health или Google Fit, мы используем их, чтобы автоматически заполнить твой день.',
        'ar': 'إذا كنتِ تسجّلين هذه البيانات بالفعل في Health أو Google Fit، فسنستخدمها لملء يومك تلقائيًا.',
        'hi': 'यदि आप पहले से ही ये डेटा Health या Google Fit में दर्ज करती हैं, तो हम उनका उपयोग आपके दिन को स्वचालित रूप से पूरा करने के लिए करते हैं।',
        'bn': 'আপনি যদি ইতিমধ্যে Health বা Google Fit-এ এই তথ্য রেকর্ড করেন, তাহলে আমরা তা ব্যবহার করে স্বয়ংক্রিয়ভাবে আপনার দিন পূরণ করি।',
        'pt': 'Se você já registra esses dados no Saúde ou Google Fit, nós os usamos para preencher seu dia automaticamente.',
      });
  String get settingsHealthSyncPermissionDenied => _t({
        'es': 'No pudimos conectar con Salud/Google Fit. Revisa los permisos en los ajustes de tu teléfono.',
        'en': "We couldn't connect to Health/Google Fit. Check the permissions in your phone's settings.",
        'fr': "Impossible de se connecter à Santé/Google Fit. Vérifiez les autorisations dans les réglages de votre téléphone.",
        'de': 'Verbindung zu Health/Google Fit fehlgeschlagen. Prüfe die Berechtigungen in den Einstellungen deines Telefons.',
        'ru': 'Не удалось подключиться к Health/Google Fit. Проверь разрешения в настройках телефона.',
        'ar': 'تعذّر الاتصال بـ Health/Google Fit. تحققي من الأذونات في إعدادات هاتفك.',
        'hi': 'हम Health/Google Fit से कनेक्ट नहीं कर सके। अपने फ़ोन की सेटिंग्स में अनुमतियां जांचें।',
        'bn': 'আমরা Health/Google Fit-এর সঙ্গে সংযোগ করতে পারিনি। আপনার ফোনের সেটিংসে অনুমতিগুলো পরীক্ষা করুন।',
        'pt': 'Não conseguimos conectar ao Saúde/Google Fit. Verifique as permissões nas configurações do seu telefone.',
      });

  String get settingsLanguageTitle => _t({'es': 'Idioma', 'en': 'Language', 'fr': 'Langue', 'de': 'Sprache', 'ru': 'Язык', 'ar': 'اللغة', 'hi': 'भाषा', 'bn': 'ভাষা', 'pt': 'Idioma'});
  String get settingsLanguageHint => _t({
        'es': 'Elige el idioma en el que quieres ver la app.',
        'en': 'Choose the language you want to see the app in.',
        'fr': "Choisissez la langue d'affichage de l'application.",
        'de': 'Wähle die Sprache, in der du die App sehen möchtest.',
        'ru': 'Выбери язык, на котором хочешь видеть приложение.',
        'ar': 'اختاري اللغة التي تريدين رؤية التطبيق بها.',
        'hi': 'वह भाषा चुनें जिसमें आप ऐप देखना चाहती हैं।',
        'bn': 'আপনি যে ভাষায় অ্যাপটি দেখতে চান তা বেছে নিন।',
        'pt': 'Escolha o idioma em que você quer ver o app.',
      });

  String get settingsTitle => _t({'es': 'Configuración', 'en': 'Settings', 'fr': 'Paramètres', 'de': 'Einstellungen', 'ru': 'Настройки', 'ar': 'الإعدادات', 'hi': 'सेटिंग्स', 'bn': 'সেটিংস', 'pt': 'Configurações'});
  String get healthMenuTitle =>
      _t({'es': 'Mi salud', 'en': 'My health', 'fr': 'Ma santé', 'de': 'Meine Gesundheit', 'ru': 'Моё здоровье', 'ar': 'صحتي', 'hi': 'मेरी सेहत', 'bn': 'আমার স্বাস্থ্য', 'pt': 'Minha saúde'});

  // ==================== Ronda 2: resto de la app ====================

  // ---- Meses (nombres completos y abreviados) ----
  static const _monthKeys = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
  ];
  static const Map<String, Map<String, String>> _monthFullTable = {
    'jan': {'es': 'enero', 'en': 'January', 'fr': 'janvier', 'de': 'Januar', 'ru': 'январь', 'ar': 'يناير', 'hi': 'जनवरी', 'bn': 'জানুয়ারি', 'pt': 'janeiro'},
    'feb': {'es': 'febrero', 'en': 'February', 'fr': 'février', 'de': 'Februar', 'ru': 'февраль', 'ar': 'فبراير', 'hi': 'फ़रवरी', 'bn': 'ফেব্রুয়ারি', 'pt': 'fevereiro'},
    'mar': {'es': 'marzo', 'en': 'March', 'fr': 'mars', 'de': 'März', 'ru': 'март', 'ar': 'مارس', 'hi': 'मार्च', 'bn': 'মার্চ', 'pt': 'março'},
    'apr': {'es': 'abril', 'en': 'April', 'fr': 'avril', 'de': 'April', 'ru': 'апрель', 'ar': 'أبريل', 'hi': 'अप्रैल', 'bn': 'এপ্রিল', 'pt': 'abril'},
    'may': {'es': 'mayo', 'en': 'May', 'fr': 'mai', 'de': 'Mai', 'ru': 'май', 'ar': 'مايو', 'hi': 'मई', 'bn': 'মে', 'pt': 'maio'},
    'jun': {'es': 'junio', 'en': 'June', 'fr': 'juin', 'de': 'Juni', 'ru': 'июнь', 'ar': 'يونيو', 'hi': 'जून', 'bn': 'জুন', 'pt': 'junho'},
    'jul': {'es': 'julio', 'en': 'July', 'fr': 'juillet', 'de': 'Juli', 'ru': 'июль', 'ar': 'يوليو', 'hi': 'जुलाई', 'bn': 'জুলাই', 'pt': 'julho'},
    'aug': {'es': 'agosto', 'en': 'August', 'fr': 'août', 'de': 'August', 'ru': 'август', 'ar': 'أغسطس', 'hi': 'अगस्त', 'bn': 'আগস্ট', 'pt': 'agosto'},
    'sep': {'es': 'septiembre', 'en': 'September', 'fr': 'septembre', 'de': 'September', 'ru': 'сентябрь', 'ar': 'سبتمبر', 'hi': 'सितंबर', 'bn': 'সেপ্টেম্বর', 'pt': 'setembro'},
    'oct': {'es': 'octubre', 'en': 'October', 'fr': 'octobre', 'de': 'Oktober', 'ru': 'октябрь', 'ar': 'أكتوبر', 'hi': 'अक्टूबर', 'bn': 'অক্টোবর', 'pt': 'outubro'},
    'nov': {'es': 'noviembre', 'en': 'November', 'fr': 'novembre', 'de': 'November', 'ru': 'ноябрь', 'ar': 'نوفمبر', 'hi': 'नवंबर', 'bn': 'নভেম্বর', 'pt': 'novembro'},
    'dec': {'es': 'diciembre', 'en': 'December', 'fr': 'décembre', 'de': 'Dezember', 'ru': 'декабрь', 'ar': 'ديسمبر', 'hi': 'दिसंबर', 'bn': 'ডিসেম্বর', 'pt': 'dezembro'},
  };
  static const Map<String, Map<String, String>> _monthShortTable = {
    'jan': {'es': 'ene', 'en': 'Jan', 'fr': 'jan', 'de': 'Jan', 'ru': 'янв', 'ar': 'ينا', 'hi': 'जन', 'bn': 'জানু', 'pt': 'jan'},
    'feb': {'es': 'feb', 'en': 'Feb', 'fr': 'fév', 'de': 'Feb', 'ru': 'фев', 'ar': 'فبر', 'hi': 'फ़र', 'bn': 'ফেব্রু', 'pt': 'fev'},
    'mar': {'es': 'mar', 'en': 'Mar', 'fr': 'mar', 'de': 'Mär', 'ru': 'мар', 'ar': 'مار', 'hi': 'मार्च', 'bn': 'মার্চ', 'pt': 'mar'},
    'apr': {'es': 'abr', 'en': 'Apr', 'fr': 'avr', 'de': 'Apr', 'ru': 'апр', 'ar': 'أبر', 'hi': 'अप्रै', 'bn': 'এপ্রিল', 'pt': 'abr'},
    'may': {'es': 'may', 'en': 'May', 'fr': 'mai', 'de': 'Mai', 'ru': 'май', 'ar': 'ماي', 'hi': 'मई', 'bn': 'মে', 'pt': 'mai'},
    'jun': {'es': 'jun', 'en': 'Jun', 'fr': 'jui', 'de': 'Jun', 'ru': 'июн', 'ar': 'يون', 'hi': 'जून', 'bn': 'জুন', 'pt': 'jun'},
    'jul': {'es': 'jul', 'en': 'Jul', 'fr': 'jui', 'de': 'Jul', 'ru': 'июл', 'ar': 'يول', 'hi': 'जुल', 'bn': 'জুলা', 'pt': 'jul'},
    'aug': {'es': 'ago', 'en': 'Aug', 'fr': 'aoû', 'de': 'Aug', 'ru': 'авг', 'ar': 'أغس', 'hi': 'अग', 'bn': 'আগ', 'pt': 'ago'},
    'sep': {'es': 'sep', 'en': 'Sep', 'fr': 'sep', 'de': 'Sep', 'ru': 'сен', 'ar': 'سبت', 'hi': 'सित', 'bn': 'সেপ্ট', 'pt': 'set'},
    'oct': {'es': 'oct', 'en': 'Oct', 'fr': 'oct', 'de': 'Okt', 'ru': 'окт', 'ar': 'أكت', 'hi': 'अक्टू', 'bn': 'অক্টো', 'pt': 'out'},
    'nov': {'es': 'nov', 'en': 'Nov', 'fr': 'nov', 'de': 'Nov', 'ru': 'ноя', 'ar': 'نوف', 'hi': 'नव', 'bn': 'নভে', 'pt': 'nov'},
    'dec': {'es': 'dic', 'en': 'Dec', 'fr': 'déc', 'de': 'Dez', 'ru': 'дек', 'ar': 'ديس', 'hi': 'दिस', 'bn': 'ডিসে', 'pt': 'dez'},
  };

  /// Nombre completo del mes (1-12) en minúsculas para es/fr/de, con
  /// mayúscula inicial en en/de donde corresponde gramaticalmente.
  String monthName(int month) => _t(_monthFullTable[_monthKeys[month - 1]]!);

  /// Abreviatura de 3 letras del mes (1-12).
  String monthShort(int month) => _t(_monthShortTable[_monthKeys[month - 1]]!);

  /// Etiqueta de un día concreto, ej. "7 de agosto" / "August 7".
  String dayLabel(int day, int month) {
    switch (code) {
      case 'en':
        return '${monthName(month)} $day';
      case 'fr':
        return '$day ${monthName(month)}';
      case 'de':
        return '$day. ${monthName(month)}';
      case 'ru':
        const monthsGenitiveRu = [
          'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
          'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
        ];
        return '$day ${monthsGenitiveRu[month - 1]}';
      case 'ar':
        return '$day ${monthName(month)}';
      case 'hi':
        return '$day ${monthName(month)}';
      case 'bn':
        return '$day ${monthName(month)}';
      case 'pt':
        return '$day de ${monthName(month)}';
      case 'es':
      default:
        return '$day de ${monthName(month)}';
    }
  }

  // ---- Días de la semana (iniciales para el calendario) ----
  String get weekdayInitials => _t({'es': 'DLMMJVS', 'en': 'SMTWTFS', 'fr': 'DLMMJVS', 'de': 'SMDMDFS', 'ru': 'ВПВСЧПС', 'ar': 'حنثرخجس', 'hi': 'रसमबगशश', 'bn': 'রসমববশশ', 'pt': 'DSTQQSS'});

  List<String> get weekdayInitialsList => weekdayInitials.split('');

  // ==================== status_card.dart ====================

  String get statusNextPeriodLabel =>
      _t({'es': 'Próximo periodo', 'en': 'Next period', 'fr': 'Prochaines règles', 'de': 'Nächste Periode', 'ru': 'Следующая менструация', 'ar': 'الدورة القادمة', 'hi': 'अगला मासिक धर्म', 'bn': 'পরবর্তী মাসিক', 'pt': 'Próximo período'});
  String get statusFertileWindowLabel =>
      _t({'es': 'Ventana fértil', 'en': 'Fertile window', 'fr': 'Fenêtre fertile', 'de': 'Fruchtbares Fenster', 'ru': 'Фертильное окно', 'ar': 'نافذة الخصوبة', 'hi': 'उपजाऊ अवधि', 'bn': 'উর্বর সময়', 'pt': 'Janela fértil'});
  String get statusRegisterPeriod =>
      _t({'es': 'Registra tu periodo', 'en': 'Log your period', 'fr': 'Enregistrez vos règles', 'de': 'Trage deine Periode ein', 'ru': 'Отметь свой период', 'ar': 'سجّلي دورتك', 'hi': 'अपना मासिक धर्म दर्ज करें', 'bn': 'আপনার মাসিক নথিভুক্ত করুন', 'pt': 'Registre seu período'});
  String get statusToday => _t({'es': 'Hoy', 'en': 'Today', 'fr': "Aujourd'hui", 'de': 'Heute', 'ru': 'Сегодня', 'ar': 'اليوم', 'hi': 'आज', 'bn': 'আজ', 'pt': 'Hoje'});
  String statusInDays(int days) =>
      _t({'es': 'En $days días', 'en': 'In $days days', 'fr': 'Dans $days jours', 'de': 'In $days Tagen', 'ru': 'Через $days дн.', 'ar': 'خلال $days أيام', 'hi': '$days दिनों में', 'bn': '$days দিনে', 'pt': 'Em $days dias'});
  String statusDaysAgo(int days) =>
      _t({'es': 'Hace $days días', 'en': '$days days ago', 'fr': 'Il y a $days jours', 'de': 'Vor $days Tagen', 'ru': '$days дн. назад', 'ar': 'قبل $days أيام', 'hi': '$days दिन पहले', 'bn': '$days দিন আগে', 'pt': 'Há $days dias'});
  String statusRangeDaysAgo(int start, int end) => _t({
        'es': 'Hace $start–$end días',
        'en': '$start–$end days ago',
        'fr': 'Il y a $start–$end jours',
        'de': 'Vor $start–$end Tagen',
        'ru': '$start–$end дн. назад',
        'ar': 'قبل $start–$end أيام',
        'hi': '$start–$end दिन पहले',
        'bn': '$start–$end দিন আগে',
        'pt': 'Há $start–$end dias',
      });
  String statusRangeBetweenTodayAnd(int end) => _t({
        'es': 'Entre hoy y $end días',
        'en': 'Between today and $end days',
        'fr': "Entre aujourd'hui et $end jours",
        'de': 'Zwischen heute und $end Tagen',
        'ru': 'Между сегодня и $end дн.',
        'ar': 'بين اليوم و$end أيام',
        'hi': 'आज और $end दिनों के बीच',
        'bn': 'আজ এবং $end দিনের মধ্যে',
        'pt': 'Entre hoje e $end dias',
      });
  String statusRangeInDays(int start, int end) => _t({
        'es': 'En $start–$end días',
        'en': 'In $start–$end days',
        'fr': 'Dans $start–$end jours',
        'de': 'In $start–$end Tagen',
        'ru': 'Через $start–$end дн.',
        'ar': 'خلال $start–$end أيام',
        'hi': '$start–$end दिनों में',
        'bn': '$start–$end দিনে',
        'pt': 'Em $start–$end dias',
      });
  String get statusFertileEmpty => _t({'es': '—', 'en': '—', 'fr': '—', 'de': '—', 'ru': '—', 'ar': '—', 'hi': '—', 'bn': '—', 'pt': '—'});
  String get statusIrregularNote => _t({
        'es':
            'ℹ️ Tu ciclo varía bastante entre meses, así que mostramos un rango de días (tanto para el periodo como para la ventana fértil) en vez de fechas exactas.',
        'en':
            "ℹ️ Your cycle varies quite a bit month to month, so we show a range of days (for both your period and your fertile window) instead of exact dates.",
        'fr':
            "ℹ️ Votre cycle varie beaucoup d'un mois à l'autre, nous affichons donc une plage de jours (pour les règles et la fenêtre fertile) plutôt que des dates exactes.",
        'de':
            'ℹ️ Dein Zyklus schwankt von Monat zu Monat recht stark, deshalb zeigen wir eine Zeitspanne (für Periode und fruchtbares Fenster) statt genauer Daten.',
        'ru': 'ℹ️ Твой цикл довольно сильно меняется от месяца к месяцу, поэтому мы показываем диапазон дней (как для менструации, так и для фертильного окна) вместо точных дат.',
        'ar': 'ℹ️ تتفاوت دورتك كثيرًا من شهر لآخر، لذا نعرض نطاقًا من الأيام (لكل من الدورة ونافذة الخصوبة) بدلاً من تواريخ دقيقة.',
        'hi': 'ℹ️ आपका चक्र महीने-दर-महीने काफी बदलता है, इसलिए हम सटीक तारीखों के बजाय दिनों की एक सीमा (मासिक धर्म और उपजाऊ अवधि दोनों के लिए) दिखाते हैं।',
        'bn': 'ℹ️ আপনার চক্র মাসে মাসে বেশ পরিবর্তিত হয়, তাই আমরা সুনির্দিষ্ট তারিখের বদলে দিনের একটি পরিসর (মাসিক এবং উর্বর সময় উভয়ের জন্য) দেখাই।',
        'pt': 'ℹ️ Seu ciclo varia bastante de mês a mês, por isso mostramos um intervalo de dias (tanto para o período quanto para a janela fértil) em vez de datas exatas.',
      });

  // ==================== main_tab_screen.dart ====================

  String get phaseNameMenstrual =>
      _t({'es': 'Fase menstrual', 'en': 'Menstrual phase', 'fr': 'Phase menstruelle', 'de': 'Menstruationsphase', 'ru': 'Менструальная фаза', 'ar': 'مرحلة الحيض', 'hi': 'मासिक धर्म चरण', 'bn': 'মাসিক পর্যায়', 'pt': 'Fase menstrual'});
  String get phaseNameFollicular =>
      _t({'es': 'Fase folicular', 'en': 'Follicular phase', 'fr': 'Phase folliculaire', 'de': 'Follikelphase', 'ru': 'Фолликулярная фаза', 'ar': 'المرحلة الجريبية', 'hi': 'फॉलिक्युलर चरण', 'bn': 'ফলিকুলার পর্যায়', 'pt': 'Fase folicular'});
  String get phaseNameOvulation => _t({
        'es': 'Ventana fértil / ovulación',
        'en': 'Fertile window / ovulation',
        'fr': 'Fenêtre fertile / ovulation',
        'de': 'Fruchtbares Fenster / Eisprung',
        'ru': 'Фертильное окно / овуляция',
        'ar': 'نافذة الخصوبة / الإباضة',
        'hi': 'उपजाऊ अवधि / अंडोत्सर्ग',
        'bn': 'উর্বর সময় / ডিম্বস্ফোটন',
        'pt': 'Janela fértil / ovulação',
      });
  String get phaseNameLuteal => _t({'es': 'Fase lútea', 'en': 'Luteal phase', 'fr': 'Phase lutéale', 'de': 'Lutealphase', 'ru': 'Лютеиновая фаза', 'ar': 'المرحلة الأصفرية', 'hi': 'ल्यूटियल चरण', 'bn': 'লুটিয়াল পর্যায়', 'pt': 'Fase lútea'});

  List<String> get phaseTipsMenstrual => [
        _t({
          'es':
              'Tu cuerpo está eliminando el revestimiento uterino. Es normal sentir más cansancio — hidrátate bien y no te exijas de más.',
          'en':
              "Your body is shedding the uterine lining. It's normal to feel more tired — stay hydrated and go easy on yourself.",
          'fr':
              "Votre corps élimine la muqueuse utérine. Il est normal de se sentir plus fatiguée — hydratez-vous bien et ne vous en demandez pas trop.",
          'de':
              'Dein Körper stößt die Gebärmutterschleimhaut ab. Mehr Müdigkeit ist normal — trink ausreichend und überfordere dich nicht.',
          'ru': 'Твоё тело избавляется от слизистой оболочки матки. Это нормально — чувствовать больше усталости: пей больше воды и не перегружай себя.',
          'ar': 'جسمك يتخلص من بطانة الرحم. من الطبيعي أن تشعري بتعب أكبر — اشربي ماء كافيًا ولا تُجهدي نفسكِ.',
          'hi': 'आपका शरीर गर्भाशय की परत को बाहर निकाल रहा है। अधिक थकान महसूस होना सामान्य है — खूब पानी पिएं और खुद पर ज़्यादा दबाव न डालें।',
          'bn': 'আপনার শরীর জরায়ুর আস্তরণ বের করে দিচ্ছে। বেশি ক্লান্তি অনুভব করা স্বাভাবিক — পর্যাপ্ত পানি পান করুন এবং নিজের উপর বেশি চাপ দেবেন না।',
          'pt': 'Seu corpo está eliminando o revestimento uterino. É normal sentir mais cansaço — mantenha-se hidratada e não se cobre demais.',
        }),
        _t({
          'es': 'Un poco de calor local (manta o bolsa térmica) puede ayudar a aliviar los cólicos en estos días.',
          'en': 'A bit of local heat (blanket or heating pad) can help ease cramps these days.',
          'fr': 'Un peu de chaleur locale (couverture ou bouillotte) peut aider à soulager les crampes ces jours-ci.',
          'de': 'Etwas lokale Wärme (Decke oder Wärmflasche) kann in diesen Tagen gegen Krämpfe helfen.',
          'ru': 'Немного локального тепла (одеяло или грелка) может помочь облегчить спазмы в эти дни.',
          'ar': 'القليل من الدفء الموضعي (بطانية أو كمادة دافئة) قد يساعد في تخفيف التقلصات هذه الأيام.',
          'hi': 'थोड़ी स्थानीय गर्माहट (कंबल या हीटिंग पैड) इन दिनों ऐंठन को कम करने में मदद कर सकती है।',
          'bn': 'সামান্য স্থানীয় তাপ (কম্বল বা হিটিং প্যাড) এই দিনগুলোতে পেটব্যথা কমাতে সাহায্য করতে পারে।',
          'pt': 'Um pouco de calor local (cobertor ou bolsa térmica) pode ajudar a aliviar as cólicas nesses dias.',
        }),
        _t({
          'es':
              'El hierro se pierde con el sangrado. Comidas con espinaca, legumbres o carne roja pueden ayudarte a reponerlo.',
          'en':
              'Iron is lost during bleeding. Meals with spinach, legumes or red meat can help you replenish it.',
          'fr':
              "Le fer se perd avec les saignements. Des repas avec épinards, légumineuses ou viande rouge peuvent aider à le reconstituer.",
          'de':
              'Beim Bluten geht Eisen verloren. Mahlzeiten mit Spinat, Hülsenfrüchten oder rotem Fleisch können helfen, es wieder aufzufüllen.',
          'ru': 'С кровотечением теряется железо. Продукты со шпинатом, бобовыми или красным мясом помогут его восполнить.',
          'ar': 'يُفقد الحديد أثناء النزيف. الأطعمة التي تحتوي على السبانخ أو البقوليات أو اللحوم الحمراء يمكن أن تساعدك على تعويضه.',
          'hi': 'रक्तस्राव के दौरान आयरन की कमी होती है। पालक, दालों या रेड मीट वाले भोजन इसकी पूर्ति में मदद कर सकते हैं।',
          'bn': 'রক্তক্ষরণের সময় আয়রন কমে যায়। পালং শাক, ডাল বা লাল মাংসযুক্ত খাবার তা পূরণ করতে সাহায্য করতে পারে।',
          'pt': 'O ferro se perde durante o sangramento. Refeições com espinafre, leguminosas ou carne vermelha podem ajudar a repô-lo.',
        }),
        _t({
          'es': 'El movimiento suave, como caminar o estirar, suele aliviar más el malestar que quedarse quieta.',
          'en': 'Gentle movement, like walking or stretching, often eases discomfort more than staying still.',
          'fr':
              "Un mouvement doux, comme marcher ou s'étirer, soulage souvent mieux l'inconfort que de rester immobile.",
          'de': 'Sanfte Bewegung wie Spazierengehen oder Dehnen lindert Beschwerden oft besser als Stillsitzen.',
          'ru': 'Лёгкое движение, например ходьба или растяжка, обычно облегчает дискомфорт лучше, чем неподвижность.',
          'ar': 'الحركة الخفيفة، مثل المشي أو التمدد، غالبًا ما تخفف الانزعاج أكثر من البقاء ساكنة.',
          'hi': 'हल्की गतिविधि, जैसे टहलना या स्ट्रेचिंग, अक्सर स्थिर बैठने से ज़्यादा असुविधा को कम करती है।',
          'bn': 'হালকা নড়াচড়া, যেমন হাঁটা বা স্ট্রেচিং, প্রায়ই স্থির বসে থাকার চেয়ে বেশি স্বস্তি দেয়।',
          'pt': 'Movimentos leves, como caminhar ou alongar, costumam aliviar mais o desconforto do que ficar parada.',
        }),
      ];

  List<String> get phaseTipsFollicular => [
        _t({
          'es':
              'Tus niveles de energía suelen empezar a subir. Buen momento para retomar rutinas o proyectos que requieran más esfuerzo.',
          'en':
              'Your energy levels usually start rising. A good time to pick back up routines or projects that need more effort.',
          'fr':
              "Votre niveau d'énergie commence généralement à augmenter. Bon moment pour reprendre des routines ou projets plus exigeants.",
          'de':
              'Dein Energielevel steigt normalerweise wieder an. Ein guter Moment, um anspruchsvollere Routinen oder Projekte anzugehen.',
          'ru': 'Твой уровень энергии обычно начинает расти. Хорошее время, чтобы вернуться к рутине или проектам, требующим больше усилий.',
          'ar': 'عادةً ما يبدأ مستوى طاقتك في الارتفاع. وقت جيد لاستئناف الروتين أو المشاريع التي تتطلب مجهودًا أكبر.',
          'hi': 'आपका ऊर्जा स्तर आमतौर पर बढ़ने लगता है। ज़्यादा मेहनत वाली दिनचर्या या परियोजनाओं को फिर से शुरू करने का अच्छा समय है।',
          'bn': 'আপনার শক্তির মাত্রা সাধারণত বাড়তে শুরু করে। বেশি পরিশ্রমের রুটিন বা প্রকল্প আবার শুরু করার ভালো সময়।',
          'pt': 'Seus níveis de energia geralmente começam a subir. Um bom momento para retomar rotinas ou projetos que exigem mais esforço.',
        }),
        _t({
          'es': 'El estrógeno va en aumento: es un buen momento para entrenamientos más intensos si te apetece.',
          'en': "Estrogen is rising: it's a good time for more intense workouts if you feel like it.",
          'fr': "L'œstrogène augmente : c'est un bon moment pour des entraînements plus intenses si vous le souhaitez.",
          'de': 'Der Östrogenspiegel steigt: ein guter Zeitpunkt für intensiveres Training, wenn dir danach ist.',
          'ru': 'Эстроген растёт: это хорошее время для более интенсивных тренировок, если тебе хочется.',
          'ar': 'هرمون الإستروجين في ارتفاع: إنه وقت مناسب لتمارين أكثر كثافة إن رغبتِ في ذلك.',
          'hi': 'एस्ट्रोजन बढ़ रहा है: अगर आपका मन हो तो अधिक तीव्र व्यायाम के लिए यह अच्छा समय है।',
          'bn': 'ইস্ট্রোজেন বাড়ছে: ইচ্ছা হলে এটি আরও তীব্র ব্যায়ামের ভালো সময়।',
          'pt': 'O estrogênio está subindo: é um bom momento para treinos mais intensos, se você quiser.',
        }),
        _t({
          'es':
              'La concentración y la memoria tienden a mejorar en esta fase — aprovéchala para tareas que requieran foco.',
          'en': 'Focus and memory tend to improve in this phase — take advantage of it for tasks that need concentration.',
          'fr':
              "La concentration et la mémoire ont tendance à s'améliorer durant cette phase — profitez-en pour les tâches qui demandent de l'attention.",
          'de':
              'Konzentration und Gedächtnis verbessern sich in dieser Phase oft — nutze sie für Aufgaben, die Fokus erfordern.',
          'ru': 'Концентрация и память обычно улучшаются в этой фазе — используй это время для задач, требующих сосредоточенности.',
          'ar': 'يميل التركيز والذاكرة إلى التحسن في هذه المرحلة — استفيدي منها في المهام التي تتطلب انتباهًا.',
          'hi': 'इस चरण में एकाग्रता और स्मरण शक्ति में सुधार होता है — फोकस चाहने वाले कामों के लिए इसका फायदा उठाएं।',
          'bn': 'এই পর্যায়ে মনোযোগ ও স্মৃতিশক্তি উন্নত হতে থাকে — মনোযোগ প্রয়োজন এমন কাজের জন্য এর সুবিধা নিন।',
          'pt': 'O foco e a memória tendem a melhorar nessa fase — aproveite para tarefas que exigem concentração.',
        }),
        _t({
          'es': 'Tu piel y ánimo suelen notarse mejor ahora. Es un buen momento para planear cosas nuevas.',
          'en': 'Your skin and mood tend to feel better now. A good time to plan new things.',
          'fr': "Votre peau et votre humeur sont généralement meilleures maintenant. Bon moment pour planifier de nouvelles choses.",
          'de': 'Haut und Stimmung fühlen sich jetzt oft besser an. Ein guter Zeitpunkt, um Neues zu planen.',
          'ru': 'Твоя кожа и настроение обычно становятся лучше сейчас. Хорошее время, чтобы планировать что-то новое.',
          'ar': 'عادةً ما تشعرين ببشرة ومزاج أفضل الآن. وقت جيد للتخطيط لأشياء جديدة.',
          'hi': 'आपकी त्वचा और मूड अभी बेहतर महसूस होते हैं। नई चीज़ों की योजना बनाने का अच्छा समय है।',
          'bn': 'আপনার ত্বক ও মেজাজ এখন ভালো অনুভব হয়। নতুন কিছু পরিকল্পনা করার ভালো সময়।',
          'pt': 'Sua pele e humor tendem a melhorar agora. Um bom momento para planejar coisas novas.',
        }),
      ];

  List<String> get phaseTipsOvulation => [
        _t({
          'es': 'Es tu momento de mayor fertilidad. Algunas personas notan más energía y mejor ánimo en estos días.',
          'en': "This is your most fertile time. Some people notice more energy and a better mood these days.",
          'fr': "C'est votre période de fertilité maximale. Certaines personnes remarquent plus d'énergie et une meilleure humeur ces jours-ci.",
          'de': 'Dies ist deine fruchtbarste Zeit. Manche Menschen bemerken in diesen Tagen mehr Energie und bessere Stimmung.',
          'ru': 'Это твой самый фертильный период. Некоторые замечают больше энергии и лучшее настроение в эти дни.',
          'ar': 'هذا هو وقت خصوبتك الأعلى. تلاحظ بعض النساء طاقة أكبر ومزاجًا أفضل في هذه الأيام.',
          'hi': 'यह आपका सबसे उपजाऊ समय है। कुछ लोगों को इन दिनों अधिक ऊर्जा और बेहतर मूड महसूस होता है।',
          'bn': 'এটি আপনার সবচেয়ে উর্বর সময়। কিছু মানুষ এই দিনগুলোতে বেশি শক্তি এবং ভালো মেজাজ লক্ষ্য করেন।',
          'pt': 'Este é o seu período mais fértil. Algumas pessoas notam mais energia e melhor humor nesses dias.',
        }),
        _t({
          'es':
              'Puedes notar un ligero aumento de temperatura basal y cambios en el flujo cervical — señales normales de la ovulación.',
          'en':
              'You may notice a slight rise in basal temperature and changes in cervical fluid — normal signs of ovulation.',
          'fr':
              "Vous pouvez remarquer une légère hausse de la température basale et des changements de la glaire cervicale — signes normaux de l'ovulation.",
          'de':
              'Du bemerkst vielleicht einen leichten Anstieg der Basaltemperatur und Veränderungen im Zervixschleim — normale Anzeichen des Eisprungs.',
          'ru': 'Ты можешь заметить небольшое повышение базальной температуры и изменения цервикальной слизи — нормальные признаки овуляции.',
          'ar': 'قد تلاحظين ارتفاعًا طفيفًا في درجة الحرارة الأساسية وتغيرات في المخاط العنقي — علامات طبيعية للإباضة.',
          'hi': 'आप बेसल तापमान में हल्की वृद्धि और सर्वाइकल द्रव में बदलाव देख सकती हैं — अंडोत्सर्ग के सामान्य संकेत।',
          'bn': 'আপনি বেসাল তাপমাত্রায় সামান্য বৃদ্ধি এবং সার্ভিকাল তরলে পরিবর্তন লক্ষ্য করতে পারেন — ডিম্বস্ফোটনের স্বাভাবিক লক্ষণ।',
          'pt': 'Você pode notar um leve aumento na temperatura basal e mudanças no muco cervical — sinais normais da ovulação.',
        }),
        _t({
          'es': 'Si buscas o evitas un embarazo, estos son los días de mayor probabilidad de concepción.',
          'en': "Whether you're trying to conceive or avoid pregnancy, these are the days with the highest chance of conception.",
          'fr': "Que vous cherchiez à concevoir ou à éviter une grossesse, ce sont les jours où la probabilité de conception est la plus élevée.",
          'de': 'Ob du schwanger werden möchtest oder nicht — dies sind die Tage mit der höchsten Empfängniswahrscheinlichkeit.',
          'ru': 'Хочешь ли ты забеременеть или избежать этого — это дни с наибольшей вероятностью зачатия.',
          'ar': 'سواء كنتِ تسعين للحمل أو تتجنبينه، فهذه هي الأيام ذات الاحتمال الأعلى للحمل.',
          'hi': 'चाहे आप गर्भधारण करना चाहती हों या इससे बचना चाहती हों, ये गर्भधारण की सबसे अधिक संभावना वाले दिन हैं।',
          'bn': 'আপনি গর্ভধারণ করতে চান বা এড়াতে চান, এই দিনগুলোতেই গর্ভধারণের সম্ভাবনা সবচেয়ে বেশি।',
          'pt': 'Seja para engravidar ou evitar a gravidez, estes são os dias com maior chance de concepção.',
        }),
        _t({
          'es':
              'Algunas mujeres sienten una leve molestia de un lado del abdomen (mittelschmerz) — suele ser normal y pasajera.',
          'en':
              'Some women feel mild discomfort on one side of the abdomen (mittelschmerz) — usually normal and short-lived.',
          'fr':
              "Certaines femmes ressentent une légère gêne d'un côté de l'abdomen (mittelschmerz) — généralement normal et passager.",
          'de':
              'Manche Frauen spüren ein leichtes Ziehen auf einer Seite des Unterbauchs (Mittelschmerz) — meist normal und vorübergehend.',
          'ru': 'Некоторые женщины чувствуют лёгкий дискомфорт с одной стороны живота (миттельшмерц) — обычно это нормально и быстро проходит.',
          'ar': 'تشعر بعض النساء بانزعاج خفيف في جانب واحد من البطن (ألم الإباضة) — عادة ما يكون طبيعيًا وعابرًا.',
          'hi': 'कुछ महिलाओं को पेट के एक तरफ हल्की तकलीफ महसूस होती है (मिटेलश्मर्ज़) — आमतौर पर यह सामान्य और अस्थायी होता है।',
          'bn': 'কিছু নারী পেটের একপাশে হালকা অস্বস্তি অনুভব করেন (মিটেলশ্মের্জ) — সাধারণত এটি স্বাভাবিক এবং ক্ষণস্থায়ী।',
          'pt': 'Algumas mulheres sentem um leve desconforto de um lado do abdômen (mittelschmerz) — geralmente normal e passageiro.',
        }),
      ];

  List<String> get phaseTipsLuteal => [
        _t({
          'es':
              'Es común sentir síntomas premenstruales (hinchazón, cambios de ánimo, antojos) en esta fase. Cuídate con calma.',
          'en':
              "It's common to feel premenstrual symptoms (bloating, mood swings, cravings) in this phase. Take it easy on yourself.",
          'fr':
              "Il est courant de ressentir des symptômes prémenstruels (ballonnements, changements d'humeur, envies) durant cette phase. Prenez soin de vous en douceur.",
          'de':
              'In dieser Phase treten häufig prämenstruelle Symptome auf (Blähungen, Stimmungsschwankungen, Heißhunger). Geh achtsam mit dir um.',
          'ru': 'В этой фазе часто ощущаются предменструальные симптомы (вздутие, перепады настроения, тяга к еде). Береги себя спокойно.',
          'ar': 'من الشائع الشعور بأعراض ما قبل الدورة الشهرية (الانتفاخ، تقلبات المزاج، الرغبة الشديدة في الطعام) في هذه المرحلة. اعتني بنفسك بهدوء.',
          'hi': 'इस चरण में प्रीमेंस्ट्रुअल लक्षण (सूजन, मूड बदलाव, खाने की तीव्र इच्छा) महसूस होना आम है। शांति से अपना ख्याल रखें।',
          'bn': 'এই পর্যায়ে প্রি-মেনস্ট্রুয়াল লক্ষণ (ফোলাভাব, মেজাজের পরিবর্তন, খাওয়ার তীব্র ইচ্ছা) অনুভব করা সাধারণ। শান্তভাবে নিজের যত্ন নিন।',
          'pt': 'É comum sentir sintomas pré-menstruais (inchaço, mudanças de humor, desejos alimentares) nesta fase. Cuide-se com calma.',
        }),
        _t({
          'es': 'La progesterona puede afectar el sueño. Intenta mantener una rutina de descanso constante estos días.',
          'en': 'Progesterone can affect sleep. Try to keep a consistent rest routine these days.',
          'fr': "La progestérone peut affecter le sommeil. Essayez de garder une routine de repos régulière ces jours-ci.",
          'de': 'Progesteron kann den Schlaf beeinflussen. Versuche in diesen Tagen einen festen Schlafrhythmus einzuhalten.',
          'ru': 'Прогестерон может влиять на сон. Постарайся сохранять постоянный режим отдыха в эти дни.',
          'ar': 'قد يؤثر البروجسترون على النوم. حاولي الحفاظ على روتين نوم ثابت هذه الأيام.',
          'hi': 'प्रोजेस्टेरोन नींद को प्रभावित कर सकता है। इन दिनों एक स्थिर आराम की दिनचर्या बनाए रखने की कोशिश करें।',
          'bn': 'প্রোজেস্টেরন ঘুমকে প্রভাবিত করতে পারে। এই দিনগুলোতে একটি নিয়মিত বিশ্রামের রুটিন বজায় রাখার চেষ্টা করুন।',
          'pt': 'A progesterona pode afetar o sono. Tente manter uma rotina de descanso constante nesses dias.',
        }),
        _t({
          'es': 'Los antojos de dulce o sal son frecuentes ahora — escucha a tu cuerpo sin culpa, con moderación.',
          'en': 'Sweet or salty cravings are common now — listen to your body without guilt, in moderation.',
          'fr': "Les envies de sucré ou de salé sont fréquentes maintenant — écoutez votre corps sans culpabilité, avec modération.",
          'de': 'Heißhunger auf Süßes oder Salziges ist jetzt häufig — höre ohne schlechtes Gewissen auf deinen Körper, in Maßen.',
          'ru': 'Тяга к сладкому или солёному сейчас нередка — прислушивайся к своему телу без чувства вины, но в меру.',
          'ar': 'الرغبة الشديدة في الحلويات أو الأطعمة المالحة شائعة الآن — استمعي لجسمك دون شعور بالذنب، وباعتدال.',
          'hi': 'मीठा या नमकीन खाने की इच्छा अभी आम है — बिना अपराधबोध के, संयम के साथ अपने शरीर की सुनें।',
          'bn': 'মিষ্টি বা নোনতা খাবারের ইচ্ছা এখন সাধারণ — অপরাধবোধ ছাড়া, পরিমিতভাবে নিজের শরীরের কথা শুনুন।',
          'pt': 'Desejos por doces ou salgados são comuns agora — escute seu corpo sem culpa, com moderação.',
        }),
        _t({
          'es': 'Si notas más irritabilidad o sensibilidad emocional, es normal: baja el ritmo si lo necesitas.',
          'en': "If you notice more irritability or emotional sensitivity, it's normal: slow down if you need to.",
          'fr': "Si vous remarquez plus d'irritabilité ou de sensibilité émotionnelle, c'est normal : ralentissez si besoin.",
          'de': 'Mehr Reizbarkeit oder emotionale Empfindlichkeit ist normal: Geh es ruhiger an, wenn du es brauchst.',
          'ru': 'Если ты замечаешь больше раздражительности или эмоциональной чувствительности — это нормально: сбавь темп, если нужно.',
          'ar': 'إذا لاحظتِ مزيدًا من التهيج أو الحساسية العاطفية، فهذا طبيعي: خففي الوتيرة إذا احتجتِ لذلك.',
          'hi': 'अगर आपको अधिक चिड़चिड़ापन या भावनात्मक संवेदनशीलता महसूस हो, तो यह सामान्य है: ज़रूरत पड़े तो अपनी गति धीमी करें।',
          'bn': 'যদি আপনি বেশি খিটখিটে ভাব বা মানসিক সংবেদনশীলতা লক্ষ্য করেন, তা স্বাভাবিক: প্রয়োজনে গতি কমিয়ে দিন।',
          'pt': 'Se você notar mais irritabilidade ou sensibilidade emocional, é normal: desacelere se precisar.',
        }),
      ];

  /// Devuelve (nombre de fase, lista de consejos) para la clave interna
  /// de fase ('menstrual' | 'folicular' | 'ovulacion' | 'lutea').
  String phaseName(String phaseKey) {
    switch (phaseKey) {
      case 'menstrual':
        return phaseNameMenstrual;
      case 'folicular':
        return phaseNameFollicular;
      case 'ovulacion':
        return phaseNameOvulation;
      case 'lutea':
        return phaseNameLuteal;
      default:
        return '';
    }
  }

  List<String> phaseTips(String phaseKey) {
    switch (phaseKey) {
      case 'menstrual':
        return phaseTipsMenstrual;
      case 'folicular':
        return phaseTipsFollicular;
      case 'ovulacion':
        return phaseTipsOvulation;
      case 'lutea':
        return phaseTipsLuteal;
      default:
        return const [];
    }
  }

  /// Explicación breve y en lenguaje sencillo de qué está ocurriendo en el
  /// cuerpo durante cada fase — se muestra en la hoja de detalle de
  /// "Etapas" en Revisión, debajo de la ilustración, a petición del
  /// usuario de que además del consejo hubiera una explicación de "lo que
  /// le está pasando".
  String phaseHappening(String phaseKey) {
    switch (phaseKey) {
      case 'menstrual':
        return _t({
          'es':
              'El revestimiento del útero, que se había engrosado para un posible embarazo, se desprende y sale como sangrado. Los niveles de estrógeno y progesterona están en su punto más bajo.',
          'en':
              "The uterine lining, which had thickened for a possible pregnancy, sheds and leaves the body as bleeding. Estrogen and progesterone levels are at their lowest point.",
          'fr':
              "La muqueuse utérine, qui s'était épaissie en vue d'une éventuelle grossesse, se détache et s'évacue sous forme de saignement. Les niveaux d'œstrogène et de progestérone sont à leur plus bas.",
          'de':
              'Die Gebärmutterschleimhaut, die sich für eine mögliche Schwangerschaft aufgebaut hatte, löst sich und wird als Blutung ausgeschieden. Östrogen und Progesteron sind auf ihrem niedrigsten Stand.',
          'ru': 'Слизистая оболочка матки, которая утолщалась на случай возможной беременности, отслаивается и выходит в виде кровотечения. Уровни эстрогена и прогестерона на самом низком уровне.',
          'ar': 'تنسلخ بطانة الرحم، التي كانت قد سمكت استعدادًا لحمل محتمل، وتخرج على شكل نزيف. مستويات الإستروجين والبروجسترون في أدنى نقطة لها.',
          'hi': 'गर्भाशय की परत, जो संभावित गर्भावस्था के लिए मोटी हो गई थी, अलग होकर रक्तस्राव के रूप में बाहर निकलती है। एस्ट्रोजन और प्रोजेस्टेरोन का स्तर अपने सबसे निचले बिंदु पर होता है।',
          'bn': 'জরায়ুর আস্তরণ, যা সম্ভাব্য গর্ভাবস্থার জন্য পুরু হয়েছিল, খসে পড়ে রক্তক্ষরণ হিসেবে বের হয়ে যায়। ইস্ট্রোজেন এবং প্রোজেস্টেরনের মাত্রা তাদের সর্বনিম্ন পর্যায়ে থাকে।',
          'pt': 'O revestimento uterino, que havia engrossado para uma possível gravidez, se desprende e sai como sangramento. Os níveis de estrogênio e progesterona estão em seu ponto mais baixo.',
        });
      case 'folicular':
        return _t({
          'es':
              'Los ovarios empiezan a madurar varios folículos, cada uno con un óvulo. El estrógeno va subiendo poco a poco, lo que hace que el revestimiento del útero se vuelva a engrosar.',
          'en':
              'The ovaries start maturing several follicles, each containing an egg. Estrogen rises gradually, causing the uterine lining to thicken again.',
          'fr':
              "Les ovaires commencent à faire mûrir plusieurs follicules, chacun contenant un ovule. L'œstrogène augmente progressivement, ce qui épaissit à nouveau la muqueuse utérine.",
          'de':
              'Die Eierstöcke lassen mehrere Follikel heranreifen, jeder mit einer Eizelle. Östrogen steigt allmählich an, wodurch sich die Gebärmutterschleimhaut wieder aufbaut.',
          'ru': 'Яичники начинают созревать несколько фолликулов, каждый с яйцеклеткой. Эстроген постепенно растёт, из-за чего слизистая оболочка матки снова утолщается.',
          'ar': 'تبدأ المبايض في إنضاج عدة جريبات، كل منها يحتوي على بويضة. يرتفع الإستروجين تدريجيًا، مما يجعل بطانة الرحم تسمك مجددًا.',
          'hi': 'अंडाशय कई फॉलिकल्स को परिपक्व करना शुरू करते हैं, जिनमें से हर एक में एक अंडा होता है। एस्ट्रोजन धीरे-धीरे बढ़ता है, जिससे गर्भाशय की परत फिर से मोटी हो जाती है।',
          'bn': 'ডিম্বাশয় বেশ কয়েকটি ফলিকল পরিপক্ব করতে শুরু করে, যার প্রতিটিতে একটি ডিম্বাণু থাকে। ইস্ট্রোজেন ধীরে ধীরে বাড়ে, যার ফলে জরায়ুর আস্তরণ আবার পুরু হয়।',
          'pt': 'Os ovários começam a amadurecer vários folículos, cada um contendo um óvulo. O estrogênio sobe gradualmente, fazendo o revestimento uterino engrossar novamente.',
        });
      case 'ovulacion':
        return _t({
          'es':
              'Un óvulo maduro se libera del ovario (ovulación) y viaja hacia el útero. Es la ventana de mayor probabilidad de embarazo, gracias a un pico de la hormona luteinizante (LH).',
          'en':
              'A mature egg is released from the ovary (ovulation) and travels toward the uterus. This is the window of highest chance of pregnancy, triggered by a surge in luteinizing hormone (LH).',
          'fr':
              "Un ovule mature est libéré par l'ovaire (ovulation) et se dirige vers l'utérus. C'est la période de plus grande probabilité de grossesse, déclenchée par un pic d'hormone lutéinisante (LH).",
          'de':
              'Eine reife Eizelle wird aus dem Eierstock freigesetzt (Eisprung) und wandert zur Gebärmutter. Dies ist das Zeitfenster mit der höchsten Schwangerschaftswahrscheinlichkeit, ausgelöst durch einen Anstieg des luteinisierenden Hormons (LH).',
          'ru': 'Зрелая яйцеклетка выходит из яичника (овуляция) и движется к матке. Это окно наибольшей вероятности беременности благодаря пику лютеинизирующего гормона (ЛГ).',
          'ar': 'تُطلق بويضة ناضجة من المبيض (الإباضة) وتنتقل نحو الرحم. هذه هي نافذة الاحتمال الأعلى للحمل، بفضل ارتفاع الهرمون الملوتن (LH).',
          'hi': 'एक परिपक्व अंडा अंडाशय से निकलता है (अंडोत्सर्ग) और गर्भाशय की ओर जाता है। ल्यूटिनाइजिंग हार्मोन (LH) में वृद्धि के कारण यह गर्भधारण की सबसे अधिक संभावना वाली अवधि है।',
          'bn': 'একটি পরিণত ডিম্বাণু ডিম্বাশয় থেকে নির্গত হয় (ডিম্বস্ফোটন) এবং জরায়ুর দিকে যায়। লুটিনাইজিং হরমোন (LH)-এর তীব্র বৃদ্ধির কারণে এটি গর্ভধারণের সর্বোচ্চ সম্ভাবনার সময়।',
          'pt': 'Um óvulo maduro é liberado do ovário (ovulação) e viaja em direção ao útero. Esta é a janela de maior chance de gravidez, desencadeada por um aumento do hormônio luteinizante (LH).',
        });
      case 'lutea':
      default:
        return _t({
          'es':
              'El folículo que liberó el óvulo se transforma en el cuerpo lúteo y produce progesterona, que prepara el revestimiento del útero por si hay embarazo. Si no lo hay, esta hormona baja y empieza un nuevo ciclo.',
          'en':
              'The follicle that released the egg turns into the corpus luteum and produces progesterone, preparing the uterine lining in case of pregnancy. If there is none, this hormone drops and a new cycle begins.',
          'fr':
              "Le follicule qui a libéré l'ovule se transforme en corps jaune et produit de la progestérone, préparant la muqueuse utérine en cas de grossesse. En l'absence de grossesse, cette hormone chute et un nouveau cycle commence.",
          'de':
              'Der Follikel, der die Eizelle freigesetzt hat, wird zum Gelbkörper und produziert Progesteron, das die Gebärmutterschleimhaut auf eine mögliche Schwangerschaft vorbereitet. Bleibt sie aus, sinkt dieses Hormon und ein neuer Zyklus beginnt.',
          'ru': 'Фолликул, выпустивший яйцеклетку, превращается в жёлтое тело и вырабатывает прогестерон, который готовит слизистую оболочку матки на случай беременности. Если беременности нет, уровень этого гормона падает и начинается новый цикл.',
          'ar': 'يتحول الجريب الذي أطلق البويضة إلى الجسم الأصفر وينتج البروجسترون، الذي يُهيئ بطانة الرحم في حال حدوث حمل. وإذا لم يحدث حمل، ينخفض هذا الهرمون وتبدأ دورة جديدة.',
          'hi': 'जिस फॉलिकल ने अंडा छोड़ा था, वह कॉर्पस ल्यूटियम में बदल जाता है और प्रोजेस्टेरोन बनाता है, जो गर्भावस्था की स्थिति में गर्भाशय की परत को तैयार करता है। यदि गर्भावस्था नहीं होती, तो यह हार्मोन घट जाता है और एक नया चक्र शुरू होता है।',
          'bn': 'যে ফলিকল ডিম্বাণু ছেড়েছিল তা কর্পাস লুটিয়ামে পরিণত হয় এবং প্রোজেস্টেরন তৈরি করে, যা গর্ভাবস্থার ক্ষেত্রে জরায়ুর আস্তরণ প্রস্তুত করে। গর্ভাবস্থা না হলে, এই হরমোন কমে যায় এবং একটি নতুন চক্র শুরু হয়।',
          'pt': 'O folículo que liberou o óvulo se transforma no corpo lúteo e produz progesterona, que prepara o revestimento uterino em caso de gravidez. Se não houver gravidez, esse hormônio cai e um novo ciclo começa.',
        });
    }
  }

  String get pregnancyWeeksLabel =>
      _t({'es': 'SEMANAS DE EMBARAZO', 'en': 'WEEKS PREGNANT', 'fr': "SEMAINES DE GROSSESSE", 'de': 'SCHWANGERSCHAFTSWOCHEN', 'ru': 'НЕДЕЛИ БЕРЕМЕННОСТИ', 'ar': 'أسابيع الحمل', 'hi': 'गर्भावस्था के सप्ताह', 'bn': 'গর্ভাবস্থার সপ্তাহ', 'pt': 'SEMANAS DE GRAVIDEZ'});
  String get pregnancySetLmpHint => _t({
        'es': 'Configura la fecha de tu último periodo en Configuración ⚙️',
        'en': 'Set your last period date in Settings ⚙️',
        'fr': 'Configurez la date de vos dernières règles dans Paramètres ⚙️',
        'de': 'Lege das Datum deiner letzten Periode in den Einstellungen fest ⚙️',
        'ru': 'Укажи дату своей последней менструации в Настройках ⚙️',
        'ar': 'حددي تاريخ آخر دورة شهرية لكِ في الإعدادات ⚙️',
        'hi': 'सेटिंग्स ⚙️ में अपनी आखिरी माहवारी की तारीख सेट करें',
        'bn': 'সেটিংসে ⚙️ আপনার শেষ মাসিকের তারিখ সেট করুন',
        'pt': 'Configure a data da sua última menstruação em Configurações ⚙️',
      });
  String pregnancyDueDate(String date) => _t({
        'es': 'Fecha probable de parto: $date',
        'en': 'Estimated due date: $date',
        'fr': 'Date probable d\'accouchement : $date',
        'de': 'Voraussichtlicher Geburtstermin: $date',
        'ru': 'Предполагаемая дата родов: $date',
        'ar': 'تاريخ الولادة المتوقع: $date',
        'hi': 'अनुमानित प्रसव तिथि: $date',
        'bn': 'আনুমানিক প্রসবের তারিখ: $date',
        'pt': 'Data provável do parto: $date',
      });

  // --- Pantalla de seguimiento de embarazo (PregnancyTrackingScreen) ---
  String get pregnancyTrackingTitle =>
      _t({'es': 'Embarazo', 'en': 'Pregnancy', 'fr': 'Grossesse', 'de': 'Schwangerschaft', 'ru': 'Беременность', 'ar': 'الحمل', 'hi': 'गर्भावस्था', 'bn': 'গর্ভাবস্থা', 'pt': 'Gravidez',});
  String get pregnancyTrackingHeroText => _t({
        'es': 'Un pequeño milagro está en camino',
        'en': 'A little miracle is on its way',
        'fr': 'Un petit miracle est en chemin',
        'de': 'Ein kleines Wunder ist unterwegs',
        'ru': 'Маленькое чудо уже в пути',
        'ar': 'معجزة صغيرة في طريقها إليكِ', 'hi': 'एक छोटा सा चमत्कार आने वाला है', 'bn': 'একটি ছোট্ট অলৌকিক ঘটনা আসছে', 'pt': 'Um pequeno milagre está a caminho',
      });
  String get pregnancyMonthLabel =>
      _t({'es': 'MES', 'en': 'MONTH', 'fr': 'MOIS', 'de': 'MONAT', 'ru': 'МЕСЯЦ', 'ar': 'الشهر', 'hi': 'महीना', 'bn': 'মাস', 'pt': 'MÊS',});
  String pregnancyWeekPill(int week, int extraDays) => _t({
        'es': 'Semana $week · +$extraDays días',
        'en': 'Week $week · +$extraDays days',
        'fr': 'Semaine $week · +$extraDays jours',
        'de': 'Woche $week · +$extraDays Tage',
        'ru': 'Неделя $week · +$extraDays дн.',
        'ar': 'الأسبوع $week · +$extraDays أيام', 'hi': 'सप्ताह $week · +$extraDays दिन', 'bn': 'সপ্তাহ $week · +$extraDays দিন', 'pt': 'Semana $week · +$extraDays dias',
      });
  String get pregnancyLastPeriodLabel =>
      _t({'es': 'Última regla', 'en': 'Last period', 'fr': 'Dernières règles', 'de': 'Letzte Periode', 'ru': 'Последняя менструация', 'ar': 'آخر دورة شهرية', 'hi': 'आखिरी माहवारी', 'bn': 'শেষ মাসিক', 'pt': 'Última menstruação',});
  String get pregnancyDueDateShortLabel =>
      _t({'es': 'Fecha de parto', 'en': 'Due date', 'fr': "Date d'accouchement", 'de': 'Geburtstermin', 'ru': 'Дата родов', 'ar': 'تاريخ الولادة', 'hi': 'प्रसव तिथि', 'bn': 'প্রসবের তারিখ', 'pt': 'Data prevista do parto',});
  String get pregnancyDueInLabel =>
      _t({'es': 'Sale de cuentas en', 'en': 'Due in', 'fr': 'Accouchement dans', 'de': 'Fällig in', 'ru': 'Роды через', 'ar': 'موعد الولادة خلال', 'hi': 'प्रसव में', 'bn': 'প্রসবে বাকি', 'pt': 'Falta para o parto'});
  String pregnancyWeeksShort(int weeks) => _t({
        'es': '$weeks sem',
        'en': '$weeks wk',
        'fr': '$weeks sem',
        'de': '$weeks Wo',
        'ru': '$weeks нед',
        'ar': '$weeks أسبوع',
        'hi': '$weeks सप्ताह',
        'bn': '$weeks সপ্তাহ',
        'pt': '$weeks sem',
      });
  String get pregnancyBabySizeTitle => _t({
        'es': 'Tamaño del bebé esta semana',
        'en': "Baby's size this week",
        'fr': 'Taille du bébé cette semaine',
        'de': 'Größe des Babys diese Woche',
        'ru': 'Размер малыша на этой неделе',
        'ar': 'حجم طفلك هذا الأسبوع',
        'hi': 'इस सप्ताह बच्चे का आकार',
        'bn': 'এই সপ্তাহে শিশুর আকার',
        'pt': 'Tamanho do bebê esta semana',
      });
  String get pregnancyWeeklyFactTitle =>
      _t({'es': 'Dato de esta semana', 'en': 'Fact of the week', 'fr': 'Le saviez-vous cette semaine', 'de': 'Wissenswertes dieser Woche', 'ru': 'Факт этой недели', 'ar': 'معلومة هذا الأسبوع', 'hi': 'इस सप्ताह की जानकारी', 'bn': 'এই সপ্তাহের তথ্য', 'pt': 'Curiosidade da semana'});
  String get pregnancyTrackingEntry => _t({
        'es': 'Ver seguimiento completo',
        'en': 'View full tracking',
        'fr': 'Voir le suivi complet',
        'de': 'Vollständige Verfolgung ansehen',
        'ru': 'Смотреть полный трекинг',
        'ar': 'عرض المتابعة الكاملة',
        'hi': 'पूरा ट्रैकिंग देखें',
        'bn': 'সম্পূর্ণ ট্র্যাকিং দেখুন',
        'pt': 'Ver acompanhamento completo',
      });

  // ==================== day_editor.dart ====================

  String selectedDayLabel(String dateLabel) => _t({
        'es': 'Día seleccionado: $dateLabel',
        'en': 'Selected day: $dateLabel',
        'fr': 'Jour sélectionné : $dateLabel',
        'de': 'Ausgewählter Tag: $dateLabel',
        'ru': 'Выбранный день: $dateLabel',
        'ar': 'اليوم المحدد: $dateLabel',
        'hi': 'चयनित दिन: $dateLabel',
        'bn': 'নির্বাচিত দিন: $dateLabel',
        'pt': 'Dia selecionado: $dateLabel',
      });

  /// Aviso mostrado cuando se abre el editor de un día futuro: los campos
  /// observacionales (flujo, síntomas, bienestar, etc.) quedan
  /// deshabilitados porque no se pueden "adelantar" observaciones del
  /// cuerpo; solo recordatorios y notas siguen disponibles.
  String get futureDayNotice => _t({
        'es': '📅 Este día aún no ha llegado — solo puedes programar recordatorios y notas. Los registros de flujo, síntomas y bienestar se habilitan cuando llegue el día.',
        'en': "📅 This day hasn't arrived yet — you can only schedule reminders and notes. Flow, symptom and wellbeing logging unlocks once the day arrives.",
        'fr': "📅 Ce jour n'est pas encore arrivé — vous ne pouvez que programmer des rappels et des notes. Le suivi du flux, des symptômes et du bien-être se débloque le jour venu.",
        'de': '📅 Dieser Tag ist noch nicht da — du kannst nur Erinnerungen und Notizen planen. Die Erfassung von Blutung, Symptomen und Wohlbefinden wird freigeschaltet, sobald der Tag da ist.',
        'ru': '📅 Этот день ещё не наступил — можно только запланировать напоминания и заметки. Регистрация выделений, симптомов и самочувствия станет доступна, когда наступит этот день.',
        'ar': '📅 هذا اليوم لم يأتِ بعد — يمكنك فقط جدولة التذكيرات والملاحظات. سيتم تفعيل تسجيل الإفرازات والأعراض والحالة الصحية عند حلول هذا اليوم.',
        'hi': '📅 यह दिन अभी नहीं आया है — आप केवल रिमाइंडर और नोट्स शेड्यूल कर सकती हैं। जब यह दिन आएगा, तब फ्लो, लक्षण और सेहत की जानकारी दर्ज करना सक्षम हो जाएगा।',
        'bn': '📅 এই দিনটি এখনও আসেনি — আপনি শুধু রিমাইন্ডার এবং নোট শিডিউল করতে পারবেন। ফ্লো, উপসর্গ এবং সুস্থতার তথ্য লেখা এই দিন এলে চালু হবে।',
        'pt': '📅 Esse dia ainda não chegou — você só pode agendar lembretes e notas. O registro de fluxo, sintomas e bem-estar é liberado quando o dia chegar.',
      });

  /// Título de la sección "Planificar" en la vista simplificada de día
  /// futuro (cita médica + recordatorio de anticonceptivo).
  String get futureDayPlanSectionTitle => _t({
        'es': 'Planificar este día',
        'en': 'Plan this day',
        'fr': 'Planifier ce jour',
        'de': 'Diesen Tag planen',
        'ru': 'Спланировать этот день',
        'ar': 'تخطيط هذا اليوم',
        'hi': 'इस दिन की योजना बनाएं',
        'bn': 'এই দিনের পরিকল্পনা করুন',
        'pt': 'Planejar este dia',
      });

  String get futureDayScheduleAppointment => _t({
        'es': '📅 Programar cita médica este día',
        'en': '📅 Schedule a medical appointment this day',
        'fr': '📅 Programmer un rendez-vous médical ce jour',
        'de': '📅 Arzttermin für diesen Tag planen',
        'ru': '📅 Запланировать медицинский приём в этот день',
        'ar': '📅 جدولة موعد طبي في هذا اليوم',
        'hi': '📅 इस दिन डॉक्टर की अपॉइंटमेंट शेड्यूल करें',
        'bn': '📅 এই দিনে ডাক্তারের অ্যাপয়েন্টমেন্ট শিডিউল করুন',
        'pt': '📅 Agendar consulta médica neste dia',
      });

  String get futureDayAppointmentTimeHint => _t({
        'es': 'Elegir hora',
        'en': 'Choose time',
        'fr': 'Choisir l\'heure',
        'de': 'Uhrzeit wählen',
        'ru': 'Выбрать время',
        'ar': 'اختيار الوقت',
        'hi': 'समय चुनें',
        'bn': 'সময় বেছে নিন',
        'pt': 'Escolher horário',
      });

  String get futureDayAppointmentSaved => _t({
        'es': 'Cita médica guardada para este día.',
        'en': 'Appointment saved for this day.',
        'fr': 'Rendez-vous enregistré pour ce jour.',
        'de': 'Termin für diesen Tag gespeichert.',
        'ru': 'Медицинский приём сохранён на этот день.',
        'ar': 'تم حفظ الموعد الطبي لهذا اليوم.',
        'hi': 'इस दिन के लिए अपॉइंटमेंट सहेज दी गई है।',
        'bn': 'এই দিনের জন্য অ্যাপয়েন্টমেন্ট সংরক্ষিত হয়েছে।',
        'pt': 'Consulta salva para este dia.',
      });

  String futureDayPillReminderActive(String time) => _t({
        'es': '✓ Recordatorio de anticonceptivo activo a las $time',
        'en': '✓ Contraceptive reminder active at $time',
        'fr': '✓ Rappel de contraceptif actif à $time',
        'de': '✓ Verhütungserinnerung aktiv um $time Uhr',
        'ru': '✓ Напоминание о контрацепции активно в $time',
        'ar': '✓ تذكير وسيلة منع الحمل مفعّل في الساعة $time',
        'hi': '✓ गर्भनिरोधक रिमाइंडर $time बजे सक्रिय है',
        'bn': '✓ গর্ভনিরোধক রিমাইন্ডার $time-এ সক্রিয়',
        'pt': '✓ Lembrete de contraceptivo ativo às $time',
      });

  String get futureDayEnablePillReminder => _t({
        'es': 'Activar recordatorio de anticonceptivo',
        'en': 'Enable contraceptive reminder',
        'fr': 'Activer le rappel de contraceptif',
        'de': 'Verhütungserinnerung aktivieren',
        'ru': 'Включить напоминание о контрацепции',
        'ar': 'تفعيل تذكير وسيلة منع الحمل',
        'hi': 'गर्भनिरोधक रिमाइंडर सक्रिय करें',
        'bn': 'গর্ভনিরোধক রিমাইন্ডার চালু করুন',
        'pt': 'Ativar lembrete de contraceptivo',
      });

  String get futureDayPillReminderEnabledConfirm => _t({
        'es': 'Recordatorio de anticonceptivo activado a las 08:00. Puedes cambiar la hora en Configuración.',
        'en': 'Contraceptive reminder enabled at 08:00. You can change the time in Settings.',
        'fr': 'Rappel de contraceptif activé à 08:00. Vous pouvez changer l\'heure dans les paramètres.',
        'de': 'Verhütungserinnerung um 08:00 Uhr aktiviert. Du kannst die Uhrzeit in den Einstellungen ändern.',
        'ru': 'Напоминание о контрацепции включено на 08:00. Ты можешь изменить время в Настройках.',
        'ar': 'تم تفعيل تذكير وسيلة منع الحمل في الساعة 08:00. يمكنك تغيير الوقت من الإعدادات.',
        'hi': 'गर्भनिरोधक रिमाइंडर सुबह 08:00 बजे सक्रिय कर दिया गया है। आप सेटिंग्स में समय बदल सकती हैं।',
        'bn': 'গর্ভনিরোধক রিমাইন্ডার সকাল ০৮:০০-এ চালু করা হয়েছে। আপনি সেটিংসে গিয়ে সময় পরিবর্তন করতে পারেন।',
        'pt': 'Lembrete de contraceptivo ativado às 08:00. Você pode alterar o horário nas Configurações.',
      });

  /// Etiqueta fija usada como `label` del `MedicalAppointment` que
  /// representa el recordatorio puntual de anticonceptivo de un día
  /// futuro concreto (distinto del interruptor global recurrente de
  /// Configuración). Se guarda tal cual como texto de la cita.
  String get contraceptiveReminderLabel => _t({
        'es': 'Anticonceptivo',
        'en': 'Birth control',
        'fr': 'Contraceptif',
        'de': 'Verhütung',
        'ru': 'Контрацепция',
        'ar': 'وسيلة منع الحمل',
        'hi': 'गर्भनिरोधक',
        'bn': 'গর্ভনিরোধক',
        'pt': 'Anticoncepcional',
      });

  /// Botón para activar el recordatorio puntual de anticonceptivo de este
  /// día concreto, con la hora ya elegida en el selector.
  String futureDayEnablePointPillReminder(String time) => _t({
        'es': 'Activar recordatorio a las $time',
        'en': 'Enable reminder at $time',
        'fr': 'Activer le rappel à $time',
        'de': 'Erinnerung um $time Uhr aktivieren',
        'ru': 'Включить напоминание в $time',
        'ar': 'تفعيل التذكير في الساعة $time',
        'hi': '$time बजे रिमाइंडर सक्रिय करें',
        'bn': '$time-এ রিমাইন্ডার চালু করুন',
        'pt': 'Ativar lembrete às $time',
      });

  /// Texto mostrado cuando el recordatorio puntual de anticonceptivo de
  /// este día ya está activo, junto al botón para desactivarlo.
  String futureDayPointPillReminderActive(String time) => _t({
        'es': '✓ Anticonceptivo a las $time',
        'en': '✓ Birth control at $time',
        'fr': '✓ Contraceptif à $time',
        'de': '✓ Verhütung um $time Uhr',
        'ru': '✓ Контрацепция в $time',
        'ar': '✓ وسيلة منع الحمل في الساعة $time',
        'hi': '✓ गर्भनिरोधक, $time बजे',
        'bn': '✓ গর্ভনিরোধক, $time-এ',
        'pt': '✓ Anticoncepcional às $time',
      });

  String get futureDayDisablePillReminder => _t({
        'es': 'Desactivar',
        'en': 'Disable',
        'fr': 'Désactiver',
        'de': 'Deaktivieren',
        'ru': 'Отключить',
        'ar': 'إلغاء التفعيل',
        'hi': 'निष्क्रिय करें',
        'bn': 'নিষ্ক্রিয় করুন',
        'pt': 'Desativar',
      });

  String get futureDayPillReminderPickTimeHint => _t({
        'es': 'Elegir hora del recordatorio',
        'en': 'Choose reminder time',
        'fr': "Choisir l'heure du rappel",
        'de': 'Erinnerungszeit wählen',
        'ru': 'Выбрать время напоминания',
        'ar': 'اختيار وقت التذكير',
        'hi': 'रिमाइंडर का समय चुनें',
        'bn': 'রিমাইন্ডারের সময় বেছে নিন',
        'pt': 'Escolher horário do lembrete',
      });

  /// Nuevo hint del campo de notas en la vista simplificada de día futuro
  /// (distinto del hint genérico `diaryHint` de la vista normal, porque
  /// aquí se trata de planificar/recordar, no de registrar cómo se sintió
  /// la persona ese día).
  String get futureDayNoteHint => _t({
        'es': 'Escribe para recordarte esta fecha...',
        'en': 'Write a reminder for yourself about this date...',
        'fr': 'Écrivez un rappel pour vous concernant cette date...',
        'de': 'Schreib dir eine Erinnerung zu diesem Datum...',
        'ru': 'Напиши напоминание себе об этой дате...',
        'ar': 'اكتبي تذكيرًا لنفسكِ حول هذا التاريخ...',
        'hi': 'इस तारीख़ के बारे में खुद को याद दिलाने के लिए लिखें...',
        'bn': 'এই তারিখ সম্পর্কে নিজেকে মনে করিয়ে দিতে লিখুন...',
        'pt': 'Escreva um lembrete para você sobre esta data...',
      });

  // ---- Opciones predefinidas del tipo de cita médica ----
  String get appointmentTypeGyno => _t({
        'es': 'Ginecólogo/a',
        'en': 'Gynecologist',
        'fr': 'Gynécologue',
        'de': 'Gynäkologe/in',
        'ru': 'Гинеколог',
        'ar': 'طبيبة النساء',
        'hi': 'स्त्री रोग विशेषज्ञ',
        'bn': 'স্ত্রীরোগ বিশেষজ্ঞ',
        'pt': 'Ginecologista',
      });
  String get appointmentTypeCheckup => _t({
        'es': 'Revisión general',
        'en': 'General checkup',
        'fr': 'Bilan de santé général',
        'de': 'Allgemeine Untersuchung',
        'ru': 'Общий осмотр',
        'ar': 'فحص عام',
        'hi': 'सामान्य जांच',
        'bn': 'সাধারণ চেকআপ',
        'pt': 'Check-up geral',
      });
  String get appointmentTypeBloodTest => _t({
        'es': 'Análisis de sangre',
        'en': 'Blood test',
        'fr': 'Analyse de sang',
        'de': 'Blutuntersuchung',
        'ru': 'Анализ крови',
        'ar': 'تحليل الدم',
        'hi': 'रक्त परीक्षण',
        'bn': 'রক্ত পরীক্ষা',
        'pt': 'Exame de sangue',
      });
  String get appointmentTypeUltrasound => _t({
        'es': 'Ecografía',
        'en': 'Ultrasound',
        'fr': 'Échographie',
        'de': 'Ultraschall',
        'ru': 'УЗИ',
        'ar': 'الموجات فوق الصوتية',
        'hi': 'अल्ट्रासाउंड',
        'bn': 'আল্ট্রাসাউন্ড',
        'pt': 'Ultrassom',
      });
  String get appointmentTypeMidwife => _t({
        'es': 'Matrona',
        'en': 'Midwife',
        'fr': 'Sage-femme',
        'de': 'Hebamme',
        'ru': 'Акушерка',
        'ar': 'القابلة',
        'hi': 'मिडवाइफ',
        'bn': 'ধাত্রী',
        'pt': 'Parteira',
      });
  String get appointmentTypeOther => _t({
        'es': 'Otro',
        'en': 'Other',
        'fr': 'Autre',
        'de': 'Sonstiges',
        'ru': 'Другое',
        'ar': 'أخرى',
        'hi': 'अन्य',
        'bn': 'অন্যান্য',
        'pt': 'Outro',
      });
  String get appointmentTypeOtherHint => _t({
        'es': 'Escribe el tipo de cita...',
        'en': 'Type the appointment type...',
        'fr': "Saisissez le type de rendez-vous...",
        'de': 'Terminart eingeben...',
        'ru': 'Напиши тип приёма...',
        'ar': 'اكتبي نوع الموعد...',
        'hi': 'अपॉइंटमेंट का प्रकार लिखें...',
        'bn': 'অ্যাপয়েন্টমেন্টের ধরন লিখুন...',
        'pt': 'Digite o tipo de consulta...',
      });
  String get appointmentTypeSectionLabel => _t({
        'es': 'Tipo de cita',
        'en': 'Appointment type',
        'fr': 'Type de rendez-vous',
        'de': 'Terminart',
        'ru': 'Тип приёма',
        'ar': 'نوع الموعد',
        'hi': 'अपॉइंटमेंट का प्रकार',
        'bn': 'অ্যাপয়েন্টমেন্টের ধরন',
        'pt': 'Tipo de consulta',
      });

  String get flowLabel => _t({'es': 'Flujo', 'en': 'Flow', 'fr': 'Flux', 'de': 'Blutung', 'ru': 'Выделения', 'ar': 'الإفرازات', 'hi': 'प्रवाह', 'bn': 'প্রবাহ', 'pt': 'Fluxo'});
  String get flowMenstrualSectionTitle =>
      _t({'es': 'Flujo menstrual', 'en': 'Menstrual flow', 'fr': 'Flux menstruel', 'de': 'Menstruationsfluss', 'ru': 'Менструальные выделения', 'ar': 'إفرازات الدورة الشهرية', 'hi': 'मासिक धर्म प्रवाह', 'bn': 'মাসিক প্রবাহ', 'pt': 'Fluxo menstrual'});
  // Aviso bajo el selector de flujo cuando se edita una fecha futura: no se
  // puede registrar período todavía (a diferencia de los recordatorios,
  // que sí admiten fecha futura) — ver RegisterScreen._isFutureEditedDate.
  String get periodFutureDateHint => _t({
        'es': 'No puedes registrar el período en una fecha futura todavía.',
        'en': 'You can\'t log a period on a future date yet.',
        'fr': 'Vous ne pouvez pas encore enregistrer de règles à une date future.',
        'de': 'Du kannst die Periode noch nicht für ein zukünftiges Datum eintragen.',
        'ru': 'Вы пока не можете отметить менструацию на будущую дату.',
        'ar': 'لا يمكنك تسجيل الدورة الشهرية في تاريخ مستقبلي بعد.',
        'hi': 'आप अभी भविष्य की तारीख़ पर पीरियड दर्ज नहीं कर सकतीं।',
        'bn': 'আপনি এখনও ভবিষ্যতের তারিখে পিরিয়ড নথিভুক্ত করতে পারবেন না।',
        'pt': 'Ainda não é possível registrar o período em uma data futura.',
      });
  String get spottingLabel => _t({'es': 'Manchado', 'en': 'Spotting', 'fr': 'Saignements légers', 'de': 'Schmierblutung', 'ru': 'Мажущие выделения', 'ar': 'نزيف خفيف', 'hi': 'स्पॉटिंग', 'bn': 'স্পটিং', 'pt': 'Escape'});
  String get vaginalFlowLabel => _t({'es': 'Flujo vaginal', 'en': 'Vaginal discharge', 'fr': 'Pertes vaginales', 'de': 'Vaginalausfluss', 'ru': 'Влагалищные выделения', 'ar': 'إفرازات مهبلية', 'hi': 'योनि स्राव', 'bn': 'যোনি স্রাব', 'pt': 'Corrimento vaginal'});
  String get symptomsLabel => _t({'es': 'Síntomas', 'en': 'Symptoms', 'fr': 'Symptômes', 'de': 'Symptome', 'ru': 'Симптомы', 'ar': 'الأعراض', 'hi': 'लक्षण', 'bn': 'উপসর্গ', 'pt': 'Sintomas'});
  String get symptomsHint => _t({
        'es': 'Toca un síntoma para marcarlo; vuelve a tocarlo para cambiar su nivel.',
        'en': 'Tap a symptom to mark it; tap again to change its level.',
        'fr': 'Touchez un symptôme pour le marquer ; retouchez-le pour changer son niveau.',
        'de': 'Tippe auf ein Symptom, um es zu markieren; tippe erneut, um die Stufe zu ändern.',
        'ru': 'Нажми на симптом, чтобы отметить его; нажми ещё раз, чтобы изменить его уровень.',
        'ar': 'اضغطي على عرض لتحديده؛ اضغطي مرة أخرى لتغيير مستواه.',
        'hi': 'किसी लक्षण को चिह्नित करने के लिए उस पर टैप करें; उसका स्तर बदलने के लिए फिर से टैप करें।',
        'bn': 'কোনো উপসর্গ চিহ্নিত করতে তাতে ট্যাপ করুন; এর মাত্রা পরিবর্তন করতে আবার ট্যাপ করুন।',
        'pt': 'Toque em um sintoma para marcá-lo; toque novamente para mudar o nível.',
      });
  String get diaryLabel => _t({'es': 'Diario', 'en': 'Diary', 'fr': 'Journal', 'de': 'Tagebuch', 'ru': 'Дневник', 'ar': 'اليوميات', 'hi': 'डायरी', 'bn': 'ডায়েরি', 'pt': 'Diário'});
  String get diaryHint => _t({
        'es': 'Escribe lo que quieras sobre tu día: cómo te sientes, notas para tu médico, lo que sea...',
        'en': "Write anything about your day: how you feel, notes for your doctor, anything at all...",
        'fr': "Écrivez ce que vous voulez sur votre journée : comment vous vous sentez, des notes pour votre médecin, tout ce que vous voulez...",
        'de': 'Schreib, was du möchtest über deinen Tag: wie du dich fühlst, Notizen für deinen Arzt, was auch immer ...',
        'ru': 'Напиши всё, что хочешь, о своём дне: как ты себя чувствуешь, заметки для врача, что угодно...',
        'ar': 'اكتبي أي شيء عن يومك: كيف تشعرين، ملاحظات لطبيبتك، أي شيء تريدينه...',
        'hi': 'अपने दिन के बारे में जो चाहें लिखें: आप कैसा महसूस कर रही हैं, अपनी डॉक्टर के लिए नोट्स, कुछ भी...',
        'bn': 'আপনার দিন সম্পর্কে যা ইচ্ছা লিখুন: আপনি কেমন অনুভব করছেন, আপনার ডাক্তারের জন্য নোট, যা কিছু...',
        'pt': 'Escreva o que quiser sobre o seu dia: como você está se sentindo, anotações para o seu médico, qualquer coisa...',
      });

  String get sexLifeLabel => _t({'es': 'Vida sexual', 'en': 'Sex life', 'fr': 'Vie sexuelle', 'de': 'Sexualleben', 'ru': 'Интимная жизнь', 'ar': 'الحياة الجنسية', 'hi': 'यौन जीवन', 'bn': 'যৌন জীবন', 'pt': 'Vida sexual'});
  String get sexRelationLabel => _t({'es': '❤️ Relación sexual', 'en': '❤️ Sex', 'fr': '❤️ Rapport sexuel', 'de': '❤️ Geschlechtsverkehr', 'ru': '❤️ Половой акт', 'ar': '❤️ علاقة حميمة', 'hi': '❤️ यौन संबंध', 'bn': '❤️ যৌন সম্পর্ক', 'pt': '❤️ Relação sexual'});
  String get sexUnprotectedLabel =>
      _t({'es': '⚠️ Sin protección', 'en': '⚠️ Unprotected', 'fr': '⚠️ Sans protection', 'de': '⚠️ Ungeschützt', 'ru': '⚠️ Без защиты', 'ar': '⚠️ بدون حماية', 'hi': '⚠️ असुरक्षित', 'bn': '⚠️ অরক্ষিত', 'pt': '⚠️ Sem proteção'});

  String get cervicalMucusLabel =>
      _t({'es': 'Moco cervical', 'en': 'Cervical mucus', 'fr': 'Glaire cervicale', 'de': 'Zervixschleim', 'ru': 'Цервикальная слизь', 'ar': 'المخاط العنقي', 'hi': 'गर्भाशय ग्रीवा का बलगम', 'bn': 'সার্ভিকাল মিউকাস', 'pt': 'Muco cervical'});
  String get cervicalMucusHint => _t({
        'es': 'Ayuda a detectar tu ventana fértil junto a la temperatura basal.',
        'en': 'Helps detect your fertile window alongside basal temperature.',
        'fr': 'Aide à détecter votre fenêtre fertile avec la température basale.',
        'de': 'Hilft, dein fruchtbares Fenster zusammen mit der Basaltemperatur zu erkennen.',
        'ru': 'Помогает определить твоё фертильное окно вместе с базальной температурой.',
        'ar': 'تساعد في تحديد نافذة خصوبتك جنبًا إلى جنب مع درجة الحرارة الأساسية.',
        'hi': 'यह बेसल तापमान के साथ मिलकर आपकी उपजाऊ अवधि पहचानने में मदद करता है।',
        'bn': 'এটি বেসাল তাপমাত্রার সাথে মিলিয়ে আপনার উর্বর সময় শনাক্ত করতে সাহায্য করে।',
        'pt': 'Ajuda a identificar sua janela fértil junto com a temperatura basal.',
      });

  static const Map<String, Map<String, String>> _cervicalMucusTable = {
    'dry': {'es': 'Seco', 'en': 'Dry', 'fr': 'Sec', 'de': 'Trocken', 'ru': 'Сухая', 'ar': 'جاف', 'hi': 'सूखा', 'bn': 'শুষ্ক', 'pt': 'Seco'},
    'sticky': {'es': 'Pegajoso', 'en': 'Sticky', 'fr': 'Collante', 'de': 'Klebrig', 'ru': 'Липкая', 'ar': 'لزج', 'hi': 'चिपचिपा', 'bn': 'আঠালো', 'pt': 'Pegajoso'},
    'creamy': {'es': 'Cremoso', 'en': 'Creamy', 'fr': 'Crémeuse', 'de': 'Cremig', 'ru': 'Кремообразная', 'ar': 'كريمي', 'hi': 'मलाईदार', 'bn': 'ক্রিমি', 'pt': 'Cremoso'},
    'watery': {'es': 'Acuoso', 'en': 'Watery', 'fr': 'Aqueuse', 'de': 'Wässrig', 'ru': 'Водянистая', 'ar': 'مائي', 'hi': 'पानी जैसा', 'bn': 'পানির মতো', 'pt': 'Aquoso'},
    'eggwhite': {'es': 'Clara de huevo', 'en': 'Egg white', 'fr': "Blanc d'œuf", 'de': 'Eiklar', 'ru': 'Яичный белок', 'ar': 'بياض البيض', 'hi': 'अंडे की सफेदी जैसा', 'bn': 'ডিমের সাদা অংশের মতো', 'pt': 'Clara de ovo'},
  };
  String cervicalMucusLabelFor(String id) => _t(_cervicalMucusTable[id] ?? {'es': id, 'en': id, 'fr': id, 'de': id, 'ru': id, 'ar': id, 'hi': id, 'bn': id, 'pt': id});

  String get lessDetails => _t({'es': '➖ Menos detalles', 'en': '➖ Less details', 'fr': '➖ Moins de détails', 'de': '➖ Weniger Details', 'ru': '➖ Меньше деталей', 'ar': '➖ تفاصيل أقل', 'hi': '➖ कम विवरण', 'bn': '➖ কম বিবরণ', 'pt': '➖ Menos detalhes'});
  String get moreDetailsOptional =>
      _t({'es': '➕ Más detalles (opcional)', 'en': '➕ More details (optional)', 'fr': '➕ Plus de détails (facultatif)', 'de': '➕ Mehr Details (optional)', 'ru': '➕ Больше деталей (необязательно)', 'ar': '➕ مزيد من التفاصيل (اختياري)', 'hi': '➕ अधिक विवरण (वैकल्पिक)', 'bn': '➕ আরও বিবরণ (ঐচ্ছিক)', 'pt': '➕ Mais detalhes (opcional)'});

  String get moreDetailsHint => _t({
        'es': 'Vida sexual, temperatura, agua, sueño, peso y fotos. Solo si quieres llevar un registro más completo.',
        'en': 'Sex life, temperature, water, sleep, weight and photos. Only if you want a more complete record.',
        'fr': 'Vie sexuelle, température, eau, sommeil, poids et photos. Seulement si vous voulez un suivi plus complet.',
        'de': 'Sexualleben, Temperatur, Wasser, Schlaf, Gewicht und Fotos. Nur wenn du ein vollständigeres Protokoll führen möchtest.',
        'ru': 'Интимная жизнь, температура, вода, сон, вес и фото. Только если хочешь вести более полный учёт.',
        'ar': 'الحياة الجنسية، درجة الحرارة، الماء، النوم، الوزن والصور. فقط إذا أردتِ سجلاً أكثر تفصيلاً.',
        'hi': 'यौन जीवन, तापमान, पानी, नींद, वजन और तस्वीरें। केवल अगर आप अधिक पूर्ण रिकॉर्ड रखना चाहती हैं।',
        'bn': 'যৌন জীবন, তাপমাত্রা, পানি, ঘুম, ওজন এবং ছবি। শুধু যদি আপনি আরও সম্পূর্ণ রেকর্ড রাখতে চান।',
        'pt': 'Vida sexual, temperatura, água, sono, peso e fotos. Só se você quiser manter um registro mais completo.',
      });

  String get wellbeingLabel => _t({'es': 'Bienestar', 'en': 'Wellbeing', 'fr': 'Bien-être', 'de': 'Wohlbefinden', 'ru': 'Самочувствие', 'ar': 'الحالة الصحية', 'hi': 'सेहत', 'bn': 'সুস্থতা', 'pt': 'Bem-estar'});
  String get wellbeingHint => _t({
        'es': 'El color te muestra cómo va cada valor: verde bien, amarillo regular, rojo atención.',
        'en': 'The color shows you how each value is doing: green good, yellow so-so, red needs attention.',
        'fr': 'La couleur indique comment se porte chaque valeur : vert bien, jaune moyen, rouge attention.',
        'de': 'Die Farbe zeigt dir, wie jeder Wert steht: grün gut, gelb mittel, rot Achtung.',
        'ru': 'Цвет показывает, как обстоят дела с каждым показателем: зелёный — хорошо, жёлтый — средне, красный — требует внимания.',
        'ar': 'يوضح اللون حالة كل قيمة: أخضر جيد، أصفر متوسط، أحمر يحتاج انتباهًا.',
        'hi': 'रंग आपको बताता है कि हर मान की स्थिति कैसी है: हरा अच्छा, पीला ठीक-ठाक, लाल ध्यान देने की ज़रूरत।',
        'bn': 'রঙ আপনাকে দেখায় প্রতিটি মান কেমন আছে: সবুজ ভালো, হলুদ মোটামুটি, লাল মনোযোগ প্রয়োজন।',
        'pt': 'A cor mostra como está cada valor: verde bom, amarelo mais ou menos, vermelho precisa de atenção.',
      });

  String get tempBasalLabel => _t({'es': '🌡️ Temp. basal (°C)', 'en': '🌡️ Basal temp. (°C)', 'fr': '🌡️ Temp. basale (°C)', 'de': '🌡️ Basaltemp. (°C)', 'ru': '🌡️ Баз. темп. (°C)', 'ar': '🌡️ درجة الحرارة الأساسية (°C)', 'hi': '🌡️ बेसल तापमान (°C)', 'bn': '🌡️ বেসাল তাপমাত্রা (°C)', 'pt': '🌡️ Temp. basal (°C)'});
  String get waterLabel => _t({'es': '💧 Agua (vasos)', 'en': '💧 Water (glasses)', 'fr': '💧 Eau (verres)', 'de': '💧 Wasser (Gläser)', 'ru': '💧 Вода (стаканы)', 'ar': '💧 الماء (أكواب)', 'hi': '💧 पानी (गिलास)', 'bn': '💧 পানি (গ্লাস)', 'pt': '💧 Água (copos)'});
  String get sleepLabel => _t({'es': '😴 Sueño (h)', 'en': '😴 Sleep (h)', 'fr': '😴 Sommeil (h)', 'de': '😴 Schlaf (Std.)', 'ru': '😴 Сон (ч)', 'ar': '😴 النوم (ساعات)', 'hi': '😴 नींद (घं.)', 'bn': '😴 ঘুম (ঘ.)', 'pt': '😴 Sono (h)'});
  String get weightLabel => _t({'es': '⚖️ Peso (kg)', 'en': '⚖️ Weight (kg)', 'fr': '⚖️ Poids (kg)', 'de': '⚖️ Gewicht (kg)', 'ru': '⚖️ Вес (кг)', 'ar': '⚖️ الوزن (كجم)', 'hi': '⚖️ वजन (किग्रा)', 'bn': '⚖️ ওজন (কেজি)', 'pt': '⚖️ Peso (kg)'});

  String get photoLabel => _t({'es': 'Foto', 'en': 'Photo', 'fr': 'Photo', 'de': 'Foto', 'ru': 'Фото', 'ar': 'صورة', 'hi': 'फ़ोटो', 'bn': 'ছবি', 'pt': 'Foto'});
  String get photoLoading => _t({'es': 'Cargando...', 'en': 'Loading...', 'fr': 'Chargement...', 'de': 'Wird geladen...', 'ru': 'Загрузка...', 'ar': 'جارٍ التحميل...', 'hi': 'लोड हो रहा है...', 'bn': 'লোড হচ্ছে...', 'pt': 'Carregando...'});
  String get photoAttach => _t({'es': '📷 Adjuntar foto', 'en': '📷 Attach photo', 'fr': '📷 Joindre une photo', 'de': '📷 Foto anhängen', 'ru': '📷 Прикрепить фото', 'ar': '📷 إرفاق صورة', 'hi': '📷 फ़ोटो संलग्न करें', 'bn': '📷 ছবি সংযুক্ত করুন', 'pt': '📷 Anexar foto'});
  String get photoInfoTooltip => _t({'es': 'Sobre la foto', 'en': 'About the photo', 'fr': 'À propos de la photo', 'de': 'Über das Foto', 'ru': 'О фото', 'ar': 'حول الصورة', 'hi': 'फ़ोटो के बारे में', 'bn': 'ছবি সম্পর্কে', 'pt': 'Sobre a foto'});
  String get commonUnderstood => _t({'es': 'Entendido', 'en': 'Got it', 'fr': "J'ai compris", 'de': 'Verstanden', 'ru': 'Понятно', 'ar': 'حسنًا', 'hi': 'समझ गई', 'bn': 'বুঝেছি', 'pt': 'Entendi'});
  String get commonBack => _t({'es': 'Volver', 'en': 'Back', 'fr': 'Retour', 'de': 'Zurück', 'ru': 'Назад', 'ar': 'رجوع', 'hi': 'वापस', 'bn': 'পেছনে', 'pt': 'Voltar'});
  String get commonClose => _t({'es': 'Cerrar', 'en': 'Close', 'fr': 'Fermer', 'de': 'Schließen', 'ru': 'Закрыть', 'ar': 'إغلاق', 'hi': 'बंद करें', 'bn': 'বন্ধ করুন', 'pt': 'Fechar'});
  String get photoRemove => _t({'es': 'Quitar', 'en': 'Remove', 'fr': 'Retirer', 'de': 'Entfernen', 'ru': 'Удалить', 'ar': 'إزالة', 'hi': 'हटाएं', 'bn': 'সরান', 'pt': 'Remover'});
  String get photoLoadError => _t({
        'es': 'No se pudo cargar la foto.',
        'en': "Couldn't load the photo.",
        'fr': "Impossible de charger la photo.",
        'de': 'Das Foto konnte nicht geladen werden.',
        'ru': 'Не удалось загрузить фото.',
        'ar': 'تعذّر تحميل الصورة.',
        'hi': 'फ़ोटो लोड नहीं हो सकी।',
        'bn': 'ছবি লোড করা যায়নি।',
        'pt': 'Não foi possível carregar a foto.',
      });
  String get photoInfoSnackbar => _t({
        'es':
            '📷 Guarda una foto junto a este día — útil para mostrarle algo puntual a tu médico (una marca en la piel, hinchazón, etc.). Se guarda solo en tu dispositivo.',
        'en':
            "📷 Save a photo with this day — useful for showing your doctor something specific (a skin mark, swelling, etc.). It's stored only on your device.",
        'fr':
            "📷 Enregistrez une photo pour ce jour — utile pour montrer quelque chose de précis à votre médecin (une marque sur la peau, un gonflement, etc.). Elle est enregistrée uniquement sur votre appareil.",
        'de':
            '📷 Speichere ein Foto zu diesem Tag — nützlich, um deinem Arzt etwas Bestimmtes zu zeigen (ein Hautmal, eine Schwellung usw.). Es wird nur auf deinem Gerät gespeichert.',
        'ru': '📷 Сохрани фото рядом с этим днём — полезно, чтобы показать что-то конкретное своему врачу (пятно на коже, отёк и т. д.). Хранится только на твоём устройстве.',
        'ar': '📷 احفظي صورة مع هذا اليوم — مفيدة لإظهار شيء محدد لطبيبتك (بقعة على الجلد، انتفاخ، إلخ). تُحفظ فقط على جهازك.',
        'hi': '📷 इस दिन के साथ एक फ़ोटो सहेजें — अपनी डॉक्टर को कुछ खास दिखाने के लिए उपयोगी (त्वचा पर निशान, सूजन, आदि)। यह केवल आपके डिवाइस पर संग्रहीत होती है।',
        'bn': '📷 এই দিনের সাথে একটি ছবি সংরক্ষণ করুন — আপনার ডাক্তারকে নির্দিষ্ট কিছু দেখানোর জন্য উপযোগী (ত্বকে দাগ, ফোলাভাব ইত্যাদি)। এটি শুধু আপনার ডিভাইসে সংরক্ষিত থাকে।',
        'pt': '📷 Salve uma foto junto com este dia — útil para mostrar algo específico ao seu médico (uma marca na pele, inchaço, etc.). Fica armazenada só no seu aparelho.',
      });

  String get deleteDay => _t({'es': 'Borrar día', 'en': 'Delete day', 'fr': 'Supprimer le jour', 'de': 'Tag löschen', 'ru': 'Удалить день', 'ar': 'حذف اليوم', 'hi': 'दिन हटाएं', 'bn': 'দিন মুছুন', 'pt': 'Excluir dia'});
  String get save => _t({'es': 'Guardar', 'en': 'Save', 'fr': 'Enregistrer', 'de': 'Speichern', 'ru': 'Сохранить', 'ar': 'حفظ', 'hi': 'सहेजें', 'bn': 'সংরক্ষণ করুন', 'pt': 'Salvar'});
  String get cycleHistory => _t({'es': 'Historial de ciclos', 'en': 'Cycle history', 'fr': 'Historique des cycles', 'de': 'Zyklusverlauf', 'ru': 'История циклов', 'ar': 'سجل الدورات', 'hi': 'चक्र इतिहास', 'bn': 'চক্রের ইতিহাস', 'pt': 'Histórico de ciclos'});

  // Estados de TrackerStatus (semáforo Bienestar)
  String get trackerGood => _t({'es': 'Bien', 'en': 'Good', 'fr': 'Bien', 'de': 'Gut', 'ru': 'Хорошо', 'ar': 'جيد', 'hi': 'अच्छा', 'bn': 'ভালো', 'pt': 'Bom'});
  String get trackerWarn => _t({'es': 'Regular', 'en': 'Fair', 'fr': 'Moyen', 'de': 'Mittel', 'ru': 'Средне', 'ar': 'متوسط', 'hi': 'ठीक-ठाक', 'bn': 'মোটামুটি', 'pt': 'Regular'});
  String get trackerBad => _t({'es': 'Atención', 'en': 'Attention', 'fr': 'Attention', 'de': 'Achtung', 'ru': 'Внимание', 'ar': 'انتباه', 'hi': 'ध्यान दें', 'bn': 'মনোযোগ প্রয়োজন', 'pt': 'Atenção'});
  // Variantes específicas del estado "bad" (rojo) para temperatura, agua
  // y sueño — más claras que el genérico "Atención" porque dicen qué
  // pasa exactamente en cada campo.
  String get trackerBadTemp => _t({'es': 'Fiebre', 'en': 'Fever', 'fr': 'Fièvre', 'de': 'Fieber', 'ru': 'Температура', 'ar': 'حمى', 'hi': 'बुखार', 'bn': 'জ্বর', 'pt': 'Febre'});
  String get trackerBadWater => _t({'es': 'Bebe agua', 'en': 'Drink water', 'fr': "Bois de l'eau", 'de': 'Trink Wasser', 'ru': 'Пей воду', 'ar': 'اشربي ماء', 'hi': 'पानी पिएं', 'bn': 'পানি পান করুন', 'pt': 'Beba água'});
  String get trackerBadSleep => _t({'es': 'Poco sueño', 'en': 'Low sleep', 'fr': 'Peu de sommeil', 'de': 'Wenig Schlaf', 'ru': 'Мало сна', 'ar': 'قلة النوم', 'hi': 'कम नींद', 'bn': 'কম ঘুম', 'pt': 'Pouco sono'});

  // ---- Catálogos con id (flujo, síntomas, niveles) ----
  // Gotas de sangre añadidas a Ligero/Medio/Abundante (una por nivel de
  // intensidad) a petición del usuario, que notó que "Flujo" era la única
  // fila del editor sin ningún símbolo, mientras que Moco cervical y
  // Síntomas sí llevan emoji — "Sin flujo" se deja sin gota a propósito,
  // ya que no hay flujo que representar.
  static const Map<String, Map<String, String>> _flowTable = {
    'none': {'es': 'Sin flujo', 'en': 'No flow', 'fr': 'Aucun flux', 'de': 'Keine Blutung', 'ru': 'Нет выделений', 'ar': 'بدون إفرازات', 'hi': 'रक्तस्राव नहीं', 'bn': 'কোনো স্রাব নেই', 'pt': 'Sem fluxo'},
    'light': {'es': '🩸 Ligero', 'en': '🩸 Light', 'fr': '🩸 Léger', 'de': '🩸 Leicht', 'ru': '🩸 Лёгкие', 'ar': '🩸 خفيف', 'hi': '🩸 हल्का', 'bn': '🩸 হালকা', 'pt': '🩸 Leve'},
    'medium': {'es': '🩸🩸 Medio', 'en': '🩸🩸 Medium', 'fr': '🩸🩸 Moyen', 'de': '🩸🩸 Mittel', 'ru': '🩸🩸 Средние', 'ar': '🩸🩸 متوسط', 'hi': '🩸🩸 मध्यम', 'bn': '🩸🩸 মাঝারি', 'pt': '🩸🩸 Médio'},
    'heavy': {'es': '🩸🩸🩸 Abundante', 'en': '🩸🩸🩸 Heavy', 'fr': '🩸🩸🩸 Abondant', 'de': '🩸🩸🩸 Stark', 'ru': '🩸🩸🩸 Обильные', 'ar': '🩸🩸🩸 غزير', 'hi': '🩸🩸🩸 भारी', 'bn': '🩸🩸🩸 ভারী', 'pt': '🩸🩸🩸 Intenso'},
  };
  String flowLabelFor(String id) => _t(_flowTable[id] ?? _flowTable['none']!);

  // Solo el texto, sin emoji de gota — usado en el diseño con icono de
  // gota dibujado aparte (Icons.water_drop) en vez de emoji incrustado en
  // el texto del chip.
  static const Map<String, Map<String, String>> _flowTextOnlyTable = {
    'none': {'es': 'Ninguno', 'en': 'None', 'fr': 'Aucun', 'de': 'Keine', 'ru': 'Нет', 'ar': 'بدون', 'hi': 'कोई नहीं', 'bn': 'কোনোটিই নয়', 'pt': 'Nenhum'},
    'light': {'es': 'Ligero', 'en': 'Light', 'fr': 'Léger', 'de': 'Leicht', 'ru': 'Лёгкие', 'ar': 'خفيف', 'hi': 'हल्का', 'bn': 'হালকা', 'pt': 'Leve'},
    'medium': {'es': 'Medio', 'en': 'Medium', 'fr': 'Moyen', 'de': 'Mittel', 'ru': 'Средние', 'ar': 'متوسط', 'hi': 'मध्यम', 'bn': 'মাঝারি', 'pt': 'Médio'},
    'heavy': {'es': 'Abundante', 'en': 'Heavy', 'fr': 'Abondant', 'de': 'Stark', 'ru': 'Обильные', 'ar': 'غزير', 'hi': 'भारी', 'bn': 'ভারী', 'pt': 'Intenso'},
  };
  String flowTextOnlyLabelFor(String id) => _t(_flowTextOnlyTable[id] ?? _flowTextOnlyTable['none']!);

  static const Map<String, Map<String, String>> _spottingTable = {
    'none': {'es': 'Ninguno', 'en': 'None', 'fr': 'Aucun', 'de': 'Keine', 'ru': 'Нет', 'ar': 'بدون', 'hi': 'कोई नहीं', 'bn': 'কোনোটিই নয়', 'pt': 'Nenhum'},
    'brown': {'es': 'Marrón', 'en': 'Brown', 'fr': 'Marron', 'de': 'Braun', 'ru': 'Коричневые', 'ar': 'بني', 'hi': 'भूरा', 'bn': 'বাদামি', 'pt': 'Marrom'},
    'pink': {'es': 'Rosa', 'en': 'Pink', 'fr': 'Rose', 'de': 'Rosa', 'ru': 'Розовые', 'ar': 'وردي', 'hi': 'गुलाबी', 'bn': 'গোলাপি', 'pt': 'Rosa'},
    'red': {'es': 'Rojo', 'en': 'Red', 'fr': 'Rouge', 'de': 'Rot', 'ru': 'Красные', 'ar': 'أحمر', 'hi': 'लाल', 'bn': 'লাল', 'pt': 'Vermelho'},
  };
  String spottingLabelFor(String id) => _t(_spottingTable[id] ?? _spottingTable['none']!);

  static const Map<String, Map<String, String>> _symptomTable = {
    'dolor': {'es': 'Dolor', 'en': 'Pain', 'fr': 'Douleur', 'de': 'Schmerz', 'ru': 'Боль', 'ar': 'ألم', 'hi': 'दर्द', 'bn': 'ব্যথা', 'pt': 'Dor'},
    'animo': {'es': 'Ánimo', 'en': 'Mood', 'fr': 'Humeur', 'de': 'Stimmung', 'ru': 'Настроение', 'ar': 'المزاج', 'hi': 'मनोदशा', 'bn': 'মেজাজ', 'pt': 'Humor'},
    'energia': {'es': 'Energía', 'en': 'Energy', 'fr': 'Énergie', 'de': 'Energie', 'ru': 'Энергия', 'ar': 'الطاقة', 'hi': 'ऊर्जा', 'bn': 'শক্তি', 'pt': 'Energia'},
    'antojos': {'es': 'Antojos', 'en': 'Cravings', 'fr': 'Envies', 'de': 'Heißhunger', 'ru': 'Тяга к еде', 'ar': 'الرغبة الشديدة في الطعام', 'hi': 'लालसा', 'bn': 'আকাঙ্ক্ষা', 'pt': 'Desejos'},
    'hinchazon': {'es': 'Hinchazón', 'en': 'Bloating', 'fr': 'Ballonnements', 'de': 'Blähungen', 'ru': 'Вздутие', 'ar': 'انتفاخ', 'hi': 'सूजन', 'bn': 'ফোলাভাব', 'pt': 'Inchaço'},
    'sueno': {'es': 'Sueño', 'en': 'Sleepiness', 'fr': 'Sommeil', 'de': 'Müdigkeit', 'ru': 'Сонливость', 'ar': 'النعاس', 'hi': 'नींद', 'bn': 'ঘুম ঘুম ভাব', 'pt': 'Sonolência'},
    'acne': {'es': 'Acné', 'en': 'Acne', 'fr': 'Acné', 'de': 'Akne', 'ru': 'Акне', 'ar': 'حب الشباب', 'hi': 'मुंहासे', 'bn': 'ব্রণ', 'pt': 'Acne'},
    'dolorcab': {'es': 'Cabeza', 'en': 'Headache', 'fr': 'Mal de tête', 'de': 'Kopfschmerzen', 'ru': 'Головная боль', 'ar': 'صداع', 'hi': 'सिरदर्द', 'bn': 'মাথাব্যথা', 'pt': 'Dor de cabeça'},
  };
  String symptomLabelFor(String id) => _t(_symptomTable[id] ?? {'es': id, 'en': id, 'fr': id, 'de': id, 'ru': id, 'ar': id, 'hi': id, 'bn': id, 'pt': id});

  static const Map<String, Map<String, String>> _symptomLevelTable = {
    'leve': {'es': 'leve', 'en': 'mild', 'fr': 'léger', 'de': 'leicht', 'ru': 'лёгкая', 'ar': 'خفيف', 'hi': 'हल्का', 'bn': 'হালকা', 'pt': 'leve'},
    'moderado': {'es': 'moderado', 'en': 'moderate', 'fr': 'modéré', 'de': 'mäßig', 'ru': 'умеренная', 'ar': 'متوسط', 'hi': 'मध्यम', 'bn': 'মাঝারি', 'pt': 'moderado'},
    'fuerte': {'es': 'fuerte', 'en': 'strong', 'fr': 'fort', 'de': 'stark', 'ru': 'сильная', 'ar': 'شديد', 'hi': 'तेज़', 'bn': 'তীব্র', 'pt': 'forte'},
  };
  String symptomLevelLabelFor(String id) => _t(_symptomLevelTable[id] ?? {'es': id, 'en': id, 'fr': id, 'de': id, 'ru': id, 'ar': id, 'hi': id, 'bn': id, 'pt': id});

  // ==================== stats_screen.dart ====================

  String get statsTitle => _t({'es': 'Estadísticas de ciclo', 'en': 'Cycle statistics', 'fr': 'Statistiques du cycle', 'de': 'Zyklusstatistik', 'ru': 'Статистика цикла', 'ar': 'إحصائيات الدورة', 'hi': 'चक्र के आँकड़े', 'bn': 'চক্রের পরিসংখ্যান', 'pt': 'Estatísticas do ciclo'});
  String get statCyclesLogged => _t({'es': 'Ciclos registrados', 'en': 'Cycles logged', 'fr': 'Cycles enregistrés', 'de': 'Erfasste Zyklen', 'ru': 'Зарегистрировано циклов', 'ar': 'الدورات المسجّلة', 'hi': 'दर्ज किए गए चक्र', 'bn': 'লগ করা চক্র', 'pt': 'Ciclos registrados'});
  String get statAvgDuration => _t({
        'es': 'Duración promedio (días)',
        'en': 'Average length (days)',
        'fr': 'Durée moyenne (jours)',
        'de': 'Durchschnittliche Dauer (Tage)',
        'ru': 'Средняя длительность (дни)',
        'ar': 'متوسط المدة (أيام)',
        'hi': 'औसत अवधि (दिन)',
        'bn': 'গড় স্থিতিকাল (দিন)',
        'pt': 'Duração média (dias)',
      });
  String get statPeriodDuration => _t({
        'es': 'Duración de periodo (días)',
        'en': 'Period length (days)',
        'fr': 'Durée des règles (jours)',
        'de': 'Periodendauer (Tage)',
        'ru': 'Длительность менструации (дни)',
        'ar': 'مدة الدورة (أيام)',
        'hi': 'माहवारी की अवधि (दिन)',
        'bn': 'পিরিয়ডের স্থিতিকাল (দিন)',
        'pt': 'Duração do período (dias)',
      });
  String get statCycleRange => _t({'es': 'Rango de ciclo (días)', 'en': 'Cycle range (days)', 'fr': 'Plage du cycle (jours)', 'de': 'Zyklusspanne (Tage)', 'ru': 'Диапазон цикла (дни)', 'ar': 'نطاق الدورة (أيام)', 'hi': 'चक्र सीमा (दिन)', 'bn': 'চক্রের পরিসীমা (দিন)', 'pt': 'Intervalo do ciclo (dias)'});

  String cycleVariationWarning(int minCycle, int maxCycle) => _t({
        'es':
            '⚠️ Tus ciclos han variado bastante últimamente (entre $minCycle y $maxCycle días). Esto puede ser normal, pero si te preocupa, vale la pena comentarlo con tu médico.',
        'en':
            "⚠️ Your cycles have varied quite a bit lately (between $minCycle and $maxCycle days). This can be normal, but if it worries you, it's worth mentioning to your doctor.",
        'fr':
            "⚠️ Vos cycles ont beaucoup varié récemment (entre $minCycle et $maxCycle jours). Cela peut être normal, mais si cela vous inquiète, il vaut la peine d'en parler à votre médecin.",
        'de':
            '⚠️ Deine Zyklen haben in letzter Zeit ziemlich stark variiert (zwischen $minCycle und $maxCycle Tagen). Das kann normal sein, aber wenn es dich beunruhigt, sprich am besten mit deiner Ärztin oder deinem Arzt darüber.',
        'ru': '⚠️ Твои циклы в последнее время довольно сильно менялись (от $minCycle до $maxCycle дн.). Это может быть нормальным, но если тебя это беспокоит, стоит обсудить с врачом.',
        'ar': '⚠️ تفاوتت دوراتكِ كثيرًا مؤخرًا (بين $minCycle و$maxCycle يومًا). قد يكون هذا طبيعيًا، لكن إذا كان يقلقكِ، فمن الجيد استشارة طبيبتك.',
        'hi': '⚠️ हाल ही में आपके चक्र काफी बदलते रहे हैं ($minCycle से $maxCycle दिनों के बीच)। यह सामान्य हो सकता है, लेकिन अगर आपको चिंता है, तो अपने डॉक्टर से बात करना अच्छा रहेगा।',
        'bn': '⚠️ সম্প্রতি আপনার চক্রে বেশ পরিবর্তন হয়েছে ($minCycle থেকে $maxCycle দিনের মধ্যে)। এটি স্বাভাবিক হতে পারে, তবে যদি এটি আপনাকে চিন্তিত করে, তাহলে আপনার ডাক্তারের সঙ্গে কথা বলা ভালো।',
        'pt': '⚠️ Seus ciclos têm variado bastante ultimamente (entre $minCycle e $maxCycle dias). Isso pode ser normal, mas se isso te preocupa, vale a pena comentar com seu médico.',
      });

  String get bmiRegisterWeightHint => _t({
        'es': '⚖️ Registra tu peso en algún día para ver tu IMC aquí.',
        'en': '⚖️ Log your weight on any day to see your BMI here.',
        'fr': '⚖️ Enregistrez votre poids un jour donné pour voir votre IMC ici.',
        'de': '⚖️ Trage an einem beliebigen Tag dein Gewicht ein, um hier deinen BMI zu sehen.',
        'ru': '⚖️ Отметь свой вес в какой-нибудь день, чтобы увидеть здесь свой ИМТ.',
        'ar': '⚖️ سجّلي وزنكِ في أي يوم لرؤية مؤشر كتلة الجسم هنا.',
        'hi': '⚖️ अपना वज़न किसी भी दिन दर्ज करें ताकि यहाँ अपना बीएमआई देख सकें।',
        'bn': '⚖️ আপনার বিএমআই এখানে দেখতে যেকোনো দিন আপনার ওজন লগ করুন।',
        'pt': '⚖️ Registre seu peso em algum dia para ver seu IMC aqui.',
      });
  String get bmiAddHeightHint => _t({
        'es': '📏 Agrega tu altura en Configuración → Mi perfil para ver tu IMC.',
        'en': '📏 Add your height in Settings → My profile to see your BMI.',
        'fr': '📏 Ajoutez votre taille dans Paramètres → Mon profil pour voir votre IMC.',
        'de': '📏 Trage deine Größe unter Einstellungen → Mein Profil ein, um deinen BMI zu sehen.',
        'ru': '📏 Добавь свой рост в Настройки → Мой профиль, чтобы увидеть свой ИМТ.',
        'ar': '📏 أضيفي طولكِ في الإعدادات ← ملفي الشخصي لرؤية مؤشر كتلة الجسم.',
        'hi': '📏 अपना बीएमआई देखने के लिए सेटिंग्स → मेरी प्रोफ़ाइल में अपनी ऊंचाई जोड़ें।',
        'bn': '📏 আপনার বিএমআই দেখতে সেটিংস → আমার প্রোফাইলে আপনার উচ্চতা যোগ করুন।',
        'pt': '📏 Adicione sua altura em Configurações → Meu perfil para ver seu IMC.',
      });
  String get bmiTitle => _t({'es': '⚖️ Tu IMC', 'en': '⚖️ Your BMI', 'fr': '⚖️ Votre IMC', 'de': '⚖️ Dein BMI', 'ru': '⚖️ Твой ИМТ', 'ar': '⚖️ مؤشر كتلة جسمك', 'hi': '⚖️ आपका बीएमआई', 'bn': '⚖️ আপনার বিএমআই', 'pt': '⚖️ Seu IMC'});
  String bmiWithValues(String weight, String heightCm) => _t({
        'es': 'Con $weight kg y $heightCm cm',
        'en': 'With $weight kg and $heightCm cm',
        'fr': 'Avec $weight kg et $heightCm cm',
        'de': 'Mit $weight kg und $heightCm cm',
        'ru': 'С весом $weight кг и ростом $heightCm см',
        'ar': 'بوزن $weight كجم وطول $heightCm سم',
        'hi': '$weight किग्रा और $heightCm सेमी के साथ',
        'bn': '$weight কেজি এবং $heightCm সেমি সহ',
        'pt': 'Com $weight kg e $heightCm cm',
      });
  String get bmiCategoryUnderweight => _t({'es': 'Bajo peso', 'en': 'Underweight', 'fr': 'Insuffisance pondérale', 'de': 'Untergewicht', 'ru': 'Недостаточный вес', 'ar': 'نقص الوزن', 'hi': 'कम वज़न', 'bn': 'কম ওজন', 'pt': 'Abaixo do peso'});
  String get bmiCategoryNormal => _t({'es': 'Normal', 'en': 'Normal', 'fr': 'Normal', 'de': 'Normal', 'ru': 'Норма', 'ar': 'طبيعي', 'hi': 'सामान्य', 'bn': 'স্বাভাবিক', 'pt': 'Normal'});
  String get bmiCategoryOverweight => _t({'es': 'Sobrepeso', 'en': 'Overweight', 'fr': 'Surpoids', 'de': 'Übergewicht', 'ru': 'Избыточный вес', 'ar': 'زيادة الوزن', 'hi': 'अधिक वज़न', 'bn': 'অতিরিক্ত ওজন', 'pt': 'Sobrepeso'});
  String get bmiCategoryObesity => _t({'es': 'Obesidad', 'en': 'Obesity', 'fr': 'Obésité', 'de': 'Adipositas', 'ru': 'Ожирение', 'ar': 'السمنة', 'hi': 'मोटापा', 'bn': 'স্থূলতা', 'pt': 'Obesidade'});

  String get exportPdfButton =>
      _t({'es': '📄 Exportar reporte para el médico (PDF)', 'en': '📄 Export report for your doctor (PDF)', 'fr': '📄 Exporter le rapport pour le médecin (PDF)', 'de': '📄 Bericht für die Ärztin/den Arzt exportieren (PDF)', 'ru': '📄 Экспортировать отчёт для врача (PDF)', 'ar': '📄 تصدير تقرير للطبيبة (PDF)', 'hi': '📄 डॉक्टर के लिए रिपोर्ट निर्यात करें (PDF)', 'bn': '📄 ডাক্তারের জন্য রিপোর্ট এক্সপোর্ট করুন (PDF)', 'pt': '📄 Exportar relatório para o médico (PDF)'});
  String get exportPdfGenerating =>
      _t({'es': 'Generando PDF...', 'en': 'Generating PDF...', 'fr': 'Génération du PDF...', 'de': 'PDF wird erstellt...', 'ru': 'Создание PDF...', 'ar': 'جارٍ إنشاء ملف PDF...', 'hi': 'PDF बन रहा है...', 'bn': 'PDF তৈরি হচ্ছে...', 'pt': 'Gerando PDF...'});
  String get exportPdfError => _t({
        'es': 'No se pudo generar el PDF.',
        'en': "Couldn't generate the PDF.",
        'fr': "Impossible de générer le PDF.",
        'de': 'Das PDF konnte nicht erstellt werden.',
        'ru': 'Не удалось создать PDF.',
        'ar': 'تعذّر إنشاء ملف PDF.',
        'hi': 'PDF नहीं बन सका।',
        'bn': 'PDF তৈরি করা যায়নি।',
        'pt': 'Não foi possível gerar o PDF.',
      });

  String get tempAndSymptomsTitle =>
      _t({'es': 'Temperatura y síntomas', 'en': 'Temperature and symptoms', 'fr': 'Température et symptômes', 'de': 'Temperatur und Symptome', 'ru': 'Температура и симптомы', 'ar': 'درجة الحرارة والأعراض', 'hi': 'तापमान और लक्षण', 'bn': 'তাপমাত্রা এবং লক্ষণ', 'pt': 'Temperatura e sintomas'});
  String get chartTempBasalLegend =>
      _t({'es': '🌡️ Temperatura basal', 'en': '🌡️ Basal temperature', 'fr': '🌡️ Température basale', 'de': '🌡️ Basaltemperatur', 'ru': '🌡️ Базальная температура', 'ar': '🌡️ درجة الحرارة الأساسية', 'hi': '🌡️ बेसल तापमान', 'bn': '🌡️ বেসাল তাপমাত্রা', 'pt': '🌡️ Temperatura basal'});
  String get chartPeriodLegend => _t({'es': '▬ Periodo', 'en': '▬ Period', 'fr': '▬ Règles', 'de': '▬ Periode', 'ru': '▬ Менструация', 'ar': '▬ الدورة', 'hi': '▬ माहवारी', 'bn': '▬ পিরিয়ড', 'pt': '▬ Período'});

  String get yearComparisonTitle =>
      _t({'es': 'Comparación por año', 'en': 'Year comparison', 'fr': 'Comparaison par année', 'de': 'Jahresvergleich', 'ru': 'Сравнение по годам', 'ar': 'مقارنة سنوية', 'hi': 'वर्ष के अनुसार तुलना', 'bn': 'বছর অনুযায়ী তুলনা', 'pt': 'Comparação por ano'});
  String yearDays(int avg) => _t({'es': '$avg días', 'en': '$avg days', 'fr': '$avg jours', 'de': '$avg Tage', 'ru': '$avg дн.', 'ar': '$avg أيام', 'hi': '$avg दिन', 'bn': '$avg দিন', 'pt': '$avg dias'});

  String get insightPrefix => _t({'es': 'Sueles registrar ', 'en': 'You tend to log ', 'fr': 'Vous enregistrez souvent ', 'de': 'Du trägst häufig ', 'ru': 'Ты обычно отмечаешь ', 'ar': 'عادةً ما تسجّلين ', 'hi': 'आप आमतौर पर दर्ज करती हैं ', 'bn': 'আপনি সাধারণত লগ করেন ', 'pt': 'Você costuma registrar '});
  String insightSuffix(int percent) => _t({
        'es': ' en los 3 días antes de tu periodo en $percent% de tus ciclos.',
        'en': ' in the 3 days before your period in $percent% of your cycles.',
        'fr': ' dans les 3 jours avant vos règles dans $percent % de vos cycles.',
        'de': ' in $percent % deiner Zyklen in den 3 Tagen vor deiner Periode ein.',
        'ru': ' за 3 дня до менструации в $percent% твоих циклов.',
        'ar': ' في الأيام الثلاثة التي تسبق دورتك في $percent% من دوراتك.',
        'hi': ' अपनी माहवारी से 3 दिन पहले $percent% चक्रों में।',
        'bn': ' আপনার পিরিয়ডের 3 দিন আগে আপনার $percent% চক্রে।',
        'pt': ' nos 3 dias antes do seu período em $percent% dos seus ciclos.',
      });

  // ---- Consejo del día, según fase actual del ciclo ----
  String get statsPhaseTipTitle => _t({
        'es': 'Consejo de hoy',
        'en': "Today's tip",
        'fr': 'Conseil du jour',
        'de': 'Tipp für heute',
        'ru': 'Совет дня',
        'ar': 'نصيحة اليوم',
        'hi': 'आज की सलाह',
        'bn': 'আজকের পরামর্শ',
        'pt': 'Dica de hoje',
      });
  String statsPhaseTipPhaseLabel(String phaseName) => _t({
        'es': 'Estás en: $phaseName',
        'en': "You're in: $phaseName",
        'fr': 'Vous êtes en : $phaseName',
        'de': 'Du bist in: $phaseName',
        'ru': 'Ты сейчас на этапе: $phaseName',
        'ar': 'أنتِ الآن في: $phaseName',
        'hi': 'आप हैं: $phaseName',
        'bn': 'আপনি আছেন: $phaseName',
        'pt': 'Você está em: $phaseName',
      });

  // ---- Tarjetas de salud por fase (HRV, FC en reposo, temperatura) ----
  // A petición del usuario, que compartió una captura de una app de
  // referencia con tarjetas que comparan una métrica de salud entre las
  // 4 fases del ciclo (gráfico de barras + promedio + más alto/más bajo).
  String get statsHrvTitle => _t({
        'es': 'Variabilidad de la frecuencia cardíaca',
        'en': 'Heart rate variability',
        'fr': 'Variabilité de la fréquence cardiaque',
        'de': 'Herzfrequenzvariabilität',
        'ru': 'Вариабельность сердечного ритма',
        'ar': 'تغيرية معدل ضربات القلب',
        'hi': 'हृदय गति परिवर्तनशीलता',
        'bn': 'হৃদস্পন্দনের পরিবর্তনশীলতা',
        'pt': 'Variabilidade da frequência cardíaca',
      });
  String get statsRestingHrTitle => _t({
        'es': 'Frecuencia cardíaca en reposo',
        'en': 'Resting heart rate',
        'fr': 'Fréquence cardiaque au repos',
        'de': 'Ruheherzfrequenz',
        'ru': 'Пульс в покое',
        'ar': 'معدل ضربات القلب أثناء الراحة',
        'hi': 'विश्राम के समय हृदय गति',
        'bn': 'বিশ্রামকালীন হৃদস্পন্দন',
        'pt': 'Frequência cardíaca em repouso',
      });
  String get statsTempDeviationTitle => _t({
        'es': 'Desviación de temperatura',
        'en': 'Temperature deviation',
        'fr': 'Écart de température',
        'de': 'Temperaturabweichung',
        'ru': 'Отклонение температуры',
        'ar': 'انحراف درجة الحرارة',
        'hi': 'तापमान विचलन',
        'bn': 'তাপমাত্রার বিচ্যুতি',
        'pt': 'Desvio de temperatura',
      });
  String statsHighestInPhase(String phaseName) => _t({
        'es': 'Más alto en tu $phaseName',
        'en': 'Highest in your $phaseName',
        'fr': 'Plus élevé pendant votre $phaseName',
        'de': 'Am höchsten in deiner $phaseName',
        'ru': 'Максимум в твоей $phaseName',
        'ar': 'الأعلى في $phaseName',
        'hi': 'आपकी $phaseName में सबसे अधिक',
        'bn': 'আপনার $phaseName-এ সর্বোচ্চ',
        'pt': 'Mais alto na sua $phaseName',
      });
  String statsLowestInPhase(String phaseName) => _t({
        'es': 'Más bajo en tu $phaseName',
        'en': 'Lowest in your $phaseName',
        'fr': 'Plus bas pendant votre $phaseName',
        'de': 'Am niedrigsten in deiner $phaseName',
        'ru': 'Минимум в твоей $phaseName',
        'ar': 'الأدنى في $phaseName',
        'hi': 'आपकी $phaseName में सबसे कम',
        'bn': 'আপনার $phaseName-এ সর্বনিম্ন',
        'pt': 'Mais baixo na sua $phaseName',
      });
  String get statsPhaseAverageLabel =>
      _t({'es': 'Promedio', 'en': 'Average', 'fr': 'Moyenne', 'de': 'Durchschnitt', 'ru': 'Среднее', 'ar': 'المتوسط', 'hi': 'औसत', 'bn': 'গড়', 'pt': 'Média'});
  String get statsPhaseHighestLabel =>
      _t({'es': 'Más alto', 'en': 'Highest', 'fr': 'Le plus élevé', 'de': 'Höchster Wert', 'ru': 'Максимум', 'ar': 'الأعلى', 'hi': 'सबसे अधिक', 'bn': 'সর্বোচ্চ', 'pt': 'Mais alto'});
  String get statsPhaseLowestLabel =>
      _t({'es': 'Más bajo', 'en': 'Lowest', 'fr': 'Le plus bas', 'de': 'Niedrigster Wert', 'ru': 'Минимум', 'ar': 'الأدنى', 'hi': 'सबसे कम', 'bn': 'সর্বনিম্ন', 'pt': 'Mais baixo'});
  String get statsBasedOnHealthData => _t({
        'es': 'Basado en los datos de tu cuerpo',
        'en': "Based on your body's data",
        'fr': 'Basé sur les données de votre corps',
        'de': 'Basierend auf deinen Körperdaten',
        'ru': 'На основе данных твоего тела',
        'ar': 'بناءً على بيانات جسمك',
        'hi': 'आपके शरीर के आँकड़ों पर आधारित',
        'bn': 'আপনার শরীরের তথ্যের ভিত্তিতে',
        'pt': 'Baseado nos dados do seu corpo',
      });
  String get statsConnectedToHealth => _t({
        'es': 'Conectado con salud',
        'en': 'Connected to health',
        'fr': 'Connecté à la santé',
        'de': 'Mit Gesundheit verbunden',
        'ru': 'Подключено к здоровью',
        'ar': 'متصل بتطبيق الصحة',
        'hi': 'स्वास्थ्य से जुड़ा हुआ',
        'bn': 'স্বাস্থ্যের সাথে সংযুক্ত',
        'pt': 'Conectado à saúde',
      });

  // Explicación al tocar el ícono (i) de cada tarjeta de salud —
  // qué mide la métrica + aviso de que requiere un reloj/wearable
  // sincronizado con Apple Salud o Health Connect (no todos los
  // teléfonos la registran por sí solos).
  String get statsHrvInfoExplanation => _t({
        'es':
            'La variabilidad de la frecuencia cardíaca (HRV) mide la variación de tiempo entre latidos y refleja cómo tu sistema nervioso se adapta al estrés y la recuperación. Suele bajar en la fase lútea y subir en la folicular.\n\nSolo se muestra si usas un reloj inteligente u otro dispositivo compatible, sincronizado con Apple Salud o Health Connect — el teléfono solo no la registra.',
        'en':
            'Heart rate variability (HRV) measures the variation in time between heartbeats and reflects how your nervous system adapts to stress and recovery. It tends to drop in the luteal phase and rise in the follicular phase.\n\nThis only shows up if you use a smartwatch or other compatible device synced with Apple Health or Health Connect — the phone alone cannot record it.',
        'fr':
            "La variabilité de la fréquence cardiaque (VFC) mesure la variation du temps entre les battements et reflète l'adaptation de votre système nerveux au stress et à la récupération. Elle a tendance à baisser en phase lutéale et à augmenter en phase folliculaire.\n\nElle ne s'affiche que si vous utilisez une montre connectée ou un autre appareil compatible synchronisé avec Apple Santé ou Health Connect — le téléphone seul ne peut pas l'enregistrer.",
        'de':
            'Die Herzfrequenzvariabilität (HRV) misst die Schwankung der Zeit zwischen den Herzschlägen und zeigt, wie sich dein Nervensystem an Stress und Erholung anpasst. Sie sinkt tendenziell in der Lutealphase und steigt in der Follikelphase.\n\nSie wird nur angezeigt, wenn du eine Smartwatch oder ein anderes kompatibles Gerät verwendest, das mit Apple Health oder Health Connect synchronisiert ist — das Telefon allein kann sie nicht erfassen.',
        'ru': 'Вариабельность сердечного ритма (ВСР) измеряет изменение времени между ударами сердца и отражает, как твоя нервная система адаптируется к стрессу и восстановлению. Обычно снижается в лютеиновой фазе и растёт в фолликулярной.\n\nОтображается только если ты используешь смарт-часы или другое совместимое устройство, синхронизированное с Apple Health или Health Connect — сам по себе телефон её не регистрирует.',
        'ar': 'تقيس تغيرية معدل ضربات القلب (HRV) التباين الزمني بين ضربات القلب وتعكس كيفية تكيّف جهازك العصبي مع التوتر والتعافي. تميل إلى الانخفاض في المرحلة الأصفرية والارتفاع في المرحلة الجريبية.\n\nتظهر فقط إذا كنتِ تستخدمين ساعة ذكية أو جهازًا متوافقًا آخر متزامنًا مع Apple Health أو Health Connect — فالهاتف وحده لا يسجّلها.',
        'hi':
            'हृदय गति परिवर्तनशीलता (HRV) दिल की धड़कनों के बीच के समय के अंतर को मापती है और दर्शाती है कि आपका तंत्रिका तंत्र तनाव और रिकवरी के अनुसार कैसे ढलता है। यह आमतौर पर ल्यूटियल चरण में घटती है और फॉलिक्युलर चरण में बढ़ती है।\n\nयह तभी दिखाई देती है जब आप कोई स्मार्टवॉच या अन्य संगत डिवाइस इस्तेमाल करती हैं, जो Apple Health या Health Connect से समन्वित हो — अकेला फ़ोन इसे दर्ज नहीं कर सकता।',
        'bn':
            'হৃদস্পন্দনের পরিবর্তনশীলতা (HRV) হৃদস্পন্দনের মধ্যবর্তী সময়ের তারতম্য পরিমাপ করে এবং এটি প্রকাশ করে যে আপনার স্নায়ুতন্ত্র কীভাবে চাপ এবং পুনরুদ্ধারের সাথে খাপ খাইয়ে নেয়। এটি সাধারণত লুটিয়াল পর্যায়ে কমে যায় এবং ফলিকুলার পর্যায়ে বেড়ে যায়।\n\nএটি তখনই দেখা যায় যখন আপনি Apple Health বা Health Connect-এর সাথে সিঙ্ক করা একটি স্মার্টওয়াচ বা অন্য সামঞ্জস্যপূর্ণ ডিভাইস ব্যবহার করেন — শুধু ফোন এটি রেকর্ড করতে পারে না।',
        'pt':
            'A variabilidade da frequência cardíaca (VFC) mede a variação de tempo entre os batimentos e reflete como seu sistema nervoso se adapta ao estresse e à recuperação. Costuma cair na fase lútea e subir na fase folicular.\n\nSó aparece se você usar um smartwatch ou outro dispositivo compatível, sincronizado com o Apple Saúde ou Health Connect — o celular sozinho não consegue registrá-la.',
      });
  String get statsRestingHrInfoExplanation => _t({
        'es':
            'La frecuencia cardíaca en reposo indica cuántas veces late tu corazón por minuto cuando estás completamente relajada. Puede subir ligeramente en la fase lútea debido a los cambios hormonales.\n\nSolo se muestra si usas un reloj inteligente u otro dispositivo compatible, sincronizado con Apple Salud o Health Connect — el teléfono solo no la registra.',
        'en':
            'Resting heart rate shows how many times your heart beats per minute while fully at rest. It can rise slightly in the luteal phase due to hormonal changes.\n\nThis only shows up if you use a smartwatch or other compatible device synced with Apple Health or Health Connect — the phone alone cannot record it.',
        'fr':
            'La fréquence cardiaque au repos indique le nombre de battements de votre cœur par minute lorsque vous êtes complètement détendue. Elle peut légèrement augmenter en phase lutéale en raison des changements hormonaux.\n\nElle ne s\'affiche que si vous utilisez une montre connectée ou un autre appareil compatible synchronisé avec Apple Santé ou Health Connect — le téléphone seul ne peut pas l\'enregistrer.',
        'de':
            'Die Ruheherzfrequenz zeigt, wie oft dein Herz pro Minute schlägt, wenn du vollständig entspannt bist. Sie kann in der Lutealphase aufgrund hormoneller Veränderungen leicht ansteigen.\n\nSie wird nur angezeigt, wenn du eine Smartwatch oder ein anderes kompatibles Gerät verwendest, das mit Apple Health oder Health Connect synchronisiert ist — das Telefon allein kann sie nicht erfassen.',
        'ru': 'Пульс в покое показывает, сколько раз бьётся твоё сердце в минуту, когда ты полностью расслаблена. Он может немного повышаться в лютеиновой фазе из-за гормональных изменений.\n\nОтображается только если ты используешь смарт-часы или другое совместимое устройство, синхронизированное с Apple Health или Health Connect — сам по себе телефон его не регистрирует.',
        'ar': 'يوضح معدل ضربات القلب أثناء الراحة عدد نبضات قلبك في الدقيقة عندما تكونين في حالة استرخاء تام. قد يرتفع قليلاً في المرحلة الأصفرية بسبب التغيرات الهرمونية.\n\nيظهر فقط إذا كنتِ تستخدمين ساعة ذكية أو جهازًا متوافقًا آخر متزامنًا مع Apple Health أو Health Connect — فالهاتف وحده لا يسجّله.',
        'hi':
            'विश्राम के समय हृदय गति बताती है कि जब आप पूरी तरह से आरामदायक स्थिति में होती हैं तो आपका दिल प्रति मिनट कितनी बार धड़कता है। हार्मोनल बदलावों के कारण यह ल्यूटियल चरण में थोड़ा बढ़ सकती है।\n\nयह तभी दिखाई देती है जब आप कोई स्मार्टवॉच या अन्य संगत डिवाइस इस्तेमाल करती हैं, जो Apple Health या Health Connect से समन्वित हो — अकेला फ़ोन इसे दर्ज नहीं कर सकता।',
        'bn':
            'বিশ্রামকালীন হৃদস্পন্দন বোঝায় যে আপনি সম্পূর্ণ বিশ্রামে থাকাকালীন আপনার হৃদয় প্রতি মিনিটে কতবার স্পন্দিত হয়। হরমোনের পরিবর্তনের কারণে এটি লুটিয়াল পর্যায়ে সামান্য বাড়তে পারে।\n\nএটি তখনই দেখা যায় যখন আপনি Apple Health বা Health Connect-এর সাথে সিঙ্ক করা একটি স্মার্টওয়াচ বা অন্য সামঞ্জস্যপূর্ণ ডিভাইস ব্যবহার করেন — শুধু ফোন এটি রেকর্ড করতে পারে না।',
        'pt':
            'A frequência cardíaca em repouso mostra quantas vezes seu coração bate por minuto quando você está totalmente relaxada. Pode subir levemente na fase lútea devido às mudanças hormonais.\n\nSó aparece se você usar um smartwatch ou outro dispositivo compatível, sincronizado com o Apple Saúde ou Health Connect — o celular sozinho não consegue registrá-la.',
      });
  String get statsTempDeviationInfoExplanation => _t({
        'es':
            'La temperatura basal sube entre 0.3 y 0.5 °C tras la ovulación y se mantiene alta durante la fase lútea — este pequeño cambio ("cambio térmico") ayuda a confirmar que ya ovulaste.\n\nSolo se muestra si usas un termómetro basal conectado, reloj inteligente u otro dispositivo compatible, sincronizado con Apple Salud o Health Connect.',
        'en':
            'Basal body temperature rises by about 0.3–0.5°C after ovulation and stays elevated through the luteal phase — this small shift ("thermal shift") helps confirm ovulation already happened.\n\nThis only shows up if you use a connected basal thermometer, smartwatch, or other compatible device synced with Apple Health or Health Connect.',
        'fr':
            "La température basale augmente d'environ 0,3 à 0,5 °C après l'ovulation et reste élevée pendant la phase lutéale — ce léger changement (« décalage thermique ») aide à confirmer que l'ovulation a déjà eu lieu.\n\nElle ne s'affiche que si vous utilisez un thermomètre basal connecté, une montre connectée ou un autre appareil compatible synchronisé avec Apple Santé ou Health Connect.",
        'de':
            'Die Basaltemperatur steigt nach dem Eisprung um etwa 0,3–0,5 °C an und bleibt während der Lutealphase erhöht — diese kleine Veränderung ("Temperaturanstieg") hilft zu bestätigen, dass der Eisprung bereits stattgefunden hat.\n\nSie wird nur angezeigt, wenn du ein verbundenes Basalthermometer, eine Smartwatch oder ein anderes kompatibles Gerät verwendest, das mit Apple Health oder Health Connect synchronisiert ist.',
        'ru': 'Базальная температура повышается на 0,3–0,5 °C после овуляции и остаётся высокой в течение лютеиновой фазы — это небольшое изменение («термический сдвиг») помогает подтвердить, что овуляция уже произошла.\n\nОтображается только если ты используешь подключённый базальный термометр, смарт-часы или другое совместимое устройство, синхронизированное с Apple Health или Health Connect.',
        'ar': 'ترتفع درجة الحرارة الأساسية بمقدار 0.3 إلى 0.5 درجة مئوية بعد الإباضة وتبقى مرتفعة طوال المرحلة الأصفرية — هذا التغير الصغير ("التحول الحراري") يساعد على تأكيد حدوث الإباضة بالفعل.\n\nيظهر فقط إذا كنتِ تستخدمين ميزان حرارة أساسي متصل، أو ساعة ذكية، أو جهازًا متوافقًا آخر متزامنًا مع Apple Health أو Health Connect.',
        'hi':
            'बेसल तापमान ओव्यूलेशन के बाद 0.3 से 0.5 °C तक बढ़ जाता है और ल्यूटियल चरण के दौरान ऊंचा बना रहता है — यह छोटा सा बदलाव ("तापीय बदलाव") यह पुष्टि करने में मदद करता है कि ओव्यूलेशन हो चुका है।\n\nयह तभी दिखाई देता है जब आप कोई कनेक्टेड बेसल थर्मामीटर, स्मार्टवॉच या अन्य संगत डिवाइस इस्तेमाल करती हैं, जो Apple Health या Health Connect से समन्वित हो।',
        'bn':
            'বেসাল তাপমাত্রা ডিম্বস্ফোটনের পরে 0.3 থেকে 0.5 °C বৃদ্ধি পায় এবং লুটিয়াল পর্যায়ে উচ্চ থাকে — এই ছোট পরিবর্তনটি ("তাপীয় পরিবর্তন") নিশ্চিত করতে সাহায্য করে যে ডিম্বস্ফোটন ইতিমধ্যে ঘটেছে।\n\nএটি তখনই দেখা যায় যখন আপনি Apple Health বা Health Connect-এর সাথে সিঙ্ক করা একটি সংযুক্ত বেসাল থার্মোমিটার, স্মার্টওয়াচ বা অন্য সামঞ্জস্যপূর্ণ ডিভাইস ব্যবহার করেন।',
        'pt':
            'A temperatura basal sobe entre 0,3 e 0,5 °C após a ovulação e permanece alta durante a fase lútea — essa pequena mudança ("mudança térmica") ajuda a confirmar que a ovulação já aconteceu.\n\nSó aparece se você usar um termômetro basal conectado, smartwatch ou outro dispositivo compatível, sincronizado com o Apple Saúde ou Health Connect.',
      });
  String get statsRequiresWearableBadge => _t({
        'es': 'Requiere reloj o dispositivo conectado',
        'en': 'Requires a connected watch or device',
        'fr': 'Nécessite une montre ou un appareil connecté',
        'de': 'Erfordert eine verbundene Uhr oder ein Gerät',
        'ru': 'Требуются часы или подключённое устройство',
        'ar': 'يتطلب ساعة أو جهازًا متصلاً',
        'hi': 'इसके लिए घड़ी या कनेक्टेड डिवाइस चाहिए',
        'bn': 'একটি ঘড়ি বা সংযুক্ত ডিভাইস প্রয়োজন',
        'pt': 'Requer relógio ou dispositivo conectado',
      });

  // Abreviaturas de las 4 fases para las etiquetas del eje del gráfico de
  // barras (espacio reducido) — 'Men', 'Fol', 'Ovu', 'Lut'.
  String phaseAbbrev(String phaseKey) {
    switch (phaseKey) {
      case 'menstrual':
        return _t({'es': 'Men', 'en': 'Men', 'fr': 'Men', 'de': 'Men', 'ru': 'Мен', 'ar': 'حيض', 'hi': 'मेन', 'bn': 'মেন', 'pt': 'Men'});
      case 'folicular':
        return _t({'es': 'Fol', 'en': 'Fol', 'fr': 'Fol', 'de': 'Fol', 'ru': 'Фол', 'ar': 'جريب', 'hi': 'फॉल', 'bn': 'ফল', 'pt': 'Fol'});
      case 'ovulacion':
        return _t({'es': 'Ovu', 'en': 'Ovu', 'fr': 'Ovu', 'de': 'Ovu', 'ru': 'Овул', 'ar': 'إباض', 'hi': 'ओवु', 'bn': 'ওভু', 'pt': 'Ovu'});
      case 'lutea':
      default:
        return _t({'es': 'Lut', 'en': 'Lut', 'fr': 'Lut', 'de': 'Lut', 'ru': 'Лют', 'ar': 'أصفر', 'hi': 'ल्यू', 'bn': 'লিউ', 'pt': 'Lut'});
    }
  }

  // ---- Tarjeta educativa "Entiende tu cuerpo" ----
  String get educationCardTitle =>
      _t({'es': '📚 Entiende tu cuerpo', 'en': '📚 Understand your body', 'fr': '📚 Comprendre votre corps', 'de': '📚 Verstehe deinen Körper', 'ru': '📚 Пойми своё тело', 'ar': '📚 افهمي جسمك', 'hi': '📚 अपने शरीर को समझें', 'bn': '📚 আপনার শরীর বুঝুন', 'pt': '📚 Entenda seu corpo'});
  String get educationCardSubtitle => _t({
        'es': 'Explicaciones breves para interpretar mejor tus propias cifras.',
        'en': 'Short explanations to help you better understand your own numbers.',
        'fr': 'Explications brèves pour mieux interpréter vos propres chiffres.',
        'de': 'Kurze Erklärungen, um deine eigenen Werte besser zu verstehen.',
        'ru': 'Краткие пояснения, чтобы лучше понимать свои собственные показатели.',
        'ar': 'شروحات موجزة لمساعدتك على فهم أرقامك بشكل أفضل.',
        'hi': 'आपके अपने आँकड़ों को बेहतर समझने के लिए संक्षिप्त स्पष्टीकरण।',
        'bn': 'আপনার নিজের সংখ্যাগুলো আরও ভালোভাবে বুঝতে সংক্ষিপ্ত ব্যাখ্যা।',
        'pt': 'Explicações breves para entender melhor seus próprios números.',
      });
  String get educationCardFooter => _t({
        'es':
            'Contenido educativo general basado en información pública de ACOG y Mayo Clinic. No es un diagnóstico ni reemplaza la consulta con un profesional de salud.',
        'en':
            'General educational content based on public information from ACOG and Mayo Clinic. This is not a diagnosis and does not replace consulting a healthcare professional.',
        'fr':
            "Contenu éducatif général basé sur des informations publiques de l'ACOG et de la Mayo Clinic. Ce n'est pas un diagnostic et cela ne remplace pas la consultation d'un professionnel de santé.",
        'de':
            'Allgemeine Bildungsinhalte basierend auf öffentlichen Informationen von ACOG und Mayo Clinic. Dies ist keine Diagnose und ersetzt nicht die Beratung durch eine Fachperson im Gesundheitswesen.',
        'ru': 'Общий образовательный контент на основе открытой информации ACOG и Mayo Clinic. Это не диагноз и не заменяет консультацию со специалистом здравоохранения.',
        'ar': 'محتوى تثقيفي عام يستند إلى معلومات عامة من ACOG وMayo Clinic. هذا ليس تشخيصًا ولا يغني عن استشارة أخصائي رعاية صحية.',
        'hi': 'ACOG और Mayo Clinic की सार्वजनिक जानकारी पर आधारित सामान्य शैक्षिक सामग्री। यह कोई निदान नहीं है और किसी स्वास्थ्य पेशेवर से परामर्श का स्थान नहीं लेता।',
        'bn': 'ACOG এবং Mayo Clinic-এর সর্বজনীন তথ্যের ভিত্তিতে সাধারণ শিক্ষামূলক বিষয়বস্তু। এটি কোনো রোগ নির্ণয় নয় এবং কোনো স্বাস্থ্যসেবা পেশাদারের পরামর্শের বিকল্প নয়।',
        'pt': 'Conteúdo educativo geral baseado em informações públicas da ACOG e da Mayo Clinic. Isso não é um diagnóstico nem substitui a consulta com um profissional de saúde.',
      });

  String get eduVariationTitle => _t({
        'es': 'Sobre la variación que ves en tus ciclos',
        'en': 'About the variation you see in your cycles',
        'fr': 'À propos de la variation observée dans vos cycles',
        'de': 'Zur Schwankung, die du in deinen Zyklen siehst',
        'ru': 'О колебаниях, которые ты видишь в своих циклах',
        'ar': 'حول التفاوت الذي تلاحظينه في دوراتك',
        'hi': 'आपके चक्रों में दिखने वाले बदलाव के बारे में',
        'bn': 'আপনার চক্রে যে তারতম্য দেখছেন তা সম্পর্কে',
        'pt': 'Sobre a variação que você vê nos seus ciclos',
      });
  String eduVariationBody(int minCycle, int maxCycle) => _t({
        'es':
            'Tus últimos ciclos van de $minCycle a $maxCycle días. Variar unos días es normal, pero una diferencia tan grande vale la pena registrarla con detalle y, si se repite varios meses, comentarla con tu médico — así descartas causas como estrés, cambios de peso o desequilibrios hormonales.',
        'en':
            'Your last cycles range from $minCycle to $maxCycle days. Varying by a few days is normal, but a difference this large is worth tracking closely and, if it repeats over several months, mentioning to your doctor — that way you can rule out causes like stress, weight changes or hormonal imbalances.',
        'fr':
            "Vos derniers cycles vont de $minCycle à $maxCycle jours. Varier de quelques jours est normal, mais un écart aussi important mérite d'être suivi de près et, s'il se répète pendant plusieurs mois, d'en parler à votre médecin — cela permet d'écarter des causes comme le stress, des changements de poids ou des déséquilibres hormonaux.",
        'de':
            'Deine letzten Zyklen liegen zwischen $minCycle und $maxCycle Tagen. Eine Schwankung von ein paar Tagen ist normal, aber ein so großer Unterschied ist es wert, genau beobachtet zu werden — und wenn er sich über mehrere Monate wiederholt, solltest du ihn mit deiner Ärztin oder deinem Arzt besprechen, um Ursachen wie Stress, Gewichtsveränderungen oder hormonelle Ungleichgewichte auszuschließen.',
        'ru': 'Твои последние циклы варьируются от $minCycle до $maxCycle дн. Колебание на несколько дней — это нормально, но такая большая разница стоит того, чтобы отслеживать её подробно, и если она повторяется несколько месяцев подряд — обсудить с врачом: так можно исключить такие причины, как стресс, изменения веса или гормональные дисбалансы.',
        'ar': 'تتراوح دوراتكِ الأخيرة بين $minCycle و$maxCycle يومًا. التفاوت بضعة أيام أمر طبيعي، لكن فرقًا بهذا الحجم يستحق المتابعة الدقيقة، وإذا تكرر عدة أشهر، يُستحسن ذكره لطبيبتك — لاستبعاد أسباب مثل التوتر أو تغيرات الوزن أو الاختلالات الهرمونية.',
        'hi':
            'आपके पिछले चक्र $minCycle से $maxCycle दिनों के बीच रहे हैं। कुछ दिनों का बदलाव सामान्य है, लेकिन इतना बड़ा अंतर ध्यान से दर्ज करने लायक है, और अगर यह कई महीनों तक दोहराता है, तो इसे अपने डॉक्टर से बताना अच्छा रहेगा — इससे तनाव, वज़न में बदलाव या हार्मोनल असंतुलन जैसे कारणों को नकारा जा सकता है।',
        'bn':
            'আপনার সাম্প্রতিক চক্রগুলো $minCycle থেকে $maxCycle দিনের মধ্যে হয়েছে। কয়েক দিনের তারতম্য স্বাভাবিক, তবে এত বড় পার্থক্য বিস্তারিতভাবে লক্ষ্য রাখার মতো এবং যদি এটি কয়েক মাস ধরে পুনরাবৃত্তি হয়, তাহলে আপনার ডাক্তারকে জানানো ভালো — এভাবে আপনি মানসিক চাপ, ওজনের পরিবর্তন বা হরমোনজনিত ভারসাম্যহীনতার মতো কারণগুলো বাদ দিতে পারবেন।',
        'pt':
            'Seus últimos ciclos variam entre $minCycle e $maxCycle dias. Variar alguns dias é normal, mas uma diferença tão grande vale a pena acompanhar de perto e, se se repetir por vários meses, comentar com seu médico — assim você descarta causas como estresse, mudanças de peso ou desequilíbrios hormonais.',
      });

  String get eduNormalCycleTitle =>
      _t({'es': '¿Qué es un ciclo "normal"?', 'en': 'What counts as a "normal" cycle?', 'fr': "Qu'est-ce qu'un cycle « normal » ?", 'de': 'Was ist ein „normaler" Zyklus?', 'ru': 'Что такое «нормальный» цикл?', 'ar': 'ما هي الدورة "الطبيعية"؟', 'hi': '"सामान्य" चक्र क्या होता है?', 'bn': '"স্বাভাবিক" চক্র বলতে কী বোঝায়?', 'pt': 'O que é um ciclo "normal"?'});
  String get eduNormalCycleBody => _t({
        'es':
            'Un ciclo de 21 a 35 días se considera dentro de lo normal, y un periodo de hasta 7 días también. Muy pocas personas tienen ciclos de exactamente 28 días — la variación de unos días de un mes a otro es habitual y no suele ser motivo de alarma.',
        'en':
            'A cycle of 21 to 35 days is considered within the normal range, and so is a period lasting up to 7 days. Very few people have cycles of exactly 28 days — a variation of a few days from one month to the next is common and usually not a cause for concern.',
        'fr':
            "Un cycle de 21 à 35 jours est considéré comme normal, tout comme des règles durant jusqu'à 7 jours. Très peu de personnes ont des cycles de exactement 28 jours — une variation de quelques jours d'un mois à l'autre est courante et n'est généralement pas inquiétante.",
        'de':
            'Ein Zyklus von 21 bis 35 Tagen gilt als normal, ebenso wie eine Periode von bis zu 7 Tagen. Nur sehr wenige Menschen haben Zyklen von genau 28 Tagen — eine Schwankung von einigen Tagen von Monat zu Monat ist üblich und normalerweise kein Grund zur Sorge.',
        'ru': 'Цикл продолжительностью от 21 до 35 дней считается нормальным, как и менструация продолжительностью до 7 дней. Очень немногие люди имеют цикл ровно в 28 дней — колебание на несколько дней от месяца к месяцу обычно и не является поводом для беспокойства.',
        'ar': 'تُعتبر الدورة التي تتراوح بين 21 و35 يومًا طبيعية، وكذلك الحيض الذي يستمر حتى 7 أيام. قلة قليلة من النساء لديهن دورة مدتها 28 يومًا بالضبط — والتفاوت بضعة أيام من شهر لآخر أمر شائع وعادة لا يستدعي القلق.',
        'hi':
            '21 से 35 दिनों का चक्र सामान्य माना जाता है, और 7 दिनों तक की माहवारी भी। बहुत कम लोगों का चक्र ठीक 28 दिनों का होता है — एक महीने से दूसरे महीने में कुछ दिनों का बदलाव सामान्य है और आमतौर पर चिंता की बात नहीं है।',
        'bn':
            '21 থেকে 35 দিনের একটি চক্র স্বাভাবিক বলে বিবেচিত হয়, এবং 7 দিন পর্যন্ত একটি পিরিয়ডও তাই। খুব কম মানুষের চক্র ঠিক 28 দিনের হয় — এক মাস থেকে অন্য মাসে কয়েক দিনের তারতম্য স্বাভাবিক এবং সাধারণত উদ্বেগের কারণ নয়।',
        'pt':
            'Um ciclo de 21 a 35 dias é considerado dentro do normal, assim como um período de até 7 dias. Muito poucas pessoas têm ciclos de exatamente 28 dias — variar alguns dias de um mês para outro é comum e geralmente não é motivo de preocupação.',
      });

  String get eduBasalTempTitle => _t({
        'es': '¿Para qué sirve la temperatura basal?',
        'en': "What's basal temperature used for?",
        'fr': "À quoi sert la température basale ?",
        'de': 'Wofür ist die Basaltemperatur gut?',
        'ru': 'Для чего нужна базальная температура?',
        'ar': 'ما فائدة درجة الحرارة الأساسية؟',
        'hi': 'बेसल तापमान किस काम आता है?',
        'bn': 'বেসাল তাপমাত্রা কী কাজে লাগে?',
        'pt': 'Para que serve a temperatura basal?',
      });
  String get eduBasalTempBody => _t({
        'es':
            'Tras la ovulación, la temperatura basal suele subir entre 0.3 y 0.5°C y se mantiene así el resto del ciclo. Por eso conviene tomarla siempre a la misma hora, nada más despertar y antes de levantarte: es cuando refleja mejor ese cambio hormonal.',
        'en':
            'After ovulation, basal temperature usually rises by about 0.3 to 0.5°C and stays that way for the rest of the cycle. That\'s why it\'s best to take it at the same time every day, right when you wake up and before getting out of bed: that\'s when it best reflects that hormonal shift.',
        'fr':
            "Après l'ovulation, la température basale augmente généralement de 0,3 à 0,5°C et reste ainsi pour le reste du cycle. C'est pourquoi il vaut mieux la prendre toujours à la même heure, dès le réveil et avant de se lever : c'est à ce moment qu'elle reflète le mieux ce changement hormonal.",
        'de':
            'Nach dem Eisprung steigt die Basaltemperatur meist um 0,3 bis 0,5 °C und bleibt für den Rest des Zyklus so. Deshalb solltest du sie immer zur gleichen Zeit messen, direkt nach dem Aufwachen und bevor du aufstehst — dann spiegelt sie diesen hormonellen Wechsel am besten wider.',
        'ru': 'После овуляции базальная температура обычно повышается на 0,3–0,5 °C и остаётся такой до конца цикла. Поэтому её стоит измерять всегда в одно и то же время, сразу после пробуждения и перед тем, как встать с кровати: именно тогда она лучше всего отражает этот гормональный сдвиг.',
        'ar': 'بعد الإباضة، ترتفع درجة الحرارة الأساسية عادةً بمقدار 0.3 إلى 0.5 درجة مئوية وتبقى كذلك لبقية الدورة. لذلك يُستحسن قياسها دائمًا في نفس الوقت، فور الاستيقاظ وقبل النهوض من السرير: فهذا هو الوقت الذي تعكس فيه هذا التحول الهرموني بشكل أفضل.',
        'hi':
            'ओव्यूलेशन के बाद, बेसल तापमान आमतौर पर 0.3 से 0.5°C तक बढ़ जाता है और बाकी चक्र के दौरान वैसा ही बना रहता है। इसलिए इसे हमेशा एक ही समय पर, जागते ही और बिस्तर से उठने से पहले नापना बेहतर होता है: यही वह समय है जब यह हार्मोनल बदलाव को सबसे अच्छी तरह दर्शाता है।',
        'bn':
            'ডিম্বস্ফোটনের পরে, বেসাল তাপমাত্রা সাধারণত 0.3 থেকে 0.5°C বৃদ্ধি পায় এবং বাকি চক্র জুড়ে তেমনই থাকে। তাই এটি সবসময় একই সময়ে, ঘুম থেকে ওঠার সাথে সাথে এবং বিছানা থেকে ওঠার আগে মাপা ভালো: তখনই এটি সেই হরমোনজনিত পরিবর্তনকে সবচেয়ে ভালোভাবে প্রতিফলিত করে।',
        'pt':
            'Após a ovulação, a temperatura basal costuma subir entre 0,3 e 0,5°C e se mantém assim pelo resto do ciclo. Por isso é melhor medi-la sempre no mesmo horário, assim que acordar e antes de se levantar: é quando ela melhor reflete essa mudança hormonal.',
      });

  String get eduWhenToSeeDoctorTitle => _t({
        'es': '¿Cuándo vale la pena consultar a un médico?',
        'en': 'When is it worth seeing a doctor?',
        'fr': "Quand vaut-il la peine de consulter un médecin ?",
        'de': 'Wann lohnt sich ein Arztbesuch?',
        'ru': 'Когда стоит обратиться к врачу?',
        'ar': 'متى يستحق الأمر استشارة الطبيبة؟', 'hi': 'डॉक्टर से कब सलाह लेनी चाहिए?', 'bn': 'কখন ডাক্তারের পরামর্শ নেওয়া উচিত?', 'pt': 'Quando vale a pena consultar um médico?',
      });
  String get eduWhenToSeeDoctorBody => _t({
        'es':
            'Si tus periodos vienen cada menos de 21 días, cada más de 45, o si de repente pasan más de 90 días sin periodo, es buen momento para hablarlo con un profesional de salud. Lo mismo si un ciclo que siempre fue regular cambia de forma sostenida durante varios meses.',
        'en':
            "If your periods come less than 21 days apart, more than 45 days apart, or if you suddenly go more than 90 days without one, it's a good time to talk to a healthcare professional. The same applies if a cycle that was always regular changes consistently over several months.",
        'fr':
            "Si vos règles surviennent à moins de 21 jours d'intervalle, à plus de 45 jours d'intervalle, ou si vous passez soudainement plus de 90 jours sans règles, c'est le bon moment d'en parler à un professionnel de santé. Il en va de même si un cycle jusque-là régulier change de façon durable pendant plusieurs mois.",
        'de':
            'Wenn deine Periode häufiger als alle 21 Tage, seltener als alle 45 Tage kommt, oder wenn plötzlich mehr als 90 Tage ohne Periode vergehen, ist es ein guter Zeitpunkt, mit einer Fachperson im Gesundheitswesen zu sprechen. Das gilt auch, wenn sich ein bisher regelmäßiger Zyklus über mehrere Monate hinweg dauerhaft verändert.',
        'ru': 'Если твои менструации приходят чаще, чем раз в 21 день, реже, чем раз в 45 дней, или если вдруг проходит больше 90 дней без менструации — самое время поговорить со специалистом здравоохранения. То же самое, если цикл, который всегда был регулярным, стабильно меняется в течение нескольких месяцев.',
        'ar': 'إذا كانت دورتكِ تأتي كل أقل من 21 يومًا، أو كل أكثر من 45 يومًا، أو إذا مرّ فجأة أكثر من 90 يومًا دون دورة، فهذا وقت مناسب للتحدث مع أخصائي رعاية صحية. وينطبق الأمر ذاته إذا تغيرت دورة كانت منتظمة دائمًا بشكل مستمر على مدى عدة أشهر.', 'hi': 'अगर आपके पीरियड 21 दिनों से कम अंतराल पर, 45 दिनों से ज़्यादा अंतराल पर आते हैं, या अचानक 90 दिनों से ज़्यादा बिना पीरियड के बीत जाते हैं, तो किसी स्वास्थ्य विशेषज्ञ से बात करने का अच्छा समय है। यही तब भी लागू होता है जब हमेशा नियमित रहा चक्र कई महीनों तक लगातार बदलता रहे।', 'bn': 'আপনার পিরিয়ড যদি ২১ দিনের কম ব্যবধানে, ৪৫ দিনের বেশি ব্যবধানে আসে, বা হঠাৎ ৯০ দিনের বেশি পিরিয়ড ছাড়া কেটে যায়, তাহলে একজন স্বাস্থ্য বিশেষজ্ঞের সাথে কথা বলার ভালো সময়। একইভাবে যদি সবসময় নিয়মিত থাকা কোনো চক্র কয়েক মাস ধরে ক্রমাগত বদলাতে থাকে।', 'pt': 'Se seus períodos vêm com menos de 21 dias de intervalo, mais de 45 dias, ou se de repente passam mais de 90 dias sem período, é um bom momento para conversar com um profissional de saúde. O mesmo vale se um ciclo que sempre foi regular muda de forma constante ao longo de vários meses.',
      });

  String get eduLutealPhaseTitle => _t({
        'es': '¿Qué significa la "fase lútea"?',
        'en': 'What does the "luteal phase" mean?',
        'fr': "Que signifie la « phase lutéale » ?",
        'de': 'Was bedeutet „Lutealphase"?',
        'ru': 'Что означает «лютеиновая фаза»?',
        'ar': 'ماذا تعني "المرحلة الأصفرية"؟', 'hi': '"ल्यूटियल फेज़" का क्या मतलब है?', 'bn': '"লুটিয়াল ফেজ" মানে কী?', 'pt': 'O que significa a "fase lútea"?',
      });
  String get eduLutealPhaseBody => _t({
        'es':
            'Es el tramo entre la ovulación y el siguiente periodo, y suele durar entre 11 y 17 días, bastante más estable que la primera mitad del ciclo. Si a ti te varía mucho justo esa fase, puede ser útil comentarlo con tu médico.',
        'en':
            "It's the stretch between ovulation and the next period, and it usually lasts between 11 and 17 days — noticeably more stable than the first half of the cycle. If that phase varies a lot for you, it may be worth mentioning to your doctor.",
        'fr':
            "C'est la période entre l'ovulation et les règles suivantes, et elle dure généralement entre 11 et 17 jours, nettement plus stable que la première moitié du cycle. Si cette phase varie beaucoup chez vous, il peut être utile d'en parler à votre médecin.",
        'de':
            'Das ist die Zeitspanne zwischen dem Eisprung und der nächsten Periode, die meist 11 bis 17 Tage dauert — deutlich stabiler als die erste Zyklushälfte. Wenn diese Phase bei dir stark schwankt, kann es sinnvoll sein, das mit deiner Ärztin oder deinem Arzt zu besprechen.',
        'ru': 'Это промежуток между овуляцией и следующей менструацией, который обычно длится от 11 до 17 дней — значительно стабильнее, чем первая половина цикла. Если именно эта фаза сильно меняется у тебя, стоит обсудить это с врачом.',
        'ar': 'هي الفترة بين الإباضة والدورة التالية، وتستمر عادةً بين 11 و17 يومًا — وهي أكثر ثباتًا بكثير من النصف الأول من الدورة. إذا كانت هذه المرحلة تتفاوت كثيرًا لديكِ، فقد يكون من المفيد ذكر ذلك لطبيبتك.', 'hi': 'यह ओव्यूलेशन और अगले पीरियड के बीच का समय है, जो आमतौर पर 11 से 17 दिनों तक चलता है और चक्र के पहले हिस्से से काफी ज़्यादा स्थिर होता है। अगर आपके लिए यह चरण बहुत ज़्यादा बदलता है, तो अपने डॉक्टर से इस बारे में बात करना अच्छा रहेगा।', 'bn': 'এটি ডিম্বস্ফোটন এবং পরবর্তী পিরিয়ডের মধ্যবর্তী সময়, যা সাধারণত ১১ থেকে ১৭ দিন স্থায়ী হয় এবং চক্রের প্রথমার্ধের চেয়ে অনেক বেশি স্থিতিশীল। যদি এই পর্যায়টি আপনার ক্ষেত্রে অনেক পরিবর্তিত হয়, তবে আপনার ডাক্তারের সাথে এটি নিয়ে কথা বলা ভালো হতে পারে।', 'pt': 'É o período entre a ovulação e o próximo período, que geralmente dura entre 11 e 17 dias, bem mais estável que a primeira metade do ciclo. Se essa fase variar muito no seu caso, pode ser útil comentar com seu médico.',
      });

  // ---- Tarjeta de cambio térmico ----
  String get thermalShiftTitle => _t({'es': '🌡️ Cambio térmico', 'en': '🌡️ Thermal shift', 'fr': '🌡️ Décalage thermique', 'de': '🌡️ Temperaturanstieg', 'ru': '🌡️ Термический сдвиг', 'ar': '🌡️ التحول الحراري', 'hi': '🌡️ तापमान में बदलाव', 'bn': '🌡️ তাপমাত্রার পরিবর্তন', 'pt': '🌡️ Mudança térmica',});
  String get thermalShiftDetectedTitle =>
      _t({'es': '🌡️ Cambio térmico detectado', 'en': '🌡️ Thermal shift detected', 'fr': '🌡️ Décalage thermique détecté', 'de': '🌡️ Temperaturanstieg erkannt', 'ru': '🌡️ Обнаружен термический сдвиг', 'ar': '🌡️ تم رصد تحول حراري', 'hi': '🌡️ तापमान में बदलाव पाया गया', 'bn': '🌡️ তাপমাত্রার পরিবর্তন শনাক্ত হয়েছে', 'pt': '🌡️ Mudança térmica detectada',});
  String thermalShiftTrackMore(int count) => _t({
        'es':
            'Registra tu temperatura basal todos los días (llevas $count este ciclo) para detectar el cambio térmico que indica que ya ovulaste.',
        'en':
            "Log your basal temperature every day (you've logged $count this cycle) to detect the thermal shift that shows ovulation has occurred.",
        'fr':
            "Enregistrez votre température basale tous les jours (vous en avez $count ce cycle) pour détecter le décalage thermique indiquant que l'ovulation a eu lieu.",
        'de':
            'Miss deine Basaltemperatur jeden Tag (bisher $count in diesem Zyklus), um den Temperaturanstieg zu erkennen, der zeigt, dass der Eisprung bereits stattgefunden hat.',
        'ru': 'Отмечай свою базальную температуру каждый день (в этом цикле у тебя $count) чтобы обнаружить термический сдвиг, который указывает, что овуляция уже произошла.',
        'ar': 'سجّلي درجة حرارتك الأساسية كل يوم (لديكِ $count في هذه الدورة) لرصد التحول الحراري الذي يشير إلى حدوث الإباضة بالفعل.', 'hi': 'ओव्यूलेशन हो चुकने का संकेत देने वाला तापमान बदलाव पहचानने के लिए हर दिन अपना बेसल तापमान दर्ज करें (इस चक्र में आपने अब तक $count बार दर्ज किया है)।', 'bn': 'ডিম্বস্ফোটন হয়ে গেছে তা বোঝানো তাপমাত্রার পরিবর্তন শনাক্ত করতে প্রতিদিন আপনার বেসাল তাপমাত্রা লগ করুন (এই চক্রে আপনি এখন পর্যন্ত $count বার লগ করেছেন)।', 'pt': 'Registre sua temperatura basal todos os dias (você já registrou $count vezes neste ciclo) para detectar a mudança térmica que indica que a ovulação já ocorreu.',
      });
  String thermalShiftConfirmed(String dateLabel) => _t({
        'es': 'Confirmado el $dateLabel. Esto sugiere que la ovulación ya ocurrió en este ciclo.',
        'en': 'Confirmed on $dateLabel. This suggests ovulation has already occurred this cycle.',
        'fr': "Confirmé le $dateLabel. Cela suggère que l'ovulation a déjà eu lieu ce cycle.",
        'de': 'Bestätigt am $dateLabel. Das deutet darauf hin, dass der Eisprung in diesem Zyklus bereits stattgefunden hat.',
        'ru': 'Подтверждено $dateLabel. Это говорит о том, что овуляция уже произошла в этом цикле.',
        'ar': 'تم التأكيد في $dateLabel. يشير هذا إلى أن الإباضة قد حدثت بالفعل في هذه الدورة.', 'hi': '$dateLabel को पुष्टि हुई। इससे पता चलता है कि इस चक्र में ओव्यूलेशन हो चुका है।', 'bn': '$dateLabel তারিখে নিশ্চিত হয়েছে। এটি বোঝায় যে এই চক্রে ডিম্বস্ফোটন ইতিমধ্যে ঘটে গেছে।', 'pt': 'Confirmado em $dateLabel. Isso sugere que a ovulação já ocorreu neste ciclo.',
      });
  String get thermalShiftNotDetected => _t({
        'es': 'Aún no se detecta un cambio térmico claro este ciclo con los datos registrados.',
        'en': "No clear thermal shift has been detected yet this cycle with the data logged so far.",
        'fr': "Aucun décalage thermique clair n'est encore détecté ce cycle avec les données enregistrées.",
        'de': 'Mit den bisher erfassten Daten wurde in diesem Zyklus noch kein klarer Temperaturanstieg erkannt.',
        'ru': 'Пока в этом цикле не обнаружен явный термический сдвиг по имеющимся данным.',
        'ar': 'لم يُرصد بعد تحول حراري واضح في هذه الدورة بناءً على البيانات المسجّلة.', 'hi': 'दर्ज किए गए डेटा के आधार पर इस चक्र में अभी तक कोई स्पष्ट तापमान बदलाव नहीं दिखा है।', 'bn': 'লগ করা তথ্য অনুযায়ী এই চক্রে এখনও কোনো স্পষ্ট তাপমাত্রার পরিবর্তন শনাক্ত হয়নি।', 'pt': 'Ainda não foi detectada uma mudança térmica clara neste ciclo com os dados registrados.',
      });
  String get thermalShiftDisclaimer => _t({
        'es':
            'Esto es solo informativo, basado en una simplificación de métodos sintotérmicos. No lo uses como único método para evitar o buscar un embarazo, ni reemplaza el consejo de un profesional de salud.',
        'en':
            "This is for informational purposes only, based on a simplified version of symptothermal methods. Don't rely on it as your only method to avoid or achieve pregnancy, and it doesn't replace advice from a healthcare professional.",
        'fr':
            "Ceci est donné à titre informatif uniquement, basé sur une simplification des méthodes symptothermiques. Ne l'utilisez pas comme seule méthode pour éviter ou rechercher une grossesse, et cela ne remplace pas l'avis d'un professionnel de santé.",
        'de':
            'Dies dient nur zur Information und basiert auf einer vereinfachten symptothermalen Methode. Verwende es nicht als einzige Methode, um eine Schwangerschaft zu vermeiden oder zu erreichen, und es ersetzt nicht den Rat einer Fachperson im Gesundheitswesen.',
        'ru': 'Это только информация, основанная на упрощении симптотермальных методов. Не используй это как единственный метод для предотвращения или достижения беременности, и это не заменяет консультацию специалиста здравоохранения.',
        'ar': 'هذه معلومات إرشادية فقط، تستند إلى تبسيط للطرق العرضية الحرارية. لا تعتمدي عليها كوسيلة وحيدة لتجنب الحمل أو تحقيقه، وهي لا تغني عن استشارة أخصائي رعاية صحية.', 'hi': 'यह जानकारी केवल सूचना के लिए है और सिम्प्टोथर्मल तरीकों के एक सरल रूप पर आधारित है। गर्भधारण से बचने या गर्भधारण की कोशिश के लिए इसे एकमात्र तरीका न मानें, और यह किसी स्वास्थ्य विशेषज्ञ की सलाह की जगह नहीं ले सकता।', 'bn': 'এটি শুধুমাত্র তথ্যগত উদ্দেশ্যে, সিম্পটোথার্মাল পদ্ধতির একটি সরলীকৃত সংস্করণের ভিত্তিতে তৈরি। গর্ভধারণ এড়াতে বা গর্ভধারণের চেষ্টা করতে এটিকে একমাত্র পদ্ধতি হিসেবে ব্যবহার করবেন না, এবং এটি কোনো স্বাস্থ্য বিশেষজ্ঞের পরামর্শের বিকল্প নয়।', 'pt': 'Isso é apenas informativo, baseado em uma simplificação dos métodos sintotérmicos. Não use como único método para evitar ou buscar uma gravidez, e não substitui o conselho de um profissional de saúde.',
      });

  // ==================== timeline_screen.dart ====================

  String get timelineTitle => _t({'es': 'Línea de tiempo', 'en': 'Timeline', 'fr': 'Chronologie', 'de': 'Zeitleiste', 'ru': 'Хронология', 'ar': 'الجدول الزمني', 'hi': 'टाइमलाइन', 'bn': 'টাইমলাইন', 'pt': 'Linha do tempo',});
  String get timelineSearchHint =>
      _t({'es': '🔎 Buscar en tu diario...', 'en': '🔎 Search your diary...', 'fr': '🔎 Rechercher dans votre journal...', 'de': '🔎 Im Tagebuch suchen...', 'ru': '🔎 Искать в дневнике...', 'ar': '🔎 البحث في يومياتك...', 'hi': '🔎 अपनी डायरी में खोजें...', 'bn': '🔎 আপনার ডায়েরিতে খুঁজুন...', 'pt': '🔎 Buscar no seu diário...',});
  String get timelineNoResults => _t({
        'es': 'No encontré nada con esa búsqueda.',
        'en': "I couldn't find anything for that search.",
        'fr': "Je n'ai rien trouvé pour cette recherche.",
        'de': 'Für diese Suche wurde nichts gefunden.',
        'ru': 'Ничего не найдено по этому запросу.',
        'ar': 'لم يتم العثور على شيء لهذا البحث.', 'hi': 'इस खोज के लिए कुछ नहीं मिला।', 'bn': 'এই অনুসন্ধানের জন্য কিছু পাওয়া যায়নি।', 'pt': 'Não encontrei nada para essa busca.',
      });
  String get timelineEmpty => _t({
        'es': 'Aún no hay registros. Toca un día del calendario para empezar.',
        'en': 'No entries yet. Tap a day on the calendar to get started.',
        'fr': "Pas encore d'entrées. Touchez un jour du calendrier pour commencer.",
        'de': 'Noch keine Einträge. Tippe auf einen Tag im Kalender, um zu beginnen.',
        'ru': 'Пока нет записей. Нажми на день в календаре, чтобы начать.',
        'ar': 'لا توجد سجلات بعد. اضغطي على يوم في التقويم للبدء.', 'hi': 'अभी तक कोई रिकॉर्ड नहीं है। शुरू करने के लिए कैलेंडर में कोई दिन चुनें।', 'bn': 'এখনো কোনো রেকর্ড নেই। শুরু করতে ক্যালেন্ডারের একটি দিনে ট্যাপ করুন।', 'pt': 'Ainda não há registros. Toque em um dia do calendário para começar.',
      });
  String get timelineSexTag => _t({'es': 'Relación sexual', 'en': 'Sex', 'fr': 'Rapport sexuel', 'de': 'Geschlechtsverkehr', 'ru': 'Половой акт', 'ar': 'علاقة حميمة', 'hi': 'यौन संबंध', 'bn': 'যৌন সম্পর্ক', 'pt': 'Relação sexual',});
  String get timelinePhotoTag => _t({'es': '📷 Foto', 'en': '📷 Photo', 'fr': '📷 Photo', 'de': '📷 Foto', 'ru': '📷 Фото', 'ar': '📷 صورة', 'hi': '📷 फोटो', 'bn': '📷 ছবি', 'pt': '📷 Foto',});
  String get timelineNoDetails => _t({'es': 'Sin detalles', 'en': 'No details', 'fr': 'Aucun détail', 'de': 'Keine Details', 'ru': 'Без деталей', 'ar': 'بدون تفاصيل', 'hi': 'कोई विवरण नहीं', 'bn': 'কোনো বিস্তারিত নেই', 'pt': 'Sem detalhes',});
  String timelineGlasses(int n) => _t({'es': '$n vasos', 'en': '$n glasses', 'fr': '$n verres', 'de': '$n Gläser', 'ru': '$n стаканов', 'ar': '$n أكواب', 'hi': '$n गिलास', 'bn': '$n গ্লাস', 'pt': '$n copos',});

  // ==================== calendar_grid.dart ====================
  // (usa monthName y weekdayInitialsList ya definidos arriba)

  // ---- Rediseño de calendario (v0 -> Flutter): píldoras mes/año, botón
  // "Hoy", marcador de inicio de período y botones inferiores. ----

  /// Botón que centra el calendario en el día actual (píldora rosa).
  String get calendarTodayButton => _t({'es': 'Hoy', 'en': 'Today', 'fr': "Aujourd'hui", 'de': 'Heute', 'ru': 'Сегодня', 'ar': 'اليوم', 'hi': 'आज', 'bn': 'আজ', 'pt': 'Hoje',});

  /// Etiqueta manuscrita junto al círculo dibujado a mano que marca el
  /// primer día de un período registrado.
  String get calendarPeriodStartLabel =>
      _t({'es': 'Inicio de la regla', 'en': 'Period starts', 'fr': 'Début des règles', 'de': 'Periodenbeginn', 'ru': 'Начало менструации', 'ar': 'بداية الدورة', 'hi': 'माहवारी की शुरुआत', 'bn': 'মাসিকের শুরু', 'pt': 'Início da menstruação',});

  /// Botón "Editar período" (píldora rosa) debajo de la leyenda.
  String get calendarEditPeriod =>
      _t({'es': 'Editar período', 'en': 'Edit period', 'fr': 'Modifier les règles', 'de': 'Periode bearbeiten', 'ru': 'Редактировать менструацию', 'ar': 'تعديل الدورة', 'hi': 'पीरियड संपादित करें', 'bn': 'পিরিয়ড সম্পাদনা করুন', 'pt': 'Editar período',});

  /// Botón "Notas" (píldora lavanda) debajo de la leyenda.
  String get calendarNotes => _t({'es': 'Notas', 'en': 'Notes', 'fr': 'Notes', 'de': 'Notizen', 'ru': 'Заметки', 'ar': 'ملاحظات', 'hi': 'नोट्स', 'bn': 'নোট', 'pt': 'Notas',});

  // ---- Menú contextual al tocar un día del calendario: 3 variantes según
  // el estado del día (borde final de período / dentro del período / sin
  // relación), todas comparten "Notas", "Leyenda" y "Cancelar". ----

  /// Opción para extender el período un día más allá del último día
  /// registrado (solo aparece si el día tocado es justo el siguiente al
  /// último día de flujo registrado).
  String get calendarExtendPeriod =>
      _t({'es': 'Prolongar período', 'en': 'Extend period', 'fr': 'Prolonger les règles', 'de': 'Periode verlängern', 'ru': 'Продлить менструацию', 'ar': 'تمديد الدورة', 'hi': 'पीरियड बढ़ाएं', 'bn': 'পিরিয়ড দীর্ঘায়িত করুন', 'pt': 'Prolongar período',});

  /// Quita el flujo solo del día tocado (día intermedio del período), sin
  /// afectar los días antes ni después. Texto explícito para no
  /// confundirse con "Fin del período aquí" (que sí corta el resto de la
  /// racha).
  String get calendarRemovePeriodDay => _t({
        'es': 'Quitar solo este día',
        'en': 'Remove just this day',
        'fr': 'Retirer seulement ce jour',
        'de': 'Nur diesen Tag entfernen',
        'ru': 'Убрать только этот день',
        'ar': 'إزالة هذا اليوم فقط', 'hi': 'सिर्फ यह दिन हटाएं', 'bn': 'শুধু এই দিনটি সরান', 'pt': 'Remover apenas este dia',
      });

  /// Corta el período en el día tocado: ese día y los posteriores ya
  /// registrados dejan de contar como período. Texto explícito ("...aquí")
  /// para diferenciarlo claramente de "Quitar solo este día".
  String get calendarEndPeriodHere => _t({
        'es': 'Terminar período aquí',
        'en': 'End period here',
        'fr': 'Terminer les règles ici',
        'de': 'Periode hier beenden',
        'ru': 'Закончить менструацию здесь',
        'ar': 'إنهاء الدورة هنا', 'hi': 'पीरियड यहां खत्म करें', 'bn': 'এখানে পিরিয়ড শেষ করুন', 'pt': 'Terminar período aqui',
      });

  /// Título del bottom sheet de leyenda (mismo contenido que la leyenda de
  /// 3 categorías bajo el calendario, mostrado como hoja modal).
  String get calendarLegendTitle => _t({'es': 'Leyenda', 'en': 'Legend', 'fr': 'Légende', 'de': 'Legende', 'ru': 'Легенда', 'ar': 'وسيلة الإيضاح', 'hi': 'लेजेंड', 'bn': 'লেজেন্ড', 'pt': 'Legenda',});

  /// Opción "Leyenda" del menú contextual de un día.
  String get calendarLegendOption => _t({'es': 'Leyenda', 'en': 'Legend', 'fr': 'Légende', 'de': 'Legende', 'ru': 'Легенда', 'ar': 'وسيلة الإيضاح', 'hi': 'लेजेंड', 'bn': 'লেজেন্ড', 'pt': 'Legenda',});

  /// Opción "Cancelar" del menú contextual de un día.
  String get calendarCancelOption => _t({'es': 'Cancelar', 'en': 'Cancel', 'fr': 'Annuler', 'de': 'Abbrechen', 'ru': 'Отмена', 'ar': 'إلغاء', 'hi': 'रद्द करें', 'bn': 'বাতিল করুন', 'pt': 'Cancelar',});

  // ---- Panel "Leyenda" rediseñado: tarjetas con icono + switch por
  // categoría, agrupadas. Cada switch decide si esa categoría se pinta en
  // el calendario — pensado para privacidad (poder mostrarle el calendario
  // a alguien ocultando antes lo que no se quiere compartir). ----

  /// Subtítulo bajo el título "Leyenda", explica para qué sirven los
  /// switches (privacidad al compartir el calendario con alguien más).
  String get calendarLegendPrivacySubtitle => _t({
        'es': 'Elige qué se muestra en el calendario. Útil si vas a enseñárselo a alguien.',
        'en': 'Choose what shows on the calendar. Useful if you\'re going to show it to someone.',
        'fr': 'Choisis ce qui s\'affiche sur le calendrier. Utile si tu vas le montrer à quelqu\'un.',
        'de': 'Wähle, was im Kalender angezeigt wird. Nützlich, wenn du ihn jemandem zeigen möchtest.',
        'ru': 'Выбери, что показывать в календаре. Полезно, если собираешься кому-то его показать.',
        'ar': 'اختاري ما يظهر في التقويم. مفيد إذا كنتِ ستعرضينه لشخص آخر.', 'hi': 'चुनें कि कैलेंडर में क्या दिखाया जाए। यह तब उपयोगी है जब आप इसे किसी को दिखाने वाले हों।', 'bn': 'ক্যালেন্ডারে কী দেখানো হবে তা বেছে নিন। কাউকে দেখানোর সময় এটি কাজে লাগে।', 'pt': 'Escolha o que aparece no calendário. Útil se você for mostrá-lo para alguém.',
      });

  /// Contador "X de Y activas" mostrado junto al título.
  String calendarLegendActiveCount(int active, int total) => _t({
        'es': '$active de $total activas',
        'en': '$active of $total on',
        'fr': '$active sur $total actives',
        'de': '$active von $total aktiv',
        'ru': '$active из $total включены',
        'ar': '$active من $total مفعّلة', 'hi': '$total में से $active सक्रिय', 'bn': '$total এর মধ্যে $active সক্রিয়', 'pt': '$active de $total ativas',
      });

  String get calendarLegendGroupCycle => _t({'es': 'Ciclo', 'en': 'Cycle', 'fr': 'Cycle', 'de': 'Zyklus', 'ru': 'Цикл', 'ar': 'الدورة', 'hi': 'चक्र', 'bn': 'চক্র', 'pt': 'Ciclo',});

  String get calendarLegendGroupSex =>
      _t({'es': 'Vida sexual', 'en': 'Sex life', 'fr': 'Vie sexuelle', 'de': 'Sexualleben', 'ru': 'Интимная жизнь', 'ar': 'الحياة الجنسية', 'hi': 'यौन जीवन', 'bn': 'যৌন জীবন', 'pt': 'Vida sexual',});

  String get calendarLegendGroupMethod =>
      _t({'es': 'Método anticonceptivo', 'en': 'Birth control', 'fr': 'Contraception', 'de': 'Verhütung', 'ru': 'Метод контрацепции', 'ar': 'وسيلة منع الحمل', 'hi': 'गर्भनिरोधक तरीका', 'bn': 'জন্মনিয়ন্ত্রণ পদ্ধতি', 'pt': 'Método anticoncepcional',});

  String get calendarLegendGroupOther => _t({'es': 'Otros', 'en': 'Other', 'fr': 'Autres', 'de': 'Sonstiges', 'ru': 'Другое', 'ar': 'أخرى', 'hi': 'अन्य', 'bn': 'অন্যান্য', 'pt': 'Outros',});

  String get calendarLegendCatPeriod => _t({'es': 'Periodo', 'en': 'Period', 'fr': 'Règles', 'de': 'Periode', 'ru': 'Менструация', 'ar': 'الدورة', 'hi': 'पीरियड', 'bn': 'পিরিয়ড', 'pt': 'Período',});

  String get calendarLegendCatPredicted =>
      _t({'es': 'Previsto', 'en': 'Predicted', 'fr': 'Prévu', 'de': 'Vorhergesagt', 'ru': 'Прогноз', 'ar': 'متوقع', 'hi': 'अनुमानित', 'bn': 'প্রত্যাশিত', 'pt': 'Previsto',});

  String get calendarLegendCatFertile => _t({'es': 'Fértil', 'en': 'Fertile', 'fr': 'Fertile', 'de': 'Fruchtbar', 'ru': 'Фертильный', 'ar': 'خصوبة', 'hi': 'उपजाऊ', 'bn': 'উর্বর', 'pt': 'Fértil',});

  String get calendarLegendCatSexUnprotected => _t({
        'es': 'Sexo sin protección',
        'en': 'Unprotected sex',
        'fr': 'Rapport non protégé',
        'de': 'Ungeschützter Sex',
        'ru': 'Секс без защиты',
        'ar': 'جنس بدون حماية', 'hi': 'बिना सुरक्षा के सेक्स', 'bn': 'সুরক্ষা ছাড়া যৌনতা', 'pt': 'Sexo sem proteção',
      });

  String get calendarLegendCatSexProtected =>
      _t({'es': 'Sexo protegido', 'en': 'Protected sex', 'fr': 'Rapport protégé', 'de': 'Geschützter Sex', 'ru': 'Защищённый секс', 'ar': 'جنس محمي', 'hi': 'सुरक्षित सेक्स', 'bn': 'সুরক্ষিত যৌনতা', 'pt': 'Sexo protegido',});

  String get calendarLegendCatMasturbation =>
      _t({'es': 'Masturbación', 'en': 'Masturbation', 'fr': 'Masturbation', 'de': 'Masturbation', 'ru': 'Мастурбация', 'ar': 'الاستمناء', 'hi': 'हस्तमैथुन', 'bn': 'হস্তমৈথুন', 'pt': 'Masturbação',});

  String get calendarLegendCatPill => _t({'es': 'Pastilla', 'en': 'Pill', 'fr': 'Pilule', 'de': 'Pille', 'ru': 'Таблетка', 'ar': 'حبوب منع الحمل', 'hi': 'गोली', 'bn': 'পিল', 'pt': 'Pílula',});

  String get calendarLegendCatDiu => _t({'es': 'DIU', 'en': 'IUD', 'fr': 'DIU', 'de': 'Spirale', 'ru': 'ВМС', 'ar': 'اللولب', 'hi': 'आईयूडी', 'bn': 'আইইউডি', 'pt': 'DIU',});

  String get calendarLegendCatMoodSymptoms => _t({
        'es': 'Síntomas y estado de ánimo',
        'en': 'Symptoms and mood',
        'fr': 'Symptômes et humeur',
        'de': 'Symptome und Stimmung',
        'ru': 'Симптомы и настроение',
        'ar': 'الأعراض والمزاج', 'hi': 'लक्षण और मूड', 'bn': 'লক্ষণ ও মেজাজ', 'pt': 'Sintomas e humor',
      });

  String get calendarLegendCatNote => _t({'es': 'Nota', 'en': 'Note', 'fr': 'Note', 'de': 'Notiz', 'ru': 'Заметка', 'ar': 'ملاحظة', 'hi': 'नोट', 'bn': 'নোট', 'pt': 'Nota',});
  // Texto del "atajo" bajo Editar período/Notas cuando el día seleccionado
  // no tiene ningún dato registrado todavía (ver
  // CalendarScreen._buildDaySummary) — tocarlo abre "Notas" igual que los
  // chips de resumen.
  String get calendarDaySummaryEmpty => _t({
        'es': 'Sin registros este día. Toca para añadir uno.',
        'en': 'No records for this day. Tap to add one.',
        'fr': 'Aucune donnée ce jour-là. Touchez pour en ajouter une.',
        'de': 'Keine Einträge an diesem Tag. Tippen, um einen hinzuzufügen.',
        'ru': 'Нет записей за этот день. Нажмите, чтобы добавить.',
        'ar': 'لا توجد بيانات لهذا اليوم. اضغطي للإضافة.',
        'hi': 'इस दिन कोई रिकॉर्ड नहीं है। जोड़ने के लिए टैप करें।',
        'bn': 'এই দিনের কোনো তথ্য নেই। যোগ করতে ট্যাপ করুন।',
        'pt': 'Nenhum registro neste dia. Toque para adicionar um.',
      });

  // Título de la hoja del botón "i" entre "Editar período" y "Notas"
  // (calendar_screen.dart, _showDayInfoSheet).
  String get calendarDayInfoTitle => _t({
        'es': 'Información del día',
        'en': 'Day information',
        'fr': 'Informations du jour',
        'de': 'Informationen zum Tag',
        'ru': 'Информация о дне',
        'ar': 'معلومات اليوم',
        'hi': 'दिन की जानकारी',
        'bn': 'দিনের তথ্য',
        'pt': 'Informações do dia',
      });

  // ==================== period_editor_screen.dart ====================
  // Pantalla nueva "Editar período" portada del diseño v0 (components/
  // period-editor.tsx): banner rosa + grid de meses en scroll continuo con
  // círculos tocables + botón GUARDAR fijo abajo.

  /// Banner de instrucción con ícono de gota, arriba del grid de meses.
  String get periodEditorInstruction => _t({
        'es': 'Toca la fecha para ajustar tu período',
        'en': 'Tap a date to adjust your period',
        'fr': 'Touchez une date pour ajuster vos règles',
        'de': 'Tippe auf ein Datum, um deine Periode anzupassen',
        'ru': 'Нажми на дату, чтобы изменить свою менструацию',
        'ar': 'اضغطي على التاريخ لتعديل دورتك', 'hi': 'अपना पीरियड ठीक करने के लिए तारीख पर टैप करें', 'bn': 'আপনার পিরিয়ড ঠিক করতে তারিখে ট্যাপ করুন', 'pt': 'Toque na data para ajustar seu período',
      });

  /// Etiqueta "HOY" sobre el número del día actual.
  String get periodEditorTodayLabel => _t({'es': 'HOY', 'en': 'TODAY', 'fr': "AUJOURD'HUI", 'de': 'HEUTE', 'ru': 'СЕГОДНЯ', 'ar': 'اليوم', 'hi': 'आज', 'bn': 'আজ', 'pt': 'HOJE',});

  /// Botón fijo abajo para guardar los cambios y cerrar la pantalla.
  String get periodEditorSave => _t({'es': 'GUARDAR', 'en': 'SAVE', 'fr': 'ENREGISTRER', 'de': 'SPEICHERN', 'ru': 'СОХРАНИТЬ', 'ar': 'حفظ', 'hi': 'सेव करें', 'bn': 'সংরক্ষণ করুন', 'pt': 'SALVAR',});

  /// Etiqueta de accesibilidad del botón X para cerrar sin guardar.
  String get periodEditorCloseA11y =>
      _t({'es': 'Cerrar', 'en': 'Close', 'fr': 'Fermer', 'de': 'Schließen', 'ru': 'Закрыть', 'ar': 'إغلاق', 'hi': 'बंद करें', 'bn': 'বন্ধ করুন', 'pt': 'Fechar',});

  /// Iniciales de días de la semana empezando en lunes (L M X J V S D),
  /// tal como pide el diseño aprobado — distinto de `weekdayInitialsList`
  /// (que empieza en domingo y sigue usándose para el offset del grid).
  List<String> get weekdayInitialsMondayFirstList {
    final sundayFirst = weekdayInitialsList;
    if (sundayFirst.length != 7) return sundayFirst;
    return [...sundayFirst.sublist(1), sundayFirst.first];
  }

  // ==================== lock_screen.dart ====================

  String get lockCreatePin => _t({'es': 'Crea un PIN de 4 dígitos', 'en': 'Create a 4-digit PIN', 'fr': 'Créez un code à 4 chiffres', 'de': 'Erstelle eine 4-stellige PIN', 'ru': 'Создай 4-значный PIN-код', 'ar': 'أنشئي رمز PIN من 4 أرقام', 'hi': '4 अंकों का पिन बनाएं', 'bn': '৪ সংখ্যার পিন তৈরি করুন', 'pt': 'Crie um PIN de 4 dígitos',});
  String get lockConfirmPin => _t({'es': 'Confirma tu PIN', 'en': 'Confirm your PIN', 'fr': 'Confirmez votre code', 'de': 'Bestätige deine PIN', 'ru': 'Подтверди свой PIN-код', 'ar': 'أكدي رمز PIN الخاص بك', 'hi': 'अपना पिन कन्फर्म करें', 'bn': 'আপনার পিন নিশ্চিত করুন', 'pt': 'Confirme seu PIN',});
  String get lockEnterPin => _t({'es': 'Ingresa tu PIN', 'en': 'Enter your PIN', 'fr': 'Entrez votre code', 'de': 'Gib deine PIN ein', 'ru': 'Введи свой PIN-код', 'ar': 'أدخلي رمز PIN الخاص بك', 'hi': 'अपना पिन डालें', 'bn': 'আপনার পিন লিখুন', 'pt': 'Digite seu PIN',});
  String get lockPinMismatch => _t({
        'es': 'Los PIN no coinciden, intenta de nuevo',
        'en': "The PINs don't match, try again",
        'fr': 'Les codes ne correspondent pas, réessayez',
        'de': 'Die PINs stimmen nicht überein, versuch es erneut',
        'ru': 'PIN-коды не совпадают, попробуй ещё раз',
        'ar': 'رمزا PIN غير متطابقين، حاولي مرة أخرى',
        'hi': 'पिन मेल नहीं खा रहे हैं, फिर से कोशिश करें',
        'bn': 'পিন মিলছে না, আবার চেষ্টা করুন',
        'pt': 'Os PINs não coincidem, tente novamente',
      });
  String get lockPinIncorrect => _t({'es': 'PIN incorrecto', 'en': 'Incorrect PIN', 'fr': 'Code incorrect', 'de': 'Falsche PIN', 'ru': 'Неверный PIN-код', 'ar': 'رمز PIN غير صحيح', 'hi': 'गलत पिन', 'bn': 'ভুল পিন', 'pt': 'PIN incorreto'});
  String get lockAppLocked =>
      _t({'es': 'CicloPlus está bloqueado', 'en': 'CicloPlus is locked', 'fr': 'CicloPlus est verrouillé', 'de': 'CicloPlus ist gesperrt', 'ru': 'CicloPlus заблокирован', 'ar': 'تطبيق CicloPlus مقفل', 'hi': 'CicloPlus लॉक है', 'bn': 'CicloPlus লক করা আছে', 'pt': 'O CicloPlus está bloqueado'});

  // ==================== auth_screen.dart ====================

  String get authCreateAccount => _t({'es': 'Crea tu cuenta gratis', 'en': 'Create your free account', 'fr': 'Créez votre compte gratuit', 'de': 'Erstelle dein kostenloses Konto', 'ru': 'Создай бесплатный аккаунт', 'ar': 'أنشئي حسابك المجاني', 'hi': 'अपना मुफ़्त खाता बनाएं', 'bn': 'আপনার ফ্রি অ্যাকাউন্ট তৈরি করুন', 'pt': 'Crie sua conta grátis'});
  String get authSignIn => _t({'es': 'Inicia sesión', 'en': 'Sign in', 'fr': 'Connectez-vous', 'de': 'Anmelden', 'ru': 'Войти', 'ar': 'تسجيل الدخول', 'hi': 'साइन इन करें', 'bn': 'সাইন ইন করুন', 'pt': 'Entrar'});
  String get authEmailLabel => _t({'es': 'Correo electrónico', 'en': 'Email', 'fr': 'E-mail', 'de': 'E-Mail', 'ru': 'Электронная почта', 'ar': 'البريد الإلكتروني', 'hi': 'ईमेल', 'bn': 'ইমেইল', 'pt': 'E-mail'});
  String get authEmailHint => _t({'es': 'tucorreo@ejemplo.com', 'en': 'youremail@example.com', 'fr': 'votremail@exemple.com', 'de': 'deine.email@beispiel.com', 'ru': 'tucorreo@ejemplo.com', 'ar': 'youremail@example.com', 'hi': 'youremail@example.com', 'bn': 'youremail@example.com', 'pt': 'seuemail@exemplo.com'});
  String get authEmailRequired => _t({'es': 'Escribe tu correo.', 'en': 'Enter your email.', 'fr': 'Saisissez votre e-mail.', 'de': 'Gib deine E-Mail-Adresse ein.', 'ru': 'Введи свою почту.', 'ar': 'أدخلي بريدك الإلكتروني.', 'hi': 'अपना ईमेल दर्ज करें।', 'bn': 'আপনার ইমেইল লিখুন।', 'pt': 'Digite seu e-mail.'});
  String get authNameRequired =>
      _t({'es': 'Escribe tu nombre.', 'en': 'Enter your name.', 'fr': 'Saisissez votre prénom.', 'de': 'Gib deinen Namen ein.', 'ru': 'Введи своё имя.', 'ar': 'أدخلي اسمك.', 'hi': 'अपना नाम दर्ज करें।', 'bn': 'আপনার নাম লিখুন।', 'pt': 'Digite seu nome.'});
  String get authPasswordLabel => _t({'es': 'Contraseña', 'en': 'Password', 'fr': 'Mot de passe', 'de': 'Passwort', 'ru': 'Пароль', 'ar': 'كلمة المرور', 'hi': 'पासवर्ड', 'bn': 'পাসওয়ার্ড', 'pt': 'Senha'});
  String get authPasswordHint =>
      _t({'es': 'Mínimo 6 caracteres', 'en': 'At least 6 characters', 'fr': 'Minimum 6 caractères', 'de': 'Mindestens 6 Zeichen', 'ru': 'Минимум 6 символов', 'ar': '6 أحرف على الأقل', 'hi': 'कम से कम 6 अक्षर', 'bn': 'ন্যূনতম ৬টি অক্ষর', 'pt': 'Mínimo de 6 caracteres',});
  String get authPasswordRequired =>
      _t({'es': 'Escribe tu contraseña.', 'en': 'Enter your password.', 'fr': 'Saisissez votre mot de passe.', 'de': 'Gib dein Passwort ein.', 'ru': 'Введи свой пароль.', 'ar': 'أدخلي كلمة المرور.', 'hi': 'अपना पासवर्ड डालें।', 'bn': 'আপনার পাসওয়ার্ড লিখুন।', 'pt': 'Digite sua senha.',});
  String get authLastNameLabel =>
      _t({'es': 'Apellido', 'en': 'Last name', 'fr': 'Nom de famille', 'de': 'Nachname', 'ru': 'Фамилия', 'ar': 'اسم العائلة', 'hi': 'उपनाम', 'bn': 'পদবি', 'pt': 'Sobrenome',});
  String get authLastNameHint => _t({'es': 'Ej. Gómez', 'en': 'E.g. Smith', 'fr': 'Ex. Dupont', 'de': 'Z. B. Müller', 'ru': 'Напр. Иванова', 'ar': 'مثال: العلي', 'hi': 'उदा. शर्मा', 'bn': 'যেমন: দাস', 'pt': 'Ex. Silva',});
  String get authLastNameRequired => _t({
        'es': 'Escribe tu apellido.',
        'en': 'Enter your last name.',
        'fr': 'Saisissez votre nom de famille.',
        'de': 'Gib deinen Nachnamen ein.',
        'ru': 'Введи свою фамилию.',
        'ar': 'أدخلي اسم عائلتك.', 'hi': 'अपना उपनाम डालें।', 'bn': 'আপনার পদবি লিখুন।', 'pt': 'Digite seu sobrenome.',
      });
  String get authBirthDateLabel =>
      _t({'es': 'Fecha de nacimiento', 'en': 'Date of birth', 'fr': 'Date de naissance', 'de': 'Geburtsdatum', 'ru': 'Дата рождения', 'ar': 'تاريخ الميلاد', 'hi': 'जन्म तिथि', 'bn': 'জন্ম তারিখ', 'pt': 'Data de nascimento',});
  String get authBirthDateHint => _t({
        'es': 'Toca para elegir la fecha',
        'en': 'Tap to choose the date',
        'fr': 'Touchez pour choisir la date',
        'de': 'Tippen, um das Datum zu wählen',
        'ru': 'Нажми, чтобы выбрать дату',
        'ar': 'اضغطي لاختيار التاريخ', 'hi': 'तारीख चुनने के लिए टैप करें', 'bn': 'তারিখ বেছে নিতে ট্যাপ করুন', 'pt': 'Toque para escolher a data',
      });
  String get authBirthDateRequired => _t({
        'es': 'Elige tu fecha de nacimiento.',
        'en': 'Choose your date of birth.',
        'fr': 'Choisissez votre date de naissance.',
        'de': 'Wähle dein Geburtsdatum.',
        'ru': 'Выбери свою дату рождения.',
        'ar': 'اختاري تاريخ ميلادك.', 'hi': 'अपनी जन्म तिथि चुनें।', 'bn': 'আপনার জন্ম তারিখ বেছে নিন।', 'pt': 'Escolha sua data de nascimento.',
      });
  String get authConfirmPasswordLabel => _t({
        'es': 'Confirmar contraseña',
        'en': 'Confirm password',
        'fr': 'Confirmer le mot de passe',
        'de': 'Passwort bestätigen',
        'ru': 'Подтверди пароль',
        'ar': 'تأكيد كلمة المرور', 'hi': 'पासवर्ड की पुष्टि करें', 'bn': 'পাসওয়ার্ড নিশ্চিত করুন', 'pt': 'Confirmar senha',
      });
  String get authConfirmPasswordHint => _t({
        'es': 'Vuelve a escribirla',
        'en': 'Type it again',
        'fr': 'Retapez-le',
        'de': 'Erneut eingeben',
        'ru': 'Введи его ещё раз',
        'ar': 'أعيدي كتابتها', 'hi': 'इसे दोबारा लिखें', 'bn': 'আবার লিখুন', 'pt': 'Digite novamente',
      });
  String get authConfirmPasswordMismatch => _t({
        'es': 'Las contraseñas no coinciden.',
        'en': "Passwords don't match.",
        'fr': 'Les mots de passe ne correspondent pas.',
        'de': 'Die Passwörter stimmen nicht überein.',
        'ru': 'Пароли не совпадают.',
        'ar': 'كلمتا المرور غير متطابقتين.', 'hi': 'पासवर्ड मेल नहीं खाते।', 'bn': 'পাসওয়ার্ড মিলছে না।', 'pt': 'As senhas não coincidem.',
      });
  String get authAcceptTermsLabelPrefix => _t({
        'es': 'Acepto los ',
        'en': 'I accept the ',
        'fr': "J'accepte les ",
        'de': 'Ich akzeptiere die ',
        'ru': 'Я принимаю ',
        'ar': 'أوافق على ', 'hi': 'मैं स्वीकार करता/करती हूं ', 'bn': 'আমি সম্মত ', 'pt': 'Eu aceito os ',
      });
  String get authTermsLink =>
      _t({'es': 'Términos de uso', 'en': 'Terms of Use', 'fr': "Conditions d'utilisation", 'de': 'Nutzungsbedingungen', 'ru': 'Условия использования', 'ar': 'شروط الاستخدام', 'hi': 'उपयोग की शर्तें', 'bn': 'ব্যবহারের শর্তাবলী', 'pt': 'Termos de Uso',});
  String get authAcceptTermsAnd => _t({'es': ' y la ', 'en': ' and the ', 'fr': ' et la ', 'de': ' und die ', 'ru': ' и ', 'ar': ' و', 'hi': ' और ', 'bn': ' এবং ', 'pt': ' e a ',});
  String get authPrivacyLink =>
      _t({'es': 'Política de Privacidad', 'en': 'Privacy Policy', 'fr': 'Politique de confidentialité', 'de': 'Datenschutzrichtlinie', 'ru': 'Политику конфиденциальности', 'ar': 'سياسة الخصوصية', 'hi': 'गोपनीयता नीति', 'bn': 'গোপনীয়তা নীতি', 'pt': 'Política de Privacidade',});
  String get authAcceptTermsRequired => _t({
        'es': 'Debes aceptar los Términos y la Política de Privacidad para continuar.',
        'en': 'You must accept the Terms and Privacy Policy to continue.',
        'fr': "Vous devez accepter les Conditions et la Politique de confidentialité pour continuer.",
        'de': 'Du musst die Nutzungsbedingungen und die Datenschutzrichtlinie akzeptieren, um fortzufahren.',
        'ru': 'Ты должна принять Условия и Политику конфиденциальности, чтобы продолжить.',
        'ar': 'يجب عليكِ الموافقة على الشروط وسياسة الخصوصية للمتابعة.', 'hi': 'जारी रखने के लिए आपको शर्तें और गोपनीयता नीति स्वीकार करनी होंगी।', 'bn': 'চালিয়ে যেতে আপনাকে শর্তাবলী এবং গোপনীয়তা নীতিতে সম্মত হতে হবে।', 'pt': 'Você deve aceitar os Termos e a Política de Privacidade para continuar.',
      });
  String get authGenericError => _t({
        'es': 'Algo salió mal. Inténtalo de nuevo.',
        'en': 'Something went wrong. Please try again.',
        'fr': "Quelque chose s'est mal passé. Réessayez.",
        'de': 'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
        'ru': 'Что-то пошло не так. Попробуй ещё раз.',
        'ar': 'حدث خطأ ما. حاولي مرة أخرى.', 'hi': 'कुछ गड़बड़ हो गई। दोबारा कोशिश करें।', 'bn': 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।', 'pt': 'Algo deu errado. Tente novamente.',
      });
  String get authForgotPassword =>
      _t({'es': '¿Olvidaste tu contraseña?', 'en': 'Forgot your password?', 'fr': 'Mot de passe oublié ?', 'de': 'Passwort vergessen?', 'ru': 'Забыла пароль?', 'ar': 'هل نسيتِ كلمة المرور؟', 'hi': 'पासवर्ड भूल गए?', 'bn': 'পাসওয়ার্ড ভুলে গেছেন?', 'pt': 'Esqueceu sua senha?',});

  // ---- Verificación de correo al registrarse (auth_gate.dart /
  // email_verification_screen.dart) — evita que alguien se registre con un
  // correo inventado o ajeno: tras crear la cuenta con correo/contraseña,
  // Firebase envía un enlace de confirmación y la app no deja entrar hasta
  // que se confirme. No aplica a Google/Facebook (ya confirman el correo
  // ellos) ni a la sesión anónima de socio/pareja (no tiene correo). ----
  String get emailVerifyTitle => _t({
        'es': 'Confirma tu correo',
        'en': 'Confirm your email',
        'fr': 'Confirmez votre e-mail',
        'de': 'Bestätige deine E-Mail',
        'ru': 'Подтвердите свою почту',
        'ar': 'أكدي بريدك الإلكتروني', 'hi': 'अपना ईमेल पुष्टि करें', 'bn': 'আপনার ইমেইল নিশ্চিত করুন', 'pt': 'Confirme seu e-mail',
      });
  String get emailVerifyBody => _t({
        'es': 'Te enviamos un enlace de confirmación a tu correo. Ábrelo para verificar tu cuenta y evitar registros con correos falsos o de otras personas.',
        'en': "We sent a confirmation link to your email. Open it to verify your account and prevent sign-ups with fake or someone else's email.",
        'fr': "Nous avons envoyé un lien de confirmation à votre e-mail. Ouvrez-le pour vérifier votre compte et éviter les inscriptions avec des e-mails faux ou appartenant à quelqu'un d'autre.",
        'de': 'Wir haben dir einen Bestätigungslink per E-Mail geschickt. Öffne ihn, um dein Konto zu bestätigen und Anmeldungen mit gefälschten oder fremden E-Mail-Adressen zu verhindern.',
        'ru': 'Мы отправили ссылку для подтверждения на вашу почту. Откройте её, чтобы подтвердить аккаунт и предотвратить регистрацию с поддельной или чужой почтой.',
        'ar': 'أرسلنا رابط تأكيد إلى بريدك الإلكتروني. افتحيه للتحقق من حسابك ومنع التسجيل ببريد مزيف أو بريد شخص آخر.',
        'hi': 'हमने आपके ईमेल पर एक पुष्टिकरण लिंक भेजा है। अपना खाता सत्यापित करने और नकली या किसी और के ईमेल से पंजीकरण रोकने के लिए इसे खोलें।',
        'bn': 'আমরা আপনার ইমেইলে একটি নিশ্চিতকরণ লিঙ্ক পাঠিয়েছি। আপনার অ্যাকাউন্ট যাচাই করতে এবং ভুয়া বা অন্য কারো ইমেইল দিয়ে নিবন্ধন রোধ করতে এটি খুলুন।',
        'pt': 'Enviamos um link de confirmação para o seu e-mail. Abra-o para verificar sua conta e evitar cadastros com e-mails falsos ou de outras pessoas.',
      });
  String get emailVerifyResend => _t({
        'es': 'Reenviar correo',
        'en': 'Resend email',
        'fr': "Renvoyer l'e-mail",
        'de': 'E-Mail erneut senden',
        'ru': 'Отправить письмо повторно',
        'ar': 'إعادة إرسال البريد', 'hi': 'ईमेल दोबारा भेजें', 'bn': 'ইমেইল আবার পাঠান', 'pt': 'Reenviar e-mail',
      });
  String get emailVerifyResendSent => _t({
        'es': 'Correo reenviado. Revisa tu bandeja de entrada (y spam).',
        'en': 'Email resent. Check your inbox (and spam folder).',
        'fr': "E-mail renvoyé. Vérifiez votre boîte de réception (et les spams).",
        'de': 'E-Mail erneut gesendet. Überprüfe dein Postfach (und den Spam-Ordner).',
        'ru': 'Письмо отправлено повторно. Проверьте почту (и папку «Спам»).',
        'ar': 'تم إعادة إرسال البريد. تحققي من بريدك الوارد (ومجلد الرسائل غير المرغوب فيها).',
        'hi': 'ईमेल फिर से भेजा गया। अपना इनबॉक्स (और स्पैम) जांचें।',
        'bn': 'ইমেইল আবার পাঠানো হয়েছে। আপনার ইনবক্স (এবং স্প্যাম) দেখুন।',
        'pt': 'E-mail reenviado. Verifique sua caixa de entrada (e spam).',
      });
  String get emailVerifyCheck => _t({
        'es': 'Ya confirmé mi correo',
        'en': 'I already confirmed my email',
        'fr': "J'ai déjà confirmé mon e-mail",
        'de': 'Ich habe meine E-Mail bereits bestätigt',
        'ru': 'Я уже подтвердил(а) почту',
        'ar': 'لقد أكدت بريدي بالفعل', 'hi': 'मैंने अपना ईमेल पहले ही पुष्टि कर दिया है', 'bn': 'আমি ইতিমধ্যে আমার ইমেইল নিশ্চিত করেছি', 'pt': 'Já confirmei meu e-mail',
      });
  String get emailVerifyNotYet => _t({
        'es': 'Todavía no hemos recibido la confirmación. Revisa tu correo (y la carpeta de spam).',
        'en': "We haven't received the confirmation yet. Check your email (and spam folder).",
        'fr': "Nous n'avons pas encore reçu la confirmation. Vérifiez votre e-mail (et les spams).",
        'de': 'Wir haben die Bestätigung noch nicht erhalten. Überprüfe deine E-Mail (und den Spam-Ordner).',
        'ru': 'Подтверждение ещё не получено. Проверьте почту (и папку «Спам»).',
        'ar': 'لم نستلم التأكيد بعد. تحققي من بريدك الإلكتروني (ومجلد الرسائل غير المرغوب فيها).',
        'hi': 'हमें अभी तक पुष्टि नहीं मिली है। अपना ईमेल (और स्पैम फ़ोल्डर) जांचें।',
        'bn': 'আমরা এখনও নিশ্চিতকরণ পাইনি। আপনার ইমেইল (এবং স্প্যাম ফোল্ডার) দেখুন।',
        'pt': 'Ainda não recebemos a confirmação. Verifique seu e-mail (e a pasta de spam).',
      });
  String get authResetPasswordTitle => _t({
        'es': 'Recuperar contraseña',
        'en': 'Reset password',
        'fr': 'Réinitialiser le mot de passe',
        'de': 'Passwort zurücksetzen',
        'ru': 'Восстановить пароль',
        'ar': 'استعادة كلمة المرور', 'hi': 'पासवर्ड रीसेट करें', 'bn': 'পাসওয়ার্ড পুনরুদ্ধার করুন', 'pt': 'Redefinir senha',
      });
  String get authResetPasswordBody => _t({
        'es': 'Escribe tu correo y te enviaremos un enlace para crear una contraseña nueva.',
        'en': "Enter your email and we'll send you a link to create a new password.",
        'fr': 'Saisissez votre e-mail et nous vous enverrons un lien pour créer un nouveau mot de passe.',
        'de': 'Gib deine E-Mail-Adresse ein und wir senden dir einen Link zum Erstellen eines neuen Passworts.',
        'ru': 'Введи свою почту, и мы отправим тебе ссылку для создания нового пароля.',
        'ar': 'أدخلي بريدك الإلكتروني وسنرسل لكِ رابطًا لإنشاء كلمة مرور جديدة.', 'hi': 'अपना ईमेल डालें और हम आपको नया पासवर्ड बनाने के लिए एक लिंक भेजेंगे।', 'bn': 'আপনার ইমেইল লিখুন এবং আমরা আপনাকে নতুন পাসওয়ার্ড তৈরির জন্য একটি লিংক পাঠাবো।', 'pt': 'Digite seu e-mail e enviaremos um link para você criar uma nova senha.',
      });
  String get authResetPasswordSend => _t({'es': 'Enviar enlace', 'en': 'Send link', 'fr': 'Envoyer le lien', 'de': 'Link senden', 'ru': 'Отправить ссылку', 'ar': 'إرسال الرابط', 'hi': 'लिंक भेजें', 'bn': 'লিংক পাঠান', 'pt': 'Enviar link',});
  String get authResetPasswordCancel => _t({'es': 'Cancelar', 'en': 'Cancel', 'fr': 'Annuler', 'de': 'Abbrechen', 'ru': 'Отмена', 'ar': 'إلغاء', 'hi': 'रद्द करें', 'bn': 'বাতিল করুন', 'pt': 'Cancelar',});
  String get authResetPasswordSent => _t({
        'es': '📩 Te enviamos un enlace para restablecer tu contraseña. Revisa tu bandeja de entrada (y spam).',
        'en': "📩 We've sent a link to reset your password. Check your inbox (and spam folder).",
        'fr': "📩 Nous avons envoyé un lien pour réinitialiser votre mot de passe. Vérifiez votre boîte de réception (et vos spams).",
        'de': '📩 Wir haben einen Link zum Zurücksetzen deines Passworts gesendet. Prüfe deinen Posteingang (und den Spam-Ordner).',
        'ru': '📩 Мы отправили ссылку для сброса пароля. Проверь входящие (и папку спам).',
        'ar': '📩 لقد أرسلنا لكِ رابطًا لإعادة تعيين كلمة المرور. تحققي من صندوق الوارد (ومجلد البريد العشوائي).', 'hi': '📩 हमने आपके पासवर्ड को रीसेट करने के लिए एक लिंक भेज दिया है। अपना इनबॉक्स (और स्पैम) जांचें।', 'bn': '📩 আমরা আপনার পাসওয়ার্ড রিসেট করার একটি লিংক পাঠিয়েছি। আপনার ইনবক্স (এবং স্প্যাম) দেখুন।', 'pt': '📩 Enviamos um link para redefinir sua senha. Verifique sua caixa de entrada (e spam).',
      });
  String get authResetPasswordNotFound => _t({
        'es': '❌ Ese correo no tiene ninguna cuenta en CicloPlus. Revisa que esté bien escrito o regístrate primero.',
        'en': "❌ That email doesn't have a CicloPlus account. Check it's typed correctly or sign up first.",
        'fr': "❌ Cet e-mail n'a pas de compte CicloPlus. Vérifiez qu'il est bien écrit ou inscrivez-vous d'abord.",
        'de': '❌ Zu dieser E-Mail-Adresse gibt es kein CicloPlus-Konto. Prüfe die Schreibweise oder registriere dich zuerst.',
        'ru': '❌ На эту почту нет аккаунта CicloPlus. Проверь, правильно ли она написана, или сначала зарегистрируйся.',
        'ar': '❌ لا يوجد حساب في CicloPlus مرتبط بهذا البريد. تأكدي من كتابته بشكل صحيح أو سجّلي أولاً.', 'hi': '❌ उस ईमेल से CicloPlus में कोई खाता नहीं है। जांचें कि यह सही लिखा है या पहले रजिस्टर करें।', 'bn': '❌ সেই ইমেইলে CicloPlus-এ কোনো অ্যাকাউন্ট নেই। এটি সঠিকভাবে লেখা আছে কিনা দেখুন বা আগে নিবন্ধন করুন।', 'pt': '❌ Esse e-mail não tem uma conta no CicloPlus. Verifique se está escrito corretamente ou cadastre-se primeiro.',
      });  String get authCreateAccountButton => _t({'es': 'Crear mi cuenta', 'en': 'Create my account', 'fr': 'Créer mon compte', 'de': 'Mein Konto erstellen', 'ru': 'Создать мой аккаунт', 'ar': 'إنشاء حسابي', 'hi': 'मेरा खाता बनाएं', 'bn': 'আমার অ্যাকাউন্ট তৈরি করুন', 'pt': 'Criar minha conta',});
  String get authEnterButton => _t({'es': 'Entrar', 'en': 'Enter', 'fr': 'Entrer', 'de': 'Anmelden', 'ru': 'Войти', 'ar': 'دخول', 'hi': 'लॉग इन करें', 'bn': 'প্রবেশ করুন', 'pt': 'Entrar',});
  String get authContinueWithGoogle =>
      _t({'es': 'Continuar con Google', 'en': 'Continue with Google', 'fr': 'Continuer avec Google', 'de': 'Mit Google fortfahren', 'ru': 'Продолжить с Google', 'ar': 'المتابعة عبر Google', 'hi': 'Google से जारी रखें', 'bn': 'Google দিয়ে চালিয়ে যান', 'pt': 'Continuar com o Google',});
  String get authContinueWithFacebook =>
      _t({'es': 'Continuar con Facebook', 'en': 'Continue with Facebook', 'fr': 'Continuer avec Facebook', 'de': 'Mit Facebook fortfahren', 'ru': 'Продолжить с Facebook', 'ar': 'المتابعة عبر Facebook', 'hi': 'Facebook से जारी रखें', 'bn': 'Facebook দিয়ে চালিয়ে যান', 'pt': 'Continuar com o Facebook',});
  String get authOrDivider => _t({'es': 'o', 'en': 'or', 'fr': 'ou', 'de': 'oder', 'ru': 'или', 'ar': 'أو', 'hi': 'या', 'bn': 'অথবা', 'pt': 'ou',});
  String get authSignInWithEmail => _t({
        'es': 'Iniciar sesión con correo',
        'en': 'Sign in with email',
        'fr': 'Se connecter avec e-mail',
        'de': 'Mit E-Mail anmelden',
        'ru': 'Войти по почте',
        'ar': 'تسجيل الدخول بالبريد الإلكتروني', 'hi': 'ईमेल से लॉग इन करें', 'bn': 'ইমেইল দিয়ে লগ ইন করুন', 'pt': 'Entrar com e-mail',
      });
  String get authSignUpWithEmail => _t({
        'es': 'Crear cuenta con correo',
        'en': 'Sign up with email',
        'fr': "S'inscrire avec e-mail",
        'de': 'Mit E-Mail registrieren',
        'ru': 'Создать аккаунт по почте',
        'ar': 'إنشاء حساب بالبريد الإلكتروني', 'hi': 'ईमेल से खाता बनाएं', 'bn': 'ইমেইল দিয়ে অ্যাকাউন্ট তৈরি করুন', 'pt': 'Criar conta com e-mail',
      });
  String get authHaveAccount =>
      _t({'es': '¿Ya tienes cuenta? Inicia sesión', 'en': 'Already have an account? Sign in', 'fr': 'Vous avez déjà un compte ? Connectez-vous', 'de': 'Hast du schon ein Konto? Anmelden', 'ru': 'Уже есть аккаунт? Войти', 'ar': 'لديكِ حساب بالفعل؟ سجّلي الدخول', 'hi': 'पहले से खाता है? लॉग इन करें', 'bn': 'অ্যাকাউন্ট আছে? লগ ইন করুন', 'pt': 'Já tem uma conta? Entrar',});
  String get authNoAccount => _t({
        'es': '¿No tienes cuenta? Regístrate gratis',
        'en': "Don't have an account? Sign up for free",
        'fr': "Vous n'avez pas de compte ? Inscrivez-vous gratuitement",
        'de': 'Noch kein Konto? Kostenlos registrieren',
        'ru': 'Нет аккаунта? Зарегистрируйся бесплатно',
        'ar': 'ليس لديكِ حساب؟ سجّلي مجانًا', 'hi': 'खाता नहीं है? मुफ्त में साइन अप करें', 'bn': 'অ্যাকাউন্ট নেই? ফ্রিতে সাইন আপ করুন', 'pt': 'Não tem uma conta? Cadastre-se grátis',
      });
  String get authPrivacyNote => _t({
        'es': '🔒 Tu correo y contraseña se usan solo para identificarte. Tus registros de ciclo siguen siendo privados.',
        'en': '🔒 Your email and password are only used to identify you. Your cycle data stays private.',
        'fr': "🔒 Votre e-mail et votre mot de passe servent uniquement à vous identifier. Vos données de cycle restent privées.",
        'de': '🔒 Deine E-Mail und dein Passwort dienen nur zu deiner Identifikation. Deine Zyklusdaten bleiben privat.',
        'ru': '🔒 Твоя почта и пароль используются только для того, чтобы тебя идентифицировать. Твои данные о цикле остаются приватными.',
        'ar': '🔒 يُستخدم بريدك الإلكتروني وكلمة المرور فقط للتعرف عليكِ. بيانات دورتك تبقى خاصة.', 'hi': '🔒 आपके ईमेल और पासवर्ड का इस्तेमाल सिर्फ आपकी पहचान के लिए किया जाता है। आपके चक्र के रिकॉर्ड निजी ही रहते हैं।', 'bn': '🔒 আপনার ইমেইল ও পাসওয়ার্ড শুধু আপনাকে শনাক্ত করতে ব্যবহৃত হয়। আপনার চক্রের রেকর্ড ব্যক্তিগতই থাকে।', 'pt': '🔒 Seu e-mail e senha são usados apenas para identificá-la. Seus registros de ciclo continuam privados.',
      });

  // ==================== reminder_service.dart ====================

  // Recordatorio de "tu periodo se acerca" (distinto del recordatorio
  // diario de registro) — antes este texto estaba fijo en español dentro
  // de reminder_service.dart, sin pasar por AppStrings como el resto de
  // notificaciones. `days` es el número de días configurado en
  // Configuración ("avisarme X días antes").
  String get notifPeriodReminderTitle =>
      _t({'es': 'CicloPlus 🌸', 'en': 'CicloPlus 🌸', 'fr': 'CicloPlus 🌸', 'de': 'CicloPlus 🌸', 'ru': 'CicloPlus 🌸', 'ar': 'CicloPlus 🌸', 'hi': 'CicloPlus 🌸', 'bn': 'CicloPlus 🌸', 'pt': 'CicloPlus 🌸',});
  String notifPeriodReminderBody(int days) => _t({
        'es': 'Tu periodo llega en $days día(s). ¡Prepárate!',
        'en': 'Your period arrives in $days day(s). Get ready!',
        'fr': 'Vos règles arrivent dans $days jour(s). Préparez-vous !',
        'de': 'Deine Periode kommt in $days Tag(en). Mach dich bereit!',
        'ru': 'Твоя менструация начнётся через $days дн. Готовься!',
        'ar': 'ستبدأ دورتك خلال $days أيام. استعدي!', 'hi': 'आपका पीरियड $days दिन में आ रहा है। तैयार हो जाइए!', 'bn': 'আপনার পিরিয়ড $days দিনে আসছে। প্রস্তুত হন!', 'pt': 'Seu período chega em $days dia(s). Prepare-se!',
      });

  // Avisos de Ovulación y Ventana fértil (pantalla "Obtener Recordatorio"
  // en Mi salud) — a diferencia del de Periodo, avisan el mismo día (sin
  // antelación configurable), por eso no reciben un parámetro `days`.
  String get notifOvulationReminderBody => _t({
        'es': 'Hoy es tu día estimado de ovulación.',
        'en': "Today is your estimated ovulation day.",
        'fr': "Aujourd'hui est votre jour d'ovulation estimé.",
        'de': 'Heute ist dein geschätzter Eisprung-Tag.',
        'ru': 'Сегодня твой предполагаемый день овуляции.',
        'ar': 'اليوم هو يوم الإباضة المتوقع لديكِ.', 'hi': 'आज आपके अनुमानित ओव्यूलेशन का दिन है।', 'bn': 'আজ আপনার আনুমানিক ডিম্বস্ফোটনের দিন।', 'pt': 'Hoje é seu dia estimado de ovulação.',
      });
  String get notifFertileReminderBody => _t({
        'es': 'Hoy comienza tu ventana fértil estimada.',
        'en': 'Your estimated fertile window starts today.',
        'fr': "Votre fenêtre de fertilité estimée commence aujourd'hui.",
        'de': 'Dein geschätztes fruchtbares Fenster beginnt heute.',
        'ru': 'Сегодня начинается твоё предполагаемое фертильное окно.',
        'ar': 'تبدأ اليوم نافذة خصوبتك المتوقعة.', 'hi': 'आज से आपकी अनुमानित उपजाऊ अवधि शुरू हो रही है।', 'bn': 'আজ থেকে আপনার আনুমানিক উর্বর সময়কাল শুরু হচ্ছে।', 'pt': 'Hoje começa sua janela fértil estimada.',
      });

  // Avisos de los 3 interruptores de "Período & fertilidad" (Inicio del
  // período, Fin del período, Introducir período) — antes eran booleanos
  // que no programaban ninguna notificación real (ver ReminderSettings).
  String get notifPeriodStartReminderBody => _t({
        'es': 'Tu período debería comenzar hoy, según tu calendario.',
        'en': 'Your period is expected to start today, based on your calendar.',
        'fr': 'Vos règles devraient commencer aujourd\'hui, selon votre calendrier.',
        'de': 'Deine Periode sollte laut Kalender heute beginnen.',
        'ru': 'Согласно твоему календарю, твоя менструация должна начаться сегодня.',
        'ar': 'من المفترض أن تبدأ دورتك اليوم، وفقًا لتقويمك.', 'hi': 'आपके कैलेंडर के अनुसार, आज आपका पीरियड शुरू होना चाहिए।', 'bn': 'আপনার ক্যালেন্ডার অনুযায়ী, আজ আপনার পিরিয়ড শুরু হওয়ার কথা।', 'pt': 'Seu período deveria começar hoje, de acordo com seu calendário.',
      });
  String get notifPeriodEndReminderBody => _t({
        'es': 'Tu período debería estar terminando por estos días.',
        'en': 'Your period should be wrapping up around now.',
        'fr': 'Vos règles devraient se terminer ces jours-ci.',
        'de': 'Deine Periode dürfte sich jetzt dem Ende nähern.',
        'ru': 'Твоя менструация должна заканчиваться примерно в эти дни.',
        'ar': 'من المفترض أن تنتهي دورتك في هذه الأيام تقريبًا.', 'hi': 'इन दिनों में आपका पीरियड खत्म हो जाना चाहिए।', 'bn': 'এই দিনগুলোতে আপনার পিরিয়ড শেষ হয়ে যাওয়ার কথা।', 'pt': 'Seu período deveria estar acabando por estes dias.',
      });
  String get notifEnterPeriodReminderBody => _t({
        'es': '¿Ya comenzó tu período? Regístralo en CicloPlus.',
        'en': 'Has your period started? Log it in CicloPlus.',
        'fr': 'Vos règles ont-elles commencé ? Enregistrez-les dans CicloPlus.',
        'de': 'Hat deine Periode schon begonnen? Trage sie in CicloPlus ein.',
        'ru': 'Уже началась менструация? Отметь её в CicloPlus.',
        'ar': 'هل بدأت دورتك؟ سجّليها في CicloPlus.', 'hi': 'क्या आपका पीरियड शुरू हो गया है? इसे CicloPlus में दर्ज करें।', 'bn': 'আপনার পিরিয়ড কি শুরু হয়ে গেছে? CicloPlus-এ এটি লগ করুন।', 'pt': 'Seu período já começou? Registre no CicloPlus.',
      });

  // Avisos de Autoexamen de mamas y Fase del ciclo (ver
  // settings_service.dart / reminder_screen.dart) — mismo patrón que el
  // resto de notificaciones puntuales, con canal propio para poder
  // silenciarlas por separado desde los ajustes del sistema.
  String get notifBreastSelfExamTitle =>
      _t({'es': 'CicloPlus 🎗️', 'en': 'CicloPlus 🎗️', 'fr': 'CicloPlus 🎗️', 'de': 'CicloPlus 🎗️', 'ru': 'CicloPlus 🎗️', 'ar': 'CicloPlus 🎗️', 'hi': 'CicloPlus 🎗️', 'bn': 'CicloPlus 🎗️', 'pt': 'CicloPlus 🎗️',});
  String get notifBreastSelfExamBody => _t({
        'es': 'Es un buen momento para hacerte el autoexamen de mamas.',
        'en': "It's a good time to do your breast self-exam.",
        'fr': "C'est un bon moment pour faire votre autoexamen des seins.",
        'de': 'Jetzt ist ein guter Zeitpunkt für deine Brustselbstuntersuchung.',
        'ru': 'Хороший момент, чтобы сделать самообследование груди.',
        'ar': 'إنه وقت مناسب لإجراء الفحص الذاتي للثدي.', 'hi': 'स्तन स्व-परीक्षण करने का यह अच्छा समय है।', 'bn': 'স্তন স্ব-পরীক্ষা করার এটি ভালো সময়।', 'pt': 'É um bom momento para fazer seu autoexame das mamas.',
      });
  String get notifBreastSelfExamChannelName => _t({
        'es': 'Recordatorio de autoexamen de mamas',
        'en': 'Breast self-exam reminder',
        'fr': 'Rappel d\'autoexamen des seins',
        'de': 'Erinnerung an Brustselbstuntersuchung',
        'ru': 'Напоминание о самообследовании груди',
        'ar': 'تذكير بالفحص الذاتي للثدي', 'hi': 'स्तन स्व-परीक्षण रिमाइंडर', 'bn': 'স্তন স্ব-পরীক্ষা রিমাইন্ডার', 'pt': 'Lembrete de autoexame das mamas',
      });
  String get notifBreastSelfExamChannelDesc => _t({
        'es': 'Recuérdame hacerme el autoexamen de mamas',
        'en': 'Remind me to do my breast self-exam',
        'fr': 'Me rappeler de faire mon autoexamen des seins',
        'de': 'Erinnere mich an meine Brustselbstuntersuchung',
        'ru': 'Напоминай мне делать самообследование груди',
        'ar': 'ذكّريني بإجراء الفحص الذاتي للثدي', 'hi': 'मुझे स्तन स्व-परीक्षण करने की याद दिलाएं', 'bn': 'আমাকে স্তন স্ব-পরীক্ষা করার কথা মনে করিয়ে দিন', 'pt': 'Me lembre de fazer o autoexame das mamas',
      });

  String get notifCyclePhaseTitle =>
      _t({'es': 'CicloPlus 🌙', 'en': 'CicloPlus 🌙', 'fr': 'CicloPlus 🌙', 'de': 'CicloPlus 🌙', 'ru': 'CicloPlus 🌙', 'ar': 'CicloPlus 🌙', 'hi': 'CicloPlus 🌙', 'bn': 'CicloPlus 🌙', 'pt': 'CicloPlus 🌙',});
  String get notifCyclePhaseBody => _t({
        'es': 'Revisa en qué fase de tu ciclo estás hoy y algunos consejos para ella.',
        'en': "Check which phase of your cycle you're in today and some tips for it.",
        'fr': "Découvrez dans quelle phase de votre cycle vous êtes aujourd'hui et quelques conseils.",
        'de': 'Sieh nach, in welcher Zyklusphase du heute bist, und erhalte passende Tipps.',
        'ru': 'Узнай, в какой фазе цикла ты находишься сегодня, и несколько советов для неё.',
        'ar': 'تحققي من المرحلة التي تمرين بها في دورتك اليوم واطّلعي على بعض النصائح لها.', 'hi': 'देखें कि आज आप अपने चक्र के किस चरण में हैं और उसके लिए कुछ सुझाव पाएं।', 'bn': 'দেখুন আজ আপনি চক্রের কোন পর্যায়ে আছেন এবং এর জন্য কিছু টিপস পান।', 'pt': 'Veja em que fase do seu ciclo você está hoje e algumas dicas para ela.',
      });
  String get notifCyclePhaseChannelName => _t({
        'es': 'Recordatorio de fase del ciclo',
        'en': 'Cycle phase reminder',
        'fr': 'Rappel de phase du cycle',
        'de': 'Erinnerung an Zyklusphase',
        'ru': 'Напоминание о фазе цикла',
        'ar': 'تذكير بمرحلة الدورة', 'hi': 'चक्र चरण रिमाइंडर', 'bn': 'চক্রের পর্যায় রিমাইন্ডার', 'pt': 'Lembrete de fase do ciclo',
      });
  String get notifCyclePhaseChannelDesc => _t({
        'es': 'Avísame cuando cambie la fase de mi ciclo',
        'en': 'Notify me when my cycle phase changes',
        'fr': 'Me prévenir quand la phase de mon cycle change',
        'de': 'Benachrichtige mich, wenn sich meine Zyklusphase ändert',
        'ru': 'Уведомляй меня, когда меняется фаза моего цикла',
        'ar': 'أعلميني عند تغير مرحلة دورتي', 'hi': 'मेरे चक्र का चरण बदलने पर मुझे बताएं', 'bn': 'আমার চক্রের পর্যায় বদলালে আমাকে জানান', 'pt': 'Me avise quando a fase do meu ciclo mudar',
      });

  String get notifDrinkWaterTitle =>
      _t({'es': 'CicloPlus 💧', 'en': 'CicloPlus 💧', 'fr': 'CicloPlus 💧', 'de': 'CicloPlus 💧', 'ru': 'CicloPlus 💧', 'ar': 'CicloPlus 💧', 'hi': 'CicloPlus 💧', 'bn': 'CicloPlus 💧', 'pt': 'CicloPlus 💧',});
  String get notifDrinkWaterBody => _t({
        'es': 'Recuerda beber agua. ¡Tu cuerpo te lo agradecerá!',
        'en': 'Remember to drink water. Your body will thank you!',
        'fr': "Pensez à boire de l'eau. Votre corps vous remerciera !",
        'de': 'Denk daran, Wasser zu trinken. Dein Körper wird es dir danken!',
        'ru': 'Не забывай пить воду. Твоё тело скажет тебе спасибо!',
        'ar': 'تذكّري شرب الماء. سيشكرك جسمك على ذلك!', 'hi': 'पानी पीना याद रखें। आपका शरीर आपको धन्यवाद देगा!', 'bn': 'পানি পান করতে ভুলবেন না। আপনার শরীর আপনাকে ধন্যবাদ দেবে!', 'pt': 'Lembre-se de beber água. Seu corpo vai agradecer!',
      });
  String get notifDrinkWaterChannelName => _t({
        'es': 'Recordatorio de agua',
        'en': 'Water reminder',
        'fr': "Rappel d'hydratation",
        'de': 'Erinnerung ans Trinken',
        'ru': 'Напоминание о воде',
        'ar': 'تذكير بشرب الماء', 'hi': 'पानी पीने का रिमाइंडर', 'bn': 'পানি পানের রিমাইন্ডার', 'pt': 'Lembrete de água',
      });
  String get notifDrinkWaterChannelDesc => _t({
        'es': 'Recuérdame beber agua durante el día',
        'en': 'Remind me to drink water during the day',
        'fr': "Me rappeler de boire de l'eau pendant la journée",
        'de': 'Erinnere mich tagsüber ans Wassertrinken',
        'ru': 'Напоминай мне пить воду в течение дня',
        'ar': 'ذكّريني بشرب الماء خلال اليوم', 'hi': 'दिन भर पानी पीने की याद दिलाएं', 'bn': 'সারাদিন পানি পানের কথা মনে করিয়ে দিন', 'pt': 'Me lembre de beber água durante o dia',
      });

  // ==================== daily_notification_service.dart ====================

  String get notifDailyReminderTitle => _t({'es': 'CicloPlus 🌸', 'en': 'CicloPlus 🌸', 'fr': 'CicloPlus 🌸', 'de': 'CicloPlus 🌸', 'ru': 'CicloPlus 🌸', 'ar': 'CicloPlus 🌸', 'hi': 'CicloPlus 🌸', 'bn': 'CicloPlus 🌸', 'pt': 'CicloPlus 🌸',});
  String get notifDailyReminderBody => _t({
        'es': '¿Ya registraste cómo te sientes hoy?',
        'en': 'Have you logged how you feel today?',
        'fr': "Avez-vous déjà noté comment vous vous sentez aujourd'hui ?",
        'de': 'Hast du schon eingetragen, wie du dich heute fühlst?',
        'ru': 'Уже отметила, как ты себя чувствуешь сегодня?',
        'ar': 'هل سجّلتِ شعورك اليوم؟', 'hi': 'क्या आपने आज अपनी तबीयत दर्ज की?', 'bn': 'আজ আপনি কেমন অনুভব করছেন তা কি লগ করেছেন?', 'pt': 'Você já registrou como está se sentindo hoje?',
      });
  String get notifDailyChannelName => _t({
        'es': 'Recordatorio diario de registro',
        'en': 'Daily log reminder',
        'fr': 'Rappel quotidien de journal',
        'de': 'Tägliche Protokoll-Erinnerung',
        'ru': 'Ежедневное напоминание о записи',
        'ar': 'تذكير يومي بالتسجيل', 'hi': 'दैनिक रिकॉर्ड रिमाइंडर', 'bn': 'দৈনিক লগ রিমাইন্ডার', 'pt': 'Lembrete diário de registro',
      });
  String get notifDailyChannelDesc => _t({
        'es': 'Recuérdame registrar mi día en CicloPlus',
        'en': 'Remind me to log my day in CicloPlus',
        'fr': 'Me rappeler de noter ma journée dans CicloPlus',
        'de': 'Erinnere mich, meinen Tag in CicloPlus einzutragen',
        'ru': 'Напоминай мне отмечать свой день в CicloPlus',
        'ar': 'ذكّريني بتسجيل يومي في CicloPlus', 'hi': 'मुझे CicloPlus में अपना दिन दर्ज करने की याद दिलाएं', 'bn': 'CicloPlus-এ আমার দিন লগ করার কথা মনে করিয়ে দিন', 'pt': 'Me lembre de registrar meu dia no CicloPlus',
      });

  String get notifPillReminderTitle => _t({'es': 'CicloPlus 💊', 'en': 'CicloPlus 💊', 'fr': 'CicloPlus 💊', 'de': 'CicloPlus 💊', 'ru': 'CicloPlus 💊', 'ar': 'CicloPlus 💊', 'hi': 'CicloPlus 💊', 'bn': 'CicloPlus 💊', 'pt': 'CicloPlus 💊',});
  String get notifPillReminderBody => _t({
        'es': 'Hora de tomar tu pastilla anticonceptiva.',
        'en': 'Time to take your birth control pill.',
        'fr': 'Il est temps de prendre votre pilule contraceptive.',
        'de': 'Zeit, deine Antibabypille einzunehmen.',
        'ru': 'Время принять противозачаточную таблетку.',
        'ar': 'حان وقت أخذ حبة منع الحمل.', 'hi': 'अपनी गर्भनिरोधक गोली लेने का समय हो गया है।', 'bn': 'আপনার জন্মনিয়ন্ত্রণ পিল খাওয়ার সময় হয়েছে।', 'pt': 'Hora de tomar sua pílula anticoncepcional.',
      });
  String get notifPillChannelName =>
      _t({'es': 'Recordatorio de anticonceptivo', 'en': 'Birth control reminder', 'fr': 'Rappel de contraception', 'de': 'Erinnerung an Verhütung', 'ru': 'Напоминание о контрацепции', 'ar': 'تذكير بوسيلة منع الحمل', 'hi': 'गर्भनिरोधक रिमाइंडर', 'bn': 'জন্মনিয়ন্ত্রণ রিমাইন্ডার', 'pt': 'Lembrete de anticoncepcional',});
  String get notifPillChannelDesc => _t({
        'es': 'Recuérdame tomar la pastilla',
        'en': 'Remind me to take the pill',
        'fr': 'Me rappeler de prendre la pilule',
        'de': 'Erinnere mich an die Pille',
        'ru': 'Напоминай мне принять таблетку',
        'ar': 'ذكّريني بأخذ الحبة', 'hi': 'गोली लेने की याद दिलाएं', 'bn': 'পিল খাওয়ার কথা মনে করিয়ে দিন', 'pt': 'Me lembre de tomar a pílula',
      });

  String get notifAppointmentTitle => _t({'es': 'CicloPlus 🏥', 'en': 'CicloPlus 🏥', 'fr': 'CicloPlus 🏥', 'de': 'CicloPlus 🏥', 'ru': 'CicloPlus 🏥', 'ar': 'CicloPlus 🏥', 'hi': 'CicloPlus 🏥', 'bn': 'CicloPlus 🏥', 'pt': 'CicloPlus 🏥',});
  String notifAppointmentBody(String label) => _t({
        'es': 'Recuerda tu cita: $label',
        'en': 'Reminder for your appointment: $label',
        'fr': 'Rappel de votre rendez-vous : $label',
        'de': 'Erinnerung an deinen Termin: $label',
        'ru': 'Напоминаем о твоём приёме: $label',
        'ar': 'تذكير بموعدك: $label', 'hi': 'अपनी अपॉइंटमेंट याद रखें: $label', 'bn': 'আপনার অ্যাপয়েন্টমেন্ট মনে রাখুন: $label', 'pt': 'Lembre-se do seu compromisso: $label',
      });
  String get notifAppointmentChannelName =>
      _t({'es': 'Citas médicas', 'en': 'Medical appointments', 'fr': 'Rendez-vous médicaux', 'de': 'Arzttermine', 'ru': 'Медицинские приёмы', 'ar': 'المواعيد الطبية', 'hi': 'डॉक्टर की अपॉइंटमेंट', 'bn': 'ডাক্তারের অ্যাপয়েন্টমেন্ট', 'pt': 'Consultas médicas',});
  String get notifAppointmentChannelDesc => _t({
        'es': 'Recuérdame mis citas médicas',
        'en': 'Remind me of my medical appointments',
        'fr': 'Me rappeler mes rendez-vous médicaux',
        'de': 'Erinnere mich an meine Arzttermine',
        'ru': 'Напоминай мне о моих медицинских приёмах',
        'ar': 'ذكّريني بمواعيدي الطبية', 'hi': 'मुझे मेरी डॉक्टर अपॉइंटमेंट की याद दिलाएं', 'bn': 'আমার ডাক্তারের অ্যাপয়েন্টমেন্টের কথা মনে করিয়ে দিন', 'pt': 'Me lembre das minhas consultas médicas',
      });

  // Recordatorio de "reenganche": se dispara si la persona pasa 2 días
  // sin abrir la app (ver DailyNotificationService.scheduleReengagementCheckIn).
  String get notifReengagementTitle => _t({
        'es': 'CicloPlus 🌷',
        'en': 'CicloPlus 🌷',
        'fr': 'CicloPlus 🌷',
        'de': 'CicloPlus 🌷',
        'ru': 'CicloPlus 🌷',
        'ar': 'CicloPlus 🌷',
        'hi': 'CicloPlus 🌷',
        'bn': 'CicloPlus 🌷',
        'pt': 'CicloPlus 🌷',
      });
  String get notifReengagementBody => _t({
        'es': '¿Cómo te sientes hoy? Hace un par de días que no entras, ¡te extrañamos!',
        'en': "How are you feeling today? It's been a couple of days — we miss you!",
        'fr': "Comment vous sentez-vous aujourd'hui ? Cela fait quelques jours, vous nous manquez !",
        'de': 'Wie fühlst du dich heute? Es ist schon ein paar Tage her — wir vermissen dich!',
        'ru': 'Как ты себя чувствуешь сегодня? Ты давно не заходила — мы скучаем!',
        'ar': 'كيف تشعرين اليوم؟ مرّ يومان منذ آخر زيارة، اشتقنا إليك!', 'hi': 'आज आप कैसा महसूस कर रही हैं? कुछ दिन हो गए हैं — हमें आपकी कमी खल रही है!', 'bn': 'আজ আপনি কেমন অনুভব করছেন? কয়েক দিন হয়ে গেছে — আমরা আপনাকে মিস করছি!', 'pt': 'Como você está se sentindo hoje? Faz alguns dias — sentimos sua falta!',
      });
  String get notifReengagementChannelName => _t({
        'es': 'Te extrañamos',
        'en': 'We miss you',
        'fr': 'Vous nous manquez',
        'de': 'Wir vermissen dich',
        'ru': 'Мы скучаем',
        'ar': 'اشتقنا إليك', 'hi': 'हमें आपकी कमी खल रही है', 'bn': 'আমরা আপনাকে মিস করছি', 'pt': 'Sentimos sua falta',
      });
  String get notifReengagementChannelDesc => _t({
        'es': 'Avísame si paso varios días sin abrir CicloPlus',
        'en': 'Let me know if I go several days without opening CicloPlus',
        'fr': "Prévenez-moi si je reste plusieurs jours sans ouvrir CicloPlus",
        'de': 'Benachrichtige mich, wenn ich mehrere Tage lang CicloPlus nicht öffne',
        'ru': 'Напомни мне, если я несколько дней не открываю CicloPlus',
        'ar': 'أخبريني إذا مرت عدة أيام دون فتح CicloPlus', 'hi': 'मुझे बताएं अगर मैं कई दिनों तक CicloPlus नहीं खोलती', 'bn': 'আমাকে জানান যদি আমি কয়েক দিন CicloPlus না খুলি', 'pt': 'Me avise se eu ficar vários dias sem abrir o CicloPlus',
      });

  // ==================== pdf_report_service.dart ====================

  String get pdfReportHeader =>
      _t({'es': 'CicloPlus — Reporte de ciclo', 'en': 'CicloPlus — Cycle report', 'fr': 'CicloPlus — Rapport de cycle', 'de': 'CicloPlus — Zyklusbericht', 'ru': 'CicloPlus — Отчёт о цикле', 'ar': 'CicloPlus — تقرير الدورة', 'hi': 'CicloPlus — चक्र रिपोर्ट', 'bn': 'CicloPlus — চক্র রিপোর্ট', 'pt': 'CicloPlus — Relatório de ciclo',});
  String pdfGeneratedOn(String date) => _t({
        'es': 'Generado el $date',
        'en': 'Generated on $date',
        'fr': 'Généré le $date',
        'de': 'Erstellt am $date',
        'ru': 'Создано $date',
        'ar': 'تم الإنشاء في $date', 'hi': '$date को तैयार किया गया', 'bn': '$date তারিখে তৈরি', 'pt': 'Gerado em $date',
      });
  String get pdfSummaryTitle => _t({'es': 'Resumen', 'en': 'Summary', 'fr': 'Résumé', 'de': 'Zusammenfassung', 'ru': 'Сводка', 'ar': 'ملخص', 'hi': 'सारांश', 'bn': 'সারসংক্ষেপ', 'pt': 'Resumo',});
  String pdfCyclesLogged(int n) => _t({
        'es': 'Ciclos registrados: $n',
        'en': 'Cycles logged: $n',
        'fr': 'Cycles enregistrés : $n',
        'de': 'Erfasste Zyklen: $n',
        'ru': 'Зарегистрировано циклов: $n',
        'ar': 'الدورات المسجّلة: $n', 'hi': 'दर्ज किए गए चक्र: $n', 'bn': 'লগ করা চক্র: $n', 'pt': 'Ciclos registrados: $n',
      });
  String pdfAvgCycleLength(int days) => _t({
        'es': 'Duración promedio de ciclo: $days días',
        'en': 'Average cycle length: $days days',
        'fr': 'Durée moyenne du cycle : $days jours',
        'de': 'Durchschnittliche Zykluslänge: $days Tage',
        'ru': 'Средняя длительность цикла: $days дн.',
        'ar': 'متوسط مدة الدورة: $days يومًا', 'hi': 'औसत चक्र अवधि: $days दिन', 'bn': 'গড় চক্রের দৈর্ঘ্য: $days দিন', 'pt': 'Duração média do ciclo: $days dias',
      });
  String pdfAvgPeriodLength(int days) => _t({
        'es': 'Duración promedio de periodo: $days días',
        'en': 'Average period length: $days days',
        'fr': 'Durée moyenne des règles : $days jours',
        'de': 'Durchschnittliche Periodendauer: $days Tage',
        'ru': 'Средняя длительность менструации: $days дн.',
        'ar': 'متوسط مدة الحيض: $days يومًا', 'hi': 'औसत पीरियड अवधि: $days दिन', 'bn': 'গড় পিরিয়ডের দৈর্ঘ্য: $days দিন', 'pt': 'Duração média do período: $days dias',
      });
  String get pdfCycleHistoryTitle =>
      _t({'es': 'Historial de ciclos', 'en': 'Cycle history', 'fr': 'Historique des cycles', 'de': 'Zyklusverlauf', 'ru': 'История циклов', 'ar': 'سجل الدورات', 'hi': 'चक्र इतिहास', 'bn': 'চক্রের ইতিহাস', 'pt': 'Histórico de ciclos',});
  String pdfCycleDaysCount(int days) => _t({'es': '$days días', 'en': '$days days', 'fr': '$days jours', 'de': '$days Tage', 'ru': '$days дн.', 'ar': '$days أيام', 'hi': '$days दिन', 'bn': '$days দিন', 'pt': '$days dias',});
  String get pdfFilename => _t({
        'es': 'cicloplus-reporte.pdf',
        'en': 'cicloplus-report.pdf',
        'fr': 'cicloplus-rapport.pdf',
        'de': 'cicloplus-bericht.pdf',
        'ru': 'cicloplus-reporte.pdf',
        'ar': 'cicloplus-reporte.pdf', 'hi': 'cicloplus-report.pdf', 'bn': 'cicloplus-report.pdf', 'pt': 'cicloplus-relatorio.pdf',
      });

  // ---- Paywall / suscripción ----
  String get paywallTitle =>
      _t({'es': 'CicloPlus Premium', 'en': 'CicloPlus Premium', 'fr': 'CicloPlus Premium', 'de': 'CicloPlus Premium', 'ru': 'CicloPlus Premium', 'ar': 'CicloPlus Premium', 'hi': 'CicloPlus Premium', 'bn': 'CicloPlus Premium', 'pt': 'CicloPlus Premium',});
  String get paywallHeadline => _t({
        'es': 'Desbloquea todo el potencial de tu ciclo',
        'en': 'Unlock the full potential of your cycle',
        'fr': 'Débloquez tout le potentiel de votre cycle',
        'de': 'Hol dir das volle Potenzial deines Zyklus',
        'ru': 'Раскрой весь потенциал своего цикла',
        'ar': 'اكتشفي الإمكانات الكاملة لدورتك', 'hi': 'अपने चक्र की पूरी क्षमता को अनलॉक करें', 'bn': 'আপনার চক্রের সম্পূর্ণ সম্ভাবনা আনলক করুন', 'pt': 'Desbloqueie todo o potencial do seu ciclo',
      });
  String get paywallSubheadline => _t({
        'es': '7 días de prueba gratis, luego elige el plan que mejor te convenga.',
        'en': '7 days free trial, then choose the plan that suits you best.',
        'fr': "7 jours d'essai gratuit, puis choisissez le forfait qui vous convient.",
        'de': '7 Tage kostenlos testen, dann wähle den passenden Plan.',
        'ru': '7 дней бесплатной пробной версии, затем выбери подходящий тебе тариф.',
        'ar': '7 أيام تجربة مجانية، ثم اختاري الخطة الأنسب لكِ.', 'hi': '7 दिन का मुफ्त ट्रायल, फिर अपने लिए सबसे अच्छा प्लान चुनें।', 'bn': '৭ দিনের ফ্রি ট্রায়াল, তারপর আপনার জন্য সবচেয়ে ভালো প্ল্যান বেছে নিন।', 'pt': '7 dias de teste grátis, depois escolha o plano que for melhor para você.',
      });
  String get paywallFeature1 => _t({
        'es': 'Predicciones avanzadas de ciclo y ovulación',
        'en': 'Advanced cycle and ovulation predictions',
        'fr': "Prédictions avancées de cycle et d'ovulation",
        'de': 'Erweiterte Zyklus- und Eisprungvorhersagen',
        'ru': 'Расширенные прогнозы цикла и овуляции',
        'ar': 'توقعات متقدمة للدورة والإباضة', 'hi': 'चक्र और ओव्यूलेशन के लिए एडवांस्ड भविष्यवाणियां', 'bn': 'চক্র ও ডিম্বস্ফোটনের জন্য উন্নত পূর্বাভাস', 'pt': 'Previsões avançadas de ciclo e ovulação',
      });
  String get paywallFeature2 => _t({
        'es': 'Estadísticas, insights y reportes en PDF',
        'en': 'Statistics, insights and PDF reports',
        'fr': 'Statistiques, analyses et rapports PDF',
        'de': 'Statistiken, Einblicke und PDF-Berichte',
        'ru': 'Статистика, аналитика и отчёты в PDF',
        'ar': 'إحصائيات ورؤى وتقارير PDF', 'hi': 'आंकड़े, इनसाइट्स और PDF रिपोर्ट', 'bn': 'পরিসংখ্যান, ইনসাইট এবং PDF রিপোর্ট', 'pt': 'Estatísticas, insights e relatórios em PDF',
      });
  String get paywallFeature3 => _t({
        'es': 'Sincronización con Apple Health / Google Fit',
        'en': 'Sync with Apple Health / Google Fit',
        'fr': 'Synchronisation avec Apple Health / Google Fit',
        'de': 'Synchronisierung mit Apple Health / Google Fit',
        'ru': 'Синхронизация с Apple Health / Google Fit',
        'ar': 'مزامنة مع Apple Health / Google Fit', 'hi': 'Apple Health / Google Fit के साथ सिंक', 'bn': 'Apple Health / Google Fit এর সাথে সিঙ্ক', 'pt': 'Sincronização com Apple Health / Google Fit',
      });
  String get paywallFeature4 => _t({
        'es': 'Sin anuncios, para siempre',
        'en': 'No ads, ever',
        'fr': 'Sans publicité, pour toujours',
        'de': 'Werbefrei, für immer',
        'ru': 'Без рекламы, навсегда',
        'ar': 'بدون إعلانات، إلى الأبد', 'hi': 'हमेशा के लिए बिना विज्ञापन', 'bn': 'চিরকালের জন্য বিজ্ঞাপনমুক্ত', 'pt': 'Sem anúncios, para sempre',
      });
  String get paywallPlanWeekly =>
      _t({'es': 'Semanal', 'en': 'Weekly', 'fr': 'Hebdomadaire', 'de': 'Wöchentlich', 'ru': 'Еженедельно', 'ar': 'أسبوعي', 'hi': 'साप्ताहिक', 'bn': 'সাপ্তাহিক', 'pt': 'Semanal',});
  String get paywallPlanMonthly =>
      _t({'es': 'Mensual', 'en': 'Monthly', 'fr': 'Mensuel', 'de': 'Monatlich', 'ru': 'Ежемесячно', 'ar': 'شهري', 'hi': 'मासिक', 'bn': 'মাসিক', 'pt': 'Mensal',});
  String get paywallPlanAnnual =>
      _t({'es': 'Anual', 'en': 'Annual', 'fr': 'Annuel', 'de': 'Jährlich', 'ru': 'Ежегодно', 'ar': 'سنوي', 'hi': 'वार्षिक', 'bn': 'বার্ষিক', 'pt': 'Anual',});
  String get paywallPlanWeeklyDesc => _t({
        'es': 'Se renueva cada semana',
        'en': 'Renews every week',
        'fr': 'Renouvelé chaque semaine',
        'de': 'Verlängert sich wöchentlich',
        'ru': 'Продлевается каждую неделю',
        'ar': 'يتجدد كل أسبوع', 'hi': 'हर हफ्ते नवीनीकृत होता है', 'bn': 'প্রতি সপ্তাহে নবায়ন হয়', 'pt': 'Renova toda semana',
      });
  String get paywallPlanMonthlyDesc => _t({
        'es': 'Se renueva cada mes',
        'en': 'Renews every month',
        'fr': 'Renouvelé chaque mois',
        'de': 'Verlängert sich monatlich',
        'ru': 'Продлевается каждый месяц',
        'ar': 'يتجدد كل شهر', 'hi': 'हर महीने नवीनीकृत होता है', 'bn': 'প্রতি মাসে নবায়ন হয়', 'pt': 'Renova todo mês',
      });
  String get paywallPlanAnnualDesc => _t({
        'es': 'Se renueva cada año · ahorra frente al mensual',
        'en': 'Renews every year · save vs. monthly',
        'fr': "Renouvelé chaque année · économisez par rapport au mensuel",
        'de': 'Verlängert sich jährlich · günstiger als monatlich',
        'ru': 'Продлевается каждый год · выгоднее месячного',
        'ar': 'يتجدد كل عام · وفّري مقارنةً بالشهري', 'hi': 'हर साल नवीनीकृत होता है · मासिक से ज़्यादा बचत', 'bn': 'প্রতি বছর নবায়ন হয় · মাসিকের চেয়ে সাশ্রয়ী', 'pt': 'Renova todo ano · economize em relação ao mensal',
      });
  String get paywallRecommendedBadge =>
      _t({'es': 'MÁS POPULAR', 'en': 'MOST POPULAR', 'fr': 'LE PLUS POPULAIRE', 'de': 'AM BELIEBTESTEN', 'ru': 'САМЫЙ ПОПУЛЯРНЫЙ', 'ar': 'الأكثر شيوعًا', 'hi': 'सबसे लोकप्रिय', 'bn': 'সবচেয়ে জনপ্রিয়', 'pt': 'MAIS POPULAR',});
  String get paywallPerWeek => _t({'es': '/semana', 'en': '/wk', 'fr': '/semaine', 'de': '/Woche', 'ru': '/нед', 'ar': '/أسبوع', 'hi': '/हफ्ता', 'bn': '/সপ্তাহ', 'pt': '/sem',});
  String get paywallPerMonth => _t({'es': '/mes', 'en': '/mo', 'fr': '/mois', 'de': '/Monat', 'ru': '/мес', 'ar': '/شهر', 'hi': '/माह', 'bn': '/মাস', 'pt': '/mês',});
  String get paywallPerYear => _t({'es': '/año', 'en': '/yr', 'fr': '/an', 'de': '/Jahr', 'ru': '/год', 'ar': '/سنة', 'hi': '/साल', 'bn': '/বছর', 'pt': '/ano',});
  String get paywallCtaButton => _t({
        'es': 'Empezar prueba gratis de 7 días',
        'en': 'Start 7-day free trial',
        'fr': "Démarrer l'essai gratuit de 7 jours",
        'de': '7 Tage kostenlos testen',
        'ru': 'Начать 7-дневную бесплатную пробную версию',
        'ar': 'بدء التجربة المجانية لمدة 7 أيام', 'hi': '7 दिन का मुफ्त ट्रायल शुरू करें', 'bn': '৭ দিনের ফ্রি ট্রায়াল শুরু করুন', 'pt': 'Começar teste grátis de 7 dias',
      });
  String get paywallRestorePurchases => _t({
        'es': 'Restaurar compras',
        'en': 'Restore purchases',
        'fr': 'Restaurer les achats',
        'de': 'Käufe wiederherstellen',
        'ru': 'Восстановить покупки',
        'ar': 'استعادة المشتريات',
        'hi': 'खरीदारी पुनर्स्थापित करें',
        'bn': 'কেনাকাটা পুনরুদ্ধার করুন',
        'pt': 'Restaurar compras',
      });
  String get paywallTerms => _t({
        'es':
            'La suscripción se renueva automáticamente salvo que la canceles al menos 24h antes de que termine el periodo actual. Puedes cancelar cuando quieras desde los ajustes de tu tienda de aplicaciones.',
        'en':
            'The subscription renews automatically unless cancelled at least 24h before the current period ends. You can cancel anytime from your app store account settings.',
        'fr':
            "L'abonnement se renouvelle automatiquement sauf annulation au moins 24h avant la fin de la période en cours. Vous pouvez annuler à tout moment depuis les paramètres de votre store.",
        'de':
            'Das Abo verlängert sich automatisch, sofern nicht mindestens 24 Stunden vor Ablauf gekündigt wird. Du kannst jederzeit in den Einstellungen deines App Stores kündigen.',
        'ru': 'Подписка продлевается автоматически, если ты не отменишь её минимум за 24 часа до окончания текущего периода. Ты можешь отменить в любой момент в настройках своего аккаунта магазина приложений.',
        'ar': 'يتجدد الاشتراك تلقائيًا ما لم تُلغيه قبل 24 ساعة على الأقل من انتهاء الفترة الحالية. يمكنكِ الإلغاء في أي وقت من إعدادات حساب متجر التطبيقات.',
        'hi': 'सदस्यता स्वचालित रूप से नवीनीकृत हो जाती है जब तक कि आप इसे मौजूदा अवधि समाप्त होने से कम से कम 24 घंटे पहले रद्द न करें। आप अपने ऐप स्टोर खाते की सेटिंग से कभी भी रद्द कर सकती हैं।',
        'bn': 'বর্তমান মেয়াদ শেষ হওয়ার অন্তত ২৪ ঘণ্টা আগে বাতিল না করলে সাবস্ক্রিপশন স্বয়ংক্রিয়ভাবে নবায়ন হয়ে যায়। আপনি যেকোনো সময় আপনার অ্যাপ স্টোর অ্যাকাউন্ট সেটিংস থেকে বাতিল করতে পারেন।',
        'pt': 'A assinatura é renovada automaticamente, a menos que você a cancele pelo menos 24h antes do fim do período atual. Você pode cancelar quando quiser nas configurações da sua conta na loja de aplicativos.',
      });
  String get paywallClose => _t({'es': 'Cerrar', 'en': 'Close', 'fr': 'Fermer', 'de': 'Schließen', 'ru': 'Закрыть', 'ar': 'إغلاق', 'hi': 'बंद करें', 'bn': 'বন্ধ করুন', 'pt': 'Fechar'});
  String get paywallAlreadyPremiumTitle => _t({
        'es': 'Ya tienes Premium ✓',
        'en': 'You already have Premium ✓',
        'fr': 'Vous avez déjà Premium ✓',
        'de': 'Du hast bereits Premium ✓',
        'ru': 'У тебя уже есть Premium ✓',
        'ar': 'لديكِ بالفعل Premium ✓',
        'hi': 'आपके पास पहले से ही Premium है ✓',
        'bn': 'আপনার কাছে ইতিমধ্যে Premium আছে ✓',
        'pt': 'Você já tem Premium ✓',
      });
  String get paywallAlreadyPremiumBody => _t({
        'es': 'Gracias por apoyar CicloPlus. Ya tienes acceso completo a todas las funciones.',
        'en': 'Thanks for supporting CicloPlus. You already have full access to every feature.',
        'fr': 'Merci de soutenir CicloPlus. Vous avez déjà accès à toutes les fonctionnalités.',
        'de': 'Danke, dass du CicloPlus unterstützt. Du hast bereits Zugriff auf alle Funktionen.',
        'ru': 'Спасибо за поддержку CicloPlus. У тебя уже есть полный доступ ко всем функциям.',
        'ar': 'شكرًا لدعمك CicloPlus. لديكِ بالفعل وصول كامل إلى جميع الميزات.',
        'hi': 'CicloPlus का समर्थन करने के लिए धन्यवाद। आपके पास पहले से ही सभी सुविधाओं तक पूरी पहुंच है।',
        'bn': 'CicloPlus-কে সমর্থন করার জন্য ধন্যবাদ। আপনার কাছে ইতিমধ্যে সমস্ত ফিচারের সম্পূর্ণ অ্যাক্সেস আছে।',
        'pt': 'Obrigado por apoiar o CicloPlus. Você já tem acesso completo a todos os recursos.',
      });
  String get paywallLoadingPlans => _t({
        'es': 'Cargando planes…',
        'en': 'Loading plans…',
        'fr': 'Chargement des forfaits…',
        'de': 'Lade Pläne…',
        'ru': 'Загрузка тарифов…',
        'ar': 'جارٍ تحميل الخطط…',
        'hi': 'योजनाएं लोड हो रही हैं…',
        'bn': 'পরিকল্পনা লোড হচ্ছে…',
        'pt': 'Carregando planos…',
      });
  String get paywallNoPlansAvailable => _t({
        'es':
            'Los planes de suscripción todavía no están disponibles. Vuelve a intentarlo más tarde.',
        'en':
            'Subscription plans are not available yet. Please try again later.',
        'fr':
            "Les formules d'abonnement ne sont pas encore disponibles. Réessayez plus tard.",
        'de':
            'Abo-Pläne sind noch nicht verfügbar. Bitte versuche es später erneut.',
        'ru': 'Тарифы подписки пока недоступны. Попробуй снова позже.',
        'ar': 'خطط الاشتراك غير متاحة حاليًا. حاولي مرة أخرى لاحقًا.',
        'hi': 'सदस्यता योजनाएं अभी उपलब्ध नहीं हैं। कृपया बाद में फिर से प्रयास करें।',
        'bn': 'সাবস্ক্রিপশন পরিকল্পনা এখনও উপলব্ধ নয়। অনুগ্রহ করে পরে আবার চেষ্টা করুন।',
        'pt': 'Os planos de assinatura ainda não estão disponíveis. Tente novamente mais tarde.',
      });
  String get paywallPurchaseError => _t({
        'es': 'No se pudo completar la compra. Inténtalo de nuevo.',
        'en': "The purchase couldn't be completed. Please try again.",
        'fr': "L'achat n'a pas pu être finalisé. Veuillez réessayer.",
        'de': 'Der Kauf konnte nicht abgeschlossen werden. Bitte versuche es erneut.',
        'ru': 'Не удалось завершить покупку. Попробуй ещё раз.',
        'ar': 'تعذّر إتمام عملية الشراء. حاولي مرة أخرى.',
        'hi': 'खरीदारी पूरी नहीं हो सकी। कृपया फिर से प्रयास करें।',
        'bn': 'কেনাকাটা সম্পূর্ণ করা যায়নি। আবার চেষ্টা করুন।',
        'pt': 'Não foi possível concluir a compra. Tente novamente.',
      });
  String get paywallPurchaseSuccess => _t({
        'es': '¡Listo! Ya tienes acceso Premium 🎉',
        'en': "You're all set! Premium access unlocked 🎉",
        'fr': "C'est fait ! Accès Premium débloqué 🎉",
        'de': 'Fertig! Premium-Zugang freigeschaltet 🎉',
        'ru': 'Готово! У тебя уже есть доступ Premium 🎉',
        'ar': 'تم! لديكِ الآن وصول Premium 🎉',
        'hi': 'तैयार! अब आपके पास Premium एक्सेस है 🎉',
        'bn': 'হয়ে গেছে! এখন আপনার কাছে Premium অ্যাক্সেস আছে 🎉',
        'pt': 'Pronto! Agora você tem acesso Premium 🎉',
      });
  String get paywallRestoreSuccess => _t({
        'es': 'Compras restauradas correctamente.',
        'en': 'Purchases restored successfully.',
        'fr': 'Achats restaurés avec succès.',
        'de': 'Käufe erfolgreich wiederhergestellt.',
        'ru': 'Покупки успешно восстановлены.',
        'ar': 'تمت استعادة المشتريات بنجاح.',
        'hi': 'खरीदारी सफलतापूर्वक पुनर्स्थापित की गई।',
        'bn': 'কেনাকাটা সফলভাবে পুনরুদ্ধার করা হয়েছে।',
        'pt': 'Compras restauradas com sucesso.',
      });
  String get paywallRestoreNothingFound => _t({
        'es': 'No se encontró ninguna compra previa para restaurar.',
        'en': 'No previous purchase was found to restore.',
        'fr': 'Aucun achat antérieur trouvé à restaurer.',
        'de': 'Es wurde kein vorheriger Kauf zum Wiederherstellen gefunden.',
        'ru': 'Не найдено предыдущих покупок для восстановления.',
        'ar': 'لم يتم العثور على أي عملية شراء سابقة لاستعادتها.',
        'hi': 'पुनर्स्थापित करने के लिए कोई पिछली खरीदारी नहीं मिली।',
        'bn': 'পুনরুদ্ধার করার জন্য কোনো পূর্ববর্তী কেনাকাটা পাওয়া যায়নি।',
        'pt': 'Nenhuma compra anterior foi encontrada para restaurar.',
      });

  // ---- Configuración -> acceso a suscripción ----
  String get settingsSubscriptionTitle =>
      _t({'es': 'Suscripción', 'en': 'Subscription', 'fr': 'Abonnement', 'de': 'Abo', 'ru': 'Подписка', 'ar': 'الاشتراك', 'hi': 'सदस्यता', 'bn': 'সাবস্ক্রিপশন', 'pt': 'Assinatura'});
  String get settingsSubscriptionHint => _t({
        'es': 'Consulta tu prueba gratis o gestiona tu plan Premium.',
        'en': 'Check your free trial or manage your Premium plan.',
        'fr': 'Consultez votre essai gratuit ou gérez votre forfait Premium.',
        'de': 'Prüfe deine kostenlose Testphase oder verwalte deinen Premium-Plan.',
        'ru': 'Проверь свою бесплатную пробную версию или управляй своим тарифом Premium.',
        'ar': 'تحققي من فترتك التجريبية المجانية أو أديري خطة Premium الخاصة بكِ.',
        'hi': 'अपना निःशुल्क परीक्षण देखें या अपनी Premium योजना प्रबंधित करें।',
        'bn': 'আপনার ফ্রি ট্রায়াল দেখুন বা আপনার Premium পরিকল্পনা পরিচালনা করুন।',
        'pt': 'Confira seu teste gratuito ou gerencie seu plano Premium.',
      });
  String get settingsManageSubscription => _t({
        'es': 'Ver planes Premium',
        'en': 'View Premium plans',
        'fr': 'Voir les forfaits Premium',
        'de': 'Premium-Pläne ansehen',
        'ru': 'Посмотреть тарифы Premium',
        'ar': 'عرض خطط Premium',
        'hi': 'Premium योजनाएं देखें',
        'bn': 'Premium পরিকল্পনা দেখুন',
        'pt': 'Ver planos Premium',
      });

  // ==================== Fase 2 del rediseño: catálogos nuevos de ====================
  // ==================== day_entry.dart + pantallas futuras (Hoy/Yo/Registrar/Recordatorio) ====================
  // Mismo patrón que _symptomTable/_flowTable arriba: tabla estática
  // id -> traducción, con un `xLabelFor(id)` que hace fallback al propio id
  // si no se encuentra (nunca debería pasar con los catálogos actuales de
  // day_entry.dart, pero evita crashear si se añade un id nuevo sin
  // traducir todavía).

  // ---- kMoodCatalog (ánimo) ----
  static const Map<String, Map<String, String>> _moodTable = {
    'feliz': {'es': 'Feliz', 'en': 'Happy', 'fr': 'Heureuse', 'de': 'Glücklich', 'ru': 'Счастливая', 'ar': 'سعيدة', 'hi': 'खुश', 'bn': 'খুশি', 'pt': 'Feliz'},
    'enfadada': {'es': 'Enfadada', 'en': 'Angry', 'fr': 'Fâchée', 'de': 'Wütend', 'ru': 'Злая', 'ar': 'غاضبة', 'hi': 'गुस्सा', 'bn': 'রাগান্বিত', 'pt': 'Brava'},
    'enamorada': {'es': 'Enamorada', 'en': 'In love', 'fr': 'Amoureuse', 'de': 'Verliebt', 'ru': 'Влюблённая', 'ar': 'واقعة في الحب', 'hi': 'प्यार में', 'bn': 'প্রেমে পড়া', 'pt': 'Apaixonada'},
    'agotada': {'es': 'Agotada', 'en': 'Exhausted', 'fr': 'Épuisée', 'de': 'Erschöpft', 'ru': 'Изнурённая', 'ar': 'منهكة', 'hi': 'थकी हुई', 'bn': 'ক্লান্ত', 'pt': 'Exausta'},
    'triste': {'es': 'Triste', 'en': 'Sad', 'fr': 'Triste', 'de': 'Traurig', 'ru': 'Грустная', 'ar': 'حزينة', 'hi': 'उदास', 'bn': 'দুঃখিত', 'pt': 'Triste'},
    'deprimida': {'es': 'Deprimida', 'en': 'Down', 'fr': 'Déprimée', 'de': 'Niedergeschlagen', 'ru': 'Подавленная', 'ar': 'مكتئبة', 'hi': 'निराश', 'bn': 'বিষণ্ণ', 'pt': 'Deprimida'},
    'sensible': {'es': 'Sensible', 'en': 'Sensitive', 'fr': 'Sensible', 'de': 'Empfindsam', 'ru': 'Чувствительная', 'ar': 'حساسة', 'hi': 'भावुक', 'bn': 'সংবেদনশীল', 'pt': 'Sensível'},
    'ansiosa': {'es': 'Ansiosa', 'en': 'Anxious', 'fr': 'Anxieuse', 'de': 'Ängstlich', 'ru': 'Тревожная', 'ar': 'قلقة', 'hi': 'चिंतित', 'bn': 'উদ্বিগ্ন', 'pt': 'Ansiosa'},
  };
  String moodLabelFor(String id) => _t(_moodTable[id] ?? {'es': id, 'en': id, 'fr': id, 'de': id, 'ru': id, 'ar': id, 'hi': id, 'bn': id, 'pt': id});

  // ---- kEnergyOptions ----
  static const Map<String, Map<String, String>> _energyTable = {
    'baja': {'es': 'Baja', 'en': 'Low', 'fr': 'Faible', 'de': 'Niedrig', 'ru': 'Низкая', 'ar': 'منخفضة', 'hi': 'कम', 'bn': 'কম', 'pt': 'Baixa'},
    'media': {'es': 'Media', 'en': 'Medium', 'fr': 'Moyenne', 'de': 'Mittel', 'ru': 'Средняя', 'ar': 'متوسطة', 'hi': 'मध्यम', 'bn': 'মাঝারি', 'pt': 'Média'},
    'alta': {'es': 'Alta', 'en': 'High', 'fr': 'Élevée', 'de': 'Hoch', 'ru': 'Высокая', 'ar': 'مرتفعة', 'hi': 'उच्च', 'bn': 'উচ্চ', 'pt': 'Alta'},
    'con_energia': {'es': 'Con energía', 'en': 'Energized', 'fr': 'Pleine d\'énergie', 'de': 'Voller Energie', 'ru': 'Полна энергии', 'ar': 'مليئة بالطاقة', 'hi': 'ऊर्जावान', 'bn': 'উদ্যমী', 'pt': 'Cheia de energia'},
  };
  String energyLabelFor(String id) => _t(_energyTable[id] ?? {'es': id, 'en': id, 'fr': id, 'de': id, 'ru': id, 'ar': id, 'hi': id, 'bn': id, 'pt': id});

  // ---- kBreastSelfExamCatalog (autoexamen de mamas) ----
  static const Map<String, Map<String, String>> _breastSelfExamTable = {
    'normal': {'es': 'Todo en orden', 'en': 'All normal', 'fr': 'Tout va bien', 'de': 'Alles in Ordnung', 'ru': 'Всё в порядке', 'ar': 'كل شيء طبيعي', 'hi': 'सब सामान्य', 'bn': 'সব স্বাভাবিক', 'pt': 'Tudo normal'},
    'congestion': {'es': 'Congestión', 'en': 'Tenderness', 'fr': 'Tension', 'de': 'Spannungsgefühl', 'ru': 'Нагрубание', 'ar': 'احتقان', 'hi': 'कोमलता', 'bn': 'কোমলতা', 'pt': 'Sensibilidade'},
    'bulto': {'es': 'Bulto', 'en': 'Lump', 'fr': 'Grosseur', 'de': 'Knoten', 'ru': 'Уплотнение', 'ar': 'كتلة', 'hi': 'गांठ', 'bn': 'পিণ্ড', 'pt': 'Caroço'},
    'hoyuelo': {'es': 'Hoyuelo', 'en': 'Dimpling', 'fr': 'Capiton', 'de': 'Einziehung', 'ru': 'Втяжение кожи', 'ar': 'انخساف الجلد', 'hi': 'त्वचा में गड्ढा', 'bn': 'ত্বকে গর্ত', 'pt': 'Retração da pele'},
    'irritacion': {'es': 'Irritación de la piel', 'en': 'Skin irritation', 'fr': 'Irritation cutanée', 'de': 'Hautreizung', 'ru': 'Раздражение кожи', 'ar': 'تهيج الجلد', 'hi': 'त्वचा में जलन', 'bn': 'ত্বকের জ্বালা', 'pt': 'Irritação na pele'},
    'pezones_agrietados': {'es': 'Pezones agrietados', 'en': 'Cracked nipples', 'fr': 'Mamelons crevassés', 'de': 'Rissige Brustwarzen', 'ru': 'Трещины на сосках', 'ar': 'تشقق الحلمتين', 'hi': 'फटे हुए निप्पल', 'bn': 'ফাটা স্তনবৃন্ত', 'pt': 'Mamilos rachados'},
    'dolor': {'es': 'Dolor', 'en': 'Pain', 'fr': 'Douleur', 'de': 'Schmerz', 'ru': 'Боль', 'ar': 'ألم', 'hi': 'दर्द', 'bn': 'ব্যথা', 'pt': 'Dor'},
    'secrecion': {'es': 'Secreción del pezón', 'en': 'Nipple discharge', 'fr': 'Écoulement du mamelon', 'de': 'Brustwarzensekret', 'ru': 'Выделения из соска', 'ar': 'إفرازات من الحلمة', 'hi': 'निप्पल से स्राव', 'bn': 'স্তনবৃন্ত থেকে ক্ষরণ', 'pt': 'Secreção no mamilo'},
  };
  String breastSelfExamLabelFor(String id) =>
      _t(_breastSelfExamTable[id] ?? {'es': id, 'en': id, 'fr': id, 'de': id, 'ru': id, 'ar': id, 'hi': id, 'bn': id, 'pt': id});

  // ---- kSkinHairCatalog (piel y cabello) ----
  static const Map<String, Map<String, String>> _skinHairTable = {
    'brillo_saludable': {'es': 'Brillo saludable', 'en': 'Healthy glow', 'fr': 'Éclat sain', 'de': 'Gesunder Glanz', 'ru': 'Здоровое сияние', 'ar': 'إشراقة صحية', 'hi': 'सेहतमंद चमक', 'bn': 'সুস্থ উজ্জ্বলতা', 'pt': 'Brilho saudável'},
    'enrojecimiento': {'es': 'Enrojecimiento', 'en': 'Redness', 'fr': 'Rougeurs', 'de': 'Rötung', 'ru': 'Покраснение', 'ar': 'احمرار', 'hi': 'लालिमा', 'bn': 'লালভাব', 'pt': 'Vermelhidão'},
    'piel_reseca': {'es': 'Piel reseca', 'en': 'Dry skin', 'fr': 'Peau sèche', 'de': 'Trockene Haut', 'ru': 'Сухая кожа', 'ar': 'بشرة جافة', 'hi': 'रूखी त्वचा', 'bn': 'শুষ্ক ত্বক', 'pt': 'Pele seca'},
    'piel_grasa': {'es': 'Piel con grasa', 'en': 'Oily skin', 'fr': 'Peau grasse', 'de': 'Fettige Haut', 'ru': 'Жирная кожа', 'ar': 'بشرة دهنية', 'hi': 'तैलीय त्वचा', 'bn': 'তৈলাক্ত ত্বক', 'pt': 'Pele oleosa'},
    'buen_dia_cabello': {'es': 'Buen día de cabello', 'en': 'Good hair day', 'fr': 'Bonne journée cheveux', 'de': 'Guter Haartag', 'ru': 'Хороший день для волос', 'ar': 'يوم جيد لشعركِ', 'hi': 'अच्छे बालों का दिन', 'bn': 'ভালো চুলের দিন', 'pt': 'Dia de cabelo bom'},
    'mal_dia_cabello': {'es': 'Mal día de cabello', 'en': 'Bad hair day', 'fr': 'Mauvaise journée cheveux', 'de': 'Schlechter Haartag', 'ru': 'Плохой день для волос', 'ar': 'يوم سيئ لشعركِ', 'hi': 'खराब बालों का दिन', 'bn': 'খারাপ চুলের দিন', 'pt': 'Dia de cabelo ruim'},
    'caida_cabello': {'es': 'Caída del cabello', 'en': 'Hair loss', 'fr': 'Chute de cheveux', 'de': 'Haarausfall', 'ru': 'Выпадение волос', 'ar': 'تساقط الشعر', 'hi': 'बाल झड़ना', 'bn': 'চুল পড়া', 'pt': 'Queda de cabelo'},
    'cabello_graso': {'es': 'Cabello con grasa', 'en': 'Greasy hair', 'fr': 'Cheveux gras', 'de': 'Fettiges Haar', 'ru': 'Жирные волосы', 'ar': 'شعر دهني', 'hi': 'तैलीय बाल', 'bn': 'তৈলাক্ত চুল', 'pt': 'Cabelo oleoso'},
  };
  String skinHairLabelFor(String id) => _t(_skinHairTable[id] ?? {'es': id, 'en': id, 'fr': id, 'de': id, 'ru': id, 'ar': id, 'hi': id, 'bn': id, 'pt': id});

  // ---- kMedicationCatalog (medicamentos) ----
  static const Map<String, Map<String, String>> _medicationTable = {
    'analgesico': {'es': 'Analgésico', 'en': 'Painkiller', 'fr': 'Antalgique', 'de': 'Schmerzmittel', 'ru': 'Обезболивающее', 'ar': 'مسكّن ألم', 'hi': 'दर्द निवारक', 'bn': 'ব্যথানাশক', 'pt': 'Analgésico'},
    'anticonceptivo': {'es': 'Anticonceptivo', 'en': 'Birth control', 'fr': 'Contraceptif', 'de': 'Verhütungsmittel', 'ru': 'Контрацептив', 'ar': 'وسيلة منع حمل', 'hi': 'गर्भनिरोधक', 'bn': 'জন্মনিয়ন্ত্রণ', 'pt': 'Anticoncepcional'},
    'antiinflamatorio': {'es': 'Antiinflamatorio', 'en': 'Anti-inflammatory', 'fr': 'Anti-inflammatoire', 'de': 'Entzündungshemmer', 'ru': 'Противовоспалительное', 'ar': 'مضاد للالتهاب', 'hi': 'सूजन-रोधी', 'bn': 'প্রদাহনাশক', 'pt': 'Anti-inflamatório'},
    'vitaminas': {'es': 'Vitaminas', 'en': 'Vitamins', 'fr': 'Vitamines', 'de': 'Vitamine', 'ru': 'Витамины', 'ar': 'فيتامينات', 'hi': 'विटामिन', 'bn': 'ভিটামিন', 'pt': 'Vitaminas'},
    'hierro': {'es': 'Hierro', 'en': 'Iron', 'fr': 'Fer', 'de': 'Eisen', 'ru': 'Железо', 'ar': 'حديد', 'hi': 'आयरन', 'bn': 'আয়রন', 'pt': 'Ferro'},
    'otro': {'es': 'Otro', 'en': 'Other', 'fr': 'Autre', 'de': 'Sonstiges', 'ru': 'Другое', 'ar': 'أخرى', 'hi': 'अन्य', 'bn': 'অন্যান্য', 'pt': 'Outro'},
  };
  String medicationLabelFor(String id) => _t(_medicationTable[id] ?? {'es': id, 'en': id, 'fr': id, 'de': id, 'ru': id, 'ar': id, 'hi': id, 'bn': id, 'pt': id});

  // ---- Vida sexual ampliada (pestaña "Registrar") ----
  String get sexNoneLabel => _t({'es': 'No tuve', 'en': "Didn't have sex", 'fr': "Je n'ai pas eu", 'de': 'Hatte keinen', 'ru': 'Не было секса', 'ar': 'لم يحدث جماع', 'hi': 'सेक्स नहीं किया', 'bn': 'সেক্স করিনি', 'pt': 'Não fiz sexo'});
  String get sexUnprotectedFullLabel => _t({
        'es': 'Sexo sin protección',
        'en': 'Unprotected sex',
        'fr': 'Rapport non protégé',
        'de': 'Ungeschützter Sex',
        'ru': 'Секс без защиты',
        'ar': 'جنس بدون حماية',
        'hi': 'बिना सुरक्षा के सेक्स',
        'bn': 'সুরক্ষা ছাড়া সেক্স',
        'pt': 'Sexo sem proteção',
      });
  String get sexProtectedLabel =>
      _t({'es': 'Sexo protegido', 'en': 'Protected sex', 'fr': 'Rapport protégé', 'de': 'Geschützter Sex', 'ru': 'Защищённый секс', 'ar': 'جنس محمي', 'hi': 'सुरक्षित सेक्स', 'bn': 'সুরক্ষিত সেক্স', 'pt': 'Sexo protegido'});
  String get sexMasturbationLabel =>
      _t({'es': 'Masturbación', 'en': 'Masturbation', 'fr': 'Masturbation', 'de': 'Masturbation', 'ru': 'Мастурбация', 'ar': 'الاستمناء', 'hi': 'हस्तमैथुन', 'bn': 'হস্তমৈথুন', 'pt': 'Masturbação'});
  String get sexNoOrgasmLabel =>
      _t({'es': 'Sin orgasmo', 'en': 'No orgasm', 'fr': 'Sans orgasme', 'de': 'Kein Orgasmus', 'ru': 'Без оргазма', 'ar': 'بدون نشوة', 'hi': 'बिना चरमसुख के', 'bn': 'অর্গাজম ছাড়া', 'pt': 'Sem orgasmo'});
  String get sexOrgasmLabel => _t({'es': 'Orgasmo', 'en': 'Orgasm', 'fr': 'Orgasme', 'de': 'Orgasmus', 'ru': 'Оргазм', 'ar': 'نشوة', 'hi': 'चरमसुख', 'bn': 'অর্গাজম', 'pt': 'Orgasmo'});
  String get sexDesireLabel =>
      _t({'es': 'Deseo sexual', 'en': 'Sex drive', 'fr': 'Désir sexuel', 'de': 'Sexuelles Verlangen', 'ru': 'Сексуальное желание', 'ar': 'الرغبة الجنسية', 'hi': 'यौन इच्छा', 'bn': 'যৌন আকাঙ্ক্ষা', 'pt': 'Desejo sexual'});
  String sexTimesLabel(int n) =>
      _t({'es': 'Veces: $n', 'en': 'Times: $n', 'fr': 'Fois : $n', 'de': 'Male: $n', 'ru': 'Раз: $n', 'ar': 'عدد المرات: $n', 'hi': 'बार: $n', 'bn': 'বার: $n', 'pt': 'Vezes: $n'});
  /// Etiqueta corta "Veces" (sin el número), usada en la tarjeta oscura
  /// "Total encuentros" del rediseño de Vida sexual (aprobado en Lovable
  /// 2026-08-16) — ahí el número va aparte, grande, junto a los botones -/+.
  String get sexTimesShortLabel => _t({'es': 'Veces', 'en': 'Times', 'fr': 'Fois', 'de': 'Male', 'ru': 'Раз', 'ar': 'عدد المرات', 'hi': 'बार', 'bn': 'বার', 'pt': 'Vezes'});
  /// Título de la tarjeta oscura que agrupa el contador de "Veces" en el
  /// nuevo diseño de Vida sexual.
  String get sexTimesTotalLabel =>
      _t({'es': 'Total encuentros', 'en': 'Total encounters', 'fr': 'Total des rencontres', 'de': 'Gesamt', 'ru': 'Всего встреч', 'ar': 'إجمالي اللقاءات', 'hi': 'कुल मिलन', 'bn': 'মোট মিলন', 'pt': 'Total de encontros'});
  /// Badge pequeño junto al título "Vida sexual" en el nuevo diseño,
  /// indicando que esta tarjeta es de registro (vs. solo lectura).
  String get sexLifeRegistroBadge => _t({'es': 'Registro', 'en': 'Log', 'fr': 'Journal', 'de': 'Eintrag', 'ru': 'Запись', 'ar': 'السجل', 'hi': 'रिकॉर्ड', 'bn': 'রেকর্ড', 'pt': 'Registro'});

  // ---- Pantalla "Registrar" (register_screen.dart, fase 4 del rediseño) ----
  // Títulos de sección para los catálogos nuevos de day_entry.dart
  // (mood/energy/breastSelfExam/skinHair/medication) que no tenían un
  // título visible de sección todavía (solo los `xLabelFor(id)` de cada
  // chip individual, ya definidos arriba).
  String get medicationSectionTitle =>
      _t({'es': 'Medicamento', 'en': 'Medication', 'fr': 'Médicament', 'de': 'Medikament', 'ru': 'Лекарство', 'ar': 'الدواء', 'hi': 'दवा', 'bn': 'ওষুধ', 'pt': 'Medicamento',});
  String get medicationAddButton =>
      _t({'es': 'Añadir medicamento', 'en': 'Add medication', 'fr': 'Ajouter un médicament', 'de': 'Medikament hinzufügen', 'ru': 'Добавить лекарство', 'ar': 'إضافة دواء', 'hi': 'दवा जोड़ें', 'bn': 'ওষুধ যোগ করুন', 'pt': 'Adicionar medicamento',});
  String get medicationDialogTitle =>
      _t({'es': 'Añadir medicamento', 'en': 'Add medication', 'fr': 'Ajouter un médicament', 'de': 'Medikament hinzufügen', 'ru': 'Добавить лекарство', 'ar': 'إضافة دواء', 'hi': 'दवा जोड़ें', 'bn': 'ওষুধ যোগ করুন', 'pt': 'Adicionar medicamento',});
  String get medicationCustomHint => _t({
        'es': 'O escribe uno distinto',
        'en': 'Or type a different one',
        'fr': 'Ou saisissez-en un autre',
        'de': 'Oder gib ein anderes ein',
        'ru': 'Или напиши другое',
        'ar': 'أو اكتبي دواءً آخر', 'hi': 'या कोई और लिखें', 'bn': 'অথবা অন্য কিছু লিখুন', 'pt': 'Ou digite um diferente',
      });
  // Rediseño editorial del sheet "Añadir medicamento" (Claude Visualize,
  // 2026-08-16): eyebrow pequeño + pregunta grande en vez de un título de
  // diálogo plano.
  String get medicationSheetEyebrow =>
      _t({'es': 'Botiquín', 'en': 'Medicine cabinet', 'fr': 'Armoire à pharmacie', 'de': 'Hausapotheke', 'ru': 'Аптечка', 'ar': 'خزانة الأدوية', 'hi': 'दवाइयों की किट', 'bn': 'ওষুধের বাক্স', 'pt': 'Armário de remédios',});
  String get medicationSheetQuestion =>
      _t({'es': '¿Qué tomaste hoy?', 'en': 'What did you take today?', 'fr': "Qu'avez-vous pris aujourd'hui ?", 'de': 'Was hast du heute genommen?', 'ru': 'Что ты приняла сегодня?', 'ar': 'ماذا تناولتِ اليوم؟', 'hi': 'आपने आज क्या लिया?', 'bn': 'আজ আপনি কী নিয়েছেন?', 'pt': 'O que você tomou hoje?',});
  String get medicationSheetCustomLabel => _t({
        'es': 'O escribe el nombre exacto',
        'en': 'Or type the exact name',
        'fr': 'Ou saisissez le nom exact',
        'de': 'Oder gib den genauen Namen ein',
        'ru': 'Или напиши точное название',
        'ar': 'أو اكتبي الاسم الدقيق', 'hi': 'या सटीक नाम लिखें', 'bn': 'অথবা সঠিক নাম লিখুন', 'pt': 'Ou digite o nome exato',
      });
  String get medicationSheetSave =>
      _t({'es': 'Guardar medicamento', 'en': 'Save medication', 'fr': 'Enregistrer le médicament', 'de': 'Medikament speichern', 'ru': 'Сохранить лекарство', 'ar': 'حفظ الدواء', 'hi': 'दवा सेव करें', 'bn': 'ওষুধ সংরক্ষণ করুন', 'pt': 'Salvar medicamento',});
  String get medicationEmpty => _t({
        'es': 'Aún no añadiste ningún medicamento hoy.',
        'en': "You haven't added any medication today yet.",
        'fr': "Vous n'avez pas encore ajouté de médicament aujourd'hui.",
        'de': 'Du hast heute noch kein Medikament hinzugefügt.',
        'ru': 'Ты ещё не добавила ни одного лекарства сегодня.',
        'ar': 'لم تُضيفي أي دواء اليوم بعد.', 'hi': 'आपने आज तक कोई दवा नहीं जोड़ी है।', 'bn': 'আপনি আজ এখনো কোনো ওষুধ যোগ করেননি।', 'pt': 'Você ainda não adicionou nenhum medicamento hoje.',
      });
  String get moodSectionTitle => _t({'es': 'Ánimo', 'en': 'Mood', 'fr': 'Humeur', 'de': 'Stimmung', 'ru': 'Настроение', 'ar': 'المزاج', 'hi': 'मूड', 'bn': 'মেজাজ', 'pt': 'Humor',});
  String get breastSelfExamSectionTitle => _t({
        'es': 'Autoexamen de mamas',
        'en': 'Breast self-exam',
        'fr': 'Auto-examen des seins',
        'de': 'Brustselbstuntersuchung',
        'ru': 'Самообследование груди',
        'ar': 'الفحص الذاتي للثدي', 'hi': 'स्तन स्व-परीक्षण', 'bn': 'স্তন স্ব-পরীক্ষা', 'pt': 'Autoexame das mamas',
      });
  String get energySectionTitle => _t({'es': 'Energía', 'en': 'Energy', 'fr': 'Énergie', 'de': 'Energie', 'ru': 'Энергия', 'ar': 'الطاقة', 'hi': 'ऊर्जा', 'bn': 'শক্তি', 'pt': 'Energia',});
  String get registerOptionalSectionLabel => _t({'es': 'Opcional', 'en': 'Optional', 'fr': 'Optionnel', 'de': 'Optional', 'ru': 'Дополнительно', 'ar': 'اختياري', 'hi': 'वैकल्पिक', 'bn': 'ঐচ্ছিক', 'pt': 'Opcional',});
  String get skinHairSectionTitle =>
      _t({'es': 'Piel y cabello', 'en': 'Skin and hair', 'fr': 'Peau et cheveux', 'de': 'Haut und Haare', 'ru': 'Кожа и волосы', 'ar': 'البشرة والشعر', 'hi': 'त्वचा और बाल', 'bn': 'ত্বক ও চুল', 'pt': 'Pele e cabelo',});
  String get registerSavedConfirm => _t({
        'es': 'Registro de hoy guardado.',
        'en': "Today's log has been saved.",
        'fr': "L'enregistrement du jour a été sauvegardé.",
        'de': 'Der heutige Eintrag wurde gespeichert.',
        'ru': 'Сегодняшняя запись сохранена.',
        'ar': 'تم حفظ سجل اليوم.', 'hi': 'आज का रिकॉर्ड सेव हो गया है।', 'bn': 'আজকের লগ সংরক্ষিত হয়েছে।', 'pt': 'O registro de hoje foi salvo.',
      });

  // ---- Pestañas nuevas (main_tab_screen.dart, fase futura) ----
  String get tabToday => _t({'es': 'Hoy', 'en': 'Today', 'fr': "Aujourd'hui", 'de': 'Heute', 'ru': 'Сегодня', 'ar': 'اليوم', 'hi': 'आज', 'bn': 'আজ', 'pt': 'Hoje',});
  String get tabLog => _t({'es': 'Registrar', 'en': 'Log', 'fr': 'Enregistrer', 'de': 'Eintragen', 'ru': 'Записать', 'ar': 'تسجيل', 'hi': 'रिकॉर्ड करें', 'bn': 'লগ করুন', 'pt': 'Registrar',});
  String get tabReminder => _t({'es': 'Recordatorio', 'en': 'Reminder', 'fr': 'Rappel', 'de': 'Erinnerung', 'ru': 'Напоминание', 'ar': 'تذكير', 'hi': 'रिमाइंडर', 'bn': 'রিমাইন্ডার', 'pt': 'Lembrete',});
  String get tabMe => _t({'es': 'Yo', 'en': 'Me', 'fr': 'Moi', 'de': 'Ich', 'ru': 'Я', 'ar': 'أنا', 'hi': 'मैं', 'bn': 'আমি', 'pt': 'Eu',});

  // ---- Pantalla "Hoy" ----
  String get todayDayLabel => _t({'es': 'Día', 'en': 'Day', 'fr': 'Jour', 'de': 'Tag', 'ru': 'День', 'ar': 'اليوم', 'hi': 'दिन', 'bn': 'দিন', 'pt': 'Dia',});
  String todayOvulationInDays(int n) => _t({
        'es': 'Ovulación: faltan $n días',
        'en': 'Ovulation: $n days left',
        'fr': 'Ovulation : $n jours restants',
        'de': 'Eisprung: noch $n Tage',
        'ru': 'Овуляция: осталось $n дн.',
        'ar': 'الإباضة: تبقى $n أيام', 'hi': 'ओव्यूलेशन: $n दिन बाकी', 'bn': 'ডিম্বস্ফোটন: বাকি $n দিন', 'pt': 'Ovulação: faltam $n dias',
      });
  String get todayPeriodEnd =>
      _t({'es': 'Fin del período', 'en': 'End of period', 'fr': 'Fin des règles', 'de': 'Ende der Periode', 'ru': 'Конец менструации', 'ar': 'نهاية الدورة', 'hi': 'पीरियड का अंत', 'bn': 'পিরিয়ডের শেষ', 'pt': 'Fim do período',});
  String get todayBodyStageHeader =>
      _t({'es': 'ETAPA CORPORAL', 'en': 'BODY STAGE', 'fr': 'ÉTAPE CORPORELLE', 'de': 'KÖRPERPHASE', 'ru': 'ЭТАП ТЕЛА', 'ar': 'مرحلة الجسم', 'hi': 'शरीर का चरण', 'bn': 'শরীরের পর্যায়', 'pt': 'ESTÁGIO CORPORAL',});
  String get todayCycleDayHeader =>
      _t({'es': 'DÍA DEL CICLO', 'en': 'CYCLE DAY', 'fr': 'JOUR DU CYCLE', 'de': 'ZYKLUSTAG', 'ru': 'ДЕНЬ ЦИКЛА', 'ar': 'يوم الدورة', 'hi': 'चक्र का दिन', 'bn': 'চক্রের দিন', 'pt': 'DIA DO CICLO',});
  String get todayStageMenstrual => _t({
        'es': 'Estás en la primera fase de tu ciclo - período',
        'en': "You're in the first phase of your cycle - period",
        'fr': 'Vous êtes dans la première phase de votre cycle - règles',
        'de': 'Du bist in der ersten Phase deines Zyklus - Periode',
        'ru': 'Ты на первой фазе своего цикла - менструация',
        'ar': 'أنتِ في المرحلة الأولى من دورتك - الحيض', 'hi': 'आप अपने चक्र के पहले चरण में हैं - पीरियड', 'bn': 'আপনি আপনার চক্রের প্রথম পর্যায়ে আছেন - পিরিয়ড', 'pt': 'Você está na primeira fase do seu ciclo - período',
      });
  String get todayStageFollicular => _t({
        'es': 'Estás en la fase folicular de tu ciclo',
        'en': "You're in the follicular phase of your cycle",
        'fr': 'Vous êtes dans la phase folliculaire de votre cycle',
        'de': 'Du bist in der follikulären Phase deines Zyklus',
        'ru': 'Ты на фолликулярной фазе своего цикла',
        'ar': 'أنتِ في المرحلة الجريبية من دورتك', 'hi': 'आप अपने चक्र के फॉलिक्युलर चरण में हैं', 'bn': 'আপনি আপনার চক্রের ফলিকুলার পর্যায়ে আছেন', 'pt': 'Você está na fase folicular do seu ciclo',
      });
  String get todayStageOvulation => _t({
        'es': 'Estás en la ventana fértil de tu ciclo - ovulación',
        'en': "You're in the fertile window of your cycle - ovulation",
        'fr': 'Vous êtes dans la fenêtre fertile de votre cycle - ovulation',
        'de': 'Du bist im fruchtbaren Fenster deines Zyklus - Eisprung',
        'ru': 'Ты в фертильном окне своего цикла - овуляция',
        'ar': 'أنتِ في نافذة الخصوبة من دورتك - الإباضة', 'hi': 'आप अपने चक्र की उपजाऊ अवधि में हैं - ओव्यूलेशन', 'bn': 'আপনি আপনার চক্রের উর্বর সময়কালে আছেন - ডিম্বস্ফোটন', 'pt': 'Você está na janela fértil do seu ciclo - ovulação',
      });
  String get todayStageLuteal => _t({
        'es': 'Estás en la fase lútea de tu ciclo',
        'en': "You're in the luteal phase of your cycle",
        'fr': 'Vous êtes dans la phase lutéale de votre cycle',
        'de': 'Du bist in der Lutealphase deines Zyklus',
        'ru': 'Ты на лютеиновой фазе своего цикла',
        'ar': 'أنتِ في المرحلة الأصفرية من دورتك', 'hi': 'आप अपने चक्र के ल्यूटियल चरण में हैं', 'bn': 'আপনি আপনার চক্রের লুটিয়াল পর্যায়ে আছেন', 'pt': 'Você está na fase lútea do seu ciclo',
      });
  String get todaySyncPartner => _t({
        'es': 'Sincroniza tu ritmo y tus momentos con tu pareja',
        'en': 'Sync your rhythm and moments with your partner',
        'fr': 'Synchronisez votre rythme et vos moments avec votre partenaire',
        'de': 'Synchronisiere deinen Rhythmus und deine Momente mit deiner Partnerin/deinem Partner',
        'ru': 'Синхронизируй свой ритм и моменты со своим партнёром',
        'ar': 'شاركي إيقاعكِ ولحظاتكِ مع شريككِ', 'hi': 'अपनी लय और पलों को अपने पार्टनर के साथ सिंक करें', 'bn': 'আপনার ছন্দ ও মুহূর্তগুলো আপনার পার্টনারের সাথে সিঙ্ক করুন', 'pt': 'Sincronize seu ritmo e seus momentos com seu parceiro(a)',
      });
  String get todayInvitePartner =>
      _t({'es': 'Invitar a un socio', 'en': 'Invite a partner', 'fr': 'Inviter un(e) partenaire', 'de': 'Partner:in einladen', 'ru': 'Пригласить партнёра', 'ar': 'دعوة شريك', 'hi': 'पार्टनर को आमंत्रित करें', 'bn': 'পার্টনারকে আমন্ত্রণ জানান', 'pt': 'Convidar um parceiro(a)',});
  String get todayHighFertility => _t({
        'es': 'Alta - posibilidad de quedar embarazada',
        'en': 'High - chance of getting pregnant',
        'fr': 'Élevée - possibilité de tomber enceinte',
        'de': 'Hoch - Schwangerschaftswahrscheinlichkeit',
        'ru': 'Высокая - вероятность забеременеть',
        'ar': 'مرتفعة - احتمال الحمل', 'hi': 'उच्च - गर्भवती होने की संभावना', 'bn': 'উচ্চ - গর্ভবতী হওয়ার সম্ভাবনা', 'pt': 'Alta - chance de engravidar',
      });
  // ---- Leyenda del slider de ovulación (fase 8, pulido visual) ----
  String get todayLegendPeriod => _t({'es': 'Período', 'en': 'Period', 'fr': 'Règles', 'de': 'Periode', 'ru': 'Менструация', 'ar': 'الدورة', 'hi': 'पीरियड', 'bn': 'পিরিয়ড', 'pt': 'Período',});
  // Etiqueta de la leyenda de la tarjeta de ovulación (_OvulationSliderCard)
  // que reemplaza a "Período" por pedido explícito de la usuaria ("que
  // esté dentro de etapa corporal... con gráfico"), acompañada del dibujo
  // anatómico UterusPhaseIllustration en vez del punto de color plano.
  String get todayLegendBodyStage => _t({
        'es': 'Etapa corporal',
        'en': 'Body stage',
        'fr': 'Étape corporelle',
        'de': 'Körperphase',
        'ru': 'Этап тела',
        'ar': 'مرحلة الجسم',
        'hi': 'शरीर का चरण',
        'bn': 'শরীরের পর্যায়',
        'pt': 'Estágio corporal',
      });
  String get todayLegendFertile => _t({'es': 'Fértil', 'en': 'Fertile', 'fr': 'Fertile', 'de': 'Fruchtbar', 'ru': 'Фертильный', 'ar': 'خصوبة', 'hi': 'उपजाऊ', 'bn': 'উর্বর', 'pt': 'Fértil',});
  String get todayLegendOvulation => _t({'es': 'Ovulación', 'en': 'Ovulation', 'fr': 'Ovulation', 'de': 'Eisprung', 'ru': 'Овуляция', 'ar': 'الإباضة', 'hi': 'ओव्यूलेशन', 'bn': 'ডিম্বস্ফোটন', 'pt': 'Ovulação',});
  String get todayHowDoYouFeel =>
      _t({'es': '¿Cómo te sientes hoy?', 'en': 'How do you feel today?', 'fr': 'Comment vous sentez-vous aujourd\'hui ?', 'de': 'Wie fühlst du dich heute?', 'ru': 'Как ты себя чувствуешь сегодня?', 'ar': 'كيف تشعرين اليوم؟', 'hi': 'आज आप कैसा महसूस कर रहे हैं?', 'bn': 'আজ আপনি কেমন অনুভব করছেন?', 'pt': 'Como você está se sentindo hoje?',});
  // Días que quedan del período actual, mostrados dentro de la tarjeta
  // "Tu jardín" (pedido explícito de la usuaria de que esa información de
  // "cuánto queda" viva ahí) — solo aparece cuando hoy es día de período.
  String todayGardenDaysLeft(int n) => _t({
        'es': 'Quedan $n días de período',
        'en': '$n days of period left',
        'fr': 'Il reste $n jours de règles',
        'de': 'Noch $n Tage der Periode',
        'ru': 'Осталось $n дн. менструации',
        'ar': 'تبقى $n أيام من الدورة',
        'hi': 'पीरियड के $n दिन बाकी हैं',
        'bn': 'পিরিয়ডের $n দিন বাকি',
        'pt': 'Faltam $n dias de período',
      });
  // Encabezado pequeño de la tarjeta "Tu jardín" (ver
  // TodayScreen._buildGardenCard) — también le faltaba al catálogo.
  String get todayGardenHeader => _t({
        'es': 'TU JARDÍN',
        'en': 'YOUR GARDEN',
        'fr': 'TON JARDIN',
        'de': 'DEIN GARTEN',
        'ru': 'ВАШ САД',
        'ar': 'حديقتك',
        'hi': 'आपका बगीचा',
        'bn': 'আপনার বাগান',
        'pt': 'SEU JARDIM',
      });
  // Texto de cada etapa de la tarjeta "Tu jardín" (ver
  // TodayScreen._buildGardenCard / gardenStageIndex en garden_stage.dart):
  // 0 = muerta (varios días sin abrir la app) hasta 4 = floración máxima
  // (racha larga y activa). Le faltaban estos 5 al catálogo, causaba
  // error de compilación ("getter no definido").
  String get todayGardenStageDead => _t({
        'es': 'Tus flores se marchitaron por completo. Abre la app cada día para revivirlas.',
        'en': 'Your flowers have completely wilted. Open the app every day to bring them back.',
        'fr': 'Tes fleurs ont complètement fané. Ouvre l\'appli chaque jour pour les faire revivre.',
        'de': 'Deine Blumen sind komplett verwelkt. Öffne die App jeden Tag, um sie wiederzubeleben.',
        'ru': 'Ваши цветы полностью увяли. Открывайте приложение каждый день, чтобы оживить их.',
        'ar': 'ذبلت أزهارك تمامًا. افتحي التطبيق كل يوم لإحيائها من جديد.',
        'hi': 'आपके फूल पूरी तरह मुरझा गए हैं। उन्हें फिर से जीवित करने के लिए हर दिन ऐप खोलें।',
        'bn': 'আপনার ফুলগুলো সম্পূর্ণ শুকিয়ে গেছে। সেগুলো আবার জীবিত করতে প্রতিদিন অ্যাপ খুলুন।',
        'pt': 'Suas flores murcharam completamente. Abra o app todos os dias para reanimá-las.',
      });
  // Antes decía "llevas varios días sin abrir la app", pero esta etapa
  // (1) también aparece con una racha corta recién empezada y CERO días
  // sin abrir (ver gardenStageIndex en garden_stage.dart) — la usuaria
  // reportó que el mensaje mentía ("dice que llevo varios días sin
  // abrir, eso es mentira"). Se quita la afirmación de un número de días
  // y se deja un mensaje que vale tanto si hay racha corta como si hay
  // ausencia real.
  String get todayGardenStageWilting => _t({
        'es': 'Tus flores se están marchitando. Ábrela hoy para ayudarlas a recuperarse.',
        'en': 'Your flowers are wilting. Open the app today to help them recover.',
        'fr': 'Tes fleurs fanent. Ouvre l\'appli aujourd\'hui pour les aider à se rétablir.',
        'de': 'Deine Blumen verwelken. Öffne die App heute, damit sie sich erholen.',
        'ru': 'Ваши цветы вянут. Откройте приложение сегодня, чтобы помочь им восстановиться.',
        'ar': 'أزهارك بدأت تذبل. افتحي التطبيق اليوم لمساعدتها على التعافي.',
        'hi': 'आपके फूल मुरझा रहे हैं। उन्हें ठीक होने में मदद के लिए आज ऐप खोलें।',
        'bn': 'আপনার ফুলগুলো শুকিয়ে যাচ্ছে। সেগুলো সুস্থ করতে আজই অ্যাপ খুলুন।',
        'pt': 'Suas flores estão murchando. Abra o app hoje para ajudá-las a se recuperar.',
      });
  String get todayGardenStageNormal => _t({
        'es': 'Tus flores están creciendo bien. Sigue abriendo la app cada día.',
        'en': 'Your flowers are growing well. Keep opening the app every day.',
        'fr': 'Tes fleurs poussent bien. Continue d\'ouvrir l\'appli chaque jour.',
        'de': 'Deine Blumen wachsen gut. Öffne die App weiterhin jeden Tag.',
        'ru': 'Ваши цветы хорошо растут. Продолжайте открывать приложение каждый день.',
        'ar': 'أزهارك تنمو بشكل جيد. واصلي فتح التطبيق كل يوم.',
        'hi': 'आपके फूल अच्छी तरह बढ़ रहे हैं। हर दिन ऐप खोलना जारी रखें।',
        'bn': 'আপনার ফুলগুলো ভালোভাবে বাড়ছে। প্রতিদিন অ্যাপ খোলা চালিয়ে যান।',
        'pt': 'Suas flores estão crescendo bem. Continue abrindo o app todos os dias.',
      });
  String get todayGardenStageHealthy => _t({
        'es': 'Tus flores están saludables gracias a tu racha.',
        'en': 'Your flowers are healthy thanks to your streak.',
        'fr': 'Tes fleurs sont en bonne santé grâce à ta série.',
        'de': 'Deine Blumen sind dank deiner Serie gesund.',
        'ru': 'Ваши цветы здоровы благодаря вашей серии.',
        'ar': 'أزهارك بصحة جيدة بفضل تتابعك اليومي.',
        'hi': 'आपकी लगातार आदत की वजह से आपके फूल स्वस्थ हैं।',
        'bn': 'আপনার ধারাবাহিকতার কারণে আপনার ফুলগুলো সুস্থ আছে।',
        'pt': 'Suas flores estão saudáveis graças à sua sequência.',
      });
  String get todayGardenStageBloom => _t({
        'es': '¡Tus flores están en plena floración! Sigue así.',
        'en': 'Your flowers are in full bloom! Keep it up.',
        'fr': 'Tes fleurs sont en pleine floraison ! Continue comme ça.',
        'de': 'Deine Blumen stehen in voller Blüte! Weiter so.',
        'ru': 'Ваши цветы в полном цвету! Продолжайте в том же духе.',
        'ar': 'أزهارك في أوج تفتحها! استمري هكذا.',
        'hi': 'आपके फूल पूरी तरह खिल गए हैं! ऐसे ही जारी रखें।',
        'bn': 'আপনার ফুলগুলো পুরোপুরি ফুটেছে! এভাবেই চালিয়ে যান।',
        'pt': 'Suas flores estão em plena floração! Continue assim.',
      });
  String get todayTellUsMore => _t({
        'es': 'Cuéntanos más sobre tu cuerpo para realizar el análisis',
        'en': 'Tell us more about your body to run the analysis',
        'fr': 'Parlez-nous en plus de votre corps pour réaliser l\'analyse',
        'de': 'Erzähl uns mehr über deinen Körper für die Auswertung',
        'ru': 'Расскажи нам больше о своём теле, чтобы провести анализ',
        'ar': 'أخبرينا المزيد عن جسمكِ لإجراء التحليل', 'hi': 'विश्लेषण करने के लिए अपने शरीर के बारे में हमें और बताएं', 'bn': 'বিশ্লেষণ করতে আপনার শরীর সম্পর্কে আমাদের আরও বলুন', 'pt': 'Conte mais sobre seu corpo para fazermos a análise',
      });
  String get todayAddSymptom =>
      _t({'es': 'Añadir síntoma', 'en': 'Add symptom', 'fr': 'Ajouter un symptôme', 'de': 'Symptom hinzufügen', 'ru': 'Добавить симптом', 'ar': 'إضافة عرض', 'hi': 'लक्षण जोड़ें', 'bn': 'লক্ষণ যোগ করুন', 'pt': 'Adicionar sintoma',});

  // ---- Pantalla "Etapa corporal" (detalle de día + probabilidad de
  // concepción), abierta al tocar la tarjeta "ETAPA CORPORAL" de Hoy ----
  String get bodyStageDayLabel =>
      _t({'es': 'Día del ciclo', 'en': 'Cycle day', 'fr': 'Jour du cycle', 'de': 'Zyklustag', 'ru': 'День цикла', 'ar': 'يوم الدورة', 'hi': 'चक्र का दिन', 'bn': 'চক্রের দিন', 'pt': 'Dia do ciclo',});
  String get bodyStageHide => _t({'es': 'Ocultar', 'en': 'Hide', 'fr': 'Masquer', 'de': 'Ausblenden', 'ru': 'Скрыть', 'ar': 'إخفاء', 'hi': 'छिपाएं', 'bn': 'লুকান', 'pt': 'Ocultar',});
  String get bodyStageSeeMore => _t({'es': 'Ver más', 'en': 'See more', 'fr': 'Voir plus', 'de': 'Mehr anzeigen', 'ru': 'Смотреть больше', 'ar': 'عرض المزيد', 'hi': 'और देखें', 'bn': 'আরও দেখুন', 'pt': 'Ver mais',});
  String get bodyStageSymptomsHeader =>
      _t({'es': 'Síntomas posibles', 'en': 'Possible symptoms', 'fr': 'Symptômes possibles', 'de': 'Mögliche Symptome', 'ru': 'Возможные симптомы', 'ar': 'الأعراض المحتملة', 'hi': 'संभावित लक्षण', 'bn': 'সম্ভাব্য লক্ষণ', 'pt': 'Possíveis sintomas'});
  // ---- Slider arrastrable de la tarjeta de ovulación en Hoy
  // (_buildOvulationCard) — al arrastrar el marcador se muestra la fecha y
  // el día del ciclo seleccionado en vez de la fecha de ovulación fija. ----
  String todayOvulationCardDateAndDay(String date, int day) => _t({
        'es': '$date - Día del Ciclo: $day',
        'en': '$date - Cycle Day: $day',
        'fr': '$date - Jour du cycle : $day',
        'de': '$date - Zyklustag: $day',
        'ru': '$date - День цикла: $day',
        'ar': '$date - يوم الدورة: $day',
        'hi': '$date - चक्र का दिन: $day',
        'bn': '$date - চক্রের দিন: $day',
        'pt': '$date - Dia do ciclo: $day',
      });
  String todayOvulationCardDayPill(int day) => _t({
        'es': 'Día $day',
        'en': 'Day $day',
        'fr': 'Jour $day',
        'de': 'Tag $day',
        'ru': 'День $day',
        'ar': 'اليوم $day',
        'hi': 'दिन $day',
        'bn': 'দিন $day',
        'pt': 'Dia $day',
      });
  String get bodyStageConceptionProbability => _t({
        'es': 'Probabilidad de concepción',
        'en': 'Chance of conception',
        'fr': 'Probabilité de conception',
        'de': 'Empfängniswahrscheinlichkeit',
        'ru': 'Вероятность зачатия',
        'ar': 'احتمال الحمل',
        'hi': 'गर्भधारण की संभावना',
        'bn': 'গর্ভধারণের সম্ভাবনা',
        'pt': 'Probabilidade de concepção',
      });
  String get bodyStageLowProbability => _t({'es': 'Baja', 'en': 'Low', 'fr': 'Faible', 'de': 'Niedrig', 'ru': 'Низкая', 'ar': 'منخفضة', 'hi': 'कम', 'bn': 'কম', 'pt': 'Baixa'});
  String get bodyStageMediumProbability => _t({'es': 'Media', 'en': 'Medium', 'fr': 'Moyenne', 'de': 'Mittel', 'ru': 'Средняя', 'ar': 'متوسطة', 'hi': 'मध्यम', 'bn': 'মাঝারি', 'pt': 'Média'});
  String get bodyStageHighProbability => _t({'es': 'Alta', 'en': 'High', 'fr': 'Élevée', 'de': 'Hoch', 'ru': 'Высокая', 'ar': 'مرتفعة', 'hi': 'उच्च', 'bn': 'উচ্চ', 'pt': 'Alta'});
  String get bodyStageToday => _t({'es': 'Hoy', 'en': 'Today', 'fr': "Aujourd'hui", 'de': 'Heute', 'ru': 'Сегодня', 'ar': 'اليوم', 'hi': 'आज', 'bn': 'আজ', 'pt': 'Hoje'});

  String get bodyStageLowProbabilityText => _t({
        'es': 'En estos días la probabilidad de quedar embarazada es baja. Es un buen momento para relajarte y escuchar a tu cuerpo.',
        'en': 'On these days the chance of getting pregnant is low. It\'s a good time to relax and listen to your body.',
        'fr': 'Ces jours-ci, la probabilité de tomber enceinte est faible. C\'est un bon moment pour vous détendre et écouter votre corps.',
        'de': 'An diesen Tagen ist die Schwangerschaftswahrscheinlichkeit niedrig. Ein guter Moment, um zu entspannen und auf deinen Körper zu hören.',
        'ru': 'В эти дни вероятность забеременеть низкая. Хорошее время, чтобы расслабиться и прислушаться к своему телу.',
        'ar': 'في هذه الأيام يكون احتمال الحمل منخفضًا. إنه وقت جيد للاسترخاء والاستماع لجسمكِ.',
        'hi': 'इन दिनों गर्भवती होने की संभावना कम होती है। यह आराम करने और अपने शरीर की सुनने का अच्छा समय है।',
        'bn': 'এই দিনগুলোতে গর্ভবতী হওয়ার সম্ভাবনা কম থাকে। এটি বিশ্রাম নেওয়ার এবং নিজের শরীরের কথা শোনার ভালো সময়।',
        'pt': 'Nesses dias a chance de engravidar é baixa. É um bom momento para relaxar e ouvir seu corpo.',
      });
  String get bodyStageMediumProbabilityText => _t({
        'es': 'Te estás acercando a tu ventana fértil. La probabilidad de concepción empieza a subir, así que presta atención a los cambios de tu cuerpo.',
        'en': 'You\'re getting closer to your fertile window. The chance of conception is starting to rise, so pay attention to your body\'s changes.',
        'fr': 'Vous vous approchez de votre fenêtre de fertilité. La probabilité de conception commence à augmenter, alors soyez attentive aux changements de votre corps.',
        'de': 'Du näherst dich deinem fruchtbaren Fenster. Die Empfängniswahrscheinlichkeit beginnt zu steigen, achte also auf die Veränderungen deines Körpers.',
        'ru': 'Ты приближаешься к своему фертильному окну. Вероятность зачатия начинает расти, так что обращай внимание на изменения своего тела.',
        'ar': 'أنتِ تقتربين من نافذة خصوبتكِ. يبدأ احتمال الحمل بالارتفاع، لذا انتبهي لتغيرات جسمكِ.',
        'hi': 'आप अपनी उपजाऊ खिड़की के करीब पहुंच रही हैं। गर्भधारण की संभावना बढ़ने लगी है, इसलिए अपने शरीर में होने वाले बदलावों पर ध्यान दें।',
        'bn': 'আপনি আপনার উর্বর সময়ের কাছাকাছি পৌঁছাচ্ছেন। গর্ভধারণের সম্ভাবনা বাড়তে শুরু করেছে, তাই আপনার শরীরের পরিবর্তনগুলোর দিকে মনোযোগ দিন।',
        'pt': 'Você está se aproximando da sua janela fértil. A probabilidade de concepção está começando a subir, então preste atenção às mudanças do seu corpo.',
      });
  String get bodyStageHighProbabilityText => _t({
        'es': 'Estás en tu ventana fértil. La probabilidad de quedar embarazada es alta en estos días, especialmente cerca de la ovulación.',
        'en': 'You\'re in your fertile window. The chance of getting pregnant is high on these days, especially close to ovulation.',
        'fr': 'Vous êtes dans votre fenêtre de fertilité. La probabilité de tomber enceinte est élevée ces jours-ci, surtout proche de l\'ovulation.',
        'de': 'Du bist in deinem fruchtbaren Fenster. Die Schwangerschaftswahrscheinlichkeit ist an diesen Tagen hoch, besonders nahe am Eisprung.',
        'ru': 'Ты в своём фертильном окне. Вероятность забеременеть высока в эти дни, особенно ближе к овуляции.',
        'ar': 'أنتِ في نافذة خصوبتكِ. احتمال الحمل مرتفع في هذه الأيام، خاصة بالقرب من الإباضة.',
        'hi': 'आप अपनी उपजाऊ खिड़की में हैं। इन दिनों गर्भवती होने की संभावना अधिक होती है, खासकर ओव्यूलेशन के करीब।',
        'bn': 'আপনি আপনার উর্বর সময়ে আছেন। এই দিনগুলোতে গর্ভবতী হওয়ার সম্ভাবনা বেশি, বিশেষত ডিম্বস্ফোটনের কাছাকাছি সময়ে।',
        'pt': 'Você está na sua janela fértil. A chance de engravidar é alta nesses dias, especialmente perto da ovulação.',
      });

  String get bodyStageMenstrualDescription => _t({
        'es': 'Durante el período, el revestimiento del útero se desprende y sale del cuerpo como sangrado. Los niveles de hormonas están en su punto más bajo, lo que puede causar cansancio o cambios de ánimo.',
        'en': 'During your period, the uterine lining sheds and leaves the body as bleeding. Hormone levels are at their lowest, which can cause tiredness or mood changes.',
        'fr': 'Pendant les règles, la paroi de l\'utérus se détache et s\'évacue sous forme de saignement. Les niveaux d\'hormones sont au plus bas, ce qui peut provoquer fatigue ou changements d\'humeur.',
        'de': 'Während der Periode löst sich die Gebärmutterschleimhaut ab und verlässt den Körper als Blutung. Die Hormonspiegel sind am niedrigsten, was Müdigkeit oder Stimmungsschwankungen verursachen kann.',
        'ru': 'Во время менструации слизистая оболочка матки отслаивается и выходит из тела в виде кровотечения. Уровень гормонов на самом низком уровне, что может вызывать усталость или перепады настроения.',
        'ar': 'خلال الدورة الشهرية، تنسلخ بطانة الرحم وتخرج من الجسم على شكل نزيف. تكون مستويات الهرمونات في أدنى نقطة لها، مما قد يسبب التعب أو تقلبات المزاج.',
        'hi': 'माहवारी के दौरान, गर्भाशय की परत झड़ जाती है और रक्तस्राव के रूप में शरीर से बाहर निकलती है। हार्मोन का स्तर सबसे कम होता है, जिससे थकान या मूड में बदलाव हो सकता है।',
        'bn': 'পিরিয়ডের সময়, জরায়ুর আস্তরণ ঝরে পড়ে এবং রক্তক্ষরণ হিসেবে শরীর থেকে বেরিয়ে যায়। হরমোনের মাত্রা সবচেয়ে কম থাকে, যা ক্লান্তি বা মেজাজ পরিবর্তনের কারণ হতে পারে।',
        'pt': 'Durante o período, o revestimento do útero se desprende e sai do corpo como sangramento. Os níveis hormonais estão no seu ponto mais baixo, o que pode causar cansaço ou mudanças de humor.',
      });
  String get bodyStageFollicularDescription => _t({
        'es': 'El cuerpo prepara un nuevo óvulo y el revestimiento del útero empieza a engrosarse de nuevo. Los estrógenos suben poco a poco, trayendo más energía y mejor ánimo.',
        'en': 'Your body is preparing a new egg and the uterine lining starts thickening again. Estrogen rises little by little, bringing more energy and a better mood.',
        'fr': 'Le corps prépare un nouvel ovule et la paroi utérine recommence à s\'épaissir. Les œstrogènes augmentent peu à peu, apportant plus d\'énergie et une meilleure humeur.',
        'de': 'Dein Körper bereitet eine neue Eizelle vor und die Gebärmutterschleimhaut beginnt sich wieder aufzubauen. Der Östrogenspiegel steigt allmählich, was mehr Energie und bessere Laune bringt.',
        'ru': 'Тело готовит новую яйцеклетку, и слизистая оболочка матки снова начинает утолщаться. Эстроген растёт понемногу, принося больше энергии и лучшее настроение.',
        'ar': 'يُحضّر الجسم بويضة جديدة، وتبدأ بطانة الرحم بالسماكة مجددًا. يرتفع الإستروجين تدريجيًا، مما يمنح طاقة أكبر ومزاجًا أفضل.',
        'hi': 'आपका शरीर एक नया अंडाणु तैयार कर रहा है और गर्भाशय की परत फिर से मोटी होने लगती है। एस्ट्रोजन धीरे-धीरे बढ़ता है, जिससे अधिक ऊर्जा और बेहतर मूड मिलता है।',
        'bn': 'আপনার শরীর একটি নতুন ডিম্বাণু তৈরি করছে এবং জরায়ুর আস্তরণ আবার পুরু হতে শুরু করে। ইস্ট্রোজেন ধীরে ধীরে বাড়ে, যা বেশি শক্তি এবং ভালো মেজাজ নিয়ে আসে।',
        'pt': 'Seu corpo está preparando um novo óvulo e o revestimento do útero começa a engrossar novamente. O estrogênio sobe pouco a pouco, trazendo mais energia e melhor humor.',
      });
  String get bodyStageOvulationDescription => _t({
        'es': 'Un óvulo maduro se libera del ovario y puede ser fecundado durante las próximas horas. Es el punto más fértil de tu ciclo.',
        'en': 'A mature egg is released from the ovary and can be fertilized over the next few hours. This is the most fertile point of your cycle.',
        'fr': 'Un ovule mature est libéré par l\'ovaire et peut être fécondé pendant les heures suivantes. C\'est le point le plus fertile de votre cycle.',
        'de': 'Eine reife Eizelle wird aus dem Eierstock freigesetzt und kann in den nächsten Stunden befruchtet werden. Dies ist der fruchtbarste Punkt deines Zyklus.',
        'ru': 'Зрелая яйцеклетка выходит из яичника и может быть оплодотворена в течение следующих нескольких часов. Это самая фертильная точка твоего цикла.',
        'ar': 'تُطلق بويضة ناضجة من المبيض ويمكن تخصيبها خلال الساعات القليلة القادمة. هذه هي أكثر نقطة خصوبة في دورتكِ.',
        'hi': 'एक परिपक्व अंडाणु अंडाशय से निकलता है और अगले कुछ घंटों में निषेचित हो सकता है। यह आपके चक्र का सबसे उपजाऊ बिंदु है।',
        'bn': 'ডিম্বাশয় থেকে একটি পরিপক্ব ডিম্বাণু নির্গত হয় এবং পরবর্তী কয়েক ঘণ্টার মধ্যে নিষিক্ত হতে পারে। এটি আপনার চক্রের সবচেয়ে উর্বর মুহূর্ত।',
        'pt': 'Um óvulo maduro é liberado do ovário e pode ser fecundado nas próximas horas. Este é o ponto mais fértil do seu ciclo.',
      });
  String get bodyStageLutealDescription => _t({
        'es': 'Tras la ovulación, el cuerpo produce progesterona para preparar el útero por si hay embarazo. Si no lo hay, las hormonas bajan y el ciclo vuelve a empezar.',
        'en': 'After ovulation, your body produces progesterone to prepare the uterus in case of pregnancy. If there isn\'t one, hormones drop and the cycle starts again.',
        'fr': 'Après l\'ovulation, le corps produit de la progestérone pour préparer l\'utérus en cas de grossesse. S\'il n\'y en a pas, les hormones baissent et le cycle recommence.',
        'de': 'Nach dem Eisprung produziert dein Körper Progesteron, um die Gebärmutter auf eine mögliche Schwangerschaft vorzubereiten. Falls keine eintritt, sinken die Hormone und der Zyklus beginnt erneut.',
        'ru': 'После овуляции тело вырабатывает прогестерон, чтобы подготовить матку на случай беременности. Если её нет, гормоны падают, и цикл начинается заново.',
        'ar': 'بعد الإباضة، ينتج الجسم البروجسترون لتهيئة الرحم في حال حدوث حمل. وإذا لم يحدث، تنخفض الهرمونات وتبدأ الدورة من جديد.',
        'hi': 'ओव्यूलेशन के बाद, आपका शरीर गर्भावस्था की स्थिति में गर्भाशय को तैयार करने के लिए प्रोजेस्टेरोन बनाता है। अगर गर्भधारण नहीं होता, तो हार्मोन का स्तर गिर जाता है और चक्र फिर से शुरू हो जाता है।',
        'bn': 'ডিম্বস্ফোটনের পর, আপনার শরীর গর্ভাবস্থার জন্য জরায়ুকে প্রস্তুত করতে প্রোজেস্টেরন তৈরি করে। যদি গর্ভধারণ না হয়, তাহলে হরমোনের মাত্রা কমে যায় এবং চক্র আবার শুরু হয়।',
        'pt': 'Depois da ovulação, seu corpo produz progesterona para preparar o útero para uma possível gravidez. Se não houver gravidez, os hormônios caem e o ciclo recomeça.',
      });

  String get bodyStageMenstrualMotivation => _t({
        'es': 'Escucha a tu cuerpo, descansa lo que necesites y sé amable contigo misma estos días.',
        'en': 'Listen to your body, rest as much as you need, and be gentle with yourself these days.',
        'fr': 'Écoutez votre corps, reposez-vous autant que nécessaire et soyez douce avec vous-même ces jours-ci.',
        'de': 'Höre auf deinen Körper, ruhe dich aus, wenn du es brauchst, und sei in diesen Tagen sanft zu dir selbst.',
        'ru': 'Прислушивайся к своему телу, отдыхай столько, сколько нужно, и будь добра к себе в эти дни.',
        'ar': 'استمعي لجسمكِ، ارتاحي بقدر ما تحتاجين، وكوني لطيفة مع نفسكِ هذه الأيام.',
        'hi': 'अपने शरीर की सुनें, जितना जरूरत हो उतना आराम करें, और इन दिनों अपने प्रति नरम रहें।',
        'bn': 'নিজের শরীরের কথা শুনুন, যতটা প্রয়োজন বিশ্রাম নিন, এবং এই দিনগুলোতে নিজের প্রতি নম্র থাকুন।',
        'pt': 'Ouça seu corpo, descanse o quanto precisar e seja gentil consigo mesma nesses dias.',
      });
  String get bodyStageFollicularMotivation => _t({
        'es': 'Aprovecha esta energía creciente: es un buen momento para empezar proyectos nuevos.',
        'en': 'Make the most of this rising energy: it\'s a great time to start new projects.',
        'fr': 'Profitez de cette énergie croissante : c\'est un bon moment pour démarrer de nouveaux projets.',
        'de': 'Nutze diese steigende Energie: eine gute Zeit, um neue Projekte zu beginnen.',
        'ru': 'Используй эту растущую энергию: сейчас отличное время, чтобы начать новые проекты.',
        'ar': 'استفيدي من هذه الطاقة المتصاعدة: إنه وقت رائع لبدء مشاريع جديدة.',
        'hi': 'इस बढ़ती ऊर्जा का पूरा फायदा उठाएं: नई परियोजनाएं शुरू करने का यह बढ़िया समय है।',
        'bn': 'এই বাড়তে থাকা শক্তির পুরো সুবিধা নিন: নতুন প্রকল্প শুরু করার এটি চমৎকার সময়।',
        'pt': 'Aproveite ao máximo essa energia crescente: é um ótimo momento para começar novos projetos.',
      });
  String get bodyStageOvulationMotivation => _t({
        'es': 'Te sientes más segura y con más energía social: un buen momento para conectar con los demás.',
        'en': 'You may feel more confident and socially energized: a great time to connect with others.',
        'fr': 'Vous vous sentez plus sûre de vous et plus énergique socialement : un bon moment pour vous connecter aux autres.',
        'de': 'Du fühlst dich sicherer und sozial energiegeladener: ein guter Moment, um dich mit anderen zu verbinden.',
        'ru': 'Ты можешь чувствовать себя увереннее и энергичнее в общении: хорошее время, чтобы наладить контакт с другими.',
        'ar': 'قد تشعرين بثقة أكبر وطاقة اجتماعية أعلى: وقت رائع للتواصل مع الآخرين.',
        'hi': 'आप अधिक आत्मविश्वासी और सामाजिक रूप से ऊर्जावान महसूस कर सकती हैं: दूसरों से जुड़ने का बढ़िया समय है।',
        'bn': 'আপনি আরও আত্মবিশ্বাসী এবং সামাজিকভাবে উদ্যমী অনুভব করতে পারেন: অন্যদের সাথে যোগাযোগ করার চমৎকার সময়।',
        'pt': 'Você pode se sentir mais confiante e socialmente energizada: um ótimo momento para se conectar com os outros.',
      });
  String get bodyStageLutealMotivation => _t({
        'es': 'Ve bajando el ritmo poco a poco y prioriza el descanso y el cuidado personal.',
        'en': 'Start slowing down little by little and prioritize rest and self-care.',
        'fr': 'Ralentissez peu à peu et privilégiez le repos et le soin de vous-même.',
        'de': 'Reduziere nach und nach dein Tempo und priorisiere Ruhe und Selbstfürsorge.',
        'ru': 'Постепенно сбавляй темп и отдавай приоритет отдыху и заботе о себе.',
        'ar': 'ابدئي بتخفيف الوتيرة تدريجيًا وأعطي الأولوية للراحة والعناية بنفسكِ.',
        'hi': 'धीरे-धीरे अपनी गति कम करना शुरू करें और आराम व आत्म-देखभाल को प्राथमिकता दें।',
        'bn': 'ধীরে ধীরে গতি কমাতে শুরু করুন এবং বিশ্রাম ও নিজের যত্নকে অগ্রাধিকার দিন।',
        'pt': 'Comece a desacelerar aos poucos e priorize o descanso e o autocuidado.',
      });

  String get bodyStageMenstrualSymptoms => _t({
        'es': 'Calambres abdominales, dolor lumbar, cambios de humor, cansancio y sensibilidad en los senos.',
        'en': 'Abdominal cramps, lower back pain, mood changes, fatigue and breast tenderness.',
        'fr': 'Crampes abdominales, douleurs lombaires, changements d\'humeur, fatigue et sensibilité des seins.',
        'de': 'Bauchkrämpfe, Rückenschmerzen, Stimmungsschwankungen, Müdigkeit und Brustspannen.',
        'ru': 'Спазмы в животе, боль в пояснице, перепады настроения, усталость и чувствительность груди.',
        'ar': 'تقلصات في البطن، ألم أسفل الظهر، تقلبات المزاج، التعب وحساسية الثدي.',
        'hi': 'पेट में ऐंठन, पीठ के निचले हिस्से में दर्द, मूड में बदलाव, थकान और स्तनों में कोमलता।',
        'bn': 'পেটে খিঁচুনি, কোমরে ব্যথা, মেজাজ পরিবর্তন, ক্লান্তি এবং স্তনে কোমলতা।',
        'pt': 'Cólicas abdominais, dor lombar, mudanças de humor, cansaço e sensibilidade nos seios.',
      });
  String get bodyStageFollicularSymptoms => _t({
        'es': 'Energía en aumento, piel más despejada, mejor ánimo y más motivación.',
        'en': 'Rising energy, clearer skin, better mood and more motivation.',
        'fr': 'Énergie croissante, peau plus nette, meilleure humeur et plus de motivation.',
        'de': 'Steigende Energie, klarere Haut, bessere Laune und mehr Motivation.',
        'ru': 'Растущая энергия, более чистая кожа, лучшее настроение и больше мотивации.',
        'ar': 'طاقة متزايدة، بشرة أصفى، مزاج أفضل ومزيد من الحافز.',
        'hi': 'बढ़ती ऊर्जा, साफ त्वचा, बेहतर मूड और अधिक प्रेरणा।',
        'bn': 'বর্ধিত শক্তি, পরিষ্কার ত্বক, ভালো মেজাজ এবং বেশি অনুপ্রেরণা।',
        'pt': 'Energia crescente, pele mais limpa, melhor humor e mais motivação.',
      });
  String get bodyStageOvulationSymptoms => _t({
        'es': 'Mayor libido, flujo vaginal elástico y transparente, leve dolor pélvico y sensibilidad en los senos.',
        'en': 'Higher libido, clear stretchy vaginal discharge, mild pelvic pain and breast tenderness.',
        'fr': 'Libido plus élevée, pertes vaginales élastiques et transparentes, légère douleur pelvienne et sensibilité des seins.',
        'de': 'Höhere Libido, klarer, dehnbarer Vaginalausfluss, leichte Unterleibsschmerzen und Brustspannen.',
        'ru': 'Повышенное либидо, эластичные прозрачные вагинальные выделения, лёгкая тазовая боль и чувствительность груди.',
        'ar': 'رغبة جنسية أعلى، إفرازات مهبلية شفافة ومطاطية، ألم خفيف في الحوض وحساسية الثدي.',
        'hi': 'अधिक कामेच्छा, साफ और लचीला योनि स्राव, हल्का पेल्विक दर्द और स्तनों में कोमलता।',
        'bn': 'বেশি যৌন আকাঙ্ক্ষা, স্বচ্ছ ও স্থিতিস্থাপক যোনি স্রাব, হালকা পেলভিক ব্যথা এবং স্তনে কোমলতা।',
        'pt': 'Maior libido, corrimento vaginal transparente e elástico, dor pélvica leve e sensibilidade nos seios.',
      });
  String get bodyStageLutealSymptoms => _t({
        'es': 'Hinchazón, sensibilidad en los senos, antojos de comida, cambios de humor e irritabilidad.',
        'en': 'Bloating, breast tenderness, food cravings, mood swings and irritability.',
        'fr': 'Ballonnements, sensibilité des seins, envies alimentaires, sautes d\'humeur et irritabilité.',
        'de': 'Blähungen, Brustspannen, Heißhunger, Stimmungsschwankungen und Reizbarkeit.',
        'ru': 'Вздутие живота, чувствительность груди, тяга к еде, перепады настроения и раздражительность.',
        'ar': 'انتفاخ، حساسية الثدي، الرغبة الشديدة في الطعام، تقلبات المزاج والتهيج.',
        'hi': 'सूजन, स्तनों में कोमलता, खाने की लालसा, मूड में उतार-चढ़ाव और चिड़चिड़ापन।',
        'bn': 'পেট ফাঁপা, স্তনে কোমলতা, খাবারের প্রতি তীব্র আকাঙ্ক্ষা, মেজাজের ওঠানামা এবং খিটখিটে ভাব।',
        'pt': 'Inchaço, sensibilidade nos seios, desejos alimentares, oscilações de humor e irritabilidade.',
      });

  // ---- Pantalla "Yo" ----
  String get mePeriodAndCycle =>
      _t({'es': 'Periodo y ciclo', 'en': 'Period and cycle', 'fr': 'Règles et cycle', 'de': 'Periode und Zyklus', 'ru': 'Менструация и цикл', 'ar': 'الدورة الشهرية والدورة', 'hi': 'पीरियड और चक्र', 'bn': 'পিরিয়ড ও চক্র', 'pt': 'Período e ciclo'});
  String get meTemperature => _t({'es': 'Temperatura', 'en': 'Temperature', 'fr': 'Température', 'de': 'Temperatur', 'ru': 'Температура', 'ar': 'درجة الحرارة', 'hi': 'तापमान', 'bn': 'তাপমাত্রা', 'pt': 'Temperatura'});
  String get meSymptomsAndPredictions => _t({
        'es': 'Síntomas y predicciones',
        'en': 'Symptoms and predictions',
        'fr': 'Symptômes et prédictions',
        'de': 'Symptome und Vorhersagen',
        'ru': 'Симптомы и прогнозы',
        'ar': 'الأعراض والتوقعات',
        'hi': 'लक्षण और भविष्यवाणियां',
        'bn': 'লক্ষণ ও পূর্বাভাস',
        'pt': 'Sintomas e previsões',
      });
  String get meOvulationTest =>
      _t({'es': 'Test de ovulación', 'en': 'Ovulation test', 'fr': "Test d'ovulation", 'de': 'Eisprungtest', 'ru': 'Тест на овуляцию', 'ar': 'اختبار الإباضة', 'hi': 'ओव्यूलेशन टेस्ट', 'bn': 'ডিম্বস্ফোটন পরীক্ষা', 'pt': 'Teste de ovulação'});
  String get meSexLife => _t({'es': 'Vida sexual', 'en': 'Sex life', 'fr': 'Vie sexuelle', 'de': 'Sexualleben', 'ru': 'Интимная жизнь', 'ar': 'الحياة الجنسية', 'hi': 'यौन जीवन', 'bn': 'যৌন জীবন', 'pt': 'Vida sexual'});
  String get meFertility => _t({'es': 'Fertilidad', 'en': 'Fertility', 'fr': 'Fertilité', 'de': 'Fruchtbarkeit', 'ru': 'Фертильность', 'ar': 'الخصوبة', 'hi': 'प्रजनन क्षमता', 'bn': 'উর্বরতা', 'pt': 'Fertilidade'});
  String get meWeight => _t({'es': 'Peso', 'en': 'Weight', 'fr': 'Poids', 'de': 'Gewicht', 'ru': 'Вес', 'ar': 'الوزن', 'hi': 'वज़न', 'bn': 'ওজন', 'pt': 'Peso'});
  String get meSleep => _t({'es': 'Sueño', 'en': 'Sleep', 'fr': 'Sommeil', 'de': 'Schlaf', 'ru': 'Сон', 'ar': 'النوم', 'hi': 'नींद', 'bn': 'ঘুম', 'pt': 'Sono'});
  String get meBreastSelfExam =>
      _t({'es': 'Autoexamen de mamas', 'en': 'Breast self-exam', 'fr': 'Autoexamen des seins', 'de': 'Brust-Selbstuntersuchung', 'ru': 'Самообследование груди', 'ar': 'الفحص الذاتي للثدي', 'hi': 'स्तन स्व-परीक्षण', 'bn': 'স্তন স্ব-পরীক্ষা', 'pt': 'Autoexame de mama'});
  String get meDrinkWater => _t({'es': 'Bebe agua', 'en': 'Drink water', 'fr': "Bois de l'eau", 'de': 'Trink Wasser', 'ru': 'Пей воду', 'ar': 'اشربي ماء', 'hi': 'पानी पिएं', 'bn': 'পানি পান করুন', 'pt': 'Beba água'});

  // ---- Pantalla de detalle de solo lectura por campo (FieldDetailScreen) ----
  String get fieldDetailEditButton =>
      _t({'es': 'Editar', 'en': 'Edit', 'fr': 'Modifier', 'de': 'Bearbeiten', 'ru': 'Редактировать', 'ar': 'تعديل', 'hi': 'संपादित करें', 'bn': 'সম্পাদনা করুন', 'pt': 'Editar'});
  String get fieldDetailEmptyTitle => _t({
        'es': 'Aún no has registrado esto',
        'en': "You haven't logged this yet",
        'fr': "Vous n'avez pas encore enregistré ceci",
        'de': 'Das hast du noch nicht erfasst',
        'ru': 'Ты ещё не отмечала это',
        'ar': 'لم تُسجّلي هذا بعد',
        'hi': 'आपने अभी तक यह दर्ज नहीं किया है',
        'bn': 'আপনি এখনও এটি লগ করেননি',
        'pt': 'Você ainda não registrou isso',
      });
  String get fieldDetailEmptyButton =>
      _t({'es': 'Registrar ahora', 'en': 'Log it now', 'fr': 'Enregistrer maintenant', 'de': 'Jetzt erfassen', 'ru': 'Отметить сейчас', 'ar': 'سجّليه الآن', 'hi': 'अभी दर्ज करें', 'bn': 'এখনই লগ করুন', 'pt': 'Registrar agora'});
  String get fieldDetailLastLogged => _t({
        'es': 'Registrado el',
        'en': 'Logged on',
        'fr': 'Enregistré le',
        'de': 'Erfasst am',
        'ru': 'Отмечено',
        'ar': 'سُجّل في',
        'hi': 'दर्ज किया गया',
        'bn': 'লগ করা হয়েছে',
        'pt': 'Registrado em',
      });
  String get fieldDetailLastRecord => _t({
        'es': 'Último registro',
        'en': 'Last record',
        'fr': 'Dernier enregistrement',
        'de': 'Letzter Eintrag',
        'ru': 'Последняя запись',
        'ar': 'آخر سجل',
        'hi': 'अंतिम रिकॉर्ड',
        'bn': 'সর্বশেষ রেকর্ড',
        'pt': 'Último registro',
      });
  String get fieldDetailTrendTitle => _t({
        'es': 'Tendencia · últimos registros',
        'en': 'Trend · recent records',
        'fr': 'Tendance · derniers enregistrements',
        'de': 'Trend · letzte Einträge',
        'ru': 'Тенденция · последние записи',
        'ar': 'الاتجاه · السجلات الأخيرة',
        'hi': 'प्रवृत्ति · हाल के रिकॉर्ड',
        'bn': 'প্রবণতা · সাম্প্রতিক রেকর্ড',
        'pt': 'Tendência · registros recentes',
      });
  String get fieldDetailEvaluationTitle =>
      _t({'es': 'Evaluación', 'en': 'Evaluation', 'fr': 'Évaluation', 'de': 'Bewertung', 'ru': 'Оценка', 'ar': 'التقييم', 'hi': 'मूल्यांकन', 'bn': 'মূল্যায়ন', 'pt': 'Avaliação'});
  String get fieldDetailTrendUp =>
      _t({'es': 'Subió', 'en': 'Up', 'fr': 'En hausse', 'de': 'Gestiegen', 'ru': 'Выросло', 'ar': 'ارتفع', 'hi': 'बढ़ा', 'bn': 'বৃদ্ধি', 'pt': 'Subiu'});
  String get fieldDetailTrendDown =>
      _t({'es': 'Bajó', 'en': 'Down', 'fr': 'En baisse', 'de': 'Gesunken', 'ru': 'Снизилось', 'ar': 'انخفض', 'hi': 'घटा', 'bn': 'হ্রাস', 'pt': 'Desceu'});
  String get fieldDetailTrendStable =>
      _t({'es': 'Estable', 'en': 'Stable', 'fr': 'Stable', 'de': 'Stabil', 'ru': 'Стабильно', 'ar': 'مستقر', 'hi': 'स्थिर', 'bn': 'স্থিতিশীল', 'pt': 'Estável'});
  String fieldDetailTrendChange(String direction, String amount) =>
      _t({
        'es': '$direction $amount respecto al registro anterior',
        'en': '$direction $amount from the previous record',
        'fr': '$direction $amount par rapport au précédent',
        'de': '$direction $amount gegenüber dem letzten Eintrag',
        'ru': '$direction на $amount по сравнению с предыдущей записью',
        'ar': '$direction $amount مقارنة بالسجل السابق',
        'hi': '$direction $amount पिछले रिकॉर्ड की तुलना में',
        'bn': 'পূর্ববর্তী রেকর্ডের তুলনায় $direction $amount',
        'pt': '$direction $amount em relação ao registro anterior',
      });
  String get fieldDetailNotEnoughTrend => _t({
        'es': 'Registra al menos 2 días para ver la tendencia.',
        'en': 'Log at least 2 days to see the trend.',
        'fr': 'Enregistrez au moins 2 jours pour voir la tendance.',
        'de': 'Erfasse mindestens 2 Tage, um den Trend zu sehen.',
        'ru': 'Отметь минимум 2 дня, чтобы увидеть тенденцию.',
        'ar': 'سجّلي يومين على الأقل لرؤية الاتجاه.',
        'hi': 'प्रवृत्ति देखने के लिए कम से कम 2 दिन दर्ज करें।',
        'bn': 'প্রবণতা দেখতে অন্তত ২ দিন লগ করুন।',
        'pt': 'Registre pelo menos 2 dias para ver a tendência.',
      });

  // ---- Pantalla resumen (QuickSummaryScreen) para los 4 accesos del grid
  // de "Yo" que abren pantallas completas (Periodo y ciclo, Síntomas y
  // predicciones, Test de ovulación, Fertilidad) en vez del editor simple
  // de FieldDetailScreen. Mismo patrón visual (barra superior + tarjetas),
  // pero el botón de la píldora lleva a la pantalla completa en vez de a
  // un editor.
  String get quickSummaryViewCalendarButton => _t({
        'es': 'Ver calendario',
        'en': 'View calendar',
        'fr': 'Voir le calendrier',
        'de': 'Kalender ansehen',
        'ru': 'Смотреть календарь',
        'ar': 'عرض التقويم',
        'hi': 'कैलेंडर देखें',
        'bn': 'ক্যালেন্ডার দেখুন',
        'pt': 'Ver calendário',
      });
  String get quickSummaryViewStatsButton => _t({
        'es': 'Ver estadísticas',
        'en': 'View statistics',
        'fr': 'Voir les statistiques',
        'de': 'Statistiken ansehen',
        'ru': 'Смотреть статистику',
        'ar': 'عرض الإحصائيات',
        'hi': 'आंकड़े देखें',
        'bn': 'পরিসংখ্যান দেখুন',
        'pt': 'Ver estatísticas',
      });
  String get quickSummaryViewTestButton => _t({
        'es': 'Ver test',
        'en': 'View test',
        'fr': 'Voir le test',
        'de': 'Test ansehen',
        'ru': 'Смотреть тест',
        'ar': 'عرض الاختبار',
        'hi': 'टेस्ट देखें',
        'bn': 'পরীক্ষা দেখুন',
        'pt': 'Ver teste',
      });
  String get quickSummaryNoDataYet => _t({
        'es': 'Sin datos suficientes',
        'en': 'Not enough data yet',
        'fr': 'Pas assez de données',
        'de': 'Noch nicht genug Daten',
        'ru': 'Недостаточно данных',
        'ar': 'لا توجد بيانات كافية',
        'hi': 'अभी पर्याप्त डेटा नहीं है',
        'bn': 'এখনও পর্যাপ্ত তথ্য নেই',
        'pt': 'Ainda não há dados suficientes',
      });
  String get quickSummaryNextPeriodLabel => _t({
        'es': 'Próximo periodo estimado',
        'en': 'Estimated next period',
        'fr': 'Prochaines règles estimées',
        'de': 'Geschätzte nächste Periode',
        'ru': 'Предполагаемая следующая менструация',
        'ar': 'الدورة القادمة المتوقعة',
        'hi': 'अनुमानित अगला पीरियड',
        'bn': 'আনুমানিক পরবর্তী পিরিয়ড',
        'pt': 'Próximo período estimado',
      });
  String get quickSummaryAvgCycleLabel => _t({
        'es': 'Ciclo promedio',
        'en': 'Average cycle',
        'fr': 'Cycle moyen',
        'de': 'Durchschnittlicher Zyklus',
        'ru': 'Средний цикл',
        'ar': 'متوسط الدورة',
        'hi': 'औसत चक्र',
        'bn': 'গড় চক্র',
        'pt': 'Ciclo médio',
      });
  String get quickSummaryAvgPeriodLabel => _t({
        'es': 'Periodo promedio',
        'en': 'Average period',
        'fr': 'Règles moyennes',
        'de': 'Durchschnittliche Periode',
        'ru': 'Средняя менструация',
        'ar': 'متوسط الحيض',
        'hi': 'औसत पीरियड',
        'bn': 'গড় পিরিয়ড',
        'pt': 'Período médio',
      });
  String get quickSummaryEvalPeriodCycle => _t({
        'es': 'Esta predicción se basa en tu historial de ciclos registrados. Cuanto más registres, más precisa será.',
        'en': 'This prediction is based on your logged cycle history. The more you log, the more accurate it gets.',
        'fr': "Cette prédiction se base sur l'historique de vos cycles enregistrés. Plus vous enregistrez, plus elle est précise.",
        'de': 'Diese Vorhersage basiert auf deinem erfassten Zyklusverlauf. Je mehr du erfasst, desto genauer wird sie.',
        'ru': 'Этот прогноз основан на истории твоих зарегистрированных циклов. Чем больше ты отмечаешь, тем точнее он будет.',
        'ar': 'يعتمد هذا التوقع على سجل دوراتك المسجّلة. كلما سجّلتِ أكثر، زادت دقته.',
        'hi': 'यह भविष्यवाणी आपके दर्ज किए गए चक्र इतिहास पर आधारित है। जितना अधिक आप दर्ज करेंगी, यह उतनी ही सटीक होगी।',
        'bn': 'এই পূর্বাভাস আপনার লগ করা চক্রের ইতিহাসের উপর ভিত্তি করে তৈরি। আপনি যত বেশি লগ করবেন, এটি তত বেশি নির্ভুল হবে।',
        'pt': 'Essa previsão é baseada no seu histórico de ciclos registrados. Quanto mais você registrar, mais precisa ela fica.',
      });
  String get quickSummaryEvalPeriodCycleNoData => _t({
        'es': 'Registra al menos 2 periodos para que CicloPlus pueda predecir tu próximo ciclo.',
        'en': 'Log at least 2 periods so CicloPlus can predict your next cycle.',
        'fr': "Enregistrez au moins 2 cycles pour que CicloPlus puisse prédire votre prochain cycle.",
        'de': 'Erfasse mindestens 2 Perioden, damit CicloPlus deinen nächsten Zyklus vorhersagen kann.',
        'ru': 'Отметь минимум 2 менструации, чтобы CicloPlus мог предсказать твой следующий цикл.',
        'ar': 'سجّلي دورتين على الأقل حتى يتمكن CicloPlus من توقع دورتك القادمة.',
        'hi': 'CicloPlus को आपके अगले चक्र की भविष्यवाणी करने के लिए कम से कम 2 पीरियड दर्ज करें।',
        'bn': 'CicloPlus আপনার পরবর্তী চক্রের পূর্বাভাস দিতে পারে, তার জন্য অন্তত ২টি পিরিয়ড লগ করুন।',
        'pt': 'Registre pelo menos 2 períodos para que o CicloPlus possa prever seu próximo ciclo.',
      });
  String get quickSummarySymptomsDaysLabel => _t({
        'es': 'Días con síntomas (últimos 30 días)',
        'en': 'Days with symptoms (last 30 days)',
        'fr': 'Jours avec symptômes (30 derniers jours)',
        'de': 'Tage mit Symptomen (letzte 30 Tage)',
        'ru': 'Дни с симптомами (последние 30 дней)',
        'ar': 'الأيام التي ظهرت فيها أعراض (آخر 30 يومًا)', 'hi': 'लक्षणों वाले दिन (पिछले 30 दिन)', 'bn': 'লক্ষণসহ দিন (গত ৩০ দিন)', 'pt': 'Dias com sintomas (últimos 30 dias)',
      });
  String get quickSummaryCurrentPhaseLabel => _t({
        'es': 'Fase actual del ciclo',
        'en': 'Current cycle phase',
        'fr': 'Phase actuelle du cycle',
        'de': 'Aktuelle Zyklusphase',
        'ru': 'Текущая фаза цикла',
        'ar': 'المرحلة الحالية من الدورة', 'hi': 'चक्र का मौजूदा चरण', 'bn': 'চক্রের বর্তমান পর্যায়', 'pt': 'Fase atual do ciclo',
      });
  String get quickSummaryEvalSymptoms => _t({
        'es': 'Revisa tus síntomas y predicciones detalladas en Estadísticas, incluyendo tendencias por fase del ciclo.',
        'en': 'Check your detailed symptoms and predictions in Statistics, including trends by cycle phase.',
        'fr': 'Consultez vos symptômes et prédictions détaillés dans Statistiques, avec les tendances par phase du cycle.',
        'de': 'Sieh dir deine detaillierten Symptome und Vorhersagen in Statistiken an, inklusive Trends je Zyklusphase.',
        'ru': 'Просмотри подробные симптомы и прогнозы в Статистике, включая тенденции по фазам цикла.',
        'ar': 'اطّلعي على أعراضكِ وتوقعاتكِ التفصيلية في الإحصائيات، بما في ذلك الاتجاهات حسب مرحلة الدورة.', 'hi': 'चक्र के चरण अनुसार रुझानों सहित, अपने विस्तृत लक्षण और भविष्यवाणियां आंकड़ों में देखें।', 'bn': 'চক্রের পর্যায় অনুযায়ী প্রবণতাসহ, আপনার বিস্তারিত লক্ষণ ও পূর্বাভাস পরিসংখ্যানে দেখুন।', 'pt': 'Veja seus sintomas e previsões detalhadas nas Estatísticas, incluindo tendências por fase do ciclo.',
      });
  String get quickSummaryEvalSymptomsNoData => _t({
        'es': 'Aún no hay suficientes registros para calcular tu fase del ciclo. Registra tus síntomas y periodo.',
        'en': "There isn't enough data yet to calculate your cycle phase. Log your symptoms and period.",
        'fr': "Il n'y a pas encore assez de données pour calculer votre phase du cycle. Enregistrez vos symptômes et règles.",
        'de': 'Es gibt noch nicht genug Daten, um deine Zyklusphase zu berechnen. Erfasse deine Symptome und Periode.',
        'ru': 'Пока недостаточно данных, чтобы рассчитать твою фазу цикла. Отмечай свои симптомы и менструацию.',
        'ar': 'لا توجد بيانات كافية بعد لحساب مرحلة دورتكِ. سجّلي أعراضكِ ودورتكِ.', 'hi': 'आपके चक्र के चरण की गणना करने के लिए अभी पर्याप्त डेटा नहीं है। अपने लक्षण और पीरियड दर्ज करें।', 'bn': 'আপনার চক্রের পর্যায় হিসাব করার জন্য এখনও পর্যাপ্ত তথ্য নেই। আপনার লক্ষণ ও পিরিয়ড লগ করুন।', 'pt': 'Ainda não há dados suficientes para calcular a fase do seu ciclo. Registre seus sintomas e período.',
      });
  String get quickSummaryOvulationNearWindow => _t({
        'es': 'Estás dentro de tu ventana fértil estimada. Buen momento para hacer un test de ovulación.',
        'en': "You're within your estimated fertile window. A good time to take an ovulation test.",
        'fr': 'Vous êtes dans votre fenêtre de fertilité estimée. Un bon moment pour faire un test d\'ovulation.',
        'de': 'Du befindest dich in deinem geschätzten fruchtbaren Fenster. Ein guter Zeitpunkt für einen Eisprungtest.',
        'ru': 'Ты находишься в своём предполагаемом фертильном окне. Хороший момент, чтобы сделать тест на овуляцию.',
        'ar': 'أنتِ ضمن نافذة خصوبتكِ المتوقعة. وقت جيد لإجراء اختبار الإباضة.', 'hi': 'आप अपनी अनुमानित उपजाऊ अवधि में हैं। ओव्यूलेशन टेस्ट कराने का अच्छा समय है।', 'bn': 'আপনি আপনার আনুমানিক উর্বর সময়কালে আছেন। ডিম্বস্ফোটন পরীক্ষা করার ভালো সময়।', 'pt': 'Você está dentro da sua janela fértil estimada. Um bom momento para fazer um teste de ovulação.',
      });
  String get quickSummaryOvulationOutsideWindow => _t({
        'es': 'Aún no estás en tu ventana fértil estimada. Te avisaremos cuando se acerque.',
        'en': "You're not in your estimated fertile window yet. We'll let you know when it's near.",
        'fr': "Vous n'êtes pas encore dans votre fenêtre de fertilité estimée. Nous vous préviendrons quand elle approchera.",
        'de': 'Du bist noch nicht in deinem geschätzten fruchtbaren Fenster. Wir sagen dir Bescheid, wenn es näher rückt.',
        'ru': 'Ты ещё не в своём предполагаемом фертильном окне. Мы сообщим тебе, когда оно приблизится.',
        'ar': 'لستِ بعد في نافذة خصوبتكِ المتوقعة. سنُعلمكِ عندما تقترب.', 'hi': 'आप अभी अपनी अनुमानित उपजाऊ अवधि में नहीं हैं। जब यह नज़दीक आएगी, हम आपको बता देंगे।', 'bn': 'আপনি এখনও আপনার আনুমানিক উর্বর সময়কালে নেই। এটি কাছাকাছি এলে আমরা আপনাকে জানাবো।', 'pt': 'Você ainda não está na sua janela fértil estimada. Vamos avisar quando estiver próxima.',
      });
  String get quickSummaryOvulationNoData => _t({
        'es': 'Registra al menos 2 periodos para estimar tu ventana fértil y saber cuándo hacer el test.',
        'en': 'Log at least 2 periods to estimate your fertile window and know when to test.',
        'fr': "Enregistrez au moins 2 cycles pour estimer votre fenêtre de fertilité et savoir quand tester.",
        'de': 'Erfasse mindestens 2 Perioden, um dein fruchtbares Fenster zu schätzen und zu wissen, wann du testen solltest.',
        'ru': 'Отметь минимум 2 менструации, чтобы рассчитать своё фертильное окно и знать, когда делать тест.',
        'ar': 'سجّلي دورتين على الأقل لتقدير نافذة خصوبتكِ ومعرفة متى تجرين الاختبار.', 'hi': 'अपनी उपजाऊ अवधि का अनुमान लगाने और टेस्ट कब करना है यह जानने के लिए कम से कम 2 पीरियड दर्ज करें।', 'bn': 'আপনার উর্বর সময়কাল অনুমান করতে এবং কখন পরীক্ষা করবেন তা জানতে অন্তত ২টি পিরিয়ড লগ করুন।', 'pt': 'Registre pelo menos 2 períodos para estimar sua janela fértil e saber quando fazer o teste.',
      });
  String get quickSummaryFertileWindowLabel => _t({
        'es': 'Ventana fértil estimada',
        'en': 'Estimated fertile window',
        'fr': 'Fenêtre de fertilité estimée',
        'de': 'Geschätztes fruchtbares Fenster',
        'ru': 'Предполагаемое фертильное окно',
        'ar': 'نافذة الخصوبة المقدرة', 'hi': 'अनुमानित उपजाऊ अवधि', 'bn': 'আনুমানিক উর্বর সময়কাল', 'pt': 'Janela fértil estimada',
      });
  String get quickSummaryEvalFertility => _t({
        'es': 'La ventana fértil incluye los días previos y posteriores a la ovulación, cuando la probabilidad de embarazo es más alta.',
        'en': 'The fertile window includes the days before and after ovulation, when the chance of pregnancy is highest.',
        'fr': "La fenêtre de fertilité comprend les jours avant et après l'ovulation, quand la probabilité de grossesse est la plus élevée.",
        'de': 'Das fruchtbare Fenster umfasst die Tage vor und nach dem Eisprung, wenn die Schwangerschaftswahrscheinlichkeit am höchsten ist.',
        'ru': 'Фертильное окно включает дни до и после овуляции, когда вероятность беременности наиболее высока.',
        'ar': 'تشمل نافذة الخصوبة الأيام التي تسبق الإباضة وتليها، عندما يكون احتمال الحمل في أعلى مستوياته.', 'hi': 'उपजाऊ अवधि में ओव्यूलेशन से पहले और बाद के वे दिन शामिल हैं, जब गर्भवती होने की संभावना सबसे ज़्यादा होती है।', 'bn': 'উর্বর সময়কালে ডিম্বস্ফোটনের আগে ও পরের দিনগুলো অন্তর্ভুক্ত, যখন গর্ভধারণের সম্ভাবনা সবচেয়ে বেশি থাকে।', 'pt': 'A janela fértil inclui os dias antes e depois da ovulação, quando a chance de gravidez é mais alta.',
      });
  String get quickSummaryEvalFertilityNoData => _t({
        'es': 'Registra al menos 2 periodos para que CicloPlus pueda estimar tu ventana fértil.',
        'en': 'Log at least 2 periods so CicloPlus can estimate your fertile window.',
        'fr': "Enregistrez au moins 2 cycles pour que CicloPlus puisse estimer votre fenêtre de fertilité.",
        'de': 'Erfasse mindestens 2 Perioden, damit CicloPlus dein fruchtbares Fenster schätzen kann.',
        'ru': 'Отметь минимум 2 менструации, чтобы CicloPlus мог оценить твоё фертильное окно.',
        'ar': 'سجّلي دورتين على الأقل حتى يتمكن CicloPlus من تقدير نافذة خصوبتكِ.', 'hi': 'CicloPlus को आपकी उपजाऊ अवधि का अनुमान लगाने देने के लिए कम से कम 2 पीरियड दर्ज करें।', 'bn': 'CicloPlus আপনার উর্বর সময়কাল অনুমান করতে পারে সেজন্য অন্তত ২টি পিরিয়ড লগ করুন।', 'pt': 'Registre pelo menos 2 períodos para que o CicloPlus possa estimar sua janela fértil.',
      });

  // ---- Evaluaciones por campo ----
  String get evalWeightNormal => _t({
        'es': 'Tu IMC está dentro del rango normal (18.5–24.9).',
        'en': 'Your BMI is within the normal range (18.5–24.9).',
        'fr': 'Votre IMC est dans la plage normale (18,5–24,9).',
        'de': 'Dein BMI liegt im Normalbereich (18,5–24,9).',
        'ru': 'Твой ИМТ находится в пределах нормы (18,5–24,9).',
        'ar': 'مؤشر كتلة جسمكِ ضمن النطاق الطبيعي (18.5–24.9).', 'hi': 'आपका बीएमआई सामान्य सीमा में है (18.5–24.9)।', 'bn': 'আপনার বিএমআই স্বাভাবিক পরিসরে আছে (১৮.৫–২৪.৯)।', 'pt': 'Seu IMC está dentro da faixa normal (18,5–24,9).',
      });
  String get evalWeightLow => _t({
        'es': 'Tu IMC está por debajo del rango normal. Considera consultar a un profesional.',
        'en': 'Your BMI is below the normal range. Consider consulting a professional.',
        'fr': 'Votre IMC est inférieur à la plage normale. Envisagez de consulter un professionnel.',
        'de': 'Dein BMI liegt unter dem Normalbereich. Erwäge, eine Fachperson zu konsultieren.',
        'ru': 'Твой ИМТ ниже нормы. Рассмотри возможность консультации со специалистом.',
        'ar': 'مؤشر كتلة جسمكِ أقل من النطاق الطبيعي. ننصح باستشارة أخصائي.', 'hi': 'आपका बीएमआई सामान्य सीमा से कम है। किसी विशेषज्ञ से सलाह लेने पर विचार करें।', 'bn': 'আপনার বিএমআই স্বাভাবিক পরিসরের নিচে। একজন বিশেষজ্ঞের পরামর্শ নেওয়ার কথা বিবেচনা করুন।', 'pt': 'Seu IMC está abaixo da faixa normal. Considere consultar um profissional.',
      });
  String get evalWeightHigh => _t({
        'es': 'Tu IMC está por encima del rango normal. Considera consultar a un profesional.',
        'en': 'Your BMI is above the normal range. Consider consulting a professional.',
        'fr': 'Votre IMC est supérieur à la plage normale. Envisagez de consulter un professionnel.',
        'de': 'Dein BMI liegt über dem Normalbereich. Erwäge, eine Fachperson zu konsultieren.',
        'ru': 'Твой ИМТ выше нормы. Рассмотри возможность консультации со специалистом.',
        'ar': 'مؤشر كتلة جسمكِ أعلى من النطاق الطبيعي. ننصح باستشارة أخصائي.', 'hi': 'आपका बीएमआई सामान्य सीमा से ज़्यादा है। किसी विशेषज्ञ से सलाह लेने पर विचार करें।', 'bn': 'আপনার বিএমআই স্বাভাবিক পরিসরের উপরে। একজন বিশেষজ্ঞের পরামর্শ নেওয়ার কথা বিবেচনা করুন।', 'pt': 'Seu IMC está acima da faixa normal. Considere consultar um profissional.',
      });
  String get evalWeightNoHeight => _t({
        'es': 'Añade tu altura en Configuración para ver tu IMC.',
        'en': 'Add your height in Settings to see your BMI.',
        'fr': 'Ajoutez votre taille dans les paramètres pour voir votre IMC.',
        'de': 'Füge deine Größe in den Einstellungen hinzu, um deinen BMI zu sehen.',
        'ru': 'Добавь свой рост в Настройках, чтобы увидеть свой ИМТ.',
        'ar': 'أضيفي طولكِ في الإعدادات لرؤية مؤشر كتلة جسمكِ.', 'hi': 'अपना बीएमआई देखने के लिए सेटिंग्स में अपनी लंबाई जोड़ें।', 'bn': 'আপনার বিএমআই দেখতে সেটিংসে আপনার উচ্চতা যোগ করুন।', 'pt': 'Adicione sua altura nas Configurações para ver seu IMC.',
      });
  String get evalSleepGood => _t({
        'es': 'Duermes dentro del rango recomendado (7–9 horas).',
        'en': "You're sleeping within the recommended range (7–9 hours).",
        'fr': 'Vous dormez dans la plage recommandée (7 à 9 heures).',
        'de': 'Du schläfst im empfohlenen Bereich (7–9 Stunden).',
        'ru': 'Ты спишь в пределах рекомендованного диапазона (7–9 часов).',
        'ar': 'تنامين ضمن النطاق الموصى به (7–9 ساعات).', 'hi': 'आप अनुशंसित सीमा (7–9 घंटे) के भीतर सो रहे हैं।', 'bn': 'আপনি প্রস্তাবিত পরিসরে (৭–৯ ঘণ্টা) ঘুমাচ্ছেন।', 'pt': 'Você está dormindo dentro do intervalo recomendado (7–9 horas).',
      });
  String get evalSleepLow => _t({
        'es': 'Duermes menos de lo recomendado. Intenta llegar a 7–9 horas.',
        'en': "You're sleeping less than recommended. Try to reach 7–9 hours.",
        'fr': 'Vous dormez moins que recommandé. Essayez d\'atteindre 7 à 9 heures.',
        'de': 'Du schläfst weniger als empfohlen. Versuche, 7–9 Stunden zu erreichen.',
        'ru': 'Ты спишь меньше рекомендованного. Постарайся довести это до 7–9 часов.',
        'ar': 'تنامين أقل من الموصى به. حاولي الوصول إلى 7–9 ساعات.', 'hi': 'आप अनुशंसित से कम सो रहे हैं। 7–9 घंटे तक पहुंचने की कोशिश करें।', 'bn': 'আপনি প্রস্তাবিতের চেয়ে কম ঘুমাচ্ছেন। ৭–৯ ঘণ্টা ঘুমানোর চেষ্টা করুন।', 'pt': 'Você está dormindo menos do que o recomendado. Tente chegar a 7–9 horas.',
      });
  String get evalSleepHigh => _t({
        'es': 'Duermes más de lo habitual. Si te sientes cansada igual, coméntalo con tu médico.',
        'en': "You're sleeping more than usual. If you still feel tired, mention it to your doctor.",
        'fr': "Vous dormez plus que d'habitude. Si vous êtes toujours fatiguée, parlez-en à votre médecin.",
        'de': 'Du schläfst mehr als gewöhnlich. Falls du dich trotzdem müde fühlst, sprich mit deiner Ärztin.',
        'ru': 'Ты спишь больше обычного. Если всё равно чувствуешь усталость, обсуди это с врачом.',
        'ar': 'تنامين أكثر من المعتاد. إذا كنتِ ما زلتِ تشعرين بالتعب، ناقشي ذلك مع طبيبتك.', 'hi': 'आप सामान्य से ज़्यादा सो रहे हैं। अगर फिर भी थकान महसूस हो, तो अपने डॉक्टर को बताएं।', 'bn': 'আপনি স্বাভাবিকের চেয়ে বেশি ঘুমাচ্ছেন। তারপরও ক্লান্ত লাগলে, আপনার ডাক্তারকে জানান।', 'pt': 'Você está dormindo mais do que o normal. Se ainda se sentir cansada, converse com seu médico.',
      });
  String get evalWaterGood => _t({
        'es': 'Buena hidratación hoy. Sigue así.',
        'en': "Good hydration today. Keep it up.",
        'fr': "Bonne hydratation aujourd'hui. Continuez ainsi.",
        'de': 'Gute Flüssigkeitszufuhr heute. Weiter so.',
        'ru': 'Хорошая гидратация сегодня. Продолжай в том же духе.',
        'ar': 'ترطيب جيد اليوم. واصلي هكذا.', 'hi': 'आज अच्छी हाइड्रेशन है। ऐसे ही जारी रखें।', 'bn': 'আজ ভালো হাইড্রেশন হয়েছে। এভাবেই চালিয়ে যান।', 'pt': 'Boa hidratação hoje. Continue assim.',
      });
  String get evalWaterLow => _t({
        'es': 'Vas por debajo de la meta diaria de agua.',
        'en': "You're below your daily water goal.",
        'fr': "Vous êtes en dessous de votre objectif quotidien d'eau.",
        'de': 'Du liegst unter deinem täglichen Wasserziel.',
        'ru': 'Ты не дотягиваешь до дневной нормы воды.',
        'ar': 'أنتِ دون هدفكِ اليومي من الماء.', 'hi': 'आप अपने दैनिक पानी के लक्ष्य से पीछे हैं।', 'bn': 'আপনি আপনার দৈনিক পানির লক্ষ্যের নিচে আছেন।', 'pt': 'Você está abaixo da sua meta diária de água.',
      });
  String get evalTempNormal => _t({
        'es': 'Temperatura dentro del rango habitual.',
        'en': 'Temperature within the usual range.',
        'fr': 'Température dans la plage habituelle.',
        'de': 'Temperatur im üblichen Bereich.',
        'ru': 'Температура в пределах обычного диапазона.',
        'ar': 'درجة الحرارة ضمن النطاق المعتاد.', 'hi': 'तापमान सामान्य सीमा में है।', 'bn': 'তাপমাত্রা স্বাভাবিক পরিসরে আছে।', 'pt': 'Temperatura dentro da faixa habitual.',
      });
  String get evalTempShift => _t({
        'es': 'Se detecta un aumento sostenido de temperatura, posible señal de ovulación reciente.',
        'en': 'A sustained temperature rise was detected, a possible sign of recent ovulation.',
        'fr': "Une hausse soutenue de température a été détectée, signe possible d'une ovulation récente.",
        'de': 'Ein anhaltender Temperaturanstieg wurde erkannt, ein möglicher Hinweis auf einen kürzlichen Eisprung.',
        'ru': 'Обнаружено устойчивое повышение температуры — возможный признак недавней овуляции.',
        'ar': 'تم رصد ارتفاع مستمر في درجة الحرارة، وهو علامة محتملة على إباضة حديثة.', 'hi': 'तापमान में लगातार बढ़ोतरी देखी गई है, जो हाल ही में ओव्यूलेशन का संकेत हो सकता है।', 'bn': 'তাপমাত্রায় স্থায়ী বৃদ্ধি শনাক্ত হয়েছে, যা সাম্প্রতিক ডিম্বস্ফোটনের সম্ভাব্য লক্ষণ।', 'pt': 'Foi detectado um aumento sustentado de temperatura, possível sinal de ovulação recente.',
      });
  String get evalSexLifeSummary => _t({
        'es': 'Resumen de actividad registrada en los últimos 30 días.',
        'en': 'Summary of activity logged in the last 30 days.',
        'fr': "Résumé de l'activité enregistrée au cours des 30 derniers jours.",
        'de': 'Zusammenfassung der Aktivität der letzten 30 Tage.',
        'ru': 'Сводка активности, зарегистрированной за последние 30 дней.',
        'ar': 'ملخص النشاط المسجّل خلال آخر 30 يومًا.', 'hi': 'पिछले 30 दिनों में दर्ज गतिविधि का सारांश।', 'bn': 'গত ৩০ দিনে লগ করা কার্যকলাপের সারসংক্ষেপ।', 'pt': 'Resumo da atividade registrada nos últimos 30 dias.',
      });
  String get evalBreastSelfExamReminder => _t({
        'es': 'Se recomienda un autoexamen de mamas una vez al mes.',
        'en': 'A breast self-exam is recommended once a month.',
        'fr': 'Un autoexamen des seins est recommandé une fois par mois.',
        'de': 'Eine Brust-Selbstuntersuchung wird einmal im Monat empfohlen.',
        'ru': 'Рекомендуется проводить самообследование груди раз в месяц.',
        'ar': 'يُنصح بإجراء الفحص الذاتي للثدي مرة في الشهر.', 'hi': 'महीने में एक बार स्तन स्व-परीक्षण करने की सलाह दी जाती है।', 'bn': 'মাসে একবার স্তন স্ব-পরীক্ষা করার পরামর্শ দেওয়া হয়।', 'pt': 'Recomenda-se um autoexame das mamas uma vez por mês.',
      });
  String get evalBreastSelfExamOverdue => _t({
        'es': 'Han pasado más de 30 días desde tu último autoexamen.',
        'en': "It's been more than 30 days since your last self-exam.",
        'fr': 'Plus de 30 jours se sont écoulés depuis votre dernier autoexamen.',
        'de': 'Es sind mehr als 30 Tage seit deiner letzten Selbstuntersuchung vergangen.',
        'ru': 'С момента твоего последнего самообследования прошло больше 30 дней.',
        'ar': 'مرّ أكثر من 30 يومًا منذ آخر فحص ذاتي أجريتِه.', 'hi': 'आपके आखिरी स्व-परीक्षण को 30 दिनों से ज़्यादा हो गए हैं।', 'bn': 'আপনার শেষ স্ব-পরীক্ষার পর ৩০ দিনের বেশি হয়ে গেছে।', 'pt': 'Já se passaram mais de 30 dias desde seu último autoexame.',
      });
  String get meTimeline => _t({'es': 'Cronología', 'en': 'Timeline', 'fr': 'Chronologie', 'de': 'Zeitleiste', 'ru': 'Хронология', 'ar': 'الجدول الزمني', 'hi': 'टाइमलाइन', 'bn': 'সময়রেখা', 'pt': 'Cronologia',});
  String get meAllRecordsHere => _t({
        'es': 'Todos los registros están aquí',
        'en': 'All your entries are here',
        'fr': 'Tous vos enregistrements sont ici',
        'de': 'Alle deine Einträge sind hier',
        'ru': 'Все твои записи здесь',
        'ar': 'جميع سجلاتكِ هنا', 'hi': 'सभी रिकॉर्ड यहां हैं', 'bn': 'সব রেকর্ড এখানে আছে', 'pt': 'Todos os registros estão aqui',
      });
  String get meMyGoal => _t({'es': 'Mi objetivo', 'en': 'My goal', 'fr': 'Mon objectif', 'de': 'Mein Ziel', 'ru': 'Моя цель', 'ar': 'هدفي', 'hi': 'मेरा लक्ष्य', 'bn': 'আমার লক্ষ্য', 'pt': 'Meu objetivo',});
  String get meGoalTrackPeriod =>
      _t({'es': 'Seguir mi periodo', 'en': 'Track my period', 'fr': 'Suivre mes règles', 'de': 'Meine Periode verfolgen', 'ru': 'Отслеживать свою менструацию', 'ar': 'متابعة دورتي', 'hi': 'अपना पीरियड ट्रैक करना', 'bn': 'আমার পিরিয়ড ট্র্যাক করা', 'pt': 'Acompanhar meu período',});
  String get meGoalTryConceive =>
      _t({'es': 'Intento concebir', 'en': 'Trying to conceive', 'fr': 'Essai de conception', 'de': 'Kinderwunsch', 'ru': 'Пытаюсь забеременеть', 'ar': 'أحاول الحمل', 'hi': 'गर्भधारण की कोशिश करना', 'bn': 'গর্ভধারণের চেষ্টা করা', 'pt': 'Tentando engravidar',});
  String get meGoalTrackPregnancy => _t({
        'es': 'Seguir mi embarazo',
        'en': 'Track my pregnancy',
        'fr': 'Suivre ma grossesse',
        'de': 'Meine Schwangerschaft verfolgen',
        'ru': 'Отслеживать свою беременность',
        'ar': 'متابعة حملي', 'hi': 'अपनी गर्भावस्था ट्रैक करना', 'bn': 'আমার গর্ভাবস্থা ট্র্যাক করা', 'pt': 'Acompanhar minha gravidez',
      });

  // ---- Cuestionario rápido al elegir "Intentar concebir" por primera vez
  // (ver widgets/conceive_intake_sheet.dart) — solo 'es'/'en' traducidos a
  // mano; el resto de idiomas cae en español (comportamiento normal de
  // `_t`) hasta que se traduzcan, igual que cualquier texto nuevo de la app
  // mientras no se complete su localización. ----
  String get conceiveIntakeTitle => _t({'es': 'Intentando concebir', 'en': 'Trying to conceive'});
  String get conceiveIntakeSubtitle =>
      _t({'es': 'Un par de preguntas para ayudarte mejor. Puedes saltarlas si prefieres.', 'en': 'A couple of questions to help you better. You can skip them if you prefer.'});
  String get conceiveIntakeTargetDateQuestion =>
      _t({'es': '¿Para cuándo te gustaría quedar embarazada o tener a tu bebé?', 'en': 'When would you like to get pregnant or have your baby?'});
  String get conceiveIntakePickDate => _t({'es': 'Elegir fecha (opcional)', 'en': 'Choose a date (optional)'});
  String get conceiveIntakeDurationQuestion =>
      _t({'es': '¿Cuánto tiempo llevas intentando concebir?', 'en': 'How long have you been trying to conceive?'});
  String get conceiveDurationUnder3 => _t({'es': 'Menos de 3 meses', 'en': 'Less than 3 months'});
  String get conceiveDuration3to6 => _t({'es': '3-6 meses', 'en': '3-6 months'});
  String get conceiveDuration6to12 => _t({'es': '6-12 meses', 'en': '6-12 months'});
  String get conceiveDurationOver12 => _t({'es': 'Más de 12 meses', 'en': 'More than 12 months'});
  String get conceiveIntakeIrregularQuestion => _t({'es': '¿Tu ciclo es irregular?', 'en': 'Is your cycle irregular?'});
  String get conceiveIntakeContraceptionQuestion =>
      _t({'es': '¿Dejaste algún método anticonceptivo hace poco?', 'en': 'Did you recently stop using contraception?'});
  String get conceiveYes => _t({'es': 'Sí', 'en': 'Yes'});
  String get conceiveNo => _t({'es': 'No', 'en': 'No'});
  String get conceiveIntakeTargetLabel => _t({'es': 'Objetivo', 'en': 'Target'});
  String get conceiveIntakeCycleLengthQuestion =>
      _t({'es': '¿Cuál es la duración promedio de tu ciclo?', 'en': 'What is your average cycle length?'});
  String get conceiveIntakePeriodLengthQuestion =>
      _t({'es': '¿Cuál es la duración promedio de tu periodo?', 'en': 'What is your average period length?'});
  String get conceiveIntakeDaysUnit => _t({'es': 'días', 'en': 'days'});
  String get conceiveIntakeOvulationTestsQuestion =>
      _t({'es': '¿Usas tests de ovulación (OPK)?', 'en': 'Do you use ovulation tests (OPK)?'});
  String get conceiveIntakeConditionsQuestion => _t({
        'es': '¿Tienes alguna condición diagnosticada que afecte tu ciclo?',
        'en': 'Do you have any diagnosed condition that affects your cycle?',
      });
  String get conceiveConditionPcos => _t({'es': 'SOP', 'en': 'PCOS'});
  String get conceiveConditionEndometriosis => _t({'es': 'Endometriosis', 'en': 'Endometriosis'});
  String get conceiveConditionThyroid => _t({'es': 'Tiroides', 'en': 'Thyroid'});
  String get conceiveConditionOther => _t({'es': 'Otra', 'en': 'Other'});
  String get conceiveConditionNone => _t({'es': 'Ninguna', 'en': 'None'});
  String get conceiveIntakeConditionsNote => _t({
        'es': 'Tus predicciones pueden variar más de lo habitual en este caso.',
        'en': 'Your predictions may vary more than usual in this case.',
      });

  // Diálogo previo al cuestionario cuando ya había respuestas guardadas de
  // una vez anterior (no es la primera vez que se elige "Intentar
  // concebir") — evita forzar las 8 preguntas de nuevo si nada cambió, ver
  // maybeShowConceiveIntake en widgets/conceive_intake_sheet.dart.
  String get conceiveIntakeSameAsBeforeTitle =>
      _t({'es': '¿Sigue siendo la misma información?', 'en': 'Is this still the same information?'});
  String get conceiveIntakeSameAsBeforeBody => _t({
        'es': 'Ya respondiste estas preguntas antes. Puedes dejarlo igual o actualizarlo si algo cambió.',
        'en': 'You already answered these questions before. You can leave it as is or update it if something changed.',
      });
  String get conceiveIntakeSameAsBeforeYes => _t({'es': 'Sigue igual', 'en': 'Still the same'});
  String get conceiveIntakeSameAsBeforeUpdate => _t({'es': 'Actualizar', 'en': 'Update'});

  String get meReport => _t({'es': 'Informe', 'en': 'Report', 'fr': 'Rapport', 'de': 'Bericht', 'ru': 'Отчёт', 'ar': 'تقرير', 'hi': 'रिपोर्ट', 'bn': 'রিপোর্ট', 'pt': 'Relatório',});
  String get meCycleAnalysis =>
      _t({'es': 'Análisis del ciclo', 'en': 'Cycle analysis', 'fr': 'Analyse du cycle', 'de': 'Zyklusanalyse', 'ru': 'Анализ цикла', 'ar': 'تحليل الدورة', 'hi': 'चक्र विश्लेषण', 'bn': 'চক্র বিশ্লেষণ', 'pt': 'Análise do ciclo',});
  String get meDayUnit => _t({'es': 'día', 'en': 'day', 'fr': 'jour', 'de': 'Tag', 'ru': 'день', 'ar': 'يوم', 'hi': 'दिन', 'bn': 'দিন', 'pt': 'dia',});
  String get meAvgPeriod => _t({'es': 'Promedio de periodo', 'en': 'Average period', 'fr': 'Règles moyennes', 'de': 'Durchschnittliche Periode', 'ru': 'Средняя менструация', 'ar': 'متوسط الحيض', 'hi': 'औसत पीरियड', 'bn': 'গড় পিরিয়ড', 'pt': 'Período médio',});
  String get meAvgCycle => _t({'es': 'Promedio de ciclo', 'en': 'Average cycle', 'fr': 'Cycle moyen', 'de': 'Durchschnittlicher Zyklus', 'ru': 'Средний цикл', 'ar': 'متوسط الدورة', 'hi': 'औसत चक्र', 'bn': 'গড় চক্র', 'pt': 'Ciclo médio',});
  String get meLogThreePeriods => _t({
        'es': 'Registra 3 periodos para desbloquear el análisis',
        'en': 'Log 3 periods to unlock the analysis',
        'fr': 'Enregistrez 3 cycles pour débloquer l\'analyse',
        'de': 'Erfasse 3 Perioden, um die Analyse freizuschalten',
        'ru': 'Отметь 3 менструации, чтобы открыть анализ',
        'ar': 'سجّلي 3 دورات لفتح التحليل', 'hi': 'विश्लेषण अनलॉक करने के लिए 3 पीरियड दर्ज करें', 'bn': 'বিশ্লেষণ আনলক করতে ৩টি পিরিয়ড লগ করুন', 'pt': 'Registre 3 períodos para desbloquear a análise',
      });
  String get meLogPeriod => _t({'es': 'Registrar periodo', 'en': 'Log period', 'fr': 'Enregistrer les règles', 'de': 'Periode eintragen', 'ru': 'Отметить менструацию', 'ar': 'تسجيل الدورة', 'hi': 'पीरियड दर्ज करें', 'bn': 'পিরিয়ড লগ করুন', 'pt': 'Registrar período',});
  String get meSignInAndSync => _t({
        'es': 'Inicie sesión y sincronice sus datos',
        'en': 'Sign in and sync your data',
        'fr': 'Connectez-vous et synchronisez vos données',
        'de': 'Melde dich an und synchronisiere deine Daten',
        'ru': 'Войди и синхронизируй свои данные',
        'ar': 'سجّلي الدخول وزامني بياناتكِ', 'hi': 'लॉग इन करें और अपना डेटा सिंक करें', 'bn': 'লগ ইন করুন এবং আপনার তথ্য সিঙ্ক করুন', 'pt': 'Faça login e sincronize seus dados',
      });
  String get meSyncData => _t({'es': 'Sincronizar datos', 'en': 'Sync data', 'fr': 'Synchroniser les données', 'de': 'Daten synchronisieren', 'ru': 'Синхронизировать данные', 'ar': 'مزامنة البيانات', 'hi': 'डेटा सिंक करें', 'bn': 'তথ্য সিঙ্ক করুন', 'pt': 'Sincronizar dados',});
  String get meSignedInAs => _t({
        'es': 'Sesión iniciada como',
        'en': 'Signed in as',
        'fr': 'Connecté en tant que',
        'de': 'Angemeldet als',
        'ru': 'Вход выполнен как',
        'ar': 'تم تسجيل الدخول باسم', 'hi': 'इस रूप में लॉग इन है', 'bn': 'হিসেবে লগ ইন করা আছে', 'pt': 'Conectado como',
      });
  String get meManageAccount => _t({'es': 'Gestionar', 'en': 'Manage', 'fr': 'Gérer', 'de': 'Verwalten', 'ru': 'Управлять', 'ar': 'إدارة', 'hi': 'प्रबंधित करें', 'bn': 'পরিচালনা করুন', 'pt': 'Gerenciar',});

  // ---- Pantalla "Gestionar cuenta" ----
  String get accountScreenTitle => _t({'es': 'Mi cuenta', 'en': 'My account', 'fr': 'Mon compte', 'de': 'Mein Konto', 'ru': 'Мой аккаунт', 'ar': 'حسابي', 'hi': 'मेरा खाता', 'bn': 'আমার অ্যাকাউন্ট', 'pt': 'Minha conta',});
  String get accountChangePhoto =>
      _t({'es': 'Cambiar foto', 'en': 'Change photo', 'fr': 'Changer la photo', 'de': 'Foto ändern', 'ru': 'Изменить фото', 'ar': 'تغيير الصورة', 'hi': 'फोटो बदलें', 'bn': 'ছবি পরিবর্তন করুন', 'pt': 'Trocar foto',});
  String get accountNameSection =>
      _t({'es': 'Nombre', 'en': 'Name', 'fr': 'Nom', 'de': 'Name', 'ru': 'Имя', 'ar': 'الاسم', 'hi': 'नाम', 'bn': 'নাম', 'pt': 'Nome',});
  String get accountFirstNameLabel =>
      _t({'es': 'Nombre', 'en': 'First name', 'fr': 'Prénom', 'de': 'Vorname', 'ru': 'Имя', 'ar': 'الاسم الأول', 'hi': 'पहला नाम', 'bn': 'প্রথম নাম', 'pt': 'Nome',});
  String get accountLastNameLabel =>
      _t({'es': 'Apellido', 'en': 'Last name', 'fr': 'Nom de famille', 'de': 'Nachname', 'ru': 'Фамилия', 'ar': 'اسم العائلة', 'hi': 'उपनाम', 'bn': 'পদবি', 'pt': 'Sobrenome',});
  String get accountSaveName =>
      _t({'es': 'Guardar nombre', 'en': 'Save name', 'fr': 'Enregistrer le nom', 'de': 'Namen speichern', 'ru': 'Сохранить имя', 'ar': 'حفظ الاسم', 'hi': 'नाम सेव करें', 'bn': 'নাম সংরক্ষণ করুন', 'pt': 'Salvar nome',});
  String get accountNameSaved => _t({
        'es': 'Nombre actualizado.',
        'en': 'Name updated.',
        'fr': 'Nom mis à jour.',
        'de': 'Name aktualisiert.',
        'ru': 'Имя обновлено.',
        'ar': 'تم تحديث الاسم.', 'hi': 'नाम अपडेट हो गया।', 'bn': 'নাম আপডেট হয়েছে।', 'pt': 'Nome atualizado.',
      });
  String get accountDetailsSection =>
      _t({'es': 'Detalles de la cuenta', 'en': 'Account details', 'fr': 'Détails du compte', 'de': 'Kontodetails', 'ru': 'Данные аккаунта', 'ar': 'تفاصيل الحساب', 'hi': 'खाते का विवरण', 'bn': 'অ্যাকাউন্টের বিবরণ', 'pt': 'Detalhes da conta'});
  String get accountEmailLabel => _t({'es': 'Correo', 'en': 'Email', 'fr': 'E-mail', 'de': 'E-Mail', 'ru': 'Почта', 'ar': 'البريد الإلكتروني', 'hi': 'ईमेल', 'bn': 'ইমেইল', 'pt': 'E-mail'});
  String get accountSignInMethodLabel =>
      _t({'es': 'Inicio de sesión', 'en': 'Sign-in method', 'fr': 'Méthode de connexion', 'de': 'Anmeldemethode', 'ru': 'Способ входа', 'ar': 'طريقة تسجيل الدخول', 'hi': 'साइन-इन का तरीका', 'bn': 'সাইন-ইন পদ্ধতি', 'pt': 'Método de login'});
  String get accountSignInMethodEmail => _t({'es': 'Correo y contraseña', 'en': 'Email and password', 'fr': 'E-mail et mot de passe', 'de': 'E-Mail und Passwort', 'ru': 'Почта и пароль', 'ar': 'البريد الإلكتروني وكلمة المرور', 'hi': 'ईमेल और पासवर्ड', 'bn': 'ইমেইল ও পাসওয়ার্ড', 'pt': 'E-mail e senha'});
  String get accountSignInMethodGoogle => _t({'es': 'Google', 'en': 'Google', 'fr': 'Google', 'de': 'Google', 'ru': 'Google', 'ar': 'Google', 'hi': 'Google', 'bn': 'Google', 'pt': 'Google'});
  String get accountSignInMethodFacebook => _t({'es': 'Facebook', 'en': 'Facebook', 'fr': 'Facebook', 'de': 'Facebook', 'ru': 'Facebook', 'ar': 'Facebook', 'hi': 'Facebook', 'bn': 'Facebook', 'pt': 'Facebook'});
  String get accountMemberSinceLabel =>
      _t({'es': 'Miembro desde', 'en': 'Member since', 'fr': 'Membre depuis', 'de': 'Mitglied seit', 'ru': 'Участница с', 'ar': 'عضوة منذ', 'hi': 'सदस्यता की शुरुआत', 'bn': 'সদস্য হওয়ার তারিখ', 'pt': 'Membro desde'});
  String get accountSubscriptionSection =>
      _t({'es': 'Suscripción', 'en': 'Subscription', 'fr': 'Abonnement', 'de': 'Abonnement', 'ru': 'Подписка', 'ar': 'الاشتراك', 'hi': 'सदस्यता', 'bn': 'সাবস্ক্রিপশন', 'pt': 'Assinatura'});
  String get accountSubscriptionPremiumActive => _t({
        'es': 'Premium activo',
        'en': 'Premium active',
        'fr': 'Premium actif',
        'de': 'Premium aktiv',
        'ru': 'Premium активна',
        'ar': 'Premium مفعّل',
        'hi': 'प्रीमियम सक्रिय है',
        'bn': 'প্রিমিয়াম সক্রিয় আছে',
        'pt': 'Premium ativo',
      });
  String get accountSubscriptionInactive => _t({
        'es': 'Sin suscripción activa',
        'en': 'No active subscription',
        'fr': 'Aucun abonnement actif',
        'de': 'Kein aktives Abonnement',
        'ru': 'Нет активной подписки',
        'ar': 'لا يوجد اشتراك مفعّل',
        'hi': 'कोई सक्रिय सदस्यता नहीं है',
        'bn': 'কোনো সক্রিয় সাবস্ক্রিপশন নেই',
        'pt': 'Nenhuma assinatura ativa',
      });
  String get accountPhotoUpdateError => _t({
        'es': 'No se pudo actualizar la foto. Inténtalo de nuevo.',
        'en': "Couldn't update the photo. Please try again.",
        'fr': "Impossible de mettre à jour la photo. Réessayez.",
        'de': 'Foto konnte nicht aktualisiert werden. Bitte versuche es erneut.',
        'ru': 'Не удалось обновить фото. Попробуй ещё раз.',
        'ar': 'تعذّر تحديث الصورة. حاولي مرة أخرى.',
        'hi': 'फ़ोटो अपडेट नहीं हो सकी। कृपया फिर से कोशिश करें।',
        'bn': 'ছবি আপডেট করা যায়নি। আবার চেষ্টা করুন।',
        'pt': 'Não foi possível atualizar a foto. Tente novamente.',
      });

  // ---- Pantalla "Test de ovulación" (fase 7, pulido final) ----
  String get ovulationTestScreenTitle =>
      _t({'es': 'Test de ovulación', 'en': 'Ovulation test', 'fr': "Test d'ovulation", 'de': 'Eisprungtest', 'ru': 'Тест на овуляцию', 'ar': 'اختبار الإباضة', 'hi': 'ओव्यूलेशन टेस्ट', 'bn': 'ওভুলেশন টেস্ট', 'pt': 'Teste de ovulação'});
  String get ovulationTestIntro => _t({
        'es': 'Registra el resultado de tu test de ovulación (tira de LH) para llevar un control junto al resto de tu ciclo.',
        'en': 'Log the result of your ovulation test (LH strip) to track it alongside the rest of your cycle.',
        'fr': "Enregistrez le résultat de votre test d'ovulation (bandelette LH) pour le suivre avec le reste de votre cycle.",
        'de': 'Erfasse das Ergebnis deines Eisprungtests (LH-Teststreifen), um es zusammen mit deinem Zyklus zu verfolgen.',
        'ru': 'Отметь результат своего теста на овуляцию (полоска ЛГ), чтобы отслеживать его вместе с остальным циклом.',
        'ar': 'سجّلي نتيجة اختبار الإباضة (شريط LH) لمتابعتها مع بقية دورتكِ.',
        'hi': 'अपने ओव्यूलेशन टेस्ट (LH स्ट्रिप) का परिणाम दर्ज करें ताकि इसे अपने चक्र के बाकी हिस्सों के साथ ट्रैक कर सकें।',
        'bn': 'আপনার ওভুলেশন টেস্টের (LH স্ট্রিপ) ফলাফল রেকর্ড করুন যাতে এটি আপনার চক্রের বাকি অংশের সাথে ট্র্যাক করা যায়।',
        'pt': 'Registre o resultado do seu teste de ovulação (fita de LH) para acompanhá-lo junto com o resto do seu ciclo.',
      });
  String get ovulationTestDateLabel => _t({'es': 'Fecha', 'en': 'Date', 'fr': 'Date', 'de': 'Datum', 'ru': 'Дата', 'ar': 'التاريخ', 'hi': 'तारीख़', 'bn': 'তারিখ', 'pt': 'Data'});
  String get ovulationTestResultLabel =>
      _t({'es': 'Resultado', 'en': 'Result', 'fr': 'Résultat', 'de': 'Ergebnis', 'ru': 'Результат', 'ar': 'النتيجة', 'hi': 'परिणाम', 'bn': 'ফলাফল', 'pt': 'Resultado'});
  String get ovulationTestNegative => _t({'es': 'Negativo', 'en': 'Negative', 'fr': 'Négatif', 'de': 'Negativ', 'ru': 'Отрицательный', 'ar': 'سلبي', 'hi': 'नकारात्मक', 'bn': 'নেগেটিভ', 'pt': 'Negativo'});
  String get ovulationTestPositive => _t({'es': 'Positivo', 'en': 'Positive', 'fr': 'Positif', 'de': 'Positiv', 'ru': 'Положительный', 'ar': 'إيجابي', 'hi': 'सकारात्मक', 'bn': 'পজিটিভ', 'pt': 'Positivo'});
  String get ovulationTestPeak => _t({'es': 'Pico de LH', 'en': 'LH peak', 'fr': 'Pic de LH', 'de': 'LH-Höchstwert', 'ru': 'Пик ЛГ', 'ar': 'ذروة LH', 'hi': 'LH चरम', 'bn': 'LH পিক', 'pt': 'Pico de LH'});
  String get ovulationTestSave =>
      _t({'es': 'Guardar test', 'en': 'Save test', 'fr': 'Enregistrer le test', 'de': 'Test speichern', 'ru': 'Сохранить тест', 'ar': 'حفظ الاختبار', 'hi': 'टेस्ट सहेजें', 'bn': 'টেস্ট সংরক্ষণ করুন', 'pt': 'Salvar teste'});
  String get ovulationTestSaved =>
      _t({'es': 'Test guardado ✓', 'en': 'Test saved ✓', 'fr': 'Test enregistré ✓', 'de': 'Test gespeichert ✓', 'ru': 'Тест сохранён ✓', 'ar': 'تم حفظ الاختبار ✓', 'hi': 'टेस्ट सहेजा गया ✓', 'bn': 'টেস্ট সংরক্ষিত হয়েছে ✓', 'pt': 'Teste salvo ✓'});
  String get ovulationTestHistory =>
      _t({'es': 'Historial', 'en': 'History', 'fr': 'Historique', 'de': 'Verlauf', 'ru': 'История', 'ar': 'السجل', 'hi': 'इतिहास', 'bn': 'ইতিহাস', 'pt': 'Histórico'});
  String get ovulationTestEmptyHistory => _t({
        'es': 'Aún no has registrado ningún test.',
        'en': "You haven't logged any tests yet.",
        'fr': "Vous n'avez encore enregistré aucun test.",
        'de': 'Du hast noch keine Tests erfasst.',
        'ru': 'Ты ещё не отмечала ни одного теста.',
        'ar': 'لم تُسجّلي أي اختبار بعد.',
        'hi': 'आपने अभी तक कोई टेस्ट दर्ज नहीं किया है।',
        'bn': 'আপনি এখনও কোনো টেস্ট রেকর্ড করেননি।',
        'pt': 'Você ainda não registrou nenhum teste.',
      });

  // ---- Ajustes nuevos ----
  String get settingsInvitePartner =>
      _t({'es': 'Invitar a mi pareja', 'en': 'Invite my partner', 'fr': 'Inviter mon/ma partenaire', 'de': 'Meine Partnerin/meinen Partner einladen', 'ru': 'Пригласить моего партнёра', 'ar': 'دعوة شريكي', 'hi': 'अपने साथी को आमंत्रित करें', 'bn': 'আপনার সঙ্গীকে আমন্ত্রণ জানান', 'pt': 'Convidar meu parceiro(a)'});
  String get settingsPredictionConfig =>
      _t({'es': 'Configuración de predicción', 'en': 'Prediction settings', 'fr': 'Paramètres de prédiction', 'de': 'Vorhersageeinstellungen', 'ru': 'Настройки прогноза', 'ar': 'إعدادات التوقع', 'hi': 'पूर्वानुमान सेटिंग्स', 'bn': 'পূর্বাভাস সেটিংস', 'pt': 'Configurações de previsão'});
  String get settingsPredictionConfigHint => _t({
        'es': 'Para periodo, ciclo y ovulación',
        'en': 'For period, cycle and ovulation',
        'fr': 'Pour les règles, le cycle et l\'ovulation',
        'de': 'Für Periode, Zyklus und Eisprung',
        'ru': 'Для менструации, цикла и овуляции',
        'ar': 'للدورة والحيض والإباضة',
        'hi': 'पीरियड, चक्र और ओव्यूलेशन के लिए',
        'bn': 'পিরিয়ড, চক্র এবং ওভুলেশনের জন্য',
        'pt': 'Para período, ciclo e ovulação',
      });
  // Selector de paleta de colores del calendario (Periodo/Previsto/Fértil/
  // Hoy) — pensado para quien tiene dificultad distinguiendo los colores
  // pastel originales.
  String get settingsCalendarColorsTitle => _t({
        'es': 'Colores del calendario',
        'en': 'Calendar colors',
        'fr': 'Couleurs du calendrier',
        'de': 'Kalenderfarben',
        'ru': 'Цвета календаря',
        'ar': 'ألوان التقويم',
        'hi': 'कैलेंडर के रंग',
        'bn': 'ক্যালেন্ডারের রং',
        'pt': 'Cores do calendário',
      });
  String get settingsCalendarColorsHint => _t({
        'es': 'Elige la combinación que mejor distingas',
        'en': 'Choose the combination you can tell apart best',
        'fr': 'Choisissez la combinaison que vous distinguez le mieux',
        'de': 'Wähle die Kombination, die du am besten unterscheiden kannst',
        'ru': 'Выбери сочетание, которое тебе легче различать',
        'ar': 'اختاري التركيبة التي تميّزينها بشكل أفضل',
        'hi': 'वह संयोजन चुनें जिसे आप सबसे अच्छी तरह पहचान सकें',
        'bn': 'যে সংমিশ্রণটি আপনি সবচেয়ে ভালোভাবে আলাদা করতে পারেন তা বেছে নিন',
        'pt': 'Escolha a combinação que você consegue diferenciar melhor',
      });
  String get settingsCustomPaletteTitle => _t({
        'es': 'Personalizar colores',
        'en': 'Customize colors',
        'fr': 'Personnaliser les couleurs',
        'de': 'Farben anpassen',
        'ru': 'Настроить цвета',
        'ar': 'تخصيص الألوان',
        'hi': 'रंग अनुकूलित करें',
        'bn': 'রং কাস্টমাইজ করুন',
        'pt': 'Personalizar cores',
      });
  String get settingsCustomPaletteHint => _t({
        'es': 'Toca cada color para cambiarlo',
        'en': 'Tap each color to change it',
        'fr': 'Touchez chaque couleur pour la modifier',
        'de': 'Tippe auf jede Farbe, um sie zu ändern',
        'ru': 'Нажми на цвет, чтобы изменить его',
        'ar': 'اضغطي على كل لون لتغييره',
        'hi': 'रंग बदलने के लिए उसे थपथपाएं',
        'bn': 'রং পরিবর্তন করতে সেটিতে ট্যাপ করুন',
        'pt': 'Toque em cada cor para alterá-la',
      });
  String get settingsCustomPaletteLabelPeriod => _t({
        'es': 'Período',
        'en': 'Period',
        'fr': 'Règles',
        'de': 'Periode',
        'ru': 'Менструация',
        'ar': 'الدورة',
        'hi': 'पीरियड',
        'bn': 'পিরিয়ড',
        'pt': 'Período',
      });
  String get settingsCustomPaletteLabelPredictedFill => _t({
        'es': 'Previsto (relleno)',
        'en': 'Predicted (fill)',
        'fr': 'Prévu (remplissage)',
        'de': 'Vorhergesagt (Füllung)',
        'ru': 'Прогноз (заливка)',
        'ar': 'متوقع (تعبئة)',
        'hi': 'अनुमानित (भरण)',
        'bn': 'পূর্বাভাস (ভরাট)',
        'pt': 'Previsto (preenchimento)',
      });
  String get settingsCustomPaletteLabelPredictedBorder => _t({
        'es': 'Previsto (borde)',
        'en': 'Predicted (border)',
        'fr': 'Prévu (bordure)',
        'de': 'Vorhergesagt (Rand)',
        'ru': 'Прогноз (граница)',
        'ar': 'متوقع (حدود)',
        'hi': 'अनुमानित (बॉर्डर)',
        'bn': 'পূর্বাভাস (বর্ডার)',
        'pt': 'Previsto (borda)',
      });
  String get settingsCustomPaletteLabelFertileFill => _t({
        'es': 'Fértil (relleno)',
        'en': 'Fertile (fill)',
        'fr': 'Fertile (remplissage)',
        'de': 'Fruchtbar (Füllung)',
        'ru': 'Фертильность (заливка)',
        'ar': 'خصوبة (تعبئة)',
        'hi': 'उपजाऊ (भरण)',
        'bn': 'উর্বর (ভরাট)',
        'pt': 'Fértil (preenchimento)',
      });
  String get settingsCustomPaletteLabelFertileBorder => _t({
        'es': 'Fértil (borde)',
        'en': 'Fertile (border)',
        'fr': 'Fertile (bordure)',
        'de': 'Fruchtbar (Rand)',
        'ru': 'Фертильность (граница)',
        'ar': 'خصوبة (حدود)',
        'hi': 'उपजाऊ (बॉर्डर)',
        'bn': 'উর্বর (বর্ডার)',
        'pt': 'Fértil (borda)',
      });
  String get settingsCustomPaletteLabelToday => _t({
        'es': 'Hoy',
        'en': 'Today',
        'fr': "Aujourd'hui",
        'de': 'Heute',
        'ru': 'Сегодня',
        'ar': 'اليوم',
        'hi': 'आज',
        'bn': 'আজ',
        'pt': 'Hoje',
      });
  String get settingsCustomPaletteLabelOvulation => _t({
        'es': 'Ovulación',
        'en': 'Ovulation',
        'fr': 'Ovulation',
        'de': 'Eisprung',
        'ru': 'Овуляция',
        'ar': 'الإباضة',
        'hi': 'ओव्यूलेशन',
        'bn': 'ডিম্বস্ফোটন',
        'pt': 'Ovulação',
      });
  String get settingsCustomPaletteSave => _t({
        'es': 'Guardar',
        'en': 'Save',
        'fr': 'Enregistrer',
        'de': 'Speichern',
        'ru': 'Сохранить',
        'ar': 'حفظ',
        'hi': 'सेव करें',
        'bn': 'সংরক্ষণ করুন',
        'pt': 'Salvar',
      });
  String get settingsCustomPaletteCancel => _t({
        'es': 'Cancelar',
        'en': 'Cancel',
        'fr': 'Annuler',
        'de': 'Abbrechen',
        'ru': 'Отмена',
        'ar': 'إلغاء',
        'hi': 'रद्द करें',
        'bn': 'বাতিল করুন',
        'pt': 'Cancelar',
      });
  String get settingsCustomPaletteChooseColor => _t({
        'es': 'Elige un color',
        'en': 'Choose a color',
        'fr': 'Choisissez une couleur',
        'de': 'Wähle eine Farbe',
        'ru': 'Выбери цвет',
        'ar': 'اختاري لونًا',
        'hi': 'एक रंग चुनें',
        'bn': 'একটি রং বেছে নিন',
        'pt': 'Escolha uma cor',
      });
  String get settingsCalendarStyleTitle => _t({
        'es': 'Estilo de calendario',
        'en': 'Calendar style',
        'fr': 'Style de calendrier',
        'de': 'Kalenderstil',
        'ru': 'Стиль календаря',
        'ar': 'نمط التقويم',
        'hi': 'कैलेंडर शैली',
        'bn': 'ক্যালেন্ডার শৈলী',
        'pt': 'Estilo de calendário',
      });
  String get settingsCalendarStyleHint => _t({
        'es': 'Elige cómo se ve el calendario de la pestaña Calendario',
        'en': 'Choose how the calendar in the Calendar tab looks',
        'fr': 'Choisissez l\'apparence du calendrier dans l\'onglet Calendrier',
        'de': 'Wähle, wie der Kalender im Tab Kalender aussieht',
        'ru': 'Выбери, как будет выглядеть календарь на вкладке «Календарь»',
        'ar': 'اختاري شكل التقويم في تبويب التقويم',
        'hi': 'चुनें कि कैलेंडर टैब में कैलेंडर कैसा दिखे',
        'bn': 'ক্যালেন্ডার ট্যাবে ক্যালেন্ডারটি কেমন দেখাবে তা বেছে নিন',
        'pt': 'Escolha a aparência do calendário na aba Calendário',
      });
  String get settingsCalendarStyleClassic => _t({
        'es': 'Clásico',
        'en': 'Classic',
        'fr': 'Classique',
        'de': 'Klassisch',
        'ru': 'Классический',
        'ar': 'كلاسيكي',
        'hi': 'क्लासिक',
        'bn': 'ক্লাসিক',
        'pt': 'Clássico',
      });
  String get settingsCalendarStyleElegant => _t({
        'es': 'Elegante',
        'en': 'Elegant',
        'fr': 'Élégant',
        'de': 'Elegant',
        'ru': 'Элегантный',
        'ar': 'أنيق',
        'hi': 'एलिगेंट',
        'bn': 'মার্জিত',
        'pt': 'Elegante',
      });
  // Tercera opción de "Estilo de calendario" (ver CalendarGridIos) — le
  // faltaba esta entrada en el catálogo, causaba error de compilación
  // ("getter no definido") en settings_screen.dart al construir la lista
  // de opciones.
  String get settingsCalendarStyleIos => _t({
        'es': 'iOS',
        'en': 'iOS',
        'fr': 'iOS',
        'de': 'iOS',
        'ru': 'iOS',
        'ar': 'iOS',
        'hi': 'iOS',
        'bn': 'iOS',
        'pt': 'iOS',
      });

  // ---- Forma y relleno de las marcas de día (solo estilo "Clásico") ----
  String get settingsCalendarMarkerShapeTitle => _t({
        'es': 'Forma',
        'en': 'Shape',
        'fr': 'Forme',
        'de': 'Form',
        'ru': 'Форма',
        'ar': 'الشكل',
        'hi': 'आकार',
        'bn': 'আকৃতি',
        'pt': 'Forma',
      });
  String get settingsCalendarMarkerShapeHint => _t({
        'es': 'Elige la forma de los días marcados (solo estilo Clásico)',
        'en': 'Choose the shape of marked days (Classic style only)',
        'fr': 'Choisissez la forme des jours marqués (style Classique uniquement)',
        'de': 'Wähle die Form der markierten Tage (nur im Stil „Klassisch“)',
        'ru': 'Выбери форму отмеченных дней (только для классического стиля)',
        'ar': 'اختاري شكل الأيام المُعلَّمة (فقط في النمط الكلاسيكي)',
        'hi': 'चिह्नित दिनों का आकार चुनें (केवल क्लासिक शैली में)',
        'bn': 'চিহ্নিত দিনগুলোর আকৃতি বেছে নিন (শুধু ক্লাসিক শৈলীতে)',
        'pt': 'Escolha a forma dos dias marcados (somente no estilo Clássico)',
      });
  String get settingsCalendarMarkerShapeSquare => _t({
        'es': 'Cuadrado',
        'en': 'Square',
        'fr': 'Carré',
        'de': 'Quadrat',
        'ru': 'Квадрат',
        'ar': 'مربع',
        'hi': 'वर्ग',
        'bn': 'বর্গক্ষেত্র',
        'pt': 'Quadrado',
      });
  String get settingsCalendarMarkerShapeCircle => _t({
        'es': 'Círculo',
        'en': 'Circle',
        'fr': 'Cercle',
        'de': 'Kreis',
        'ru': 'Круг',
        'ar': 'دائرة',
        'hi': 'वृत्त',
        'bn': 'বৃত্ত',
        'pt': 'Círculo',
      });
  String get settingsCalendarMarkerShapeRaya => _t({
        'es': 'Raya',
        'en': 'Line',
        'fr': 'Trait',
        'de': 'Strich',
        'ru': 'Черта',
        'ar': 'خط',
        'hi': 'रेखा',
        'bn': 'দাগ',
        'pt': 'Traço',
      });
  String get settingsCalendarMarkerFillTitle => _t({
        'es': 'Relleno',
        'en': 'Fill',
        'fr': 'Remplissage',
        'de': 'Füllung',
        'ru': 'Заливка',
        'ar': 'التعبئة',
        'hi': 'भराव',
        'bn': 'ভরাট',
        'pt': 'Preenchimento',
      });
  String get settingsCalendarMarkerFillFilled => _t({
        'es': 'Con relleno',
        'en': 'Filled',
        'fr': 'Rempli',
        'de': 'Gefüllt',
        'ru': 'Сплошной',
        'ar': 'معبأ',
        'hi': 'भरा हुआ',
        'bn': 'ভরা',
        'pt': 'Preenchido',
      });
  String get settingsCalendarMarkerFillOutline => _t({
        'es': 'Sin relleno',
        'en': 'Outline only',
        'fr': 'Contour seulement',
        'de': 'Nur Umriss',
        'ru': 'Только контур',
        'ar': 'حدود فقط',
        'hi': 'केवल रूपरेखा',
        'bn': 'শুধু রূপরেখা',
        'pt': 'Apenas contorno',
      });

  String get calendarPaletteNamePastel => _t({
        'es': 'Pastel (original)',
        'en': 'Pastel (original)',
        // 'original' concuerda en género con "la palette" (femenino) en
        // francés — antes decía 'Pastel (original)', copiado tal cual del
        // español, sin la 'e' de concordancia.
        'fr': 'Pastel (originale)',
        'de': 'Pastell (Original)',
        'ru': 'Пастельная (оригинал)',
        'ar': 'باستيل (الأصلي)',
        'hi': 'पेस्टल (मूल)',
        'bn': 'প্যাস্টেল (মূল)',
        'pt': 'Pastel (original)',
      });
  String get calendarPaletteNameVivid => _t({'es': 'Vivo', 'en': 'Vivid', 'fr': 'Vif', 'de': 'Kräftig', 'ru': 'Яркая', 'ar': 'زاهي', 'hi': 'गहरा', 'bn': 'উজ্জ্বল', 'pt': 'Vivo'});
  String get calendarPaletteNameHighContrast => _t({
        'es': 'Alto contraste',
        'en': 'High contrast',
        'fr': 'Contraste élevé',
        'de': 'Hoher Kontrast',
        'ru': 'Высокий контраст',
        'ar': 'تباين عالٍ',
        'hi': 'उच्च कंट्रास्ट',
        'bn': 'হাই কনট্রাস্ট',
        'pt': 'Alto contraste',
      });
  String get calendarPaletteNameSuave => _t({
        'es': 'Suave',
        'en': 'Soft',
        'fr': 'Doux',
        'de': 'Sanft',
        'ru': 'Мягкая',
        'ar': 'ناعم',
        'hi': 'सौम्य',
        'bn': 'নরম',
        'pt': 'Suave',
      });
  String get calendarPaletteNameCalido => _t({
        'es': 'Cálido',
        'en': 'Warm',
        'fr': 'Chaud',
        'de': 'Warm',
        'ru': 'Тёплая',
        'ar': 'دافئ',
        'hi': 'गर्म',
        'bn': 'উষ্ণ',
        'pt': 'Quente',
      });
  String get calendarPaletteNameJoya => _t({
        'es': 'Joya',
        'en': 'Jewel',
        'fr': 'Bijou',
        'de': 'Juwel',
        'ru': 'Драгоценная',
        'ar': 'جوهرة',
        'hi': 'रत्न',
        'bn': 'রত্ন',
        'pt': 'Joia',
      });
  String get calendarPaletteNameCustom => _t({
        'es': 'Personalizado',
        'en': 'Custom',
        'fr': 'Personnalisé',
        'de': 'Benutzerdefiniert',
        'ru': 'Свой',
        'ar': 'مخصص',
        'hi': 'कस्टम',
        'bn': 'কাস্টম',
        'pt': 'Personalizado',
      });
  String get settingsPredictionCurrentValues => _t({
        'es': 'Valores actuales',
        'en': 'Current values',
        'fr': 'Valeurs actuelles',
        'de': 'Aktuelle Werte',
        'ru': 'Текущие значения',
        'ar': 'القيم الحالية',
        'hi': 'वर्तमान मान',
        'bn': 'বর্তমান মান',
        'pt': 'Valores atuais',
      });
  String get settingsPredictionCurrentValuesHint => _t({
        'es': 'Calculados a partir de tu historial de periodos. Se ajustan solos con cada registro nuevo.',
        'en': 'Calculated from your period history. They adjust automatically with every new entry.',
        'fr': 'Calculées à partir de votre historique de règles. Elles s\'ajustent automatiquement à chaque nouvelle saisie.',
        'de': 'Berechnet aus deinem Periodenverlauf. Sie passen sich automatisch mit jedem neuen Eintrag an.',
        'ru': 'Рассчитаны на основе твоей истории менструаций. Автоматически корректируются с каждой новой записью.',
        'ar': 'محسوبة استنادًا إلى سجل دوراتكِ. تتعدل تلقائيًا مع كل سجل جديد.',
        'hi': 'आपके पीरियड इतिहास के आधार पर गणना की गई। हर नई प्रविष्टि के साथ ये अपने आप समायोजित हो जाते हैं।',
        'bn': 'আপনার পিরিয়ড ইতিহাসের ভিত্তিতে গণনা করা হয়েছে। প্রতিটি নতুন এন্ট্রির সাথে এগুলো নিজে থেকেই সামঞ্জস্য হয়।',
        'pt': 'Calculados a partir do seu histórico de períodos. Eles se ajustam automaticamente a cada novo registro.',
      });
  String get settingsBirthYear => _t({'es': 'Año de nacimiento', 'en': 'Birth year', 'fr': 'Année de naissance', 'de': 'Geburtsjahr', 'ru': 'Год рождения', 'ar': 'سنة الميلاد', 'hi': 'जन्म वर्ष', 'bn': 'জন্ম সাল', 'pt': 'Ano de nascimento'});
  String get settingsFollowOthersCycles =>
      _t({'es': 'Seguir ciclos de otros', 'en': "Follow others' cycles", 'fr': "Suivre le cycle d'autres personnes", 'de': 'Zyklen anderer verfolgen', 'ru': 'Следить за циклами других', 'ar': 'متابعة دورات الآخرين', 'hi': 'दूसरों के चक्र फ़ॉलो करें', 'bn': 'অন্যদের চক্র অনুসরণ করুন', 'pt': 'Seguir os ciclos de outras pessoas'});
  String get settingsExportForDoctor => _t({
        'es': 'Exportar datos a un documento para el doctor',
        'en': 'Export data to a document for your doctor',
        'fr': 'Exporter les données dans un document pour le médecin',
        'de': 'Daten als Dokument für den Arzt exportieren',
        'ru': 'Экспортировать данные в документ для врача',
        'ar': 'تصدير البيانات إلى مستند لطبيبتكِ',
        'hi': 'डॉक्टर के लिए डेटा को दस्तावेज़ में निर्यात करें',
        'bn': 'ডাক্তারের জন্য ডেটা একটি ডকুমেন্টে এক্সপোর্ট করুন',
        'pt': 'Exportar dados para um documento para o médico',
      });
  String get settingsDeleteAllData =>
      _t({'es': 'Borrar todos los datos', 'en': 'Delete all data', 'fr': 'Supprimer toutes les données', 'de': 'Alle Daten löschen', 'ru': 'Удалить все данные', 'ar': 'حذف جميع البيانات', 'hi': 'सभी डेटा हटाएं', 'bn': 'সব ডেটা মুছে ফেলুন', 'pt': 'Excluir todos os dados'});
  String get settingsDeleteAllDataConfirmTitle => _t({
        'es': '¿Borrar todos los datos?',
        'en': 'Delete all data?',
        'fr': 'Supprimer toutes les données ?',
        'de': 'Alle Daten löschen?',
        'ru': 'Удалить все данные?',
        'ar': 'هل تريدين حذف جميع البيانات؟',
        'hi': 'क्या सभी डेटा हटाना है?',
        'bn': 'সব ডেটা মুছে ফেলবেন?',
        'pt': 'Excluir todos os dados?',
      });
  String get settingsDeleteAllDataConfirmBody => _t({
        'es': 'Se eliminarán permanentemente todos tus registros del ciclo (periodos, síntomas, temperatura, diario) y todos tus ajustes (perfil, tema, recordatorios, idioma). Esta acción no se puede deshacer. Tu cuenta seguirá existiendo, con sesión iniciada, como si acabaras de registrarte.',
        'en': 'All your cycle records (periods, symptoms, temperature, diary) and all your settings (profile, theme, reminders, language) will be permanently deleted. This action cannot be undone. Your account will still exist, signed in, as if you had just registered.',
        'fr': "Toutes vos données de cycle (règles, symptômes, température, journal) et tous vos paramètres (profil, thème, rappels, langue) seront supprimés définitivement. Cette action est irréversible. Votre compte continuera d'exister, connecté, comme si vous veniez de vous inscrire.",
        'de': 'Alle deine Zyklusdaten (Perioden, Symptome, Temperatur, Tagebuch) und alle deine Einstellungen (Profil, Design, Erinnerungen, Sprache) werden dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden. Dein Konto bleibt bestehen, angemeldet, als hättest du dich gerade erst registriert.',
        'ru': 'Все твои записи цикла (менструации, симптомы, температура, дневник) и все твои настройки (профиль, тема, напоминания, язык) будут удалены безвозвратно. Это действие нельзя отменить. Твой аккаунт продолжит существовать, с активной сессией, как будто ты только что зарегистрировалась.',
        'ar': 'سيتم حذف جميع سجلات دورتكِ (الدورات، الأعراض، درجة الحرارة، اليوميات) وجميع إعداداتكِ (الملف الشخصي، السمة، التذكيرات، اللغة) نهائيًا. لا يمكن التراجع عن هذا الإجراء. سيظل حسابكِ موجودًا، ومسجلاً الدخول، كما لو كنتِ قد سجّلتِ للتو.',
        'hi': 'आपके चक्र के सभी रिकॉर्ड (पीरियड, लक्षण, तापमान, डायरी) और आपकी सभी सेटिंग्स (प्रोफ़ाइल, थीम, रिमाइंडर, भाषा) स्थायी रूप से हटा दी जाएंगी। इस कार्रवाई को पूर्ववत नहीं किया जा सकता। आपका खाता मौजूद रहेगा, लॉग-इन रहेगा, जैसे आपने अभी-अभी पंजीकरण किया हो।',
        'bn': 'আপনার চক্রের সব রেকর্ড (পিরিয়ড, উপসর্গ, তাপমাত্রা, ডায়েরি) এবং আপনার সব সেটিংস (প্রোফাইল, থিম, রিমাইন্ডার, ভাষা) স্থায়ীভাবে মুছে ফেলা হবে। এই কাজটি পূর্বাবস্থায় ফেরানো যাবে না। আপনার অ্যাকাউন্ট থেকে যাবে, লগ-ইন অবস্থায়, যেন আপনি এইমাত্র নিবন্ধন করেছেন।',
        'pt': 'Todos os seus registros de ciclo (períodos, sintomas, temperatura, diário) e todas as suas configurações (perfil, tema, lembretes, idioma) serão excluídos permanentemente. Essa ação não pode ser desfeita. Sua conta continuará existindo, com a sessão iniciada, como se você tivesse acabado de se cadastrar.',
      });
  String get settingsDeleteAllDataSuccess => _t({
        'es': 'Todos los datos se han borrado ✓',
        'en': 'All data has been deleted ✓',
        'fr': 'Toutes les données ont été supprimées ✓',
        'de': 'Alle Daten wurden gelöscht ✓',
        'ru': 'Все данные удалены ✓',
        'ar': 'تم حذف جميع البيانات ✓',
        'hi': 'सभी डेटा हटा दिया गया है ✓',
        'bn': 'সব ডেটা মুছে ফেলা হয়েছে ✓',
        'pt': 'Todos os dados foram excluídos ✓',
      });
  String get deleteAction => _t({'es': 'Borrar', 'en': 'Delete', 'fr': 'Supprimer', 'de': 'Löschen', 'ru': 'Удалить', 'ar': 'حذف', 'hi': 'हटाएं', 'bn': 'মুছুন', 'pt': 'Excluir',});
  String get settingsDeleteConfirmPasswordTitle => _t({
        'es': 'Confirma tu contraseña',
        'en': 'Confirm your password',
        'fr': 'Confirmez votre mot de passe',
        'de': 'Bestätige dein Passwort',
        'ru': 'Подтверди свой пароль',
        'ar': 'أكدي كلمة المرور', 'hi': 'अपने पासवर्ड की पुष्टि करें', 'bn': 'আপনার পাসওয়ার্ড নিশ্চিত করুন', 'pt': 'Confirme sua senha',
      });
  String get settingsDeleteConfirmPasswordBody => _t({
        'es': 'Por seguridad, escribe la contraseña con la que iniciaste sesión antes de borrar todos tus datos.',
        'en': 'For security, enter the password you signed in with before deleting all your data.',
        'fr': 'Pour votre sécurité, saisissez le mot de passe avec lequel vous vous êtes connectée avant de supprimer toutes vos données.',
        'de': 'Aus Sicherheitsgründen gib das Passwort ein, mit dem du dich angemeldet hast, bevor du alle deine Daten löschst.',
        'ru': 'Для безопасности введи пароль, с которым ты вошла, прежде чем удалить все свои данные.',
        'ar': 'لأسباب أمنية، أدخلي كلمة المرور التي سجّلتِ بها الدخول قبل حذف جميع بياناتكِ.', 'hi': 'सुरक्षा कारणों से, अपना सारा डेटा हटाने से पहले वह पासवर्ड डालें जिससे आपने लॉग इन किया था।', 'bn': 'নিরাপত্তার জন্য, আপনার সব তথ্য মুছে ফেলার আগে যে পাসওয়ার্ড দিয়ে লগ ইন করেছিলেন তা লিখুন।', 'pt': 'Por segurança, digite a senha com que você entrou antes de excluir todos os seus dados.',
      });
  String get settingsDeleteConfirmPasswordHint =>
      _t({'es': 'Contraseña', 'en': 'Password', 'fr': 'Mot de passe', 'de': 'Passwort', 'ru': 'Пароль', 'ar': 'كلمة المرور', 'hi': 'पासवर्ड', 'bn': 'পাসওয়ার্ড', 'pt': 'Senha',});
  String get settingsDeleteConfirmSocialBody => _t({
        'es': 'Por seguridad, vuelve a iniciar sesión con la misma cuenta antes de borrar todos tus datos.',
        'en': 'For security, sign in again with the same account before deleting all your data.',
        'fr': 'Pour votre sécurité, reconnectez-vous avec le même compte avant de supprimer toutes vos données.',
        'de': 'Aus Sicherheitsgründen melde dich erneut mit demselben Konto an, bevor du alle deine Daten löschst.',
        'ru': 'Для безопасности снова войди с тем же аккаунтом, прежде чем удалить все свои данные.',
        'ar': 'لأسباب أمنية، سجّلي الدخول مجددًا بنفس الحساب قبل حذف جميع بياناتكِ.', 'hi': 'सुरक्षा कारणों से, अपना सारा डेटा हटाने से पहले उसी खाते से दोबारा लॉग इन करें।', 'bn': 'নিরাপত্তার জন্য, আপনার সব তথ্য মুছে ফেলার আগে একই অ্যাকাউন্ট দিয়ে আবার লগ ইন করুন।', 'pt': 'Por segurança, faça login novamente com a mesma conta antes de excluir todos os seus dados.',
      });
  String get settingsDeleteConfirmAction =>
      _t({'es': 'Confirmar', 'en': 'Confirm', 'fr': 'Confirmer', 'de': 'Bestätigen', 'ru': 'Подтвердить', 'ar': 'تأكيد', 'hi': 'पुष्टि करें', 'bn': 'নিশ্চিত করুন', 'pt': 'Confirmar',});
  String get settingsDeleteConfirmWrongPassword => _t({
        'es': 'Contraseña incorrecta. No se ha borrado nada.',
        'en': 'Incorrect password. Nothing was deleted.',
        'fr': "Mot de passe incorrect. Rien n'a été supprimé.",
        'de': 'Falsches Passwort. Es wurde nichts gelöscht.',
        'ru': 'Неверный пароль. Ничего не было удалено.',
        'ar': 'كلمة مرور غير صحيحة. لم يتم حذف أي شيء.', 'hi': 'गलत पासवर्ड। कुछ भी नहीं हटाया गया।', 'bn': 'ভুল পাসওয়ার্ড। কিছুই মোছা হয়নি।', 'pt': 'Senha incorreta. Nada foi excluído.',
      });
  String get settingsDeleteAccount =>
      _t({'es': 'Borrar cuenta', 'en': 'Delete account', 'fr': 'Supprimer le compte', 'de': 'Konto löschen', 'ru': 'Удалить аккаунт', 'ar': 'حذف الحساب', 'hi': 'खाता हटाएं', 'bn': 'অ্যাকাউন্ট মুছুন', 'pt': 'Excluir conta',});
  String get settingsDeleteAccountConfirmTitle => _t({
        'es': '¿Borrar tu cuenta?',
        'en': 'Delete your account?',
        'fr': 'Supprimer votre compte ?',
        'de': 'Dein Konto löschen?',
        'ru': 'Удалить свой аккаунт?',
        'ar': 'هل تريدين حذف حسابكِ؟', 'hi': 'क्या आप अपना खाता हटाना चाहते हैं?', 'bn': 'আপনার অ্যাকাউন্ট মুছে ফেলবেন?', 'pt': 'Excluir sua conta?',
      });
  String get settingsDeleteAccountConfirmBody => _t({
        'es': 'Se eliminará tu cuenta por completo: registros del ciclo, ajustes y tu acceso a CicloPlus. No podrás recuperarla. Esta acción no se puede deshacer.',
        'en': "Your account will be permanently deleted: cycle records, settings, and your access to CicloPlus. You won't be able to recover it. This action cannot be undone.",
        'fr': "Votre compte sera définitivement supprimé : données de cycle, paramètres et votre accès à CicloPlus. Vous ne pourrez pas le récupérer. Cette action est irréversible.",
        'de': 'Dein Konto wird endgültig gelöscht: Zyklusdaten, Einstellungen und dein Zugang zu CicloPlus. Du kannst es nicht wiederherstellen. Diese Aktion kann nicht rückgängig gemacht werden.',
        'ru': 'Твой аккаунт будет удалён полностью: записи цикла, настройки и твой доступ к CicloPlus. Ты не сможешь его восстановить. Это действие нельзя отменить.',
        'ar': 'سيتم حذف حسابكِ بالكامل: سجلات الدورة، الإعدادات، ووصولكِ إلى CicloPlus. لن تتمكني من استعادته. لا يمكن التراجع عن هذا الإجراء.', 'hi': 'आपका खाता पूरी तरह हटा दिया जाएगा: चक्र के रिकॉर्ड, सेटिंग्स और CicloPlus तक आपकी पहुंच। आप इसे वापस नहीं पा सकेंगे। यह कार्रवाई पूर्ववत नहीं की जा सकती।', 'bn': 'আপনার অ্যাকাউন্ট সম্পূর্ণরূপে মুছে যাবে: চক্রের রেকর্ড, সেটিংস এবং CicloPlus-এ আপনার প্রবেশাধিকার। আপনি এটি ফিরে পাবেন না। এই কাজটি বাতিল করা যাবে না।', 'pt': 'Sua conta será excluída permanentemente: registros de ciclo, configurações e seu acesso ao CicloPlus. Você não poderá recuperá-la. Esta ação não pode ser desfeita.',
      });
  String get settingsDeleteAccountConfirmPasswordBody => _t({
        'es': 'Por seguridad, escribe la contraseña con la que iniciaste sesión antes de borrar tu cuenta.',
        'en': 'For security, enter the password you signed in with before deleting your account.',
        'fr': 'Pour votre sécurité, saisissez le mot de passe avec lequel vous vous êtes connectée avant de supprimer votre compte.',
        'de': 'Aus Sicherheitsgründen gib das Passwort ein, mit dem du dich angemeldet hast, bevor du dein Konto löschst.',
        'ru': 'Для безопасности введи пароль, с которым ты вошла, прежде чем удалить свой аккаунт.',
        'ar': 'لأسباب أمنية، أدخلي كلمة المرور التي سجّلتِ بها الدخول قبل حذف حسابكِ.', 'hi': 'सुरक्षा कारणों से, अपना खाता हटाने से पहले वह पासवर्ड डालें जिससे आपने लॉग इन किया था।', 'bn': 'নিরাপত্তার জন্য, আপনার অ্যাকাউন্ট মুছে ফেলার আগে যে পাসওয়ার্ড দিয়ে লগ ইন করেছিলেন তা লিখুন।', 'pt': 'Por segurança, digite a senha com que você entrou antes de excluir sua conta.',
      });
  String get settingsDeleteAccountConfirmSocialBody => _t({
        'es': 'Por seguridad, vuelve a iniciar sesión con la misma cuenta antes de borrar tu cuenta.',
        'en': 'For security, sign in again with the same account before deleting your account.',
        'fr': 'Pour votre sécurité, reconnectez-vous avec le même compte avant de supprimer votre compte.',
        'de': 'Aus Sicherheitsgründen melde dich erneut mit demselben Konto an, bevor du dein Konto löschst.',
        'ru': 'Для безопасности снова войди с тем же аккаунтом, прежде чем удалить свой аккаунт.',
        'ar': 'لأسباب أمنية، سجّلي الدخول مجددًا بنفس الحساب قبل حذف حسابكِ.', 'hi': 'सुरक्षा कारणों से, अपना खाता हटाने से पहले उसी खाते से दोबारा लॉग इन करें।', 'bn': 'নিরাপত্তার জন্য, আপনার অ্যাকাউন্ট মুছে ফেলার আগে একই অ্যাকাউন্ট দিয়ে আবার লগ ইন করুন।', 'pt': 'Por segurança, faça login novamente com a mesma conta antes de excluir sua conta.',
      });
  String get settingsDeleteAccountSuccess => _t({
        'es': 'Tu cuenta se ha borrado. Hasta pronto 💜',
        'en': 'Your account has been deleted. See you soon 💜',
        'fr': 'Votre compte a été supprimé. À bientôt 💜',
        'de': 'Dein Konto wurde gelöscht. Bis bald 💜',
        'ru': 'Твой аккаунт удалён. До скорого 💜',
        'ar': 'تم حذف حسابكِ. إلى اللقاء 💜', 'hi': 'आपका खाता हटा दिया गया है। फिर मिलेंगे 💜', 'bn': 'আপনার অ্যাকাউন্ট মুছে ফেলা হয়েছে। শীঘ্রই দেখা হবে 💜', 'pt': 'Sua conta foi excluída. Até breve 💜',
      });
  String get settingsFaceIdPassword =>
      _t({'es': 'Face ID & contraseña', 'en': 'Face ID & password', 'fr': 'Face ID et mot de passe', 'de': 'Face ID & Passwort', 'ru': 'Face ID и пароль', 'ar': 'Face ID وكلمة المرور', 'hi': 'Face ID और पासवर्ड', 'bn': 'Face ID ও পাসওয়ার্ড', 'pt': 'Face ID e senha',});
  String get settingsFaceIdEnabledConfirm => _t({
        'es': 'Face ID y contraseña activados 🔒',
        'en': 'Face ID & password enabled 🔒',
        'fr': 'Face ID et mot de passe activés 🔒',
        'de': 'Face ID & Passwort aktiviert 🔒',
        'ru': 'Face ID и пароль включены 🔒',
        'ar': 'تم تفعيل Face ID وكلمة المرور 🔒', 'hi': 'Face ID और पासवर्ड चालू 🔒', 'bn': 'Face ID ও পাসওয়ার্ড চালু হয়েছে 🔒', 'pt': 'Face ID e senha ativados 🔒',
      });
  String get settingsFaceIdDisabledConfirm => _t({
        'es': 'Face ID y contraseña desactivados',
        'en': 'Face ID & password disabled',
        'fr': 'Face ID et mot de passe désactivés',
        'de': 'Face ID & Passwort deaktiviert',
        'ru': 'Face ID и пароль отключены',
        'ar': 'تم إلغاء تفعيل Face ID وكلمة المرور', 'hi': 'Face ID और पासवर्ड बंद', 'bn': 'Face ID ও পাসওয়ার্ড বন্ধ হয়েছে', 'pt': 'Face ID e senha desativados',
      });
  String get settingsCustomOptions =>
      _t({'es': 'Opciones personalizadas', 'en': 'Custom options', 'fr': 'Options personnalisées', 'de': 'Benutzerdefinierte Optionen', 'ru': 'Персональные настройки', 'ar': 'خيارات مخصصة', 'hi': 'कस्टम विकल्प', 'bn': 'কাস্টম অপশন', 'pt': 'Opções personalizadas',});
  String get settingsAppleHealth => _t({'es': 'Apple Salud', 'en': 'Apple Health', 'fr': 'Apple Santé', 'de': 'Apple Health', 'ru': 'Apple Health', 'ar': 'Apple Health', 'hi': 'Apple Health', 'bn': 'Apple Health', 'pt': 'Apple Saúde',});
  String get settingsAppleWatch => _t({'es': 'Apple Watch', 'en': 'Apple Watch', 'fr': 'Apple Watch', 'de': 'Apple Watch', 'ru': 'Apple Watch', 'ar': 'Apple Watch', 'hi': 'Apple Watch', 'bn': 'Apple Watch', 'pt': 'Apple Watch',});
  String get settingsWidget => _t({'es': 'Widget', 'en': 'Widget', 'fr': 'Widget', 'de': 'Widget', 'ru': 'Виджет', 'ar': 'الودجة', 'hi': 'Widget', 'bn': 'Widget', 'pt': 'Widget',});
  String get settingsForum => _t({'es': 'Foro', 'en': 'Forum', 'fr': 'Forum', 'de': 'Forum', 'ru': 'Форум', 'ar': 'المنتدى', 'hi': 'फोरम', 'bn': 'ফোরাম', 'pt': 'Fórum',});

  // ---- Pantallas informativas "próximamente" con diseño propio (fase 7) ----
  String get appleWatchScreenSubtitle => _t({
        'es': 'Pronto podrás ver tu ciclo, registrar síntomas y recibir recordatorios directamente desde tu Apple Watch.',
        'en': "Soon you'll be able to see your cycle, log symptoms and get reminders right from your Apple Watch.",
        'fr': "Bientôt, vous pourrez voir votre cycle, enregistrer des symptômes et recevoir des rappels directement depuis votre Apple Watch.",
        'de': 'Bald kannst du deinen Zyklus sehen, Symptome erfassen und Erinnerungen direkt auf deiner Apple Watch erhalten.',
        'ru': 'Скоро ты сможешь видеть свой цикл, отмечать симптомы и получать напоминания прямо с твоих Apple Watch.',
        'ar': 'قريبًا ستتمكنين من رؤية دورتكِ وتسجيل الأعراض وتلقي التذكيرات مباشرة من ساعة Apple Watch.', 'hi': 'जल्द ही आप अपने Apple Watch से सीधे अपना चक्र देख पाएंगे, लक्षण दर्ज कर पाएंगे और रिमाइंडर पा सकेंगे।', 'bn': 'শীঘ্রই আপনি সরাসরি আপনার Apple Watch থেকে আপনার চক্র দেখতে, লক্ষণ লগ করতে এবং রিমাইন্ডার পেতে পারবেন।', 'pt': 'Em breve você poderá ver seu ciclo, registrar sintomas e receber lembretes direto do seu Apple Watch.',
      });
  String get widgetScreenSubtitle => _t({
        'es': 'Estamos preparando un widget para tu pantalla de inicio, con tu día de ciclo y próximas predicciones de un vistazo.',
        'en': "We're preparing a home screen widget with your cycle day and upcoming predictions at a glance.",
        'fr': "Nous préparons un widget pour votre écran d'accueil, avec votre jour de cycle et vos prochaines prédictions en un coup d'œil.",
        'de': 'Wir bereiten ein Homescreen-Widget vor, das deinen Zyklustag und kommende Vorhersagen auf einen Blick zeigt.',
        'ru': 'Мы готовим виджет для твоего домашнего экрана с днём твоего цикла и ближайшими прогнозами на первый взгляд.',
        'ar': 'نُجهّز ودجة لشاشتكِ الرئيسية تعرض يوم دورتكِ والتوقعات القادمة بنظرة واحدة.', 'hi': 'हम एक होम स्क्रीन विजेट तैयार कर रहे हैं, जिसमें आपके चक्र का दिन और आने वाली भविष्यवाणियां एक नज़र में दिखेंगी।', 'bn': 'আমরা একটি হোম স্ক্রিন উইজেট তৈরি করছি, যেখানে এক নজরে আপনার চক্রের দিন এবং আসন্ন পূর্বাভাস দেখা যাবে।', 'pt': 'Estamos preparando um widget para a tela inicial, com seu dia do ciclo e próximas previsões em um só lugar.',
      });
  String get forumScreenSubtitle => _t({
        'es': 'Muy pronto podrás compartir experiencias y resolver dudas con otras personas de la comunidad CicloPlus.',
        'en': "Very soon you'll be able to share experiences and ask questions with other people in the CicloPlus community.",
        'fr': "Très bientôt, vous pourrez partager vos expériences et poser vos questions avec d'autres membres de la communauté CicloPlus.",
        'de': 'Schon bald kannst du Erfahrungen teilen und Fragen mit anderen Mitgliedern der CicloPlus-Community austauschen.',
        'ru': 'Очень скоро ты сможешь делиться опытом и задавать вопросы вместе с другими людьми из сообщества CicloPlus.',
        'ar': 'قريبًا جدًا ستتمكنين من مشاركة تجاربكِ وطرح أسئلتكِ مع أشخاص آخرين في مجتمع CicloPlus.', 'hi': 'बहुत जल्द आप CicloPlus समुदाय के अन्य लोगों के साथ अनुभव साझा कर पाएंगे और सवाल पूछ पाएंगे।', 'bn': 'খুব শীঘ্রই আপনি CicloPlus কমিউনিটির অন্যান্য মানুষের সাথে অভিজ্ঞতা শেয়ার করতে এবং প্রশ্ন জিজ্ঞাসা করতে পারবেন।', 'pt': 'Muito em breve você poderá compartilhar experiências e tirar dúvidas com outras pessoas da comunidade CicloPlus.',
      });
  String get comingSoonGotIt => _t({'es': 'Entendido', 'en': 'Got it', 'fr': "J'ai compris", 'de': 'Verstanden', 'ru': 'Понятно', 'ar': 'حسنًا', 'hi': 'समझ गया', 'bn': 'বুঝেছি', 'pt': 'Entendi',});
  String get settingsRemoveAdsForever =>
      _t({'es': 'Elimina los anuncios para siempre', 'en': 'Remove ads forever', 'fr': 'Supprimer les publicités pour toujours', 'de': 'Werbung für immer entfernen', 'ru': 'Убрать рекламу навсегда', 'ar': 'إزالة الإعلانات للأبد', 'hi': 'विज्ञापन हमेशा के लिए हटाएं', 'bn': 'বিজ্ঞাপন চিরতরে সরান', 'pt': 'Remova os anúncios para sempre',});
  String get settingsWhyAdsQuestion =>
      _t({'es': '¿por qué veo anuncios?', 'en': 'why am I seeing ads?', 'fr': 'pourquoi je vois des publicités ?', 'de': 'warum sehe ich Werbung?', 'ru': 'почему я вижу рекламу?', 'ar': 'لماذا أرى إعلانات؟', 'hi': 'मुझे विज्ञापन क्यों दिख रहे हैं?', 'bn': 'আমি কেন বিজ্ঞাপন দেখছি?', 'pt': 'por que estou vendo anúncios?',});
  String get settingsBugReport => _t({
        'es': 'Informe de errores en la aplicación',
        'en': 'Report a bug in the app',
        'fr': "Signaler un bug dans l'application",
        'de': 'Fehler in der App melden',
        'ru': 'Сообщить об ошибке в приложении',
        'ar': 'الإبلاغ عن خطأ في التطبيق', 'hi': 'ऐप में बग की रिपोर्ट करें', 'bn': 'অ্যাপে বাগ রিপোর্ট করুন', 'pt': 'Relatar um erro no aplicativo',
      });
  String get settingsRateUs => _t({'es': 'Puntúanos', 'en': 'Rate us', 'fr': 'Notez-nous', 'de': 'Bewerte uns', 'ru': 'Оцени нас', 'ar': 'قيّمينا', 'hi': 'हमें रेट करें', 'bn': 'আমাদের রেটিং দিন', 'pt': 'Avalie-nos',});
  String get settingsHelpTranslate =>
      _t({'es': 'Ayúdanos con la traducción', 'en': 'Help us translate', 'fr': 'Aidez-nous à traduire', 'de': 'Hilf uns beim Übersetzen', 'ru': 'Помоги нам с переводом', 'ar': 'ساعدينا في الترجمة', 'hi': 'अनुवाद में हमारी मदद करें', 'bn': 'অনুবাদে আমাদের সাহায্য করুন', 'pt': 'Ajude-nos com a tradução',});

  // ---- Placeholders "próximamente" ----
  String get comingSoonFeature => _t({
        'es': 'Esta función estará disponible próximamente',
        'en': 'This feature will be available soon',
        'fr': 'Cette fonctionnalité sera bientôt disponible',
        'de': 'Diese Funktion ist bald verfügbar',
        'ru': 'Эта функция скоро появится',
        'ar': 'ستكون هذه الميزة متاحة قريبًا', 'hi': 'यह सुविधा जल्द ही उपलब्ध होगी', 'bn': 'এই ফিচারটি শীঘ্রই উপলব্ধ হবে', 'pt': 'Este recurso estará disponível em breve',
      });
  String get comingSoonNotify => _t({
        'es': 'Te avisaremos cuando esté lista',
        'en': "We'll let you know when it's ready",
        'fr': 'Nous vous préviendrons dès qu\'elle sera prête',
        'de': 'Wir benachrichtigen dich, sobald sie bereit ist',
        'ru': 'Мы сообщим тебе, когда она будет готова',
        'ar': 'سنُعلمكِ عندما تكون جاهزة', 'hi': 'तैयार होने पर हम आपको बता देंगे', 'bn': 'প্রস্তুত হলে আমরা আপনাকে জানাবো', 'pt': 'Avisaremos quando estiver pronto',
      });

  // ---- Pantalla "Recordatorio" (ampliación) ----
  String get reminderPeriodAndFertility =>
      _t({'es': 'Período & fertilidad', 'en': 'Period & fertility', 'fr': 'Règles et fertilité', 'de': 'Periode & Fruchtbarkeit', 'ru': 'Менструация и фертильность', 'ar': 'الدورة والخصوبة', 'hi': 'पीरियड और प्रजनन क्षमता', 'bn': 'পিরিয়ড ও উর্বরতা', 'pt': 'Período e fertilidade',});
  String get reminderPeriodStart =>
      _t({'es': 'Inicio del período', 'en': 'Period start', 'fr': 'Début des règles', 'de': 'Beginn der Periode', 'ru': 'Начало менструации', 'ar': 'بداية الدورة', 'hi': 'पीरियड की शुरुआत', 'bn': 'পিরিয়ডের শুরু', 'pt': 'Início do período',});
  String get reminderPeriodEnd =>
      _t({'es': 'Fin del período', 'en': 'End of period', 'fr': 'Fin des règles', 'de': 'Ende der Periode', 'ru': 'Конец менструации', 'ar': 'نهاية الدورة', 'hi': 'पीरियड का अंत', 'bn': 'পিরিয়ডের শেষ', 'pt': 'Fim do período',});
  String get reminderEnterPeriod =>
      _t({'es': 'Introducir período', 'en': 'Enter period', 'fr': 'Saisir les règles', 'de': 'Periode eingeben', 'ru': 'Ввести менструацию', 'ar': 'إدخال الدورة', 'hi': 'पीरियड दर्ज करें', 'bn': 'পিরিয়ড প্রবেশ করান', 'pt': 'Inserir período',});
  String get reminderFertileApproaching => _t({
        'es': 'Se aproxima periodo fértil',
        'en': 'Fertile window approaching',
        'fr': 'La période fertile approche',
        'de': 'Fruchtbares Fenster naht',
        'ru': 'Приближается фертильный период',
        'ar': 'تقترب فترة الخصوبة', 'hi': 'उपजाऊ अवधि नज़दीक आ रही है', 'bn': 'উর্বর সময়কাল কাছে আসছে', 'pt': 'Janela fértil se aproximando',
      });
  String get reminderOvulationDay =>
      _t({'es': 'Día de ovulación', 'en': 'Ovulation day', 'fr': "Jour de l'ovulation", 'de': 'Eisprungtag', 'ru': 'День овуляции', 'ar': 'يوم الإباضة', 'hi': 'ओव्यूलेशन का दिन', 'bn': 'ডিম্বস্ফোটনের দিন', 'pt': 'Dia da ovulação',});
  String get reminderPill => _t({'es': 'Pastilla', 'en': 'Pill', 'fr': 'Pilule', 'de': 'Pille', 'ru': 'Таблетка', 'ar': 'حبة منع الحمل', 'hi': 'गोली', 'bn': 'পিল', 'pt': 'Pílula',});
  String get reminderTakePill => _t({'es': 'Tomar Píldora', 'en': 'Take the pill', 'fr': 'Prendre la pilule', 'de': 'Pille einnehmen', 'ru': 'Принять таблетку', 'ar': 'تناول الحبة', 'hi': 'गोली लें', 'bn': 'পিল খান', 'pt': 'Tomar a pílula',});
  String get reminderAppointment => _t({'es': 'Cita', 'en': 'Appointment', 'fr': 'Rendez-vous', 'de': 'Termin', 'ru': 'Приём', 'ar': 'موعد', 'hi': 'अपॉइंटमेंट', 'bn': 'অ্যাপয়েন্টমেন্ট', 'pt': 'Compromisso',});
  String get reminderDoctorAppointment =>
      _t({'es': 'Cita con el médico', 'en': "Doctor's appointment", 'fr': 'Rendez-vous médical', 'de': 'Arzttermin', 'ru': 'Приём у врача', 'ar': 'موعد الطبيب', 'hi': 'डॉक्टर की अपॉइंटमेंट', 'bn': 'ডাক্তারের অ্যাপয়েন্টমেন্ট', 'pt': 'Consulta médica',});
  String get reminderLifestyle => _t({'es': 'Estilo de vida', 'en': 'Lifestyle', 'fr': 'Mode de vie', 'de': 'Lebensstil', 'ru': 'Образ жизни', 'ar': 'نمط الحياة', 'hi': 'जीवनशैली', 'bn': 'জীবনযাত্রা', 'pt': 'Estilo de vida',});
  String get reminderDailyLog => _t({'es': 'Registro Diario', 'en': 'Daily log', 'fr': 'Journal quotidien', 'de': 'Tagesprotokoll', 'ru': 'Ежедневная запись', 'ar': 'السجل اليومي', 'hi': 'दैनिक रिकॉर्ड', 'bn': 'দৈনিক লগ', 'pt': 'Registro diário',});
  String get reminderDrinkWaterReminder =>
      _t({'es': 'Recuerda beber agua', 'en': 'Remember to drink water', 'fr': "Pensez à boire de l'eau", 'de': 'Denk daran, Wasser zu trinken', 'ru': 'Не забудь пить воду', 'ar': 'تذكّري شرب الماء', 'hi': 'पानी पीना याद रखें', 'bn': 'পানি পান করার কথা মনে রাখুন', 'pt': 'Lembre-se de beber água',});
  String get reminderNotifications =>
      _t({'es': 'Notificaciones', 'en': 'Notifications', 'fr': 'Notifications', 'de': 'Benachrichtigungen', 'ru': 'Уведомления', 'ar': 'الإشعارات', 'hi': 'नोटिफिकेशन', 'bn': 'বিজ্ঞপ্তি', 'pt': 'Notificações',});
  String get reminderCyclePhaseReminder =>
      _t({'es': 'Recordatorio de fase del ciclo', 'en': 'Cycle phase reminder', 'fr': 'Rappel de phase du cycle', 'de': 'Erinnerung an Zyklusphase', 'ru': 'Напоминание о фазе цикла', 'ar': 'تذكير بمرحلة الدورة', 'hi': 'चक्र चरण रिमाइंडर', 'bn': 'চক্রের পর্যায় রিমাইন্ডার', 'pt': 'Lembrete de fase do ciclo',});
  String get reminderCyclePhaseTipsHint => _t({
        'es': 'Recibe consejos y recordatorios para las fases de tu ciclo',
        'en': 'Get tips and reminders for the phases of your cycle',
        'fr': 'Recevez des conseils et rappels pour les phases de votre cycle',
        'de': 'Erhalte Tipps und Erinnerungen zu den Phasen deines Zyklus',
        'ru': 'Получай советы и напоминания для фаз своего цикла',
        'ar': 'احصلي على نصائح وتذكيرات لمراحل دورتكِ', 'hi': 'अपने चक्र के चरणों के लिए सुझाव और रिमाइंडर पाएं', 'bn': 'আপনার চক্রের পর্যায়ের জন্য টিপস ও রিমাইন্ডার পান', 'pt': 'Receba dicas e lembretes para as fases do seu ciclo',
      });
  String get reminderOn => _t({'es': 'ACTIVADO', 'en': 'ON', 'fr': 'ACTIVÉ', 'de': 'AN', 'ru': 'ВКЛЮЧЕНО', 'ar': 'مفعّل', 'hi': 'चालू', 'bn': 'চালু', 'pt': 'ATIVADO',});
  String get reminderOff => _t({'es': 'DESACTIVADO', 'en': 'OFF', 'fr': 'DÉSACTIVÉ', 'de': 'AUS', 'ru': 'ВЫКЛЮЧЕНО', 'ar': 'معطّل', 'hi': 'बंद', 'bn': 'বন্ধ', 'pt': 'DESATIVADO',});

  // ---- Bottom sheet ReminderTimeSheet (selector fecha/hora precargado) ----
  // Se abre al activar CUALQUIER interruptor de recordatorio de esta
  // pantalla, con un valor por defecto ya calculado (fecha prevista de
  // período/ovulación/etc.) para que la usuaria solo tenga que confirmar
  // o ajustar, nunca calcular nada a mano.
  String get reminderTimeSheetDateLabel =>
      _t({'es': 'Fecha', 'en': 'Date', 'fr': 'Date', 'de': 'Datum', 'ru': 'Дата', 'ar': 'التاريخ', 'hi': 'तारीख', 'bn': 'তারিখ', 'pt': 'Data',});
  String get reminderTimeSheetTimeLabel =>
      _t({'es': 'Hora', 'en': 'Time', 'fr': 'Heure', 'de': 'Uhrzeit', 'ru': 'Время', 'ar': 'الوقت', 'hi': 'समय', 'bn': 'সময়', 'pt': 'Hora',});
  String get reminderTimeSheetSuggestedHint => _t({
        'es': 'Ya precargamos una fecha y hora sugeridas según tu ciclo. Puedes guardarla tal cual o ajustarla.',
        'en': "We've pre-filled a suggested date and time based on your cycle. You can save it as is or adjust it.",
        'fr': 'Nous avons préchargé une date et une heure suggérées selon votre cycle. Vous pouvez la garder ou l\'ajuster.',
        'de': 'Wir haben bereits ein vorgeschlagenes Datum und eine Uhrzeit basierend auf deinem Zyklus eingetragen. Du kannst es so speichern oder anpassen.',
        'ru': 'Мы уже предзаполнили предлагаемую дату и время на основе твоего цикла. Можешь сохранить как есть или изменить.',
        'ar': 'لقد قمنا بتعبئة تاريخ ووقت مقترحين مسبقًا بناءً على دورتكِ. يمكنكِ حفظهما كما هما أو تعديلهما.', 'hi': 'हमने आपके चक्र के आधार पर एक सुझाई गई तारीख और समय पहले से भर दिया है। आप इसे ऐसे ही सेव कर सकते हैं या बदल सकते हैं।', 'bn': 'আমরা আপনার চক্রের ভিত্তিতে একটি প্রস্তাবিত তারিখ ও সময় আগে থেকেই পূরণ করে দিয়েছি। আপনি এটি এভাবেই সংরক্ষণ করতে পারেন বা পরিবর্তন করতে পারেন।', 'pt': 'Já preenchemos uma data e horário sugeridos com base no seu ciclo. Você pode salvar como está ou ajustar.',
      });
  String get reminderTimeSheetSuggestedHintTimeOnly => _t({
        'es': 'Elige la hora a la que quieres recibir este aviso todos los días.',
        'en': 'Choose the time you want to receive this reminder every day.',
        'fr': 'Choisissez l\'heure à laquelle vous souhaitez recevoir ce rappel chaque jour.',
        'de': 'Wähle die Uhrzeit, zu der du diese Erinnerung täglich erhalten möchtest.',
        'ru': 'Выбери время, в которое хочешь получать это напоминание каждый день.',
        'ar': 'اختاري الوقت الذي تريدين تلقي هذا التذكير فيه كل يوم.', 'hi': 'वह समय चुनें जब आप हर दिन यह सूचना पाना चाहते हैं।', 'bn': 'প্রতিদিন কোন সময়ে এই বিজ্ঞপ্তি পেতে চান তা বেছে নিন।', 'pt': 'Escolha o horário em que deseja receber este aviso todos os dias.',
      });
  String get reminderTimeSheetSave => _t({'es': 'Guardar', 'en': 'Save', 'fr': 'Enregistrer', 'de': 'Speichern', 'ru': 'Сохранить', 'ar': 'حفظ', 'hi': 'सेव करें', 'bn': 'সংরক্ষণ করুন', 'pt': 'Salvar',});
  String get reminderTimeSheetCancel => _t({'es': 'Cancelar', 'en': 'Cancel', 'fr': 'Annuler', 'de': 'Abbrechen', 'ru': 'Отмена', 'ar': 'إلغاء', 'hi': 'रद्द करें', 'bn': 'বাতিল করুন', 'pt': 'Cancelar',});
  String get reminderTimeSheetChangeDate =>
      _t({'es': 'Cambiar fecha', 'en': 'Change date', 'fr': 'Changer la date', 'de': 'Datum ändern', 'ru': 'Изменить дату', 'ar': 'تغيير التاريخ', 'hi': 'तारीख बदलें', 'bn': 'তারিখ পরিবর্তন করুন', 'pt': 'Mudar data',});
  String get reminderTimeSheetChangeTime =>
      _t({'es': 'Cambiar hora', 'en': 'Change time', 'fr': "Changer l'heure", 'de': 'Uhrzeit ändern', 'ru': 'Изменить время', 'ar': 'تغيير الوقت', 'hi': 'समय बदलें', 'bn': 'সময় পরিবর্তন করুন', 'pt': 'Mudar horário',});

  // ---- _TimePickerSheet (selector de hora propio, reemplaza el
  // showTimePicker nativo de Material) — rediseño aprobado en Claude
  // Visualize (2026-08-16).
  String get reminderTimeSheetPickTimeTitle =>
      _t({'es': 'Elige la hora', 'en': 'Choose the time', 'fr': "Choisissez l'heure", 'de': 'Uhrzeit wählen', 'ru': 'Выбери время', 'ar': 'اختاري الوقت', 'hi': 'समय चुनें', 'bn': 'সময় বেছে নিন', 'pt': 'Escolha o horário',});
  String get reminderTimeSheet12h => _t({'es': '12 h', 'en': '12 h', 'fr': '12 h', 'de': '12 Std', 'ru': '12 ч', 'ar': '12 ساعة', 'hi': '12 h', 'bn': '12 h', 'pt': '12 h',});
  String get reminderTimeSheet24h => _t({'es': '24 h', 'en': '24 h', 'fr': '24 h', 'de': '24 Std', 'ru': '24 ч', 'ar': '24 ساعة', 'hi': '24 h', 'bn': '24 h', 'pt': '24 h',});
  String get reminderTimeSheetDone => _t({'es': 'Listo', 'en': 'Done', 'fr': 'OK', 'de': 'Fertig', 'ru': 'Готово', 'ar': 'تم', 'hi': 'हो गया', 'bn': 'সম্পন্ন', 'pt': 'Concluído',});

  // ---- ReminderDatePickerSheet (selector de fecha propio con ruedas
  // día/mes/año, reemplaza el showDatePicker nativo de Material — mismo
  // rediseño aprobado en Claude Visualize, 2026-08-16).
  String get reminderDateSheetPickDateTitle =>
      _t({'es': 'Elige la fecha', 'en': 'Choose the date', 'fr': 'Choisissez la date', 'de': 'Datum wählen', 'ru': 'Выбери дату', 'ar': 'اختاري التاريخ', 'hi': 'तारीख चुनें', 'bn': 'তারিখ বেছে নিন', 'pt': 'Escolha a data',});

  // Título del sheet por cada tipo de recordatorio — reutiliza las mismas
  // etiquetas ya existentes (reminderPeriodStart, etc.) como título, así
  // que no hace falta duplicar texto aquí; esta sección solo cubre las
  // piezas que sí son nuevas y específicas del sheet.
  String get reminderCyclePhaseAutoHint => _t({
        'es': 'Este aviso no usa una hora fija: se dispara automáticamente cuando tu ciclo entra en una fase nueva (menstrual, folicular, ovulación o lútea). Elige a qué hora del día prefieres recibirlo.',
        'en': "This reminder doesn't use a fixed date: it fires automatically when your cycle enters a new phase (menstrual, follicular, ovulation, or luteal). Choose what time of day you'd prefer to receive it.",
        'fr': "Ce rappel n'utilise pas d'heure fixe : il se déclenche automatiquement quand votre cycle entre dans une nouvelle phase (menstruelle, folliculaire, ovulation ou lutéale). Choisissez à quelle heure vous préférez le recevoir.",
        'de': 'Diese Erinnerung nutzt keine feste Uhrzeit: Sie wird automatisch ausgelöst, wenn dein Zyklus in eine neue Phase eintritt (Menstruation, Follikelphase, Eisprung oder Lutealphase). Wähle, zu welcher Tageszeit du sie bevorzugst.',
        'ru': 'Это напоминание не привязано к фиксированному времени: оно срабатывает автоматически, когда твой цикл переходит в новую фазу (менструальную, фолликулярную, овуляцию или лютеиновую). Выбери, в какое время суток предпочитаешь его получать.',
        'ar': 'لا يستخدم هذا التذكير وقتًا ثابتًا: يتم تفعيله تلقائيًا عندما تدخل دورتكِ مرحلة جديدة (الحيض، الجريبية، الإباضة، أو الأصفرية). اختاري الوقت من اليوم الذي تفضلين تلقيه فيه.',
        'hi': 'यह रिमाइंडर किसी तय समय पर नहीं आता: यह अपने आप तब चलता है जब तुम्हारा चक्र किसी नए चरण में प्रवेश करता है (माहवारी, फॉलिक्युलर, ओव्यूलेशन या ल्यूटियल)। चुनो कि तुम इसे दिन के किस समय पाना चाहती हो।',
        'bn': 'এই রিমাইন্ডারে কোনো নির্দিষ্ট সময় ব্যবহার হয় না: তোমার চক্র যখন কোনো নতুন পর্যায়ে (মাসিক, ফলিকুলার, ডিম্বস্ফোটন বা লুটিয়াল) প্রবেশ করে তখন এটি নিজে থেকেই সক্রিয় হয়। দিনের কোন সময় এটি পেতে চাও তা বেছে নাও।',
        'pt': 'Este lembrete não usa um horário fixo: ele é disparado automaticamente quando seu ciclo entra em uma nova fase (menstrual, folicular, ovulação ou lútea). Escolha em que horário do dia prefere recebê-lo.',
      });
  String get reminderDaysBeforeLabel =>
      _t({'es': 'Días antes de la fecha calculada', 'en': 'Days before the calculated date', 'fr': 'Jours avant la date calculée', 'de': 'Tage vor dem berechneten Datum', 'ru': 'Дни до рассчитанной даты', 'ar': 'الأيام قبل التاريخ المحسوب', 'hi': 'अनुमानित तारीख से पहले के दिन', 'bn': 'নির্ধারিত তারিখের আগের দিন', 'pt': 'Dias antes da data calculada'});

  // ==================== Sección "Estilo de vida" (register_screen.dart) ====================
  // 4 círculos (Temperatura/Bebe agua/Sueño/Peso) portados del diseño
  // aprobado en Lovable ("Cycle Compass"), con modales de registro y
  // pantallas de detalle con gráfica + IMC/ICA/grasa corporal.
  String get lifestyleSectionTitle =>
      _t({'es': 'Estilo de vida', 'en': 'Lifestyle', 'fr': 'Mode de vie', 'de': 'Lebensstil', 'ru': 'Образ жизни', 'ar': 'نمط الحياة', 'hi': 'जीवनशैली', 'bn': 'জীবনযাত্রা', 'pt': 'Estilo de vida'});
  String get lifestyleTemperature =>
      _t({'es': 'Temperatura', 'en': 'Temperature', 'fr': 'Température', 'de': 'Temperatur', 'ru': 'Температура', 'ar': 'درجة الحرارة', 'hi': 'तापमान', 'bn': 'তাপমাত্রা', 'pt': 'Temperatura'});
  String get lifestyleDrinkWater =>
      _t({'es': 'Bebe agua', 'en': 'Drink water', 'fr': "Boire de l'eau", 'de': 'Wasser trinken', 'ru': 'Пей воду', 'ar': 'اشربي ماء', 'hi': 'पानी पियो', 'bn': 'পানি পান করো', 'pt': 'Beba água'});
  String get lifestyleSleep => _t({'es': 'Sueño', 'en': 'Sleep', 'fr': 'Sommeil', 'de': 'Schlaf', 'ru': 'Сон', 'ar': 'النوم', 'hi': 'नींद', 'bn': 'ঘুম', 'pt': 'Sono'});
  String get lifestyleWeight => _t({'es': 'Peso', 'en': 'Weight', 'fr': 'Poids', 'de': 'Gewicht', 'ru': 'Вес', 'ar': 'الوزن', 'hi': 'वज़न', 'bn': 'ওজন', 'pt': 'Peso'});
  String get lifestyleNoData => _t({'es': '—', 'en': '—', 'fr': '—', 'de': '—', 'ru': '—', 'ar': '—', 'hi': '—', 'bn': '—', 'pt': '—'});

  // ---- Modal estilo iOS (Temperatura / Peso) ----
  String get lifestyleEnterValue =>
      _t({'es': 'Introduce el valor', 'en': 'Enter the value', 'fr': 'Entrez la valeur', 'de': 'Wert eingeben', 'ru': 'Введи значение', 'ar': 'أدخلي القيمة', 'hi': 'मान दर्ज करो', 'bn': 'মান লিখুন', 'pt': 'Insira o valor'});
  String get lifestyleDateLabel => _t({'es': 'Fecha', 'en': 'Date', 'fr': 'Date', 'de': 'Datum', 'ru': 'Дата', 'ar': 'التاريخ', 'hi': 'तारीख', 'bn': 'তারিখ', 'pt': 'Data'});
  String get lifestyleTimeLabel => _t({'es': 'Hora', 'en': 'Time', 'fr': 'Heure', 'de': 'Uhrzeit', 'ru': 'Время', 'ar': 'الوقت', 'hi': 'समय', 'bn': 'সময়', 'pt': 'Hora'});
  String get lifestyleSaveButton => _t({'es': 'Guardar', 'en': 'Save', 'fr': 'Enregistrer', 'de': 'Speichern', 'ru': 'Сохранить', 'ar': 'حفظ', 'hi': 'सहेजें', 'bn': 'সংরক্ষণ করুন', 'pt': 'Salvar'});
  String get lifestyleAddButton => _t({'es': 'Añadir', 'en': 'Add', 'fr': 'Ajouter', 'de': 'Hinzufügen', 'ru': 'Добавить', 'ar': 'إضافة', 'hi': 'जोड़ें', 'bn': 'যোগ করুন', 'pt': 'Adicionar'});
  String get lifestylePreviousRecords =>
      _t({'es': 'Registros anteriores', 'en': 'Previous records', 'fr': 'Enregistrements précédents', 'de': 'Frühere Einträge', 'ru': 'Предыдущие записи', 'ar': 'السجلات السابقة', 'hi': 'पिछले रिकॉर्ड', 'bn': 'পূর্ববর্তী রেকর্ড', 'pt': 'Registros anteriores'});
  String get lifestyleNoPreviousRecords => _t({
        'es': 'Aún no hay registros anteriores.',
        'en': 'No previous records yet.',
        'fr': 'Pas encore d\'enregistrements précédents.',
        'de': 'Noch keine früheren Einträge.',
        'ru': 'Пока нет предыдущих записей.',
        'ar': 'لا توجد سجلات سابقة بعد.',
        'hi': 'अभी तक कोई पिछला रिकॉर्ड नहीं है।',
        'bn': 'এখনো কোনো পূর্ববর্তী রেকর্ড নেই।',
        'pt': 'Ainda não há registros anteriores.',
      });
  String get lifestyleEditRecord =>
      _t({'es': 'Editar', 'en': 'Edit', 'fr': 'Modifier', 'de': 'Bearbeiten', 'ru': 'Редактировать', 'ar': 'تعديل', 'hi': 'संपादित करें', 'bn': 'সম্পাদনা করুন', 'pt': 'Editar'});

  // ---- Temperatura ----
  String get lifestyleTempDetailTitle =>
      _t({'es': 'Temperatura basal', 'en': 'Basal temperature', 'fr': 'Température basale', 'de': 'Basaltemperatur', 'ru': 'Базальная температура', 'ar': 'درجة الحرارة الأساسية', 'hi': 'बेसल तापमान', 'bn': 'বেসাল তাপমাত্রা', 'pt': 'Temperatura basal'});
  String get lifestyleTempOutOfRange => _t({
        'es': 'Valor fuera del rango habitual (35.5°C - 37.5°C). Revísalo antes de guardar.',
        'en': 'Value outside the usual range (35.5°C - 37.5°C). Double-check before saving.',
        'fr': 'Valeur hors de la plage habituelle (35,5°C - 37,5°C). Vérifiez avant d\'enregistrer.',
        'de': 'Wert außerhalb des üblichen Bereichs (35,5°C - 37,5°C). Bitte vor dem Speichern prüfen.',
        'ru': 'Значение вне обычного диапазона (35,5°C - 37,5°C). Проверь перед сохранением.',
        'ar': 'القيمة خارج النطاق المعتاد (35.5°م - 37.5°م). تحققي منها قبل الحفظ.',
        'hi': 'मान सामान्य दायरे (35.5°C - 37.5°C) से बाहर है। सहेजने से पहले जांच लो।',
        'bn': 'মান স্বাভাবিক পরিসরের (35.5°C - 37.5°C) বাইরে। সংরক্ষণ করার আগে যাচাই করো।',
        'pt': 'Valor fora do intervalo habitual (35,5°C - 37,5°C). Confira antes de salvar.',
      });
  String get lifestyleTempChartEmpty => _t({
        'es': 'Registra tu temperatura basal para ver su evolución aquí.',
        'en': 'Log your basal temperature to see its trend here.',
        'fr': 'Enregistrez votre température basale pour voir son évolution ici.',
        'de': 'Trage deine Basaltemperatur ein, um ihren Verlauf hier zu sehen.',
        'ru': 'Отмечай свою базальную температуру, чтобы видеть здесь её динамику.',
        'ar': 'سجّلي درجة حرارتكِ الأساسية لرؤية تطورها هنا.',
        'hi': 'यहां अपने बेसल तापमान का रुझान देखने के लिए इसे दर्ज करो।',
        'bn': 'এখানে তোমার বেসাল তাপমাত্রার প্রবণতা দেখতে এটি লগ করো।',
        'pt': 'Registre sua temperatura basal para ver a evolução aqui.',
      });

  // ---- Bebe agua ----
  String get lifestyleWaterUnitGlasses => _t({'es': 'Vasos', 'en': 'Glasses', 'fr': 'Verres', 'de': 'Gläser', 'ru': 'Стаканы', 'ar': 'أكواب', 'hi': 'गिलास', 'bn': 'গ্লাস', 'pt': 'Copos'});
  String get lifestyleWaterUnitDrops => _t({'es': 'Gotas', 'en': 'Drops', 'fr': 'Gouttes', 'de': 'Tropfen', 'ru': 'Капли', 'ar': 'قطرات', 'hi': 'बूंदें', 'bn': 'ফোঁটা', 'pt': 'Gotas'});
  String lifestyleWaterGoalOf(int current, int goal, String unit) => _t({
        'es': '$current/$goal $unit',
        'en': '$current/$goal $unit',
        'fr': '$current/$goal $unit',
        'de': '$current/$goal $unit',
        'ru': '$current/$goal $unit',
        'ar': '$current/$goal $unit',
        'hi': '$current/$goal $unit',
        'bn': '$current/$goal $unit',
        'pt': '$current/$goal $unit',
      });
  String get lifestyleWaterDone => _t({
        'es': '¡Meta cumplida! Sigue así.',
        'en': 'Goal reached! Keep it up.',
        'fr': 'Objectif atteint ! Continuez ainsi.',
        'de': 'Ziel erreicht! Weiter so.',
        'ru': 'Цель достигнута! Продолжай в том же духе.',
        'ar': 'تم تحقيق الهدف! واصلي هكذا.',
        'hi': 'लक्ष्य पूरा हुआ! ऐसे ही जारी रखो।',
        'bn': 'লক্ষ্য পূরণ হয়েছে! এভাবেই চালিয়ে যাও।',
        'pt': 'Meta alcançada! Continue assim.',
      });
  String get lifestyleWaterEyebrow =>
      _t({'es': 'Hidratación', 'en': 'Hydration', 'fr': 'Hydratation', 'de': 'Flüssigkeitszufuhr', 'ru': 'Гидратация', 'ar': 'الترطيب', 'hi': 'जलयोजन', 'bn': 'হাইড্রেশন', 'pt': 'Hidratação'});
  String lifestyleWaterPercentOfGoal(String percent) => _t({
        'es': '$percent de tu meta',
        'en': '$percent of your goal',
        'fr': '$percent de votre objectif',
        'de': '$percent deines Ziels',
        'ru': '$percent от твоей цели',
        'ar': '$percent من هدفكِ',
        'hi': 'तुम्हारे लक्ष्य का $percent',
        'bn': 'তোমার লক্ষ্যের $percent',
        'pt': '$percent da sua meta',
      });
  String get lifestyleWaterEmptyHint => _t({
        'es': 'Aún no has bebido agua hoy.',
        'en': "You haven't had any water yet today.",
        'fr': "Vous n'avez pas encore bu d'eau aujourd'hui.",
        'de': 'Du hast heute noch kein Wasser getrunken.',
        'ru': 'Ты ещё не пила воду сегодня.',
        'ar': 'لم تشربي ماءً بعد اليوم.',
        'hi': 'आज तुमने अभी तक पानी नहीं पिया है।',
        'bn': 'আজ তুমি এখনো পানি পান করোনি।',
        'pt': 'Você ainda não bebeu água hoje.',
      });

  // ---- Sueño ----
  String get lifestyleSleepYesterday => _t({'es': 'Ayer', 'en': 'Yesterday', 'fr': 'Hier', 'de': 'Gestern', 'ru': 'Вчера', 'ar': 'أمس', 'hi': 'कल', 'bn': 'গতকাল', 'pt': 'Ontem'});
  String get lifestyleSleepToday => _t({'es': 'Hoy', 'en': 'Today', 'fr': "Aujourd'hui", 'de': 'Heute', 'ru': 'Сегодня', 'ar': 'اليوم', 'hi': 'आज', 'bn': 'আজ', 'pt': 'Hoje'});
  String get lifestyleSleepBedtime =>
      _t({'es': 'Hora de dormir', 'en': 'Bedtime', 'fr': 'Heure du coucher', 'de': 'Schlafenszeit', 'ru': 'Время сна', 'ar': 'وقت النوم', 'hi': 'सोने का समय', 'bn': 'ঘুমানোর সময়', 'pt': 'Hora de dormir'});
  String get lifestyleSleepWakeTime =>
      _t({'es': 'Hora de despertar', 'en': 'Wake-up time', 'fr': 'Heure du réveil', 'de': 'Aufwachzeit', 'ru': 'Время пробуждения', 'ar': 'وقت الاستيقاظ', 'hi': 'जागने का समय', 'bn': 'ঘুম থেকে ওঠার সময়', 'pt': 'Hora de acordar'});
  String get lifestyleSleepDone => _t({'es': 'Listo', 'en': 'Done', 'fr': 'Terminé', 'de': 'Fertig', 'ru': 'Готово', 'ar': 'تم', 'hi': 'हो गया', 'bn': 'সম্পন্ন', 'pt': 'Concluído'});
  String lifestyleSleepDuration(int hours, int minutes) => _t({
        'es': '${hours}h ${minutes}m',
        'en': '${hours}h ${minutes}m',
        'fr': '${hours}h ${minutes}m',
        'de': '${hours}h ${minutes}m',
        'ru': '${hours}ч ${minutes}м',
        'ar': '${hours} س ${minutes} د',
        'hi': '${hours} घं ${minutes} मि',
        'bn': '${hours} ঘ ${minutes} মি',
        'pt': '${hours}h ${minutes}m',
      });

  // ---- Peso ----
  String get lifestyleWeightDetailTitle =>
      _t({'es': 'Peso', 'en': 'Weight', 'fr': 'Poids', 'de': 'Gewicht', 'ru': 'Вес', 'ar': 'الوزن', 'hi': 'वज़न', 'bn': 'ওজন', 'pt': 'Peso'});
  String get lifestyleWeightUnitKg => _t({'es': 'kg', 'en': 'kg', 'fr': 'kg', 'de': 'kg', 'ru': 'кг', 'ar': 'كجم', 'hi': 'किग्रा', 'bn': 'কেজি', 'pt': 'kg'});
  String get lifestyleWeightUnitLb => _t({'es': 'lb', 'en': 'lb', 'fr': 'lb', 'de': 'lb', 'ru': 'фунт', 'ar': 'رطل', 'hi': 'पाउंड', 'bn': 'পাউন্ড', 'pt': 'lb'});
  String get lifestyleWeightChartEmpty => _t({
        'es': 'Registra tu peso para ver su evolución aquí.',
        'en': 'Log your weight to see its trend here.',
        'fr': 'Enregistrez votre poids pour voir son évolution ici.',
        'de': 'Trage dein Gewicht ein, um seinen Verlauf hier zu sehen.',
        'ru': 'Отмечай свой вес, чтобы видеть здесь его динамику.',
        'ar': 'سجّلي وزنكِ لرؤية تطوره هنا.',
        'hi': 'यहां अपने वज़न का रुझान देखने के लिए इसे दर्ज करो।',
        'bn': 'এখানে তোমার ওজনের প্রবণতা দেখতে এটি লগ করো।',
        'pt': 'Registre seu peso para ver a evolução aqui.',
      });

  // ---- 3 tarjetas educativas de la pantalla de detalle de Peso ----
  String get lifestyleBmiCardTitle => _t({'es': 'IMC', 'en': 'BMI', 'fr': 'IMC', 'de': 'BMI', 'ru': 'ИМТ', 'ar': 'مؤشر كتلة الجسم', 'hi': 'बीएमआई', 'bn': 'বিএমআই', 'pt': 'IMC'});
  String get lifestyleWhrCardTitle =>
      _t({'es': 'ICA (índice cintura-altura)', 'en': 'WHtR (waist-to-height ratio)', 'fr': 'RTH (rapport taille-hauteur)', 'de': 'WHtR (Taille-Größe-Verhältnis)', 'ru': 'ИОТР (индекс отношения талии к росту)', 'ar': 'نسبة الخصر إلى الطول', 'hi': 'डब्ल्यूएचटीआर (कमर-ऊंचाई अनुपात)', 'bn': 'ডব্লিউএইচটিআর (কোমর-উচ্চতা অনুপাত)', 'pt': 'RCEst (relação cintura-estatura)'});
  String get lifestyleBodyFatCardTitle =>
      _t({'es': '% de grasa corporal', 'en': 'Body fat %', 'fr': '% de graisse corporelle', 'de': 'Körperfettanteil %', 'ru': '% жира в организме', 'ar': 'نسبة الدهون في الجسم', 'hi': 'शरीर में वसा %', 'bn': 'শরীরের চর্বি %', 'pt': '% de gordura corporal'});
  String get lifestyleCalculateButton =>
      _t({'es': 'Calcular', 'en': 'Calculate', 'fr': 'Calculer', 'de': 'Berechnen', 'ru': 'Рассчитать', 'ar': 'احسبي', 'hi': 'गणना करें', 'bn': 'গণনা করুন', 'pt': 'Calcular'});
  String get lifestylePlaceholderMissingData =>
      _t({'es': 'de entrada', 'en': 'input needed', 'fr': 'donnée requise', 'de': 'Eingabe nötig', 'ru': 'нужны данные', 'ar': 'يلزم إدخال بيانات', 'hi': 'डेटा दर्ज करना होगा', 'bn': 'তথ্য প্রয়োজন', 'pt': 'dado necessário'});
  String get lifestyleMissingHeightHint => _t({
        'es': 'Añade tu altura en Configuración para calcular esto.',
        'en': 'Add your height in Settings to calculate this.',
        'fr': 'Ajoutez votre taille dans les paramètres pour calculer ceci.',
        'de': 'Füge deine Größe in den Einstellungen hinzu, um dies zu berechnen.',
        'ru': 'Добавь свой рост в Настройках, чтобы рассчитать это.',
        'ar': 'أضيفي طولكِ في الإعدادات لحساب ذلك.', 'hi': 'इसकी गणना के लिए सेटिंग्स में अपनी लंबाई जोड़ें।', 'bn': 'এটি হিসাব করতে সেটিংসে আপনার উচ্চতা যোগ করুন।', 'pt': 'Adicione sua altura nas Configurações para calcular isso.',
      });
  String get lifestyleMissingWaistHint => _t({
        'es': 'Introduce tu contorno de cintura para calcular esto.',
        'en': 'Enter your waist circumference to calculate this.',
        'fr': 'Entrez votre tour de taille pour calculer ceci.',
        'de': 'Gib deinen Taillenumfang ein, um dies zu berechnen.',
        'ru': 'Введи обхват своей талии, чтобы рассчитать это.',
        'ar': 'أدخلي محيط خصركِ لحساب ذلك.', 'hi': 'इसकी गणना के लिए अपनी कमर की माप डालें।', 'bn': 'এটি হিসাব করতে আপনার কোমরের মাপ লিখুন।', 'pt': 'Informe sua circunferência de cintura para calcular isso.',
      });
  String get lifestyleMissingAgeHint => _t({
        'es': 'Añade tu fecha de nacimiento en Mi perfil para calcular esto.',
        'en': 'Add your birth date in My profile to calculate this.',
        'fr': 'Ajoutez votre date de naissance dans Mon profil pour calculer ceci.',
        'de': 'Füge dein Geburtsdatum in Mein Profil hinzu, um dies zu berechnen.',
        'ru': 'Добавь свою дату рождения в разделе «Мой профиль», чтобы рассчитать это.',
        'ar': 'أضيفي تاريخ ميلادكِ في "ملفي الشخصي" لحساب ذلك.', 'hi': 'इसकी गणना के लिए मेरी प्रोफ़ाइल में अपनी जन्म तिथि जोड़ें।', 'bn': 'এটি হিসাব করতে আমার প্রোফাইলে আপনার জন্ম তারিখ যোগ করুন।', 'pt': 'Adicione sua data de nascimento em Meu perfil para calcular isso.',
      });
  String get lifestyleWaistInputLabel =>
      _t({'es': 'Contorno de cintura (cm)', 'en': 'Waist circumference (cm)', 'fr': 'Tour de taille (cm)', 'de': 'Taillenumfang (cm)', 'ru': 'Обхват талии (см)', 'ar': 'محيط الخصر (سم)', 'hi': 'कमर की माप (सेमी)', 'bn': 'কোমরের মাপ (সেমি)', 'pt': 'Circunferência da cintura (cm)',});
  String get lifestyleBiologicalSexLabel =>
      _t({'es': 'Sexo biológico', 'en': 'Biological sex', 'fr': 'Sexe biologique', 'de': 'Biologisches Geschlecht', 'ru': 'Биологический пол', 'ar': 'الجنس البيولوجي', 'hi': 'जैविक लिंग', 'bn': 'জৈবিক লিঙ্গ', 'pt': 'Sexo biológico',});
  String get lifestyleSexFemale => _t({'es': 'Mujer', 'en': 'Female', 'fr': 'Femme', 'de': 'Weiblich', 'ru': 'Женский', 'ar': 'أنثى', 'hi': 'महिला', 'bn': 'নারী', 'pt': 'Feminino',});
  String get lifestyleSexMale => _t({'es': 'Hombre', 'en': 'Male', 'fr': 'Homme', 'de': 'Männlich', 'ru': 'Мужской', 'ar': 'ذكر', 'hi': 'पुरुष', 'bn': 'পুরুষ', 'pt': 'Masculino',});
  String get lifestyleBmiCategoryUnderweight =>
      _t({'es': 'Bajo peso', 'en': 'Underweight', 'fr': 'Insuffisance pondérale', 'de': 'Untergewicht', 'ru': 'Недостаточный вес', 'ar': 'نقص الوزن', 'hi': 'कम वज़न', 'bn': 'কম ওজন', 'pt': 'Abaixo do peso',});
  String get lifestyleBmiCategoryNormal => _t({'es': 'Normal', 'en': 'Normal', 'fr': 'Normal', 'de': 'Normal', 'ru': 'Норма', 'ar': 'طبيعي', 'hi': 'सामान्य', 'bn': 'স্বাভাবিক', 'pt': 'Normal',});
  String get lifestyleBmiCategoryOverweight =>
      _t({'es': 'Sobrepeso', 'en': 'Overweight', 'fr': 'Surpoids', 'de': 'Übergewicht', 'ru': 'Избыточный вес', 'ar': 'زيادة الوزن', 'hi': 'अधिक वज़न', 'bn': 'অতিরিক্ত ওজন', 'pt': 'Sobrepeso',});
  String get lifestyleBmiCategoryObesity => _t({'es': 'Obesidad', 'en': 'Obesity', 'fr': 'Obésité', 'de': 'Adipositas', 'ru': 'Ожирение', 'ar': 'السمنة', 'hi': 'मोटापा', 'bn': 'স্থূলতা', 'pt': 'Obesidade',});
  String get lifestyleWhrCategoryLow =>
      _t({'es': 'Riesgo bajo', 'en': 'Low risk', 'fr': 'Risque faible', 'de': 'Geringes Risiko', 'ru': 'Низкий риск', 'ar': 'خطر منخفض', 'hi': 'कम जोखिम', 'bn': 'কম ঝুঁকি', 'pt': 'Risco baixo',});
  String get lifestyleWhrCategoryModerate =>
      _t({'es': 'Riesgo moderado', 'en': 'Moderate risk', 'fr': 'Risque modéré', 'de': 'Mäßiges Risiko', 'ru': 'Умеренный риск', 'ar': 'خطر متوسط', 'hi': 'मध्यम जोखिम', 'bn': 'মাঝারি ঝুঁকি', 'pt': 'Risco moderado',});
  String get lifestyleWhrCategoryHigh =>
      _t({'es': 'Riesgo alto', 'en': 'High risk', 'fr': 'Risque élevé', 'de': 'Hohes Risiko', 'ru': 'Высокий риск', 'ar': 'خطر مرتفع', 'hi': 'ज़्यादा जोखिम', 'bn': 'উচ্চ ঝুঁকি', 'pt': 'Risco alto',});

  // ==================== Ronda 2: porte FIEL al diseño exacto de Lovable ====================
  // Strings nuevos para el rediseño 1:1 de Temperatura (modal simplificado
  // con número gigante + fecha/hora), Sueño (pantalla completa de 2 niveles
  // con franjas horarias AYER/HOY), Peso (pantalla completa con formulario
  // "Tus datos" persistido) y Bebe agua (panel compacto con toggle e
  // iconos de vaso). El bloque anterior de `lifestyle*` se mantiene íntegro
  // (varias claves se siguen usando tal cual: `lifestyleSaveButton`,
  // `lifestyleDateLabel`, `lifestyleTimeLabel`, `lifestyleWaterUnitGlasses`,
  // etc.), esto solo añade lo que faltaba.

  // ---- Temperatura: subtítulo de rango habitual bajo el número grande ----
  String lifestyleTempUsualRange(String min, String max) => _t({
        'es': 'Temperatura basal habitual: $min°C – $max°C',
        'en': 'Usual basal temperature: $min°C – $max°C',
        'fr': 'Température basale habituelle : $min°C – $max°C',
        'de': 'Übliche Basaltemperatur: $min°C – $max°C',
        'ru': 'Обычная базальная температура: $min°C – $max°C',
        'ar': 'درجة الحرارة الأساسية المعتادة: $min°م – $max°م', 'hi': 'सामान्य बेसल तापमान: $min°C – $max°C', 'bn': 'স্বাভাবিক বেসাল তাপমাত্রা: $min°C – $max°C', 'pt': 'Temperatura basal habitual: $min°C – $max°C',
      });
  String get lifestyleSwitchToKeyboard => _t({
        'es': 'Cambiar a teclado numérico',
        'en': 'Switch to numeric keyboard',
        'fr': 'Passer au clavier numérique',
        'de': 'Zur Zifferntastatur wechseln',
        'ru': 'Переключиться на цифровую клавиатуру',
        'ar': 'التبديل إلى لوحة المفاتيح الرقمية', 'hi': 'नंबर कीबोर्ड पर स्विच करें', 'bn': 'সংখ্যা কীবোর্ডে পরিবর্তন করুন', 'pt': 'Mudar para teclado numérico',
      });

  // ---- Sueño: pantalla 1 (resumen con anillo) ----
  String get lifestyleSleepGoalLabel =>
      _t({'es': 'Objetivo', 'en': 'Goal', 'fr': 'Objectif', 'de': 'Ziel', 'ru': 'Цель', 'ar': 'الهدف', 'hi': 'लक्ष्य', 'bn': 'লক্ষ্য', 'pt': 'Meta',});
  String lifestyleSleepGoalHours(int hours) => _t({
        'es': '$hours Horas',
        'en': '$hours Hours',
        'fr': '$hours heures',
        'de': '$hours Stunden',
        'ru': '$hours часов',
        'ar': '$hours ساعات', 'hi': '$hours घंटे', 'bn': '$hours ঘণ্টা', 'pt': '$hours Horas',
      });
  String get lifestyleSleepLogEntry =>
      _t({'es': 'Registro de sueño', 'en': 'Sleep log', 'fr': 'Journal de sommeil', 'de': 'Schlafprotokoll', 'ru': 'Запись сна', 'ar': 'سجل النوم', 'hi': 'नींद का रिकॉर्ड', 'bn': 'ঘুমের লগ', 'pt': 'Registro de sono',});

  // ---- Sueño: pantalla 2 (edición AYER/HOY) ----
  String get lifestyleSleepDurationLabel =>
      _t({'es': 'Duración del sueño', 'en': 'Sleep duration', 'fr': 'Durée du sommeil', 'de': 'Schlafdauer', 'ru': 'Продолжительность сна', 'ar': 'مدة النوم', 'hi': 'नींद की अवधि', 'bn': 'ঘুমের সময়কাল', 'pt': 'Duração do sono',});
  String get lifestyleSleepFellAsleep =>
      _t({'es': 'Me dormí', 'en': 'I fell asleep', 'fr': 'Je me suis endormie', 'de': 'Ich bin eingeschlafen', 'ru': 'Я заснула', 'ar': 'نمتُ', 'hi': 'मैं सो गया/गई', 'bn': 'আমি ঘুমিয়ে পড়েছি', 'pt': 'Adormeci',});
  String get lifestyleSleepWokeUp =>
      _t({'es': 'Me desperté', 'en': 'I woke up', 'fr': 'Je me suis réveillée', 'de': 'Ich bin aufgewacht', 'ru': 'Я проснулась', 'ar': 'استيقظتُ', 'hi': 'मैं जाग गया/गई', 'bn': 'আমি জেগে উঠেছি', 'pt': 'Acordei',});

  // ---- Bebe agua: panel compacto ----
  String get lifestyleWaterGlassesToday =>
      _t({'es': 'Vasos de hoy', 'en': "Today's glasses", 'fr': "Verres du jour", 'de': 'Gläser heute', 'ru': 'Стаканы сегодня', 'ar': 'أكواب اليوم', 'hi': 'आज के गिलास', 'bn': 'আজকের গ্লাস', 'pt': 'Copos de hoje',});
  String lifestyleWaterOfGoal(int current, int goal, String unit) => _t({
        'es': '$current de $goal $unit',
        'en': '$current of $goal $unit',
        'fr': '$current sur $goal $unit',
        'de': '$current von $goal $unit',
        'ru': '$current из $goal $unit',
        'ar': '$current من $goal $unit', 'hi': '$goal $unit में से $current', 'bn': '$goal $unit এর মধ্যে $current', 'pt': '$current de $goal $unit',
      });

  // ---- Peso: pantalla completa ----
  String get lifestyleWeightEvolutionTitle =>
      _t({'es': 'Evolución', 'en': 'Evolution', 'fr': 'Évolution', 'de': 'Verlauf', 'ru': 'Динамика', 'ar': 'التطور', 'hi': 'बदलाव', 'bn': 'পরিবর্তন', 'pt': 'Evolução',});
  String get lifestyleWeightAxisKg => _t({'es': 'kg', 'en': 'kg', 'fr': 'kg', 'de': 'kg', 'ru': 'кг', 'ar': 'كجم', 'hi': 'kg', 'bn': 'kg', 'pt': 'kg',});
  String get lifestyleYourDataTitle =>
      _t({'es': 'Tus datos', 'en': 'Your data', 'fr': 'Vos données', 'de': 'Deine Daten', 'ru': 'Твои данные', 'ar': 'بياناتكِ', 'hi': 'आपका डेटा', 'bn': 'আপনার তথ্য', 'pt': 'Seus dados',});
  String get lifestyleHeightFieldLabel =>
      _t({'es': 'Altura (cm)', 'en': 'Height (cm)', 'fr': 'Taille (cm)', 'de': 'Größe (cm)', 'ru': 'Рост (см)', 'ar': 'الطول (سم)', 'hi': 'लंबाई (सेमी)', 'bn': 'উচ্চতা (সেমি)', 'pt': 'Altura (cm)',});
  String get lifestyleWaistFieldLabel =>
      _t({'es': 'Cintura (cm)', 'en': 'Waist (cm)', 'fr': 'Tour de taille (cm)', 'de': 'Taille (cm)', 'ru': 'Талия (см)', 'ar': 'الخصر (سم)', 'hi': 'कमर (सेमी)', 'bn': 'কোমর (সেমি)', 'pt': 'Cintura (cm)',});
  String get lifestyleAgeFieldLabel =>
      _t({'es': 'Edad', 'en': 'Age', 'fr': 'Âge', 'de': 'Alter', 'ru': 'Возраст', 'ar': 'العمر', 'hi': 'उम्र', 'bn': 'বয়স', 'pt': 'Idade',});
  String get lifestyleSexFieldLabel =>
      _t({'es': 'Sexo', 'en': 'Sex', 'fr': 'Sexe', 'de': 'Geschlecht', 'ru': 'Пол', 'ar': 'الجنس', 'hi': 'लिंग', 'bn': 'লিঙ্গ', 'pt': 'Sexo',});
  String get lifestyleBmiFormulaSubtitle => _t({
        'es': 'IMC = peso (kg) / altura (m)²',
        'en': 'BMI = weight (kg) / height (m)²',
        'fr': 'IMC = poids (kg) / taille (m)²',
        'de': 'BMI = Gewicht (kg) / Größe (m)²',
        'ru': 'ИМТ = вес (кг) / рост (м)²',
        'ar': 'مؤشر كتلة الجسم = الوزن (كجم) / الطول (م)²', 'hi': 'बीएमआई = वज़न (किग्रा) / लंबाई (मी)²', 'bn': 'বিএমআই = ওজন (কেজি) / উচ্চতা (মি)²', 'pt': 'IMC = peso (kg) / altura (m)²',
      });
  String get lifestyleWhrFormulaSubtitle => _t({
        'es': 'ICA = cintura (cm) / altura (cm)',
        'en': 'WHtR = waist (cm) / height (cm)',
        'fr': 'RTH = tour de taille (cm) / taille (cm)',
        'de': 'WHtR = Taille (cm) / Größe (cm)',
        'ru': 'ИОТР = талия (см) / рост (см)',
        'ar': 'نسبة الخصر إلى الطول = الخصر (سم) / الطول (سم)', 'hi': 'डब्ल्यूएचटीआर = कमर (सेमी) / लंबाई (सेमी)', 'bn': 'WHtR = কোমর (সেমি) / উচ্চতা (সেমি)', 'pt': 'ICA = cintura (cm) / altura (cm)',
      });
  String get lifestyleBodyFatFormulaSubtitle => _t({
        'es': 'Estimación con la fórmula de Deurenberg.',
        'en': 'Estimate using the Deurenberg formula.',
        'fr': 'Estimation avec la formule de Deurenberg.',
        'de': 'Schätzung mit der Deurenberg-Formel.',
        'ru': 'Оценка по формуле Дюренберга.',
        'ar': 'تقدير باستخدام معادلة ديورنبرغ.', 'hi': 'ड्युरेनबर्ग फॉर्मूला के साथ अनुमान।', 'bn': 'ডিউরেনবার্গ সূত্র দিয়ে অনুমান।', 'pt': 'Estimativa usando a fórmula de Deurenberg.',
      });
  String get lifestyleBmiCardFullTitle => _t({
        'es': 'IMC (Índice de Masa Corporal)',
        'en': 'BMI (Body Mass Index)',
        'fr': 'IMC (Indice de Masse Corporelle)',
        'de': 'BMI (Body-Mass-Index)',
        'ru': 'ИМТ (Индекс массы тела)',
        'ar': 'مؤشر كتلة الجسم', 'hi': 'बीएमआई (बॉडी मास इंडेक्स)', 'bn': 'বিএমআই (বডি মাস ইনডেক্স)', 'pt': 'IMC (Índice de Massa Corporal)',
      });

  // ---- Tarjeta resumen "Vida sexual" (rediseño con 4 estadísticas en
  // grid 2x2, estilo captura de referencia) y sus 4 pantallas de detalle
  // (Veces/Orgasmo femenino/Con protección/Sin protección). ----
  String sexLifeThisWeekCount(int n) => _t({
        'es': 'Esta semana $n veces',
        'en': 'This week $n times',
        'fr': 'Cette semaine $n fois',
        'de': 'Diese Woche ${n}x',
        'ru': 'На этой неделе $n раз',
        'ar': 'هذا الأسبوع $n مرات', 'hi': 'इस हफ्ते $n बार', 'bn': 'এই সপ্তাহে $n বার', 'pt': 'Esta semana $n vezes',
      });
  String get sexLifeStatTimes =>
      _t({'es': 'Veces', 'en': 'Times', 'fr': 'Fois', 'de': 'Mal', 'ru': 'Раз', 'ar': 'عدد المرات', 'hi': 'बार', 'bn': 'বার', 'pt': 'Vezes',});
  String get sexLifeStatFemaleOrgasm => _t({
        'es': 'Orgasmo femenino',
        'en': 'Female orgasm',
        'fr': 'Orgasme féminin',
        'de': 'Weiblicher Orgasmus',
        'ru': 'Женский оргазм',
        'ar': 'النشوة الأنثوية', 'hi': 'महिला ऑर्गेज़्म', 'bn': 'নারী অর্গাজম', 'pt': 'Orgasmo feminino',
      });
  String get sexLifeStatProtected =>
      _t({'es': 'Con protección', 'en': 'Protected', 'fr': 'Avec protection', 'de': 'Mit Schutz', 'ru': 'С защитой', 'ar': 'بحماية', 'hi': 'सुरक्षा के साथ', 'bn': 'সুরক্ষাসহ', 'pt': 'Com proteção',});
  String get sexLifeStatUnprotected =>
      _t({'es': 'Sin protección', 'en': 'Unprotected', 'fr': 'Sans protection', 'de': 'Ohne Schutz', 'ru': 'Без защиты', 'ar': 'بدون حماية', 'hi': 'बिना सुरक्षा के', 'bn': 'সুরক্ষা ছাড়া', 'pt': 'Sem proteção',});
  String get sexLifeDetailCoitusChartTitle =>
      _t({'es': 'Gráfica de coitos', 'en': 'Intercourse chart', 'fr': 'Graphique des rapports', 'de': 'Verkehrsdiagramm', 'ru': 'График половых актов', 'ar': 'مخطط العلاقات الحميمة', 'hi': 'संभोग चार्ट', 'bn': 'সহবাসের চার্ট', 'pt': 'Gráfico de relações',});
  String get sexLifeDetailPregnancyChance => _t({
        'es': 'Posibilidad de quedar embarazada',
        'en': 'Chance of getting pregnant',
        'fr': 'Probabilité de grossesse',
        'de': 'Schwangerschaftswahrscheinlichkeit',
        'ru': 'Вероятность забеременеть',
        'ar': 'احتمال الحمل', 'hi': 'गर्भवती होने की संभावना', 'bn': 'গর্ভবতী হওয়ার সম্ভাবনা', 'pt': 'Chance de engravidar',
      });
  String get sexLifeDetailChanceHigh =>
      _t({'es': 'Alta', 'en': 'High', 'fr': 'Élevée', 'de': 'Hoch', 'ru': 'Высокая', 'ar': 'مرتفعة', 'hi': 'ज़्यादा', 'bn': 'বেশি', 'pt': 'Alta',});
  String get sexLifeDetailChanceMedium =>
      _t({'es': 'Media', 'en': 'Medium', 'fr': 'Moyenne', 'de': 'Mittel', 'ru': 'Средняя', 'ar': 'متوسطة', 'hi': 'मध्यम', 'bn': 'মাঝারি', 'pt': 'Média',});
  String get sexLifeDetailChanceLow =>
      _t({'es': 'Baja', 'en': 'Low', 'fr': 'Faible', 'de': 'Niedrig', 'ru': 'Низкая', 'ar': 'منخفضة', 'hi': 'कम', 'bn': 'কম', 'pt': 'Baixa',});
  String get sexLifeDetailDate =>
      _t({'es': 'Fecha', 'en': 'Date', 'fr': 'Date', 'de': 'Datum', 'ru': 'Дата', 'ar': 'التاريخ', 'hi': 'तारीख', 'bn': 'তারিখ', 'pt': 'Data',});
  String get sexLifeDetailOrgasmReportTitle =>
      _t({'es': 'Informe de orgasmo', 'en': 'Orgasm report', 'fr': "Rapport d'orgasme", 'de': 'Orgasmusbericht', 'ru': 'Отчёт об оргазме', 'ar': 'تقرير النشوة', 'hi': 'ऑर्गेज़्म रिपोर्ट', 'bn': 'অর্গাজম রিপোর্ট', 'pt': 'Relatório de orgasmo',});
  String get sexLifeDetailFrequencyStatsTitle =>
      _t({'es': 'Las estadísticas de frecuencia', 'en': 'Frequency statistics', 'fr': 'Statistiques de fréquence', 'de': 'Häufigkeitsstatistik', 'ru': 'Статистика частоты', 'ar': 'إحصائيات التكرار', 'hi': 'आवृत्ति के आंकड़े', 'bn': 'ফ্রিকোয়েন্সি পরিসংখ্যান', 'pt': 'Estatísticas de frequência',});
  String get sexLifeDetailFrequencySex =>
      _t({'es': 'Tienes sexo cada', 'en': 'You have sex every', 'fr': 'Vous avez des rapports tous les', 'de': 'Du hast Sex alle', 'ru': 'У тебя секс каждые', 'ar': 'تمارسين الجنس كل', 'hi': 'सेक्स की आवृत्ति: हर', 'bn': 'যৌনতার সংঘটন: প্রতি', 'pt': 'Você tem relações a cada',});
  String get sexLifeDetailFrequencyOrgasm =>
      _t({'es': 'Llegas al orgasmo cada', 'en': 'You reach orgasm every', 'fr': 'Vous atteignez l\'orgasme tous les', 'de': 'Du kommst alle', 'ru': 'Ты достигаешь оргазма каждые', 'ar': 'تصلين إلى النشوة كل', 'hi': 'ऑर्गेज़्म की आवृत्ति: हर', 'bn': 'অর্গাজমের সংঘটন: প্রতি', 'pt': 'Você atinge o orgasmo a cada',});
  String sexLifeDetailEveryNDays(int n) => _t({
        'es': '$n días',
        'en': '$n days',
        'fr': '$n jours',
        'de': '$n Tage',
        'ru': '$n дн.',
        'ar': '$n أيام', 'hi': '$n दिन', 'bn': '$n দিন', 'pt': '$n dias',
      });
  String get sexLifeDetailNoData =>
      _t({'es': 'Sin datos suficientes', 'en': 'Not enough data', 'fr': 'Données insuffisantes', 'de': 'Nicht genügend Daten', 'ru': 'Недостаточно данных', 'ar': 'لا توجد بيانات كافية', 'hi': 'पर्याप्त डेटा नहीं', 'bn': 'পর্যাপ্ত তথ্য নেই', 'pt': 'Dados insuficientes',});
  String get sexLifeDetailProtectedRecordsTitle =>
      _t({'es': 'Registros con protección', 'en': 'Protected records', 'fr': 'Enregistrements protégés', 'de': 'Geschützte Einträge', 'ru': 'Записи с защитой', 'ar': 'سجلات بحماية', 'hi': 'सुरक्षा वाले रिकॉर्ड', 'bn': 'সুরক্ষাসহ রেকর্ড', 'pt': 'Registros com proteção',});
  String get sexLifeDetailUnprotectedRecordsTitle =>
      _t({'es': 'Registros sin protección', 'en': 'Unprotected records', 'fr': 'Enregistrements non protégés', 'de': 'Ungeschützte Einträge', 'ru': 'Записи без защиты', 'ar': 'سجلات بدون حماية', 'hi': 'बिना सुरक्षा वाले रिकॉर्ड', 'bn': 'সুরক্ষা ছাড়া রেকর্ড', 'pt': 'Registros sem proteção',});
  String get sexLifeDetailNoRecordsInRange => _t({
        'es': 'No hay registros en los últimos 30 días.',
        'en': 'No records in the last 30 days.',
        'fr': 'Aucun enregistrement au cours des 30 derniers jours.',
        'de': 'Keine Einträge in den letzten 30 Tagen.',
        'ru': 'Нет записей за последние 30 дней.',
        'ar': 'لا توجد سجلات في آخر 30 يومًا.', 'hi': 'पिछले 30 दिनों में कोई रिकॉर्ड नहीं है।', 'bn': 'গত ৩০ দিনে কোনো রেকর্ড নেই।', 'pt': 'Não há registros nos últimos 30 dias.',
      });

  // ==================== today_screen.dart (Dato curioso / Explora tu anatomía) ====================
  String get todayFunFactLabel => _t({
        'es': 'DATO CURIOSO DEL DÍA',
        'en': 'FUN FACT OF THE DAY',
        'fr': 'LE FAIT DU JOUR',
        'de': 'WISSENSWERTES DES TAGES',
        'ru': 'ИНТЕРЕСНЫЙ ФАКТ ДНЯ',
        'ar': 'معلومة اليوم الطريفة',
        'hi': 'आज का रोचक तथ्य',
        'bn': 'আজকের মজার তথ্য',
        'pt': 'CURIOSIDADE DO DIA',
      });

  List<String> get todayFunFacts => _tList({
        'es': [
          'El útero es el único órgano capaz de crear otro órgano nuevo: la placenta 🤯',
          'Reír libera endorfinas — el antídoto natural contra un mal día 😄',
          'El chocolate negro (70%+) puede ayudar a calmar los antojos sin culpa 🍫',
          'Beber suficiente agua puede ayudar a reducir la hinchazón 💧',
          'El ciclo "de 28 días" es solo un promedio: entre 21 y 35 días también es normal 🌙',
          'Estirar 5 minutos al día ayuda tanto como parece — pruébalo hoy 🧘‍♀️',
          'Los antojos no son solo antojo: a veces el cuerpo pide un nutriente concreto 🍓',
          'Una siesta corta (20 min) puede con casi cualquier bajón de energía 😴',
          'El olfato cambia durante el ciclo — por eso algunos olores molestan más ciertos días 👃',
          'Escribir 3 cosas buenas del día mejora el ánimo más de lo que parece ✍️',
          'La música que te gusta baja el cortisol en minutos — ponte una canción ahora 🎶',
          'El cuerpo humano tiene más bacterias "buenas" que células propias — cuídalas comiendo fibra 🌾',
          'Un abrazo de 20 segundos libera oxitocina, la hormona del bienestar 🤗',
          'Beber té de jengibre es un clásico casero contra las náuseas y los cólicos 🫚',
        ],
        'en': [
          'The uterus is the only organ capable of creating a brand-new organ: the placenta 🤯',
          "Laughing releases endorphins — nature's antidote to a bad day 😄",
          'Dark chocolate (70%+) can help curb cravings without the guilt 🍫',
          'Drinking enough water can help reduce bloating 💧',
          'The "28-day" cycle is just an average — anywhere from 21 to 35 days is also normal 🌙',
          'Stretching for 5 minutes a day helps as much as it sounds — try it today 🧘‍♀️',
          "Cravings aren't just cravings — sometimes your body is asking for a specific nutrient 🍓",
          'A short nap (20 min) can beat almost any energy slump 😴',
          "Your sense of smell changes during your cycle — that's why some smells bother you more on certain days 👃",
          "Writing down 3 good things from your day boosts your mood more than you'd think ✍️",
          'Music you love lowers cortisol within minutes — put a song on right now 🎶',
          'The human body has more "good" bacteria than its own cells — feed them with fiber 🌾',
          'A 20-second hug releases oxytocin, the wellbeing hormone 🤗',
          'Drinking ginger tea is a classic home remedy for nausea and cramps 🫚',
        ],
        'fr': [
          "L'utérus est le seul organe capable de créer un tout nouvel organe : le placenta 🤯",
          "Rire libère des endorphines — l'antidote naturel à une mauvaise journée 😄",
          'Le chocolat noir (70 % et plus) peut aider à calmer les envies sans culpabiliser 🍫',
          'Boire assez d\'eau peut aider à réduire les ballonnements 💧',
          'Le cycle « de 28 jours » n\'est qu\'une moyenne : entre 21 et 35 jours, c\'est aussi normal 🌙',
          "S'étirer 5 minutes par jour aide autant qu'il n'y paraît — essaie aujourd'hui 🧘‍♀️",
          'Les envies ne sont pas que des caprices : parfois le corps réclame un nutriment précis 🍓',
          'Une courte sieste (20 min) peut venir à bout de presque tous les coups de fatigue 😴',
          "L'odorat change pendant le cycle — c'est pourquoi certaines odeurs dérangent plus certains jours 👃",
          "Écrire 3 bonnes choses de sa journée améliore l'humeur plus qu'on ne le pense ✍️",
          'La musique que tu aimes fait baisser le cortisol en quelques minutes — mets une chanson maintenant 🎶',
          'Le corps humain compte plus de "bonnes" bactéries que de cellules propres — prends-en soin avec des fibres 🌾',
          "Un câlin de 20 secondes libère de l'ocytocine, l'hormone du bien-être 🤗",
          'Boire du thé au gingembre est un classique maison contre les nausées et les crampes 🫚',
        ],
        'de': [
          'Die Gebärmutter ist das einzige Organ, das ein völlig neues Organ erschaffen kann: die Plazenta 🤯',
          'Lachen setzt Endorphine frei — das natürliche Gegenmittel gegen einen schlechten Tag 😄',
          'Dunkle Schokolade (70 %+) kann Heißhunger ohne schlechtes Gewissen zügeln 🍫',
          'Ausreichend Wasser zu trinken kann helfen, Blähungen zu reduzieren 💧',
          'Der "28-Tage-Zyklus" ist nur ein Durchschnitt — zwischen 21 und 35 Tagen ist ebenfalls normal 🌙',
          'Fünf Minuten Dehnen am Tag hilft mehr, als man denkt — probier es heute aus 🧘‍♀️',
          'Heißhunger ist nicht immer nur Lust — manchmal verlangt der Körper nach einem bestimmten Nährstoff 🍓',
          'Ein kurzes Nickerchen (20 Min.) schlägt fast jedes Energietief 😴',
          'Der Geruchssinn verändert sich während des Zyklus — deshalb stören manche Gerüche an bestimmten Tagen mehr 👃',
          'Drei gute Dinge des Tages aufzuschreiben hebt die Stimmung mehr, als man denkt ✍️',
          'Musik, die dir gefällt, senkt den Cortisolspiegel innerhalb von Minuten — leg jetzt einen Song auf 🎶',
          'Der menschliche Körper hat mehr "gute" Bakterien als eigene Zellen — pflege sie mit Ballaststoffen 🌾',
          'Eine 20-sekündige Umarmung setzt Oxytocin frei, das Wohlfühlhormon 🤗',
          'Ingwertee zu trinken ist ein klassisches Hausmittel gegen Übelkeit und Krämpfe 🫚',
        ],
        'ru': [
          'Матка — единственный орган, способный создать совершенно новый орган: плаценту 🤯',
          'Смех высвобождает эндорфины — естественное противоядие от плохого дня 😄',
          'Тёмный шоколад (70%+) может помочь унять тягу к сладкому без чувства вины 🍫',
          'Достаточное количество воды может помочь уменьшить вздутие 💧',
          'Цикл "в 28 дней" — это лишь среднее значение: от 21 до 35 дней тоже нормально 🌙',
          'Растяжка по 5 минут в день помогает не меньше, чем кажется — попробуй сегодня 🧘‍♀️',
          'Тяга к еде — не просто прихоть: иногда организм просит конкретный питательный элемент 🍓',
          'Короткий сон (20 минут) справляется почти с любым упадком сил 😴',
          'Обоняние меняется в течение цикла — поэтому некоторые запахи раздражают сильнее в определённые дни 👃',
          'Записывать 3 хороших момента дня улучшает настроение сильнее, чем кажется ✍️',
          'Музыка, которая тебе нравится, снижает уровень кортизола за считаные минуты — включи песню прямо сейчас 🎶',
          'В человеческом теле больше "хороших" бактерий, чем собственных клеток — заботься о них с помощью клетчатки 🌾',
          'Объятие длиной 20 секунд высвобождает окситоцин — гормон хорошего самочувствия 🤗',
          'Имбирный чай — классическое домашнее средство от тошноты и спазмов 🫚',
        ],
        'ar': [
          'الرحم هو العضو الوحيد القادر على تكوين عضو جديد تمامًا: المشيمة 🤯',
          'الضحك يفرز الإندورفين — الترياق الطبيعي ليوم سيئ 😄',
          'الشوكولاتة الداكنة (70% فأكثر) يمكن أن تهدئ الرغبة الشديدة في الحلويات دون شعور بالذنب 🍫',
          'شرب كمية كافية من الماء قد يساعد في تقليل الانتفاخ 💧',
          'دورة "الـ28 يومًا" مجرد متوسط: بين 21 و35 يومًا يُعد طبيعيًا أيضًا 🌙',
          'التمدد 5 دقائق يوميًا يساعد أكثر مما يبدو — جربيه اليوم 🧘‍♀️',
          'الرغبة الشديدة في الطعام ليست مجرد نزوة: أحيانًا يطلب الجسم عنصرًا غذائيًا محددًا 🍓',
          'قيلولة قصيرة (20 دقيقة) قد تتغلب على أي إرهاق تقريبًا 😴',
          'حاسة الشم تتغير خلال الدورة — لهذا تزعج بعض الروائح أكثر في أيام معينة 👃',
          'كتابة 3 أشياء جيدة عن يومك تحسّن المزاج أكثر مما يبدو ✍️',
          'الموسيقى التي تحبينها تخفض الكورتيزول خلال دقائق — شغّلي أغنية الآن 🎶',
          'جسم الإنسان يحتوي على بكتيريا "نافعة" أكثر من خلاياه الخاصة — اعتني بها بتناول الألياف 🌾',
          'عناق لمدة 20 ثانية يفرز الأوكسيتوسين، هرمون الشعور بالراحة 🤗',
          'شرب شاي الزنجبيل علاج منزلي كلاسيكي للغثيان والتشنجات 🫚',
        ],
        'hi': [
          'गर्भाशय एकमात्र ऐसा अंग है जो एक बिल्कुल नया अंग बना सकता है: प्लेसेंटा 🤯',
          'हंसने से एंडोर्फिन निकलते हैं — बुरे दिन का प्राकृतिक इलाज 😄',
          'डार्क चॉकलेट (70%+) बिना अपराधबोध के क्रेविंग शांत करने में मदद कर सकती है 🍫',
          'पर्याप्त पानी पीने से सूजन कम करने में मदद मिल सकती है 💧',
          '"28 दिन" का चक्र केवल एक औसत है — 21 से 35 दिनों के बीच होना भी सामान्य है 🌙',
          'रोज़ 5 मिनट स्ट्रेचिंग उतना ही फायदा करती है जितना लगता है — आज आज़माएं 🧘‍♀️',
          'क्रेविंग सिर्फ इच्छा नहीं होती — कभी-कभी शरीर किसी खास पोषक तत्व की मांग करता है 🍓',
          'एक छोटी झपकी (20 मिनट) लगभग किसी भी थकान को दूर कर सकती है 😴',
          'चक्र के दौरान सूंघने की क्षमता बदलती है — इसीलिए कुछ दिनों में कुछ गंधें ज़्यादा परेशान करती हैं 👃',
          'दिन की 3 अच्छी बातें लिखने से मूड उतना बेहतर होता है जितना लगता नहीं ✍️',
          'पसंदीदा संगीत मिनटों में कॉर्टिसोल कम करता है — अभी एक गाना लगाएं 🎶',
          'मानव शरीर में अपनी कोशिकाओं से ज़्यादा "अच्छे" बैक्टीरिया होते हैं — फाइबर खाकर इनका ख्याल रखें 🌾',
          '20 सेकंड का आलिंगन ऑक्सीटोसिन छोड़ता है, जो खुशहाली का हार्मोन है 🤗',
          'अदरक की चाय पीना मतली और ऐंठन के लिए एक क्लासिक घरेलू नुस्खा है 🫚',
        ],
        'bn': [
          'জরায়ু হলো একমাত্র অঙ্গ যা সম্পূর্ণ নতুন একটি অঙ্গ তৈরি করতে পারে: প্লাসেন্টা 🤯',
          'হাসলে এন্ডোরফিন নিঃসৃত হয় — খারাপ দিনের প্রাকৃতিক প্রতিষেধক 😄',
          'ডার্ক চকোলেট (৭০%+) অপরাধবোধ ছাড়াই ক্রেভিং কমাতে সাহায্য করতে পারে 🍫',
          'পর্যাপ্ত পানি পান করলে ফোলাভাব কমাতে সাহায্য হতে পারে 💧',
          '"২৮ দিনের" চক্র শুধু একটি গড় সংখ্যা — ২১ থেকে ৩৫ দিনও স্বাভাবিক 🌙',
          'দিনে ৫ মিনিট স্ট্রেচিং যতটা মনে হয় ততটাই উপকারী — আজই চেষ্টা করুন 🧘‍♀️',
          'ক্রেভিং শুধু ইচ্ছা নয় — কখনো কখনো শরীর একটি নির্দিষ্ট পুষ্টি উপাদান চায় 🍓',
          'একটি ছোট ঘুম (২০ মিনিট) প্রায় যেকোনো ক্লান্তি দূর করতে পারে 😴',
          'চক্রের সময় ঘ্রাণশক্তি বদলায় — তাই কিছু গন্ধ নির্দিষ্ট দিনে বেশি বিরক্তিকর মনে হয় 👃',
          'দিনের ৩টি ভালো বিষয় লিখলে মেজাজ যতটা মনে হয় তার চেয়ে বেশি ভালো হয় ✍️',
          'পছন্দের গান মিনিটেই কর্টিসল কমায় — এখনই একটি গান চালান 🎶',
          'মানবদেহে নিজের কোষের চেয়ে বেশি "ভালো" ব্যাকটেরিয়া থাকে — ফাইবার খেয়ে এদের যত্ন নিন 🌾',
          '২০ সেকেন্ডের একটি আলিঙ্গন অক্সিটোসিন নিঃসরণ করে, যা সুখানুভূতির হরমোন 🤗',
          'আদা চা বমি বমি ভাব ও পেটব্যথার জন্য একটি ক্লাসিক ঘরোয়া প্রতিকার 🫚',
        ],
        'pt': [
          'O útero é o único órgão capaz de criar um órgão totalmente novo: a placenta 🤯',
          'Rir libera endorfinas — o antídoto natural para um dia ruim 😄',
          'O chocolate amargo (70%+) pode ajudar a acalmar a vontade de comer doce sem culpa 🍫',
          'Beber água suficiente pode ajudar a reduzir o inchaço 💧',
          'O ciclo "de 28 dias" é apenas uma média: entre 21 e 35 dias também é normal 🌙',
          'Alongar-se por 5 minutos por dia ajuda tanto quanto parece — experimente hoje 🧘‍♀️',
          'As vontades não são só vontade: às vezes o corpo pede um nutriente específico 🍓',
          'Uma soneca curta (20 min) resolve quase qualquer baixa de energia 😴',
          'O olfato muda durante o ciclo — por isso alguns cheiros incomodam mais em certos dias 👃',
          'Escrever 3 coisas boas do dia melhora o humor mais do que parece ✍️',
          'A música que você gosta reduz o cortisol em minutos — coloque uma música agora 🎶',
          'O corpo humano tem mais bactérias "boas" do que células próprias — cuide delas comendo fibras 🌾',
          'Um abraço de 20 segundos libera ocitocina, o hormônio do bem-estar 🤗',
          'Beber chá de gengibre é um clássico caseiro contra náuseas e cólicas 🫚',
        ],
      });

  // "Dato curioso del día" pedido de diferenciar por objetivo ("y que haga
  // bien la diferencia con los 3 objetivos"): `todayFunFacts` de arriba se
  // usa para "Seguir mi período" (datos generales de ciclo/bienestar);
  // estas dos listas nuevas se usan para "Intentar concebir" (fertilidad/
  // ventana fértil) y "Seguir mi embarazo" (embarazo/desarrollo del bebé)
  // — misma mecánica de rotación diaria en `_buildFunFactCard`, solo que
  // eligiendo la lista según `tryingToConceive`/`inPregnancyMode`.
  List<String> get todayFunFactsFertility => _tList({
        'es': [
          'La ventana fértil dura unos 6 días: los 5 antes de la ovulación y el día de la ovulación 🥚',
          'El ácido fólico antes del embarazo ayuda a prevenir defectos del tubo neural 🌿',
          'El moco cervical cambia de textura cerca de la ovulación — se vuelve más elástico, como clara de huevo 💧',
          'El estrés crónico puede alterar el ciclo y retrasar la ovulación — cuidar la mente también ayuda a concebir 🧘‍♀️',
          'Tener relaciones cada 1-2 días durante la ventana fértil maximiza las probabilidades 📅',
          'La temperatura basal sube ligeramente tras la ovulación — por eso algunas la usan para detectarla 🌡️',
          'El espermatozoide puede sobrevivir hasta 5 días dentro del cuerpo esperando al óvulo ⏳',
          'Dormir bien y mantener un peso saludable favorecen el equilibrio hormonal necesario para concebir 😴',
        ],
        'en': [
          'The fertile window lasts about 6 days: the 5 before ovulation and ovulation day itself 🥚',
          'Folic acid before pregnancy helps prevent neural tube defects 🌿',
          'Cervical mucus changes texture near ovulation — it becomes stretchier, like egg white 💧',
          "Chronic stress can disrupt your cycle and delay ovulation — caring for your mind helps conception too 🧘‍♀️",
          'Having sex every 1-2 days during the fertile window maximizes your chances 📅',
          "Basal body temperature rises slightly after ovulation — that's why some track it to detect it 🌡️",
          'Sperm can survive up to 5 days inside the body waiting for the egg ⏳',
          'Sleeping well and maintaining a healthy weight support the hormonal balance needed to conceive 😴',
        ],
        'fr': [
          "La fenêtre de fertilité dure environ 6 jours : les 5 jours avant l'ovulation et le jour de l'ovulation lui-même 🥚",
          "L'acide folique avant la grossesse aide à prévenir les anomalies du tube neural 🌿",
          'La glaire cervicale change de texture près de l\'ovulation — elle devient plus élastique, comme du blanc d\'œuf 💧',
          "Le stress chronique peut perturber le cycle et retarder l'ovulation — prendre soin de son esprit aide aussi à concevoir 🧘‍♀️",
          'Avoir des rapports tous les 1 à 2 jours pendant la fenêtre de fertilité maximise les chances 📅',
          "La température basale augmente légèrement après l'ovulation — c'est pourquoi certaines la suivent pour la détecter 🌡️",
          'Les spermatozoïdes peuvent survivre jusqu\'à 5 jours dans le corps en attendant l\'ovule ⏳',
          'Bien dormir et maintenir un poids sain favorisent l\'équilibre hormonal nécessaire pour concevoir 😴',
        ],
        'de': [
          'Das fruchtbare Fenster dauert etwa 6 Tage: die 5 Tage vor dem Eisprung und der Tag des Eisprungs selbst 🥚',
          'Folsäure vor der Schwangerschaft hilft, Neuralrohrdefekte zu verhindern 🌿',
          'Der Zervixschleim verändert seine Konsistenz kurz vor dem Eisprung — er wird dehnbarer, wie Eiweiß 💧',
          'Chronischer Stress kann den Zyklus stören und den Eisprung verzögern — auf die eigene Psyche zu achten hilft auch bei der Empfängnis 🧘‍♀️',
          'Alle 1–2 Tage Sex während des fruchtbaren Fensters zu haben maximiert die Chancen 📅',
          'Die Basaltemperatur steigt nach dem Eisprung leicht an — deshalb nutzen manche sie, um ihn zu erkennen 🌡️',
          'Spermien können bis zu 5 Tage im Körper überleben und auf die Eizelle warten ⏳',
          'Guter Schlaf und ein gesundes Gewicht unterstützen das hormonelle Gleichgewicht, das für die Empfängnis nötig ist 😴',
        ],
        'ru': [
          'Фертильное окно длится около 6 дней: 5 дней до овуляции и сам день овуляции 🥚',
          'Фолиевая кислота до беременности помогает предотвратить дефекты нервной трубки 🌿',
          'Цервикальная слизь меняет текстуру ближе к овуляции — становится более тягучей, как яичный белок 💧',
          'Хронический стресс может нарушить цикл и задержать овуляцию — забота о психике тоже помогает зачатию 🧘‍♀️',
          'Половые контакты каждые 1–2 дня в фертильное окно повышают шансы 📅',
          'Базальная температура немного повышается после овуляции — поэтому её отслеживают, чтобы определить овуляцию 🌡️',
          'Сперматозоиды могут жить в организме до 5 дней, ожидая яйцеклетку ⏳',
          'Хороший сон и здоровый вес поддерживают гормональный баланс, необходимый для зачатия 😴',
        ],
        'ar': [
          'تستمر نافذة الخصوبة نحو 6 أيام: الخمسة أيام التي تسبق الإباضة ويوم الإباضة نفسه 🥚',
          'حمض الفوليك قبل الحمل يساعد في الوقاية من عيوب الأنبوب العصبي 🌿',
          'يتغيّر قوام المخاط العنقي قرب الإباضة — يصبح أكثر مرونة، أشبه ببياض البيض 💧',
          'التوتر المزمن قد يخل بالدورة ويؤخر الإباضة — الاهتمام بالصحة النفسية يساعد أيضًا على الحمل 🧘‍♀️',
          'ممارسة العلاقة كل يوم أو يومين خلال نافذة الخصوبة يزيد من فرص الحمل 📅',
          'ترتفع درجة الحرارة الأساسية قليلًا بعد الإباضة — لهذا تتابعها بعض النساء لتحديد موعدها 🌡️',
          'يمكن للحيوانات المنوية أن تعيش داخل الجسم حتى 5 أيام بانتظار البويضة ⏳',
          'النوم الجيد والوزن الصحي يدعمان التوازن الهرموني اللازم للحمل 😴',
        ],
        'hi': [
          'उपजाऊ खिड़की लगभग 6 दिन तक रहती है: ओव्यूलेशन से पहले के 5 दिन और ओव्यूलेशन का दिन खुद 🥚',
          'गर्भधारण से पहले फोलिक एसिड न्यूरल ट्यूब दोषों को रोकने में मदद करता है 🌿',
          'ओव्यूलेशन के करीब सर्वाइकल म्यूकस की बनावट बदलती है — यह अंडे की सफेदी जैसा लचीला हो जाता है 💧',
          'लगातार तनाव चक्र को बिगाड़ सकता है और ओव्यूलेशन में देरी कर सकता है — मन का ध्यान रखना भी गर्भधारण में मदद करता है 🧘‍♀️',
          'उपजाऊ खिड़की के दौरान हर 1-2 दिन में संबंध बनाना संभावनाएं बढ़ाता है 📅',
          'ओव्यूलेशन के बाद बेसल तापमान थोड़ा बढ़ जाता है — इसीलिए कुछ लोग इसे ट्रैक करते हैं 🌡️',
          'शुक्राणु अंडे का इंतज़ार करते हुए शरीर के अंदर 5 दिनों तक जीवित रह सकते हैं ⏳',
          'अच्छी नींद और स्वस्थ वज़न गर्भधारण के लिए ज़रूरी हार्मोनल संतुलन बनाए रखने में मदद करते हैं 😴',
        ],
        'bn': [
          'উর্বর সময়কাল প্রায় ৬ দিন স্থায়ী হয়: ডিম্বস্ফোটনের আগের ৫ দিন এবং ডিম্বস্ফোটনের দিনটি নিজেই 🥚',
          'গর্ভধারণের আগে ফলিক অ্যাসিড নিউরাল টিউব ত্রুটি প্রতিরোধে সাহায্য করে 🌿',
          'ডিম্বস্ফোটনের কাছাকাছি সার্ভিকাল মিউকাসের গঠন পরিবর্তিত হয় — এটি ডিমের সাদা অংশের মতো আরও স্থিতিস্থাপক হয়ে ওঠে 💧',
          'দীর্ঘস্থায়ী মানসিক চাপ চক্রকে বিঘ্নিত করতে এবং ডিম্বস্ফোটন বিলম্বিত করতে পারে — মনের যত্ন নেওয়াও গর্ভধারণে সাহায্য করে 🧘‍♀️',
          'উর্বর সময়কালে প্রতি ১-২ দিনে মিলন সম্ভাবনা বাড়ায় 📅',
          'ডিম্বস্ফোটনের পরে বেসাল তাপমাত্রা সামান্য বেড়ে যায় — তাই অনেকে এটি ট্র্যাক করেন 🌡️',
          'শুক্রাণু ডিম্বাণুর অপেক্ষায় শরীরের ভিতরে ৫ দিন পর্যন্ত বাঁচতে পারে ⏳',
          'ভালো ঘুম এবং স্বাস্থ্যকর ওজন গর্ভধারণের জন্য প্রয়োজনীয় হরমোনাল ভারসাম্য বজায় রাখতে সাহায্য করে 😴',
        ],
        'pt': [
          'A janela fértil dura cerca de 6 dias: os 5 dias antes da ovulação e o próprio dia da ovulação 🥚',
          'O ácido fólico antes da gravidez ajuda a prevenir defeitos do tubo neural 🌿',
          'O muco cervical muda de textura perto da ovulação — fica mais elástico, como clara de ovo 💧',
          'O estresse crônico pode alterar o ciclo e atrasar a ovulação — cuidar da mente também ajuda a engravidar 🧘‍♀️',
          'Ter relações a cada 1-2 dias durante a janela fértil maximiza as chances 📅',
          'A temperatura basal sobe ligeiramente após a ovulação — por isso algumas pessoas a monitoram 🌡️',
          'O espermatozoide pode sobreviver até 5 dias dentro do corpo esperando pelo óvulo ⏳',
          'Dormir bem e manter um peso saudável favorecem o equilíbrio hormonal necessário para engravidar 😴',
        ],
      });

  List<String> get todayFunFactsPregnancy => _tList({
        'es': [
          'El corazón del bebé empieza a latir alrededor de la semana 6 💓',
          'El útero puede multiplicar su tamaño hasta por 500 durante el embarazo 🤰',
          'El bebé puede escuchar sonidos desde alrededor de la semana 18 🎶',
          'El olfato más sensible en el embarazo es real: los cambios hormonales lo intensifican 👃',
          'Las huellas dactilares del bebé ya están formadas hacia la semana 17 🖐️',
          'El líquido amniótico se renueva por completo cada pocas horas 💧',
          'El bebé traga líquido amniótico y hasta puede tener hipo en el útero 😊',
          'La placenta actúa como un órgano completo: produce hormonas, filtra nutrientes y protege al bebé 🌸',
        ],
        'en': [
          "The baby's heart starts beating around week 6 💓",
          'The uterus can grow up to 500 times its size during pregnancy 🤰',
          'The baby can hear sounds from around week 18 🎶',
          "A heightened sense of smell in pregnancy is real — hormonal changes intensify it 👃",
          "The baby's fingerprints are already formed by around week 17 🖐️",
          'Amniotic fluid completely renews itself every few hours 💧',
          'The baby swallows amniotic fluid and can even get hiccups in the womb 😊',
          'The placenta acts like a full organ: it produces hormones, filters nutrients, and protects the baby 🌸',
        ],
        'fr': [
          'Le cœur du bébé commence à battre vers la semaine 6 💓',
          "L'utérus peut multiplier sa taille jusqu'à 500 fois pendant la grossesse 🤰",
          'Le bébé peut entendre des sons dès environ la semaine 18 🎶',
          "L'odorat plus sensible pendant la grossesse est bien réel : les changements hormonaux l'intensifient 👃",
          'Les empreintes digitales du bébé sont déjà formées vers la semaine 17 🖐️',
          'Le liquide amniotique se renouvelle complètement toutes les quelques heures 💧',
          'Le bébé avale du liquide amniotique et peut même avoir le hoquet dans l\'utérus 😊',
          'Le placenta agit comme un organe à part entière : il produit des hormones, filtre les nutriments et protège le bébé 🌸',
        ],
        'de': [
          'Das Herz des Babys beginnt etwa in Woche 6 zu schlagen 💓',
          'Die Gebärmutter kann sich während der Schwangerschaft bis auf das 500-Fache vergrößern 🤰',
          'Das Baby kann ab etwa Woche 18 Geräusche hören 🎶',
          'Ein verstärkter Geruchssinn in der Schwangerschaft ist real — hormonelle Veränderungen verstärken ihn 👃',
          'Die Fingerabdrücke des Babys sind bereits um Woche 17 herum ausgebildet 🖐️',
          'Das Fruchtwasser erneuert sich alle paar Stunden vollständig 💧',
          'Das Baby schluckt Fruchtwasser und kann im Mutterleib sogar Schluckauf bekommen 😊',
          'Die Plazenta funktioniert wie ein vollständiges Organ: Sie produziert Hormone, filtert Nährstoffe und schützt das Baby 🌸',
        ],
        'ru': [
          'Сердце малыша начинает биться примерно на 6-й неделе 💓',
          'Матка может увеличиться в размере до 500 раз за время беременности 🤰',
          'Малыш может слышать звуки примерно с 18-й недели 🎶',
          'Обострённое обоняние при беременности реально — гормональные изменения его усиливают 👃',
          'Отпечатки пальцев малыша уже сформированы примерно к 17-й неделе 🖐️',
          'Околоплодные воды полностью обновляются каждые несколько часов 💧',
          'Малыш глотает околоплодные воды и даже может икать в утробе 😊',
          'Плацента действует как полноценный орган: вырабатывает гормоны, фильтрует питательные вещества и защищает малыша 🌸',
        ],
        'ar': [
          'يبدأ قلب الجنين بالنبض في نحو الأسبوع السادس 💓',
          'يمكن أن يكبر الرحم حتى 500 ضعف حجمه خلال الحمل 🤰',
          'يستطيع الجنين سماع الأصوات ابتداءً من نحو الأسبوع الثامن عشر 🎶',
          'حاسة الشم الأكثر حساسية أثناء الحمل حقيقية — التغيرات الهرمونية تعزّزها 👃',
          'تتكوّن بصمات أصابع الجنين تقريبًا بحلول الأسبوع السابع عشر 🖐️',
          'يتجدد السائل الأمنيوسي بالكامل كل بضع ساعات 💧',
          'يبتلع الجنين السائل الأمنيوسي وقد يصاب بالفواق داخل الرحم 😊',
          'تعمل المشيمة كعضو كامل: تنتج الهرمونات وتُرشّح العناصر الغذائية وتحمي الجنين 🌸',
        ],
        'hi': [
          'बच्चे का दिल लगभग सप्ताह 6 में धड़कना शुरू करता है 💓',
          'गर्भावस्था के दौरान गर्भाशय अपने आकार से 500 गुना तक बड़ा हो सकता है 🤰',
          'बच्चा लगभग सप्ताह 18 से आवाज़ें सुन सकता है 🎶',
          'गर्भावस्था में सूंघने की तेज़ क्षमता असली होती है — हार्मोनल बदलाव इसे और तेज़ कर देते हैं 👃',
          'बच्चे के फिंगरप्रिंट लगभग सप्ताह 17 तक बन चुके होते हैं 🖐️',
          'एम्नियोटिक द्रव हर कुछ घंटों में पूरी तरह से नवीनीकृत होता है 💧',
          'बच्चा एम्नियोटिक द्रव निगलता है और गर्भ में हिचकी भी ले सकता है 😊',
          'प्लेसेंटा एक पूरे अंग की तरह काम करता है: यह हार्मोन बनाता है, पोषक तत्वों को छानता है और बच्चे की रक्षा करता है 🌸',
        ],
        'bn': [
          'শিশুর হৃদস্পন্দন প্রায় ৬ সপ্তাহে শুরু হয় 💓',
          'গর্ভাবস্থায় জরায়ু তার আকারের ৫০০ গুণ পর্যন্ত বড় হতে পারে 🤰',
          'শিশু প্রায় ১৮ সপ্তাহ থেকে শব্দ শুনতে পারে 🎶',
          'গর্ভাবস্থায় ঘ্রাণশক্তি আরও তীক্ষ্ণ হওয়া সত্যি — হরমোনের পরিবর্তন এটিকে তীব্র করে 👃',
          'শিশুর আঙুলের ছাপ প্রায় ১৭ সপ্তাহের মধ্যে তৈরি হয়ে যায় 🖐️',
          'অ্যামনিওটিক ফ্লুইড প্রতি কয়েক ঘণ্টায় সম্পূর্ণরূপে নবায়ন হয় 💧',
          'শিশু অ্যামনিওটিক ফ্লুইড গিলে ফেলে এবং গর্ভে হেঁচকিও তুলতে পারে 😊',
          'প্লাসেন্টা একটি সম্পূর্ণ অঙ্গের মতো কাজ করে: এটি হরমোন তৈরি করে, পুষ্টি ফিল্টার করে এবং শিশুকে রক্ষা করে 🌸',
        ],
        'pt': [
          'O coração do bebê começa a bater por volta da semana 6 💓',
          'O útero pode multiplicar seu tamanho em até 500 vezes durante a gravidez 🤰',
          'O bebê consegue ouvir sons a partir de cerca da semana 18 🎶',
          'O olfato mais sensível na gravidez é real: as mudanças hormonais o intensificam 👃',
          'As impressões digitais do bebê já estão formadas por volta da semana 17 🖐️',
          'O líquido amniótico se renova completamente a cada poucas horas 💧',
          'O bebê engole líquido amniótico e pode até ter soluços no útero 😊',
          'A placenta age como um órgão completo: produz hormônios, filtra nutrientes e protege o bebê 🌸',
        ],
      });

  String get exploreAnatomyTitle => _t({
        'es': 'Explora tu anatomía',
        'en': 'Explore your anatomy',
        'fr': 'Explore ton anatomie',
        'de': 'Entdecke deine Anatomie',
        'ru': 'Изучи свою анатомию',
        'ar': 'استكشفي تشريحك',
        'hi': 'अपनी शारीरिक रचना जानें',
        'bn': 'আপনার অ্যানাটমি জানুন',
        'pt': 'Explore sua anatomia',
      });

  String get anatomyInteractiveModelSubtitle => _t({
        'es': 'Modelo interactivo del útero',
        'en': 'Interactive model of the uterus',
        'fr': "Modèle interactif de l'utérus",
        'de': 'Interaktives Modell der Gebärmutter',
        'ru': 'Интерактивная модель матки',
        'ar': 'نموذج تفاعلي للرحم',
        'hi': 'गर्भाशय का इंटरैक्टिव मॉडल',
        'bn': 'জরায়ুর ইন্টারঅ্যাক্টিভ মডেল',
        'pt': 'Modelo interativo do útero',
      });

  String anatomyNowMoment(String shortName) => _t({
        'es': 'Ahora mismo: $shortName',
        'en': 'Right now: $shortName',
        'fr': 'En ce moment : $shortName',
        'de': 'Gerade jetzt: $shortName',
        'ru': 'Сейчас: $shortName',
        'ar': 'الآن: $shortName',
        'hi': 'अभी: $shortName',
        'bn': 'এখন: $shortName',
        'pt': 'Agora mesmo: $shortName',
      });

  String anatomyNow(String shortName) => _t({
        'es': 'Ahora: $shortName',
        'en': 'Now: $shortName',
        'fr': 'Maintenant : $shortName',
        'de': 'Jetzt: $shortName',
        'ru': 'Сейчас: $shortName',
        'ar': 'الآن: $shortName',
        'hi': 'अभी: $shortName',
        'bn': 'এখন: $shortName',
        'pt': 'Agora: $shortName',
      });

  String anatomyNowAndNext(String shortName, String nextShortName) => _t({
        'es': 'Ahora: $shortName · Después: $nextShortName',
        'en': 'Now: $shortName · Next: $nextShortName',
        'fr': 'Maintenant : $shortName · Ensuite : $nextShortName',
        'de': 'Jetzt: $shortName · Danach: $nextShortName',
        'ru': 'Сейчас: $shortName · Далее: $nextShortName',
        'ar': 'الآن: $shortName · بعد ذلك: $nextShortName',
        'hi': 'अभी: $shortName · आगे: $nextShortName',
        'bn': 'এখন: $shortName · এরপর: $nextShortName',
        'pt': 'Agora: $shortName · Depois: $nextShortName',
      });

  String get anatomyDragHint => _t({
        'es': 'Arrastra la imagen o usa las flechas para descubrir cada parte',
        'en': 'Drag the image or use the arrows to discover each part',
        'fr': "Fais glisser l'image ou utilise les flèches pour découvrir chaque partie",
        'de': 'Ziehe das Bild oder benutze die Pfeile, um jeden Teil zu entdecken',
        'ru': 'Перемещай изображение или используй стрелки, чтобы изучить каждую часть',
        'ar': 'اسحبي الصورة أو استخدمي الأسهم لاكتشاف كل جزء',
        'hi': 'हर हिस्से को जानने के लिए तस्वीर को घुमाएं या तीरों का उपयोग करें',
        'bn': 'প্রতিটি অংশ জানতে ছবিটি টেনে দেখুন বা তীরচিহ্ন ব্যবহার করুন',
        'pt': 'Arraste a imagem ou use as setas para descobrir cada parte',
      });

  String get anatomyViewButton => _t({
        'es': 'Ver',
        'en': 'View',
        'fr': 'Voir',
        'de': 'Ansehen',
        'ru': 'Смотреть',
        'ar': 'عرض',
        'hi': 'देखें',
        'bn': 'দেখুন',
        'pt': 'Ver',
      });

  String get anatomyEmptyHint => _t({
        'es': 'Toca un punto del dibujo o usa las flechas para explorar.',
        'en': 'Tap a point on the drawing or use the arrows to explore.',
        'fr': 'Touche un point du dessin ou utilise les flèches pour explorer.',
        'de': 'Tippe auf einen Punkt der Zeichnung oder nutze die Pfeile zum Erkunden.',
        'ru': 'Коснись точки на рисунке или используй стрелки, чтобы изучить.',
        'ar': 'المسي نقطة في الرسم أو استخدمي الأسهم للاستكشاف.',
        'hi': 'चित्र पर किसी बिंदु को टैप करें या तीरों से जानें।',
        'bn': 'ছবির কোনো বিন্দু চাপুন অথবা তীরচিহ্ন ব্যবহার করে ঘুরে দেখুন।',
        'pt': 'Toque em um ponto do desenho ou use as setas para explorar.',
      });

  String anatomyNextPhaseFollows(String shortName) => _t({
        'es': 'Después le sigue $shortName',
        'en': 'Next comes $shortName',
        'fr': 'Vient ensuite $shortName',
        'de': 'Danach folgt $shortName',
        'ru': 'Далее наступит $shortName',
        'ar': 'يليها $shortName',
        'hi': 'इसके बाद आता है $shortName',
        'bn': 'এরপর আসে $shortName',
        'pt': 'Depois vem $shortName',
      });

  String get anatomyViewCurrentState => _t({
        'es': 'Ver mi estado actual',
        'en': 'View my current state',
        'fr': 'Voir mon état actuel',
        'de': 'Meinen aktuellen Status ansehen',
        'ru': 'Посмотреть моё текущее состояние',
        'ar': 'عرض حالتي الحالية',
        'hi': 'मेरी वर्तमान स्थिति देखें',
        'bn': 'আমার বর্তমান অবস্থা দেখুন',
        'pt': 'Ver meu estado atual',
      });

  // ---- Fase del ciclo mostrada en la tarjeta de anatomía ----
  String get phaseLabelPregnancy => _t({'es': 'TU ESTADO ACTUAL · EMBARAZO', 'en': 'YOUR CURRENT STATE · PREGNANCY', 'fr': 'TON ÉTAT ACTUEL · GROSSESSE', 'de': 'DEIN AKTUELLER STATUS · SCHWANGERSCHAFT', 'ru': 'ТВОЁ ТЕКУЩЕЕ СОСТОЯНИЕ · БЕРЕМЕННОСТЬ', 'ar': 'حالتك الحالية · الحمل', 'hi': 'आपकी वर्तमान स्थिति · गर्भावस्था', 'bn': 'আপনার বর্তমান অবস্থা · গর্ভাবস্থা', 'pt': 'SEU ESTADO ATUAL · GRAVIDEZ'});
  String get phaseShortNamePregnancy => _t({'es': 'tu embarazo', 'en': 'your pregnancy', 'fr': 'ta grossesse', 'de': 'deine Schwangerschaft', 'ru': 'твою беременность', 'ar': 'حملكِ', 'hi': 'आपकी गर्भावस्था', 'bn': 'আপনার গর্ভাবস্থা', 'pt': 'sua gravidez'});
  String get phaseDescriptionPregnancy => _t({
        'es': 'Tu cuerpo está en modo embarazo: el útero se expande poco a poco para alojar y proteger al bebé en desarrollo.',
        'en': 'Your body is in pregnancy mode: the uterus gradually expands to house and protect the developing baby.',
        'fr': "Ton corps est en mode grossesse : l'utérus s'agrandit peu à peu pour loger et protéger le bébé en développement.",
        'de': 'Dein Körper befindet sich im Schwangerschaftsmodus: Die Gebärmutter dehnt sich nach und nach aus, um das heranwachsende Baby zu beherbergen und zu schützen.',
        'ru': 'Твоё тело находится в режиме беременности: матка постепенно увеличивается, чтобы вместить и защитить развивающегося ребёнка.',
        'ar': 'جسمكِ في وضع الحمل: يتمدد الرحم تدريجيًا لاستيعاب الجنين النامي وحمايته.',
        'hi': 'आपका शरीर गर्भावस्था मोड में है: गर्भाशय धीरे-धीरे फैलता है ताकि विकसित हो रहे शिशु को समायोजित कर सके और उसकी सुरक्षा कर सके।',
        'bn': 'আপনার শরীর গর্ভাবস্থা মোডে আছে: বিকাশমান শিশুকে ধারণ ও সুরক্ষা দিতে জরায়ু ধীরে ধীরে প্রসারিত হয়।',
        'pt': 'Seu corpo está em modo gravidez: o útero se expande aos poucos para acomodar e proteger o bebê em desenvolvimento.',
      });

  String get phaseLabelMenstrual => _t({'es': 'TU ESTADO ACTUAL · MENSTRUACIÓN', 'en': 'YOUR CURRENT STATE · PERIOD', 'fr': 'TON ÉTAT ACTUEL · RÈGLES', 'de': 'DEIN AKTUELLER STATUS · MENSTRUATION', 'ru': 'ТВОЁ ТЕКУЩЕЕ СОСТОЯНИЕ · МЕНСТРУАЦИЯ', 'ar': 'حالتك الحالية · الدورة الشهرية', 'hi': 'आपकी वर्तमान स्थिति · माहवारी', 'bn': 'আপনার বর্তমান অবস্থা · মাসিক', 'pt': 'SEU ESTADO ATUAL · MENSTRUAÇÃO'});
  String get phaseShortNameMenstrual => _t({'es': 'tu menstruación', 'en': 'your period', 'fr': 'tes règles', 'de': 'deine Menstruation', 'ru': 'твою менструацию', 'ar': 'دورتكِ الشهرية', 'hi': 'आपकी माहवारी', 'bn': 'আপনার মাসিক', 'pt': 'sua menstruação'});
  String get phaseDescriptionMenstrual => _t({
        'es': 'Estás en tu periodo: el endometrio se desprende, lo que causa el sangrado menstrual.',
        'en': "You're on your period: the endometrium sheds, which causes menstrual bleeding.",
        'fr': "Tu es dans tes règles : l'endomètre se détache, ce qui provoque les saignements menstruels.",
        'de': 'Du hast deine Periode: Das Endometrium löst sich ab, was die Menstruationsblutung verursacht.',
        'ru': 'У тебя менструация: эндометрий отслаивается, что вызывает менструальное кровотечение.',
        'ar': 'أنتِ في فترة الدورة الشهرية: يتساقط بطانة الرحم، مما يسبب نزيف الدورة.',
        'hi': 'आप अपनी माहवारी में हैं: एंडोमेट्रियम झड़ जाता है, जिससे मासिक धर्म रक्तस्राव होता है।',
        'bn': 'আপনি এখন মাসিকে আছেন: এন্ডোমেট্রিয়াম খসে পড়ে, যার ফলে মাসিক রক্তপাত হয়।',
        'pt': 'Você está no seu período: o endométrio se desprende, o que causa o sangramento menstrual.',
      });

  String get phaseLabelFolicular => _t({'es': 'TU ESTADO ACTUAL · FASE FOLICULAR', 'en': 'YOUR CURRENT STATE · FOLLICULAR PHASE', 'fr': 'TON ÉTAT ACTUEL · PHASE FOLLICULAIRE', 'de': 'DEIN AKTUELLER STATUS · FOLLIKELPHASE', 'ru': 'ТВОЁ ТЕКУЩЕЕ СОСТОЯНИЕ · ФОЛЛИКУЛЯРНАЯ ФАЗА', 'ar': 'حالتك الحالية · الطور الجريبي', 'hi': 'आपकी वर्तमान स्थिति · फॉलिक्युलर चरण', 'bn': 'আপনার বর্তমান অবস্থা · ফলিকুলার পর্যায়', 'pt': 'SEU ESTADO ATUAL · FASE FOLICULAR'});
  String get phaseShortNameFolicular => _t({'es': 'tu fase folicular', 'en': 'your follicular phase', 'fr': 'ta phase folliculaire', 'de': 'deine Follikelphase', 'ru': 'твою фолликулярную фазу', 'ar': 'طورك الجريبي', 'hi': 'आपका फॉलिक्युलर चरण', 'bn': 'আপনার ফলিকুলার পর্যায়', 'pt': 'sua fase folicular'});
  String get phaseDescriptionFolicular => _t({
        'es': 'Tus ovarios están desarrollando folículos que contienen óvulos, preparándose para la ovulación.',
        'en': 'Your ovaries are developing follicles containing eggs, getting ready for ovulation.',
        'fr': "Tes ovaires développent des follicules contenant des ovules, en préparation de l'ovulation.",
        'de': 'Deine Eierstöcke entwickeln Follikel, die Eizellen enthalten, und bereiten sich auf den Eisprung vor.',
        'ru': 'Твои яичники развивают фолликулы, содержащие яйцеклетки, готовясь к овуляции.',
        'ar': 'تُطوّر مبيضاكِ حويصلات تحتوي على بويضات، استعدادًا للإباضة.',
        'hi': 'आपके अंडाशय अंडे युक्त फॉलिकल्स विकसित कर रहे हैं, जो ओव्यूलेशन की तैयारी कर रहे हैं।',
        'bn': 'আপনার ডিম্বাশয় ডিম্বাণুযুক্ত ফলিকল তৈরি করছে, যা ডিম্বস্ফোটনের জন্য প্রস্তুত হচ্ছে।',
        'pt': 'Seus ovários estão desenvolvendo folículos que contêm óvulos, se preparando para a ovulação.',
      });

  String get phaseLabelOvulacion => _t({'es': 'TU ESTADO ACTUAL · OVULACIÓN', 'en': 'YOUR CURRENT STATE · OVULATION', 'fr': 'TON ÉTAT ACTUEL · OVULATION', 'de': 'DEIN AKTUELLER STATUS · EISPRUNG', 'ru': 'ТВОЁ ТЕКУЩЕЕ СОСТОЯНИЕ · ОВУЛЯЦИЯ', 'ar': 'حالتك الحالية · التبويض', 'hi': 'आपकी वर्तमान स्थिति · ओव्यूलेशन', 'bn': 'আপনার বর্তমান অবস্থা · ডিম্বস্ফোটন', 'pt': 'SEU ESTADO ATUAL · OVULAÇÃO'});
  String get phaseShortNameOvulacion => _t({'es': 'tu ovulación', 'en': 'your ovulation', 'fr': 'ton ovulation', 'de': 'deinen Eisprung', 'ru': 'твою овуляцию', 'ar': 'تبويضكِ', 'hi': 'आपका ओव्यूलेशन', 'bn': 'আপনার ডিম্বস্ফোটন', 'pt': 'sua ovulação'});
  String get phaseDescriptionOvulacion => _t({
        'es': 'Estás en tu fase ovulatoria: uno de tus ovarios libera un óvulo maduro, tu ventana de mayor fertilidad.',
        'en': "You're in your ovulatory phase: one of your ovaries releases a mature egg — your window of highest fertility.",
        'fr': "Tu es dans ta phase ovulatoire : l'un de tes ovaires libère un ovule mature, ta fenêtre de fertilité maximale.",
        'de': 'Du bist in deiner Eisprungphase: Einer deiner Eierstöcke setzt eine reife Eizelle frei — dein Zeitfenster mit der höchsten Fruchtbarkeit.',
        'ru': 'Ты в фазе овуляции: один из твоих яичников высвобождает зрелую яйцеклетку — твоё окно максимальной фертильности.',
        'ar': 'أنتِ في طور التبويض: يُطلق أحد مبيضيكِ بويضة ناضجة — نافذة أعلى خصوبة لديكِ.',
        'hi': 'आप अपने ओव्यूलेशन चरण में हैं: आपके अंडाशयों में से एक परिपक्व अंडा छोड़ता है — यह आपकी सबसे अधिक प्रजनन क्षमता वाली अवधि है।',
        'bn': 'আপনি এখন ডিম্বস্ফোটন পর্যায়ে আছেন: আপনার একটি ডিম্বাশয় থেকে একটি পরিণত ডিম্বাণু নির্গত হয় — এটি আপনার সর্বোচ্চ উর্বরতার সময়।',
        'pt': 'Você está na sua fase ovulatória: um dos seus ovários libera um óvulo maduro, sua janela de maior fertilidade.',
      });

  String get phaseLabelLutea => _t({'es': 'TU ESTADO ACTUAL · FASE LÚTEA', 'en': 'YOUR CURRENT STATE · LUTEAL PHASE', 'fr': 'TON ÉTAT ACTUEL · PHASE LUTÉALE', 'de': 'DEIN AKTUELLER STATUS · GELBKÖRPERPHASE', 'ru': 'ТВОЁ ТЕКУЩЕЕ СОСТОЯНИЕ · ЛЮТЕИНОВАЯ ФАЗА', 'ar': 'حالتك الحالية · الطور الأصفري', 'hi': 'आपकी वर्तमान स्थिति · ल्यूटियल चरण', 'bn': 'আপনার বর্তমান অবস্থা · লুটিয়াল পর্যায়', 'pt': 'SEU ESTADO ATUAL · FASE LÚTEA'});
  String get phaseShortNameLutea => _t({'es': 'tu fase lútea', 'en': 'your luteal phase', 'fr': 'ta phase lutéale', 'de': 'deine Gelbkörperphase', 'ru': 'твою лютеиновую фазу', 'ar': 'طورك الأصفري', 'hi': 'आपका ल्यूटियल चरण', 'bn': 'আপনার লুটিয়াল পর্যায়', 'pt': 'sua fase lútea'});
  String get phaseDescriptionLutea => _t({
        'es': 'El endometrio se engrosa y se prepara por si ocurre un embarazo en los próximos días.',
        'en': 'The endometrium thickens and prepares in case pregnancy occurs in the coming days.',
        'fr': "L'endomètre s'épaissit et se prépare au cas où une grossesse surviendrait dans les jours à venir.",
        'de': 'Das Endometrium verdickt sich und bereitet sich darauf vor, falls in den kommenden Tagen eine Schwangerschaft eintritt.',
        'ru': 'Эндометрий утолщается и готовится на случай наступления беременности в ближайшие дни.',
        'ar': 'يتكاثف بطانة الرحم ويستعد لاحتمال حدوث حمل في الأيام القادمة.',
        'hi': 'एंडोमेट्रियम मोटा होता है और आने वाले दिनों में संभावित गर्भावस्था के लिए तैयारी करता है।',
        'bn': 'আগামী দিনগুলোতে গর্ভধারণ হতে পারে, এই সম্ভাবনার জন্য এন্ডোমেট্রিয়াম পুরু হয় এবং প্রস্তুত হয়।',
        'pt': 'O endométrio se espessa e se prepara caso ocorra uma gravidez nos próximos dias.',
      });

  // ---- Puntos de la ilustración anatómica del útero ----
  String get hotspotTitleOvarios => _t({'es': 'Ovarios', 'en': 'Ovaries', 'fr': 'Ovaires', 'de': 'Eierstöcke', 'ru': 'Яичники', 'ar': 'المبيضان', 'hi': 'अंडाशय', 'bn': 'ডিম্বাশয়', 'pt': 'Ovários'});
  String get hotspotDescriptionOvarios => _t({
        'es': 'Producen los óvulos y las hormonas como el estrógeno y la progesterona. Cada mes, uno de ellos libera un óvulo durante la ovulación.',
        'en': 'They produce eggs and hormones like estrogen and progesterone. Each month, one of them releases an egg during ovulation.',
        'fr': "Ils produisent les ovules et des hormones comme les œstrogènes et la progestérone. Chaque mois, l'un d'eux libère un ovule pendant l'ovulation.",
        'de': 'Sie produzieren Eizellen und Hormone wie Östrogen und Progesteron. Jeden Monat setzt einer von ihnen während des Eisprungs eine Eizelle frei.',
        'ru': 'Они производят яйцеклетки и гормоны, такие как эстроген и прогестерон. Каждый месяц один из них высвобождает яйцеклетку во время овуляции.',
        'ar': 'تنتج البويضات والهرمونات مثل الإستروجين والبروجسترون. كل شهر، يُطلق أحدهما بويضة أثناء التبويض.',
        'hi': 'ये अंडे और एस्ट्रोजेन व प्रोजेस्टेरोन जैसे हार्मोन बनाते हैं। हर महीने, इनमें से एक ओव्यूलेशन के दौरान एक अंडा छोड़ता है।',
        'bn': 'এগুলো ডিম্বাণু এবং ইস্ট্রোজেন ও প্রোজেস্টেরনের মতো হরমোন তৈরি করে। প্রতি মাসে এদের একটি ডিম্বস্ফোটনের সময় একটি ডিম্বাণু ছাড়ে।',
        'pt': 'Eles produzem os óvulos e hormônios como estrogênio e progesterona. Todo mês, um deles libera um óvulo durante a ovulação.',
      });

  String get hotspotTitleTrompas => _t({'es': 'Trompas de Falopio', 'en': 'Fallopian tubes', 'fr': 'Trompes de Fallope', 'de': 'Eileiter', 'ru': 'Маточные трубы', 'ar': 'قناتا فالوب', 'hi': 'फैलोपियन ट्यूब', 'bn': 'ফ্যালোপিয়ান টিউব', 'pt': 'Trompas de Falópio'});
  String get hotspotDescriptionTrompas => _t({
        'es': 'Conectan los ovarios con el útero. El óvulo viaja por aquí y, si hay espermatozoides presentes, es donde puede ocurrir la fecundación.',
        'en': 'They connect the ovaries to the uterus. The egg travels through here, and if sperm are present, this is where fertilization can happen.',
        'fr': "Elles relient les ovaires à l'utérus. L'ovule y voyage et, si des spermatozoïdes sont présents, c'est là que la fécondation peut avoir lieu.",
        'de': 'Sie verbinden die Eierstöcke mit der Gebärmutter. Die Eizelle wandert hier hindurch, und wenn Spermien vorhanden sind, kann hier die Befruchtung stattfinden.',
        'ru': 'Они соединяют яичники с маткой. Яйцеклетка перемещается по ним, и если присутствуют сперматозоиды, именно здесь может произойти оплодотворение.',
        'ar': 'تربط المبيضين بالرحم. تنتقل البويضة عبرهما، وإذا كانت الحيوانات المنوية موجودة، فهنا يمكن أن يحدث الإخصاب.',
        'hi': 'ये अंडाशयों को गर्भाशय से जोड़ती हैं। अंडा यहीं से यात्रा करता है, और यदि शुक्राणु मौजूद हों, तो यहीं निषेचन हो सकता है।',
        'bn': 'এগুলো ডিম্বাশয়কে জরায়ুর সঙ্গে সংযুক্ত করে। ডিম্বাণু এখান দিয়ে যাতায়াত করে, এবং শুক্রাণু উপস্থিত থাকলে এখানেই নিষেক ঘটতে পারে।',
        'pt': 'Elas conectam os ovários ao útero. O óvulo viaja por aqui e, se houver espermatozoides presentes, é aqui que a fecundação pode ocorrer.',
      });

  String get hotspotTitleEndometrio => _t({'es': 'Endometrio', 'en': 'Endometrium', 'fr': 'Endomètre', 'de': 'Endometrium', 'ru': 'Эндометрий', 'ar': 'بطانة الرحم', 'hi': 'एंडोमेट्रियम', 'bn': 'এন্ডোমেট্রিয়াম', 'pt': 'Endométrio'});
  String get hotspotDescriptionEndometrio => _t({
        'es': 'Es la capa interna que recubre el útero. Se engrosa en cada ciclo para prepararse ante un posible embarazo y, si no ocurre, se desprende durante la menstruación.',
        'en': "It's the inner lining of the uterus. It thickens each cycle to prepare for a possible pregnancy, and if that doesn't happen, it sheds during menstruation.",
        'fr': "C'est la couche interne qui tapisse l'utérus. Elle s'épaissit à chaque cycle pour se préparer à une éventuelle grossesse et, si celle-ci ne se produit pas, elle se détache pendant les règles.",
        'de': 'Das ist die innere Schicht, die die Gebärmutter auskleidet. Sie verdickt sich in jedem Zyklus, um sich auf eine mögliche Schwangerschaft vorzubereiten, und löst sich, falls diese nicht eintritt, während der Menstruation ab.',
        'ru': 'Это внутренний слой, выстилающий матку. Он утолщается в каждом цикле, готовясь к возможной беременности, а если она не наступает, отслаивается во время менструации.',
        'ar': 'هي الطبقة الداخلية المبطنة للرحم. تتكاثف في كل دورة استعدادًا لحمل محتمل، وإذا لم يحدث، تتساقط أثناء الدورة الشهرية.',
        'hi': 'यह गर्भाशय की भीतरी परत है। यह हर चक्र में संभावित गर्भावस्था के लिए मोटी होती है, और यदि गर्भावस्था नहीं होती, तो यह माहवारी के दौरान झड़ जाती है।',
        'bn': 'এটি জরায়ুর ভেতরের আস্তরণ। সম্ভাব্য গর্ভধারণের জন্য প্রতি চক্রে এটি পুরু হয়, আর গর্ভধারণ না ঘটলে মাসিকের সময় এটি খসে পড়ে।',
        'pt': 'É a camada interna que reveste o útero. Ela se espessa a cada ciclo para se preparar para uma possível gravidez e, se isso não ocorrer, se desprende durante a menstruação.',
      });

  String get hotspotTitleMiometrio => _t({'es': 'Miometrio', 'en': 'Myometrium', 'fr': 'Myomètre', 'de': 'Myometrium', 'ru': 'Миометрий', 'ar': 'عضل الرحم', 'hi': 'मायोमेट्रियम', 'bn': 'মায়োমেট্রিয়াম', 'pt': 'Miométrio'});
  String get hotspotDescriptionMiometrio => _t({
        'es': 'Es la capa muscular y más gruesa del útero. Sus contracciones son las responsables de los cólicos menstruales y, durante el parto, ayudan a expulsar al bebé.',
        'en': "It's the uterus's thickest, muscular layer. Its contractions cause menstrual cramps and, during labor, help push the baby out.",
        'fr': "C'est la couche musculaire, la plus épaisse de l'utérus. Ses contractions sont responsables des crampes menstruelles et, pendant l'accouchement, aident à expulser le bébé.",
        'de': 'Das ist die muskuläre und dickste Schicht der Gebärmutter. Ihre Kontraktionen sind für die Menstruationskrämpfe verantwortlich und helfen während der Geburt, das Baby herauszupressen.',
        'ru': 'Это мышечный и самый толстый слой матки. Его сокращения вызывают менструальные спазмы, а во время родов помогают вытолкнуть ребёнка.',
        'ar': 'هي الطبقة العضلية والأكثر سُمكًا في الرحم. تسبب انقباضاتها تشنجات الدورة الشهرية، وتساعد أثناء الولادة على دفع الطفل للخارج.',
        'hi': 'यह गर्भाशय की मांसपेशीय और सबसे मोटी परत है। इसके संकुचन मासिक धर्म की ऐंठन के लिए जिम्मेदार होते हैं, और प्रसव के दौरान शिशु को बाहर निकालने में मदद करते हैं।',
        'bn': 'এটি জরায়ুর পেশিবহুল ও সবচেয়ে পুরু স্তর। এর সংকোচন মাসিকের ব্যথার জন্য দায়ী, এবং প্রসবের সময় শিশুকে বের করে আনতে সাহায্য করে।',
        'pt': 'É a camada muscular e mais espessa do útero. Suas contrações são responsáveis pelas cólicas menstruais e, durante o parto, ajudam a expulsar o bebê.',
      });

  String get hotspotTitleCervix => _t({'es': 'Cuello uterino (cérvix)', 'en': 'Cervix', 'fr': "Col de l'utérus (cervix)", 'de': 'Gebärmutterhals (Zervix)', 'ru': 'Шейка матки (цервикс)', 'ar': 'عنق الرحم', 'hi': 'गर्भाशय ग्रीवा (सर्विक्स)', 'bn': 'জরায়ুমুখ (সার্ভিক্স)', 'pt': 'Colo do útero (cérvix)'});
  String get hotspotDescriptionCervix => _t({
        'es': 'Es la parte inferior y más estrecha del útero, que conecta con la vagina. Produce el moco cervical, cuya textura cambia a lo largo del ciclo.',
        'en': "It's the lower, narrowest part of the uterus, connecting to the vagina. It produces cervical mucus, whose texture changes throughout the cycle.",
        'fr': "C'est la partie inférieure et la plus étroite de l'utérus, qui se connecte au vagin. Il produit la glaire cervicale, dont la texture change tout au long du cycle.",
        'de': 'Das ist der untere, engste Teil der Gebärmutter, der mit der Vagina verbunden ist. Er produziert Zervixschleim, dessen Beschaffenheit sich im Laufe des Zyklus verändert.',
        'ru': 'Это нижняя, самая узкая часть матки, соединяющаяся с влагалищем. Она вырабатывает цервикальную слизь, текстура которой меняется на протяжении цикла.',
        'ar': 'هو الجزء السفلي والأضيق من الرحم، ويتصل بالمهبل. ينتج المخاط العنقي الذي يتغير قوامه على مدار الدورة.',
        'hi': 'यह गर्भाशय का निचला और सबसे संकरा हिस्सा है, जो योनि से जुड़ता है। यह सर्वाइकल म्यूकस बनाता है, जिसकी बनावट पूरे चक्र में बदलती रहती है।',
        'bn': 'এটি জরায়ুর নিচের এবং সবচেয়ে সরু অংশ, যা যোনির সঙ্গে যুক্ত। এটি সার্ভিকাল মিউকাস তৈরি করে, যার গঠন পুরো চক্র জুড়ে বদলায়।',
        'pt': 'É a parte inferior e mais estreita do útero, que se conecta à vagina. Produz o muco cervical, cuja textura muda ao longo do ciclo.',
      });


  // ---- Informe de errores / Puntúanos / Apple Watch: funcionalidad real (fase 8) ----
  String get settingsBugReportEmailSubject => _t({
        'es': 'Informe de error - CicloPlus',
        'en': 'Bug report - CicloPlus',
        'fr': 'Signalement de bug - CicloPlus',
        'de': 'Fehlerbericht - CicloPlus',
        'ru': 'Отчёт об ошибке - CicloPlus',
        'ar': 'تقرير خطأ - CicloPlus', 'hi': 'बग रिपोर्ट - CicloPlus', 'bn': 'বাগ রিপোর্ট - CicloPlus', 'pt': 'Relatório de erro - CicloPlus',
      });
  String get settingsBugReportEmailBody => _t({
        'es': 'Describe aquí el problema que encontraste y, si puedes, los pasos para reproducirlo:\n\n\n\nGracias por ayudarnos a mejorar CicloPlus.',
        'en': "Describe the problem you found and, if you can, the steps to reproduce it:\n\n\n\nThanks for helping us improve CicloPlus.",
        'fr': "Décrivez le problème que vous avez rencontré et, si possible, les étapes pour le reproduire :\n\n\n\nMerci de nous aider à améliorer CicloPlus.",
        'de': 'Beschreibe das Problem, das du gefunden hast, und wenn möglich die Schritte, um es zu reproduzieren:\n\n\n\nDanke, dass du uns hilfst, CicloPlus zu verbessern.',
        'ru': 'Опиши проблему, с которой ты столкнулась, и, если можешь, шаги для её воспроизведения:\n\n\n\nСпасибо, что помогаешь нам улучшить CicloPlus.',
        'ar': 'صفي المشكلة التي واجهتِها، وإن أمكن خطوات إعادة حدوثها:\n\n\n\nشكرًا لمساعدتكِ في تحسين CicloPlus.', 'hi': 'आपको मिली समस्या का वर्णन करें और यदि संभव हो तो उसे दोहराने के चरण बताएं:\n\n\n\nCicloPlus को बेहतर बनाने में मदद के लिए धन्यवाद।', 'bn': 'আপনি যে সমস্যাটি পেয়েছেন তা বর্ণনা করুন এবং সম্ভব হলে এটি পুনরায় ঘটানোর পদক্ষেপগুলো লিখুন:\n\n\n\nCicloPlus উন্নত করতে সাহায্য করার জন্য ধন্যবাদ।', 'pt': 'Descreva aqui o problema que encontrou e, se possível, os passos para reproduzi-lo:\n\n\n\nObrigado por nos ajudar a melhorar o CicloPlus.',
      });
  String get settingsBugReportError => _t({
        'es': 'No pudimos abrir tu app de correo. Escríbenos a soportelambert@gmail.com',
        'en': "We couldn't open your email app. Please write to us at soportelambert@gmail.com",
        'fr': "Nous n'avons pas pu ouvrir votre application de messagerie. Écrivez-nous à soportelambert@gmail.com",
        'de': 'Wir konnten deine E-Mail-App nicht öffnen. Schreib uns an soportelambert@gmail.com',
        'ru': 'Не удалось открыть почтовое приложение. Напиши нам на soportelambert@gmail.com',
        'ar': 'تعذّر فتح تطبيق البريد. راسلينا على soportelambert@gmail.com', 'hi': 'हम आपका ईमेल ऐप नहीं खोल सके। कृपया हमें soportelambert@gmail.com पर लिखें', 'bn': 'আমরা আপনার ইমেল অ্যাপ খুলতে পারিনি। আমাদের soportelambert@gmail.com এ লিখুন', 'pt': 'Não conseguimos abrir seu app de e-mail. Escreva para soportelambert@gmail.com',
      });
  String get settingsRateUsError => _t({
        'es': 'No pudimos abrir la Play Store. Inténtalo de nuevo más tarde.',
        'en': "We couldn't open the Play Store. Please try again later.",
        'fr': "Nous n'avons pas pu ouvrir le Play Store. Veuillez réessayer plus tard.",
        'de': 'Wir konnten den Play Store nicht öffnen. Bitte versuche es später erneut.',
        'ru': 'Не удалось открыть Play Store. Попробуй ещё раз позже.',
        'ar': 'تعذّر فتح متجر Play. حاولي مرة أخرى لاحقًا.', 'hi': 'हम Play Store नहीं खोल सके। कृपया बाद में फिर से प्रयास करें।', 'bn': 'আমরা Play Store খুলতে পারিনি। পরে আবার চেষ্টা করুন।', 'pt': 'Não conseguimos abrir a Play Store. Tente novamente mais tarde.',
      });
  String get appleWatchScreenExplanation => _t({
        'es': 'CicloPlus no tiene todavía una app propia para Apple Watch, pero puedes ver tu ciclo directamente desde tu reloj activando la sincronización con Apple Salud (o Health Connect en Android): tu flujo, peso, sueño y temperatura se comparten con la app Salud, y desde ahí también quedan disponibles en tu Apple Watch.',
        'en': "CicloPlus doesn't have its own Apple Watch app yet, but you can see your cycle right from your watch by turning on sync with Apple Health (or Health Connect on Android): your flow, weight, sleep and temperature are shared with the Health app, and from there they're also available on your Apple Watch.",
        'fr': "CicloPlus n'a pas encore d'application propre pour Apple Watch, mais vous pouvez voir votre cycle directement depuis votre montre en activant la synchronisation avec Apple Santé (ou Health Connect sur Android) : votre flux, poids, sommeil et température sont partagés avec l'application Santé, et deviennent ainsi disponibles sur votre Apple Watch.",
        'de': 'CicloPlus hat noch keine eigene Apple-Watch-App, aber du kannst deinen Zyklus direkt auf deiner Uhr sehen, wenn du die Synchronisierung mit Apple Health (oder Health Connect auf Android) aktivierst: dein Zyklusfluss, Gewicht, Schlaf und Temperatur werden mit der Health-App geteilt und stehen von dort auch auf deiner Apple Watch bereit.',
        'ru': 'У CicloPlus пока нет собственного приложения для Apple Watch, но ты можешь видеть свой цикл прямо на часах, включив синхронизацию с Apple Health (или Health Connect на Android): данные о выделениях, весе, сне и температуре передаются в приложение Health, а оттуда становятся доступны и на Apple Watch.',
        'ar': 'لا يمتلك CicloPlus حتى الآن تطبيقًا خاصًا لساعة Apple Watch، لكن يمكنكِ رؤية دورتكِ مباشرة من ساعتكِ بتفعيل المزامنة مع Apple Health (أو Health Connect على أندرويد): تتم مشاركة تدفق الدورة والوزن والنوم ودرجة الحرارة مع تطبيق Health، ومن هناك تصبح متاحة أيضًا على ساعة Apple Watch.', 'hi': 'CicloPlus के पास अभी अपना Apple Watch ऐप नहीं है, लेकिन Apple Health (या Android पर Health Connect) के साथ सिंक चालू करके आप अपने चक्र को सीधे अपनी वॉच से देख सकते हैं: आपका फ्लो, वज़न, नींद और तापमान Health ऐप के साथ साझा किया जाता है, और वहां से यह आपकी Apple Watch पर भी उपलब्ध हो जाता है।', 'bn': 'CicloPlus-এর এখনও নিজস্ব Apple Watch অ্যাপ নেই, তবে Apple Health (বা Android-এ Health Connect) এর সাথে সিঙ্ক চালু করে আপনি সরাসরি আপনার ঘড়ি থেকে আপনার চক্র দেখতে পারেন: আপনার ফ্লো, ওজন, ঘুম এবং তাপমাত্রা Health অ্যাপের সাথে শেয়ার হয়, এবং সেখান থেকে এটি আপনার Apple Watch-এও উপলব্ধ হয়।', 'pt': 'O CicloPlus ainda não tem um app próprio para Apple Watch, mas você pode ver seu ciclo direto do seu relógio ativando a sincronização com o Apple Saúde (ou Health Connect no Android): seu fluxo, peso, sono e temperatura são compartilhados com o app Saúde, e a partir daí também ficam disponíveis no seu Apple Watch.',
      });
  String get appleWatchScreenEnabledHint => _t({
        'es': 'La sincronización ya está activada. Abre la app Salud (o Health Connect) en tu teléfono para comprobar que tus datos de ciclo aparecen ahí, y desde tu Apple Watch podrás consultarlos igual que cualquier otro dato de salud.',
        'en': "Sync is already turned on. Open the Health app (or Health Connect) on your phone to check that your cycle data shows up there, and from your Apple Watch you'll be able to check it just like any other health data.",
        'fr': "La synchronisation est déjà activée. Ouvrez l'application Santé (ou Health Connect) sur votre téléphone pour vérifier que vos données de cycle y apparaissent, et depuis votre Apple Watch vous pourrez les consulter comme n'importe quelle autre donnée de santé.",
        'de': 'Die Synchronisierung ist bereits aktiviert. Öffne die Health-App (oder Health Connect) auf deinem Handy, um zu prüfen, ob deine Zyklusdaten dort erscheinen. Auf deiner Apple Watch kannst du sie dann wie jede andere Gesundheitsangabe einsehen.',
        'ru': 'Синхронизация уже включена. Открой приложение Health (или Health Connect) на телефоне, чтобы проверить, что данные о цикле там появились — на Apple Watch их можно посмотреть так же, как любые другие данные о здоровье.',
        'ar': 'المزامنة مفعّلة بالفعل. افتحي تطبيق Health (أو Health Connect) على هاتفكِ للتأكد من ظهور بيانات دورتكِ فيه، ومن ساعة Apple Watch يمكنكِ مراجعتها كأي بيانات صحية أخرى.', 'hi': 'सिंक पहले से चालू है। अपने फोन पर Health ऐप (या Health Connect) खोलकर देखें कि आपका चक्र डेटा वहां दिख रहा है, और अपनी Apple Watch से आप इसे किसी भी अन्य स्वास्थ्य डेटा की तरह देख सकेंगे।', 'bn': 'সিঙ্ক ইতিমধ্যে চালু আছে। আপনার ফোনে Health অ্যাপ (বা Health Connect) খুলে দেখুন আপনার চক্রের ডেটা সেখানে দেখা যাচ্ছে কিনা, এবং আপনার Apple Watch থেকে আপনি এটি অন্য কোনো স্বাস্থ্য ডেটার মতোই দেখতে পারবেন।', 'pt': 'A sincronização já está ativada. Abra o app Saúde (ou Health Connect) no seu celular para verificar se os dados do seu ciclo aparecem lá, e no seu Apple Watch você poderá consultá-los como qualquer outro dado de saúde.',
      });
  String get appleWatchScreenDisabledHint => _t({
        'es': 'Actívala aquí abajo para empezar a verla desde tu Apple Watch.',
        'en': 'Turn it on below to start seeing it from your Apple Watch.',
        'fr': "Activez-la ci-dessous pour commencer à la voir depuis votre Apple Watch.",
        'de': 'Aktiviere sie unten, um sie ab jetzt auf deiner Apple Watch zu sehen.',
        'ru': 'Включи её ниже, чтобы начать видеть данные на Apple Watch.',
        'ar': 'فعّليها أدناه لتبدئي برؤيتها من ساعة Apple Watch.', 'hi': 'इसे नीचे चालू करें और अपनी Apple Watch से इसे देखना शुरू करें।', 'bn': 'আপনার Apple Watch থেকে এটি দেখা শুরু করতে নিচে এটি চালু করুন।', 'pt': 'Ative-a abaixo para começar a vê-la no seu Apple Watch.',
      });


  // ---- Widget real de pantalla de inicio (fase 8) ----
  String homeWidgetCycleDay(int day) => _t({
        'es': 'Día $day de tu ciclo',
        'en': 'Day $day of your cycle',
        'fr': 'Jour $day de votre cycle',
        'de': 'Tag $day deines Zyklus',
        'ru': 'День $day твоего цикла',
        'ar': 'اليوم $day من دورتكِ', 'hi': 'आपके चक्र का दिन $day', 'bn': 'আপনার চক্রের দিন $day', 'pt': 'Dia $day do seu ciclo',
      });
  String get homeWidgetPeriodToday => _t({
        'es': 'Tu periodo llega hoy',
        'en': 'Your period arrives today',
        'fr': 'Vos règles arrivent aujourd\'hui',
        'de': 'Deine Periode beginnt heute',
        'ru': 'Твой период начинается сегодня',
        'ar': 'دورتكِ تبدأ اليوم', 'hi': 'आपका पीरियड आज आ रहा है', 'bn': 'আপনার পিরিয়ড আজ আসছে', 'pt': 'Seu período chega hoje',
      });
  String homeWidgetDaysUntilPeriod(int n) {
    if (n == 0) return homeWidgetPeriodToday;
    if (n == 1) {
      return _t({
        'es': 'Tu periodo llega en 1 día',
        'en': 'Your period arrives in 1 day',
        'fr': 'Vos règles arrivent dans 1 jour',
        'de': 'Deine Periode beginnt in 1 Tag',
        'ru': 'Твой период начнётся через 1 день',
        'ar': 'دورتكِ تبدأ بعد يوم واحد', 'hi': 'आपका पीरियड 1 दिन में आ रहा है', 'bn': 'আপনার পিরিয়ড ১ দিনে আসছে', 'pt': 'Seu período chega em 1 dia',
      });
    }
    return _t({
      'es': 'Tu periodo llega en $n días',
      'en': 'Your period arrives in $n days',
      'fr': 'Vos règles arrivent dans $n jours',
      'de': 'Deine Periode beginnt in $n Tagen',
      'ru': 'Твой период начнётся через $n дн.',
      'ar': 'دورتكِ تبدأ بعد $n أيام', 'hi': 'आपका पीरियड $n दिनों में आ रहा है', 'bn': 'আপনার পিরিয়ড $n দিনে আসছে', 'pt': 'Seu período chega em $n dias',
    });
  }
  String get homeWidgetNoDataLine => _t({
        'es': 'Registra tu periodo en CicloPlus para ver tu predicción aquí',
        'en': 'Log your period in CicloPlus to see your prediction here',
        'fr': 'Enregistrez vos règles dans CicloPlus pour voir votre prédiction ici',
        'de': 'Trage deine Periode in CicloPlus ein, um deine Vorhersage hier zu sehen',
        'ru': 'Отметь свой период в CicloPlus, чтобы увидеть прогноз здесь',
        'ar': 'سجّلي دورتكِ في CicloPlus لرؤية توقعكِ هنا', 'hi': 'यहां अपनी भविष्यवाणी देखने के लिए CicloPlus में अपना पीरियड दर्ज करें', 'bn': 'এখানে আপনার পূর্বাভাস দেখতে CicloPlus-এ আপনার পিরিয়ড লগ করুন', 'pt': 'Registre seu período no CicloPlus para ver sua previsão aqui',
      });
  // ---- Pantalla real "Widget" (Configuración > Widget) ----
  String get widgetScreenRealExplanation => _t({
        'es': 'CicloPlus ya tiene un widget real para tu pantalla de inicio, con tu día de ciclo y la cuenta atrás a tu próximo periodo. Para añadirlo: mantén pulsada una zona vacía de tu pantalla de inicio, toca "Widgets", busca CicloPlus y arrástralo a tu pantalla.',
        'en': 'CicloPlus already has a real home screen widget with your cycle day and the countdown to your next period. To add it: long-press an empty area of your home screen, tap "Widgets", find CicloPlus and drag it onto your screen.',
        'fr': "CicloPlus dispose déjà d'un vrai widget pour votre écran d'accueil, avec votre jour de cycle et le compte à rebours jusqu'à vos prochaines règles. Pour l'ajouter : maintenez appuyé sur une zone vide de votre écran d'accueil, appuyez sur « Widgets », trouvez CicloPlus et faites-le glisser sur votre écran.",
        'de': 'CicloPlus hat bereits ein echtes Homescreen-Widget mit deinem Zyklustag und dem Countdown bis zu deiner nächsten Periode. Zum Hinzufügen: Halte einen leeren Bereich deines Homescreens gedrückt, tippe auf „Widgets", suche CicloPlus und ziehe es auf deinen Bildschirm.',
        'ru': 'У CicloPlus уже есть настоящий виджет для домашнего экрана с днём твоего цикла и обратным отсчётом до следующего периода. Чтобы добавить его: удерживай пустую область домашнего экрана, нажми «Виджеты», найди CicloPlus и перетащи его на экран.',
        'ar': 'يمتلك CicloPlus بالفعل ودجة حقيقية لشاشتكِ الرئيسية تعرض يوم دورتكِ والعد التنازلي لدورتكِ القادمة. لإضافتها: اضغطي مطولًا على منطقة خالية من شاشتكِ الرئيسية، ثم اضغطي على "الودجات"، وابحثي عن CicloPlus واسحبيها إلى شاشتكِ.', 'hi': 'CicloPlus में पहले से ही आपकी होम स्क्रीन के लिए एक असली विजेट है, जिसमें आपके चक्र का दिन और आपके अगले पीरियड तक की उलटी गिनती दिखती है। इसे जोड़ने के लिए: अपनी होम स्क्रीन के किसी खाली हिस्से को दबाकर रखें, "विजेट्स" पर टैप करें, CicloPlus ढूंढें और उसे अपनी स्क्रीन पर खींचें।', 'bn': 'CicloPlus-এ ইতিমধ্যে আপনার হোম স্ক্রিনের জন্য একটি বাস্তব উইজেট আছে, যেখানে আপনার চক্রের দিন এবং আপনার পরবর্তী পিরিয়ডের কাউন্টডাউন দেখা যায়। এটি যুক্ত করতে: আপনার হোম স্ক্রিনের একটি খালি জায়গা চেপে ধরুন, "উইজেট" ট্যাপ করুন, CicloPlus খুঁজুন এবং এটি আপনার স্ক্রিনে টেনে আনুন।', 'pt': 'O CicloPlus já tem um widget real para sua tela inicial, com seu dia do ciclo e a contagem regressiva para seu próximo período. Para adicioná-lo: mantenha pressionada uma área vazia da sua tela inicial, toque em "Widgets", procure CicloPlus e arraste-o para sua tela.',
      });
  String get widgetScreenPreviewLabel => _t({
        'es': 'Así se ve ahora mismo:',
        'en': "Here's what it looks like right now:",
        'fr': "Voici à quoi il ressemble en ce moment :",
        'de': 'So sieht es gerade aus:',
        'ru': 'Вот как это выглядит сейчас:',
        'ar': 'هكذا يبدو الآن:', 'hi': 'अभी यह ऐसा दिखता है:', 'bn': 'এখন এটি এমন দেখাচ্ছে:', 'pt': 'É assim que ele está agora:',
      });

}
