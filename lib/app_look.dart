import 'package:flutter/material.dart';

import 'bundled_text.dart';

/// Warm paper and quiet ink, with a little clay and gold left in.
const Color lookPaper = Color(0xFFF3F0EA);
const Color lookCard = Color(0xFFFFFCF8);
const Color lookInk = Color(0xFF16325C);
const Color lookInkBlue = Color(0xFF1A4A8A);
const Color lookReading = Color(0xFF3E5270);
const Color lookRomaji = Color(0xFFC56A32);
const Color lookMeaning = Color(0xFF1A4A8A);
const Color lookCount = Color(0xFF5E6D82);
const Color lookGold = Color(0xFFD99A1C);
const Color lookLine = Color(0x2416325C);
const Color lookTile = Color(0xFFE7F1F8);
const Color lookDisabled = Color(0xFFE6E1D8);
const Color lookDisabledInk = Color(0xFF8C857C);

const TextStyle lookPrompt = TextStyle(
  fontSize: 48,
  fontWeight: FontWeight.bold,
  color: lookInk,
);

const TextStyle lookCountPlain = TextStyle(
  fontSize: 20,
  color: lookCount,
);

const TextStyle lookCountStyle = TextStyle(
  fontSize: 20,
  height: 1.1,
  color: lookCount,
);

const TextStyle lookReadingStyle = TextStyle(
  fontSize: 24,
  height: 1.1,
  color: lookReading,
);

const TextStyle lookRomajiStyle = TextStyle(
  fontSize: 24,
  height: 1.1,
  color: lookRomaji,
);

const TextStyle lookMeaningStyle = TextStyle(
  fontSize: 28,
  height: 1.1,
  color: lookMeaning,
);

const RoundedRectangleBorder lookSoftShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  side: BorderSide(color: lookLine),
);

const RoundedRectangleBorder lookStudyTileShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(22)),
  side: BorderSide(color: Color(0x332A6A9A)),
);

ThemeData appTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: lookInkBlue,
      brightness: Brightness.light,
      surface: lookPaper,
    ),
    scaffoldBackgroundColor: lookPaper,
    fontFamily: 'AppText',
    fontFamilyFallback: const ['AppJapanese', 'AppEmoji'],
  );
  return base.copyWith(
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: lookPaper,
      foregroundColor: lookInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleTextStyle: bundledText.copyWith(
        color: lookInk,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: lookInkBlue),
      shape: const LinearBorder(
        side: BorderSide(color: lookLine),
        bottom: LinearBorderEdge(),
      ),
    ),
    iconTheme: const IconThemeData(color: lookInkBlue),
    dialogTheme: const DialogThemeData(
      backgroundColor: lookCard,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(22)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: lookCard,
        foregroundColor: lookInkBlue,
        disabledBackgroundColor: lookDisabled,
        disabledForegroundColor: lookDisabledInk,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: lookSoftShape,
        textStyle: bundledText.copyWith(
          fontSize: 16,
          height: 1.1,
        ),
      ),
    ),
    textTheme: base.textTheme.apply(
      fontFamily: 'AppText',
      fontFamilyFallback: const ['AppJapanese', 'AppEmoji'],
      bodyColor: lookInk,
      displayColor: lookInk,
    ),
  );
}

class QuietNote extends StatelessWidget {
  const QuietNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: bundledText.copyWith(
          fontSize: 18,
          height: 1.45,
          color: lookCount,
        ),
      ),
    );
  }
}
