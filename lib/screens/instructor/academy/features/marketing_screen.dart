import 'package:flutter/material.dart';
import '../../../../../theme/app_theme.dart';
import '../../../../../widgets/neon_widgets.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final _metaPixelCtrl = TextEditingController();
  final _tiktokPixelCtrl = TextEditingController();
  bool _pixelsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Marketing'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pixels Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.track_changes, color: Colors.blueAccent),
                          SizedBox(width: 12),
                          Text('Tracking Pixels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Switch(
                        value: _pixelsEnabled, 
                        activeColor: AppColors.neonGreen,
                        onChanged: (val) => setState(() => _pixelsEnabled = val)
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Conecta tus cuentas publicitarias para rastrear conversiones en tu web.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  if (_pixelsEnabled) ...[
                    TextField(
                      controller: _metaPixelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Meta Pixel ID',
                        prefixIcon: Icon(Icons.facebook),
                        border: OutlineInputBorder(),
                        hintText: 'XXXXXXXXXXXXXXX'
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tiktokPixelCtrl,
                      decoration: const InputDecoration(
                        labelText: 'TikTok Pixel ID',
                        prefixIcon: Icon(Icons.music_note), // Icon fallback
                        border: OutlineInputBorder(),
                        hintText: 'XXXXXXXXXXXXXXX'
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPurple, foregroundColor: Colors.white),
                        onPressed: () {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pixels guardados')));
                        },
                        child: const Text('Guardar'),
                      ),
                    )
                  ]
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Campaigns Card
            const Text('Campañas Activas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                // REMOVED INVALID BorderStyle.dashed - replaced with solid for now
                border: Border.all(color: Colors.grey.withOpacity(0.3)), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Column(
                children: [
                  Icon(Icons.campaign_outlined, color: Colors.grey.shade400, size: 48),
                  const SizedBox(height: 12),
                  Text('No tienes campañas activas', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Crea campañas de email marketing o notificaciones push para tus alumnos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Crear Nueva Campaña'),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
