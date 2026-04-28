import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../design_tokens.dart';
import '../components/app_components.dart';
import '../components/app_bottom_nav.dart';
import '../components/optimized_network_image.dart';
import '../services/cowbnb_api.dart';
import '../models/api_models.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key, required this.listingId}) : super(key: key);

  final String listingId;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  DateTime? startDate;
  DateTime? endDate;
  late final CowbnbApi _api;

  @override
  void initState() {
    super.initState();
    _api = CowbnbApi();
  }

  @override
  Widget build(BuildContext context) {
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
              context.go('/listing');
            }
          },
        ),
      ),
      body: FutureBuilder<Listing>(
        future: _api.fetchListing(widget.listingId),
        builder: (context, snapshot) {
          final listing = snapshot.data;
          if (listing == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
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
                            imageUrl: listing.imageUrl,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            memCacheWidth: 800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          listing.title,
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
                              '${listing.location} • ${listing.sizeHectares ?? 0} Hectáreas',
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

              _buildPriceRow('Noche (${listing.sizeHectares ?? 0} hectáreas)', '\$${listing.priceMonthly}', '1'),
              _buildPriceRow('Gastos de servicio', '\$120', ''),
              _buildPriceRow('Impuestos', '\$132', ''),

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
                      '\$${listing.priceMonthly}',
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
                    if (startDate == null || endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona fechas de reserva.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    final payload = ReservaPayload(
                      terrenoId: listing.id,
                      renterId: 'demo-renter',
                      ownerId: 'demo-owner',
                      startDate: startDate!.millisecondsSinceEpoch,
                      endDate: endDate!.millisecondsSinceEpoch,
                      priceMonthly: listing.priceMonthly,
                    );

                    await _api.createReserva(payload);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Reserva confirmada!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    context.go('/renter');
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
          );
        },
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
