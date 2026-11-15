import '../services/locale_controller.dart';

/// Textos nuevos del rediseño "CicloPlus 2.0" (pestaña Hoy con anillo del
/// ciclo, resumen del día, ánimo en un toque, agua/sueño). Viven aparte de
/// `AppStrings` para no tocar ese archivo gigante; mismos 9 idiomas.
class RedesignStrings {
  final String code;
  const RedesignStrings._(this.code);

  static RedesignStrings get current => RedesignStrings._(LocaleController.instance.languageCode);

  String _t(Map<String, String> table) => table[code] ?? table['es']!;

  String greeting(int hour, String? name) {
    final n = (name == null || name.trim().isEmpty) ? '' : ', ${name.trim()}';
    if (hour >= 5 && hour < 13) {
      return _t({
        'es': '¡Buenos días$n!',
        'en': 'Good morning$n!',
        'fr': 'Bonjour$n !',
        'de': 'Guten Morgen$n!',
        'ru': 'Доброе утро$n!',
        'ar': 'صباح الخير$n!',
        'hi': 'सुप्रभात$n!',
        'bn': 'সুপ্রভাত$n!',
        'pt': 'Bom dia$n!',
      });
    }
    if (hour >= 13 && hour < 20) {
      return _t({
        'es': '¡Buenas tardes$n!',
        'en': 'Good afternoon$n!',
        'fr': 'Bon après-midi$n !',
        'de': 'Guten Tag$n!',
        'ru': 'Добрый день$n!',
        'ar': 'مساء الخير$n!',
        'hi': 'शुभ दोपहर$n!',
        'bn': 'শুভ অপরাহ্ন$n!',
        'pt': 'Boa tarde$n!',
      });
    }
    return _t({
      'es': '¡Buenas noches$n!',
      'en': 'Good evening$n!',
      'fr': 'Bonsoir$n !',
      'de': 'Guten Abend$n!',
      'ru': 'Добрый вечер$n!',
      'ar': 'مساء الخير$n!',
      'hi': 'शुभ संध्या$n!',
      'bn': 'শুভ সন্ধ্যা$n!',
      'pt': 'Boa noite$n!',
    });
  }

  String get greetingSubtitle => _t({
        'es': 'Cuida de ti hoy, tu bienestar importa.',
        'en': 'Take care of yourself today, your wellbeing matters.',
        'fr': 'Prends soin de toi aujourd’hui, ton bien-être compte.',
        'de': 'Pass heute gut auf dich auf, dein Wohlbefinden zählt.',
        'ru': 'Позаботься о себе сегодня, твоё самочувствие важно.',
        'ar': 'اعتني بنفسك اليوم، راحتك مهمة.',
        'hi': 'आज अपना ख्याल रखें, आपकी सेहत मायने रखती है।',
        'bn': 'আজ নিজের যত্ন নিন, আপনার সুস্থতা গুরুত্বপূর্ণ।',
        'pt': 'Cuide de você hoje, seu bem-estar importa.',
      });

  String get cycleDay => _t({
        'es': 'Día del ciclo',
        'en': 'Cycle day',
        'fr': 'Jour du cycle',
        'de': 'Zyklustag',
        'ru': 'День цикла',
        'ar': 'يوم الدورة',
        'hi': 'चक्र का दिन',
        'bn': 'চক্রের দিন',
        'pt': 'Dia do ciclo',
      });

  String dayN(int n) => _t({
        'es': 'Día $n',
        'en': 'Day $n',
        'fr': 'Jour $n',
        'de': 'Tag $n',
        'ru': 'День $n',
        'ar': 'اليوم $n',
        'hi': 'दिन $n',
        'bn': 'দিন $n',
        'pt': 'Dia $n',
      });

  String ofNDays(int n) => _t({
        'es': 'de $n días',
        'en': 'of $n days',
        'fr': 'sur $n jours',
        'de': 'von $n Tagen',
        'ru': 'из $n дн.',
        'ar': 'من $n يومًا',
        'hi': '$n दिनों में से',
        'bn': '$n দিনের মধ্যে',
        'pt': 'de $n dias',
      });

