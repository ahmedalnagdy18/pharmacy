import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

double appHight(BuildContext context, double h) {
  return MediaQuery.of(context).size.height * h;
}

double appWidth(BuildContext context, double w) {
  return MediaQuery.of(context).size.width * w;
}

// Prevent spaces at the start of the text
class PreventStartingSpaceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String newText = newValue.text;

    // Prevent starting with a space by trimming only the beginning
    if (newText.startsWith(' ')) {
      newText = newText.trimLeft();
    }

    // Replace multiple spaces with a single space throughout the text.
    newText = newText.replaceAll(RegExp(r'\s{2,}'), ' ');
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

TextInputFormatter noSpaceFormatter() {
  return TextInputFormatter.withFunction((oldValue, newValue) {
    if (newValue.text.startsWith(' ')) {
      final newText = newValue.text.trimLeft();
      return newValue.copyWith(
        text: newText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newText.length),
        ),
      );
    }
    return newValue;
  });
} //  noSpaceFormatter(),   to call it

// or

//  inputFormatters: [
//              FilteringTextInputFormatter.deny(RegExp(r'\s')),
//
