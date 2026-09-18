import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../navigation/shell_navigation.dart';

DateTime? parseAnyDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;

  final value = raw.toString().trim();
  if (value.isEmpty) return null;

  return DateTime.tryParse(value);
}

DateTime? parseFormDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  final normalized = value.replaceAll('/', '-').replaceAll('.', '-');

  return DateTime.tryParse(normalized);
}

String formatDateOnly(dynamic raw) {
  final date = parseAnyDate(raw);
  if (date == null) return '';
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatRocBirthday(dynamic value) {
  final date = parseAnyDate(value);
  if (date == null) return value?.toString() ?? '';

  final rocYear = date.year - 1911;

  return '$rocYear.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')}';
}

String nameWithRocBirthday(dynamic name, dynamic birthday) {
  final n = name?.toString().trim() ?? '';
  final b = formatRocBirthday(birthday);

  return [n, b].where((e) => e.isNotEmpty).join(' ');
}

String? normalizeBirthdayInput(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  final normalized = value
      .replaceAll('民國', '')
      .replaceAll('年', '-')
      .replaceAll('月', '-')
      .replaceAll('日', '')
      .replaceAll('/', '-')
      .replaceAll('.', '-');

  final parts = normalized.split('-').where((e) => e.isNotEmpty).toList();

  if (parts.length != 3) return '__INVALID__';

  final yearText = parts[0];
  final year = int.tryParse(yearText);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);

  if (year == null || month == null || day == null) {
    return '__INVALID__';
  }

  int westernYear;

  if (yearText.length == 4 && year >= 1911) {
    westernYear = year;
  } else if (yearText.length == 2 || yearText.length == 3) {
    westernYear = year + 1911;
  } else {
    return '__INVALID__';
  }

  try {
    final date = DateTime(westernYear, month, day);

    if (date.year != westernYear || date.month != month || date.day != day) {
      return '__INVALID__';
    }

    return DateFormat('yyyy-MM-dd').format(date);
  } catch (_) {
    return '__INVALID__';
  }
}

bool isValidPhoneInput(String raw) {
  final value = raw
      .replaceAll(' ', '')
      .replaceAll('-', '')
      .replaceAll('(', '')
      .replaceAll(')', '');

  if (value.isEmpty) return true;

  return RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value);
}

Future<void> showFormWarning(
  BuildContext context,
  String message,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('資料格式錯誤'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('確定'),
        ),
      ],
    ),
  );
}

void snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(text)),
    );
}

Widget sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

NavigationBar mainNavigationBar(
  BuildContext context,
  int currentIndex,
) {
  return NavigationBar(
    selectedIndex: currentIndex,
    height: 72,
    onDestinationSelected: (value) {
      shellIndexNotifier.value = value;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );
      }
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home),
        label: '首頁',
      ),
      NavigationDestination(
        icon: Icon(Icons.people),
        label: '客戶',
      ),
      NavigationDestination(
        icon: Icon(Icons.grid_view),
        label: '九宮格',
      ),
      NavigationDestination(
        icon: Icon(Icons.handshake_outlined),
        label: '經營',
      ),
      NavigationDestination(
        icon: Icon(Icons.group_add_outlined),
        label: '增員',
      ),
    ],
  );
}
