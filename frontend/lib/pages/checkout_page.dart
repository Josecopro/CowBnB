import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/listing_service.dart';
import '../services/reservation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> listing;
  const CheckoutPage({Key? key, required this.listing}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  DateTime? startDate;
  DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    int months = 1;
    if (startDate != null && endDate != null) {
      final days = endDate!.difference(startDate!).inDays;
      months = (days / 30).ceil();
      if (months <= 0) months = 1;
    }
    
    const double minTaxes = 1000;
    final int monthlyPrice = int.tryParse(widget.listing['price']?.toString() ?? '1200') ?? 1200;
    final double maintenanceMonthly = (widget.listing['maintenanceCost'] as num?)?.toDouble() ?? 0;
    final int subtotal = months * monthlyPrice;
    final double maintenanceTotal = maintenanceMonthly * months;
    final double taxes = math.max(subtotal * 0.19, minTaxes);
    final double total = subtotal + maintenanceTotal + taxes;

    final String imgUrl = (widget.listing['images'] != null && widget.listing['images'] is List && widget.listing['images'].isNotEmpty)
      ? widget.listing['images'][0].toString()
      : 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?q=80&w=1000&auto=format&fit=crop';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text(
          'Confirmar Reserva',
          style: AppTextStyles.headline.copyWith(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Listing Summary
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: AppNetworkImage(
                        imageUrl: imgUrl,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        memCacheWidth: 800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      widget.listing['title']?.toString() ?? 'Sin Titulo',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.listing['location']?.toString() ?? 'Cordoba, Argentina'} • ${widget.listing['size']?.toString() ?? '12'} Hectareas',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Date Selection
              Text(
                'Fechas de Reserva',
                style: AppTextStyles.label.copyWith(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => startDate = date);
                        }
                      },
                      child: AppCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inicio',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  startDate != null
                                      ? '${startDate!.day}/${startDate!.month}'
                                      : 'Seleccionar',
                                  style: AppTextStyles.label,
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today,
                                color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => endDate = date);
                        }
                      },
                      child: AppCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fin',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  endDate != null
                                      ? '${endDate!.day}/${endDate!.month}'
                                      : 'Seleccionar',
                                  style: AppTextStyles.label,
                                ),
                              ],
                            ),
                            const Icon(Icons.calendar_today,
                                color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Price Breakdown
              Text(
                'Detalles de Pago',
                style: AppTextStyles.label.copyWith(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _buildPriceRow('Mes', '\$${monthlyPrice.toStringAsFixed(0)}', '$months'),
              _buildPriceRow('Gastos de servicios', '\$${maintenanceTotal.toStringAsFixed(0)}', maintenanceMonthly > 0 ? '$months' : ''),
              _buildPriceRow('Impuestos', '\$${taxes.toStringAsFixed(0)}', ''),

              const SizedBox(height: AppSpacing.md),

              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(0)}',
                      style: AppTextStyles.headline.copyWith(
                        color: AppColors.primary,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Terms Checkbox
              Row(
                children: [
                  Checkbox(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: Text(
                      'Acepto los términos y condiciones',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // CTA Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final listingId = widget.listing['id']?.toString();
                    if (listingId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se encontro el anuncio.')),
                      );
                      return;
                    }
                    if (startDate == null || endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona las fechas de reserva.')),
                      );
                      return;
                    }
                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      final displayName = user?.displayName ?? user?.email ?? 'Usuario';
                      final images = widget.listing['images'] as List<dynamic>?;
                      final image = (images != null && images.isNotEmpty)
                          ? images.first.toString()
                          : '';
                      await ReservationService().createReservation(
                        listingId: listingId,
                        listingTitle: widget.listing['title']?.toString() ?? 'Sin título',
                        listingImage: image,
                        ownerId: widget.listing['ownerId']?.toString() ?? '',
                        ownerName: '',
                        startDate: startDate!.toIso8601String(),
                        endDate: endDate!.toIso8601String(),
                        months: months,
                        monthlyPrice: monthlyPrice,
                        maintenanceMonthly: maintenanceMonthly,
                        taxes: taxes,
                        total: total,
                        renterName: displayName,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('¡Reserva confirmada!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      context.go('/renter');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No se pudo confirmar la reserva: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    'Confirmar Reserva',
                    style: AppTextStyles.label.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeItem: AppNavItem.profile),
    );
  }

  Widget _buildPriceRow(String label, String price, String qty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Row(
            children: [
              if (qty.isNotEmpty)
                Text(
                  'x$qty',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              const SizedBox(width: AppSpacing.md),
              Text(
                price,
                style: AppTextStyles.label,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
