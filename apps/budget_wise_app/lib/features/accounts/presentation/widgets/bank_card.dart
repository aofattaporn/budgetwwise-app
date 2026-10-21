import 'package:flutter/material.dart';

import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/account.dart';

/// Compact bank-card style tile for an [Account]: gradient surface, type icon,
/// name, masked tail and the current balance.
class BankCard extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onMenuTap;
  final bool selected;
  final Widget? trailing;

  const BankCard({
    super.key,
    required this.account,
    this.onTap,
    this.onMenuTap,
    this.selected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final style = _CardStyle.of(account.type);
    final radius = BorderRadius.circular(22);

    return Semantics(
      button: onTap != null,
      label:
          '${account.name}, ${_typeName(account.type)}, balance ${CurrencyUtils.formatCurrency(account.balance)}',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: selected ? Border.all(color: Colors.white, width: 2) : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: style.colors.last.withValues(alpha: 0.28),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  Positioned(right: -36, top: -48, child: _circle(130, 0.10)),
                  Positioned(right: 36, bottom: -70, child: _circle(120, 0.07)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(style.icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                account.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_typeName(account.type)} · ${_tail(account.id)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              CurrencyUtils.formatCurrency(account.balance),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ),
                        if (trailing != null)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: trailing,
                          )
                        else if (onMenuTap != null)
                          InkResponse(
                            onTap: onMenuTap,
                            radius: 20,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(Icons.more_vert_rounded,
                                  size: 20,
                                  color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          )
                        else if (selected)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.check_circle_rounded,
                                size: 22, color: Colors.white),
                          )
                        else
                          const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _circle(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );

  static String _tail(String id) {
    final clean = id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final last4 = clean.length >= 4
        ? clean.substring(clean.length - 4)
        : clean.padLeft(4, '0');
    return '•••• $last4';
  }

  static String _typeName(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'bank':
        return 'Bank';
      case 'debit':
        return 'Debit';
      case 'ewallet':
      case 'e-wallet':
        return 'E-Wallet';
      default:
        return type;
    }
  }
}

class _CardStyle {
  final List<Color> colors;
  final IconData icon;

  const _CardStyle(this.colors, this.icon);

  static _CardStyle of(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return const _CardStyle(
            [Color(0xFFF59E0B), Color(0xFFB45309)], Icons.payments_rounded);
      case 'ewallet':
      case 'e-wallet':
        return const _CardStyle(
            [Color(0xFF14B8A6), Color(0xFF0F766E)], Icons.wallet_rounded);
      case 'debit':
        return const _CardStyle(
            [Color(0xFF3F3F46), Color(0xFF111114)], Icons.credit_card_rounded);
      case 'bank':
      default:
        return const _CardStyle(
            [Color(0xFF3B82F6), Color(0xFF1E3A8A)], Icons.account_balance_rounded);
    }
  }
}
