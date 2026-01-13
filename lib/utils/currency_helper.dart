import 'package:intl/intl.dart';

class CurrencyHelper {
  static String format(double amount, String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'CL': // Chile: $10.000
        return '\$${NumberFormat('#,###', 'es_CL').format(amount)}';
      
      case 'PE': // Peru: S/ 50.00
        return 'S/ ${NumberFormat('#,##0.00', 'es_PE').format(amount)}';
      
      case 'BR': // Brazil: R$ 100,00
        return 'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(amount)}';
        
      case 'US': // USA: $100.00
      default:
        return '\$${NumberFormat('#,##0.00', 'en_US').format(amount)}';
    }
  }

  static String getSymbol(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'CL': return '\$';
      case 'PE': return 'S/';
      case 'BR': return 'R\$';
      default: return '\$';
    }
  }
}