  String get fertileEstimated => _t({
        'es': 'Fase fértil estimada',
        'en': 'Estimated fertile window',
        'fr': 'Période fertile estimée',
        'de': 'Geschätzte fruchtbare Phase',
        'ru': 'Предполагаемые фертильные дни',
        'ar': 'فترة الخصوبة المقدّرة',
        'hi': 'अनुमानित उपजाऊ अवधि',
        'bn': 'আনুমানিক উর্বর সময়',
        'pt': 'Fase fértil estimada',
      });

  String periodInDays(int n) {
    if (n <= 0) {
      return _t({
        'es': 'Periodo previsto hoy',
        'en': 'Period expected today',
        'fr': 'Règles prévues aujourd’hui',
        'de': 'Periode heute erwartet',
        'ru': 'Менструация ожидается сегодня',
        'ar': 'الدورة متوقعة اليوم',
        'hi': 'पीरियड आज अपेक्षित',
        'bn': 'পিরিয়ড আজ প্রত্যাশিত',
        'pt': 'Período previsto hoje',
      });
    }
    return _t({
      'es': n == 1 ? 'Periodo en 1 día' : 'Periodo en $n días',
      'en': n == 1 ? 'Period in 1 day' : 'Period in $n days',
      'fr': n == 1 ? 'Règles dans 1 jour' : 'Règles dans $n jours',
      'de': n == 1 ? 'Periode in 1 Tag' : 'Periode in $n Tagen',
      'ru': 'Менструация через $n дн.',
      'ar': 'الدورة بعد $n يوم',
      'hi': 'पीरियड $n दिन में',
      'bn': 'পিরিয়ড $n দিনে',
      'pt': n == 1 ? 'Período em 1 dia' : 'Período em $n dias',
    });
  }

  String ovulationInDays(int n) => _t({
        'es': n <= 0 ? 'Ovulación aprox. hoy' : 'Ovulación aprox. en $n días',
        'en': n <= 0 ? 'Ovulation approx. today' : 'Ovulation approx. in $n days',
        'fr': n <= 0 ? 'Ovulation env. aujourd’hui' : 'Ovulation env. dans $n jours',
        'de': n <= 0 ? 'Eisprung ca. heute' : 'Eisprung ca. in $n Tagen',
        'ru': n <= 0 ? 'Овуляция примерно сегодня' : 'Овуляция примерно через $n дн.',
        'ar': n <= 0 ? 'الإباضة تقريبًا اليوم' : 'الإباضة تقريبًا بعد $n يوم',
        'hi': n <= 0 ? 'ओव्यूलेशन लगभग आज' : 'ओव्यूलेशन लगभग $n दिन में',
        'bn': n <= 0 ? 'ডিম্বস্ফোটন প্রায় আজ' : 'ডিম্বস্ফোটন প্রায় $n দিনে',
        'pt': n <= 0 ? 'Ovulação aprox. hoje' : 'Ovulação aprox. em $n dias',
      });

  String get noDataTitle => _t({
        'es': 'Empieza tu ciclo',
        'en': 'Start your cycle',
        'fr': 'Commence ton cycle',
        'de': 'Starte deinen Zyklus',
        'ru': 'Начни свой цикл',
        'ar': 'ابدئي دورتك',
        'hi': 'अपना चक्र शुरू करें',
        'bn': 'আপনার চক্র শুরু করুন',
        'pt': 'Comece seu ciclo',
      });

  String get noDataBody => _t({
        'es': 'Registra el primer día de tu periodo y CicloPlus calculará tu ciclo.',
        'en': 'Log the first day of your period and CicloPlus will calculate your cycle.',
        'fr': 'Note le premier jour de tes règles et CicloPlus calculera ton cycle.',
        'de': 'Trage den ersten Tag deiner Periode ein und CicloPlus berechnet deinen Zyklus.',
        'ru': 'Отметь первый день менструации, и CicloPlus рассчитает твой цикл.',
        'ar': 'سجّلي أول يوم من دورتك وسيحسب CicloPlus دورتك.',
        'hi': 'अपने पीरियड का पहला दिन दर्ज करें, CicloPlus आपका चक्र गिनेगा।',
        'bn': 'পিরিয়ডের প্রথম দিন লিখুন, CicloPlus আপনার চক্র হিসাব করবে।',
        'pt': 'Registre o primeiro dia do seu período e o CicloPlus calculará seu ciclo.',
      });

