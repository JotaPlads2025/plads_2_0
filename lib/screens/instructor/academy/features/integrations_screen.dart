import 'package:flutter/material.dart';
import '../../../../../theme/app_theme.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> {
  bool _zoomConnected = false;
  bool _calendarConnected = true;
  bool _zapierConnected = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Integraciones'),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntegrationCard(
            theme,
            'Zoom Meetings',
            'Genera enlaces de videollamada automáticamente para tus clases online.',
            Icons.videocam,
            Colors.blue,
            _zoomConnected,
            (val) => setState(() => _zoomConnected = val)
          ),
          const SizedBox(height: 16),
          _buildIntegrationCard(
            theme,
            'Google Calendar',
            'Sincroniza tus clases con tu calendario personal.',
            Icons.calendar_today,
            Colors.green,
            _calendarConnected,
            (val) => setState(() => _calendarConnected = val)
          ),
          const SizedBox(height: 16),
          _buildIntegrationCard(
            theme,
            'Zapier',
            'Conecta Plads con más de 5000 apps (Mailchimp, Slack, Sheets).',
            Icons.bolt,
            Colors.orange,
            _zapierConnected,
            (val) => setState(() => _zapierConnected = val)
          ),
          const SizedBox(height: 16),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add, color: Colors.grey),
            title: const Text('Solicitar nueva integración', style: TextStyle(color: Colors.grey)),
            onTap: () {},
          )
        ],
      ),
    );
  }

  Widget _buildIntegrationCard(ThemeData theme, String title, String desc, IconData icon, Color color, bool isConnected, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isConnected ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.2)),
        boxShadow: [
           if (isConnected) BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6)
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: isConnected ? Colors.green : Colors.grey),
                    const SizedBox(width: 6),
                    Text(isConnected ? 'Conectado' : 'Desconectado', style: TextStyle(
                      fontSize: 12, 
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.green : Colors.grey
                    )),
                  ],
                ),
              ),
              Switch(
                value: isConnected,
                activeColor: color,
                onChanged: onChanged,
              ) // Simple toggle for mock
            ],
          )
        ],
      ),
    );
  }
}
