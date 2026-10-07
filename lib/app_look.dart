import 'package:flutter/material.dart';

import 'bundled_text.dart';

/// Warm paper and quiet ink, with a little clay and gold left in.
const Color lookPaper = Color(0xFFF3F0EA);
const Color lookCard = Color(0xFFFFFCF8);
const Color lookInk = Color(0xFF16325C);
const Color lookInkBlue = Color(0xFF1A4A8A);
const Color lookReading = Color(0xFF3E5270);
const Color lookRomaji = Colors.red;
const Color lookMeaning = Color(0xFF1A4A8A);
const Color lookCount = Color(0xFF5E6D82);
const Color lookGold = Color(0xFFD99A1C);
const Color lookLine = Color(0x2416325C);
const Color lookTile = Color(0xFFE7F1F8);
const Color lookTileQuiet = Color(0xFFF4F8FB);
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
  fontSize: 48,
  height: 1.1,
  color: lookRomaji,
);

double romanSpellingHeight(String text, double maxWidth, TextScaler textScaler) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: lookRomajiStyle),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    textAlign: TextAlign.center,
  )..layout(maxWidth: maxWidth);
  return painter.height + 4;
}

const TextStyle lookMeaningStyle = TextStyle(
  fontSize: 28,
  height: 1.1,
  color: lookMeaning,
);

const lookSoftShape = RaisedEdge(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  side: BorderSide(color: lookLine),
);

const lookStudyTileShape = RaisedEdge(
  borderRadius: BorderRadius.all(Radius.circular(22)),
  side: BorderSide(color: Color(0x332A6A9A)),
);

/// Rounded edge with a light top and a darker bottom, so a button
/// looks a little raised even where the drop shadow is tight.
class RaisedEdge extends RoundedRectangleBorder {
  const RaisedEdge({
    super.side = const BorderSide(color: lookLine),
    super.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  @override
  RoundedRectangleBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) {
    return RaisedEdge(
      side: side ?? this.side,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    super.paint(canvas, rect, textDirection: textDirection);
    final inset = side.width == 0 ? 1.0 : side.strokeInset + 0.6;
    final inner = borderRadius.resolve(textDirection).toRRect(rect).deflate(inset);
    final bevel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xD9FFFFFF),
          Color(0x00FFFFFF),
          Color(0x00000000),
          Color(0x3318334A),
        ],
        stops: [0.0, 0.42, 0.68, 1.0],
      ).createShader(rect);
    canvas.drawRRect(inner, bevel);
  }
}

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
        backgroundColor: lookCard,
        foregroundColor: lookInkBlue,
        disabledBackgroundColor: lookDisabled,
        disabledForegroundColor: lookDisabledInk,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x7330486A),
        shape: lookSoftShape,
        textStyle: bundledText.copyWith(
          fontSize: 16,
          height: 1.1,
        ),
      ).copyWith(
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return 0;
          if (states.contains(WidgetState.pressed)) return 1;
          if (states.contains(WidgetState.hovered)) return 5;
          return 3;
        }),
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