  String get summaryTitle => _t({
        'es': 'Mi resumen de hoy',
        'en': 'My summary today',
        'fr': 'Mon résumé du jour',
        'de': 'Meine Zusammenfassung heute',
        'ru': 'Мой итог дня',
        'ar': 'ملخصي اليوم',
        'hi': 'आज का मेरा सारांश',
        'bn': 'আজকের সারাংশ',
        'pt': 'Meu resumo de hoje',
      });

  String summaryFor(String? phaseKey) {
    switch (phaseKey) {
      case 'menstrual':
        return _t({
          'es': 'Estás en tu periodo. Descansa, hidrátate y date algo de calor si tienes molestias.',
          'en': 'You’re on your period. Rest, stay hydrated and use some warmth if you have cramps.',
          'fr': 'Tu as tes règles. Repose-toi, hydrate-toi et un peu de chaleur aide en cas de douleurs.',
          'de': 'Du hast deine Periode. Ruh dich aus, trink genug und Wärme hilft bei Krämpfen.',
          'ru': 'У тебя менструация. Отдыхай, пей больше воды, тепло помогает при спазмах.',
          'ar': 'أنتِ في فترة الدورة. استريحي واشربي الماء، والدفء يساعد عند التقلصات.',
          'hi': 'आपका पीरियड चल रहा है। आराम करें, पानी पिएं और दर्द हो तो गर्माहट लें।',
          'bn': 'আপনার পিরিয়ড চলছে। বিশ্রাম নিন, পানি পান করুন, ব্যথায় উষ্ণতা সাহায্য করে।',
          'pt': 'Você está no período. Descanse, hidrate-se e use calor se tiver cólicas.',
        });
      case 'folicular':
        return _t({
          'es': 'Tu energía suele ir en aumento estos días. Buen momento para nuevos planes y algo de ejercicio.',
          'en': 'Your energy usually rises these days. A good time for new plans and some exercise.',
          'fr': 'Ton énergie augmente souvent ces jours-ci. Bon moment pour de nouveaux projets et du sport.',
          'de': 'Deine Energie steigt oft in diesen Tagen. Gute Zeit für neue Pläne und Bewegung.',
          'ru': 'В эти дни энергия обычно растёт. Хорошее время для новых планов и спорта.',
          'ar': 'عادةً ما ترتفع طاقتك في هذه الأيام. وقت جيد لخطط جديدة وبعض الرياضة.',
          'hi': 'इन दिनों आपकी ऊर्जा अक्सर बढ़ती है। नई योजनाओं और व्यायाम का अच्छा समय।',
          'bn': 'এই দিনগুলোতে সাধারণত শক্তি বাড়ে। নতুন পরিকল্পনা ও ব্যায়ামের ভালো সময়।',
          'pt': 'Sua energia costuma aumentar nestes dias. Bom momento para novos planos e exercícios.',
        });
      case 'ovulacion':
        return _t({
          'es': 'Tu energía y ánimo suelen estar más altos en esta fase. Ideal para actividad física y vida social.',
          'en': 'Energy and mood are often higher in this phase. Great for physical activity and socialising.',
          'fr': 'Énergie et humeur sont souvent au plus haut. Idéal pour le sport et les sorties.',
          'de': 'Energie und Stimmung sind oft am höchsten. Ideal für Sport und Treffen mit Freunden.',
          'ru': 'В эту фазу энергия и настроение часто на пике. Отлично для спорта и общения.',
          'ar': 'غالبًا ما تكون الطاقة والمزاج أعلى في هذه المرحلة. مثالية للنشاط والحياة الاجتماعية.',
          'hi': 'इस चरण में ऊर्जा और मूड अक्सर ऊंचे रहते हैं। व्यायाम और मेलजोल के लिए बढ़िया।',
          'bn': 'এই পর্যায়ে শক্তি ও মেজাজ প্রায়ই বেশি থাকে। ব্যায়াম ও সামাজিকতার জন্য দারুণ।',
          'pt': 'Energia e humor costumam estar mais altos nesta fase. Ótimo para atividade física e vida social.',
        });
      case 'lutea':
        return _t({
          'es': 'Puede que notes más cansancio o antojos. Escucha a tu cuerpo y duerme bien.',
          'en': 'You may notice more tiredness or cravings. Listen to your body and sleep well.',
          'fr': 'Tu peux ressentir plus de fatigue ou d’envies. Écoute ton corps et dors bien.',
          'de': 'Vielleicht bist du müder oder hast Heißhunger. Hör auf deinen Körper und schlaf gut.',
          'ru': 'Возможны усталость или тяга к еде. Прислушивайся к телу и высыпайся.',
          'ar': 'قد تلاحظين تعبًا أو رغبة في الأكل. استمعي لجسمك ونامي جيدًا.',
          'hi': 'थकान या क्रेविंग ज़्यादा हो सकती है। अपने शरीर की सुनें और अच्छी नींद लें।',
          'bn': 'ক্লান্তি বা খাবারের ইচ্ছা বাড়তে পারে। শরীরের কথা শুনুন, ভালো ঘুমান।',
          'pt': 'Você pode sentir mais cansaço ou desejos. Escute seu corpo e durma bem.',
        });
    }
    return _t({
      'es': 'Registra cómo te sientes cada día y descubre los patrones de tu ciclo.',
      'en': 'Log how you feel every day and discover your cycle patterns.',
      'fr': 'Note ton ressenti chaque jour et découvre les tendances de ton cycle.',
      'de': 'Notiere täglich, wie du dich fühlst, und entdecke deine Zyklusmuster.',
      'ru': 'Отмечай самочувствие каждый день и узнай закономерности цикла.',
      'ar': 'سجّلي شعورك كل يوم واكتشفي أنماط دورتك.',
      'hi': 'हर दिन अपनी भावनाएं दर्ज करें और अपने चक्र के पैटर्न जानें।',
      'bn': 'প্রতিদিন কেমন লাগছে লিখুন এবং চক্রের ধরন জানুন।',
      'pt': 'Registre como se sente todos os dias e descubra os padrões do seu ciclo.',
    });
  }

