import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyGiftSummary {
  const FamilyGiftSummary({
    required this.familyId,
    required this.familyName,
    required this.tierName,
    required this.annualPremium,
    required this.lumpSumTotal,
    required this.memberCount,
    required this.memberNames,
    required this.memberIds,
    required this.primaryCustomerId,
    required this.primaryRecipient,
    required this.giftQuantity,
  });

  final String familyId;
  final String familyName;
  final String tierName;
  final double annualPremium;
  final double lumpSumTotal;

  final int memberCount;
  final List<String> memberNames;
  final List<String> memberIds;

  final String primaryCustomerId;
  final String primaryRecipient;

  final int giftQuantity;
}

class GiftRepository {
  final SupabaseClient client = Supabase.instance.client;

  String get uid {
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('尚未登入');
    }
    return user.id;
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _annualized(double amount, String frequency) {
    switch (frequency) {
      case '半年繳':
        return amount * 2;
      case '季繳':
        return amount * 4;
      case '月繳':
        return amount * 12;
      case '躉繳':
        return 0;
      default:
        return amount;
    }
  }

  Future<List<Map<String, dynamic>>> customers() async {
    final rows = await client
        .from('customers')
        .select('id,name')
        .eq('user_id', uid)
        .order('name');

    return (rows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Set<String>> assignedCustomerIds({
    String? excludingFamilyId,
  }) async {
    final rows =
        await client.from('family_members').select('family_id,customer_id');

    final result = <String>{};

    for (final raw in rows as List) {
      final row = Map<String, dynamic>.from(raw as Map);

      if (excludingFamilyId != null &&
          row['family_id']?.toString() == excludingFamilyId) {
        continue;
      }

      final id = row['customer_id']?.toString() ?? '';

      if (id.isNotEmpty) {
        result.add(id);
      }
    }

    return result;
  }

  Future<void> saveFamily({
    String? familyId,
    required String familyName,
    required List<String> customerIds,
    required String primaryCustomerId,
    int giftQuantity = 1,
  }) async {
    if (familyName.trim().isEmpty) {
      throw ArgumentError('請輸入家庭名稱');
    }

    if (customerIds.isEmpty) {
      throw ArgumentError('至少選擇一位家庭成員');
    }

    if (!customerIds.contains(primaryCustomerId)) {
      throw ArgumentError('主要收禮人必須是家庭成員');
    }

    String id;

    if (familyId == null) {
      final created = await client
          .from('families')
          .insert({
            'user_id': uid,
            'family_name': familyName.trim(),
            'primary_customer_id': primaryCustomerId,
            'gift_quantity': giftQuantity,
          })
          .select('id')
          .single();

      id = created['id'].toString();
    } else {
      id = familyId;

      await client
          .from('families')
          .update({
            'family_name': familyName.trim(),
            'primary_customer_id': primaryCustomerId,
            'gift_quantity': giftQuantity,
          })
          .eq('id', familyId)
          .eq('user_id', uid);

      await client.from('family_members').delete().eq('family_id', familyId);
    }

    await client.from('family_members').insert(
          customerIds
              .map(
                (customerId) => {
                  'family_id': id,
                  'customer_id': customerId,
                },
              )
              .toList(),
        );
  }

  Future<List<FamilyGiftSummary>> familySummaries() async {
    final familyRows = await client
        .from('families')
        .select()
        .eq('user_id', uid)
        .order('created_at');

    final families = (familyRows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (families.isEmpty) return [];

    final memberRows = await client.from('family_members').select();

    final members = (memberRows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final customerRows =
        await client.from('customers').select('id,name').eq('user_id', uid);

    final customers = <String, String>{};

    for (final raw in customerRows as List) {
      final row = Map<String, dynamic>.from(raw as Map);

      customers[row['id'].toString()] = row['name']?.toString() ?? '未命名';
    }

    final policyRows =
        await client.from('policies').select().eq('user_id', uid);

    final policies = (policyRows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final riderRows =
        await client.from('policy_riders').select().eq('user_id', uid);

    final riders = (riderRows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final tierRows = await client
        .from('gift_tier_settings')
        .select()
        .eq('user_id', uid)
        .order('min_annual_premium', ascending: false);

    var tiers = (tierRows as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (tiers.isEmpty) {
      tiers = [
        {
          'tier_name': '黑鑽級',
          'min_annual_premium': 200000,
        },
        {
          'tier_name': '白金級',
          'min_annual_premium': 100000,
        },
        {
          'tier_name': '金級',
          'min_annual_premium': 50000,
        },
        {
          'tier_name': '銀級',
          'min_annual_premium': 0,
        },
      ];
    }

    String tierFor(double annualPremium) {
      for (final tier in tiers) {
        if (annualPremium >= _number(tier['min_annual_premium'])) {
          return tier['tier_name']?.toString() ?? '銀級';
        }
      }

      return '銀級';
    }

    final summaries = <FamilyGiftSummary>[];

    for (final family in families) {
      final familyId = family['id'].toString();

      final familyMemberIds = members
          .where(
            (m) => m['family_id']?.toString() == familyId,
          )
          .map(
            (m) => m['customer_id']?.toString() ?? '',
          )
          .where((id) => id.isNotEmpty)
          .toList();

      final familyMemberSet = familyMemberIds.toSet();

      final memberNames =
          familyMemberIds.map((id) => customers[id] ?? '未命名').toList();

      double annualPremium = 0;
      double lumpSumTotal = 0;

      final activePolicyIds = <String>{};

      for (final policy in policies) {
        final customerId = policy['customer_id']?.toString() ?? '';

        if (!familyMemberSet.contains(customerId)) {
          continue;
        }

        final status = policy['policy_status']?.toString().trim();

        if (status != null && status.isNotEmpty && status != '有效') {
          continue;
        }

        final policyId = policy['id']?.toString() ?? '';

        if (policyId.isNotEmpty) {
          activePolicyIds.add(policyId);
        }

        final frequency =
            policy['payment_frequency']?.toString().trim().isNotEmpty == true
                ? policy['payment_frequency'].toString()
                : '年繳';

        final amount = _number(policy['premium_amount']);

        if (frequency == '躉繳') {
          lumpSumTotal += amount;
        } else {
          final storedAnnual = _number(policy['annual_premium']);

          annualPremium +=
              storedAnnual > 0 ? storedAnnual : _annualized(amount, frequency);
        }
      }

      for (final rider in riders) {
        final policyId = rider['policy_id']?.toString() ?? '';

        if (!activePolicyIds.contains(policyId)) {
          continue;
        }

        final frequency =
            rider['payment_frequency']?.toString().trim().isNotEmpty == true
                ? rider['payment_frequency'].toString()
                : '年繳';

        final amount = _number(rider['premium_amount']);

        if (frequency == '躉繳') {
          lumpSumTotal += amount;
        } else {
          final storedAnnual = _number(rider['annual_premium']);

          annualPremium +=
              storedAnnual > 0 ? storedAnnual : _annualized(amount, frequency);
        }
      }

      final primaryId = family['primary_customer_id']?.toString() ?? '';

      summaries.add(
        FamilyGiftSummary(
          familyId: familyId,
          familyName: family['family_name']?.toString() ?? '未命名家庭',
          tierName: tierFor(annualPremium),
          annualPremium: annualPremium,
          lumpSumTotal: lumpSumTotal,
          memberCount: familyMemberIds.length,
          memberNames: memberNames,
          memberIds: familyMemberIds,
          primaryCustomerId: primaryId,
          primaryRecipient: customers[primaryId] ?? '未指定',
          giftQuantity: int.tryParse(
                family['gift_quantity']?.toString() ?? '',
              ) ??
              1,
        ),
      );
    }

    summaries.sort(
      (a, b) => b.annualPremium.compareTo(a.annualPremium),
    );

    return summaries;
  }
}