  String get water => _t({
        'es': 'Agua',
        'en': 'Water',
        'fr': 'Eau',
        'de': 'Wasser',
        'ru': 'Вода',
        'ar': 'الماء',
        'hi': 'पानी',
        'bn': 'পানি',
        'pt': 'Água',
      });

  String glasses(int n) => _t({
        'es': '$n/8 vasos',
        'en': '$n/8 glasses',
        'fr': '$n/8 verres',
        'de': '$n/8 Gläser',
        'ru': '$n/8 стаканов',
        'ar': '$n/8 أكواب',
        'hi': '$n/8 गिलास',
        'bn': '$n/8 গ্লাস',
        'pt': '$n/8 copos',
      });

  String get sleep => _t({
        'es': 'Sueño',
        'en': 'Sleep',
        'fr': 'Sommeil',
        'de': 'Schlaf',
        'ru': 'Сон',
        'ar': 'النوم',
        'hi': 'नींद',
        'bn': 'ঘুম',
        'pt': 'Sono',
      });

  String get tapToLog => _t({
        'es': 'Toca para anotar',
        'en': 'Tap to log',
        'fr': 'Touche pour noter',
        'de': 'Tippen zum Eintragen',
        'ru': 'Нажми, чтобы отметить',
        'ar': 'اضغطي للتسجيل',
        'hi': 'दर्ज करने के लिए टैप करें',
        'bn': 'লিখতে ট্যাপ করুন',
        'pt': 'Toque para registrar',
      });

  String get logMyDay => _t({
        'es': 'Registrar mi día',
        'en': 'Log my day',
        'fr': 'Noter ma journée',
        'de': 'Meinen Tag eintragen',
        'ru': 'Записать мой день',
        'ar': 'تسجيل يومي',
        'hi': 'मेरा दिन दर्ज करें',
        'bn': 'আমার দিন লিখুন',
        'pt': 'Registrar meu dia',
      });

  String get estimatedNote => _t({
        'es': 'Estimaciones orientativas, no sirven como método anticonceptivo.',
        'en': 'Estimates for guidance only, not a contraceptive method.',
        'fr': 'Estimations indicatives, pas une méthode contraceptive.',
        'de': 'Nur Schätzungen, keine Verhütungsmethode.',
        'ru': 'Ориентировочные оценки, не метод контрацепции.',
        'ar': 'تقديرات إرشادية فقط وليست وسيلة لمنع الحمل.',
        'hi': 'केवल अनुमान, गर्भनिरोधक तरीका नहीं।',
        'bn': 'শুধু আনুমানিক, গর্ভনিরোধক পদ্ধতি নয়।',
        'pt': 'Estimativas apenas orientativas, não servem como método contraceptivo.',
      });

  // ---------- Yo / Calendario / Registrar (rediseño 2.0) ----------
  String get myCycleNumbers => _t({
        'es': 'Mi ciclo en números',
        'en': 'My cycle in numbers',
        'fr': 'Mon cycle en chiffres',
        'de': 'Mein Zyklus in Zahlen',
        'ru': 'Мой цикл в цифрах',
        'ar': 'دورتي بالأرقام',
        'hi': 'मेरा चक्र आंकड़ों में',
        'bn': 'সংখ্যায় আমার চক্র',
        'pt': 'Meu ciclo em números',
      });

  String daysN(int n) => _t({
        'es': '$n días',
        'en': '$n days',
        'fr': '$n jours',
        'de': '$n Tage',
        'ru': '$n дн.',
        'ar': '$n أيام',
        'hi': '$n दिन',
        'bn': '$n দিন',
        'pt': '$n dias',
      });

  String get avgCycle => _t({
        'es': 'Ciclo medio',
        'en': 'Average cycle',
        'fr': 'Cycle moyen',
        'de': 'Ø Zyklus',
        'ru': 'Средний цикл',
        'ar': 'متوسط الدورة',
        'hi': 'औसत चक्र',
        'bn': 'গড় চক্র',
        'pt': 'Ciclo médio',
      });

  String get avgPeriod => _t({
        'es': 'Periodo medio',
        'en': 'Average period',
        'fr': 'Règles moyennes',
        'de': 'Ø Periode',
        'ru': 'Средние месячные',
        'ar': 'متوسط الحيض',
        'hi': 'औसत पीरियड',
        'bn': 'গড় পিরিয়ড',
        'pt': 'Período médio',
      });

  String get regular => _t({
        'es': 'Regular',
        'en': 'Regular',
        'fr': 'Régulier',
        'de': 'Regelmäßig',
        'ru': 'Регулярный',
        'ar': 'منتظمة',
        'hi': 'नियमित',
        'bn': 'নিয়মিত',
        'pt': 'Regular',
      });

  String get irregular => _t({
        'es': 'Irregular',
        'en': 'Irregular',
        'fr': 'Irrégulier',
        'de': 'Unregelmäßig',
        'ru': 'Нерегулярный',
        'ar': 'غير منتظمة',
        'hi': 'अनियमित',
        'bn': 'অনিয়মিত',
        'pt': 'Irregular',
      });

  String get stableCycles => _t({
        'es': 'Ciclos estables',
        'en': 'Stable cycles',
        'fr': 'Cycles stables',
        'de': 'Stabile Zyklen',
        'ru': 'Стабильные циклы',
        'ar': 'دورات مستقرة',
        'hi': 'स्थिर चक्र',
        'bn': 'স্থির চক্র',
        'pt': 'Ciclos estáveis',
      });

  String get variableCycles => _t({
        'es': 'Ciclos variables',
        'en': 'Variable cycles',
        'fr': 'Cycles variables',
        'de': 'Wechselnde Zyklen',
        'ru': 'Переменные циклы',
        'ar': 'دورات متغيرة',
        'hi': 'बदलते चक्र',
        'bn': 'পরিবর্তনশীল চক্র',
        'pt': 'Ciclos variáveis',
      });

  String get myGoalNow => _t({
        'es': 'Mi objetivo actual:',
        'en': 'My current goal:',
        'fr': 'Mon objectif actuel :',
        'de': 'Mein aktuelles Ziel:',
        'ru': 'Моя текущая цель:',
        'ar': 'هدفي الحالي:',
        'hi': 'मेरा वर्तमान लक्ष्य:',
        'bn': 'আমার বর্তমান লক্ষ্য:',
        'pt': 'Meu objetivo atual:',
      });

  String get quickAccess => _t({
        'es': 'Accesos rápidos',
        'en': 'Quick access',
        'fr': 'Accès rapides',
        'de': 'Schnellzugriff',
        'ru': 'Быстрый доступ',
        'ar': 'وصول سريع',
        'hi': 'त्वरित पहुंच',
        'bn': 'দ্রুত প্রবেশ',
        'pt': 'Acessos rápidos',
      });

  String dayOfCycleN(int n) => _t({
        'es': 'Día $n del ciclo',
        'en': 'Cycle day $n',
        'fr': 'Jour $n du cycle',
        'de': 'Zyklustag $n',
        'ru': 'День цикла $n',
        'ar': 'اليوم $n من الدورة',
        'hi': 'चक्र का दिन $n',
        'bn': 'চক্রের দিন $n',
        'pt': 'Dia $n do ciclo',
      });

  String get symptomsLogged => _t({
        'es': 'Síntomas registrados',
        'en': 'Logged symptoms',
        'fr': 'Symptômes notés',
        'de': 'Eingetragene Symptome',
        'ru': 'Отмеченные симптомы',
        'ar': 'الأعراض المسجلة',
        'hi': 'दर्ज लक्षण',
        'bn': 'লেখা উপসর্গ',
        'pt': 'Sintomas registrados',
      });

  String get nothingLogged => _t({
        'es': 'Aún no hay nada registrado este día',
        'en': 'Nothing logged on this day yet',
        'fr': 'Rien de noté ce jour-là',
        'de': 'Für diesen Tag ist noch nichts eingetragen',
        'ru': 'За этот день пока ничего не отмечено',
        'ar': 'لا يوجد شيء مسجل لهذا اليوم بعد',
        'hi': 'इस दिन अभी कुछ दर्ज नहीं है',
        'bn': 'এই দিনে এখনও কিছু লেখা নেই',
        'pt': 'Ainda não há nada registrado neste dia',
      });

  String get editDayRecords => _t({
        'es': 'Editar registros del día',
        'en': 'Edit this day',
        'fr': 'Modifier ce jour',
        'de': 'Tag bearbeiten',
        'ru': 'Изменить записи дня',
        'ar': 'تعديل سجلات اليوم',
        'hi': 'दिन के रिकॉर्ड बदलें',
        'bn': 'দিনের রেকর্ড সম্পাদনা',
        'pt': 'Editar registros do dia',
      });

  String get logYourDaySubtitle => _t({
        'es': 'Registra tus síntomas, hábitos y notas.',
        'en': 'Log your symptoms, habits and notes.',
        'fr': 'Note tes symptômes, habitudes et notes.',
        'de': 'Trage Symptome, Gewohnheiten und Notizen ein.',
        'ru': 'Отмечай симптомы, привычки и заметки.',
        'ar': 'سجّلي أعراضك وعاداتك وملاحظاتك.',
        'hi': 'अपने लक्षण, आदतें और नोट्स दर्ज करें।',
        'bn': 'আপনার উপসর্গ, অভ্যাস ও নোট লিখুন।',
        'pt': 'Registre seus sintomas, hábitos e notas.',
      });

  String monthShort(int month) {
    const t = {
      'es': ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'],
      'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      'fr': ['Janv', 'Févr', 'Mars', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'],
      'de': ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'],
      'ru': ['Янв', 'Фев', 'Мар', 'Апр', 'Май', 'Июн', 'Июл', 'Авг', 'Сен', 'Окт', 'Ноя', 'Дек'],
      'ar': ['ينا', 'فبر', 'مار', 'أبر', 'ماي', 'يون', 'يول', 'أغس', 'سبت', 'أكت', 'نوف', 'ديس'],
      'hi': ['जन', 'फ़र', 'मार्च', 'अप्रै', 'मई', 'जून', 'जुल', 'अग', 'सित', 'अक्टू', 'नव', 'दिस'],
      'bn': ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রি', 'মে', 'জুন', 'জুলা', 'আগ', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'],
      'pt': ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'],
    };
    return (t[code] ?? t['es']!)[(month - 1).clamp(0, 11)];
  }
}
